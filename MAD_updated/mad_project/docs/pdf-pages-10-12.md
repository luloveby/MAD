# PDF pages 10-12

Implemented the physical PDF pages 10-12 (boards 09-11): return reminders,
request details, borrowing history, archive selection, and notifications.
The Home notification bell opens the new notification screen. Existing page
classes, navigation, Firebase initialization, and request service are reused.
The My Requests status-tab changes are preserved.

## Automatic approval and PDF page 8

New valid submissions now save `status: Approved` and an `approvedAt` server
timestamp in the existing submission transaction. The confirmation screen shows
Approved only after that transaction succeeds. Existing Pending records are not
retroactively changed.

The Home bell listens to the user's requests. An Approved request without
`approvalReadAt` displays a red unread dot. Tapping the bell opens the newest
unread approval notice matching PDF page 8; the notice includes the pickup
schedule and Confirm pickup action. Opening the notice saves `approvalReadAt`
as a server timestamp. Other unread approvals keep the dot visible. With no unread
approvals, the bell opens the notification list. Approval entries in that list
also open the approval notice. Failed read writes show a retry action.

The updated `firestore.rules` must be deployed before using this flow in
production: new requests require Approved and a server approval timestamp;
owners may update only `approvalReadAt` when marking an approval read.
Deployment is pending Firebase CLI authentication:

```powershell
firebase login
firebase deploy --only firestore:rules --project borrowit-5e6c3
```

## Firebase data

New request document IDs are allocated as `BIT-0001`, `BIT-0002`, etc. A shared
`counters/requests` document stores `lastNumber` and `lastRequestId`. The request
and counter are saved in one Firestore transaction so simultaneous submissions
retry safely. Failed submissions do not consume a number. The counter is created
with the first successful request; no manual seed is necessary. Existing IDs
are preserved. The updated rules validate the counter and request together and
must be published by the project owner before numbered submissions can work.


All screens use `RequestScope` / `RequestService.watchRequests()` to listen to
the existing `requests` collection filtered by the signed-in user's `uid`.
Sorting and status filtering happen locally, avoiding a new composite index.
There is no new database, notification collection, package, or Firebase project.

Existing fields remain unchanged: `uid`, `equipmentId`, `equipmentName`,
`status`, `purpose`, `borrowAt`, `returnAt`, `returnedAt`, and `archived`.
Dates use Firestore timestamps. Optional event timestamps `createdAt`,
`approvedAt`, and `pickedUpAt` are supported; older documents can omit them.
Undated notifications say "Request update" rather than inventing an event time.

Notifications are in-app projections of request data, not stored notification
history or push notifications. Actionable updates have orange borders. Return
reminders appear within 24 hours of the deadline or while overdue. Deadline
screens refresh every minute while open. Returned and archived requests do not
generate active return reminders. Archiving hides a request from ordinary
history and keeps it accessible through Archive.

Archiving uses the existing transaction, which validates ownership and Returned
status before saving. Only successful writes clear the selection; failures allow
retry. Return confirmation is unresolved in the PDF. This implementation does
not let a student mark equipment returned; history reflects the Returned status
recorded by the equipment office.

## Verification

`flutter test` covers the existing app plus request timestamp parsing, deadline
logic, stream updates, notification navigation, history filtering, archive
success/failure, and narrow phone layouts. Screen baselines are in `test/goldens`.
`flutter analyze --no-pub` checks the source for integration issues.

Live verification could not run because this environment has no saved Firebase
CLI login. No deployed rules or production records were changed. After logging
in to Firebase with access to the existing project, run:

```powershell
node scripts/verify_request_firebase.cjs
```

This read-only check verifies the user-filtered query, compares deployed rules
with `firestore.rules`, and tests ownership isolation and disallowed transitions
with the isolated Rules API. It does not write test records to production.
The saved CLI credential uses administrative access for query checks; the Rules
API tests separately evaluate the student ownership conditions. Actual signed-in
device reads and archive writes still require an authorized end-to-end check.
