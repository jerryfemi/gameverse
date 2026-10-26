import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_ball/game/physics/shot_difficulty.dart';
import 'package:b_ball/game/ui/common/difficulty_stepped_slider.dart';

/// Hoops match settings card: Rounds, Shot Clock, and Difficulty slider.
class MatchHoopsSettingsCard extends StatelessWidget {
  final int rounds;
  final int duration;
  final ShotDifficulty difficulty;
  final ValueChanged<int> onRoundsChanged;
  final ValueChanged<int> onDurationChanged;
  final ValueChanged<ShotDifficulty> onDifficultyChanged;

  const MatchHoopsSettingsCard({
    super.key,
    required this.rounds,
    required this.duration,
    required this.difficulty,
    required this.onRoundsChanged,
    required this.onDurationChanged,
    required this.onDifficultyChanged,
  });

  static const Color hoopsColor = Color(0xFFF59E0B);
  static const List<int> roundOptions = [2, 3, 4];
  static const List<int> durationOptions = [30, 60];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Column(
        children: [
          // Rounds Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Row(
              children: [
                const Text(
                  'Rounds',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Row(
                  children: roundOptions.map((r) {
                    final isSel = rounds == r;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onRoundsChanged(r);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 6.0),
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: isSel ? hoopsColor : const Color(0xFF1E2638),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          '$r',
                          style: TextStyle(
                            color: isSel ? const Color(0xFF0A0E1A) : Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E2638), height: 1.0),

          // Shot Clock Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Row(
              children: [
                const Text(
                  'Shot clock',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Row(
                  children: durationOptions.map((d) {
                    final isSel = duration == d;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onDurationChanged(d);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 6.0),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: isSel ? hoopsColor : const Color(0xFF1E2638),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          '${d}s',
                          style: TextStyle(
                            color: isSel ? const Color(0xFF0A0E1A) : Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E2638), height: 1.0),

          // Difficulty Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Difficulty',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      difficulty.label,
                      style: const TextStyle(
                        color: Color(0xFF00FFCC),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                DifficultySteppedSlider(
                  value: difficulty,
                  onChanged: onDifficultyChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
