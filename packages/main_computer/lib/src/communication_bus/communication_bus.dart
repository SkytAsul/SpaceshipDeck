import 'package:grpc/grpc.dart';
import 'package:logging/logging.dart';

import 'agent.dart';

class CommunicationBus {

  final _logger = Logger("SpaceshipDeck.CommunicationBus");

  final _server = Server.create(
    services: [AgentService()],
  );

  Future<void> start() {
    _logger.info("Starting...");
    return _server.serve(port: 58451);
  }

  Future<void> shutdown() {
    _logger.info("Shutting down...");
    return _server.shutdown();
  }

}
