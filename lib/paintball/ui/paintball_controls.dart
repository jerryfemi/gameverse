import 'package:flutter/material.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/match_state.dart';
import 'package:b_ball/paintball/paintball_game.dart';

/// Interactive dual-thumb touch controls overlay for Paintball duels.
///
/// Follows Paintball Plan §5b & §8:
/// - Bottom-Left: 5 ammo pips + ◀ ▶ circular slide buttons.
/// - Bottom-Right: ▲ ▼ stance buttons + prominent glowing red FIRE button.
/// - Right-Half Drag Zone: gesture detector for aiming reticle without interfering with buttons.
class PaintballControlsOverlay extends StatelessWidget {
  final PaintballGame game;

  const PaintballControlsOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final you = game.match.you;

    return Stack(
      children: [
        // ─── 1. Right-Half Drag Aim Touchpad ────────────────────────────────
        Positioned(
          top: 100,
          right: 0,
          bottom: 180, // Leaves space for bottom-right action buttons
          left: MediaQuery.sizeOf(context).width * 0.45,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) {
              game.onAimDrag(details.delta.dx, details.delta.dy);
            },
          ),
        ),

        // ─── 2. Bottom Controls Bar ─────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Bottom-Left Cluster: Ammo + Slide Buttons
                  _buildSlideCluster(you),

                  // Bottom-Right Cluster: Stance + FIRE
                  _buildFireCluster(you),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Left Cluster: Ammo & Sliding ─────────────────────────────────────────

  Widget _buildSlideCluster(PaintballPlayerState you) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 5 Ammo Pips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          margin: const EdgeInsets.only(bottom: 10, left: 4),
          decoration: BoxDecoration(
            color: const Color(0xCC0A0E1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(PaintballK.maxAmmo, (index) {
              final isLoaded = index < you.ammo;
              return Container(
                width: 7,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isLoaded ? const Color(0xFFEC4899) : const Color(0xFF334155),
                  boxShadow: isLoaded
                      ? [
                          const BoxShadow(
                            color: Color(0x88EC4899),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              );
            }),
          ),
        ),

        // ◀ ▶ Slide Buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoundButton(
              size: 58,
              icon: Icons.chevron_left_rounded,
              iconSize: 32,
              enabled: game.canAct && you.lane > PaintballK.minLane,
              onTap: () => game.playerSlide(-1),
            ),
            const SizedBox(width: 12),
            _buildRoundButton(
              size: 58,
              icon: Icons.chevron_right_rounded,
              iconSize: 32,
              enabled: game.canAct && you.lane < PaintballK.maxLane,
              onTap: () => game.playerSlide(1),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Right Cluster: Stance & FIRE ─────────────────────────────────────────

  Widget _buildFireCluster(PaintballPlayerState you) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ▲ ▼ Stance Buttons
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoundButton(
              size: 48,
              icon: Icons.keyboard_arrow_up_rounded,
              iconSize: 28,
              enabled: game.canAct && you.stance != PaintballStance.stand,
              highlight: you.stance == PaintballStance.stand,
              onTap: () => game.playerStanceStep(1),
            ),
            const SizedBox(height: 8),
            _buildRoundButton(
              size: 48,
              icon: Icons.keyboard_arrow_down_rounded,
              iconSize: 28,
              enabled: game.canAct && you.stance != PaintballStance.duck,
              highlight: you.stance == PaintballStance.duck,
              onTap: () => game.playerStanceStep(-1),
            ),
          ],
        ),
        const SizedBox(width: 14),

        // Glowing Red FIRE Action Button
        // Fires on touch-down (no wait for release, no tap-vs-drag
        // disambiguation), so fast repeated taps all register.
        _PressScale(
          onPress: () {
            if (game.playerCanFire) game.firePlayerShot();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: game.playerCanFire ? const Color(0xFFEF4444) : const Color(0xFF4B5563),
              border: Border.all(color: Colors.white, width: 3.5),
              boxShadow: game.playerCanFire
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.65),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: const Text(
              'FIRE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoundButton({
    required double size,
    required IconData icon,
    required double iconSize,
    required bool enabled,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return _PressScale(
      onPress: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: highlight
              ? const Color(0xFF38BDF8)
              : enabled
                  ? const Color(0xCC0A0E1A)
                  : const Color(0x660A0E1A),
          border: Border.all(
            color: highlight
                ? Colors.white
                : enabled
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: highlight
              ? const Color(0xFF0A0E1A)
              : enabled
                  ? Colors.white
                  : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

/// Button that acts on pointer-down and dips slightly while pressed.
/// A Listener takes no part in the gesture arena, so it never loses a tap
/// to the aim drag or to double-tap detection.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.onPress, required this.child});

  final VoidCallback? onPress;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        widget.onPress?.call();
        setState(() => _down = true);
      },
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
