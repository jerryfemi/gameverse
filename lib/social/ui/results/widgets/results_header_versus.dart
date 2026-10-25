import 'package:flutter/material.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/social/models/match_summary.dart';
import 'package:b_ball/social/ui/common/crown_avatar.dart';

/// Crowned 68px avatars versus header row in [ResultsSheet].
class ResultsHeaderVersus extends StatelessWidget {
  final MatchSummary summary;

  const ResultsHeaderVersus({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CrownAvatar(
          avatar: summary.me.avatar,
          size: 68.0,
          crowned: summary.didIWin == true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'VS',
            style: UiFont.style(
              size: 14.0,
              weight: 900,
              color: const Color(0xFF64748B),
              letterSpacing: 1.5,
            ),
          ),
        ),
        CrownAvatar(
          avatar: summary.opponent.avatar,
          size: 68.0,
          crowned: summary.didIWin == false,
        ),
      ],
    );
  }
}
