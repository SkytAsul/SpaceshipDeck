part of 'subsystems.dart';

final contractsCommand = KernelCommand(
  "contracts",
  (String label) =>
      KernelCommandRunner(label, "Shows informations and manages contracts.")
        ..addCommand(_ListSubcommand()),
);

class _ListSubcommand extends KernelSubcommand {
  _ListSubcommand() : super("list", "List ongoing contracts.");

  @override
  FutureOr? run() async {
    final contracts = (await ContractsApi(
      context!.kernel.get(),
    ).getContracts())!.data;
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
