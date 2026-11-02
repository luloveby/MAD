import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;
  final bool showCancel;
  final String cancelText;
  final VoidCallback? onCancel;
  final bool large;

  const CustomDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
    this.showCancel = false,
    this.cancelText = 'Cancel',
    this.onCancel,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: large ? 20 : 35),
      child: Container(
        width: large ? 380 : 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFF5722), Color(0xFFF58220)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // BLACK HEADER
            Container(
              height: large ? 56 : 45,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF202020),
                borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: large ? 17 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // ORANGE BODY
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    textAlign: large ? TextAlign.center : TextAlign.start,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: large ? 18 : 13,
                      height: large ? 1.35 : null,
                    ),
                  ),

                  SizedBox(height: large ? 32 : 45),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (showCancel) ...[
                        _dialogButton(
                          cancelText,
                          onCancel ?? () => Navigator.pop(context),
                          large: large,
                        ),
                        const SizedBox(width: 7),
                      ],
                      _dialogButton(confirmText, onConfirm, large: large),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogButton(
    String text,
    VoidCallback onPressed, {
    bool large = false,
  }) {
    return SizedBox(
      width: large ? 92 : 76,
      height: large ? 38 : 27,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF202020),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: large ? 13 : 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
