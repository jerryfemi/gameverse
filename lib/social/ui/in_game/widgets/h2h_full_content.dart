import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/social/models/head_to_head.dart';
import 'package:b_ball/social/ui/common/crown_avatar.dart';
import 'package:b_ball/social/ui/in_game/widgets/h2h_match_row.dart';
import 'package:b_ball/social/ui/in_game/widgets/h2h_primitives.dart';

/// Content of the full expanded Head-to-Head panel per Artboard 4.
class H2HFullContent extends StatelessWidget {
  final String myUid;
  final String? myAvatar;
  final String opponentName;
  final String opponentAvatar;
  final HeadToHead h2h;
  final String selectedGame;
  final ValueChanged<String> onGameSelected;
  final VoidCallback? onCollapse;

  const H2HFullContent({
    super.key,
    required this.myUid,
    this.myAvatar,
    required this.opponentName,
    required this.opponentAvatar,
    required this.h2h,
    required this.selectedGame,
    required this.onGameSelected,
    this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final currentGame = selectedGame;
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
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36.0,
              height: 4.0,
              margin: const EdgeInsets.only(bottom: 12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),

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
              if (onCollapse != null)
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E2638),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
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
                ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Sport Filter Pills (All / Darts / Hoops / Archery)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill('All ${h2h.totalMatches}', 'all', currentGame),
                const SizedBox(width: 8.0),
                _buildFilterPill(
                  'Darts ${h2h.byGame['darts']?.total ?? 0}',
                  'darts',
                  currentGame,
                ),
                const SizedBox(width: 8.0),
                _buildFilterPill(
                  'Hoops ${h2h.byGame['basketball']?.total ?? h2h.byGame['hoops']?.total ?? 0}',
                  'basketball',
                  currentGame,
                ),
                const SizedBox(width: 8.0),
                _buildFilterPill(
                  'Archery ${h2h.byGame['archery']?.total ?? 0}',
                  'archery',
                  currentGame,
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
                H2HSplitBar(myRatio: filteredRatio),
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
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filteredMatches.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: Color(0xFF1E2638), height: 1.0),
                itemBuilder: (ctx, i) {
                  final summary = filteredMatches[i];
                  return H2HMatchRow(summary: summary);
                },
              ),
            ),
        ],
      ),
    );
  }

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

  Widget _buildFilterPill(String label, String gameKey, String selected) {
    final isSelected = selected == gameKey;

    return Material(
      color: isSelected ? Colors.white : const Color(0xFF1E2638),
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onGameSelected(gameKey);
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
}
