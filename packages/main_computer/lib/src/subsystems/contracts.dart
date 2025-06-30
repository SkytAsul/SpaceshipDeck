import 'dart:async';

import 'package:main_computer/main_computer.dart';
import 'package:main_computer/src/kernel_commands.dart';
import 'package:space_traders/api.dart';

final contractsCommand = KernelCommand("contracts", _getCommand);

KernelCommandRunner _getCommand(String label) =>
    KernelCommandRunner(label, "Shows informations and manages contracts.")
    ..addCommand(_ListSubcommand());

class _ListSubcommand extends KernelSubcommand {

  _ListSubcommand() : super("list", "List ongoing contracts.");

  @override
  FutureOr? run() async {
    final contracts = (await ContractsApi(context!.kernel.get()).getContracts())!.data;
    print("Contracts list:");
    print(contracts.join("\n"));
  }

}

KernelService getContractsService() => KernelService(
  name: "Contracts Subsystem",
  start: (context) {
    final system = ContractsSystem(context);
    context.expose(system);
    return system;
  },
);

class ContractsSystem {
  final KernelUnitContext _context;
  
  ContractsSystem(this._context);
}
