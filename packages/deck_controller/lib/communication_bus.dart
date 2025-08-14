import 'package:grpc/grpc.dart';
import 'package:commons/src/generated/agent.pbgrpc.dart';
import 'package:commons/src/generated/google/protobuf/empty.pb.dart';

Future<void> connect(String host, int port) async {
  final channel = ClientChannel(
    host,
    port: port,
    options: ChannelOptions(credentials: ChannelCredentials.insecure()),
  );

  final answer = await AgentProviderClient(channel).getMyAgent(Empty());
  print("Connected. You are ${answer.symbol}");
}
