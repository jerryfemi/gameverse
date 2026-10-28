import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/match_state.dart';

/// End-of-match recap card for Paintball 1v1 duels.
///
/// Follows GameVerse design standards:
/// - Obsidian dark card with vibrant neon outcome border & glow halo.
/// - Winner crowned with golden medallion and verdict explanation.
/// - Two player columns side-by-side with avatars, surviving hit pips, and big hit scores.
/// - Head-to-head performance comparison matrix (Hits, Shots, Accuracy, Dodges, Survival).
/// - Instant rematch button with haptic feedback.
class PaintballResultCard extends StatelessWidget {
  final PaintballMatchState match;
  final VoidCallback onRematch;
  final VoidCallback? onLobby;

  const PaintballResultCard({
    super.key,
    required this.match,
    required this.onRematch,
    this.onLobby,
  });

  @override
  Widget build(BuildContext context) {
    final isWinner = match.winner == PaintballWinner.you;
    final isTie = match.winner == PaintballWinner.tie;

    final themeColor = isWinner
        ? const Color(0xFF00FFCC)
        : (isTie ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    final durationSeconds = (PaintballK.matchDurationSeconds - match.timeRemaining)
        .clamp(0, PaintballK.matchDurationSeconds)
        .toInt();
    final durationStr = '${durationSeconds ~/ 60}:${(durationSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF131D31),
                Color(0xFF0B1020),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: themeColor.withValues(alpha: 0.80), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.22),
                blurRadius: 32,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 1. Medallion & Title ───────────────────────────────────────
              _buildVerdictMedallion(isWinner, isTie, themeColor),
              const SizedBox(height: 12),
              Text(
                isWinner ? 'VICTORY!' : (isTie ? 'SUDDEN DEATH DRAW' : 'DEFEAT'),
                style: UiFont.style(
                  size: 26,
                  weight: 900,
                  color: themeColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isWinner
                    ? 'You eliminated the opponent in $durationStr!'
                    : (isTie
                        ? 'Match tied after sudden death!'
                        : 'You took 3 hits in the arena. Better luck next time!'),
                textAlign: TextAlign.center,
                style: UiFont.style(
                  size: 13,
                  weight: 500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 20),

              // ── 2. Versus Header (Avatars, Crowns, Big Scores) ──────────────
              _buildPlayersVersus(isWinner, isTie),
              const SizedBox(height: 20),

              // ── 3. Head-to-Head Performance Matrix ────────────────────────
              _buildStatsTable(durationStr),
              const SizedBox(height: 24),

              // ── 4. Action Buttons ──────────────────────────────────────────
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerdictMedallion(bool isWinner, bool isTie, Color themeColor) {
    final IconData icon = isWinner
        ? Icons.emoji_events_rounded
        : (isTie ? Icons.handshake_rounded : Icons.shield_outlined);

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: themeColor.withValues(alpha: 0.15),
        border: Border.all(color: themeColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.35),
            blurRadius: 18,
          ),
        ],
      ),
      child: Icon(icon, color: themeColor, size: 32),
    );
  }

  Widget _buildPlayersVersus(bool isWinner, bool isTie) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          // Player (YOU)
          Expanded(
            child: _buildPlayerCard(
              name: 'YOU',
              nameColor: const Color(0xFF38BDF8),
              avatarBg: const Color(0xFF0284C7),
              avatarIcon: Icons.military_tech_rounded,
              isCrowned: isWinner,
              hitsTaken: match.you.hitsTaken,
              shotsHit: match.you.shotsHit,
              isLeft: true,
            ),
          ),

          // VS Divider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'VS',
              style: UiFont.style(
                size: 11,
                weight: 900,
                color: const Color(0xFF64748B),
                letterSpacing: 1.0,
              ),
            ),
          ),

          // Opponent (BOT)
          Expanded(
            child: _buildPlayerCard(
              name: 'BOT',
              nameColor: const Color(0xFFF59E0B),
              avatarBg: const Color(0xFFD97706),
              avatarIcon: Icons.smart_toy_rounded,
              isCrowned: !isWinner && !isTie,
              hitsTaken: match.opponent.hitsTaken,
              shotsHit: match.opponent.shotsHit,
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard({
    required String name,
    required Color nameColor,
    required Color avatarBg,
    required IconData avatarIcon,
    required bool isCrowned,
    required int hitsTaken,
    required int shotsHit,
    required bool isLeft,
  }) {
    return Column(
      children: [
        // Avatar + Optional Crown
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarBg.withValues(alpha: 0.25),
                border: Border.all(color: nameColor, width: 1.5),
              ),
              child: Icon(avatarIcon, color: nameColor, size: 24),
            ),
            if (isCrowned)
              const Positioned(
                top: -14,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFFACC15),
                  size: 22,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        Text(
          name,
          style: UiFont.style(size: 13, weight: 800, color: nameColor),
        ),
        const SizedBox(height: 4),

        // Surviving Hit Pips (3 pips, filled = alive, hollow = damaged)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(PaintballK.hitsToWin, (i) {
            final isDamaged = i < hitsTaken;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDamaged ? Colors.transparent : nameColor,
                border: Border.all(
                  color: isDamaged ? const Color(0xFF475569) : nameColor,
                  width: 1.5,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),

        // Big Hit Score
        Text(
          '$shotsHit HITS',
          style: UiFont.style(size: 15, weight: 900, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildStatsTable(String durationStr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          _buildStatRow(
            label: 'Hits Landed',
            val1: '${match.you.shotsHit}',
            val2: '${match.opponent.shotsHit}',
            isVal1Better: match.you.shotsHit > match.opponent.shotsHit,
            isVal2Better: match.opponent.shotsHit > match.you.shotsHit,
          ),
          const Divider(color: Color(0xFF1E293B), height: 16),
          _buildStatRow(
            label: 'Shots Fired',
            val1: '${match.you.shotsFired}',
            val2: '${match.opponent.shotsFired}',
          ),
          const Divider(color: Color(0xFF1E293B), height: 16),
          _buildStatRow(
            label: 'Accuracy',
            val1: '${match.you.accuracyPercent.toStringAsFixed(1)}%',
            val2: '${match.opponent.accuracyPercent.toStringAsFixed(1)}%',
            isVal1Better: match.you.accuracyPercent > match.opponent.accuracyPercent,
            isVal2Better: match.opponent.accuracyPercent > match.you.accuracyPercent,
          ),
          const Divider(color: Color(0xFF1E293B), height: 16),
          _buildStatRow(
            label: 'Times Dodged',
            val1: '${match.you.timesDodged}',
            val2: '${match.opponent.timesDodged}',
            isVal1Better: match.you.timesDodged > match.opponent.timesDodged,
            isVal2Better: match.opponent.timesDodged > match.you.timesDodged,
          ),
          const Divider(color: Color(0xFF1E293B), height: 16),
          _buildStatRow(
            label: 'Longest Survival',
            val1: '${match.you.longestSurvivalSeconds.toStringAsFixed(1)}s',
            val2: '${match.opponent.longestSurvivalSeconds.toStringAsFixed(1)}s',
            isVal1Better: match.you.longestSurvivalSeconds > match.opponent.longestSurvivalSeconds,
            isVal2Better: match.opponent.longestSurvivalSeconds > match.you.longestSurvivalSeconds,
          ),
          const Divider(color: Color(0xFF1E293B), height: 16),
          _buildStatRow(
            label: 'Duration',
            val1: durationStr,
            val2: durationStr,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String val1,
    required String val2,
    bool isVal1Better = false,
    bool isVal2Better = false,
  }) {
    return Row(
      children: [
        // Player 1 Value
        SizedBox(
          width: 65,
          child: Text(
            val1,
            style: UiFont.style(
              size: 13,
              weight: isVal1Better ? 800 : 600,
              color: isVal1Better ? const Color(0xFF38BDF8) : Colors.white,
            ),
          ),
        ),

        // Metric Label
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: UiFont.style(
              size: 12,
              weight: 600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),

        // Player 2 Value
        SizedBox(
          width: 65,
          child: Text(
            val2,
            textAlign: TextAlign.right,
            style: UiFont.style(
              size: 13,
              weight: isVal2Better ? 800 : 600,
              color: isVal2Better ? const Color(0xFFF59E0B) : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (onLobby != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onLobby!();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF94A3B8),
                side: const BorderSide(color: Color(0xFF334155)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'LOBBY',
                style: UiFont.style(size: 12.5, weight: 800, color: const Color(0xFF94A3B8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.heavyImpact();
              onRematch();
            },
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: Text(
              'PLAY AGAIN',
              style: UiFont.style(
                size: 13,
                weight: 900,
                color: const Color(0xFF0A0E1A),
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: const Color(0xFF0A0E1A),
              elevation: 4,
              shadowColor: const Color(0xFF38BDF8).withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
