import 'dart:io';

import 'package:logging/logging.dart';
import 'package:main_computer/main_computer.dart';
import 'package:main_computer/src/commands.dart';
import 'package:main_computer/src/communication_bus/communication_bus.dart';
import 'package:main_computer/src/extraship_communication.dart';
import 'package:main_computer/src/subsystems/contracts.dart';

void _setupLogging() {
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print("[${record.loggerName}] [${record.level.name}] ${record.message}");
    if (record.error != null) {
      stderr.writeln(record.error);
    }
    if (record.stackTrace != null) {
      stderr.writeln(record.stackTrace);
    }
  });
}

Future<SpaceshipKernel> bootKernel() async {
  _setupLogging();
  final logger = Logger("SpaceshipDeck.USB");

  logger.info("- Universal Spaceship Bootloader -");
  logger.info("Loading kernel...");

  final kernel = SpaceshipKernel(
    units: [
      getCommunicationBusService(),
      getExtraShipCommunicationService(),
      getContractsService(),
      ...getKernelCommands()
    ],
  );
  return kernel;
}
