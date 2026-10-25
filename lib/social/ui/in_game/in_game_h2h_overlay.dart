import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/social/ui/in_game/in_game_h2h_panel.dart';

/// Full-screen in-game overlay controller for Head-to-Head peek and full panels per Section 9:
/// - Intercepts all touches outside the card to prevent accidental canvas throws.
/// - Controls Flame engine pause/resume lifecycle during solo play.
/// - Positions the peek and full panels with spring transitions.
class InGameH2HOverlay extends HookConsumerWidget {
  final InGameH2HState state;
  final String myUid;
  final String? myAvatar;
  final String opponentUid;
  final String opponentName;
  final String opponentAvatar;
  final String defaultGame;
  final Widget? footerSummary;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final VoidCallback onClose;
  final VoidCallback? onAddFriend;
  final int? turnCountdown;
  final bool isOnline;
  final bool isMyTurn;
  final VoidCallback? onPauseEngine;
  final VoidCallback? onResumeEngine;

  const InGameH2HOverlay({
    super.key,
    required this.state,
    required this.myUid,
    this.myAvatar,
    required this.opponentUid,
    required this.opponentName,
    required this.opponentAvatar,
    this.defaultGame = 'all',
    this.footerSummary,
    required this.onExpand,
    required this.onCollapse,
    required this.onClose,
    this.onAddFriend,
    this.turnCountdown,
    this.isOnline = false,
    this.isMyTurn = false,
    this.onPauseEngine,
    this.onResumeEngine,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = state != InGameH2HState.closed;

    // Solo play: pause engine while panel is open, resume when closed
    useEffect(() {
      if (!isOnline) {
        if (isOpen) {
          onPauseEngine?.call();
        } else {
          onResumeEngine?.call();
        }
      }
      return null;
    }, [isOpen, isOnline]);

    // Solo play: automatically close when it becomes your throw
    useEffect(() {
      if (!isOnline && isMyTurn && isOpen) {
        onClose();
      }
      return null;
    }, [isMyTurn, isOnline, isOpen]);

    if (!isOpen) {
      return const SizedBox.shrink();
    }

    final isFull = state == InGameH2HState.full;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Gesture barrier: absorbs all touches outside card so throws don't pass to Flame
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: Container(color: Colors.transparent),
        ),

        // 2. Animated H2H Panel (Peek or Full)
        Positioned(
          left: isFull ? 0.0 : null,
          right: isFull ? 0.0 : 16.0,
          bottom: 12.0,
          child: Center(
            child: InGameH2HPanel(
              state: state,
              myUid: myUid,
              myAvatar: myAvatar,
              opponentUid: opponentUid,
              opponentName: opponentName,
              opponentAvatar: opponentAvatar,
              defaultGame: defaultGame,
              footerSummary: footerSummary,
              onExpand: onExpand,
              onCollapse: onCollapse,
              onAddFriend: onAddFriend,
              turnCountdown: turnCountdown,
            ),
          ),
        ),
      ],
    );
  }
}
