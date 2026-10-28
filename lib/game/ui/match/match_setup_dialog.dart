import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:share_plus/share_plus.dart';

import 'package:b_ball/archery/state/archery_rules.dart';
import 'package:b_ball/darts/state/darts_rules.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/models/friend_profile.dart';
import 'package:b_ball/models/player_descriptor.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/firestore_match_service.dart';
import 'package:b_ball/services/update/update_platform.dart';
import 'package:b_ball/game/match/match_config.dart';
import 'package:b_ball/game/ui/common/app_colors.dart';
import 'package:b_ball/game/ui/common/inline_feedback.dart';
import 'package:b_ball/game/ui/inbox/join_match_dialog.dart';
import 'package:b_ball/game/ui/match/components/friend_selector_ribbon.dart';
import 'package:b_ball/game/ui/match/components/match_code_reveal_card.dart';
import 'package:b_ball/game/ui/match/components/match_game_cards.dart';
import 'package:b_ball/game/ui/match/components/match_hoops_settings_card.dart';
import 'package:b_ball/game/ui/match/components/match_rules_card.dart';

/// "Play a friend" modal dialog matching Design Templates 16 and 17:
/// - Game selection cards (HOOPS, ARCHERY, DARTS, PAINTBALL)
/// - Mode switcher (Share a code / A friend)
/// - Hoops match settings (Rounds, Shot clock, Difficulty)
/// - Friend radio-picker list
/// - FittedBox responsive scaling (< 250 lines)
class MatchSetupDialog extends HookWidget {
  final MatchConfig initialConfig;
  final bool showGamePicker;
  final bool allowJoin;

  const MatchSetupDialog({
    super.key,
    this.initialConfig = const MatchConfig(),
    this.showGamePicker = true,
    this.allowJoin = true,
  });

  static Future<MatchConfig?> show(
    BuildContext context, {
    MatchConfig initialConfig = const MatchConfig(),
    bool showGamePicker = true,
    bool allowJoin = true,
  }) {
    return showDialog<MatchConfig>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => MatchSetupDialog(
        initialConfig: initialConfig,
        showGamePicker: showGamePicker,
        allowJoin: allowJoin,
      ),
    );
  }

  static const Color _hoops = Color(0xFFF59E0B);
  static const Color _archery = Color(0xFF00FFCC);
  static const Color _darts = Color(0xFF38BDF8);
  static const Color _paintball = Color(0xFFF472B6);

  @override
  Widget build(BuildContext context) {
    final selectedGame = useState(initialConfig.game);
    final bool isArchery = selectedGame.value == 'archery';
    final bool isDarts = selectedGame.value == 'darts';
    final bool isPaintball = selectedGame.value == 'paintball';
    final bool fixedRules = isArchery || isDarts || isPaintball;

    MatchConfig withGameRules(MatchConfig c) => switch (selectedGame.value) {
          'archery' => c.copyWith(
              game: 'archery',
              totalRounds: ArcheryRules.maxSets,
              roundDurationSeconds: ArcheryRules.onlineSetSeconds,
            ),
          'darts' => c.copyWith(
              game: 'darts',
              totalRounds: DartsRules.maxRounds,
              roundDurationSeconds: DartsRules.onlineTurnSeconds,
            ),
          'paintball' => c.copyWith(
              game: 'paintball',
              totalRounds: 1,
              roundDurationSeconds: PaintballK.matchDurationSeconds,
            ),
          _ => c.copyWith(game: selectedGame.value),
        };

    final selectedRounds = useState(initialConfig.totalRounds);
    final selectedDuration = useState(initialConfig.roundDurationSeconds);
    final selectedDifficulty = useState(initialConfig.difficulty);
    final opponentMode = useState(initialConfig.opponentFriend != null ? 1 : 0);
    final selectedFriend = useState<FriendProfile?>(initialConfig.opponentFriend);
    final isGeneratingCode = useState(false);
    final precreatedMatch = useState<CloudMatch?>(null);
    final codeCopied = useState(false);
    final codeError = useState<String?>(null);
    final showPickFriendHint = useState(false);

    Future<void> generateUpfrontCode(UserProfile? knownProfile) async {
      if (isGeneratingCode.value) return;
      codeError.value = null;
      if (!isDeviceOnline()) {
        codeError.value = 'You\'re offline. Reconnect to the internet to create a 1v1 match.';
        return;
      }
      isGeneratingCode.value = true;
      try {
        final profile = knownProfile ??
            AuthService.instance.currentUser ??
            await AuthService.instance.initialize();
        final config = withGameRules(MatchConfig(
          totalRounds: selectedRounds.value,
          roundDurationSeconds: selectedDuration.value,
          difficulty: selectedDifficulty.value,
          player1Name: profile.displayName,
          player1Avatar: profile.avatarEmoji,
          player2Name: 'Opponent',
          player2Avatar: '⏳',
        ));
        final match = await FirestoreMatchService.instance.createMatch(
          config: config,
          player1Profile: profile,
        );
        if (context.mounted) {
          precreatedMatch.value = match;
          codeCopied.value = false;
          isGeneratingCode.value = false;
        }
        HapticFeedback.mediumImpact();
        try {
          await Clipboard.setData(ClipboardData(text: match.joinCode));
          if (context.mounted) codeCopied.value = true;
        } catch (_) {}
      } catch (e) {
        if (context.mounted) {
          isGeneratingCode.value = false;
          codeError.value = InlineErrorPanel.friendlyMessage(
            e,
            fallback: 'Couldn\'t generate a match code. Please try again.',
          );
        }
      }
    }

    Future<void> copyCode() async {
      final match = precreatedMatch.value;
      if (match == null) return;
      try {
        await Clipboard.setData(ClipboardData(text: match.joinCode));
        HapticFeedback.lightImpact();
        codeCopied.value = true;
      } catch (_) {}
    }

    Future<void> shareCode() async {
      final match = precreatedMatch.value;
      if (match == null) return;
      HapticFeedback.lightImpact();
      final code = match.joinCode;
      final text = match.isArchery
          ? '🎯 Shoot archery with me on GameVerse! Match code: $code\nhttps://dunkverse.web.app/match/$code'
          : match.isPaintball
              ? '🎨 Paintball duel on GameVerse! Best of 3 rounds. Match code: $code\nhttps://dunkverse.web.app/match/$code'
          : match.isDarts
              ? '🎯 Play me at darts on GameVerse! 301, first to zero. Match code: $code\nhttps://dunkverse.web.app/match/$code'
              : '🏀 Play me 1v1 on DunkVerse! Match code: $code\nhttps://dunkverse.web.app/match/$code';
      try {
        await SharePlus.instance.share(ShareParams(text: text));
      } catch (_) {
        try {
          await Clipboard.setData(ClipboardData(text: text));
          codeCopied.value = true;
        } catch (_) {}
      }
    }

    void onStartPressed() {
      HapticFeedback.mediumImpact();
      if (opponentMode.value == 1 && selectedFriend.value == null) {
        showPickFriendHint.value = true;
        return;
      }

      final profile = AuthService.instance.currentUser;
      final myName = profile?.displayName ?? 'Player';
      final myAvatar = profile?.avatarEmoji ?? PlayerDescriptor.defaultAvatar;
      final isFriendMode = opponentMode.value == 1 && selectedFriend.value != null;

      final config = withGameRules(MatchConfig(
        totalRounds: selectedRounds.value,
        roundDurationSeconds: selectedDuration.value,
        difficulty: selectedDifficulty.value,
        player1Name: myName,
        player1Avatar: myAvatar,
        player2Name: isFriendMode ? selectedFriend.value!.displayName : 'Opponent',
        player2Avatar: isFriendMode ? selectedFriend.value!.avatarEmoji : '⏳',
        player2Uid: isFriendMode ? selectedFriend.value?.uid : null,
        opponentFriend: isFriendMode ? selectedFriend.value : null,
        precreatedMatch: isFriendMode ? null : precreatedMatch.value,
      ));

      Navigator.of(context).pop(config);
    }

    Future<void> joinWithCode() async {
      final joined = await JoinMatchDialog.show(context);
      if (joined != null && context.mounted) {
        Navigator.of(context).pop(MatchConfig(game: joined.game, joinedMatch: joined));
      }
    }

    final bool codeMode = opponentMode.value == 0;
    final bool hasCode = precreatedMatch.value != null;

    String primaryLabel() {
      if (!codeMode) {
        final f = selectedFriend.value;
        return f == null ? 'PICK A FRIEND' : 'CHALLENGE ${f.displayName.toUpperCase()}';
      }
      return hasCode ? 'ENTER MATCH LOBBY' : 'GET MATCH CODE';
    }

    void onPrimary() {
      if (codeMode && !hasCode) {
        generateUpfrontCode(AuthService.instance.currentUser);
        return;
      }
      onStartPressed();
    }

    final profile = AuthService.instance.currentUser;
    final Color gameAccent = isPaintball
        ? _paintball
        : (isArchery ? _archery : (isDarts ? _darts : _hoops));

    final String subtitleText = isPaintball
        ? 'Live duel, best of 3 rounds'
        : isArchery
        ? 'Sets of 3 arrows, first to 6 set points'
        : (isDarts
            ? '301 down to zero, checkout on a double'
            : 'Take turns, highest total wins');

    final maxH = MediaQuery.sizeOf(context).height * 0.90;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      elevation: 0,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 360.0, maxHeight: maxH),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1424),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0xCC000000), blurRadius: 36.0, offset: Offset(0, 14)),
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
                                'Play a friend',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                subtitleText,
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
                            child: const Icon(Icons.close_rounded, size: 18.0, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // Game Selection Cards (Hoops, Archery, Darts, Paintball)
                    if (showGamePicker) ...[
                      MatchGameCards(
                        selectedGame: selectedGame.value,
                        enabled: !hasCode,
                        onGameSelected: (game) => selectedGame.value = game,
                      ),
                      const SizedBox(height: 12.0),
                    ],

                    // Mode Switcher: Share a code vs A friend
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF090E1A),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: const Color(0xFF1E2638)),
                      ),
                      child: Row(
                        children: [
                          _buildModeTab(
                            title: 'Share a code',
                            icon: Icons.tag_rounded,
                            isSelected: opponentMode.value == 0,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              opponentMode.value = 0;
                            },
                          ),
                          _buildModeTab(
                            title: 'A friend',
                            icon: Icons.people_alt_rounded,
                            isSelected: opponentMode.value == 1,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              opponentMode.value = 1;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    // Dynamic Body
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (codeMode) ...[
                              if (hasCode)
                                MatchCodeRevealCard(
                                  code: precreatedMatch.value!.joinCode,
                                  copied: codeCopied.value,
                                  onCopy: copyCode,
                                  onShare: shareCode,
                                )
                              else if (!fixedRules)
                                MatchHoopsSettingsCard(
                                  rounds: selectedRounds.value,
                                  duration: selectedDuration.value,
                                  difficulty: selectedDifficulty.value,
                                  onRoundsChanged: (r) => selectedRounds.value = r,
                                  onDurationChanged: (d) => selectedDuration.value = d,
                                  onDifficultyChanged: (diff) => selectedDifficulty.value = diff,
                                )
                              else
                                MatchRulesCard(isArchery: isArchery, isPaintball: isPaintball),
                            ] else ...[
                              FriendSelectorRibbon(
                                profile: profile,
                                selectedFriend: selectedFriend.value,
                                onFriendSelected: (friend) {
                                  selectedFriend.value = friend;
                                  showPickFriendHint.value = false;
                                },
                                onUseOpenCode: () => opponentMode.value = 0,
                              ),
                            ],

                            // Inline Error / Hint
                            if (codeError.value != null && codeMode) ...[
                              const SizedBox(height: 10.0),
                              InlineErrorPanel(
                                title: 'MATCH CODE UNAVAILABLE',
                                message: codeError.value!,
                                onRetry: () => generateUpfrontCode(profile),
                                onDismiss: () => codeError.value = null,
                              ),
                            ],
                            if (showPickFriendHint.value && !codeMode && selectedFriend.value == null) ...[
                              const SizedBox(height: 10.0),
                              InlineErrorPanel(
                                icon: Icons.people_alt_rounded,
                                accent: AppColors.accentAmber,
                                title: 'PICK A FRIEND',
                                message: 'Select a friend from the list above, or share a code instead.',
                                onDismiss: () => showPickFriendHint.value = false,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Primary Action Button
                    ElevatedButton(
                      onPressed: isGeneratingCode.value ? null : onPrimary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gameAccent,
                        foregroundColor: const Color(0xFF0A0E1A),
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                      ),
                      child: isGeneratingCode.value
                          ? const SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFF0A0E1A),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  codeMode
                                      ? (hasCode ? Icons.arrow_forward_rounded : Icons.tag_rounded)
                                      : Icons.send_rounded,
                                  size: 18.0,
                                ),
                                const SizedBox(width: 6.0),
                                Text(
                                  primaryLabel(),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                    ),

                    // Bottom Link: Got a code? Join with a code
                    if (allowJoin) ...[
                      const SizedBox(height: 10.0),
                      Center(
                        child: GestureDetector(
                          onTap: joinWithCode,
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12.0,
                                fontFamily: 'Inter',
                              ),
                              children: [
                                TextSpan(text: 'Got a code? '),
                                TextSpan(
                                  text: 'Join with a code',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8.5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E2638) : Colors.transparent,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14.0,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5.0),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
