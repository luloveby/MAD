import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/equipment_item.dart';
import '../utils/philippine_time.dart';
import '../widgets/app_scaffold.dart';
import '../services/request_service.dart';
import '../widgets/invalid_time_request_dialog.dart';
import 'request_submitted_page.dart';

class BorrowRequestPage extends StatefulWidget {
  const BorrowRequestPage({super.key, required this.item, this.submitRequest});
  final EquipmentItem item;
  final Future<String> Function({
    required EquipmentItem item,
    required DateTime borrowAt,
    required DateTime returnAt,
    required String purpose,
  })?
  submitRequest;

  @override
  State<BorrowRequestPage> createState() => _BorrowRequestPageState();
}

class _BorrowRequestPageState extends State<BorrowRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _purpose = TextEditingController();
  late DateTime _needed;
  late DateTime _return;
  String? _scheduleError;
  bool _scheduleValidated = false;
  bool _submitting = false;

  bool _outsideHours(DateTime value) {
    value = PhilippineTime.wallClock(value);
    final minutes = value.hour * 60 + value.minute;
    return minutes < 8 * 60 || minutes > 17 * 60;
  }

  @override
  void initState() {
    super.initState();
    final now = PhilippineTime.wallClock(DateTime.now());
    _needed = PhilippineTime.fromWallClock(
      now.year,
      now.month,
      now.day + 1,
      10,
    );
    _return = PhilippineTime.fromWallClock(
      now.year,
      now.month,
      now.day + 2,
      15,
    );
  }

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool returnDate, required bool time}) async {
    if (_submitting) return;
    final value = PhilippineTime.wallClock(returnDate ? _return : _needed);
    DateTime? result;
    if (time) {
      final selected = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(value),
      );
      if (selected != null) {
        result = PhilippineTime.fromWallClock(
          value.year,
          value.month,
          value.day,
          selected.hour,
          selected.minute,
        );
      }
    } else {
      final now = PhilippineTime.wallClock(DateTime.now());
      final first = DateTime(now.year, now.month, now.day);
      final selected = await showDatePicker(
        context: context,
        initialDate:
            DateTime(value.year, value.month, value.day).isBefore(first)
            ? first
            : DateTime(value.year, value.month, value.day),
        firstDate: first,
        lastDate: DateTime(now.year + 5, 12, 31),
      );
      if (selected != null) {
        result = PhilippineTime.fromWallClock(
          selected.year,
          selected.month,
          selected.day,
          value.hour,
          value.minute,
        );
      }
    }
    if (!mounted || result == null) return;
    setState(() {
      if (returnDate) {
        _return = result!;
      } else {
        _needed = result!;
      }
      _scheduleError = null;
    });
  }

  void _submit() {
    if (_submitting) return;
    final valid = _formKey.currentState!.validate();
    final invalidNeededTime = _outsideHours(_needed);
    final invalidReturnTime = _outsideHours(_return);
    setState(() {
      _scheduleValidated = true;
      _scheduleError = !_needed.isAfter(DateTime.now())
          ? 'Choose a future borrowing date and time.'
          : !_return.isAfter(_needed)
          ? 'Return date and time must be after borrowing.'
          : invalidNeededTime || invalidReturnTime
          ? 'Please select a valid time between 8:00am and 5:00 pm'
          : null;
    });
    if (_scheduleError != null) {
      showDialog<bool>(
        context: context,
        builder: (_) => InvalidTimeRequestDialog(message: _scheduleError!),
      ).then((confirmed) {
        if (confirmed == true && mounted) {
          _pick(
            returnDate: !invalidNeededTime && invalidReturnTime,
            time: invalidNeededTime || invalidReturnTime,
          );
        }
      });
      return;
    }
    if (!valid) return;
    showDialog<bool>(
      context: context,
      builder: (_) => const InvalidTimeRequestDialog(
        confirmation: true,
        message: 'Are you sure you want to submit this request?',
      ),
    ).then((confirmed) async {
      if (confirmed != true || !mounted) return;
      setState(() => _submitting = true);
      try {
        final service = widget.submitRequest == null ? RequestService() : null;
        final id = await (widget.submitRequest ?? service!.submitRequest)(
          item: widget.item,
          borrowAt: _needed,
          returnAt: _return,
          purpose: _purpose.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => RequestSubmittedPage(
              item: widget.item,
              needed: _needed,
              returnAt: _return,
              purpose: _purpose.text.trim(),
              requestId: id,
              status: service?.lastSubmissionStatus ?? 'Approved',
            ),
          ),
        );
      } catch (error) {
        if (!mounted) return;
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is RequestSubmissionException
                  ? 'Unable to submit request. ${error.message}'
                  : error is FirebaseException &&
                        error.code == 'permission-denied'
                  ? 'Unable to submit request. Firebase denied access for this account. Verify the account and published rules for borrowit-5e6c3.'
                  : error is StateError
                  ? 'Unable to submit request. ${error.message}'
                  : 'Unable to submit request. Check your connection, then try again.',
            ),
          ),
        );
      }
    });
  }

  Widget _pickerField(
    String label,
    DateTime value, {
    bool returnDate = false,
    bool time = false,
  }) {
    final hasError =
        time &&
        _scheduleValidated &&
        (_outsideHours(value) ||
            (returnDate
                ? !_return.isAfter(_needed)
                : !_needed.isAfter(DateTime.now())));
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: hasError ? Colors.red : Colors.grey,
        width: hasError ? 2 : 1,
      ),
    );
    final text = time
        ? TimeOfDay.fromDateTime(PhilippineTime.wallClock(value))
              .format(context)
        : MaterialLocalizations.of(context)
              .formatMediumDate(PhilippineTime.wallClock(value));
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _pick(returnDate: returnDate, time: time),
            child: InputDecorator(
              decoration: InputDecoration(
                border: outline,
                enabledBorder: outline,
                focusedBorder: outline,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                suffixIcon: Icon(
                  time ? Icons.access_time : Icons.calendar_today,
                  size: 20,
                ),
              ),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Borrow request',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.item.category} – ${widget.item.eligiblePrograms}',
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFF6525),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.item.name} – ${widget.item.status}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
                _pickerField('DATE NEEDED', _needed),
                _pickerField('BORROWING TIME', _needed, time: true),
                _pickerField('EXPECTED RETURN DATE', _return, returnDate: true),
                _pickerField(
                  'EXPECTED RETURN TIME',
                  _return,
                  returnDate: true,
                  time: true,
                ),
                if (_scheduleError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _scheduleError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const Text(
                  'PURPOSE OF BORROWING',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                TextSelectionTheme(
                  data: const TextSelectionThemeData(
                    cursorColor: Color(0xFFFF692B),
                    selectionColor: Color(0x40FF692B),
                    selectionHandleColor: Color(0xFFFF692B),
                  ),
                  child: TextFormField(
                    controller: _purpose,
                    cursorColor: const Color(0xFFFF692B),
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 2000,
                    enabled: !_submitting,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Purpose',
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF692B),
                          width: 2,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter the purpose of borrowing.'
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5424), Color(0xFFF58B21)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed:
                          !_submitting && widget.item.status == 'Available'
                          ? _submit
                          : null,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _submitting ? 'Submitting…' : 'Submit Request',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF757575),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
