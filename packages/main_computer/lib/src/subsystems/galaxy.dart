part of 'subsystems.dart';

KernelService getGalaxyService() => KernelService(
  name: "Galaxy Subsystem",
  start: (context) async {
    final system = GalaxySubsystem(context);
    context.expose(system);
    return system;
  },
);

class GalaxySubsystem {
  final KernelUnitContext _context;

  @protected
  SystemsApi get client {
    final apiClient = _context.kernel.get<ApiClient>();
    return apiClient != null
        ? SystemsApi(apiClient)
        : throw StateError("Extra-ship communication cannot be established.");
  }

  final _cachedSystems = <String, System>{};

  final _cachedWaypoints = <String, Waypoint>{};

  GalaxySubsystem(this._context);

  Future<System> getSystem(String symbol) async {
    var system = _cachedSystems[symbol];
    if (system != null) {
      return system;
    }

    system = (await client.getSystem(symbol))!.data;
    _cachedSystems[symbol] = system;
    return system;
  }

  String getSystemFromWaypoint(String waypointSymbol) =>
      waypointSymbol.substring(0, waypointSymbol.lastIndexOf("-"));

  Future<Waypoint?> getWaypoint(String waypointSymbol) async {
    var waypoint = _cachedWaypoints[waypointSymbol];
    if (waypoint != null) {
      return waypoint;
    }

    waypoint = (await client.getWaypoint(
      getSystemFromWaypoint(waypointSymbol),
      waypointSymbol,
    ))!.data;
    _cachedWaypoints[waypointSymbol] = waypoint;
    return waypoint;
  }

  Stream<Waypoint> listWaypoints(
    String systemSymbol, {
    List<WaypointTraitSymbol>? traits,
  }) {
    return paginationToStream(
      (page, limit) => client.getSystemWaypoints(
        systemSymbol,
        page: page,
        limit: limit,
        traits: traits,
      ),
      (rep) => rep!.data,
      (rep) => rep!.meta,
    );
  }
}
