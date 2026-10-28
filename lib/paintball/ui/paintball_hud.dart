import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/archery/ui/archery_match_bar.dart' show ArcheryMatchesButton, ArcheryRoundButton;
import 'package:b_ball/game/ui/common/app_avatar.dart';
import 'package:b_ball/game/ui/common/lobby_pill.dart';
import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/match_state.dart';
import 'package:b_ball/paintball/logic/paintball_players.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/social/ui/in_game/in_game_h2h_overlay.dart';
import 'package:b_ball/social/ui/in_game/in_game_h2h_panel.dart';
import 'package:b_ball/social/ui/in_game/opponent_badge_social.dart';

/// Paintball HUD, in the same family as the darts and archery HUDs:
/// - Top row: your badge (avatar, name, 3 hit pips) | clock | opponent badge.
///   Tapping a human opponent's avatar opens the head-to-head sheet.
/// - Under the top row: LOBBY pill on the left; pause, your profile drawer
///   and (solo) PLAY A FRIEND on the right, like darts.
class PaintballHudOverlay extends HookConsumerWidget {
  final PaintballMatchState match;
  final PaintballPlayers players;

  /// False in the standalone harness (no Firebase): profile / friend buttons
  /// and the head-to-head sheet are hidden.
  final bool socialReady;
  final bool isOnline;
  final String? matchId;

  final VoidCallback onPause;
  final VoidCallback onLobby;
  final VoidCallback onOpenProfile;
  final VoidCallback onPlayFriend;
  final VoidCallback? onPauseEngine;
  final VoidCallback? onResumeEngine;

  const PaintballHudOverlay({
    super.key,
    required this.match,
    required this.players,
    required this.onPause,
    required this.onLobby,
    required this.onOpenProfile,
    required this.onPlayFriend,
    this.socialReady = false,
    this.isOnline = false,
    this.matchId,
    this.onPauseEngine,
    this.onResumeEngine,
  });

  static const Color _you = Color(0xFF38BDF8);
  static const Color _them = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h2h = useState<InGameH2HState>(InGameH2HState.closed);
    final user = socialReady ? ref.watch(currentUserProfileProvider).value : null;
    final bool humanOpponent =
        socialReady && !players.opponent.isBot && (players.opponent.uid?.isNotEmpty ?? false);

    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _PlayerBadge(
                            player: players.you,
                            hitsTaken: match.you.hitsTaken,
                            roundsWon: match.youRounds,
                            color: _you,
                            isLeft: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ClockPill(match: match),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: _PlayerBadge(
                            player: players.opponent,
                            hitsTaken: match.opponent.hitsTaken,
                            roundsWon: match.opponentRounds,
                            color: _them,
                            isLeft: false,
                            social: socialReady,
                            matchId: matchId,
                            onAvatarTap: humanOpponent
                                ? () => h2h.value = InGameH2HState.peek
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LobbyPill(onTap: onLobby, compact: true),
                    const Spacer(),
                    Column(
                      children: [
                        ArcheryRoundButton(
                          icon: Icons.pause_rounded,
                          tooltip: 'Pause',
                          onTap: onPause,
                        ),
                        if (socialReady) ...[
                          const SizedBox(height: 8),
                          ArcheryMatchesButton(onTap: onOpenProfile),
                          if (!isOnline) ...[
                            const SizedBox(height: 8),
                            ArcheryRoundButton(
                              icon: Icons.people_alt_rounded,
                              tooltip: 'Challenge a friend',
                              onTap: onPlayFriend,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (h2h.value != InGameH2HState.closed)
          InGameH2HOverlay(
            state: h2h.value,
            myUid: user?.uid ?? '',
            myAvatar: user?.avatarEmoji,
            opponentUid: players.opponent.uid ?? '',
            opponentName: players.opponent.name,
            opponentAvatar: players.opponent.avatar,
            defaultGame: 'paintball',
            onExpand: () => h2h.value = InGameH2HState.full,
            onCollapse: () => h2h.value = InGameH2HState.closed,
            onClose: () => h2h.value = InGameH2HState.closed,
            isOnline: isOnline,
            onPauseEngine: onPauseEngine,
            onResumeEngine: onResumeEngine,
          ),
      ],
    );
  }
}

/// Avatar + name + 3 hit pips in a frosted badge (darts score-badge style).
/// A pip empties each time this player is hit.
class _PlayerBadge extends StatelessWidget {
  final PaintballPlayer player;
  final int hitsTaken;
  final int roundsWon;
  final Color color;
  final bool isLeft;
  final bool social;
  final String? matchId;
  final VoidCallback? onAvatarTap;

  const _PlayerBadge({
    required this.player,
    required this.hitsTaken,
    this.roundsWon = 0,
    required this.color,
    required this.isLeft,
    this.social = false,
    this.matchId,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final left = (PaintballK.hitsToWin - hitsTaken).clamp(0, PaintballK.hitsToWin);
    Widget avatar = AppAvatar(avatar: player.avatar, size: 34, borderColor: color.withValues(alpha: 0.7));
    if (!isLeft && social) {
      avatar = OpponentBadgeSocial(
        opponentUid: player.uid,
        opponentName: player.name,
        matchId: matchId,
        isBot: player.isBot,
        isLeft: false,
        badgeBorderColor: const Color(0xFF0F172A),
        onAvatarTap: onAvatarTap,
        child: avatar,
      );
    }
    final pips = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(PaintballK.hitsToWin, (i) {
        final full = isLeft ? i < left : i >= PaintballK.hitsToWin - left;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 9,
          height: 9,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: full ? color : const Color(0xFF334155),
            boxShadow: full ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 5)] : null,
          ),
        );
      }),
    );
    // Rounds won (best of 3): two small amber marks.
    final roundStars = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(PaintballK.roundsToWin, (i) {
        final won = i < roundsWon;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(won ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 12, color: won ? const Color(0xFFF59E0B) : const Color(0xFF475569)),
        );
      }),
    );
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isLeft) ...[roundStars, const SizedBox(width: 6)],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Text(
                player.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiFont.style(size: 10.5, weight: 800, color: Colors.white, letterSpacing: 0.8),
              ),
            ),
            if (isLeft) ...[const SizedBox(width: 6), roundStars],
          ],
        ),
        const SizedBox(height: 4),
        pips,
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xCC0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [avatar, const SizedBox(width: 8), text]
            : [text, const SizedBox(width: 8), avatar],
      ),
    );
  }
}

class _ClockPill extends StatelessWidget {
  final PaintballMatchState match;
  const _ClockPill({required this.match});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color = Colors.white;
    switch (match.phase) {
      case PaintballMatchPhase.intro:
      case PaintballMatchPhase.countdown:
        final c = match.countdownRemaining.ceil();
        text = c > 0 ? '$c' : 'GO!';
        color = const Color(0xFFFACC15);
      case PaintballMatchPhase.live:
        final secs = match.timeRemaining.ceil();
        text = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
        if (secs <= 10) color = const Color(0xFFEF4444);
      case PaintballMatchPhase.suddenDeath:
        text = 'SUDDEN DEATH';
        color = const Color(0xFFEF4444);
      case PaintballMatchPhase.roundOver:
        text = 'ROUND ${match.round}';
        color = const Color(0xFFF59E0B);
      case PaintballMatchPhase.gameOver:
        text = 'FINAL';
        color = const Color(0xFF94A3B8);
    }
    final inPlay = match.phase != PaintballMatchPhase.gameOver &&
        match.phase != PaintballMatchPhase.roundOver;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xCC0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: UiFont.style(size: 16, weight: 900, color: color, letterSpacing: 1.1),
          ),
          if (inPlay)
            Text(
              'ROUND ${match.round} OF ${PaintballK.maxRounds}',
              style: UiFont.style(size: 8.5, weight: 800, color: const Color(0xFF94A3B8), letterSpacing: 1.0),
            ),
        ],
      ),
    );
  }
}
