import 'package:tiki_core/tactics/team_plan.dart';

/// Ready-made game plans. Each is just a combination of the four phases
/// and the dials in [TeamPlan].
abstract final class Presets {
  static const TeamPlan balanced = TeamPlan(name: 'Balanced');

  static const TeamPlan tikiTaka = TeamPlan(
    name: 'Tiki-taka',
    attack: AttackStyle.possession,
    afterWin: AfterWin.keep,
    afterLoss: AfterLoss.counterPress,
    lineHeight: 0.7,
    compactness: 0.6,
    width: 0.65,
    pressIntensity: 0.7,
  );

  static const TeamPlan gegenpress = TeamPlan(
    name: 'Gegenpress',
    attack: AttackStyle.direct,
    afterWin: AfterWin.counter,
    afterLoss: AfterLoss.counterPress,
    lineHeight: 0.85,
    compactness: 0.75,
    width: 0.55,
    pressIntensity: 0.95,
  );

  static const TeamPlan counterAttack = TeamPlan(
    name: 'Quick counter',
    attack: AttackStyle.direct,
    afterWin: AfterWin.counter,
    afterLoss: AfterLoss.dropIntoShape,
    lineHeight: 0.35,
    compactness: 0.65,
    width: 0.6,
    pressIntensity: 0.35,
  );

  static const TeamPlan lowBlock = TeamPlan(
    name: 'Low block',
    attack: AttackStyle.direct,
    afterWin: AfterWin.counter,
    afterLoss: AfterLoss.dropIntoShape,
    lineHeight: 0.1,
    compactness: 0.9,
    width: 0.5,
    pressIntensity: 0.1,
  );

  static const TeamPlan overload = TeamPlan(
    name: 'Overload',
    attack: AttackStyle.overload,
    afterWin: AfterWin.keep,
    afterLoss: AfterLoss.counterPress,
    lineHeight: 0.6,
    compactness: 0.8,
    width: 0.45,
    pressIntensity: 0.7,
  );

  static const TeamPlan wingPlay = TeamPlan(
    name: 'Wing play',
    attack: AttackStyle.wide,
    afterWin: AfterWin.keep,
    afterLoss: AfterLoss.dropIntoShape,
    lineHeight: 0.5,
    compactness: 0.45,
    width: 0.95,
    pressIntensity: 0.5,
  );

  static const TeamPlan manToMan = TeamPlan(
    name: 'Man-to-man',
    attack: AttackStyle.possession,
    afterWin: AfterWin.counter,
    afterLoss: AfterLoss.counterPress,
    marking: Marking.man,
    lineHeight: 0.6,
    compactness: 0.5,
    width: 0.6,
    pressIntensity: 0.6,
  );

  static const List<TeamPlan> all = [
    balanced,
    tikiTaka,
    gegenpress,
    counterAttack,
    lowBlock,
    overload,
    wingPlay,
    manToMan,
  ];
}
