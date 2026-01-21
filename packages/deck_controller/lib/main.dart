import 'package:commons/commons.dart';
import 'package:deck_controller/src/features/system/presentation/system_page.dart';
import 'package:deck_controller/src/features/system/presentation/system_window.dart';
import 'package:deck_controller/src/features/windows/presentation/window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:grpc/grpc.dart';
import 'package:logging/logging.dart';
import 'dart:developer' as dev;

final getIt = GetIt.instance;
final logger = Logger("Deck Controller");

Agent? _agent;

void main() async {
  await _setup();

  runApp(const MyApp());
}

Future<void> _setup() async {
  hierarchicalLoggingEnabled = true;
  Logger.root.onRecord.listen((record) {
    dev.log(
      record.message,
      error: record.error,
      stackTrace: record.stackTrace,
      level: record.level.value,
      name: record.loggerName,
      sequenceNumber: record.sequenceNumber,
      time: record.time,
      zone: record.zone,
    );
  });
  logger.level = Level.ALL;
  logger.fine("Booting up...");

  getIt.registerSingleton<ClientChannel>(
    await _getCommunicationBus("::1", 58451),
  );
}

Future<ClientChannel> _getCommunicationBus(String host, int port) async {
  logger.fine("Connecting to communication bus: $host:$port...");
  final channel = ClientChannel(
    host,
    port: port,
    options: ChannelOptions(credentials: ChannelCredentials.insecure()),
  );

  // no way to test that the channel is correctly opened, thus we send a dummy
  // request to test.
  _agent = await AgentProviderClient(channel).getMyAgent(Empty());
  logger.info("Connected to communication bus. Hello ${_agent!.symbol}");

  return channel;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Spaceship Deck Controller',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF500073)),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF500073),
            brightness: Brightness.dark,
          ),
        ),
        home: Material(
          child: Center(
            child: WindowWidget(
              title: "System",
              child: SystemWindow(
                symbol: getSystemFromWaypoint(_agent!.headquarters),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
