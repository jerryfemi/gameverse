import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../game/audio/audio_engine.dart';

/// Modal dialog/bottom sheet for managing background music, sound effects, and master mute.
class SoundSettingsModal extends HookWidget {
  const SoundSettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SoundSettingsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicVol = useState(AudioEngine.musicVolume);
    final sfxVol = useState(AudioEngine.sfxVolume);
    final isMuted = useState(AudioEngine.isMuted);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 24.0,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Sound Settings',
                  style: UiFont.style(
                    size: 18.0,
                    weight: 900,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF94A3B8), size: 20.0),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Master Mute Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Mute All Audio',
                style: UiFont.style(
                  size: 14.5,
                  weight: 700,
                  color: Colors.white,
                ),
              ),
              value: isMuted.value,
              activeThumbColor: const Color(0xFFEF4444),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                isMuted.value = val;
                AudioEngine.isMuted = val;
              },
            ),
            const Divider(color: Color(0xFF1E2638), height: 16.0),

            // Music Volume
            Text(
              'Music Volume (${(musicVol.value * 100).round()}%)',
              style: UiFont.style(
                size: 13.0,
                weight: 700,
                color: const Color(0xFF94A3B8),
              ),
            ),
            Slider(
              value: musicVol.value,
              activeColor: const Color(0xFF00FFCC),
              inactiveColor: const Color(0xFF1E2638),
              onChanged: isMuted.value
                  ? null
                  : (val) {
                      musicVol.value = val;
                      AudioEngine.musicVolume = val;
                    },
            ),
            const SizedBox(height: 8.0),

            // Sound Effects Volume
            Text(
              'Sound Effects (${(sfxVol.value * 100).round()}%)',
              style: UiFont.style(
                size: 13.0,
                weight: 700,
                color: const Color(0xFF94A3B8),
              ),
            ),
            Slider(
              value: sfxVol.value,
              activeColor: const Color(0xFF38BDF8),
              inactiveColor: const Color(0xFF1E2638),
              onChanged: isMuted.value
                  ? null
                  : (val) {
                      sfxVol.value = val;
                      AudioEngine.sfxVolume = val;
                    },
            ),
          ],
        ),
      ),
    );
  }
}
