// lib/widgets/custom_divider.dart
import 'package:flutter/material.dart';

class CustomDivider extends StatelessWidget {
  final Color color;
  final double thickness;
  final double indent;
  final double endIndent;

  const CustomDivider({
    this.color = Colors.lightBlueAccent,
    this.thickness = 1.5,
    this.indent = 16.0,
    this.endIndent = 16.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: indent),
      child: Divider(
        color: color,
        thickness: thickness,
        endIndent: endIndent,
      ),
    );
  }
}
