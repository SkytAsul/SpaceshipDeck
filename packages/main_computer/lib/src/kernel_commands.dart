import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:main_computer/main_computer.dart';

class KernelCommandRunner<T> extends CommandRunner<T> {
  KernelUnitContext? context;

  KernelCommandRunner(super.executableName, super.description);

  @override
  Future<T?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.command == null) {
      return runDefault(topLevelResults);
    }
    return super.runCommand(topLevelResults);
  }

  FutureOr<T?> runDefault(ArgResults argResults) {
    return super.runCommand(argResults);
  }
}

abstract class KernelSubcommand<T> extends Command<T> {
  KernelUnitContext? get context =>
      (runner as KernelCommandRunner<T>?)?.context;

  @override
  final String name, description;

  KernelSubcommand(this.name, this.description);

  /// Utility method to get an exposed object from the kernel.
  A? get<A>() => context?.kernel.get<A>();
}
