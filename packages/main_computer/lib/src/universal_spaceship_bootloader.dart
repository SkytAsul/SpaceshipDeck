import 'package:logging/logging.dart';
import 'package:main_computer/main_computer.dart';
import 'package:main_computer/src/communication_bus/communication_bus.dart';

void _setupLogging() {
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print("[${record.loggerName}] [${record.level.name}] ${record.message}");
  });
}

Future<SpaceshipKernel> loadKernel() async {
  _setupLogging();
  final logger = Logger("SpaceshipDeck.USB");

  logger.info("- Universal Spaceship Bootloader -");
  logger.info("Loading kernel...");

  final kernel = SpaceshipKernel(
    units: [
      getCommunicationBusService()
    ]
  );
  return kernel;
}