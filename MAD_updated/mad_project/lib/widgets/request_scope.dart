import 'package:flutter/widgets.dart';

import '../models/borrow_request.dart';
import '../services/request_service.dart';

/// Same dependency injection pattern as EquipmentScope.
class RequestScope extends InheritedWidget {
  const RequestScope({super.key, required this.watch, required super.child});
  final Stream<List<BorrowRequest>> Function() watch;
  static Stream<List<BorrowRequest>> watchOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RequestScope>()?.watch() ??
      RequestService().watchRequests();
  @override
  bool updateShouldNotify(RequestScope oldWidget) => watch != oldWidget.watch;
}
