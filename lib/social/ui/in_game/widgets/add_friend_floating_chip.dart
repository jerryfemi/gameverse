import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Display mode / state of the in-game floating social chip.
enum FloatingChipState {
  /// Initial countdown "+ Add to friends" chip with emptying mint bar.
  introCountdown,

  /// "✓ Request sent to `<Name>`" confirmation pill.
  requestSent,

  /// "Couldn't send · Tap to retry" error pill.
  errorRetry,

  /// Dismissed / hidden.
  hidden,
}

/// Floating contextual pill chip providing "+ Add to friends", countdown,
/// sent confirmation, and retry states per Artboards 1 & 2.
class AddFriendFloatingChip extends HookWidget {
  final FloatingChipState state;
  final String opponentName;
  final VoidCallback onTap;
  final VoidCallback onRetry;
  final VoidCallback onDismissed;
  final bool isAbove;

  const AddFriendFloatingChip({
    super.key,
    required this.state,
    required this.opponentName,
    required this.onTap,
    required this.onRetry,
    required this.onDismissed,
    this.isAbove = true,
  });

  static const Color _mint = Color(0xFF00FFCC);
  static const Color _bgDark = Color(0xF00F172A);
  static const Color _borderDark = Color(0x3300FFCC);
  static const Color _errorBg = Color(0xF02A0F14);
  static const Color _errorBorder = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    // 2-second countdown controller for the emptying mint progress bar
    final countdownController = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    );

    // Fade/scale entry and exit controller
    final visibilityController = useAnimationController(
      duration: const Duration(milliseconds: 240),
    );

    final autoDismissTimer = useRef<Timer?>(null);

    useEffect(() {
      autoDismissTimer.value?.cancel();

      if (state == FloatingChipState.introCountdown) {
        visibilityController.forward();
        countdownController.forward(from: 0.0);

        countdownController.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            visibilityController.reverse().then((_) {
              onDismissed();
            });
          }
        });
      } else if (state == FloatingChipState.requestSent) {
        countdownController.stop();
        visibilityController.forward();
        autoDismissTimer.value = Timer(const Duration(seconds: 2), () {
          visibilityController.reverse().then((_) {
            onDismissed();
          });
        });
      } else if (state == FloatingChipState.errorRetry) {
        countdownController.stop();
        visibilityController.forward();
      } else {
        visibilityController.reverse().then((_) {
          onDismissed();
        });
      }

      return () {
        autoDismissTimer.value?.cancel();
      };
    }, [state]);

    if (state == FloatingChipState.hidden) {
      return const SizedBox.shrink();
    }

    final isError = state == FloatingChipState.errorRetry;
    final isSent = state == FloatingChipState.requestSent;

    void handleTap() {
      HapticFeedback.lightImpact();
      if (isError) {
        onRetry();
      } else if (state == FloatingChipState.introCountdown) {
        onTap();
      }
    }

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: visibilityController,
        curve: Curves.easeOutCubic,
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1.0).animate(
          CurvedAnimation(
            parent: visibilityController,
            curve: Curves.easeOutBack,
          ),
        ),
        alignment: isAbove ? Alignment.bottomRight : Alignment.topRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isAbove) _buildCaret(isAbove: false, isError: isError),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: handleTap,
              child: Container(
                decoration: BoxDecoration(
                  color: isError ? _errorBg : _bgDark,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: isError ? _errorBorder : _borderDark,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10.0,
                      offset: const Offset(0, 4),
                    ),
                    if (!isError)
                      BoxShadow(
                        color: _mint.withValues(alpha: 0.12),
                        blurRadius: 8.0,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11.0,
                          vertical: 6.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isError) ...[
                              const Icon(
                                Icons.refresh_rounded,
                                size: 12.0,
                                color: _errorBorder,
                              ),
                              const SizedBox(width: 5.0),
                              const Text(
                                "Couldn't send · Tap to retry",
                                style: TextStyle(
                                  color: Color(0xFFFCA5A5),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ] else if (isSent) ...[
                              const Icon(
                                Icons.check_rounded,
                                size: 13.0,
                                color: _mint,
                              ),
                              const SizedBox(width: 5.0),
                              Text(
                                'Request sent to $opponentName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ] else ...[
                              const Icon(
                                Icons.add_rounded,
                                size: 13.0,
                                color: _mint,
                              ),
                              const SizedBox(width: 4.0),
                              const Text(
                                'Add to friends',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Countdown progress bar along bottom (empties from left to right)
                      if (state == FloatingChipState.introCountdown)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 2.0,
                          child: AnimatedBuilder(
                            animation: countdownController,
                            builder: (context, _) {
                              final remaining = 1.0 - countdownController.value;
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: remaining.clamp(0.0, 1.0),
                                child: Container(color: _mint),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (isAbove) _buildCaret(isAbove: true, isError: isError),
          ],
        ),
      ),
    );
  }

  Widget _buildCaret({required bool isAbove, required bool isError}) {
    return Padding(
      padding: const EdgeInsets.only(right: 18.0),
      child: CustomPaint(
        size: const Size(8.0, 5.0),
        painter: _CaretPainter(
          isPointingDown: isAbove,
          color: isError ? _errorBg : _bgDark,
          borderColor: isError ? _errorBorder : _borderDark,
        ),
      ),
    );
  }
}

class _CaretPainter extends CustomPainter {
  final bool isPointingDown;
  final Color color;
  final Color borderColor;

  const _CaretPainter({
    required this.isPointingDown,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (isPointingDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    }
    path.close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CaretPainter oldDelegate) =>
      oldDelegate.isPointingDown != isPointingDown ||
      oldDelegate.color != color ||
      oldDelegate.borderColor != borderColor;
}
