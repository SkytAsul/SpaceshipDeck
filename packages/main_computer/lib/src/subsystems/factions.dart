import 'package:main_computer/main_computer.dart';
import 'package:space_traders/api.dart';

KernelService getFactionsService() => KernelService(
  name: "Factions Subsystem",
  start: (context) async {
    final system = FactionsSubsystem(context);
    await system.load();
    context.expose(system);
    return system;
  },
);

class FactionsSubsystem {
  final KernelUnitContext _context;

  FactionsApi get _client {
    final apiClient = _context.kernel.get<ApiClient>();
    return apiClient != null
        ? FactionsApi(apiClient)
        : throw StateError("Extra-ship communication cannot be established.");
  }

  final _cachedFactions = <String, Faction>{};

  Map<String, int>? _reputation;
  Map<String, int> get reputation => _reputation!;

  FactionsSubsystem(this._context);

  Future<void> load() async {
    _reputation = Map.fromEntries(
      (await _client.getMyFactions())!.data.map(
        (data) => MapEntry(data.symbol, data.reputation),
      ),
    );
  }

  Future<Faction> getFaction(String name) async {
    var faction = _cachedFactions[name];
    if (faction != null) {
      return faction;
    }

    faction = (await _client.getFaction(name))!.data;
    _cachedFactions[name] = faction;
    return faction;
  }
}
