import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:main_computer/main_computer.dart';

import 'agent.dart';

const busPort = 58451;

class CommunicationBus {
  final KernelUnitContext _kernelContext;

  late final _server = Server.create(
    services: [AgentProviderService(_kernelContext.kernel.get()!)],
  );

  CommunicationBus(this._kernelContext);

  Future<void> start() async {
    await _server.serve(address: InternetAddress.anyIPv6, port: busPort);
    _kernelContext.logger.info("Opened bus on ${_server.port}.");
  }

  Future<void> shutdown() {
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
