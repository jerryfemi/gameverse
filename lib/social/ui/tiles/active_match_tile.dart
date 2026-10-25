import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/services/auth_service.dart';
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
    final isMyTurn = !isInvite && match.isMyTurn(effectiveUid);

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
      );
    } else {
      return ActiveMatchTheirTurnCard(
        match: match,
        effectiveUid: effectiveUid,
        onWatchLive: () => _navigateToMatch(context),
      );
    }
  }
}
