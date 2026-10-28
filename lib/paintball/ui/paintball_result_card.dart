import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  const PaintballResultCard({
    super.key,
    required this.match,
    required this.players,
    required this.onRematch,
    this.onPlayFriend,
    this.onLobby,
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
    final String title = draw
        ? 'DRAW'
        : (youWon ? 'YOU WIN' : '${opp.toUpperCase()} WINS');
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
                border: Border.all(
                  color: accent.withValues(alpha: 0.45),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.20),
                    blurRadius: 40,
                  ),
                  const BoxShadow(
                    color: Color(0xCC000000),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: Center(
                      child: _Medallion(icon: medal, color: accent),
                    ),
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
                            shadows: [
                              Shadow(
                                color: accent.withValues(alpha: 0.45),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _howItEnded(match, opp),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
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
                        child: Text(
                          'VS',
                          style: TextStyle(
                            color: _subtle,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
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
                  _CardButton(
                    label: 'REMATCH',
                    icon: Icons.replay_rounded,
                    primary: true,
                    onTap: onRematch,
                  ),
                  if (onPlayFriend != null) ...[
                    const SizedBox(height: 10),
                    _CardButton(
                      label: 'CHALLENGE A FRIEND',
                      icon: Icons.people_alt_rounded,
                      onTap: onPlayFriend!,
                    ),
                  ],
                  if (onLobby != null) ...[
                    const SizedBox(height: 10),
                    _CardButton(
                      label: 'BACK TO LOBBY',
                      icon: Icons.grid_view_rounded,
                      onTap: onLobby!,
                    ),
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
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.35), const Color(0xFF0F172A)],
        ),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 22),
        ],
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
    final progress = (roundsWon / PaintballK.roundsToWin)
        .clamp(0.0, 1.0)
        .toDouble();
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            AppAvatar(
              avatar: player.avatar,
              size: 52,
              borderColor: crowned
                  ? const Color(0xFFF59E0B)
                  : color.withValues(alpha: 0.6),
              borderWidth: crowned ? 2.5 : 1.5,
            ),
            if (crowned)
              const Positioned(
                top: -16,
                child: Text('👑', style: TextStyle(fontSize: 18)),
              ),
          ],
        ),
        const SizedBox(height: 8),
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
          style: const TextStyle(
            color: PaintballResultCard._subtle,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
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
        _Stat(
          label: 'LONGEST ALIVE',
          value: '${stats.longestSurvivalSeconds.round()}s',
        ),
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
          Text(
            label,
            style: const TextStyle(
              color: PaintballResultCard._subtle,
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
              fontSize: 12,
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
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary
              ? PaintballResultCard._you
              : PaintballResultCard._card,
          foregroundColor: primary ? const Color(0xFF0A0E1A) : Colors.white,
          side: primary ? null : const BorderSide(color: Color(0x2EFFFFFF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
