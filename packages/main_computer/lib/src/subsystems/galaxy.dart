import 'package:main_computer/main_computer.dart';
import 'package:space_traders/api.dart';

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

  SystemsApi get _client {
    final apiClient = _context.kernel.get<ApiClient>();
    return apiClient != null
        ? SystemsApi(apiClient)
        : throw StateError("Extra-ship communication cannot be established.");
  }

  final _cachedSystems = <String, System>{};

  GalaxySubsystem(this._context);

  Future<System> getSystem(String symbol) async {
    var system = _cachedSystems[symbol];
    if (system != null) {
      return system;
    }

    system = (await _client.getSystem(symbol))!.data;
    _cachedSystems[symbol] = system;
    return system;
  }
}
