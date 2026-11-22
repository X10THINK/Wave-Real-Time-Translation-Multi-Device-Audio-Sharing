import '../../../core/native/wave_native.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/wave_theme.dart';
import '../../../core/ui/wave_widgets.dart';
import '../../../state/wave_scope.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final name = TextEditingController();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (name.text.isEmpty) name.text = WaveScope.of(context).displayName;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = WaveScope.of(context);
    return WavePage(
      title: 'Settings',
      subtitle: 'Your WAVE preferences',
      children: [
        WaveCapsulePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WaveLabel('Display Name'),
              WaveField(controller: name, label: 'Your name'),
              WavePrimaryButton(
                title: 'Save Name',
                onPressed: () {
                  if (name.text.trim().isEmpty ||
                      name.text.trim().length > 40) {
                    waveToast(
                      context,
                      'Enter a name between 1 and 40 characters.',
                    );
                    return;
                  }
                  state.setName(name.text);
                  waveToast(context, 'Saved to this device.');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WaveCapsulePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WaveLabel('Default Translation Language'),
              DropdownButtonFormField<String>(
                initialValue: state.defaultLanguage,
                items:
                    ['English', 'Tamil']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) {
                  if (v != null) state.setLanguage(v);
                },
              ),
              const SizedBox(height: 16),
              const WaveLabel('Default Audio Volume'),
              Slider(
                value: state.defaultVolume,
                onChanged: state.setVolume,
                activeColor: WaveColors.deepTeal,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WaveOptionTile(
          title: 'Permissions',
          subtitle: 'Manage WAVE permissions in Android Settings',
          icon: Icons.security_rounded,
          onTap: () async {
            await WaveNative.instance.openAppSettings();
          },
        ),
        WaveOptionTile(
          title: 'About WAVE',
          subtitle: 'WAVE Android local audio • Version 6.2.0',
          icon: Icons.info_outline_rounded,
          onTap:
              () => showAboutDialog(
                context: context,
                applicationName: 'WAVE',
                applicationVersion: '6.2.0 Source Edition',
                children: [
                  const Text(
                    'Local Audio Share supports Android Bluetooth and LAN transports. Live Translation AI/API is not configured. Network security and multi-device timing require further engineering validation.',
                  ),
                ],
              ),
        ),
        const WaveNote(
          'Name, language, volume and recent session history persist locally. Live native sessions run in the Android foreground service and are not silently recreated after process termination.',
        ),
      ],
    );
  }
}
