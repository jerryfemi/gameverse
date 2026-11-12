/// Which team. Which way a team attacks depends on the half: ask
/// `MatchState.dir(side)` (+1 = toward +x / right, −1 = toward −x).
enum Side {
  home,
  away;

  Side get other => this == Side.home ? Side.away : Side.home;

  String get label => this == Side.home ? 'HOME' : 'AWAY';
}
