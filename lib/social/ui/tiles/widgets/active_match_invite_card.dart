import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/services/firestore_match_service.dart';
import 'package:b_ball/social/ui/common/crown_avatar.dart';
import 'package:b_ball/social/ui/common/game_chip.dart';

/// Card widget for active match in "INVITE NOT JOINED" state (Artboard 10 - bottom card).
class ActiveMatchInviteCard extends StatelessWidget {
  final CloudMatch match;
  final String effectiveUid;
  final bool codeCopied;
  final VoidCallback onCopy;

  const ActiveMatchInviteCard({
    super.key,
    required this.match,
    required this.effectiveUid,
    required this.codeCopied,
    required this.onCopy,
  });

  Future<void> _cancelInvite(BuildContext context) async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF131826),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFF2E3954),
            width: 1.5,
          ),
        ),
        title: Text(
          'CANCEL INVITE',
          style: UiFont.style(
            size: 16.0,
            weight: 900,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this match invite?',
          style: UiFont.style(
            size: 13.0,
            weight: 500,
            color: const Color(0xFF94A3B8),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'NO',
              style: UiFont.style(
                size: 13.0,
                weight: 700,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'CANCEL INVITE',
              style: UiFont.style(
                size: 13.0,
                weight: 800,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && effectiveUid.isNotEmpty) {
      await FirestoreMatchService.instance.leaveOrDismissMatch(
        matchId: match.id,
        myUid: effectiveUid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myPlayer = match.myPlayer(effectiveUid);
    final oppName = match.player2?.displayName ?? 'Opponent';
    final oppAvatar = match.player2?.avatarEmoji ?? '⏳';
    final sentTimeStr = _formatRelativeTime(match.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color(0xFF1E2638),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: GameChip, Sent time, NOT JOINED pill
          Row(
            children: [
              GameChip.fromMatch(match),
              const SizedBox(width: 10.0),
              Text(
                sentTimeStr,
                style: UiFont.style(
                  size: 12.0,
                  weight: 600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0x2664748B),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'NOT JOINED',
                  style: UiFont.style(
                    size: 11.0,
                    weight: 800,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Row 2: Avatars & Hyphen scores
          Row(
            children: [
              CrownAvatar(
                avatar: myPlayer?.avatarEmoji ?? '👤',
                size: 40.0,
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOU',
                      style: UiFont.style(
                        size: 11.0,
                        weight: 800,
                        color: const Color(0xFF38BDF8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '—',
                      style: UiFont.style(
                        size: 20.0,
                        weight: 900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  'VS',
                  style: UiFont.style(
                    size: 11.0,
                    weight: 800,
                    color: const Color(0xFF475569),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      oppName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiFont.style(
                        size: 11.0,
                        weight: 800,
                        color: const Color(0xFFF59E0B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '—',
                      style: UiFont.style(
                        size: 20.0,
                        weight: 900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10.0),
              CrownAvatar(
                avatar: oppAvatar,
                size: 40.0,
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Row 3: Sentence
          Text(
            'Waiting for $oppName to join · code ${match.joinCode}',
            style: UiFont.style(
              size: 13.0,
              weight: 600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12.0),

          // Row 4: Buttons (Copy code and Cancel)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40.0,
                  child: OutlinedButton(
                    onPressed: onCopy,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2638),
                      side: BorderSide(
                        color: codeCopied
                            ? const Color(0xFF00FFCC)
                            : const Color(0xFF2A344A),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      codeCopied ? '✓ CODE COPIED' : 'Copy code',
                      style: UiFont.style(
                        size: 12.5,
                        weight: 800,
                        color: codeCopied
                            ? const Color(0xFF00FFCC)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: SizedBox(
                  height: 40.0,
                  child: ElevatedButton(
                    onPressed: () => _cancelInvite(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2638),
                      foregroundColor: const Color(0xFF94A3B8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: UiFont.style(
                        size: 12.5,
                        weight: 800,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(int timestampMs) {
    if (timestampMs <= 0) return 'Just now';
    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMs = now - timestampMs;
    final diffSec = diffMs ~/ 1000;
    if (diffSec < 60) return 'Just now';
    final diffMin = diffSec ~/ 60;
    if (diffMin < 60) return 'Sent $diffMin m ago';
    final diffHours = diffMin ~/ 60;
    if (diffHours < 24) return 'Sent $diffHours h ago';
    final diffDays = diffHours ~/ 24;
    return 'Sent $diffDays d ago';
  }
}
