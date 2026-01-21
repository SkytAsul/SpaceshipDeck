import 'dart:ui';

import 'package:commons/commons.dart';
import 'package:deck_controller/main.dart';
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

@Riverpod(keepAlive: true)
Future<List<Ship>> fetchShips(Ref ref, String systemSymbol) async {
  _logger.finer("Fetching ships in system $systemSymbol");
  final client = ShipsProviderClient(getIt.get<ClientChannel>());
  return (await client.getShipsInSystem(
    ShipSystemRequest(systemSymbol: systemSymbol),
  )).ships;
}

extension SystemWaypointUtils on SystemWaypoint {
  Offset get position => Offset(x.toDouble(), y.toDouble());
}

extension SystemTypeUtils on SystemType {
  String get prettyName =>
      name.substring("SYSTEM_".length).toLowerCase().replaceAll("_", " ");
}

extension WaypointTypeUtils on WaypointType {
  String get prettyName =>
      name.substring("WAYPOINT_".length).toLowerCase().replaceAll("_", " ");
}
