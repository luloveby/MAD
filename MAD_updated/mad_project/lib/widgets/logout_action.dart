import 'package:flutter/material.dart';

import '../dialog.dart';
import '../services/auth_service.dart';

/// Shared confirmation, sign-out, error handling and return to login.
Future<void> confirmLogout(
  BuildContext context, {
  Future<void> Function()? signOut,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => CustomDialog(
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmText: 'Log Out',
      showCancel: true,
      onConfirm: () => Navigator.pop(dialogContext, true),
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await (signOut ?? AuthService().logout)();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to log out. Please try again.')),
    );
  }
}
