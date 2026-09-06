import 'package:flutter/material.dart';

class SuperAlanGreenLabLogo extends StatelessWidget {
  final double width;
  final double height;
  final Color textColor;
  final Color greenColor;
  final TextAlign textAlign;

  const SuperAlanGreenLabLogo({
    Key? key,
    required this.width,
    required this.height,
    this.textColor = Colors.black,
    this.greenColor = const Color(0xff3bb30b),
    this.textAlign = TextAlign.left,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: 120,
      fontWeight: FontWeight.w900,
      height: 0.9,
      letterSpacing: -2.5,
      color: textColor,
    );
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: _crossAxisAlignment(textAlign),
          children: [
            Text('SUPER', textAlign: textAlign, style: baseStyle),
            Text('ALAN', textAlign: textAlign, style: baseStyle),
            Text('GREEN',
                textAlign: textAlign,
                style: baseStyle.copyWith(color: greenColor)),
            Text('LAB', textAlign: textAlign, style: baseStyle),
          ],
        ),
      ),
    );
  }

  CrossAxisAlignment _crossAxisAlignment(TextAlign align) {
    if (align == TextAlign.center) {
      return CrossAxisAlignment.center;
    }
    if (align == TextAlign.right || align == TextAlign.end) {
      return CrossAxisAlignment.end;
    }
    return CrossAxisAlignment.start;
  }
}
