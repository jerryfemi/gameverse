import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// Matches are played sideways. While a match is on ([active]) and a phone
/// is held upright, this covers it with a "turn your phone" screen and
/// tells [onPortrait] so the match can pause. The menus work both ways up,
/// so they are never covered. Tablets and desktops are never blocked.
class PortraitGate extends StatefulWidget {
  final Widget child;
  final bool active;
  final VoidCallback onPortrait;

  const PortraitGate({
    super.key,
    required this.child,
    required this.active,
    required this.onPortrait,
  });

  /// A phone (short side under 600 px) held upright.
  static bool isPortraitPhone(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.shortestSide < 600 && size.height > size.width;
  }

  @override
  State<PortraitGate> createState() => _PortraitGateState();
}

class _PortraitGateState extends State<PortraitGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  bool _wasPortrait = false;

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portrait = widget.active && PortraitGate.isPortraitPhone(context);
    if (portrait && !_wasPortrait) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onPortrait());
    }
    _wasPortrait = portrait;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Kept alive underneath so nothing resets while the phone turns.
        widget.child,
        if (portrait) _cover(),
      ],
    );
  }

  Widget _cover() {
    return ColoredBox(
      color: TikiPalette.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _turn,
                  builder: (context, _) {
                    // Hold upright, turn a quarter, hold, back.
                    final t = _turn.value;
                    final k = t < 0.25
                        ? 0.0
                        : (t < 0.55
                              ? Curves.easeInOut.transform((t - 0.25) / 0.3)
                              : (t < 0.85 ? 1.0 : 1.0 - (t - 0.85) / 0.15));
                    return Transform.rotate(angle: -k * 1.5708, child: _phone());
                  },
                ),
                const SizedBox(height: 36),
                Text(
                  'Turn your phone sideways',
                  textAlign: TextAlign.center,
                  style: TikiText.display(size: 24, weight: 900),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tiki Counter is played on a wide board. '
                  'Your match waits for you.',
                  textAlign: TextAlign.center,
                  style: TikiText.body(size: 14, color: TikiPalette.slate),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A phone outline with a tiny pitch inside.
  Widget _phone() => Container(
    width: 64,
    height: 112,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: Container(
      decoration: BoxDecoration(
        color: TikiPalette.pitch,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Container(width: 40, height: 2, color: TikiPalette.chalk),
      ),
    ),
  );
}
