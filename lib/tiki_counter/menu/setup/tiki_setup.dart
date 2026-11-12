import 'package:tiki_core/control/bot_level.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/formations.dart';
import 'package:tiki_core/tactics/presets.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Everything the menus remember between visits: your club, the mode,
/// your formation per mode, your playstyle and the bot's level.
/// Immutable: change it with [copyWith], save it with `SetupStore`.
class TikiSetup {
  final String clubName;

  /// 3-letter short form, upper case.
  final String clubCode;
  final GameMode mode;
  final String formation5;
  final String formation7;
  final TeamPlan plan;
  final String botLevel;

  const TikiSetup({
    required this.clubName,
    required this.clubCode,
    required this.mode,
    required this.formation5,
    required this.formation7,
    required this.plan,
    required this.botLevel,
  });

  static final TikiSetup initial = TikiSetup(
    clubName: 'My Club',
    clubCode: 'MYC',
    mode: GameMode.fiveASide,
    formation5: Formations.defaultFor(GameMode.fiveASide).name,
    formation7: Formations.defaultFor(GameMode.sevenASide).name,
    plan: Presets.tikiTaka,
    botLevel: BotLevel.easy.name,
  );

  /// "Lagos Tiki FC" → "LTF"; short names borrow their next letters.
  static String codeFor(String name) {
    final letter = RegExp('[A-Za-z]');
    final firsts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && letter.hasMatch(w[0]))
        .map((w) => w[0])
        .join();
    final all = (firsts + name.replaceAll(RegExp('[^A-Za-z]'), '')).toUpperCase();
    return all.length >= 3 ? all.substring(0, 3) : all.padRight(3, 'X');
  }

  /// A first club name from a player's GameVerse name: "Oyin" → "Oyin FC".
  /// Null if the name has no letters to use.
  static String? clubNameFor(String playerName) {
    final first = playerName.trim().split(RegExp(r'\s+')).first;
    final clean = first.replaceAll(RegExp('[^A-Za-z0-9]'), '');
    if (clean.isEmpty || !RegExp('[A-Za-z]').hasMatch(clean)) return null;
    final cut = clean.length > 16 ? clean.substring(0, 16) : clean;
    return '$cut FC';
  }

  Formation formationFor(GameMode m) {
    final want = m == GameMode.fiveASide ? formation5 : formation7;
    for (final f in Formations.forMode(m)) {
      if (f.name == want) return f;
    }
    return Formations.defaultFor(m);
  }

  Formation get formation => formationFor(mode);

  BotLevel get level {
    for (final l in BotLevel.all) {
      if (l.name == botLevel) return l;
    }
    return BotLevel.easy;
  }

  TikiSetup withFormation(Formation f) => mode == GameMode.fiveASide
      ? copyWith(formation5: f.name)
      : copyWith(formation7: f.name);

  TikiSetup copyWith({
    String? clubName,
    String? clubCode,
    GameMode? mode,
    String? formation5,
    String? formation7,
    TeamPlan? plan,
    String? botLevel,
  }) {
    return TikiSetup(
      clubName: clubName ?? this.clubName,
      clubCode: clubCode ?? this.clubCode,
      mode: mode ?? this.mode,
      formation5: formation5 ?? this.formation5,
      formation7: formation7 ?? this.formation7,
      plan: plan ?? this.plan,
      botLevel: botLevel ?? this.botLevel,
    );
  }

  Map<String, Object> toJson() => {
    'clubName': clubName,
    'clubCode': clubCode,
    'mode': mode.name,
    'formation5': formation5,
    'formation7': formation7,
    'plan': plan.toJson(),
    'botLevel': botLevel,
  };

  factory TikiSetup.fromJson(Map<String, Object?> j) {
    final d = initial;
    String str(String k, String fallback) =>
        j[k] is String && (j[k]! as String).isNotEmpty ? j[k]! as String : fallback;
    var mode = d.mode;
    for (final m in GameMode.values) {
      if (m.name == j['mode']) mode = m;
    }
    final plan = j['plan'];
    return TikiSetup(
      clubName: str('clubName', d.clubName),
      clubCode: str('clubCode', d.clubCode),
      mode: mode,
      formation5: str('formation5', d.formation5),
      formation7: str('formation7', d.formation7),
      plan: plan is Map<String, Object?> ? TeamPlan.fromJson(plan) : d.plan,
      botLevel: str('botLevel', d.botLevel),
    );
  }
}
