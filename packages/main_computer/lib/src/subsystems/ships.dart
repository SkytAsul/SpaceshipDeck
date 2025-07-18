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

  ShipsSubsystem(this._context);

  Future<List<Ship>> getMyShips() async {
    return (await _client.getMyShips())!.data;
  }

  Future<Shipyard> getShipyard(String waypointSymbol) async {
    var galaxySubsystem = _context.kernel.get<GalaxySubsystem>()!;
    return (await galaxySubsystem.client.getShipyard(
      galaxySubsystem.getSystemFromWaypoint(waypointSymbol),
      waypointSymbol,
    ))!.data;
  }
}

final shipsCommand = KernelCommand(
  "ship",
  (String label) => KernelCommandRunner(label, "Control the ships.")
    ..addCommand(_ShipListCommand())
    ..addCommand(_ShipyardCommand()),
);

class _ShipListCommand extends KernelSubcommand {
  ShipsSubsystem? get subsystem => context?.kernel.get();

  _ShipListCommand() : super("list", "List ships.");

  @override
  FutureOr? run() async {
    final myShips = await subsystem!.getMyShips();

    print("Fleet status:");
    print(myShips);
  }
}

class _ShipyardCommand extends KernelSubcommand {
  ShipsSubsystem? get subsystem => get();

  _ShipyardCommand() : super("shipyard", "Show shipyard information.");

  @override
  FutureOr? run() async {
    final ships = await subsystem!.getMyShips();

    final systems = ships.map((ship) => ship.nav.systemSymbol).toSet();

    for (var system in systems) {
      final systemShipyards = await get<GalaxySubsystem>()!
          .listWaypoints(system, traits: [WaypointTraitSymbol.SHIPYARD])
          .toList();
      print("*Shipyards in $system : (${systemShipyards.length})");
      print(systemShipyards.map((shipyard) => "- $shipyard").join("\n"));
    }
  }
}
