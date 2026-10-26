import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_ball/game/basketball_game.dart';

/// Displays the obsidian "How to play" rules dialog matching Design Template 12.
Future<void> showGameRulesDialog(
  BuildContext context, {
  BasketballGame? game,
  String initialGame = 'hoops',
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    builder: (context) => HowToPlayDialog(game: game, initialGame: initialGame),
  );
}

/// Dynamic multi-game rules modal matching Template 12.
/// Includes HOOPS, ARCHERY, and DARTS tabs with responsive FittedBox scaling.
class HowToPlayDialog extends StatefulWidget {
  final BasketballGame? game;
  final String initialGame;

  const HowToPlayDialog({
    super.key,
    this.game,
    this.initialGame = 'hoops',
  });

  @override
  State<HowToPlayDialog> createState() => _HowToPlayDialogState();
}

class _HowToPlayDialogState extends State<HowToPlayDialog> {
  late String _activeGame;

  @override
  void initState() {
    super.initState();
    _activeGame = widget.initialGame.toLowerCase();
    if (_activeGame != 'archery' && _activeGame != 'darts') {
      _activeGame = 'hoops';
    }
  }

  Color get _accentColor {
    switch (_activeGame) {
      case 'archery':
        return const Color(0xFF00FFCC);
      case 'darts':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color get _primaryBtnTextColor {
    return _activeGame == 'archery' ? const Color(0xFF0A0E1A) : (_activeGame == 'darts' ? const Color(0xFF0A0E1A) : const Color(0xFF0A0E1A));
  }

  String get _subtitle {
    switch (_activeGame) {
      case 'archery':
        return 'Archery 1v1 · sets of 3 arrows, first to 6 set points';
      case 'darts':
        return 'Darts 301 · take turns, checkout on a double';
      default:
        return 'Hoops 1v1 · take turns, highest total wins';
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxH = media.size.height * 0.88;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      elevation: 0,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360.0,
            maxHeight: maxH,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1424),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xCC000000),
                  blurRadius: 36.0,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Row: Title + Close Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'How to play',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                _subtitle,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(18.0),
                          child: Container(
                            width: 32.0,
                            height: 32.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18.0,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // Game Segmented Switcher
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF090E1A),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: const Color(0xFF1E2638)),
                      ),
                      child: Row(
                        children: [
                          _buildGameTab('hoops', 'HOOPS', const Color(0xFFF59E0B)),
                          _buildGameTab('archery', 'ARCHERY', const Color(0xFF00FFCC)),
                          _buildGameTab('darts', 'DARTS', const Color(0xFF38BDF8)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    // Scrollable Rules Content
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSectionHeader(
                              _activeGame == 'darts' ? 'THROWING' : 'SHOOTING',
                            ),
                            const SizedBox(height: 6.0),
                            _buildControlsCard(),
                            const SizedBox(height: 14.0),
                            _buildSectionHeader('ON SCREEN'),
                            const SizedBox(height: 6.0),
                            _buildOnScreenCard(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Footer Action Buttons
                    Row(
                      children: [
                        if (widget.game != null && _activeGame == 'hoops') ...[
                          InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Navigator.of(context).pop();
                              widget.game!
                                ..tourNewStepsOnly = false
                                ..isTourActiveNotifier.value = true;
                            },
                            borderRadius: BorderRadius.circular(14.0),
                            child: Container(
                              height: 46.0,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2638),
                                borderRadius: BorderRadius.circular(14.0),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18.0),
                                  SizedBox(width: 4.0),
                                  Text(
                                    'Tour',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: _primaryBtnTextColor,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(46.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                            ),
                            child: const Text(
                              'GOT IT',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameTab(String key, String label, Color accent) {
    final bool isSelected = _activeGame == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            setState(() => _activeGame = key);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8.5),
          decoration: BoxDecoration(
            color: isSelected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10.0),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0A0E1A) : const Color(0xFF94A3B8),
              fontSize: 12.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 11.0,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildControlsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Column(
        children: [
          if (_activeGame == 'hoops') ...[
            _buildGuideRow(
              iconWidget: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFF59E0B), size: 16.0),
              title: 'Flick up to shoot',
              desc: 'Drag from the ball towards the hoop and let go. A longer, faster flick throws further.',
            ),
            const Divider(color: Color(0xFF1E2638), height: 1.0),
            _buildGuideRow(
              iconWidget: const Icon(Icons.north_east_rounded, color: Color(0xFFF59E0B), size: 16.0),
              title: 'Angle it to aim',
              desc: 'Flick slightly left or right to curve the shot; bank it off the backboard.',
            ),
            const Divider(color: Color(0xFF1E2638), height: 1.0),
            _buildGuideRow(
              iconWidget: const Icon(Icons.alarm_rounded, color: Color(0xFFF59E0B), size: 16.0),
              title: 'Beat the clock',
              desc: "Each round is timed. Score as many as you can, then it's their turn.",
            ),
          ] else if (_activeGame == 'archery') ...[
            _buildGuideRow(
              iconWidget: const Icon(Icons.track_changes_rounded, color: Color(0xFF00FFCC), size: 16.0),
              title: 'Draw & release',
              desc: 'Drag back to draw the bow, hold steady to line up your aim, then release to shoot.',
            ),
            const Divider(color: Color(0xFF1E2638), height: 1.0),
            _buildGuideRow(
              iconWidget: const Icon(Icons.air_rounded, color: Color(0xFF00FFCC), size: 16.0),
              title: 'Watch the wind',
              desc: 'Check the wind flag for speed and drift direction before every single shot.',
            ),
            const Divider(color: Color(0xFF1E2638), height: 1.0),
            _buildGuideRow(
              iconWidget: const Icon(Icons.stars_rounded, color: Color(0xFF00FFCC), size: 16.0),
              title: 'Hit the gold',
              desc: 'Target rings score 1–10. Inner 10 is an X used to break head-to-head ties.',
            ),
          ] else ...[
            _buildGuideRow(
              iconWidget: const Icon(Icons.gps_fixed_rounded, color: Color(0xFF38BDF8), size: 16.0),
              title: 'Flick to throw',
              desc: 'Flick towards your target on the dartboard. Faster, straighter flicks fly truer.',
            ),
            const Divider(color: Color(0xFF1E2638), height: 1.0),
            _buildGuideRow(
              iconWidget: const Icon(Icons.numbers_rounded, color: Color(0xFF38BDF8), size: 16.0),
              title: 'Count down from 301',
              desc: 'Score points across 3 darts per turn to reduce your remaining score to exactly zero.',
            ),
            const Divider(color: Color(0xFF1E2638), height: 1.0),
            _buildGuideRow(
              iconWidget: const Icon(Icons.emoji_events_rounded, color: Color(0xFF38BDF8), size: 16.0),
              title: 'Finish on a double',
              desc: 'Your final dart must land in an outer ring double or the bullseye to checkout.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOnScreenCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Column(
        children: [
          _buildGuideRow(
            iconWidget: Container(
              width: 22.0,
              height: 22.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF38BDF8),
              ),
              alignment: Alignment.center,
              child: const Text(
                'BL',
                style: TextStyle(
                  color: Color(0xFF0A0E1A),
                  fontSize: 10.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            title: 'Tap a player for their record and head to head',
            desc: null,
          ),
          const Divider(color: Color(0xFF1E2638), height: 1.0),
          _buildGuideRow(
            iconWidget: Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentColor,
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.6),
                    blurRadius: 8.0,
                  ),
                ],
              ),
            ),
            title: "A glowing ring means it's your turn",
            desc: null,
          ),
          const Divider(color: Color(0xFF1E2638), height: 1.0),
          _buildGuideRow(
            iconWidget: const Icon(Icons.pause_rounded, color: Color(0xFF94A3B8), size: 18.0),
            title: 'Pause for sound, restart and leaving',
            desc: null,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow({
    required Widget iconWidget,
    required String title,
    String? desc,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.0,
            height: 32.0,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2234),
              borderRadius: BorderRadius.circular(9.0),
            ),
            alignment: Alignment.center,
            child: iconWidget,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (desc != null) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.0,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
