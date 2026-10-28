import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/models/match_invite.dart';
import 'package:b_ball/models/player_descriptor.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/firestore_match_service.dart';
import 'package:b_ball/paintball/paintball_game_screen.dart' show PaintballChallenge;
import 'package:b_ball/paintball/net/paintball_session.dart';

import 'package:b_ball/game/ui/common/app_avatar.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/match_state.dart';
import 'package:b_ball/paintball/logic/paintball_players.dart';

/// End-of-match card in the GameVerse result style (same as darts):
/// a glowing medallion half above the card, YOU WIN / BOT WINS, how it ended,
/// two player columns (crowned winner, hits landed, stats) and actions.
/// The screen fades it in after the death / win animations.
class PaintballResultCard extends StatelessWidget {
  final PaintballMatchState match;
  final PaintballPlayers players;
  final VoidCallback onRematch;
  final VoidCallback? onPlayFriend;
  final VoidCallback? onLobby;

  /// Online 1v1: the finished match's id. The REMATCH button then becomes
  /// the darts-style request / "WANTS A REMATCH" accept-decline swap.
  final String? onlineMatchId;

  const PaintballResultCard({
    super.key,
    required this.match,
    required this.players,
    required this.onRematch,
    this.onPlayFriend,
    this.onLobby,
    this.onlineMatchId,
  });

  static const Color _you = Color(0xFF38BDF8);
  static const Color _them = Color(0xFFF59E0B);
  static const Color _mint = Color(0xFF00FFCC);
  static const Color _red = Color(0xFFEF4444);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _subtle = Color(0xFF64748B);
  static const Color _card = Color(0xFF1E2638);

  @override
  Widget build(BuildContext context) {
    final winner = match.winner;
    final bool youWon = winner == PaintballWinner.you;
    final bool draw = winner == PaintballWinner.tie || winner == null;
    final String opp = players.opponent.name;

    final Color accent = draw ? _them : (youWon ? _mint : _red);
    final String title = draw ? 'DRAW' : (youWon ? 'YOU WIN' : '${opp.toUpperCase()} WINS');
    final IconData medal = draw
        ? Icons.handshake_rounded
        : (youWon ? Icons.emoji_events_rounded : Icons.gps_fixed_rounded);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 380,
              maxHeight: MediaQuery.sizeOf(context).height * 0.92,
            ),
            child: Container(
              width: 380,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFA111A2E), Color(0xFA0A0E1A)],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.4),
                boxShadow: [
                  BoxShadow(color: accent.withValues(alpha: 0.20), blurRadius: 40),
                  const BoxShadow(color: Color(0xCC000000), blurRadius: 28, offset: Offset(0, 14)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            shadows: [Shadow(color: accent.withValues(alpha: 0.45), blurRadius: 18)],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _howItEnded(match, opp),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _muted, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _PlayerColumn(
                          player: players.you,
                          color: _you,
                          stats: match.you,
                          roundsWon: match.youRounds,
                          hitsLanded: match.youHitsLanded,
                          crowned: youWon,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 22),
                        child: Text('VS', style: TextStyle(color: _subtle, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                      Expanded(
                        child: _PlayerColumn(
                          player: players.opponent,
                          color: _them,
                          stats: match.opponent,
                          roundsWon: match.opponentRounds,
                          hitsLanded: match.opponentHitsLanded,
                          crowned: winner == PaintballWinner.opponent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (onlineMatchId != null)
                    _OnlineRematch(matchId: onlineMatchId!, fallbackName: opp)
                  else
                    _CardButton(label: 'REMATCH', icon: Icons.replay_rounded, primary: true, onTap: onRematch),
                  if (onPlayFriend != null) ...[
                    const SizedBox(height: 10),
                    _CardButton(label: 'CHALLENGE A FRIEND', icon: Icons.people_alt_rounded, onTap: onPlayFriend!),
                  ],
                  if (onLobby != null) ...[
                    const SizedBox(height: 10),
                    _CardButton(label: 'BACK TO LOBBY', icon: Icons.grid_view_rounded, onTap: onLobby!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _howItEnded(PaintballMatchState m, String opp) {
    final score = '${m.youRounds}–${m.opponentRounds}';
    final rounds = m.roundHits.map((r) => '${r.$1}–${r.$2}').join(' · ');
    final detail = rounds.isEmpty ? '' : '\nRounds: $rounds';
    switch (m.winner) {
      case PaintballWinner.you:
        return 'You won $score on rounds.$detail';
      case PaintballWinner.opponent:
        return '$opp won $score on rounds.$detail';
      case PaintballWinner.tie:
      case null:
        return 'Level at $score after ${m.roundHits.length} rounds.$detail';
    }
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
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: 0.35), const Color(0xFF0F172A)]),
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 22)],
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}

/// One player's side: crowned avatar, name, hits landed, progress, stats.
class _PlayerColumn extends StatelessWidget {
  final PaintballPlayer player;
  final Color color;
  final PaintballPlayerState stats;
  final int roundsWon;
  final int hitsLanded;
  final bool crowned;

  const _PlayerColumn({
    required this.player,
    required this.color,
    required this.stats,
    required this.roundsWon,
    required this.hitsLanded,
    required this.crowned,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (roundsWon / PaintballK.roundsToWin).clamp(0.0, 1.0).toDouble();
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            AppAvatar(
              avatar: player.avatar,
              size: 52,
              borderColor: crowned ? const Color(0xFFF59E0B) : color.withValues(alpha: 0.6),
              borderWidth: crowned ? 2.5 : 1.5,
            ),
            if (crowned)
              const Positioned(top: -16, child: Text('👑', style: TextStyle(fontSize: 18))),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          player.name.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
        ),
        const SizedBox(height: 2),
        Text(
          '$roundsWon',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            height: 1.1,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          'ROUNDS WON',
          style: const TextStyle(color: PaintballResultCard._subtle, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: PaintballResultCard._card,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Stat(label: 'HITS LANDED', value: '$hitsLanded'),
        _Stat(label: 'ACCURACY', value: '${stats.accuracyPercent.round()}%'),
        _Stat(label: 'SHOTS', value: '${stats.shotsFired}'),
        _Stat(label: 'DODGED', value: '${stats.timesDodged}'),
        _Stat(label: 'LONGEST ALIVE', value: '${stats.longestSurvivalSeconds.round()}s'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: PaintballResultCard._subtle, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
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

  const _CardButton({required this.label, required this.icon, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary ? PaintballResultCard._you : PaintballResultCard._card,
          foregroundColor: primary ? const Color(0xFF0A0E1A) : Colors.white,
          side: primary ? null : const BorderSide(color: Color(0x2EFFFFFF)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

/// Online rematch, same flow as darts: tap REMATCH → "WAITING FOR X…" (✕ to
/// cancel). The opponent's button swaps live to "X WANTS A REMATCH!" with
/// ACCEPT / DECLINE. Accepting takes both into the new match, already READY.
class _OnlineRematch extends HookConsumerWidget {
  final String matchId;
  final String fallbackName;
  const _OnlineRematch({required this.matchId, required this.fallbackName});

  static const _mint = Color(0xFF00FFCC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = useState(false);
    final outgoingId = useState<String?>(null);
    final declined = useState(false);
    final error = useState<String?>(null);
    final entering = useState(false);

    final myUid = AuthService.instance.currentUser?.uid ?? '';
    // Read the match live: the copy the screen opened with may predate the
    // opponent joining.
    final finished = ref.watch(singleMatchProvider(matchId)).value;
    final opp = finished?.opponentPlayer(myUid);
    final oppUid = opp?.uid ?? '';
    final oppName = opp?.displayName ?? fallbackName;

    final incoming = oppUid.isEmpty
        ? null
        : (ref.watch(incomingMatchChallengesProvider).value ?? const <MatchInvite>[])
            .where((i) => i.isPending && i.hostUid == oppUid && i.game == 'paintball')
            .firstOrNull;

    final outgoing = outgoingId.value != null
        ? ref.watch(singleMatchProvider(outgoingId.value!)).value
        : null;

    void enter(String id) {
      if (entering.value) return;
      entering.value = true;
      PaintballSession.autoReady.add(id); // both agreed: skip READY
      HapticFeedback.heavyImpact();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) GoRouter.maybeOf(context)?.go('/match/$id');
      });
    }

    // They accepted our request: in we go. They declined: say so.
    useEffect(() {
      final m = outgoing;
      if (m != null && m.player2 != null) {
        enter(m.id);
      } else if (m != null && m.status == MatchStatus.declined) {
        HapticFeedback.mediumImpact();
        declined.value = true;
        outgoingId.value = null;
      }
      return null;
    }, [outgoing?.player2?.uid, outgoing?.status]);

    Widget box({required Color color, required Widget child}) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF131D31),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 1.4),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 14)],
          ),
          child: child,
        );

    final Widget body;
    if (entering.value) {
      body = box(
        color: _mint,
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _mint)),
          SizedBox(width: 10),
          Text('STARTING REMATCH…',
              style: TextStyle(color: _mint, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ]),
      );
    } else if (incoming != null) {
      body = box(
        color: _mint,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            AppAvatar(avatar: incoming.hostAvatar, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${incoming.hostName.toUpperCase()} WANTS A REMATCH!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: busy.value
                    ? null
                    : () async {
                        HapticFeedback.lightImpact();
                        await FirestoreMatchService.instance.declineMatchChallenge(
                          myUid: myUid,
                          matchId: incoming.matchId,
                          hostUid: incoming.hostUid,
                        );
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF94A3B8),
                  side: const BorderSide(color: Color(0xFF334155)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('DECLINE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: busy.value
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        busy.value = true;
                        try {
                          final user = await AuthService.instance.ensureAuthenticated();
                          final me = AuthService.instance.currentUser ??
                              UserProfile(
                                uid: user.uid,
                                displayName: user.displayName ?? 'Player',
                                avatarEmoji: PlayerDescriptor.defaultAvatar,
                              );
                          await FirestoreMatchService.instance.acceptMatchChallenge(
                            invite: incoming,
                            recipientProfile: me,
                          );
                          enter(incoming.matchId);
                        } catch (_) {
                          busy.value = false;
                          error.value = 'Couldn\'t join the rematch. Try again.';
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mint,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: busy.value
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('ACCEPT REMATCH', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
              ),
            ),
          ]),
        ]),
      );
    } else if (outgoingId.value != null) {
      body = Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0x2800FFCC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x6600FFCC)),
        ),
        child: Row(children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _mint)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('WAITING FOR ${oppName.toUpperCase()}…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _mint, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
            tooltip: 'Cancel rematch',
            onPressed: () async {
              final id = outgoingId.value;
              outgoingId.value = null;
              if (id != null) {
                await PaintballChallenge.cancelRematch(matchId: id, oppUid: oppUid, myUid: myUid);
              }
            },
          ),
        ]),
      );
    } else {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (declined.value) ...[
          Text('$oppName declined the rematch.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
        ],
        if (error.value != null) ...[
          Text(error.value!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
        ],
        _CardButton(
          label: busy.value ? 'CONNECTING…' : 'REMATCH',
          icon: Icons.replay_rounded,
          primary: true,
          onTap: () async {
            if (busy.value || finished == null || oppUid.isEmpty) return;
            busy.value = true;
            declined.value = false;
            error.value = null;
            try {
              final r = await PaintballChallenge.requestRematch(finished: finished, myUid: myUid);
              if (!context.mounted) return;
              if (r.joined) {
                enter(r.match.id); // they asked first: join theirs
              } else {
                outgoingId.value = r.match.id;
              }
            } catch (_) {
              error.value = 'Couldn\'t request a rematch. Check your connection.';
            } finally {
              busy.value = false;
            }
          },
        ),
      ]);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(
        key: ValueKey('${entering.value}${incoming?.matchId}${outgoingId.value}'),
        child: body,
      ),
    );
  }
}
