import 'package:flutter/material.dart';

/// Standard Secondary/Outlined Button (Section 56).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Text(text),
        ],
      ),
    );
  }
}
