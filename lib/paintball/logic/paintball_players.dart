import 'package:flutter/foundation.dart';

import 'package:b_ball/models/player_descriptor.dart';

/// One player as shown on the paintball HUD and results card.
@immutable
class PaintballPlayer {
  final String name;

  /// Anything AppAvatar can draw: asset path, data URI, URL, or emoji.
  final String avatar;

  /// Firebase Auth UID when signed in / online; null for the bot or a guest.
  final String? uid;

  final bool isBot;

  const PaintballPlayer({
    required this.name,
    required this.avatar,
    this.uid,
    this.isBot = false,
  });
}

/// You and your opponent. Solo = you vs the bot; online = you vs a friend
/// (set by the online session when it exists).
@immutable
class PaintballPlayers {
  final PaintballPlayer you;
  final PaintballPlayer opponent;

  const PaintballPlayers({required this.you, required this.opponent});

  static const PaintballPlayer defaultYou =
      PaintballPlayer(name: 'You', avatar: PlayerDescriptor.defaultAvatar);

  /// Same bot identity as darts and archery.
  static const PaintballPlayer bot = PaintballPlayer(
    name: 'Bot',
    avatar: 'assets/avatars/dunk_heads (2).webp',
    isBot: true,
  );

  static const PaintballPlayers solo = PaintballPlayers(you: defaultYou, opponent: bot);
}
