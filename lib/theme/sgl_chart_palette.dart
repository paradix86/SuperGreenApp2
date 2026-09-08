import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:flutter/painting.dart';

/// Series colors for the environment graphs. Mid-saturation values chosen to
/// read on both the light and the dark SglColors grounds, so the bloc (which
/// has no BuildContext) can pick them statically.
class SglChartPalette {
  static const Color temperature = Color(0xFF3FB816);
  static const Color humidity = Color(0xFF4A8FC4);
  static const Color vpd = Color(0xFFD4644E);
  static const Color ventilation = Color(0xFF2AA7A0);
  static const Color light = Color(0xFFE0A32B);
  static const Color co2 = Color(0xFF8A948C);
  static const Color weight = Color(0xFF8B6BC9);

  static charts.Color chart(Color c) {
    return charts.Color(
      r: (c.r * 255).round(),
      g: (c.g * 255).round(),
      b: (c.b * 255).round(),
      a: (c.a * 255).round(),
    );
  }
}
