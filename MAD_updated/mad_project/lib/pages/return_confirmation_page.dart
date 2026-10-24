import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/request_service.dart';
import '../widgets/confirm_pickup_button.dart';
import '../widgets/request_widgets.dart';
import '../widgets/transaction_widgets.dart';
import 'request_details_page.dart';
import 'user_requests_page.dart';

class ReturnConfirmationPage extends StatefulWidget {
  const ReturnConfirmationPage({super.key, required this.requestId});
  final String requestId;

  @override
  State<ReturnConfirmationPage> createState() => _ReturnConfirmationPageState();
}

class _ReturnConfirmationPageState extends State<ReturnConfirmationPage> {
  Uint8List? _photo;
  bool _saving = false;

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 45,
      maxWidth: 900,
      maxHeight: 900,
    );
    final bytes = await image?.readAsBytes();
    if (bytes != null && mounted) setState(() => _photo = bytes);
  }

  Future<void> _confirmReturn() async {
    if (_saving || _photo == null) return;
    setState(() => _saving = true);
    try {
      final encoded = base64Encode(_photo!);
      final photoData = 'data:image/jpeg;base64,$encoded';
      if (photoData.length > 750000) {
        throw StateError('Please choose a smaller photo.');
      }
      await RequestService().confirmReturn(
        widget.requestId,
        returnConditionPhotoUrl: photoData,
      );
      if (!mounted) return;
      final viewDetails = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Return confirmed'),
          content: const Text('Thank you for confirming that you returned the item.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('View Details'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => viewDetails == true
              ? RequestDetailsPage(requestId: widget.requestId)
              : const UserRequestsPage(),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to confirm return. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => RequestContent(
    builder: (context, requests) {
      final matches = requests.where((r) => r.id == widget.requestId);
      if (matches.isEmpty) {
        return const TransactionLayout(
          title: 'Return confirmation',
          subtitle: '',
          children: [Text('Request not found.')],
        );
      }
      final request = matches.first;
      return TransactionLayout(
        title: 'Return confirmation',
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
                  'Return deadline: ${transactionDate(request.returnAt)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          TransactionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Return status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Have you already returned this equipment?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Confirm only after you have handed it back to the equipment office.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                ),
              ],
            ),
          ),
          TransactionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Item condition upon return',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (_photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      _photo!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _choosePhoto,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Take or upload return photo'),
                  ),
                if (_photo != null)
                  TextButton.icon(
                    onPressed: _saving ? null : _choosePhoto,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake or choose another'),
                  ),
              ],
            ),
          ),
          ConfirmPickupButton(
            label: _saving ? 'Saving return...' : 'Yes, I returned it',
            onPressed: !_saving && request.status == 'Borrowed' && _photo != null
                ? _confirmReturn
                : null,
          ),
          TransactionButton(
            label: 'Not Yet',
            onPressed: _saving
                ? null
                : () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => RequestDetailsPage(requestId: widget.requestId),
                    ),
                  ),
          ),
        ],
      );
    },
  );
}
