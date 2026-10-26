import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/social/models/head_to_head.dart';
import 'package:b_ball/social/ui/common/crown_avatar.dart';
import 'package:b_ball/social/ui/in_game/widgets/h2h_primitives.dart';

/// Content of the compact Head-to-Head peek card per Artboard 3.
class H2HPeekContent extends StatelessWidget {
  final String opponentName;
  final String opponentAvatar;
  final HeadToHead h2h;
  final bool isFriend;
  final VoidCallback? onAddFriend;
  final VoidCallback? onExpand;
  final Widget? footer;

  const H2HPeekContent({
    super.key,
    required this.opponentName,
    required this.opponentAvatar,
    required this.h2h,
    required this.isFriend,
    this.onAddFriend,
    this.onExpand,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final total = h2h.totalMatches;
    final double myRatio = total > 0
        ? (h2h.myWins / (h2h.myWins + h2h.theirWins).clamp(1, 999))
        : 0.5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
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
              if (!isFriend && onAddFriend != null) ...[
                const SizedBox(width: 8.0),
                SizedBox(
                  height: 32.0,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onAddFriend?.call();
                    },
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
          H2HSplitBar(myRatio: myRatio),
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
                      H2HOutcomeDot(didWin: didWin),
                      const SizedBox(width: 5.0),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16.0),

          // See all our matches Expand Button
          if (onExpand != null)
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

          // Attached badge footer (visibly is the badge, expanded)
          if (footer != null) ...[
            const SizedBox(height: 12.0),
            footer!,
          ],
        ],
      ),
    );
  }
}
