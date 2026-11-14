/// Team-level decisions made once per brain tick, before each disc picks
/// its own job. They stop everyone doing the same thing (two discs pressing
/// the same man, three discs running to the same support spot).
class Assignments {
  /// disc id → support spot (world x, y).
  final Map<int, ({double x, double y})> support = {};

  /// disc id → a structure job with the ball (rest defence, far-side
  /// width): where to stand and the job's name. See `StructureAssigner`.
  final Map<int, ({double x, double y, String job})> structure = {};

  /// Pressers in order: first presses, second blocks the easy pass, third
  /// (counter-press only) closes in too.
  final List<int> pressers = [];

  /// disc id → opponent disc id whose passing lane it cuts.
  final Map<int, int> laneCuts = {};

  /// disc id → opponent disc id it marks (man marking).
  final Map<int, int> marks = {};

  /// Disc that stays goal-side as cover (−1 = none).
  int cover = -1;

  /// Disc that chases a loose ball (−1 = none).
  int chaser = -1;

  bool isPresser(int id) => pressers.contains(id);
}
