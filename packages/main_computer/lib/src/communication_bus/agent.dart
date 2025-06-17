import 'package:commons/src/generated/agent.pbgrpc.dart';
import 'package:commons/src/generated/google/protobuf/empty.pb.dart';
import 'package:grpc/grpc.dart';

class AgentService extends AgentServiceBase {
  @override
  Future<AgentInfo> getAgentInfo(ServiceCall call, Empty request) {
    // TODO: implement getAgentInfo
    throw UnimplementedError();
  }

}