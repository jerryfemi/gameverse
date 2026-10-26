import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/basketball_game.dart';
import 'package:b_ball/game/match/match_session.dart';
import 'package:b_ball/game/ui/common/inline_feedback.dart';
import 'package:b_ball/game/ui/match/podium/podium_action_buttons.dart';
import 'package:b_ball/game/ui/match/podium/podium_avatars_row.dart';
import 'package:b_ball/game/ui/match/podium/podium_score_matrix.dart';
import 'package:b_ball/game/ui/match/podium/podium_stats_comparison.dart';
import 'package:b_ball/game/ui/match/podium/podium_trophy_header.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/models/friend_profile.dart';
import 'package:b_ball/models/match_invite.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/firestore_match_service.dart';

/// Grand celebration podium overlay matching Design Template 18:
/// - Floating circular trophy badge
/// - Glowing "YOU WIN" header
/// - Head-to-Head avatars with crowns and giant score numerals
/// - Per-round score breakdown matrix
/// - Match shooting statistics comparison table
/// - REMATCH primary button and BACK TO SOLO with countdown
/// - Responsive FittedBox scaling (< 250 lines)
class MatchWinnerPodiumOverlay extends HookConsumerWidget {
  final BasketballGame game;
  final MatchSession session;

  const MatchWinnerPodiumOverlay({
    super.key,
    required this.game,
    required this.session,
  });

  Future<void> _handleCloseOrDismiss(BuildContext context) async {
    game.exitToSoloMode();
  }

  Future<void> _handleInstantRematch(
    BuildContext context,
    ValueNotifier<String?> rematchError,
    ValueNotifier<bool> isRematching,
    ValueNotifier<String?> outgoingMatchId,
    ValueNotifier<bool> oppDeclined,
  ) async {
    if (isRematching.value) return;
    HapticFeedback.mediumImpact();
    rematchError.value = null;
    oppDeclined.value = false;
    isRematching.value = true;
    final profile = AuthService.instance.currentUser;
    final myUid = profile?.uid ?? '';

    final opponent = session.player2;
    final bool hasValidUid = opponent.id.isNotEmpty && opponent.id != 'them';
    final opponentFriend = hasValidUid
        ? FriendProfile(
            uid: opponent.id,
            displayName: opponent.name,
            avatarEmoji: opponent.avatar,
            addedAt: DateTime.now().millisecondsSinceEpoch,
          )
        : null;

    try {
      final config = MatchConfig(
        totalRounds: session.totalRounds,
        roundDurationSeconds: session.config.roundDurationSeconds,
        difficulty: session.config.difficulty,
        player1Name: session.player1.name,
        player1Avatar: session.player1.avatar,
        player2Name: opponent.name,
        player2Avatar: opponent.avatar,
        player2Uid: opponent.id.isNotEmpty ? opponent.id : null,
        opponentFriend: opponentFriend,
      );

      final userProfile = profile ??
          UserProfile(
            uid: myUid,
            displayName: session.player1.name,
            avatarEmoji: session.player1.avatar,
          );

      final String? finishedId = session.cloudMatchId;
      final ({CloudMatch match, bool joined}) result = finishedId != null
          ? await FirestoreMatchService.instance.createOrJoinRematch(
              finishedMatchId: finishedId,
              config: config,
              me: userProfile,
            )
          : (
              match: await FirestoreMatchService.instance.createMatch(
                config: config,
                player1Profile: userProfile,
              ),
              joined: false,
            );

      final newMatch = result.match;
      outgoingMatchId.value = newMatch.id;

      if (result.joined) {
        if (context.mounted) {
          game.startCloudMatch(newMatch, myUid);
        }
      } else {
        if (context.mounted) isRematching.value = false;
      }
    } catch (e) {
      if (context.mounted) {
        isRematching.value = false;
        rematchError.value = InlineErrorPanel.friendlyMessage(
          e,
          fallback: 'Could not send rematch challenge.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRematching = useState<bool>(false);
    final rematchError = useState<String?>(null);
    final outgoingMatchId = useState<String?>(null);
    final oppDeclined = useState<bool>(false);
    final isEnteringArena = useState<bool>(false);

    final outgoingMatch = outgoingMatchId.value != null
        ? ref.watch(singleMatchProvider(outgoingMatchId.value!)).value
        : null;

    useEffect(() {
      final m = outgoingMatch;
      if (m != null && m.player2 != null && m.status == MatchStatus.active) {
        HapticFeedback.heavyImpact();
        isEnteringArena.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            final profile = AuthService.instance.currentUser;
            game.startCloudMatch(m, profile?.uid ?? '');
          }
        });
      } else if (m != null && m.status == MatchStatus.declined) {
        HapticFeedback.mediumImpact();
        oppDeclined.value = true;
        outgoingMatchId.value = null;
      }
      return null;
    }, [outgoingMatch?.player2?.uid, outgoingMatch?.status]);

    final opponentId = session.player2.id;
    final rematchInvite = session.isHistoryView || !session.isOnline
        ? null
        : (ref.watch(incomingMatchChallengesProvider).value ?? const <MatchInvite>[])
            .where((i) => i.isPending && i.hostUid == opponentId)
            .firstOrNull;

    final bool liveEnd = !session.isHistoryView && session.cloudMatchId != null;
    final bool oppLeft = session.forfeitWinner != null;
    final backIn = useState<int>(oppLeft ? 10 : 45);
    final holdCountdown = useRef(false);
    holdCountdown.value = rematchInvite != null ||
        isRematching.value ||
        rematchError.value != null ||
        outgoingMatchId.value != null ||
        isEnteringArena.value;

    useEffect(() {
      if (!liveEnd) return null;
      final t = Timer.periodic(const Duration(seconds: 1), (t) {
        if (holdCountdown.value) return;
        backIn.value--;
        if (backIn.value <= 0) {
          t.cancel();
          if (context.mounted) _handleCloseOrDismiss(context);
        }
      });
      return t.cancel;
    }, [liveEnd]);

    final winner = session.overallWinner;
    final isTie = session.isTie;
    final isP1Winner = winner == session.player1;

    final Color bannerColor = isTie
        ? const Color(0xFFF59E0B)
        : (isP1Winner ? const Color(0xFF22C55E) : const Color(0xFF38BDF8));

    final String winnerDeclaration = isTie || winner == null
        ? 'MATCH TIED!'
        : (session.isOnline && isP1Winner ? 'YOU WIN' : '${winner.name.toUpperCase()} WINS');

    final maxH = MediaQuery.sizeOf(context).height * 0.92;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 360.0, maxHeight: maxH),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1424),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0xCC000000), blurRadius: 36.0, offset: Offset(0, 14)),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PodiumTrophyHeader(
                    session: session,
                    bannerColor: bannerColor,
                    winnerDeclaration: winnerDeclaration,
                    isTie: isTie,
                    onClose: () => _handleCloseOrDismiss(context),
                  ),
                  const SizedBox(height: 16.0),

                  PodiumAvatarsRow(
                    session: session,
                    isP1Winner: isP1Winner,
                    isTie: isTie,
                  ),
                  const SizedBox(height: 14.0),

                  PodiumScoreMatrix(session: session),
                  const SizedBox(height: 10.0),

                  PodiumStatsComparison(session: session),
                  const SizedBox(height: 16.0),

                  if (rematchError.value != null) ...[
                    InlineErrorPanel(
                      title: 'REMATCH UNAVAILABLE',
                      message: rematchError.value!,
                      onDismiss: () => rematchError.value = null,
                    ),
                    const SizedBox(height: 10.0),
                  ],

                  PodiumActionButtons(
                    accentColor: bannerColor,
                    isRematching: isRematching.value,
                    onRematch: () => _handleInstantRematch(
                      context,
                      rematchError,
                      isRematching,
                      outgoingMatchId,
                      oppDeclined,
                    ),
                    onClose: () => _handleCloseOrDismiss(context),
                    countdownSeconds: liveEnd ? backIn.value : null,
                    totalCountdown: oppLeft ? 10 : 45,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
