import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:b_ball/firebase_options.dart';
import 'package:b_ball/models/player_descriptor.dart';
import 'package:b_ball/services/friends_service.dart';
import 'package:b_ball/services/vatar/vatar_bridge.dart';

/// Exception thrown when an online feature is attempted without valid Firebase authentication.
class AuthRequiredException implements Exception {
  final String message;
  const AuthRequiredException(this.message);

  @override
  String toString() => message;
}

/// Lightweight profile representation for the local player.
class UserProfile implements PlayerDescriptor {
  final String uid;
  @override
  final String displayName;
  final String avatarEmoji;
  final bool isAnonymous;
  final bool isFirebaseVerified;
  final String? email;

  @override
  String get id => uid;

  @override
  String get avatar => avatarEmoji;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.avatarEmoji,
    this.isAnonymous = true,
    this.isFirebaseVerified = false,
    this.email,
  });

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? avatarEmoji,
    bool? isAnonymous,
    bool? isFirebaseVerified,
    String? email,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isFirebaseVerified: isFirebaseVerified ?? this.isFirebaseVerified,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'avatarEmoji': avatarEmoji,
    'isAnonymous': isAnonymous,
    'isFirebaseVerified': isFirebaseVerified,
    if (email != null) 'email': email,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'] as String,
    displayName: json['displayName'] as String? ?? 'Player',
    avatarEmoji:
        json['avatarEmoji'] as String? ?? PlayerDescriptor.defaultAvatar,
    isAnonymous: json['isAnonymous'] as bool? ?? true,
    isFirebaseVerified: json['isFirebaseVerified'] as bool? ?? false,
    email: json['email'] as String?,
  );
}

/// Service handling silent background guest authentication,
/// local profile persistence, and reactive auth state updates.
class AuthService {
  final FriendsService? friendsService;

  AuthService({this.friendsService});

  AuthService._internal() : friendsService = null;
  static final AuthService instance = AuthService._internal();

  FriendsService get _effectiveFriendsService =>
      friendsService ?? FriendsService.instance;

  static const String _prefKeyUid = 'bball_local_guest_uid';
  static const String _prefKeyName = 'bball_player_name';
  static const String _prefKeyAvatar = 'bball_player_avatar';

  /// Real avatar assets available in the game
  static const List<String> avatarImageOptions = [
    'assets/avatars/dunk_heads (1).webp',
    'assets/avatars/dunk_heads (2).webp',
    'assets/avatars/dunk_heads (3).webp',
    'assets/avatars/dunk_heads (4).webp',
    'assets/avatars/dunk_heads (5).webp',
    'assets/avatars/dunk_heads (6).webp',
    'assets/avatars/dunk_heads (7).webp',
    'assets/avatars/dunk_heads (8).webp',
    'assets/avatars/dunk_heads (9).webp',
    'assets/avatars/dunk_heads (10).webp',
    'assets/avatars/dunk_heads (11).webp',
    'assets/avatars/dunk_heads (12).webp',
    'assets/avatars/dunk_heads (13).webp',
    'assets/avatars/dunk_heads (14).webp',
    'assets/avatars/dunk_heads (15).webp',
  ];

  static String getRandomAvatar() {
    final rand = Random();
    return avatarImageOptions[rand.nextInt(avatarImageOptions.length)];
  }

  final ValueNotifier<UserProfile?> currentUserNotifier =
      ValueNotifier<UserProfile?>(null);

  UserProfile? get currentUser => currentUserNotifier.value;

  /// Whether the user is confirmed and authenticated with Firebase Auth.
  bool get isAuthenticatedWithFirebase =>
      FirebaseAuth.instance.currentUser != null;

  Future<UserProfile>? _initFuture;

  /// Initializes Firebase and performs silent guest authentication.
  ///
  /// Caches the initialization Future so concurrent calls await the exact
  /// same operation, preventing duplicate anonymous user creation.
  Future<UserProfile> initialize() {
    return _initFuture ??= _doInitialize();
  }

  /// Generates a unique basketball gamer tag (e.g. "Baller#4829", "Hooper#7182").
  static String generateUniqueGamerTag() {
    const monikers = [
      'Baller',
      'Hooper',
      'Rookie',
      'Bucket',
      'Playmaker',
      'Dunker',
      'Swish',
    ];
    final rand = Random();
    final moniker = monikers[rand.nextInt(monikers.length)];
    final code = rand.nextInt(9000) + 1000;
    return '$moniker#$code';
  }

  Future<UserProfile> _doInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    final rawName = prefs.getString(_prefKeyName);
    String savedName;
    if (rawName == null || rawName.isEmpty || rawName == 'Baller') {
      savedName = generateUniqueGamerTag();
      await prefs.setString(_prefKeyName, savedName);
    } else {
      savedName = rawName;
    }
    final rawAvatar = prefs.getString(_prefKeyAvatar);
    String savedAvatar;
    if (rawAvatar == null || !rawAvatar.startsWith('assets/')) {
      savedAvatar = getRandomAvatar();
      await prefs.setString(_prefKeyAvatar, savedAvatar);
    } else {
      savedAvatar = rawAvatar;
    }

    // If running embedded inside Lagos Life, adopt character name and avatar
    final vatar = VatarBridge.instance;
    if (vatar.isInsideVatar && vatar.player != null) {
      final vPlayer = vatar.player!;
      if (vPlayer.name.isNotEmpty) {
        savedName = vPlayer.name;
        unawaited(prefs.setString(_prefKeyName, savedName));
      }
      if (vPlayer.avatar != null && vPlayer.avatar!.isNotEmpty) {
        savedAvatar = vPlayer.avatar!;
        unawaited(prefs.setString(_prefKeyAvatar, savedAvatar));
      }
    }

    String? localGuestUid = prefs.getString(_prefKeyUid);

    // 1. Ensure Firebase Core is ready
    bool firebaseReady = false;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      firebaseReady = true;
    } catch (e) {
      debugPrint('[AuthService] Firebase Core initialization notice: $e');
    }

    // 2. Perform Silent Guest Authentication
    String activeUid;
    bool isAnon = true;
    bool isVerified = false;

    if (firebaseReady) {
      final auth = FirebaseAuth.instance;

      // Check if returning from a Google redirect sign-in flow on web
      if (kIsWeb) {
        try {
          final redirectCred = await auth.getRedirectResult();
          if (redirectCred.user != null) {
            debugPrint(
              '[AuthService] Successfully completed redirect sign-in: ${redirectCred.user?.email}',
            );
            return await _syncProfileFromFirebaseUser(redirectCred.user);
          }
        } on FirebaseAuthException catch (e) {
          debugPrint('[AuthService] getRedirectResult exception: ${e.code} - ${e.message}');
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            if (e.credential != null) {
              final cred = await auth.signInWithCredential(e.credential!);
              if (cred.user != null) {
                return await _syncProfileFromFirebaseUser(cred.user);
              }
            }
          }
        } catch (e) {
          debugPrint('[AuthService] getRedirectResult notice: $e');
        }
      }

      try {
        User? user = auth.currentUser;

        // On web, IndexedDB persistence restoration is asynchronous.
        // Wait briefly for authStateChanges before assuming no user exists.
        user ??= await auth.authStateChanges().first.timeout(
          const Duration(milliseconds: 1200),
          onTimeout: () => null,
        );

        if (user == null) {
          debugPrint('[AuthService] Performing silent anonymous sign-in...');
          final cred = await auth.signInAnonymously();
          user = cred.user;
        }

        if (user != null) {
          activeUid = user.uid;
          isAnon = user.isAnonymous;
          isVerified = true;

          // If the user signed in with Google, use their Google display name
          if (user.displayName != null && user.displayName!.isNotEmpty && user.displayName != 'Baller') {
            savedName = user.displayName!;
            await prefs.setString(_prefKeyName, savedName);
          }

          if (vatar.isInsideVatar && vatar.player != null) {
            unawaited(user.updateDisplayName(savedName));
          } else if (user.displayName != null &&
              user.displayName!.isNotEmpty &&
              user.displayName != 'Baller') {
            savedName = user.displayName!;
            await prefs.setString(_prefKeyName, savedName);
          } else {
            unawaited(user.updateDisplayName(savedName));
          }
          await prefs.setString(_prefKeyUid, activeUid);
          debugPrint(
            '[AuthService] Silent guest signed in: $activeUid ($savedName)',
          );
        } else {
          activeUid = _getOrCreateFallbackUid(prefs, localGuestUid);
        }
      } catch (e) {
        debugPrint(
          '[AuthService] Silent sign-in fallback active (Tip: ensure Anonymous auth is enabled in Firebase Console): $e',
        );
        activeUid = _getOrCreateFallbackUid(prefs, localGuestUid);
      }
    } else {
      activeUid = _getOrCreateFallbackUid(prefs, localGuestUid);
    }

    final profile = UserProfile(
      uid: activeUid,
      displayName: savedName,
      avatarEmoji: savedAvatar,
      isAnonymous: isAnon,
      isFirebaseVerified: isVerified,
      email: FirebaseAuth.instance.currentUser?.email,
    );

    currentUserNotifier.value = profile;
    if (isVerified) {
      unawaited(_effectiveFriendsService.publishMyProfile(profile));
    }

    // Listen to background auth changes
    if (firebaseReady) {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          currentUserNotifier.value = currentUserNotifier.value?.copyWith(
            uid: user.uid,
            displayName:
                user.displayName ?? currentUserNotifier.value?.displayName,
            isAnonymous: user.isAnonymous,
            isFirebaseVerified: true,
            email: user.email,
          );
        }
      });
    }

    return profile;
  }

  /// Ensures a valid Firebase user exists before performing online operations.
  /// Throws [AuthRequiredException] if unauthenticated and offline.
  Future<User> ensureAuthenticated() async {
    await initialize();
    final auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null) return user;

    try {
      final cred = await auth.signInAnonymously();
      if (cred.user != null) {
        currentUserNotifier.value = currentUserNotifier.value?.copyWith(
          uid: cred.user!.uid,
          isFirebaseVerified: true,
        );
        return cred.user!;
      }
    } catch (e) {
      throw AuthRequiredException(
        'Online multiplayer requires an active internet connection ($e).',
      );
    }

    throw const AuthRequiredException(
      'Unable to establish anonymous session with Firebase.',
    );
  }

  /// Updates player display name and avatar emoji locally and in Firebase.
  Future<void> updateProfile({String? displayName, String? avatarEmoji}) async {
    final current = currentUserNotifier.value;
    if (current == null) return;

    final newName = displayName ?? current.displayName;
    final newAvatar = avatarEmoji ?? current.avatarEmoji;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyName, newName);
    await prefs.setString(_prefKeyAvatar, newAvatar);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && displayName != null) {
        await user.updateDisplayName(newName);
      }
    } catch (_) {}

    final updated = current.copyWith(
      displayName: newName,
      avatarEmoji: newAvatar,
    );
    currentUserNotifier.value = updated;
    unawaited(_effectiveFriendsService.publishMyProfile(updated));
  }

  /// Links the anonymous guest account with a permanent credential (Google, Email, etc.)
  Future<UserCredential?> linkWithCredential(AuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final cred = await user.linkWithCredential(credential);
    currentUserNotifier.value = currentUserNotifier.value?.copyWith(
      isAnonymous: cred.user?.isAnonymous ?? false,
      isFirebaseVerified: true,
      email: cred.user?.email,
    );
    return cred;
  }

  /// Links the current anonymous account to Google, or seamlessly recovers
  /// an existing Google profile if this device previously created a throwaway guest session.
  Future<UserProfile> signInOrLinkWithGoogle() async {
    final auth = FirebaseAuth.instance;
    final provider = GoogleAuthProvider();
    final current = auth.currentUser;

    // Mobile web browsers (iOS Safari, Android Chrome) block cross-domain popups
    // because window.opener is stripped, causing handler tabs to close immediately.
    // Use full-page redirect flow directly on mobile web for reliable authentication.
    final isMobileWeb = kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    if (isMobileWeb) {
      debugPrint('[AuthService] Mobile web detected: using redirect flow...');
      if (current != null && current.isAnonymous) {
        await current.linkWithRedirect(provider);
      } else {
        await auth.signInWithRedirect(provider);
      }
      return currentUserNotifier.value ?? currentUser!;
    }

    if (current != null && current.isAnonymous) {
      try {
        debugPrint('[AuthService] Attempting to link guest with Google popup...');
        final cred = await current.linkWithPopup(provider);
        return await _syncProfileFromFirebaseUser(cred.user);
      } on FirebaseAuthException catch (e) {
        debugPrint('[AuthService] Link result code: ${e.code}');
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          // This Google account belongs to a real profile from another device.
          // Delete or abandon the ephemeral guest account on this device.
          try {
            await current.delete();
          } catch (_) {}

          // Sign in to the existing permanent account
          final cred = await auth.signInWithPopup(provider);
          return await _syncProfileFromFirebaseUser(cred.user);
        } else if (e.code == 'popup-closed-by-user' ||
            e.code == 'cancelled-popup-request' ||
            e.code == 'popup-blocked') {
          if (kIsWeb) {
            debugPrint('[AuthService] Popup failed (${e.code}), falling back to linkWithRedirect...');
            await current.linkWithRedirect(provider);
            return currentUserNotifier.value ?? currentUser!;
          }
        }
        rethrow;
      }
    } else {
      try {
        final cred = await auth.signInWithPopup(provider);
        return await _syncProfileFromFirebaseUser(cred.user);
      } on FirebaseAuthException catch (e) {
        if ((e.code == 'popup-closed-by-user' ||
                e.code == 'cancelled-popup-request' ||
                e.code == 'popup-blocked') &&
            kIsWeb) {
          debugPrint('[AuthService] Popup failed (${e.code}), falling back to signInWithRedirect...');
          await auth.signInWithRedirect(provider);
          return currentUserNotifier.value ?? currentUser!;
        }
        rethrow;
      }
    }
  }

  /// Synchronizes local preferences and Firestore user profile with the signed-in Firebase user.
  Future<UserProfile> _syncProfileFromFirebaseUser(User? user) async {
    if (user == null) {
      throw const AuthRequiredException('No user returned from Google sign-in.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyUid, user.uid);

    // Check if player has an existing profile document in Firestore
    String resolvedName;
    String resolvedAvatar;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        resolvedName = data['displayName'] as String? ??
            user.displayName ??
            generateUniqueGamerTag();
        resolvedAvatar = data['avatarEmoji'] as String? ?? getRandomAvatar();
      } else {
        resolvedName = currentUser?.displayName ??
            user.displayName ??
            generateUniqueGamerTag();
        resolvedAvatar = currentUser?.avatarEmoji ?? getRandomAvatar();
      }
    } catch (_) {
      resolvedName = currentUser?.displayName ??
          user.displayName ??
          generateUniqueGamerTag();
      resolvedAvatar = currentUser?.avatarEmoji ?? getRandomAvatar();
    }

    await prefs.setString(_prefKeyName, resolvedName);
    await prefs.setString(_prefKeyAvatar, resolvedAvatar);

    final profile = UserProfile(
      uid: user.uid,
      displayName: resolvedName,
      avatarEmoji: resolvedAvatar,
      isAnonymous: user.isAnonymous,
      isFirebaseVerified: true,
      email: user.email,
    );

    currentUserNotifier.value = profile;
    unawaited(_effectiveFriendsService.publishMyProfile(profile));
    return profile;
  }

  /// Signs out of the permanent Google account and resets to a silent guest account.
  Future<void> signOut() async {
    final auth = FirebaseAuth.instance;
    await auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyUid);
    await prefs.remove(_prefKeyName);
    await prefs.remove(_prefKeyAvatar);

    _initFuture = null;
    await initialize();
  }

  String _getOrCreateFallbackUid(SharedPreferences prefs, String? existing) {
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final newUid =
        'guest_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
    prefs.setString(_prefKeyUid, newUid);
    return newUid;
  }
}
