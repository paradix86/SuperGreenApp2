import 'package:flutter/material.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/theme/sgl_typography.dart';

/// One plain-language explanation for a value shown in the app.
class SglExplanation {
  final String title;
  final String body;

  const SglExplanation(this.title, this.body);
}

/// Central place for "what does this number mean" texts, keyed by a short id.
/// Keep them short: what it measures, the unit, what a good value looks like.
class SglExplanations {
  static const Map<String, SglExplanation> _all = {
    'temp': SglExplanation('Temperature',
        'Air temperature inside the box, read by the SHT sensor. Most plants are happy between 20 and 28 °C (68–82 °F) with the lights on, a few degrees lower at night.'),
    'rh': SglExplanation('Relative humidity',
        'How much water the air holds, in % of what it could hold at this temperature. Seedlings like 65–75 %, vegetative plants 50–65 %, flowering plants 40–50 % to avoid mould.'),
    'vpd': SglExplanation('VPD',
        'Vapour pressure deficit, in kPa: how hard the air pulls water out of the leaves. It combines temperature and humidity. Around 0.8–1.2 kPa is comfortable; below 0.5 the plant hardly transpires, above 1.5 it dries out.'),
    'co2': SglExplanation('CO2',
        'Carbon dioxide in the box, in parts per million. Outdoor air is about 420 ppm. Only shown when a CO2 sensor is connected.'),
    'weight': SglExplanation('Weight',
        'Reading of the scale connected to the controller. Useful to see the pot drying between waterings. Only shown when a scale is connected.'),
    'range3h': SglExplanation('3 h range',
        'Lowest and highest value seen in the last 3 hours, from the readings the app polls every 15 seconds while it is open.'),
    'ventilation': SglExplanation('Ventilation',
        'Duty cycle of the blower (exhaust fan) in %, 0 % = off, 100 % = full speed. In automatic mode the controller raises it when temperature or humidity exceed the target.'),
    'light': SglExplanation('Light',
        'Average dimming of the LED channels assigned to this box, in %. It follows the light schedule and the dim you set.'),
    'led_dim': SglExplanation('LED dim',
        'Brightness of the LED channels assigned to this box, in %. 100 % is the full power the driver can give.'),
    'blower': SglExplanation('Blower',
        'Duty cycle of the exhaust fan right now, in %. The controller computes it from the fan settings (min/max and the sensor it follows).'),
    'schedule': SglExplanation('Schedule',
        'Daily light timer. The lights turn on and off at these times, in the controller\'s clock. Typical: 18 h on for vegetative growth, 12 h on for flowering.'),
    'wifi': SglExplanation('Wi-Fi',
        'Whether the controller is connected to your home Wi-Fi. When it is not, the app can only reach it through the controller\'s own access point.'),
    'mqtt': SglExplanation('MQTT',
        'Connection to the SuperGreenLab cloud broker, used for remote control and for the sensor history graphs. Not needed for local control.'),
    'uptime': SglExplanation('Uptime', 'Time since the controller last booted.'),
    'restarts': SglExplanation('Restarts',
        'How many times the controller booted since it was first set up. Counts power cycles, firmware updates and crashes.'),
    'ota': SglExplanation('OTA', 'State of the over-the-air firmware update: idle, downloading, or done.'),
    'clock': SglExplanation('Clock',
        'Whether the controller got the time from the internet (NTP). The light schedule depends on it.'),
    'reset': SglExplanation('Reset',
        'Why the controller last rebooted: power-on (normal), software (update or restart), watchdog or panic (a crash), brownout (the power supply dipped).'),
    'flash': SglExplanation('Flash',
        'Space used by the settings and the web dashboard on the controller\'s flash memory.'),
    'heap': SglExplanation('Free heap',
        'RAM the firmware still has available. It should stay well above 8 KB; a value that keeps dropping over days points to a memory leak.'),
  };

  static SglExplanation? of(String key) => _all[key];
}

/// Small (i) icon. Tapping it opens a bottom sheet with the explanation for
/// [infoKey]. Renders nothing when the key has no explanation.
class SglInfoButton extends StatelessWidget {
  final String infoKey;
  final double size;
  final Color? color;

  const SglInfoButton(this.infoKey, {Key? key, this.size = 16, this.color}) : super(key: key);

  static void show(BuildContext context, String infoKey) {
    final SglExplanation? e = SglExplanations.of(infoKey);
    if (e == null) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        final SglColors c = context.sgl;
        final TextTheme t = Theme.of(context).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WHAT IS THIS', style: SglTextStyles.eyebrow.copyWith(color: c.ink3)),
              const SizedBox(height: 6),
              Text(e.title, style: t.titleLarge?.copyWith(color: c.ink)),
              const SizedBox(height: 10),
              Text(e.body, style: t.bodyMedium?.copyWith(color: c.ink2, height: 1.4)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (SglExplanations.of(infoKey) == null) {
      return const SizedBox();
    }
    return InkWell(
      onTap: () => show(context, infoKey),
      borderRadius: BorderRadius.circular(size),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(Icons.info_outline, size: size, color: color ?? context.sgl.ink3),
      ),
    );
  }
}
