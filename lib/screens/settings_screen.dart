import 'package:flutter/material.dart';
import 'package:tuna/icons/myna_outlined.dart';
import 'package:tuna/icons/myna_solid.dart';
import 'package:tuna/models/app_settings.dart';
import 'package:tuna/screens/instruments_screen.dart';
import 'package:tuna/widgets/top_bar.dart';
import 'package:tuna/widgets/tuna_scope.dart';

const inTuneColors = <int>[
  0xFF2ECC71,
  0xFF3498DB,
  0xFFF1C40F,
  0xFFE67E22,
  0xFFE74C3C,
  0xFF9B59B6,
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = TunaScope.of(context);
    final settings = app.settings;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              title: 'Settings',
              buttonRight: IconButton(
                icon: const Icon(MynaSolid.xHexagon),
                tooltip: 'Close',
                onPressed: () => Navigator.maybePop(context),
              ),
              buttonLeft: IconButton(
                icon: const Icon(MynaOutlined.infoHexagon),
                tooltip: 'About',
                onPressed: () => _showAbout(context),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  const _SectionLabel('Tuning'),
                  _SliderRow(
                    label: 'Tolerance',
                    valueLabel: '±${settings.tuningTolerance.toStringAsFixed(1)}¢',
                    child: Slider(
                      value: settings.tuningTolerance.clamp(0.5, 15),
                      min: 0.5,
                      max: 15,
                      onChanged: app.setTolerance,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('In-tune color'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final hex in inTuneColors)
                        _ColorSwatch(
                          color: Color(hex),
                          selected: settings.colorOnCorrectHex == hex,
                          onPressed: () => app.setInTuneColor(hex),
                        ),
                    ],
                  ),
                  const _SectionLabel('Device'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Keep device awake'),
                    subtitle: const Text('The screen stays on while Tuna is open.'),
                    value: settings.keepDeviceAwake,
                    onChanged: app.setKeepAwake,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Save energy'),
                    subtitle: const Text(
                      'Slows tuner updates and skips the full-screen beat flash.',
                    ),
                    value: settings.saveEnergy,
                    onChanged: app.setSaveEnergy,
                  ),
                  const _SectionLabel('Metronome'),
                  const Text('Tick sound'),
                  const SizedBox(height: 8),
                  SegmentedButton<TickSoundType>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      foregroundColor: Colors.black,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                    ),
                    segments: [
                      for (final sound in TickSoundType.values)
                        ButtonSegment(
                          value: sound,
                          label: Text(sound.displayName),
                        ),
                    ],
                    selected: {settings.tickSound},
                    onSelectionChanged: (selection) {
                      app.setTickSound(selection.first);
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => app.engine.preview(),
                      child: const Text('Preview tick'),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Flash on beat'),
                    subtitle: const Text(
                      'Uses the in-tune color. Save energy turns this into the beat dots only.',
                    ),
                    value: settings.flashOnBeat,
                    onChanged: app.setFlashOnBeat,
                  ),
                  const _SectionLabel('Instruments'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Arrange tunings'),
                    subtitle: const Text('Show, hide, and reorder guitar and ukulele tunings.'),
                    trailing: const Icon(MynaSolid.list, color: Colors.black),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/instruments',
                        arguments: const InstrumentRouteArgs(editing: true),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tuna'),
          content: const Text('Tuner and metronome\nVersion 0.2.0'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.4,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final Widget child;

  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(valueLabel),
          ],
        ),
        child,
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'In-tune color',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black,
              width: selected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
