import 'package:logging/logging.dart';
import 'package:main_computer/src/communication_bus/communication_bus.dart';
import 'package:space_traders/api.dart';

class MainComputerInit {

  final _logger = Logger("SpaceshipDeck.Init");

  bool verbose;
  String agentToken;

  ApiClient? _apiClient;
  ApiClient get apiClient => _apiClient!;

  CommunicationBus? _communicationBus;

  MainComputerInit({
    this.verbose = false,
    required this.agentToken,
  });

  void _setupLogging() {
    hierarchicalLoggingEnabled = true;
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print("[${record.loggerName}] [${record.level.name}] ${record.message}");
    });
  }

  Future<void> boot() async {
    _setupLogging();
    _logger.info("Booting up...");

    _apiClient = ApiClient(authentication: HttpBearerAuth()..accessToken = agentToken);
  
    final result = await AgentsApi(apiClient).getMyAgent();
    if (result == null) {
      throw StateError("Unable to fetch agent informations.");
    }

    _logger.info("Hello ${result.data.symbol}!");

    _communicationBus = CommunicationBus();
    await _communicationBus!.start();

    daemon();
  }

  void daemon() async {
    while(false) {
      // do loop
    }
  }

  Future<void> shutdown() async {
    _apiClient?.client.close();
    
    if (_communicationBus != null) {
      await _communicationBus!.shutdown();
    }
  }

}
