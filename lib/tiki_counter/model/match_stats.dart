/// One team's numbers for the half-time and full-time cards.
class TeamStats {
  double possessionSeconds = 0.0;
  int passesTried = 0;
  int passesCompleted = 0;
  int shots = 0;
  int shotsOnTarget = 0;
  int interceptions = 0;
  int tacklesWon = 0;
  int offsides = 0;
  int saves = 0;

  /// 0..100, rounded.
  int passAccuracy() =>
      passesTried == 0 ? 0 : (passesCompleted * 100 / passesTried).round();
}
