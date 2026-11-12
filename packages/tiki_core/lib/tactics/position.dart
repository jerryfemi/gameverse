import 'package:tiki_core/model/disc.dart';

/// Where a disc plays. Decides its default role (see `roles.dart`) and its
/// broad [Role] (keeper / defender / midfielder / forward).
enum Position {
  keeper('GK', Role.keeper),
  centreBack('CB', Role.defender),
  fullBack('FB', Role.defender),
  holdingMid('DM', Role.midfielder),
  centralMid('CM', Role.midfielder),
  wideMid('WM', Role.midfielder),
  attackingMid('AM', Role.midfielder),
  winger('W', Role.forward),
  striker('ST', Role.forward);

  const Position(this.short, this.role);

  final String short;
  final Role role;

  bool get isWide => this == fullBack || this == wideMid || this == winger;
}
