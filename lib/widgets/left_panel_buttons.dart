import 'package:flutter/material.dart';

class LeftPanelButtonWidget extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Function() onPressed;

  const LeftPanelButtonWidget({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          size: 40,
          color: color,
        ),
      ),
    );
  }
}