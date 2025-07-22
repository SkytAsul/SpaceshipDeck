part of 'subsystems.dart';

KernelService getContractsService() => KernelService(
  name: "Contracts Subsystem",
  start: (context) {
    final system = ContractsSubsystem(context);
    context.expose(system);
    return system;
  },
);

class ContractsSubsystem {
  final KernelUnitContext _context;

  @protected
  ContractsApi get client {
    final apiClient = _context.kernel.get<ApiClient>();
    return apiClient != null
        ? ContractsApi(apiClient)
        : throw StateError("Extra-ship communication cannot be established.");
  }

  ContractsSubsystem(this._context);

  Stream<Contract> listContracts() {
    return paginationToStream(
      (page, limit) => client.getContracts(page: page, limit: limit),
      (rep) => rep!.data,
      (rep) => rep!.meta,
    );
  }

  Future<Contract> negotiateContract(String shipSymbol) async {
    return (await client.negotiateContract(shipSymbol))!.data.contract;
  }

  Future<Contract> acceptContract(String contractId) async {
    final data = (await client.acceptContract(contractId))!.data;
    _context.kernel.get<AgentSubsystem>()!._agent = data.agent;
    return data.contract;
  }
}

final contractsCommand = KernelCommand(
  "contract",
  (String label) =>
      KernelCommandRunner(label, "Shows informations and manages contracts.")
        ..addCommand(_ContractListSubcommand())
        ..addCommand(_ContractNegotiateSubcommand())
        ..addCommand(_ContractAcceptSubcommand()),
);

class _ContractListSubcommand extends KernelSubcommand {
  ContractsSubsystem? get subsystem => get();

  _ContractListSubcommand() : super("list", "List ongoing contracts.");

  @override
  FutureOr? run() async {
    await for (var contract in subsystem!.listContracts()) {
      String state;
      if (!contract.accepted) {
        state = "PENDING UNTIL ${contract.deadlineToAccept}";
      } else if (contract.fulfilled) {
        state = "COMPLETE";
      } else {
        state = "ONGOING";
      }
      print("""
- *${contract.id}*
  State: $state
  Type: ${contract.type}
  Terms: ${contract.terms}
  Faction: ${contract.factionSymbol}""");
    }
  }
}

class _ContractNegotiateSubcommand extends KernelSubcommand {
  ContractsSubsystem? get subsystem => get();

  _ContractNegotiateSubcommand()
    : super("negotiate", "Negotiate a new contract.") {
    argParser.addOption("ship", mandatory: true);
  }

  @override
  FutureOr? run() async {
    final shipSymbol = argResults!.option("ship")!;
    print("Negotiating a new contract with ship *$shipSymbol*...");

    final contract = await subsystem!.negotiateContract(shipSymbol);
    print("New contract received: $contract");
  }
}

class _ContractAcceptSubcommand extends KernelSubcommand {
  ContractsSubsystem? get subsystem => get();

  _ContractAcceptSubcommand() : super("accept", "Accept a contract.") {
    argParser.addOption("contractId", mandatory: true);
  }

  @override
  FutureOr? run() async {
    final contractId = argResults!.option("contractId")!;
    print("Accepting the contract *$contractId*...");

    int oldCredits = get<AgentSubsystem>()!.agent.credits;
    await subsystem!.acceptContract(contractId);
    int newCredits = get<AgentSubsystem>()!.agent.credits;

    print(
      "Contract *$contractId* accepted! Received ${newCredits - oldCredits} credits.",
    );
  }
}
