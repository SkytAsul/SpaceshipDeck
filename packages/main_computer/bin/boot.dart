import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:main_computer/main_computer.dart';
import 'package:main_computer/src/utils/async.dart';

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addOption("agent-token", defaultsTo: Platform.environment["AGENT_TOKEN"]);
}

void printUsage(ArgParser argParser) {
  print('Usage: dart main_computer.dart <flags> [arguments]');
  print(argParser.usage);
}

Future<void> main(List<String> arguments) async {
  final ArgParser argParser = buildParser();
  /*MainComputerInit computer;
  try {
    final ArgResults results = argParser.parse(arguments);

    // Process the parsed arguments.
    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }

    final agentToken = results.option("agent-token");
    if (agentToken == null) {
      throw ArgumentError("agent_token not found.");
    }

    computer = MainComputerInit(
      verbose: results.flag('verbose'),
      agentToken: agentToken,
    );
  } on FormatException catch (e) {
    print(e.message);
    print('');
    printUsage(argParser);
    exit(2);
  }*/

  final kernel = await bootKernel();
  _showConsole(kernel);
  await kernel.run();
}

void _showConsole(SpaceshipKernel kernel) async {
  stdin.lineMode = false;
  stdin.echoMode = false;
  StreamSubscription? streamSubscription;
  final stdinStream = stdin.asBroadcastStream(
    onListen: (subscription) => streamSubscription = subscription,
  );

  if (!kernel.started) {
    await kernel.startedStream.next();
  }

  while (kernel.started) {
    try {
      bool manual = await SpaceshipConsole(stdinStream, stdout, kernel: kernel).run();
      if (manual) {
        print("""
  You tried to exited the console from the bootloader.
  Use 'shutdown' instead if you want to exit the main spacehip computer.""");
      }
    } catch (ex, st) {
      print("An error occurred in the console.");
      print(ex);
      print(st);
    }
  }

  await streamSubscription!.cancel();
}
