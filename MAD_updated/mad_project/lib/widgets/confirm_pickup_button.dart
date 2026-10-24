import 'package:flutter/material.dart';

class ConfirmPickupButton extends StatelessWidget {
  const ConfirmPickupButton({
    super.key,
    required this.onPressed,
    this.label = 'Confirm pickup',
  });
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF541D), Color(0xFFEB8424)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: TextStyle(
              fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(label),
        ),
      ),
    ),
  );
}
