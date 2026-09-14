import 'package:flutter/material.dart';
import 'package:super_green_app/theme.dart';

class IconCheckbox extends StatelessWidget {
  const IconCheckbox({
    Key? key,
    required this.icon,
    required this.checked,
    required this.size,
  }) : super(key: key);

  final IconData icon;
  final bool checked;
  final double size;

  get asset {
    return Opacity(opacity: checked ? 1.0 : 0.5, child: Icon(icon, size: size));
  }

  double get finalContainerSize {
    return size + 12.0;
  }

  Color get strokeColor {
    return checked ? SglColor.green : SglColor.inactive;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: finalContainerSize,
      height: finalContainerSize,
      decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: strokeColor, width: 3.0)
      ),
      child: Center(
        child: asset,
      ),
    );
  }
}