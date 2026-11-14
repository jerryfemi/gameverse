import 'package:tiki_core/tactics/position.dart';

/// Every movement a disc can choose from. Each has one file in
/// `brain/behaviours/`.
enum BehaviourKind {
  // Always available
  holdShape,
  // With the ball
  support,
  keepStructure,
  runInBehind,
  holdWidth,
  dropToReceive,
  cutInside,
  overlap,
  // Without the ball
  press,
  cutLane,
  markMan,
  cover,
  trackRunner,
  chaseLooseBall,
}

/// A role = a name + how much a disc likes each behaviour.
/// 0 (or missing) = never does it, 1 = normal, above 1 = loves it.
///
/// This is why nobody has to give every disc instructions: picking a
/// formation gives each spot a role, and the role already knows its moves.
class RolePreset {
  final String name;
  final Map<BehaviourKind, double> weights;

  const RolePreset(this.name, this.weights);

  double weight(BehaviourKind k) => weights[k] ?? 0.0;
}

abstract final class Roles {
  // Shared by every outfield role: defending, plus keeping the team's
  // structure when we have the ball (rest defence, far-side width).
  static const Map<BehaviourKind, double> _defending = {
    BehaviourKind.holdShape: 1.0,
    BehaviourKind.keepStructure: 1.0,
    BehaviourKind.press: 1.0,
    BehaviourKind.cutLane: 1.0,
    BehaviourKind.markMan: 1.0,
    BehaviourKind.chaseLooseBall: 1.0,
  };

  static const RolePreset keeper = RolePreset('Keeper', {
    BehaviourKind.holdShape: 1.0,
  });

  static const RolePreset centreBack = RolePreset('Centre back', {
    ..._defending,
    BehaviourKind.support: 0.8,
    BehaviourKind.cover: 1.2,
    BehaviourKind.trackRunner: 1.3,
  });

  static const RolePreset fullBack = RolePreset('Overlapping full back', {
    ..._defending,
    BehaviourKind.support: 1.0,
    BehaviourKind.holdWidth: 0.9,
    BehaviourKind.overlap: 1.2,
    BehaviourKind.trackRunner: 1.1,
  });

  static const RolePreset holdingMid = RolePreset('Holding mid', {
    ..._defending,
    BehaviourKind.support: 1.3,
    BehaviourKind.cover: 1.0,
    BehaviourKind.trackRunner: 0.8,
  });

  static const RolePreset centralMid = RolePreset('Box-to-box', {
    ..._defending,
    BehaviourKind.support: 1.2,
    BehaviourKind.dropToReceive: 0.8,
    BehaviourKind.runInBehind: 0.6,
  });

  static const RolePreset wideMid = RolePreset('Wide mid', {
    ..._defending,
    BehaviourKind.support: 1.0,
    BehaviourKind.holdWidth: 1.2,
    BehaviourKind.overlap: 0.8,
    BehaviourKind.runInBehind: 0.7,
  });

  static const RolePreset playmaker = RolePreset('Playmaker', {
    ..._defending,
    BehaviourKind.support: 1.2,
    BehaviourKind.dropToReceive: 1.2,
    BehaviourKind.runInBehind: 0.5,
  });

  static const RolePreset insideForward = RolePreset('Inside forward', {
    ..._defending,
    BehaviourKind.support: 0.7,
    BehaviourKind.holdWidth: 0.8,
    BehaviourKind.cutInside: 1.2,
    BehaviourKind.runInBehind: 1.2,
  });

  static const RolePreset striker = RolePreset('Striker', {
    ..._defending,
    BehaviourKind.support: 0.6,
    BehaviourKind.runInBehind: 1.3,
    BehaviourKind.dropToReceive: 1.0,
  });

  static RolePreset forPosition(Position p) => switch (p) {
    Position.keeper => keeper,
    Position.centreBack => centreBack,
    Position.fullBack => fullBack,
    Position.holdingMid => holdingMid,
    Position.centralMid => centralMid,
    Position.wideMid => wideMid,
    Position.attackingMid => playmaker,
    Position.winger => insideForward,
    Position.striker => striker,
  };
}
