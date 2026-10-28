import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/services/auth_service.dart';

/// Clean, modern Google account linking and status card for [ProfileSheet].
///
/// Prompts anonymous players to save their progress with Google, and renders
/// a muted, non-intrusive status pill when already linked.
class ProfileGoogleSyncCard extends HookWidget {
  final UserProfile? profile;

  const ProfileGoogleSyncCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);
    final inlineError = useState<String?>(null);
    final auth = AuthService.instance;
    final redirectError = useValueListenable(auth.googleSignInError);
    final justLinked = useValueListenable(auth.googleJustLinked);
    // Show the confirmation for a few seconds, then settle.
    useEffect(() {
      if (!justLinked) return null;
      HapticFeedback.lightImpact();
      final t = Future<void>.delayed(const Duration(seconds: 4), () {
        auth.googleJustLinked.value = false;
      });
      t.ignore();
      return null;
    }, [justLinked]);
    final shownError = inlineError.value ?? redirectError;
    final authUser = FirebaseAuth.instance.currentUser;
    final isLinked =
        (profile != null &&
            !profile!.isAnonymous &&
            profile!.email != null &&
            profile!.email!.isNotEmpty) ||
        (authUser != null &&
            !authUser.isAnonymous &&
            authUser.email != null &&
            authUser.email!.isNotEmpty);

    final displayEmail = (profile?.email != null && profile!.email!.isNotEmpty)
        ? profile!.email!
        : (authUser?.email ?? '');

    if (isLinked && displayEmail.isNotEmpty) {
      return _buildLinkedState(context, displayEmail, isLoading, justLinked);
    }

    return _buildUnlinkedState(context, isLoading, inlineError, shownError);
  }

  Widget _buildUnlinkedState(
    BuildContext context,
    ValueNotifier<bool> isLoading,
    ValueNotifier<String?> inlineError,
    String? shownError,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildGoogleLogoBadge(size: 34.0),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save your progress',
                      style: UiFont.style(
                        size: 14.0,
                        weight: 800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Play across devices & keep your record',
                      style: UiFont.style(
                        size: 11.5,
                        weight: 500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (shownError != null) ...[
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16.0,
                    color: Color(0xFFF87171),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      shownError,
                      style: UiFont.style(
                        size: 11.5,
                        weight: 600,
                        color: const Color(0xFFFECACA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14.0),
          SizedBox(
            height: 40.0,
            child: ElevatedButton(
              onPressed: isLoading.value
                  ? null
                  : () async {
                      HapticFeedback.lightImpact();
                      inlineError.value = null;
                      AuthService.instance.googleSignInError.value = null;
                      isLoading.value = true;
                      try {
                        await AuthService.instance.signInOrLinkWithGoogle();
                        // Success: the card swaps to the linked state with a
                        // "✓ GOOGLE LINKED" badge (AuthService.googleJustLinked).
                      } catch (e) {
                        debugPrint('[ProfileGoogleSyncCard] Sign in error: $e');
                        final errorMsg = e is FirebaseAuthException
                            ? AuthService.googleErrorMessage(e)
                            : 'Google sign-in failed. Try again.';
                        inlineError.value = errorMsg;
                      } finally {
                        isLoading.value = false;
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              child: isLoading.value
                  ? const SizedBox(
                      width: 18.0,
                      height: 18.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF0F172A),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGoogleColorG(size: 16.0),
                        const SizedBox(width: 8.0),
                        Text(
                          'Continue with Google',
                          style: UiFont.style(
                            size: 13.0,
                            weight: 800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedState(
    BuildContext context,
    String email,
    ValueNotifier<bool> isLoading,
    bool justLinked,
  ) {
    const green = Color(0xFF10B981);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1523),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: justLinked ? green.withValues(alpha: 0.7) : const Color(0xFF1E2638),
          width: justLinked ? 1.4 : 1.0,
        ),
        boxShadow: justLinked
            ? [BoxShadow(color: green.withValues(alpha: 0.25), blurRadius: 18.0)]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 22.0,
            height: 22.0,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF10B981),
              size: 14.0,
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    justLinked ? '✓ GOOGLE LINKED · PROGRESS SAVED' : 'GOOGLE ACCOUNT',
                    key: ValueKey(justLinked),
                    style: UiFont.style(
                      size: 9.5,
                      weight: 800,
                      color: justLinked ? green : const Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 1.0),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiFont.style(
                    size: 12.5,
                    weight: 700,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          TextButton(
            onPressed: isLoading.value
                ? null
                : () => _confirmSignOut(context, isLoading),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Sign out',
              style: UiFont.style(
                size: 11.5,
                weight: 700,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, ValueNotifier<bool> isLoading) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF131826),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
          side: const BorderSide(color: Color(0xFF2E3954), width: 1.2),
        ),
        title: Text(
          'Sign Out?',
          style: UiFont.style(size: 16.0, weight: 900, color: Colors.white),
        ),
        content: Text(
          'You can sign back in with this Google account anytime. Your match history and trophies are saved.',
          style: UiFont.style(
            size: 13.0,
            weight: 500,
            color: const Color(0xFF94A3B8),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'CANCEL',
              style: UiFont.style(
                size: 12.0,
                weight: 700,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              isLoading.value = true;
              try {
                await AuthService.instance.signOut();
              } finally {
                isLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Text(
              'SIGN OUT',
              style: UiFont.style(size: 12.0, weight: 800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleLogoBadge({required double size}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2638),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF334155), width: 1.0),
      ),
      child: Center(child: _buildGoogleColorG(size: size - 12.0)),
    );
  }

  Widget _buildGoogleColorG({required double size}) {
    return Image.asset(
      'assets/images/google_logo.webp',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            'G',
            style: TextStyle(
              color: const Color(0xFF4285F4),
              fontSize: size * 0.76,
              fontWeight: FontWeight.w900,
              fontFamily: 'sans-serif',
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
