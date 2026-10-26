import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_ball/game/audio/audio_engine.dart';

/// Sound settings card matching Design Templates 21 and 22:
/// - SFX & Music volume sliders with mute buttons
/// - Track picker / ambience label
/// - Optional streak FX switch & graphics quality row
class PauseSoundCard extends StatelessWidget {
  final Color accentColor;
  final String? trackName;
  final VoidCallback? onCycleTrack;
  final Widget? streakFxRow;
  final Widget? graphicsRow;

  const PauseSoundCard({
    super.key,
    required this.accentColor,
    this.trackName,
    this.onCycleTrack,
    this.streakFxRow,
    this.graphicsRow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Column(
        children: [
          // Effects Slider Row
          _buildVolumeRow(
            icon: Icons.volume_up_rounded,
            offIcon: Icons.volume_off_rounded,
            label: 'Effects',
            enabledNotifier: AudioEngine.sfxEnabledNotifier,
            volumeNotifier: AudioEngine.sfxVolumeNotifier,
            onToggle: AudioEngine.setSfxEnabled,
            onChanged: (v) => AudioEngine.sfxVolume = v,
          ),
          const SizedBox(height: 6.0),

          // Music Slider Row
          _buildVolumeRow(
            icon: Icons.music_note_rounded,
            offIcon: Icons.music_off_rounded,
            label: 'Music',
            enabledNotifier: AudioEngine.musicEnabledNotifier,
            volumeNotifier: AudioEngine.musicVolumeNotifier,
            onToggle: AudioEngine.setMusicEnabled,
            onChanged: (v) => AudioEngine.musicVolume = v,
          ),

          // Track row
          if (trackName != null) ...[
            const Divider(color: Color(0xFF1E2638), height: 16.0),
            InkWell(
              onTap: onCycleTrack,
              borderRadius: BorderRadius.circular(8.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Text(
                      'Track',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$trackName  >',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Optional Streak FX row
          if (streakFxRow != null) ...[
            const Divider(color: Color(0xFF1E2638), height: 16.0),
            streakFxRow!,
          ],

          // Optional Graphics row
          if (graphicsRow != null) ...[
            const Divider(color: Color(0xFF1E2638), height: 16.0),
            graphicsRow!,
          ],
        ],
      ),
    );
  }

  Widget _buildVolumeRow({
    required IconData icon,
    required IconData offIcon,
    required String label,
    required ValueNotifier<bool> enabledNotifier,
    required ValueNotifier<double> volumeNotifier,
    required Future<void> Function(bool enabled) onToggle,
    required ValueChanged<double> onChanged,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: enabledNotifier,
      builder: (context, isOn, _) {
        return ValueListenableBuilder<double>(
          valueListenable: volumeNotifier,
          builder: (context, volume, _) {
            final activeColor = isOn ? accentColor : const Color(0xFFEF4444);
            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    unawaited(onToggle(!isOn));
                  },
                  child: Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor.withValues(alpha: 0.16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isOn ? icon : offIcon,
                      size: 16.0,
                      color: activeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                SizedBox(
                  width: 52.0,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3.5,
                      activeTrackColor: activeColor,
                      inactiveTrackColor: const Color(0xFF1E2638),
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                    ),
                    child: Slider(
                      value: isOn ? volume.clamp(0.0, 1.0) : 0.0,
                      onChanged: isOn ? onChanged : null,
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
                SizedBox(
                  width: 36.0,
                  child: Text(
                    isOn ? '${(volume * 100).round()}%' : 'OFF',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isOn ? const Color(0xFFCBD5E1) : const Color(0xFFEF4444),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
