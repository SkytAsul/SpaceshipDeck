import 'dart:async';

import 'package:main_computer/main_computer.dart';
import 'package:space_traders/api.dart';

List<KernelCommand> getKernelCommands() => [
  KernelCommand(name: "agent", function: _agentCommand),
  KernelCommand(name: "help", function: _helpCommand),
  KernelCommand(name: "shutdown", function: _shutdownCommand),
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
