import 'dart:math' as math;

/// A made-up club for the bot to play as.
class OpponentClub {
  final String name;
  final String code;

  const OpponentClub(this.name, this.code);
}

abstract final class OpponentClubs {
  static const List<OpponentClub> all = [
    OpponentClub('Harbour Rovers', 'HRV'),
    OpponentClub('Eko Athletic', 'EKA'),
    OpponentClub('Ridgeway Town', 'RDG'),
    OpponentClub('Northbank United', 'NBU'),
    OpponentClub('Crescent City', 'CRC'),
    OpponentClub('Ironbridge FC', 'IRB'),
    OpponentClub('Lakeside Wanderers', 'LKW'),
    OpponentClub('Kingsgate Albion', 'KGA'),
  ];

  /// A random club whose short form isn't [avoidCode].
  static OpponentClub random(math.Random rng, {String avoidCode = ''}) {
    final pool = [
      for (final c in all)
        if (c.code != avoidCode.toUpperCase()) c,
    ];
    return pool[rng.nextInt(pool.length)];
  }
}
