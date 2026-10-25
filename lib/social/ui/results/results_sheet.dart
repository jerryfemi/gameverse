import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:b_ball/archery/archery_game_screen.dart' show ArcheryChallenge;
import 'package:b_ball/darts/darts_game_screen.dart' show DartsChallenge;
import 'package:b_ball/game/match/match_config.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/models/player_descriptor.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/firestore_match_service.dart';
import 'package:b_ball/social/models/match_summary.dart';
import 'package:b_ball/social/providers/social_providers.dart';
import 'package:b_ball/social/ui/common/crown_avatar.dart';
import 'package:b_ball/social/ui/common/game_chip.dart';
import 'package:b_ball/social/ui/common/verdict_banner.dart';
import 'package:b_ball/social/ui/in_game/h2h_card.dart';
import 'package:b_ball/social/ui/results/archery_results_body.dart';
import 'package:b_ball/social/ui/results/darts_results_body.dart';
import 'package:b_ball/social/ui/results/hoops_results_body.dart';

/// Full-screen modern match recap modal sheet displaying comprehensive scores,
/// player performance analytics, and instant rematch triggers without launching Flame.
class ResultsSheet extends ConsumerWidget {
  final CloudMatch match;
  final VoidCallback? onOpenH2H;

  const ResultsSheet({super.key, required this.match, this.onOpenH2H});

  /// Displays the [ResultsSheet] modal bottom sheet.
  static Future<void> show(
    BuildContext context,
    CloudMatch match, {
    VoidCallback? onOpenH2H,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => ResultsSheet(match: match, onOpenH2H: onOpenH2H),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = AuthService.instance.currentUser?.uid ?? '';
    final summary = MatchSummary.fromMatch(match, myUid);
    final size = MediaQuery.sizeOf(context);

    return Container(
      height: size.height * 0.96,
      decoration: const BoxDecoration(
        color: Color(0xFF0B1020),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      child: Column(
        children: [
          // ── Grabber & Header ──────────────────────────────────────────────
          _buildGrabber(),
          _buildTopBar(context),

          // ── Scrollable Recap Content ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8.0),

                  // 1. Crowned Avatars Versus
                  _buildAvatarsVersus(summary),
                  const SizedBox(height: 18.0),

                  // 2. Hero Verdict Banner
                  VerdictBanner.hero(
                    win: summary.didIWin ?? false,
                    line: summary.verdictLine,
                  ),
                  const SizedBox(height: 18.0),

                  // 3. Two Comparison Score Cards
                  _buildScoreCards(summary),
                  const SizedBox(height: 20.0),

                  // 4. Game-Specific Analytics Body
                  _buildGameBody(myUid),
                  const SizedBox(height: 18.0),

                  // 5. Head-to-Head Peek Row
                  _buildH2HPeek(context, ref, summary),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),

          // ── Sticky Action Buttons ─────────────────────────────────────────
          _buildFooterActions(context, myUid),
        ],
      ),
    );
  }

  Widget _buildGrabber() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
      child: Center(
        child: Container(
          width: 38.0,
          height: 4.0,
          decoration: BoxDecoration(
            color: const Color(0x5564748B),
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final dateStr = _formatDate(
      match.updatedAt > 0 ? match.updatedAt : match.createdAt,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GameChip.fromMatch(match),
          Text(
            dateStr,
            style: UiFont.style(
              size: 12.0,
              weight: 600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFF94A3B8),
              size: 22.0,
            ),
            splashRadius: 20.0,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarsVersus(MatchSummary summary) {
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

  Widget _buildScoreCards(MatchSummary summary) {
    return Row(
      children: [
        // Left: You
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0x1A38BDF8),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0x5538BDF8), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOU',
                  style: UiFont.style(
                    size: 11.0,
                    weight: 800,
                    color: const Color(0xFF38BDF8),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2.0),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    summary.me.headline,
                    maxLines: 1,
                    style: UiFont.style(
                      size: 26.0,
                      weight: 900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Text(
                  summary.me.unit,
                  style: UiFont.style(
                    size: 11.0,
                    weight: 600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),

        // Right: Opponent
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0x1AF59E0B),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0x55F59E0B), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  summary.opponent.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiFont.style(
                    size: 11.0,
                    weight: 800,
                    color: const Color(0xFFF59E0B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2.0),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    summary.opponent.headline,
                    maxLines: 1,
                    style: UiFont.style(
                      size: 26.0,
                      weight: 900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Text(
                  summary.opponent.unit,
                  style: UiFont.style(
                    size: 11.0,
                    weight: 600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameBody(String myUid) {
    if (match.isDarts) {
      return DartsResultsBody(match: match, myUid: myUid);
    }
    if (match.isArchery) {
      return ArcheryResultsBody(match: match, myUid: myUid);
    }
    return HoopsResultsBody(match: match, myUid: myUid);
  }

  Widget _buildH2HPeek(
    BuildContext context,
    WidgetRef ref,
    MatchSummary summary,
  ) {
    final h2h = ref.watch(headToHeadProvider(summary.opponent.uid));

    final String leadWord;
    if (h2h.myWins > h2h.theirWins) {
      leadWord = 'You lead ';
    } else if (h2h.theirWins > h2h.myWins) {
      leadWord = '${summary.opponent.name} leads ';
    } else {
      leadWord = 'Level ';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onOpenH2H != null) {
            onOpenH2H!();
          } else {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (sheetCtx) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: H2HCard.full(
                    myUid: summary.me.uid,
                    opponentUid: summary.opponent.uid,
                    opponentName: summary.opponent.name,
                    opponentAvatar: summary.opponent.avatar,
                    myAvatar: summary.me.avatar,
                    onCollapse: () => Navigator.of(sheetCtx).pop(),
                  ),
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(14.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
          ),
          child: Row(
            children: [
              Text(
                'HEAD TO HEAD',
                style: UiFont.style(
                  size: 11.0,
                  weight: 800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: UiFont.style(size: 12.0, weight: 700),
                    children: [
                      TextSpan(text: leadWord),
                      TextSpan(
                        text: '${h2h.myWins}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(text: ' – '),
                      TextSpan(
                        text: '${h2h.theirWins}',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF64748B),
                size: 18.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context, String myUid) {
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
                onPressed: () => _handleRematch(context, myUid),
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

  Future<void> _handleRematch(BuildContext context, String myUid) async {
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

  String _formatDate(int timestampMs) {
    if (timestampMs <= 0) return 'Recent';
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();

    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday =
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.subtract(const Duration(days: 1)).day;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    if (isToday) return 'Today · $hour:$minute';
    if (isYesterday) return 'Yesterday · $hour:$minute';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
