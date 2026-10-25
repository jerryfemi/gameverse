import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/ui/common/app_avatar.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/models/match_invite.dart';
import 'package:b_ball/models/player_descriptor.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/firestore_match_service.dart';
import 'package:b_ball/darts/darts_constants.dart';
import 'package:b_ball/darts/darts_game_screen.dart';
import 'package:b_ball/darts/state/darts_match_notifier.dart';
import 'package:b_ball/darts/state/darts_match_state.dart';
import 'package:b_ball/darts/state/darts_players.dart';
import 'package:b_ball/social/ui/results/results_sheet.dart';

/// End-of-match card for Darts 301 (solo vs the bot, or a live 1v1).
///
/// - A medallion and the result ("YOU WIN", "DARTBOT WINS", "DRAW") with
///   one line on how it was decided.
/// - Both players side by side: avatar (winner crowned), points left, and a
///   bar showing how much of the 301 they knocked off.
/// - Three quick stats each: 3-dart average, best turn, tons (100+ turns).
/// - REMATCH, then CHALLENGE A FRIEND (solo) or BACK TO SOLO (online).
/// - Seamless inline rematch: no popup lobby modals, instant auto-entry
///   upon opponent acceptance.
class DartsResultCard extends HookConsumerWidget {
  final VoidCallback onRematch;
  final VoidCallback? onPlayFriend;

  /// Live 1v1: name the opponent instead of the bot, and relabel the buttons.
  final bool online;

  /// The finished match details when in online mode.
  final CloudMatch? finishedMatch;

  /// Current user's UID when in online mode.
  final String? myUid;

  const DartsResultCard({
    super.key,
    required this.onRematch,
    this.onPlayFriend,
    this.online = false,
    this.finishedMatch,
    this.myUid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(dartsMatchProvider);
    final players = ref.watch(dartsPlayersProvider);
    if (!match.matchOver) return const SizedBox.shrink();

    // ── Online Rematch Reactive State ─────────────────────────────────────
    final isCreatingOrJoining = useState(false);
    final outgoingMatchId = useState<String?>(null);
    final rematchDeclined = useState(false);
    final rematchError = useState<String?>(null);
    final isStartingArena = useState(false);

    final effectiveUid = myUid ?? AuthService.instance.currentUser?.uid ?? '';
    final oppPlayer = finishedMatch?.opponentPlayer(effectiveUid);
    final String oppUid = oppPlayer?.uid ?? '';
    final String oppName = oppPlayer?.displayName ?? players.opponent.name;

    // 1. Reactive check: did opponent send a rematch challenge?
    final incomingChallenges = online && oppUid.isNotEmpty
        ? (ref.watch(incomingMatchChallengesProvider).value ?? const <MatchInvite>[])
        : const <MatchInvite>[];
    final incomingRematch = incomingChallenges
        .where((i) =>
            i.isPending &&
            i.hostUid == oppUid &&
            (i.isDarts || i.game == 'darts' || i.game.isEmpty))
        .firstOrNull;

    // 2. Stream outgoing match to detect when opponent joins or declines
    final outgoingMatch = outgoingMatchId.value != null
        ? ref.watch(singleMatchProvider(outgoingMatchId.value!)).value
        : null;

    // Auto-enter arena as soon as opponent joins Player 1's created room
    useEffect(() {
      final m = outgoingMatch;
      if (m != null && m.player2 != null && !isStartingArena.value) {
        isStartingArena.value = true;
        HapticFeedback.heavyImpact();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            GoRouter.maybeOf(context)?.go('/match/${m.id}');
          }
        });
      } else if (m != null && m.status == MatchStatus.declined) {
        HapticFeedback.mediumImpact();
        rematchDeclined.value = true;
        outgoingMatchId.value = null;
      }
      return null;
    }, [outgoingMatch?.player2?.uid, outgoingMatch?.status]);

    final int winner = match.winner ?? 0; // 1 you, -1 opponent, 0 draw
    final bool youWon = winner == 1;
    final bool draw = winner == 0;
    final String opp = players.opponent.name;

    final Color accent = draw
        ? const Color(DartsK.accentP2)
        : (youWon ? const Color(DartsK.accentMint) : const Color(DartsK.accentRed));
    final String title =
        draw ? 'DRAW' : (youWon ? 'YOU WIN' : '${opp.toUpperCase()} WINS');
    final IconData medal = draw
        ? Icons.handshake_rounded
        : (youWon ? Icons.emoji_events_rounded : Icons.gps_fixed_rounded);

    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xB3000000))),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 18.0),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400.0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFA111A2E), Color(0xFA0A0E1A)],
                    ),
                    borderRadius: BorderRadius.circular(26.0),
                    border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.4),
                    boxShadow: [
                      BoxShadow(color: accent.withValues(alpha: 0.20), blurRadius: 40.0),
                      const BoxShadow(
                        color: Color(0xCC000000),
                        blurRadius: 28.0,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Medallion + result ─────────────────────────────
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: Center(child: _Medallion(icon: medal, color: accent)),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -18),
                        child: Column(
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: accent,
                                fontSize: 30.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                                shadows: [
                                  Shadow(color: accent.withValues(alpha: 0.45), blurRadius: 18.0),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              _howItEnded(match, winner, opp),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(DartsK.textMuted),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Players ───────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _PlayerColumn(
                              player: players.you,
                              color: const Color(DartsK.accentP1),
                              remaining: match.yourRemaining,
                              turns: match.yourTurns,
                              crowned: youWon,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 22.0),
                            child: Text(
                              'VS',
                              style: TextStyle(
                                color: Color(DartsK.textSubtle),
                                fontSize: 12.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _PlayerColumn(
                              player: players.opponent,
                              color: const Color(DartsK.accentP2),
                              remaining: match.theirRemaining,
                              turns: match.theirTurns,
                              crowned: winner == -1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22.0),

                      // ── Rematch / Actions Area ─────────────────────────
                      if (rematchError.value != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: const Color(0x28EF4444),
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(color: const Color(0x66EF4444)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 18.0, color: Color(0xFFF87171)),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  rematchError.value!,
                                  style: const TextStyle(
                                    color: Color(0xFFFCA5A5),
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16.0, color: Color(0xFF94A3B8)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => rematchError.value = null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10.0),
                      ],

                      if (isStartingArena.value) ...[
                        Container(
                          height: 48.0,
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          decoration: BoxDecoration(
                            color: const Color(0x3322C55E),
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(color: const Color(0xFF22C55E)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                                blurRadius: 16.0,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bolt_rounded, color: Color(0xFF22C55E), size: 20.0),
                              SizedBox(width: 8.0),
                              Text(
                                'STARTING REMATCH...',
                                style: TextStyle(
                                  color: Color(0xFF4ADE80),
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (incomingRematch != null) ...[
                        // Opponent wants a rematch: show vibrant prompt right here!
                        Container(
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131D31),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(color: const Color(0xFF00FFCC), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FFCC).withValues(alpha: 0.18),
                                blurRadius: 14.0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  AppAvatar(avatar: incomingRematch.hostAvatar, size: 28.0),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      '${incomingRematch.hostName.toUpperCase()} WANTS A REMATCH!',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: isCreatingOrJoining.value
                                          ? null
                                          : () async {
                                              HapticFeedback.lightImpact();
                                              await FirestoreMatchService.instance.declineMatchChallenge(
                                                myUid: effectiveUid,
                                                matchId: incomingRematch.matchId,
                                                hostUid: incomingRematch.hostUid,
                                              );
                                            },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF94A3B8),
                                        side: const BorderSide(color: Color(0xFF334155)),
                                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                      ),
                                      child: const Text(
                                        'DECLINE',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: isCreatingOrJoining.value
                                          ? null
                                          : () async {
                                              HapticFeedback.mediumImpact();
                                              isCreatingOrJoining.value = true;
                                              try {
                                                final profile = await AuthService.instance.ensureAuthenticated();
                                                final userProfile = AuthService.instance.currentUser ??
                                                    UserProfile(
                                                      uid: profile.uid,
                                                      displayName: profile.displayName ?? 'Player',
                                                      avatarEmoji: PlayerDescriptor.defaultAvatar,
                                                    );
                                                await FirestoreMatchService.instance.acceptMatchChallenge(
                                                  invite: incomingRematch,
                                                  recipientProfile: userProfile,
                                                );
                                                if (context.mounted) {
                                                  GoRouter.maybeOf(context)?.go('/match/${incomingRematch.matchId}');
                                                }
                                              } catch (e) {
                                                isCreatingOrJoining.value = false;
                                                rematchError.value = 'Failed to join rematch';
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00FFCC),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                      ),
                                      child: isCreatingOrJoining.value
                                          ? const SizedBox(
                                              width: 14.0,
                                              height: 14.0,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.0,
                                                color: Colors.black,
                                              ),
                                            )
                                          : const Text(
                                              'ACCEPT REMATCH',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else if (outgoingMatchId.value != null) ...[
                        // Player 1 waiting for opponent to accept
                        Container(
                          height: 48.0,
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          decoration: BoxDecoration(
                            color: const Color(0x2800FFCC),
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(color: const Color(0x6600FFCC)),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16.0,
                                height: 16.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Color(0xFF00FFCC),
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Text(
                                  'WAITING FOR ${oppName.toUpperCase()}...',
                                  style: const TextStyle(
                                    color: Color(0xFF00FFCC),
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18.0, color: Color(0xFF94A3B8)),
                                tooltip: 'Cancel Rematch',
                                onPressed: () async {
                                  final id = outgoingMatchId.value;
                                  outgoingMatchId.value = null;
                                  if (id != null) {
                                    await DartsChallenge.cancelRematch(
                                      matchId: id,
                                      oppUid: oppUid,
                                      myUid: effectiveUid,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ] else if (rematchDeclined.value) ...[
                        // Opponent declined rematch
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: const Color(0x28EF4444),
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(color: const Color(0x66EF4444)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 18.0, color: Color(0xFFF87171)),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  '$oppName declined the rematch.',
                                  style: const TextStyle(
                                    color: Color(0xFFFCA5A5),
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Standard Rematch Button
                        _CardButton(
                          label: isCreatingOrJoining.value
                              ? 'CONNECTING...'
                              : 'REMATCH',
                          icon: Icons.replay_rounded,
                          primary: true,
                          onTap: () async {
                            if (!online || finishedMatch == null || effectiveUid.isEmpty) {
                              onRematch();
                              return;
                            }
                            isCreatingOrJoining.value = true;
                            rematchError.value = null;
                            rematchDeclined.value = false;
                            try {
                              final result = await DartsChallenge.requestRematch(
                                finished: finishedMatch!,
                                myUid: effectiveUid,
                              );
                              if (!context.mounted) return;
                              if (result.joined) {
                                GoRouter.maybeOf(context)?.go('/match/${result.match.id}');
                                return;
                              }
                              outgoingMatchId.value = result.match.id;
                            } catch (e) {
                              rematchError.value = 'Could not request rematch. Check connection.';
                            } finally {
                              isCreatingOrJoining.value = false;
                            }
                          },
                        ),
                      ],
                      if (online && finishedMatch != null) ...[
                        const SizedBox(height: 10.0),
                        _CardButton(
                          label: 'VIEW MATCH RECAP',
                          icon: Icons.analytics_outlined,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ResultsSheet.show(context, finishedMatch!);
                          },
                        ),
                      ],
                      if (onPlayFriend != null) ...[
                        const SizedBox(height: 10.0),
                        _CardButton(
                          label: online ? 'BACK TO SOLO' : 'CHALLENGE A FRIEND',
                          icon: online ? Icons.person_rounded : Icons.people_alt_rounded,
                          onTap: onPlayFriend!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _howItEnded(DartsMatchState m, int winner, String opp) {
    if (m.forfeitWinner != null) {
      return winner == 1 ? '$opp left the match. The win is yours.' : 'You left the match.';
    }
    if (m.yourRemaining == 0 && m.theirRemaining == 0) {
      if (m.yourLastDarts == m.theirLastDarts) {
        return 'Both checked out in round ${m.round} with ${m.yourLastDarts} darts each.';
      }
      final bool you = m.yourLastDarts < m.theirLastDarts;
      return 'Both checked out in round ${m.round}. ${you ? 'You' : opp} needed fewer darts '
          '(${math.min(m.yourLastDarts, m.theirLastDarts)} vs ${math.max(m.yourLastDarts, m.theirLastDarts)}).';
    }
    if (winner == 1) return 'You checked out 301 in round ${m.round}.';
    if (winner == -1) {
      return m.theirRemaining == 0
          ? '$opp checked out 301 in round ${m.round}.'
          : 'Round ${DartsK.maxRounds} reached: fewer points left wins.';
    }
    return 'Same points left after ${DartsK.maxRounds} rounds.';
  }
}

/// Round glowing badge that sits half above the card.
class _Medallion extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _Medallion({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64.0,
      height: 64.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.35), const Color(DartsK.surfaceMid)],
        ),
        border: Border.all(color: color, width: 2.0),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 22.0)],
      ),
      child: Icon(icon, color: color, size: 30.0),
    );
  }
}

/// One player's side: avatar, name, points left, progress, quick stats.
class _PlayerColumn extends StatelessWidget {
  final DartsPlayer player;
  final Color color;
  final int remaining;
  final List<int> turns;
  final bool crowned;

  const _PlayerColumn({
    required this.player,
    required this.color,
    required this.remaining,
    required this.turns,
    required this.crowned,
  });

  @override
  Widget build(BuildContext context) {
    final int scored = DartsK.startScore - remaining;
    final double progress = (scored / DartsK.startScore).clamp(0.0, 1.0).toDouble();
    final int best = turns.isEmpty ? 0 : turns.reduce(math.max);
    final double avg = turns.isEmpty ? 0.0 : scored / turns.length;
    final int tons = turns.where((t) => t >= 100).length;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            AppAvatar(
              avatar: player.avatar,
              size: 52.0,
              borderColor: crowned ? const Color(0xFFF59E0B) : color.withValues(alpha: 0.6),
              borderWidth: crowned ? 2.5 : 1.5,
            ),
            if (crowned)
              const Positioned(
                top: -16.0,
                child: Text('👑', style: TextStyle(fontSize: 18.0)),
              ),
          ],
        ),
        const SizedBox(height: 8.0),
        Text(
          player.name.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          '$remaining',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36.0,
            fontWeight: FontWeight.w900,
            height: 1.1,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const Text(
          'LEFT',
          style: TextStyle(
            color: Color(DartsK.textSubtle),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3.0),
            child: SizedBox(
              height: 5.0,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(DartsK.surfaceCard),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10.0),
        _Stat(label: 'AVG', value: avg.toStringAsFixed(1)),
        _Stat(label: 'BEST TURN', value: '$best'),
        _Stat(label: 'TONS', value: '$tons'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(DartsK.textSubtle),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 12.0,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _CardButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.0,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        icon: Icon(icon, size: 18.0),
        label: Text(
          label,
          style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w900, letterSpacing: 1.0),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary ? const Color(DartsK.accentP1) : const Color(DartsK.surfaceCard),
          foregroundColor: primary ? const Color(DartsK.surfaceDark) : Colors.white,
          side: primary ? null : const BorderSide(color: Color(0x2EFFFFFF)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
        ),
      ),
    );
  }
}
