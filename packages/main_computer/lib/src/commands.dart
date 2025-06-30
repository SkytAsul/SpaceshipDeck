import 'dart:async';

import 'package:args/args.dart';
import 'package:main_computer/main_computer.dart';
import 'package:main_computer/src/subsystems/contracts.dart';
import 'package:main_computer/src/kernel_commands.dart';

List<KernelCommand> getKernelCommands() => [
  KernelCommand("help", HelpCommand.new),
  KernelCommand("shutdown", ShutdownCommand.new),
  contractsCommand,
];

class HelpCommand extends KernelCommandRunner {
  HelpCommand(String label) : super(label, "Shows a list of available commands.");

  @override
  FutureOr runDefault(ArgResults argResults) {
    final commands = context!.kernel.units.whereType<KernelCommand>().toList();
    commands.sort((c1, c2) => c1.name.compareTo(c2.name));
    
    print("Available commands:");
    for (var command in commands) {
      var commandRunner = command.runnerProvider(command.name);
      print("- ${command.name}: ${commandRunner.description}");
    }

    return Future.value(null);
  }
}

class ShutdownCommand extends KernelCommandRunner {
  ShutdownCommand(String label) : super(label, "Shuts down the spaceship computer.");

  @override
  FutureOr runDefault(ArgResults argResults) {
    context?.kernel.askShutdown();
    print("Shutdown initiated.");
  }
}
