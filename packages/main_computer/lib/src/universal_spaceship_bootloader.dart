import 'package:logging/logging.dart';
import 'package:main_computer/main_computer.dart';
import 'package:main_computer/src/communication_bus/communication_bus.dart';
import 'package:main_computer/src/extraship_communication.dart';

void _setupLogging() {
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print("[${record.loggerName}] [${record.level.name}] ${record.message}");
    if (record.error != null) {
      print(record.error);
    }
    if (record.stackTrace != null) {
      print(record.stackTrace);
    }
  });
}

Future<SpaceshipKernel> loadKernel() async {
  _setupLogging();
  final logger = Logger("SpaceshipDeck.USB");

  logger.info("- Universal Spaceship Bootloader -");
  logger.info("Loading kernel...");

  final kernel = SpaceshipKernel(
    units: [
      getCommunicationBusService(),
      // getExtraShipCommunicationService(),
    ],
  );
  return kernel;
}
