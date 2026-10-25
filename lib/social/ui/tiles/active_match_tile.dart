import 'dart:async';
import 'dart:math' as math;
import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../archery/state/archery_rules.dart';
import '../../../darts/state/darts_rules.dart';
import '../../../models/cloud_match.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_match_service.dart';
import '../common/crown_avatar.dart';
import '../common/game_chip.dart';

/// Card widget for active matches adhering to Artboard 10 of GameVerse design.
///
/// Supports three canonical states:
/// 1. Your Turn: Mint glow, "YOUR TURN" filled pill, game action CTA.
/// 2. Waiting On Them: Dark card, amber "THEIR TURN" pill, lead narrative, "Watch live".
/// 3. Invite Not Joined: Dark card, slate "NOT JOINED" pill, code copy with confirmation, cancel.
class ActiveMatchTile extends StatefulWidget {
  final CloudMatch match;
  final String? myUid;
  final VoidCallback? onPlay;

  const ActiveMatchTile({
    super.key,
    required this.match,
    this.myUid,
    this.onPlay,
  });

  @override
  State<ActiveMatchTile> createState() => _ActiveMatchTileState();
}

class _ActiveMatchTileState extends State<ActiveMatchTile> {
  bool _codeCopied = false;
  Timer? _copyResetTimer;

  @override
  void dispose() {
    _copyResetTimer?.cancel();
    super.dispose();
  }

  void _copyJoinCode() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.match.joinCode));
    setState(() => _codeCopied = true);
    _copyResetTimer?.cancel();
    _copyResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _codeCopied = false);
      }
    });
  }

  Future<void> _cancelInvite(BuildContext context, String effectiveUid) async {
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
        matchId: widget.match.id,
        myUid: effectiveUid,
      );
    }
  }

  void _navigateToMatch() {
    HapticFeedback.mediumImpact();
    if (widget.onPlay != null) {
      widget.onPlay!();
    } else {
      GoRouter.maybeOf(context)?.go('/match/${widget.match.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUid =
        widget.myUid ?? AuthService.instance.currentUser?.uid ?? '';
    final match = widget.match;
    final isInvite =
        match.status == MatchStatus.waitingForOpponent || match.player2 == null;
    final isMyTurn = !isInvite && match.isMyTurn(effectiveUid);

    if (isInvite) {
      return _buildInviteCard(context, effectiveUid);
    } else if (isMyTurn) {
      return _buildYourTurnCard(context, effectiveUid);
    } else {
      return _buildTheirTurnCard(context, effectiveUid);
    }
  }

  // ---------------------------------------------------------------------------
  // 1. YOUR TURN CARD (Artboard 10 - top card)
  // ---------------------------------------------------------------------------
  Widget _buildYourTurnCard(BuildContext context, String effectiveUid) {
    final match = widget.match;
    final myPlayer = match.myPlayer(effectiveUid);
    final oppPlayer = match.opponentPlayer(effectiveUid);
    final oppName = oppPlayer?.displayName ?? 'Opponent';

    final scoreData = _computeScores(effectiveUid);
    final roundText = _computeRoundText();

    final ctaVerb = match.isDarts
        ? 'THROW YOUR TURN'
        : (match.isArchery ? 'SHOOT YOUR SET' : 'SHOOT YOUR TURN');
    final ctaIcon = match.isDarts
        ? Icons.adjust_rounded
        : (match.isArchery
            ? Icons.arrow_outward_rounded
            : Icons.sports_basketball_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A1F),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color(0xFF00FFCC),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2900FFCC),
            blurRadius: 12.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: GameChip, Round text, YOUR TURN pill
          Row(
            children: [
              GameChip.fromMatch(match),
              const SizedBox(width: 10.0),
              Text(
                roundText,
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
                  color: const Color(0xFF00FFCC),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'YOUR TURN',
                  style: UiFont.style(
                    size: 11.0,
                    weight: 900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Row 2: Scores and Avatars
          _buildScoreRow(
            myAvatar: myPlayer?.avatarEmoji ?? '👤',
            oppAvatar: oppPlayer?.avatarEmoji ?? '⏳',
            oppName: oppName,
            scoreData: scoreData,
          ),
          const SizedBox(height: 14.0),

          // Row 3: Action Button (Primary CTA)
          SizedBox(
            height: 44.0,
            child: ElevatedButton.icon(
              onPressed: _navigateToMatch,
              icon: Icon(ctaIcon, size: 16.0),
              label: Text(
                ctaVerb,
                style: UiFont.style(
                  size: 13.0,
                  weight: 900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: 0.6,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFCC),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. THEIR TURN CARD (Artboard 10 - middle card)
  // ---------------------------------------------------------------------------
  Widget _buildTheirTurnCard(BuildContext context, String effectiveUid) {
    final match = widget.match;
    final myPlayer = match.myPlayer(effectiveUid);
    final oppPlayer = match.opponentPlayer(effectiveUid);
    final oppName = oppPlayer?.displayName ?? 'Opponent';

    final scoreData = _computeScores(effectiveUid);
    final roundText = _computeRoundText();
    final narrative = _computeLeadNarrative(oppName, scoreData);

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
          // Row 1: GameChip, Round text, THEIR TURN pill
          Row(
            children: [
              GameChip.fromMatch(match),
              const SizedBox(width: 10.0),
              Text(
                roundText,
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
                  color: const Color(0x26F59E0B),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'THEIR TURN',
                  style: UiFont.style(
                    size: 11.0,
                    weight: 900,
                    color: const Color(0xFFF59E0B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Row 2: Scores and Avatars
          _buildScoreRow(
            myAvatar: myPlayer?.avatarEmoji ?? '👤',
            oppAvatar: oppPlayer?.avatarEmoji ?? '⏳',
            oppName: oppName,
            scoreData: scoreData,
          ),
          const SizedBox(height: 10.0),

          // Row 3: Narrative sentence
          Text(
            narrative,
            style: UiFont.style(
              size: 13.0,
              weight: 600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12.0),

          // Row 4: Watch live Action Button
          SizedBox(
            height: 40.0,
            child: ElevatedButton(
              onPressed: _navigateToMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 0,
              ),
              child: Text(
                'Watch live',
                style: UiFont.style(
                  size: 13.0,
                  weight: 800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. INVITE NOT JOINED CARD (Artboard 10 - bottom card)
  // ---------------------------------------------------------------------------
  Widget _buildInviteCard(BuildContext context, String effectiveUid) {
    final match = widget.match;
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
                    onPressed: _copyJoinCode,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2638),
                      side: BorderSide(
                        color: _codeCopied
                            ? const Color(0xFF00FFCC)
                            : const Color(0xFF2A344A),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      _codeCopied ? '✓ CODE COPIED' : 'Copy code',
                      style: UiFont.style(
                        size: 12.5,
                        weight: 800,
                        color: _codeCopied
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
                    onPressed: () => _cancelInvite(context, effectiveUid),
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

  // ---------------------------------------------------------------------------
  // Shared Score Row Builder
  // ---------------------------------------------------------------------------
  Widget _buildScoreRow({
    required String myAvatar,
    required String oppAvatar,
    required String oppName,
    required _ScoreResult scoreData,
  }) {
    return Row(
      children: [
        CrownAvatar(avatar: myAvatar, size: 40.0),
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
              const SizedBox(height: 1.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    scoreData.myValue,
                    style: UiFont.style(
                      size: 20.0,
                      weight: 900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    scoreData.myUnit,
                    style: UiFont.style(
                      size: 12.0,
                      weight: 600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
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
              const SizedBox(height: 1.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    scoreData.oppUnit,
                    style: UiFont.style(
                      size: 12.0,
                      weight: 600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    scoreData.oppValue,
                    style: UiFont.style(
                      size: 20.0,
                      weight: 900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10.0),
        CrownAvatar(avatar: oppAvatar, size: 40.0),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Score Calculations
  // ---------------------------------------------------------------------------
  _ScoreResult _computeScores(String effectiveUid) {
    final match = widget.match;
    final myPlayer = match.myPlayer(effectiveUid);
    final oppPlayer = match.opponentPlayer(effectiveUid);

    if (match.isDarts) {
      final myRemaining =
          DartsRules.remaining(myPlayer?.roundScores ?? const []);
      final oppRemaining =
          DartsRules.remaining(oppPlayer?.roundScores ?? const []);
      return _ScoreResult(
        myValue: '$myRemaining',
        myUnit: 'left',
        oppValue: '$oppRemaining',
        oppUnit: 'left',
        myRaw: myRemaining,
        oppRaw: oppRemaining,
      );
    } else if (match.isArchery) {
      final isP1Me = match.player1.uid == effectiveUid;
      final sp = ArcheryRules.setPoints(
        match.player1.roundScores,
        match.player2?.roundScores ?? const [],
      );
      final mySets = isP1Me ? sp.you : sp.them;
      final oppSets = isP1Me ? sp.them : sp.you;
      return _ScoreResult(
        myValue: '$mySets',
        myUnit: 'sets',
        oppValue: '$oppSets',
        oppUnit: 'sets',
        myRaw: mySets,
        oppRaw: oppSets,
      );
    } else {
      final myScore = myPlayer?.totalScore ?? 0;
      final oppScore = oppPlayer?.totalScore ?? 0;
      return _ScoreResult(
        myValue: '$myScore',
        myUnit: 'pts',
        oppValue: '$oppScore',
        oppUnit: 'pts',
        myRaw: myScore,
        oppRaw: oppScore,
      );
    }
  }

  String _computeRoundText() {
    final match = widget.match;
    final p1Rounds = match.player1.roundScores.length;
    final p2Rounds = match.player2?.roundScores.length ?? 0;
    final currentRound = math.max(p1Rounds, p2Rounds) + 1;
    final totalRounds = match.totalRounds > 0
        ? match.totalRounds
        : (match.isDarts ? 20 : (match.isArchery ? 5 : 2));

    final effectiveRound = math.min(currentRound, totalRounds);
    return 'Round $effectiveRound of $totalRounds';
  }

  String _computeLeadNarrative(String oppName, _ScoreResult scoreData) {
    final match = widget.match;
    final verb = match.isDarts
        ? 'throwing'
        : (match.isArchery ? 'shooting set' : 'shooting');

    final p1Rounds = match.player1.roundScores.length;
    final p2Rounds = match.player2?.roundScores.length ?? 0;
    final roundNumber = math.max(p1Rounds, p2Rounds) + 1;

    final String leadStr;
    if (match.isDarts) {
      final diff = scoreData.oppRaw - scoreData.myRaw; // less left is leading
      if (diff > 0) {
        leadStr = 'You lead by $diff.';
      } else if (diff < 0) {
        leadStr = '$oppName leads by ${-diff}.';
      } else {
        leadStr = 'Tied.';
      }
    } else {
      final diff = scoreData.myRaw - scoreData.oppRaw; // more is leading
      if (diff > 0) {
        leadStr = 'You lead by $diff.';
      } else if (diff < 0) {
        leadStr = '$oppName leads by ${-diff}.';
      } else {
        leadStr = 'Tied.';
      }
    }

    return '$oppName is $verb round $roundNumber now. $leadStr';
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

class _ScoreResult {
  final String myValue;
  final String myUnit;
  final String oppValue;
  final String oppUnit;
  final int myRaw;
  final int oppRaw;

  const _ScoreResult({
    required this.myValue,
    required this.myUnit,
    required this.oppValue,
    required this.oppUnit,
    required this.myRaw,
    required this.oppRaw,
  });
}
