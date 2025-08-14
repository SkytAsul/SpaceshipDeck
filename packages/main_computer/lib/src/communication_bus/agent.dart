import 'package:commons/src/generated/agent.pbgrpc.dart';
import 'package:commons/src/generated/google/protobuf/empty.pb.dart';
import 'package:grpc/grpc.dart';
import 'package:main_computer/src/subsystems/subsystems.dart';
import 'package:space_traders/api.dart' as api;

class AgentProviderService extends AgentProviderServiceBase {
  AgentSubsystem agentSubsystem;

  AgentProviderService(this.agentSubsystem);

  @override
  Future<Agent> getMyAgent(ServiceCall call, Empty request) {
    return Future.value(agentSubsystem.agent.toProtobuf());
  }
}

extension on api.Agent {
  Agent toProtobuf() => Agent(symbol: symbol);
}
