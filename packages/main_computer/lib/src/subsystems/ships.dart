part of 'subsystems.dart';

KernelService getShipsService() => KernelService(
  name: "Ships Subsystem",
  start: (context) {
    final system = ShipsSubsystem(context);
    context.expose(system);
    return system;
  },
);

class ShipsSubsystem {
  final KernelUnitContext _context;

  FleetApi get _client {
    final apiClient = _context.kernel.get<ApiClient>();
    return apiClient != null
        ? FleetApi(apiClient)
        : throw StateError("Extra-ship communication cannot be established.");
  }

  List<Ship>? _cachedShips;

  ShipsSubsystem(this._context);

  Future<List<Ship>> getMyShips() async {
    _cachedShips ??= (await _client.getMyShips())!.data;
    return _cachedShips!;
  }

  Future<Shipyard> getShipyard(String waypointSymbol) async {
    var galaxySubsystem = _context.kernel.get<GalaxySubsystem>()!;
    return (await galaxySubsystem.client.getShipyard(
      commons.getSystemFromWaypoint(waypointSymbol),
      waypointSymbol,
    ))!.data;
  }

  Future<Ship> purchaseShip(ShipType type, String shipyardSymbol) async {
    var result = (await _client.purchaseShip(
      PurchaseShipRequest(shipType: type, waypointSymbol: shipyardSymbol),
    ))!.data;

    _context.kernel.get<AgentSubsystem>()!._agent = result.agent;
    return result.ship;
  }
}

final shipsCommand = KernelCommand(
  "ship",
  (String label) => KernelCommandRunner(label, "Control the ships.")
    ..addCommand(_ShipListCommand())
    ..addCommand(_ShipyardCommand())
    ..addCommand(_ShipPurchaseCommand()),
);

class _ShipListCommand extends KernelSubcommand {
  ShipsSubsystem? get subsystem => context?.kernel.get();

  _ShipListCommand() : super("list", "List ships.");

  @override
  FutureOr? run() async {
    final myShips = await subsystem!.getMyShips();

    print("Fleet status (${myShips.length}):");
    print(myShips.toFormattedString());
  }
}

class _ShipyardCommand extends KernelSubcommand {
  _ShipyardCommand() : super("shipyard", "") {
    addSubcommand(_ShipyardListSubcommand());
    addSubcommand(_ShipyardInfoSubcommand());
  }
}

class _ShipyardListSubcommand extends KernelSubcommand {
  ShipsSubsystem? get subsystem => get();

  _ShipyardListSubcommand() : super("list", "List shipyards.") {
    argParser.addFlag(
      "only-where-ship",
      abbr: "o",
      help: "Only shows shipyards where at least one of the agent's ships are.",
    );
  }

  @override
  FutureOr? run() async {
    final ships = await subsystem!.getMyShips();

    final systems = ships.map((ship) => ship.nav.systemSymbol).toSet();

    for (var system in systems) {
      var systemShipyardsStream = get<GalaxySubsystem>()!.listWaypoints(
        system,
        traits: [WaypointTraitSymbol.SHIPYARD],
      );

      if (argResults!.flag("only-where-ship")) {
        systemShipyardsStream = systemShipyardsStream.where(
          (waypoint) =>
              ships.any((ship) => ship.nav.waypointSymbol == waypoint.symbol),
        );
      }

      final systemShipyards = await systemShipyardsStream.toList();
      print("*Shipyards in $system : (${systemShipyards.length})");
      print(systemShipyards.toFormattedString());
    }
  }
}

class _ShipyardInfoSubcommand extends KernelSubcommand {
  ShipsSubsystem get subsystem => get()!;

  _ShipyardInfoSubcommand() : super("info", "Show shipyard informations.") {
    argParser.addOption("shipyard", mandatory: true);
  }

  @override
  FutureOr? run() async {
    final shipyardSymbol = argResults!.option("shipyard")!;

    final shipyard = await subsystem.getShipyard(shipyardSymbol);
    print("Information about shipyard *$shipyardSymbol*:");
    print(shipyard.toFormattedString());
  }
}

class _ShipPurchaseCommand extends KernelSubcommand {
  ShipsSubsystem get subsystem => get()!;

  _ShipPurchaseCommand() : super("purchase", "Purchase a ship.") {
    argParser.addOption(
      "type",
      mandatory: true,
      allowed: ShipType.values.map((type) => type.value),
    );
    argParser.addOption("shipyard", mandatory: true);
  }

  @override
  FutureOr? run() async {
    final typeName = argResults!.option("type");
    final type = ShipType.values.singleWhere((type) => type.value == typeName);

    final shipyardSymbol = argResults!.option("shipyard")!;

    print("Purchasing a $typeName from $shipyardSymbol...");
    final ship = await subsystem.purchaseShip(type, shipyardSymbol);

    print("Purchased ship!");
    print(ship.toFormattedString());
  }
}
