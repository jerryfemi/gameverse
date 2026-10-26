import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/firestore_match_service.dart';

/// Modal dialog for entering a 6-character arcade code to join a remote match,
/// matching Design Template 14.
class JoinMatchDialog extends HookWidget {
  const JoinMatchDialog({super.key});

  static Future<CloudMatch?> show(BuildContext context) {
    return showDialog<CloudMatch>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => const JoinMatchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final codeLength = useState<int>(0);
    final isLoading = useState<bool>(false);
    final errorMessage = useState<({String title, String message})?>(null);

    useEffect(() {
      void listener() {
        final text = controller.text.toUpperCase();
        if (text != controller.text) {
          controller.value = controller.value.copyWith(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
        codeLength.value = text.length;
        if (errorMessage.value != null) {
          errorMessage.value = null;
        }
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    Future<void> handleJoin() async {
      final code = controller.text.trim().toUpperCase();
      if (code.length != 6) {
        errorMessage.value = (
          title: 'Invalid code length',
          message: 'Code must be exactly 6 characters.',
        );
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        final user = await AuthService.instance.ensureAuthenticated();
        final currentProfile = AuthService.instance.currentUser ??
            UserProfile(
              uid: user.uid,
              displayName: user.displayName ?? 'Player',
              avatarEmoji: '⚡',
            );

        final match = await FirestoreMatchService.instance.joinMatchByCode(
          joinCode: code,
          player2Profile: currentProfile,
        );

        HapticFeedback.mediumImpact();
        if (context.mounted) {
          Navigator.of(context).pop(match);
        }
      } on MatchNotFoundException {
        errorMessage.value = (
          title: 'Code not found',
          message: 'No match with that code. It may have expired.',
        );
      } on MatchClosedException catch (e) {
        errorMessage.value = (
          title: 'Match closed',
          message: e.message,
        );
      } on SelfJoinException catch (e) {
        errorMessage.value = (
          title: 'Cannot join own match',
          message: e.message,
        );
      } on MatchAlreadyFullException catch (e) {
        errorMessage.value = (
          title: 'Match is full',
          message: e.message,
        );
      } catch (e) {
        final raw = e.toString();
        final cleanMsg = raw
            .replaceAll(
              RegExp(r'^(Exception:|Error:(\s*Dart Exception:)?)\s*', caseSensitive: false),
              '',
            )
            .trim();
        errorMessage.value = (
          title: 'Unable to join',
          message: cleanMsg.isNotEmpty ? cleanMsg : 'Please check the code and try again.',
        );
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    Future<void> handlePaste() async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null) return;
      HapticFeedback.lightImpact();
      final clean = data!.text!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      final take = clean.length > 6 ? clean.substring(0, 6) : clean;
      controller.text = take;
      focusNode.requestFocus();
    }

    final media = MediaQuery.of(context);
    final maxH = media.size.height * 0.88;
    final isComplete = codeLength.value == 6;

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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Join a match',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 3.0),
                              Text(
                                'Enter the 6-character code your friend sent',
                                style: TextStyle(
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
                    const SizedBox(height: 20.0),

                    // 6 Pin Code Input Boxes with Hidden Text Input
                    GestureDetector(
                      onTap: () => focusNode.requestFocus(),
                      behavior: HitTestBehavior.opaque,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 6 Visual Pin Boxes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              final currentText = controller.text;
                              final char = index < currentText.length ? currentText[index] : '';
                              final isCurrent = index == currentText.length && focusNode.hasFocus;
                              final hasChar = char.isNotEmpty;

                              return Container(
                                width: 46.0,
                                height: 56.0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111827),
                                  borderRadius: BorderRadius.circular(14.0),
                                  border: Border.all(
                                    color: isCurrent
                                        ? const Color(0xFF00FFCC)
                                        : (hasChar ? const Color(0xFF334155) : const Color(0xFF1E2638)),
                                    width: isCurrent ? 1.8 : 1.2,
                                  ),
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF00FFCC).withValues(alpha: 0.25),
                                            blurRadius: 8.0,
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: isCurrent
                                    ? Container(
                                        width: 2.0,
                                        height: 24.0,
                                        color: const Color(0xFF00FFCC),
                                      )
                                    : Text(
                                        char,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22.0,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0,
                                        ),
                                      ),
                              );
                            }),
                          ),

                          // Invisible full-size text field overlay for native keyboard input
                          Opacity(
                            opacity: 0.0,
                            child: TextField(
                              controller: controller,
                              focusNode: focusNode,
                              autofocus: true,
                              maxLength: 6,
                              textCapitalization: TextCapitalization.characters,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) {
                                if (isComplete) handleJoin();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Subtext & Paste Button Row
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Letters and numbers, not case sensitive',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: handlePaste,
                          borderRadius: BorderRadius.circular(16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2638),
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.paste_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 13.0,
                                ),
                                SizedBox(width: 4.0),
                                Text(
                                  'PASTE',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18.0),

                    // Join Match Primary Button
                    ElevatedButton(
                      onPressed: (!isComplete || isLoading.value) ? null : handleJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FFCC),
                        disabledBackgroundColor: const Color(0xFF0F2E2C),
                        foregroundColor: const Color(0xFF0A0E1A),
                        disabledForegroundColor: const Color(0xFF00FFCC).withValues(alpha: 0.4),
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                      ),
                      child: isLoading.value
                          ? const SizedBox(
                              width: 18.0,
                              height: 18.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFF0A0E1A),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login_rounded, size: 18.0),
                                SizedBox(width: 6.0),
                                Text(
                                  'JOIN MATCH',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                    ),

                    // Error Alert Banner matching Template 14
                    if (errorMessage.value != null) ...[
                      const SizedBox(height: 14.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22131C),
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1.0),
                              child: Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 18.0,
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    errorMessage.value!.title,
                                    style: const TextStyle(
                                      color: Color(0xFFFCA5A5),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 1.0),
                                  Text(
                                    errorMessage.value!.message,
                                    style: const TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontSize: 11.0,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
}
