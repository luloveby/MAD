# PDF pages 8–11 implementation

Existing files were not modified. navigation.patch is a proposed, unapplied change to the two existing navigation files. The app has no central router: the patch follows its MaterialPageRoute and RouteSettings pattern. Requests, details, pickup, reminders, history, and archive are linked inside the new feature.

## Backend contract and limitations

The existing app defines only equipment and users collections. requests is a proposed new collection, using existing camelCase field conventions and uid ownership. Each document needs uid, equipmentId, equipmentName, status (Pending/Approved/Borrowed/Returned), purpose, borrowAt and returnAt (Firestore timestamps), optional returnedAt, and archived (boolean). EquipmentItem is not recreated or changed. equipmentName is a transaction display snapshot, not a replacement equipment model.

RequestService uses FirebaseFirestore.instance, uid-filtered snapshots, and local sorting, matching EquipmentService; there is no existing pagination pattern. No Firebase initialization or new dependency is added. Loading and read errors use AppScaffold, StreamBuilder, a spinner, and inline error text; write errors use snackbars and mounted guards.

Current firestore.rules denies requests reads/writes. Review the supplied rules fragment and merge it inside the existing /databases/{database}/documents match before using live data. No rules were deployed. Trusted backend/admin code must create requests, approve them, manage inventory reservation, and mark them Returned; these pages never mark equipment returned or change stock. There is no existing request producer in this repository. Reminder text is shown on demand; scheduled notifications are outside these PDF pages.

The PDF explicitly leaves return confirmation and archive interactions unresolved. This implementation allows archiving returned requests and opening their details; it does not invent a student return-confirmation action. The existing Home active-borrowings placeholder is unchanged. Full entry from the existing bottom bar/drawer requires applying navigation.patch, which is outside the permitted edits. Theme and shared chrome are reused; this is not a pixel-exact reproduction of the embedded thumbnails.

## File summary

- lib/models/borrow_request.dart: typed request document parser.
- lib/services/request_service.dart: live owned requests, transactional pickup, transactional archive.
- lib/widgets/request_scope.dart: injectable request stream following EquipmentScope.
- lib/widgets/request_widgets.dart: shared loading/error state, cards, dates and page layout.
- lib/pages/user_requests_page.dart: status filters, request cards and history entry.
- lib/pages/request_details_page.dart: live transaction details, pickup and reminder entries.
- lib/pages/pickup_confirmation_page.dart: received/not-yet actions and success dialog.
- lib/pages/return_reminder_page.dart: deadline/overdue display and View Request.
- lib/pages/borrowing_history_page.dart: returned transactions and archive entry.
- lib/pages/archive_page.dart: selection, archive persistence and archived details.
- test/request_pages_test.dart: status filtering, details navigation, pickup success/failure.
- output/pages_8_11/navigation.patch: unapplied entry-point changes for review.
- output/pages_8_11/requests.rules.fragment: proposed request security rules, not deployed.
- output/pages_8_11/complete_source.md: this delivery document with complete Dart file contents.

## Complete file contents

### lib/models/borrow_request.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Proposed request schema; equipment remains in the existing equipment collection.
class BorrowRequest {
  const BorrowRequest({
    required this.id,
    required this.uid,
    required this.equipmentId,
    required this.equipmentName,
    required this.status,
    required this.purpose,
    this.borrowAt,
    this.returnAt,
    this.returnedAt,
    this.archived = false,
  });

  final String id, uid, equipmentId, equipmentName, status, purpose;
  final DateTime? borrowAt, returnAt, returnedAt;
  final bool archived;

  factory BorrowRequest.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime? date(String key) => (data[key] as Timestamp?)?.toDate();
    return BorrowRequest(
      id: id,
      uid: data['uid'] as String,
      equipmentId: data['equipmentId'] as String,
      equipmentName: data['equipmentName'] as String? ?? 'Equipment',
      status: data['status'] as String,
      purpose: data['purpose'] as String? ?? '',
      borrowAt: date('borrowAt'),
      returnAt: date('returnAt'),
      returnedAt: date('returnedAt'),
      archived: data['archived'] == true,
    );
  }
}

```

### lib/services/request_service.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/borrow_request.dart';

class RequestService {
  RequestService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please log in to view requests.');
    return user.uid;
  }

  Stream<List<BorrowRequest>> watchRequests() {
    return _db
        .collection('requests')
        .where('uid', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => BorrowRequest.fromFirestore(doc.id, doc.data()))
              .toList();
          requests.sort(
            (a, b) => (b.borrowAt ?? DateTime(1970)).compareTo(
              a.borrowAt ?? DateTime(1970),
            ),
          );
          return requests;
        });
  }

  Future<void> confirmPickup(String id) async {
    final uid = _uid;
    final ref = _db.collection('requests').doc(id);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null || data['uid'] != uid) {
        throw StateError('Request not found.');
      }
      if (data['status'] == 'Borrowed') return;
      if (data['status'] != 'Approved') {
        throw StateError('Only approved requests can be picked up.');
      }
      transaction.update(ref, {
        'status': 'Borrowed',
        'pickedUpAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> archiveRequests(Set<String> ids) async {
    if (ids.isEmpty) return;
    if (ids.length > 400) {
      throw StateError('Select up to 400 requests at a time.');
    }
    final uid = _uid;
    await _db.runTransaction((transaction) async {
      final refs = ids.map((id) => _db.collection('requests').doc(id)).toList();
      for (final ref in refs) {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        if (data == null ||
            data['uid'] != uid ||
            data['status'] != 'Returned') {
          throw StateError('Only your returned requests can be archived.');
        }
      }
      for (final ref in refs) {
        transaction.update(ref, {
          'archived': true,
          'archivedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}

```

### lib/widgets/request_scope.dart

```dart
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

```

### lib/widgets/request_widgets.dart

```dart
import 'package:flutter/material.dart';

import '../models/borrow_request.dart';
import 'app_scaffold.dart';
import 'request_scope.dart';

String requestDate(DateTime? date) => date == null
    ? 'Not scheduled'
    : '${date.month}/${date.day}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

class RequestContent extends StatefulWidget {
  const RequestContent({super.key, required this.builder});
  final Widget Function(BuildContext, List<BorrowRequest>) builder;
  @override
  State<RequestContent> createState() => _RequestContentState();
}

class _RequestContentState extends State<RequestContent> {
  Stream<List<BorrowRequest>>? _stream;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    try {
      _stream = RequestScope.watchOf(context);
    } catch (error, stack) {
      _stream = Stream<List<BorrowRequest>>.error(error, stack);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<BorrowRequest>>(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const AppScaffold(
          showBack: true,
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to load requests. Check your connection or try again later.',
              ),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const AppScaffold(
          showBack: true,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return widget.builder(context, snapshot.data!);
    },
  );
}

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.selected = false,
  });
  final BorrowRequest request;
  final VoidCallback onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) => Card(
    color: selected ? const Color(0xFFFFE8D9) : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Colors.grey),
    ),
    child: ListTile(
      onTap: onTap,
      leading: Icon(
        selected ? Icons.check_circle : Icons.devices,
        color: const Color(0xFFFF692B),
      ),
      title: Text(request.equipmentName),
      subtitle: Text(
        '${request.status}\nBorrowing: ${requestDate(request.borrowAt)}\n'
        '${request.status == 'Returned' ? 'Returned' : 'Return deadline'}: '
        '${requestDate(request.status == 'Returned' ? request.returnedAt : request.returnAt)}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class RequestLayout extends StatelessWidget {
  const RequestLayout({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => AppScaffold(
    showBack: true,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}

```

### lib/pages/user_requests_page.dart

```dart
import 'package:flutter/material.dart';

import '../widgets/request_widgets.dart';
import 'borrowing_history_page.dart';
import 'request_details_page.dart';

class UserRequestsPage extends StatefulWidget {
  const UserRequestsPage({super.key});
  @override
  State<UserRequestsPage> createState() => _UserRequestsPageState();
}

class _UserRequestsPageState extends State<UserRequestsPage> {
  String status = 'Approved';
  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final filtered = requests
          .where((r) => r.status == status && !r.archived)
          .toList();
      return RequestLayout(
        title: 'My Requests',
        children: [
          const Text('Active and upcoming borrowings'),
          Wrap(
            spacing: 8,
            children: [
              for (final value in [
                'Pending',
                'Approved',
                'Borrowed',
                'Returned',
              ])
                ChoiceChip(
                  label: Text(value),
                  selected: status == value,
                  onSelected: (_) => setState(() => status = value),
                ),
            ],
          ),
          TextButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('Borrowing History'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const BorrowingHistoryPage(),
              ),
            ),
          ),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No requests in this category.'),
            ),
          for (final request in filtered)
            RequestCard(
              request: request,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => RequestDetailsPage(requestId: request.id),
                ),
              ),
            ),
        ],
      );
    },
  );
}

```

### lib/pages/request_details_page.dart

```dart
import 'package:flutter/material.dart';

import '../widgets/request_widgets.dart';
import '../widgets/app_navigation_bar.dart';
import 'pickup_confirmation_page.dart';
import 'return_reminder_page.dart';

class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({super.key, required this.requestId});
  final String requestId;
  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final matches = requests.where((r) => r.id == requestId);
      if (matches.isEmpty) {
        return const RequestLayout(
          title: 'Request details',
          children: [Text('Request not found.')],
        );
      }
      final request = matches.first;
      return RequestLayout(
        title: 'Request details',
        children: [
          Text('Request #${request.id}'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TRANSACTION DETAILS',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Status: ${request.status}'),
                  Text('Equipment: ${request.equipmentName}'),
                  Text('Borrow: ${requestDate(request.borrowAt)}'),
                  Text('Return: ${requestDate(request.returnAt)}'),
                  Text('Purpose: ${request.purpose}'),
                  if (request.returnedAt != null)
                    Text('Returned: ${requestDate(request.returnedAt)}'),
                ],
              ),
            ),
          ),
          if (request.status == 'Approved')
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PickupConfirmationPage(requestId: requestId),
                ),
              ),
              child: const Text('Confirm pickup'),
            ),
          if (request.status == 'Borrowed') ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Pickup confirmed'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReturnReminderPage(requestId: requestId),
                ),
              ),
              child: const Text('Return reminder'),
            ),
          ],
          ElevatedButton(
            onPressed: () => AppNavigation.openHome(context),
            child: const Text('Back to Home'),
          ),
        ],
      );
    },
  );
}

```

### lib/pages/pickup_confirmation_page.dart

```dart
import 'package:flutter/material.dart';

import '../services/request_service.dart';
import '../widgets/request_widgets.dart';
import 'request_details_page.dart';
import 'user_requests_page.dart';

class PickupConfirmationPage extends StatefulWidget {
  const PickupConfirmationPage({
    super.key,
    required this.requestId,
    this.confirmPickup,
  });
  final String requestId;
  final Future<void> Function(String)? confirmPickup;
  @override
  State<PickupConfirmationPage> createState() => _PickupConfirmationPageState();
}

class _PickupConfirmationPageState extends State<PickupConfirmationPage> {
  bool saving = false;
  Future<void> confirm() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await (widget.confirmPickup ?? RequestService().confirmPickup)(
        widget.requestId,
      );
      if (!mounted) return;
      setState(() => saving = false);
      final details = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Thank you for confirming!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('View Details'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => details == true
              ? RequestDetailsPage(requestId: widget.requestId)
              : const UserRequestsPage(),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to confirm pickup. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final matches = requests.where((r) => r.id == widget.requestId);
      if (matches.isEmpty) {
        return const RequestLayout(
          title: 'Pickup confirmation',
          children: [Text('Request not found.')],
        );
      }
      final request = matches.first;
      return RequestLayout(
        title: 'Pickup confirmation',
        children: [
          Text('Request #${request.id}'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${request.equipmentName} - ${request.status}\nScheduled pickup: ${requestDate(request.borrowAt)}',
              ),
            ),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pickup status\nHave you already received this equipment?\nConfirm only after it is in your care.',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: !saving && request.status == 'Approved' ? confirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF692B),
              foregroundColor: Colors.white,
            ),
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Yes, I received it'),
          ),
          TextButton(
            onPressed: saving
                ? null
                : () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const UserRequestsPage(),
                    ),
                  ),
            child: const Text('Not Yet'),
          ),
          const Text(
            'Not Yet keeps status Approved. Confirm later to change status to Borrowed.',
          ),
        ],
      );
    },
  );
}

```

### lib/pages/return_reminder_page.dart

```dart
import 'package:flutter/material.dart';

import '../widgets/request_widgets.dart';
import 'request_details_page.dart';

class ReturnReminderPage extends StatelessWidget {
  const ReturnReminderPage({super.key, required this.requestId});
  final String requestId;
  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final matches = requests.where((r) => r.id == requestId);
      if (matches.isEmpty) {
        return const RequestLayout(
          title: 'Return Reminder',
          children: [Text('Request not found.')],
        );
      }
      final request = matches.first;
      final overdue =
          request.returnAt != null &&
          request.returnAt!.isBefore(DateTime.now());
      return RequestLayout(
        title: 'Return Reminder',
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                request.status == 'Borrowed'
                    ? '${overdue ? 'Return overdue' : 'Upcoming deadline'}\n'
                          'Please return your ${request.equipmentName} by ${requestDate(request.returnAt)}.'
                    : 'Current request status: ${request.status}',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => RequestDetailsPage(requestId: requestId),
              ),
            ),
            child: const Text('View Request'),
          ),
        ],
      );
    },
  );
}

```

### lib/pages/borrowing_history_page.dart

```dart
import 'package:flutter/material.dart';

import '../widgets/request_widgets.dart';
import 'archive_page.dart';
import 'request_details_page.dart';

class BorrowingHistoryPage extends StatelessWidget {
  const BorrowingHistoryPage({super.key});
  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final returned = requests
          .where((r) => r.status == 'Returned' && !r.archived)
          .toList();
      return RequestLayout(
        title: 'Borrowing History',
        children: [
          const Text('Your completed transactions'),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ArchivePage()),
            ),
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive'),
          ),
          if (returned.isEmpty) const Text('No completed transactions.'),
          for (final request in returned)
            RequestCard(
              request: request,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => RequestDetailsPage(requestId: request.id),
                ),
              ),
            ),
        ],
      );
    },
  );
}

```

### lib/pages/archive_page.dart

```dart
import 'package:flutter/material.dart';

import '../services/request_service.dart';
import '../widgets/request_widgets.dart';
import 'request_details_page.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key, this.archiveRequests});
  final Future<void> Function(Set<String>)? archiveRequests;
  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final selected = <String>{};
  bool saving = false;
  Future<void> archive(Set<String> eligible) async {
    final ids = selected.intersection(eligible);
    if (saving || ids.isEmpty) return;
    setState(() => saving = true);
    try {
      await (widget.archiveRequests ?? RequestService().archiveRequests)(ids);
      if (!mounted) return;
      setState(selected.clear);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Requests archived.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to archive requests. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final returned = requests.where((r) => r.status == 'Returned').toList();
      final eligible = returned
          .where((r) => !r.archived)
          .map((r) => r.id)
          .toSet();
      return RequestLayout(
        title: 'Archive',
        children: [
          const Text('Select returned transactions to archive'),
          ElevatedButton(
            onPressed: !saving && selected.intersection(eligible).isNotEmpty
                ? () => archive(eligible)
                : null,
            child: Text(saving ? 'Archiving...' : 'Archive selected'),
          ),
          if (returned.isEmpty) const Text('No returned transactions.'),
          for (final request in returned)
            Row(
              children: [
                Checkbox(
                  value: selected.contains(request.id),
                  onChanged: saving || request.archived
                      ? null
                      : (value) => setState(() {
                          if (value == true) {
                            selected.add(request.id);
                          } else {
                            selected.remove(request.id);
                          }
                        }),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (request.archived) const Text('Archived'),
                      RequestCard(
                        request: request,
                        selected: selected.contains(request.id),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                RequestDetailsPage(requestId: request.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      );
    },
  );
}

```

### test/request_pages_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_project/models/borrow_request.dart';
import 'package:mad_project/pages/user_requests_page.dart';
import 'package:mad_project/pages/pickup_confirmation_page.dart';
import 'package:mad_project/widgets/request_scope.dart';

const approved = BorrowRequest(
  id: 'r1',
  uid: 'u1',
  equipmentId: 'e1',
  equipmentName: 'Laptop',
  status: 'Approved',
  purpose: 'Coursework',
);
const returned = BorrowRequest(
  id: 'r2',
  uid: 'u1',
  equipmentId: 'e2',
  equipmentName: 'Mouse',
  status: 'Returned',
  purpose: 'Coursework',
);

Widget app(Widget page) => RequestScope(
  watch: () => Stream.value([approved, returned]),
  child: MaterialApp(home: page),
);

void main() {
  testWidgets('Filters requests and opens live request details', (
    tester,
  ) async {
    await tester.pumpWidget(app(const UserRequestsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Laptop'), findsOneWidget);
    expect(find.text('Mouse'), findsNothing);
    await tester.tap(find.text('Returned'));
    await tester.pumpAndSettle();
    expect(find.text('Mouse'), findsOneWidget);
    expect(find.text('Laptop'), findsNothing);
    await tester.tap(find.text('Mouse'));
    await tester.pumpAndSettle();
    expect(find.text('Request #r2'), findsOneWidget);
    expect(find.text('Status: Returned'), findsOneWidget);
  });

  testWidgets('Only acknowledges pickup after successful persistence', (
    tester,
  ) async {
    String? saved;
    await tester.pumpWidget(
      app(
        PickupConfirmationPage(
          requestId: 'r1',
          confirmPickup: (id) async {
            saved = id;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, I received it'));
    await tester.pumpAndSettle();
    expect(saved, 'r1');
    expect(find.text('Thank you for confirming!'), findsOneWidget);
  });

  testWidgets('Failed pickup shows error without success dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        PickupConfirmationPage(
          requestId: 'r1',
          confirmPickup: (_) async {
            throw StateError('offline');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, I received it'));
    await tester.pump();
    expect(find.text('Thank you for confirming!'), findsNothing);
    expect(
      find.text('Unable to confirm pickup. Please try again.'),
      findsOneWidget,
    );
  });
}

```

## Validation

All 13 Flutter tests passed, including three new request-flow tests. Live Firestore writes were not exercised; the existing rules deny the proposed requests collection.

## Proposed rules fragment (complete content)

```
// Proposed fragment: merge inside /databases/{database}/documents.
// Request creation, approval, inventory and return processing belong to trusted backend code.
match /requests/{requestId} {
  function ownsRequest() {
    return request.auth != null && resource.data.uid == request.auth.uid;
  }
  allow read: if ownsRequest();
  allow create, delete: if false;
  allow update: if ownsRequest() && (
    (resource.data.status == 'Approved'
      && request.resource.data.status == 'Borrowed'
      && request.resource.data.pickedUpAt == request.time
      && request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['status', 'pickedUpAt']))
    || (resource.data.status == 'Returned'
      && request.resource.data.archived == true
      && request.resource.data.archivedAt == request.time
      && request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['archived', 'archivedAt']))
  );
}

```

## Proposed navigation patch (complete content)

```diff
--- a/lib/widgets/app_navigation_bar.dart
+++ b/lib/widgets/app_navigation_bar.dart
@@ -1,11 +1,21 @@
 import 'package:flutter/material.dart';
 
 import '../home_page.dart';
+import '../pages/user_requests_page.dart';
 import '../pages/borrow_it_screen.dart';
 
 class AppNavigation {
   static const home = '/home';
   static const equipment = '/equipment';
+  static const requests = '/requests';
+
+  static void openRequests(BuildContext context) {
+    if (ModalRoute.of(context)?.settings.name == requests) return;
+    Navigator.of(context).push(MaterialPageRoute<void>(
+      settings: const RouteSettings(name: requests),
+      builder: (_) => const UserRequestsPage(),
+    ));
+  }
 
   static void openHome(BuildContext context) {
     final navigator = Navigator.of(context);
@@ -61,9 +71,7 @@
       } else if (index == 1) {
         AppNavigation.openEquipment(context);
       } else {
-        ScaffoldMessenger.of(context).showSnackBar(
-          const SnackBar(content: Text('Requests are coming soon.')),
-        );
+        AppNavigation.openRequests(context);
       }
     },
     items: const [
--- a/lib/widgets/main_drawer.dart
+++ b/lib/widgets/main_drawer.dart
@@ -112,7 +112,7 @@
             menuItem(
               icon: Icons.touch_app,
               title: 'Requests',
-              onTap: () => showComingSoon(context, 'Requests'),
+              onTap: () => navigate(context, AppNavigation.openRequests),
             ),
 
             // NOTIFICATIONS

```
