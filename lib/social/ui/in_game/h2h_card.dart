import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/friends_service.dart';
import 'package:b_ball/social/models/head_to_head.dart';
import 'package:b_ball/social/models/match_summary.dart';
import 'package:b_ball/social/providers/social_providers.dart';
import 'package:b_ball/social/ui/common/crown_avatar.dart';
import 'package:b_ball/social/ui/results/results_sheet.dart';

enum H2HCardMode { peek, full }

/// Reusable Head-to-Head card widget supporting both in-game `peek` and expanded `full` views.
///
/// Built with flutter_hooks + hooks_riverpod:
/// - Peek: Opponent profile + Add button, aggregate score bar, Last-5 outcome dots, expand button.
/// - Full: Stacked avatars, sport filter pills, record panel with lead badge, match history list.
class H2HCard extends HookConsumerWidget {
  final String myUid;
  final String opponentUid;
  final String opponentName;
  final String opponentAvatar;
  final String? myAvatar;
  final H2HCardMode mode;
  final VoidCallback? onExpand;
  final VoidCallback? onCollapse;
  final VoidCallback? onAddFriend;

  const H2HCard({
    super.key,
    required this.myUid,
    required this.opponentUid,
    required this.opponentName,
    required this.opponentAvatar,
    this.myAvatar,
    this.mode = H2HCardMode.peek,
    this.onExpand,
    this.onCollapse,
    this.onAddFriend,
  });

  const H2HCard.peek({
    super.key,
    required this.myUid,
    required this.opponentUid,
    required this.opponentName,
    required this.opponentAvatar,
    this.myAvatar,
    this.onExpand,
    this.onAddFriend,
  }) : mode = H2HCardMode.peek,
       onCollapse = null;

  const H2HCard.full({
    super.key,
    required this.myUid,
    required this.opponentUid,
    required this.opponentName,
    required this.opponentAvatar,
    this.myAvatar,
    this.onCollapse,
    this.onAddFriend,
  }) : mode = H2HCardMode.full,
       onExpand = null;

  void _handleAddFriend() {
    HapticFeedback.lightImpact();
    if (onAddFriend != null) {
      onAddFriend!();
    } else {
      final myProfile = AuthService.instance.currentUser;
      if (myProfile != null) {
        FriendsService.instance.sendFriendInvite(
          targetUid: opponentUid,
          myProfile: myProfile,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = useState('all');
    final h2h = ref.watch(headToHeadProvider(opponentUid));
    final isFriend = ref.watch(isFriendProvider(opponentUid));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20.0,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: mode == H2HCardMode.peek
          ? _buildPeekView(context, h2h, isFriend)
          : _buildFullView(context, ref, h2h, selectedGame),
    );
  }

  // ===========================================================================
  // PEEK VIEW (Artboard 3)
  // ===========================================================================
  Widget _buildPeekView(BuildContext context, HeadToHead h2h, bool isFriend) {
    final total = h2h.totalMatches;
    final double myRatio = total > 0
        ? (h2h.myWins / (h2h.myWins + h2h.theirWins).clamp(1, 999))
        : 0.5;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Opponent Header + Add Friend Button
          Row(
            children: [
              CrownAvatar(avatar: opponentAvatar, size: 46.0),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opponentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiFont.style(
                        size: 16.5,
                        weight: 900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      isFriend ? 'In your friends' : 'Not in your friends yet',
                      style: UiFont.style(
                        size: 12.0,
                        weight: 600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isFriend) ...[
                const SizedBox(width: 8.0),
                SizedBox(
                  height: 32.0,
                  child: ElevatedButton.icon(
                    onPressed: _handleAddFriend,
                    icon: const Icon(Icons.add_rounded, size: 16.0),
                    label: Text(
                      'Add',
                      style: UiFont.style(
                        size: 12.0,
                        weight: 800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFCC),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16.0),

          // Section header: HEAD TO HEAD · n matches
          Row(
            children: [
              Text(
                'HEAD TO HEAD',
                style: UiFont.style(
                  size: 11.0,
                  weight: 800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '$total ${total == 1 ? "match" : "matches"}',
                style: UiFont.style(
                  size: 12.0,
                  weight: 600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Big Record Numbers (Sky blue & Amber)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${h2h.myWins}',
                style: UiFont.style(
                  size: 32.0,
                  weight: 900,
                  color: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                'You',
                style: UiFont.style(
                  size: 12.0,
                  weight: 700,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const Spacer(),
              Text(
                'WINS',
                style: UiFont.style(
                  size: 10.5,
                  weight: 800,
                  color: const Color(0xFF475569),
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                'Them',
                style: UiFont.style(
                  size: 12.0,
                  weight: 700,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                '${h2h.theirWins}',
                style: UiFont.style(
                  size: 32.0,
                  weight: 900,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Split Progress Bar
          _buildSplitBar(myRatio),
          const SizedBox(height: 16.0),

          // Last 5 row
          Row(
            children: [
              Text(
                'Last 5',
                style: UiFont.style(
                  size: 12.0,
                  weight: 600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              if (h2h.lastFive.isEmpty)
                Text(
                  'No recent games',
                  style: UiFont.style(
                    size: 11.5,
                    weight: 600,
                    color: const Color(0xFF475569),
                  ),
                )
              else
                Row(
                  children: [
                    for (final didWin in h2h.lastFive) ...[
                      _buildOutcomeDot(didWin),
                      const SizedBox(width: 5.0),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16.0),

          // See all our matches Expand Button
          SizedBox(
            height: 42.0,
            child: Material(
              color: const Color(0xFF1E2638),
              borderRadius: BorderRadius.circular(12.0),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onExpand?.call();
                },
                borderRadius: BorderRadius.circular(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'See all our matches',
                      style: UiFont.style(
                        size: 13.0,
                        weight: 700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 18.0,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FULL VIEW (Artboard 4)
  // ===========================================================================
  Widget _buildFullView(
    BuildContext context,
    WidgetRef ref,
    HeadToHead h2h,
    ValueNotifier<String> selectedGame,
  ) {
    final currentGame = selectedGame.value;
    final filteredMatches = currentGame == 'all'
        ? h2h.matches
        : h2h.matches
              .where((m) => m.game.toLowerCase().trim() == currentGame)
              .toList();

    final filteredWins = currentGame == 'all'
        ? h2h.myWins
        : (h2h.byGame[currentGame]?.myWins ?? 0);
    final filteredLosses = currentGame == 'all'
        ? h2h.theirWins
        : (h2h.byGame[currentGame]?.theirWins ?? 0);
    final double filteredRatio = (filteredWins + filteredLosses) > 0
        ? (filteredWins / (filteredWins + filteredLosses))
        : 0.5;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Stacked avatars, You vs Opponent, Collapse button
          Row(
            children: [
              _buildStackedAvatars(),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You vs $opponentName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiFont.style(
                        size: 17.5,
                        weight: 900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Head to head · ${h2h.totalMatches} matches',
                      style: UiFont.style(
                        size: 12.0,
                        weight: 600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70,
                  size: 24.0,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onCollapse?.call();
                },
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Sport Filter Pills (All / Darts / Hoops / Archery)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill(
                  'All ${h2h.totalMatches}',
                  'all',
                  currentGame,
                  (g) => selectedGame.value = g,
                ),
                const SizedBox(width: 8.0),
                _buildFilterPill(
                  'Darts ${h2h.byGame['darts']?.total ?? 0}',
                  'darts',
                  currentGame,
                  (g) => selectedGame.value = g,
                ),
                const SizedBox(width: 8.0),
                _buildFilterPill(
                  'Hoops ${h2h.byGame['basketball']?.total ?? h2h.byGame['hoops']?.total ?? 0}',
                  'basketball',
                  currentGame,
                  (g) => selectedGame.value = g,
                ),
                const SizedBox(width: 8.0),
                _buildFilterPill(
                  'Archery ${h2h.byGame['archery']?.total ?? 0}',
                  'archery',
                  currentGame,
                  (g) => selectedGame.value = g,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Record Panel with Lead Badge
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1020),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Your wins
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$filteredWins',
                          style: UiFont.style(
                            size: 28.0,
                            weight: 900,
                            color: const Color(0xFF38BDF8),
                          ),
                        ),
                        Text(
                          'YOUR WINS',
                          style: UiFont.style(
                            size: 10.0,
                            weight: 800,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Lead Pill (e.g. "You lead · won last 2")
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1F00FFCC),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        h2h.leadSummary,
                        style: UiFont.style(
                          size: 11.5,
                          weight: 800,
                          color: const Color(0xFF00FFCC),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Their wins
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$filteredLosses',
                          style: UiFont.style(
                            size: 28.0,
                            weight: 900,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        Text(
                          'THEIR WINS',
                          style: UiFont.style(
                            size: 10.0,
                            weight: 800,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                _buildSplitBar(filteredRatio),
              ],
            ),
          ),
          const SizedBox(height: 14.0),

          // Match History Rows
          if (filteredMatches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  'No matches found in this category.',
                  style: UiFont.style(
                    size: 13.0,
                    weight: 600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280.0),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filteredMatches.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: Color(0xFF1E2638), height: 1.0),
                itemBuilder: (ctx, i) {
                  final summary = filteredMatches[i];
                  return _buildMatchRow(context, ref, summary);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stacked Avatars (You & Opponent overlapping)
  // ---------------------------------------------------------------------------
  Widget _buildStackedAvatars() {
    return SizedBox(
      width: 66.0,
      height: 40.0,
      child: Stack(
        children: [
          CrownAvatar(avatar: myAvatar ?? '👤', size: 40.0),
          Positioned(
            left: 26.0,
            child: CrownAvatar(avatar: opponentAvatar, size: 40.0),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter Pill Button
  // ---------------------------------------------------------------------------
  Widget _buildFilterPill(
    String label,
    String gameKey,
    String selectedGame,
    ValueChanged<String> onSelect,
  ) {
    final isSelected = selectedGame == gameKey;

    return Material(
      color: isSelected ? Colors.white : const Color(0xFF1E2638),
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onSelect(gameKey);
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isSelected ? Colors.white : const Color(0xFF2A344A),
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: UiFont.style(
              size: 12.0,
              weight: 800,
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Single Match Row in Full List
  // ---------------------------------------------------------------------------
  Widget _buildMatchRow(
    BuildContext context,
    WidgetRef ref,
    MatchSummary summary,
  ) {
    final allMatches = ref.read(userMatchesProvider).value ?? const [];
    final originalMatch = allMatches
        .where((m) => m.id == summary.matchId)
        .firstOrNull;

    final IconData icon;
    final Color iconColor;
    final Color iconBg;

    final g = summary.game.toLowerCase().trim();
    if (g == 'darts') {
      icon = Icons.adjust_rounded;
      iconColor = const Color(0xFFF87171);
      iconBg = const Color(0x26F87171);
    } else if (g == 'archery') {
      icon = Icons.arrow_outward_rounded;
      iconColor = const Color(0xFF00FFCC);
      iconBg = const Color(0x2600FFCC);
    } else {
      icon = Icons.sports_basketball_rounded;
      iconColor = const Color(0xFFF59E0B);
      iconBg = const Color(0x26F59E0B);
    }

    final dateStr = _formatDate(summary.finishedAt);
    final isWin = summary.didIWin == true;
    final isLoss = summary.didIWin == false;

    final pillLabel = isWin ? 'WON' : (isLoss ? 'LOST' : 'DRAW');
    final pillBg = isWin
        ? const Color(0x2600FFCC)
        : (isLoss ? const Color(0x26F87171) : const Color(0xFF1E2638));
    final pillColor = isWin
        ? const Color(0xFF00FFCC)
        : (isLoss ? const Color(0xFFF87171) : const Color(0xFF94A3B8));

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (originalMatch != null) {
          ResultsSheet.show(context, originalMatch);
        }
      },
      borderRadius: BorderRadius.circular(10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 16.0, color: iconColor),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.verdictLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiFont.style(
                      size: 13.0,
                      weight: 700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    dateStr,
                    style: UiFont.style(
                      size: 11.0,
                      weight: 600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 3.5,
              ),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                pillLabel,
                style: UiFont.style(
                  size: 11.0,
                  weight: 900,
                  color: pillColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper Widgets: Split Bar & Outcome Dot
  // ---------------------------------------------------------------------------
  Widget _buildSplitBar(double myRatio) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: SizedBox(
        height: 6.0,
        child: Row(
          children: [
            Expanded(
              flex: (myRatio * 100).round().clamp(1, 99),
              child: Container(color: const Color(0xFF38BDF8)),
            ),
            const SizedBox(width: 2.0),
            Expanded(
              flex: ((1.0 - myRatio) * 100).round().clamp(1, 99),
              child: Container(color: const Color(0xFFF59E0B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutcomeDot(bool? didWin) {
    final String label;
    final Color bg;
    final Color textColor;

    if (didWin == true) {
      label = 'W';
      bg = const Color(0xFF00FFCC);
      textColor = const Color(0xFF0B2E28);
    } else if (didWin == false) {
      label = 'L';
      bg = const Color(0x2EF87171);
      textColor = const Color(0xFFF87171);
    } else {
      label = 'D';
      bg = const Color(0xFF1E2638);
      textColor = const Color(0xFF94A3B8);
    }

    return Container(
      width: 22.0,
      height: 22.0,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(
          label,
          style: UiFont.style(size: 11.0, weight: 900, color: textColor),
        ),
      ),
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
