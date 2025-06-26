import 'dart:async';

import 'package:args/args.dart';
import 'package:main_computer/main_computer.dart';
import 'package:space_traders/api.dart';

List<KernelCommand> getKernelCommands() => [
  KernelCommand(name: "agent", function: _agentCommand),
  KernelCommand(name: "help", function: _helpCommand),
  KernelCommand(name: "shutdown", function: _shutdownCommand),
  KernelCommand(name: "contract", function: _contractCommand),
];

Future<void> _helpCommand(KernelUnitContext context, List<String> args) {
  final commands = context.kernel.units.whereType<KernelCommand>().toList();
  commands.sort((c1, c2) => c1.name.compareTo(c2.name));
  
  print("Available commands:");
  for (var command in commands) {
    print("- ${command.name}");
  }

  return Future.value(null);
}

Future<void> _shutdownCommand(KernelUnitContext context, List<String> args) async {
  await context.kernel.shutdown();
}

Future<void> _agentCommand(KernelUnitContext context, List<String> args) async {
  final client = context.kernel.get<ApiClient>();
  final agent = (await AgentsApi(client).getMyAgent())!.data;

  print(agent);
}

Future<void> _contractCommand(KernelUnitContext context, List<String> args) async {
  final parser = ArgParser()
    ..addCommand("list")
    ..addCommand("accept");
  // TODO switch to CommandRunner and move in own file?
  
  final results = parser.parse(args.skip(1));
  if (results.command == null) {
    print(parser.usage);
  } else if (results.command!.name == "list") {
    final contracts = (await ContractsApi(context.kernel.get()).getContracts())!.data;
    print("Contracts list:");
    print(contracts.join("\n"));
  }
}
