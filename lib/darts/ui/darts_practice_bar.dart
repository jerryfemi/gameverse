import 'package:flutter/material.dart';

import 'package:b_ball/darts/darts_game.dart';

/// Top bar shown instead of the match HUD while practising free throws:
/// a PRACTICE pill with the darts in this set and the running set score,
/// plus the pause button (Back to match lives in the pause menu).
class DartsPracticeBar extends StatelessWidget {
  final DartsGame game;
  final VoidCallback onOpenPause;

  const DartsPracticeBar({
    super.key,
    required this.game,
    required this.onOpenPause,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10.0,
      left: 16.0,
      right: 16.0,
      child: Row(
        children: [
          Container(
            height: 36.0,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: const Color(0xE00F172A),
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(color: const Color(0x8038BDF8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PRACTICE',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 10.0),
                ValueListenableBuilder<int>(
                  valueListenable: game.practiceSetDarts,
                  builder: (_, thrown, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < 3; i++)
                        Container(
                          width: 6.0,
                          height: 14.0,
                          margin: const EdgeInsets.only(right: 3.0),
                          decoration: BoxDecoration(
                            color: i < 3 - thrown
                                ? const Color(0xFFFFFFFF)
                                : const Color(0x33FFFFFF),
                            borderRadius: BorderRadius.circular(3.0),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                ValueListenableBuilder<int>(
                  valueListenable: game.practiceSetPoints,
                  builder: (_, pts, _) => Text(
                    '$pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Material(
            color: const Color(0xE00F172A),
            shape: const CircleBorder(
              side: BorderSide(color: Color(0x2EFFFFFF)),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onOpenPause,
              child: const SizedBox(
                width: 40.0,
                height: 40.0,
                child: Icon(
                  Icons.pause_rounded,
                  color: Colors.white,
                  size: 20.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
