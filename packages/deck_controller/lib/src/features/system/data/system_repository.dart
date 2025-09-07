import 'package:commons/commons.dart';
import 'package:deck_controller/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'system_repository.g.dart';

final _logger = Logger("Deck Controller.System Repository");

@riverpod
Future<System> fetchSystem(Ref ref, String symbol) async {
  _logger.finer("Fetching information for system $symbol");
  final client = SystemProviderClient(getIt.get<ClientChannel>());
  return await client.getSystem(SystemRequest(symbol: symbol));
}

@Riverpod(keepAlive: true)
Future<Waypoint> fetchWaypoint(Ref ref, String symbol) async {
  _logger.finer("Fetching information for waypoint $symbol");
  final client = SystemProviderClient(getIt.get<ClientChannel>());
  return await client.getWaypoint(WaypointRequest(symbol: symbol));
}
