import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../dialog.dart';

import '../services/request_service.dart';
import '../widgets/request_widgets.dart';
import '../widgets/transaction_widgets.dart';
import '../widgets/confirm_pickup_button.dart';
import 'request_details_page.dart';
import 'user_requests_page.dart';

class PickupConfirmationPage extends StatefulWidget {
  const PickupConfirmationPage({
    super.key,
    required this.requestId,
    this.confirmPickup,
    this.pickPhoto,
  });
  final String requestId;
  final Future<void> Function(String)? confirmPickup;
  final Future<Uint8List?> Function()? pickPhoto;
  @override
  State<PickupConfirmationPage> createState() => _PickupConfirmationPageState();
}

class _PickupConfirmationPageState extends State<PickupConfirmationPage> {
  bool saving = false;
  Uint8List? photo;

  Future<void> choosePhoto() async {
    final selected = await (widget.pickPhoto ?? _pickPhoto)();
    if (selected != null && mounted) setState(() => photo = selected);
  }

  Future<Uint8List?> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Take a photo'), onTap: () => Navigator.pop(context, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Choose from gallery'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ]),
      ),
    );
    if (source == null) return null;
    final image = await ImagePicker().pickImage(source: source, imageQuality: 45, maxWidth: 900, maxHeight: 900);
    return image?.readAsBytes();
  }

  Future<void> confirm() async {
    if (saving || (photo == null && widget.confirmPickup == null)) return;
    setState(() => saving = true);
    try {
      if (widget.confirmPickup != null) {
        await widget.confirmPickup!(widget.requestId);
      } else {
        final encoded = base64Encode(photo!);
        final photoData = 'data:image/jpeg;base64,$encoded';
        if (photoData.length > 750000) {
          throw StateError('Please choose a smaller photo.');
        }
        await RequestService().confirmPickup(
          widget.requestId,
          conditionPhotoUrl: photoData,
        );
      }
      if (!mounted) return;
      setState(() => saving = false);
      final details = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomDialog(
          title: 'Confirmation',
          message: 'Thank you for confirming!',
          showCancel: true,
          cancelText: 'View Details',
          onCancel: () => Navigator.pop(context, true),
          confirmText: 'Close',
          onConfirm: () => Navigator.pop(context, false),
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
      return TransactionLayout(
        title: 'Pickup confirmation',
        subtitle: 'REQUEST #${request.id}',
        children: [
          TransactionPanel(
            color: const Color(0xFFFF692B),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${request.equipmentName} - ${request.status}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Scheduled pickup: ${transactionDate(request.borrowAt)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const TransactionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  'Have you already received this equipment?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Confirm only after it is in your care.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TransactionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Item condition upon borrowing',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      photo!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: saving ? null : choosePhoto,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Take or upload item photo'),
                  ),
                if (photo != null)
                  TextButton.icon(
                    onPressed: saving ? null : choosePhoto,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake or choose another'),
                  ),
              ],
            ),
          ),
          ConfirmPickupButton(
            onPressed: !saving &&
                    request.status == 'Approved' &&
                    (photo != null || widget.confirmPickup != null)
                ? confirm
                : null,
            label: saving ? 'Saving photo...' : 'Yes, I received it',
          ),
          TransactionButton(
            label: 'Not Yet',
            onPressed: saving
                ? null
                : () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const UserRequestsPage(),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFBDBDBD),
              border: Border.all(color: const Color(0xFF888888)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              request.status == 'Approved'
                  ? 'Not Yet keeps status Approved. Confirm later to change status to Borrowed.'
                  : 'Current status: ${request.status}. View My Requests for the latest details.',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Color(0xFF444444),
              ),
            ),
          ),
        ],
      );
    },
  );
}
