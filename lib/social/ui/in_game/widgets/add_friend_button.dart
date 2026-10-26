import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Interactive in-game 22px circle micro-button sitting on the opponent avatar.
///
/// Features:
/// - 22px visual diameter with 44px accessible touch target.
/// - Mint (#00FFCC) background with subtle glow and badge-matching border.
/// - Smooth morph animation to checkmark (dark fill, mint ring) upon request dispatch.
class AddFriendButton extends HookWidget {
  final bool isPending;
  final VoidCallback onTap;
  final Color badgeBorderColor;

  const AddFriendButton({
    super.key,
    required this.isPending,
    required this.onTap,
    this.badgeBorderColor = const Color(0xFF0F172A),
  });

  static const Color _mintColor = Color(0xFF00FFCC);
  static const Color _darkSurface = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final scaleController = useAnimationController(
      duration: const Duration(milliseconds: 250),
    );

    final scaleAnimation = useMemoized(
      () => TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 60),
      ]).animate(CurvedAnimation(
        parent: scaleController,
        curve: Curves.easeOutBack,
      )),
      [scaleController],
    );

    useEffect(() {
      if (isPending) {
        scaleController.forward(from: 0.0);
      }
      return null;
    }, [isPending]);

    void handleTap() {
      if (isPending) return;
      HapticFeedback.lightImpact();
      scaleController.forward(from: 0.0);
      onTap();
    }

    return SizedBox(
      width: 44.0,
      height: 44.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: handleTap,
        child: Center(
          child: ScaleTransition(
            scale: scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 22.0,
              height: 22.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPending ? _darkSurface : _mintColor,
                border: Border.all(
                  color: isPending ? _mintColor : badgeBorderColor,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _mintColor.withValues(alpha: isPending ? 0.25 : 0.45),
                    blurRadius: 6.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: isPending
                      ? const Icon(
                          Icons.check_rounded,
                          key: ValueKey('check'),
                          size: 13.0,
                          color: _mintColor,
                        )
                      : const Icon(
                          Icons.add_rounded,
                          key: ValueKey('add'),
                          size: 14.0,
                          color: _darkSurface,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
