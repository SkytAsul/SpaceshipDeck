import 'dart:io';

import 'package:args/args.dart';
import 'package:main_computer/main_computer.dart';

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

  final kernel = await loadKernel();

  await kernel.boot();
  await SpaceshipConsole(kernel: kernel).run();
  await kernel.shutdown();
}
