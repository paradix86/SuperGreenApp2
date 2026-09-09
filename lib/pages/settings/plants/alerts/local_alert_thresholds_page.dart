import 'package:flutter/material.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/theme/sgl_typography.dart';
import 'package:super_green_app/widgets/sgl/sgl_card.dart';
import 'package:super_green_app/widgets/appbar.dart';

class LocalAlertThresholdsPage extends StatefulWidget {
  final Plant plant;

  const LocalAlertThresholdsPage({required this.plant, Key? key}) : super(key: key);

  @override
  _LocalAlertThresholdsPageState createState() => _LocalAlertThresholdsPageState();
}

class _LocalAlertThresholdsPageState extends State<LocalAlertThresholdsPage> {
  late double _tempMin;
  late double _tempMax;
  late double _humiMin;
  late double _humiMax;

  @override
  void initState() {
    super.initState();
    _tempMin = 18.0;
    _tempMax = 28.0;
    _humiMin = 40.0;
    _humiMax = 75.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SGLAppBar('Temperature & humidity alerts'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SglCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Temperature (°C)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildRangeSlider('Min', _tempMin, 0, 50, (v) => setState(() => _tempMin = v)),
                const SizedBox(height: 16),
                _buildRangeSlider('Max', _tempMax, 0, 50, (v) => setState(() => _tempMax = v)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SglCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Humidity (%)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildRangeSlider('Min', _humiMin, 0, 100, (v) => setState(() => _humiMin = v)),
                const SizedBox(height: 16),
                _buildRangeSlider('Max', _humiMax, 0, 100, (v) => setState(() => _humiMax = v)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saveLimits,
            child: const Text('Save thresholds'),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSlider(String label, double value, double min, double max, Function(double) onChanged) {
    final SglColors c = context.sgl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text('${value.toStringAsFixed(1)}', style: SglTextStyles.reading.copyWith(color: c.accent, fontSize: 18)),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          divisions: ((max - min) * 2).toInt(),
        ),
      ],
    );
  }

  void _saveLimits() {
    // TODO: Save to AppDB local alert preferences (plant_id: temp_min, temp_max, humi_min, humi_max)
    Navigator.pop(context, true);
  }
}
