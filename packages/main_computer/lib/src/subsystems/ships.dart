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

  final _shipsTasks = <String, Task>{};

  ShipsSubsystem(this._context);

  Task _registerShipTask(String shipSymbol, Task task) {
    if (_shipsTasks.containsKey(shipSymbol)) {
      _shipsTasks[shipSymbol]!.last.following = task;
    } else {
      _shipsTasks[shipSymbol] = task;
      task.start();
    }
    return task;
  }

  Future<List<Ship>> getMyShips() async {
    _cachedShips ??= (await _client.getMyShips())!.data; // TODO paginate
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
    _context.logger.fine("Purchasing $type from $shipyardSymbol");
    var result = (await _client.purchaseShip(
      PurchaseShipRequest(shipType: type, waypointSymbol: shipyardSymbol),
    ))!.data;

    _context.kernel.get<AgentSubsystem>()!._agent = result.agent;
    return result.ship;
  }

  Task orbitShip(String shipSymbol) {
    return _registerShipTask(
      shipSymbol,
      Task("Put ship into orbit", (setEstEnd) async {
        _context.logger.fine("Orbiting $shipSymbol");
        await _client.orbitShip(shipSymbol);
      }),
    );
  }

  Task navigateShip(String shipSymbol, String waypointSymbol) {
    return _registerShipTask(
      shipSymbol,
      Task("Navigation towards $waypointSymbol", (setEstEnd) async {
        _context.logger.fine("Navigating $shipSymbol to $waypointSymbol");
        var result = (await _client.navigateShip(
          shipSymbol,
          NavigateShipRequest(waypointSymbol: waypointSymbol),
        ))!.data;
        assert(result.nav.status == .IN_TRANSIT);

        setEstEnd(result.nav.route.arrival);
        var flightDuration = DateTime.now().difference(
          result.nav.route.arrival,
        );
        _context.logger.fine("Time of travel: $flightDuration");
      }),
    );
  }
}

// COMMANDS
final shipsCommand = KernelCommand(
  "ship",
  (String label) => KernelCommandRunner(label, "Control the ships.")
    ..addCommand(_ShipListCommand())
    ..addCommand(
      KernelSubcommand("shipyard", "View and purchase ships")
        ..addSubcommand(_ShipyardListSubcommand())
        ..addSubcommand(_ShipyardInfoSubcommand()),
    )
    ..addCommand(_ShipPurchaseCommand())
    ..addCommand(
      KernelSubcommand("navigate", "Handle ship navigation")
        ..addSubcommand(_ShipOrbitCommand()),
    ),
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

class _ShipOrbitCommand extends KernelSubcommand {
  ShipsSubsystem get subsystem => get()!;

  _ShipOrbitCommand() : super("orbit", "Put the ship into orbit") {
    argParser.addOption("ship", abbr: "s", mandatory: true);
  }

  @override
  FutureOr<dynamic>? run() {
    subsystem.orbitShip(argResults!.option("ship")!);
  }
}
