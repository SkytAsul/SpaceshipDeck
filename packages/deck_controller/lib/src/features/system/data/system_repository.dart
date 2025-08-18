import 'package:commons/commons.dart';
import 'package:deck_controller/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'system_repository.g.dart';

@riverpod
Future<System> fetchSystem(Ref ref, String symbol) async {
  final client = SystemProviderClient(getIt.get<ClientChannel>());
  return await client.getSystem(SystemRequest(symbol: symbol));
}
