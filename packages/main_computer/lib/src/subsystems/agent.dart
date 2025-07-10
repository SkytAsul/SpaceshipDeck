import 'dart:async';

import 'package:args/src/arg_results.dart';
import 'package:main_computer/main_computer.dart';
import 'package:space_traders/api.dart';

KernelService getAgentService() => KernelService(
  name: "Agent Subsystem",
  start: (context) async {
    final system = AgentSubsystem(context);
    await system.load();
    context.expose(system);
    return system;
  },
);

class AgentSubsystem {
  final KernelUnitContext _context;

  AgentsApi get _client {
    final apiClient = _context.kernel.get<ApiClient>();
    return apiClient != null
        ? AgentsApi(apiClient)
        : throw StateError("Extra-ship communication cannot be established.");
  }

  Agent? _agent;
  Agent get agent => _agent!;

  AgentSubsystem(this._context);

  Future<void> load() async {
    _agent = (await _client.getMyAgent())!.data;
  }
}

final agentCommand = KernelCommand("agent", _getCommand);

KernelCommandRunner _getCommand(String label) => _AgentCommand(label);

class _AgentCommand extends KernelCommandRunner {
  AgentSubsystem? get subsystem => context?.kernel.get();

  _AgentCommand(String label)
    : super(label, "Shows information about the agent.");

  @override
  FutureOr runDefault(ArgResults argResults) {
    Agent agent = subsystem!.agent;
    print("""
*Agent ${agent.symbol}*
Headquarters: ${agent.headquarters}
Credits: ${agent.credits}
Starting faction: ${agent.startingFaction}
Ship count: ${agent.shipCount}
""");
  }
}
