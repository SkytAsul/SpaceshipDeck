import 'package:grpc/grpc.dart';
import 'package:logging/logging.dart';
import 'package:main_computer/main_computer.dart';

import 'agent.dart';

class CommunicationBus {
  final _logger = Logger("SpaceshipDeck.CommunicationBus");
  // ignore: unused_field
  final SpaceshipKernel _kernel;

  final _server = Server.create(services: [AgentService()]);

  CommunicationBus(this._kernel);

  Future<void> start() {
    _logger.info("Starting...");
    return _server.serve(port: 58451);
  }

  Future<void> shutdown() {
    _logger.info("Shutting down...");
    return _server.shutdown();
  }
}

KernelService getCommunicationBusService() {
  return KernelService<CommunicationBus>(
    name: "Communication Bus",
    start: (kernel) async {
      final bus = CommunicationBus(kernel);
      await bus.start();
      return bus;
    },
    stop: (bus) => bus!.shutdown(),
  );
}
