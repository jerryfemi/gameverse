/// The two match sizes. Each mode carries its own pitch measurements.
///
/// Coordinates: the pitch centre is (0, 0). x runs along the length
/// (−length/2 … +length/2), y across the width (−width/2 … +width/2).
/// On screen, +x is right and +y is down.
enum GameMode {
  fiveASide(
    label: '5v5',
    teamSize: 5,
    length: 40.0,
    width: 22.0,
    goalWidth: 3.6,
    goalHeight: 2.0,
    boxDepth: 6.0,
    boxWidth: 12.0,
    centreCircle: 3.0,
    offside: false,
    shootRange: 11.0,
  ),
  sevenASide(
    label: '7v7',
    teamSize: 7,
    length: 55.0,
    width: 36.0,
    goalWidth: 5.0,
    goalHeight: 2.0,
    boxDepth: 9.0,
    boxWidth: 20.0,
    centreCircle: 5.0,
    offside: true,
    shootRange: 15.0,
  );

  const GameMode({
    required this.label,
    required this.teamSize,
    required this.length,
    required this.width,
    required this.goalWidth,
    required this.goalHeight,
    required this.boxDepth,
    required this.boxWidth,
    required this.centreCircle,
    required this.offside,
    required this.shootRange,
  });

  final String label;
  final int teamSize;
  final double length;
  final double width;
  final double goalWidth;
  final double goalHeight;
  final double boxDepth;
  final double boxWidth;
  final double centreCircle;

  /// Offside is ON in 7v7 and OFF in 5v5 (handoff, round 3).
  final bool offside;

  /// Bots consider shooting inside this distance to goal.
  final double shootRange;

  double get halfLength => length / 2.0;
  double get halfWidth => width / 2.0;
}
