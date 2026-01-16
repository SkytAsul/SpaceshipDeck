part of 'system_page.dart';

class _LayoutedShip extends _LayoutedObject {
  final Ship ship;

  _LayoutedShip._orbits({
    required this.ship,
    required super.objectsMap,
    required super.orbits,
    required super.style,
  }) : super.orbits();

  _LayoutedShip._positioned({
    required this.ship,
    required super.objectsMap,
    required super.position,
    required super.style,
  }) : super.positioned();

  factory _LayoutedShip(Ship ship, Map<String, _LayoutedObject> objectsMap) {
    return switch (ship.nav.status) {
      ShipNavStatus.SHIP_NAV_IN_ORBIT => _LayoutedShip._orbits(
        ship: ship,
        objectsMap: objectsMap,
        orbits: ship.nav.systemSymbol,
        style: _LayoutedShipStyle(icon: Icons.rocket),
      ),
      ShipNavStatus.SHIP_NAV_DOCKED => _LayoutedShip._positioned(
        ship: ship,
        objectsMap: objectsMap,
        position: Offset.zero,
        style: _LayoutedShipStyle(icon: Icons.rocket),
      ),
      ShipNavStatus.SHIP_NAV_IN_TRANSIT => _LayoutedShip._positioned(
        ship: ship,
        objectsMap: objectsMap,
        position: Offset.zero,
        style: _LayoutedShipStyle(icon: Icons.rocket_launch),
      ),
      _ => throw UnsupportedError(
        "Unknown ship navigation status ${ship.nav.status}",
      ),
    };
  }

  @override
  void computePositions() {
    switch (ship.nav.status) {
      case ShipNavStatus.SHIP_NAV_IN_ORBIT:
        super.computePositions();
        break;
      case ShipNavStatus.SHIP_NAV_DOCKED:
        orbitCenter = null;
        position = objectsMap[ship.nav.waypointSymbol]!.position!;
        break;
      case ShipNavStatus.SHIP_NAV_IN_TRANSIT:
        orbitCenter = null;
        Offset origin = objectsMap[ship.nav.route.originSymbol]!.position!;
        Offset destination =
            objectsMap[ship.nav.route.destinationSymbol]!.position!;
        Duration travelLeft = ship.nav.route.arrival.toDateTime().difference(
          DateTime.now(),
        );
        Duration travelLength = ship.nav.route.arrival.toDateTime().difference(
          ship.nav.route.departure.toDateTime(),
        );
        double percent = travelLeft.inSeconds / travelLength.inSeconds;
        position = (destination - origin) * percent;
        break;
    }
  }
}

class _LayoutedShipStyle extends _LayoutedObjectStyle {
  final IconData icon;

  const _LayoutedShipStyle({
    super.radius = 4,
    super.orbitStrokeColor = Colors.red,
    super.orbitStrokeWidth = 0.1,
    required this.icon,
  }) : super();
}
