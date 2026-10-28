import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/firestore_match_service.dart';
import 'package:b_ball/social/ui/tiles/widgets/active_match_invite_card.dart';
import 'package:b_ball/social/ui/tiles/widgets/active_match_their_turn_card.dart';
import 'package:b_ball/social/ui/tiles/widgets/active_match_your_turn_card.dart';

export 'package:b_ball/social/ui/tiles/widgets/active_match_invite_card.dart';
export 'package:b_ball/social/ui/tiles/widgets/active_match_score_row.dart';
export 'package:b_ball/social/ui/tiles/widgets/active_match_their_turn_card.dart';
export 'package:b_ball/social/ui/tiles/widgets/active_match_your_turn_card.dart';

/// Card widget for active matches adhering to Artboard 10 of GameVerse design.
///
/// Built with flutter_hooks + hooks_riverpod:
/// 1. Your Turn: Mint glow, "YOUR TURN" filled pill, game action CTA.
/// 2. Waiting On Them: Dark card, amber "THEIR TURN" pill, lead narrative, "Watch live".
/// 3. Invite Not Joined: Dark card, slate "NOT JOINED" pill, code copy with confirmation, cancel.
class ActiveMatchTile extends HookConsumerWidget {
  final CloudMatch match;
  final String? myUid;
  final VoidCallback? onPlay;

  const ActiveMatchTile({
    super.key,
    required this.match,
    this.myUid,
    this.onPlay,
  });

  void _navigateToMatch(BuildContext context) {
    HapticFeedback.mediumImpact();
    if (onPlay != null) {
      onPlay!();
    } else {
      GoRouter.maybeOf(context)?.go('/match/${match.id}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeCopied = useState(false);
    final copyResetTimer = useRef<Timer?>(null);

    useEffect(() {
      return () => copyResetTimer.value?.cancel();
    }, const []);

    void copyJoinCode() {
      HapticFeedback.lightImpact();
      Clipboard.setData(ClipboardData(text: match.joinCode));
      codeCopied.value = true;
      copyResetTimer.value?.cancel();
      copyResetTimer.value = Timer(const Duration(seconds: 2), () {
        codeCopied.value = false;
      });
    }

    final effectiveUid =
        myUid ?? AuthService.instance.currentUser?.uid ?? '';
    final isInvite =
        match.status == MatchStatus.waitingForOpponent || match.player2 == null;
    // Paintball is live (no turns): always the "rejoin" card.
    final isMyTurn = !isInvite && (match.isPaintball || match.isMyTurn(effectiveUid));

    Future<void> leave() async {
      HapticFeedback.mediumImpact();
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF131826),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
            side: const BorderSide(color: Color(0xFF2E3954), width: 1.2),
          ),
          title: Text('Leave this match?',
              style: UiFont.style(size: 16.0, weight: 900, color: Colors.white)),
          content: Text(
            'The match ends for both of you and counts as a forfeit. It stays in your history.',
            style: UiFont.style(size: 13.0, weight: 500, color: const Color(0xFF94A3B8), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: Text('CANCEL', style: UiFont.style(size: 12.0, weight: 700, color: const Color(0xFF94A3B8))),
            ),
            TextButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: Text('LEAVE', style: UiFont.style(size: 12.0, weight: 800, color: const Color(0xFFF87171))),
            ),
          ],
        ),
      );
      if (ok != true) return;
      // Forfeit keeps the match in both histories (status forfeited).
      await FirestoreMatchService.instance.forfeitMatch(
        matchId: match.id,
        forfeiterUid: effectiveUid,
        winnerUid: match.opponentPlayer(effectiveUid)?.uid ?? '',
      );
    }

    if (isInvite) {
      return ActiveMatchInviteCard(
        match: match,
        effectiveUid: effectiveUid,
        codeCopied: codeCopied.value,
        onCopy: copyJoinCode,
      );
    } else if (isMyTurn) {
      return ActiveMatchYourTurnCard(
        match: match,
        effectiveUid: effectiveUid,
        onPlay: () => _navigateToMatch(context),
        onLeave: leave,
      );
    } else {
      return ActiveMatchTheirTurnCard(
        match: match,
        effectiveUid: effectiveUid,
        onWatchLive: () => _navigateToMatch(context),
        onLeave: leave,
      );
    }
  }
}
