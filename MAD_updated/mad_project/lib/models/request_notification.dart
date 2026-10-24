import 'borrow_request.dart';

enum RequestNotificationDestination { details, approval, pickup, reminder }

/// In-app updates derived from the user's live Firestore request records.
/// Missing event timestamps are displayed without an invented event time.
class RequestNotification {
  const RequestNotification({
    required this.requestId,
    required this.title,
    required this.message,
    required this.date,
    this.actionable = false,
    this.isRead = false,
    this.destination = RequestNotificationDestination.details,
  });
  final String requestId, title, message;
  final DateTime? date;
  final bool actionable;
  final bool isRead;
  final RequestNotificationDestination destination;

  static List<RequestNotification> fromRequests(
    List<BorrowRequest> requests,
    DateTime now,
  ) {
    final result = <RequestNotification>[];
    for (final request in requests.where((r) => !r.archived)) {
      void add(
        String title,
        String message,
        DateTime? date, {
        bool actionable = false,
        RequestNotificationDestination destination =
            RequestNotificationDestination.details,
      }) {
        result.add(
          RequestNotification(
            requestId: request.id,
            title: title,
            message: message,
            date: date,
            actionable: actionable,
            isRead:
                request.readNotificationKeys.contains(title) ||
                (title == 'Request Approved' && request.approvalReadAt != null),
            destination: destination,
          ),
        );
      }

      if (request.status == 'Approved' || request.approvedAt != null) {
        add(
          'Request Approved',
          'Your request for ${request.equipmentName} was approved!',
          request.approvedAt,
          actionable: request.status == 'Approved',
          destination: RequestNotificationDestination.approval,
        );
      }
      if (request.status == 'Borrowed' || request.pickedUpAt != null) {
        add(
          'Pickup confirmed',
          '${request.equipmentName} status changed to Borrowed.',
          request.pickedUpAt,
        );
      }
      if (request.status == 'Borrowed' && request.returnAt != null) {
        add(
          'Return schedule',
          'Check the return schedule for your ${request.equipmentName}.',
          request.pickedUpAt,
        );
        if (!request.returnAt!.isAfter(now.add(const Duration(hours: 24)))) {
          final overdue = request.returnAt!.isBefore(now);
          add(
            overdue ? 'Return overdue' : 'Return reminder',
            '${request.equipmentName} ${overdue ? 'is overdue. Please return it to the equipment office.' : 'is due within 24 hours. View the return deadline.'}',
            request.returnAt!.subtract(const Duration(hours: 24)),
            actionable: true,
            destination: RequestNotificationDestination.reminder,
          );
        }
      }
      if (request.status == 'Returned') {
        add(
          'Equipment returned',
          '${request.equipmentName} transaction marked Returned.',
          request.returnedAt,
        );
      }
    }
    result.sort((a, b) {
      final byDate = (b.date ?? DateTime(1970)).compareTo(
        a.date ?? DateTime(1970),
      );
      if (byDate != 0) return byDate;
      final byId = a.requestId.compareTo(b.requestId);
      return byId != 0 ? byId : a.title.compareTo(b.title);
    });
    return result;
  }
}
