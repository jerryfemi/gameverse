import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:b_ball/archery/archery_game_screen.dart' show ArcheryChallenge;
import 'package:b_ball/darts/darts_game_screen.dart' show DartsChallenge;
import 'package:b_ball/game/match/match_config.dart';
import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/models/player_descriptor.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/firestore_match_service.dart';
import 'package:b_ball/social/models/match_summary.dart';

/// Sticky footer actions bar in [ResultsSheet] containing the primary
/// Rematch button (instant rematch) and Share button.
class ResultsFooterActions extends StatelessWidget {
  final CloudMatch match;
  final String myUid;

  const ResultsFooterActions({
    super.key,
    required this.match,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1020),
        border: Border(top: BorderSide(color: Color(0xFF1E2638), width: 1.0)),
      ),
      child: Row(
        children: [
          // REMATCH (2/3 width)
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48.0,
              child: ElevatedButton.icon(
                onPressed: () => _handleRematch(context),
                icon: const Icon(Icons.refresh_rounded, size: 18.0),
                label: Text(
                  'REMATCH',
                  style: UiFont.style(
                    size: 13.0,
                    weight: 900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 1.0,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10.0),

          // Share (1/3 width)
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 48.0,
              child: OutlinedButton.icon(
                onPressed: () => _handleShare(context),
                icon: const Icon(Icons.ios_share_rounded, size: 16.0),
                label: Text(
                  'Share',
                  style: UiFont.style(
                    size: 13.0,
                    weight: 800,
                    color: Colors.white,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2638),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF334155)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRematch(BuildContext context) async {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();

    if (match.isDarts) {
      await DartsChallenge.rematch(context, finished: match, myUid: myUid);
    } else if (match.isArchery) {
      await ArcheryChallenge.rematch(context, finished: match, myUid: myUid);
    } else {
      // Basketball / Hoops Rematch
      final user = AuthService.instance.currentUser;
      if (user != null) {
        final opp = match.opponentPlayer(myUid);
        final config = MatchConfig(
          game: match.game,
          totalRounds: match.totalRounds,
          roundDurationSeconds: match.roundDurationSeconds,
          player1Name: user.displayName,
          player1Avatar: user.avatarEmoji,
          player2Name: opp?.displayName ?? 'Opponent',
          player2Avatar: opp?.avatarEmoji ?? PlayerDescriptor.defaultAvatar,
          player2Uid: (opp != null && opp.uid.isNotEmpty) ? opp.uid : null,
        );
        final result = await FirestoreMatchService.instance.createOrJoinRematch(
          finishedMatchId: match.id,
          config: config,
          me: user,
        );
        if (context.mounted) {
          GoRouter.maybeOf(context)?.go('/match/${result.match.id}');
        }
      }
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    HapticFeedback.lightImpact();
    final gameTitle = CloudMatch.gameTitle(match.game);
    final summary = MatchSummary.fromMatch(
      match,
      AuthService.instance.currentUser?.uid ?? '',
    );
    final outcomeText = summary.didIWin == true ? 'I won' : 'Great match';
    final text =
        '🏆 $outcomeText at $gameTitle in GameVerse! Join code: ${match.joinCode}';

    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'GameVerse 1v1 $gameTitle'),
    );
  }
}
