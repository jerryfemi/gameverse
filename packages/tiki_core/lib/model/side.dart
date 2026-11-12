/// Which team. Home attacks towards +x (right), away towards −x (left).
///
/// Ends don't swap at half-time (kept simple for now).
enum Side {
  home,
  away;

  Side get other => this == Side.home ? Side.away : Side.home;

  /// +1 for home, −1 for away: multiply an x by this to get
  /// "how far forward" it is for this team.
  double get attackDir => this == Side.home ? 1.0 : -1.0;

  String get label => this == Side.home ? 'HOME' : 'AWAY';
}
