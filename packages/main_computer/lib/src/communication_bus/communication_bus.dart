import 'package:grpc/grpc.dart';
import 'package:main_computer/main_computer.dart';

import 'agent.dart';

class CommunicationBus {
  final KernelUnitContext _kernelContext;

  final _server = Server.create(services: [AgentService()]);

  CommunicationBus(this._kernelContext);

  Future<void> start() {
    _kernelContext.logger.info("Starting...");
    return _server.serve(port: 58451);
  }

  Future<void> shutdown() {
    _kernelContext.logger.info("Shutting down...");
    return _server.shutdown();
  }
}

KernelService getCommunicationBusService() {
  return KernelService<CommunicationBus>(
    name: "Communication Bus",
    start: (context) async {
      final bus = CommunicationBus(context);
      await bus.start();
      return bus;
    },
    stop: (bus) => bus.shutdown(),
  );
}
