import 'package:commons/commons.dart';
import 'package:grpc/grpc.dart';
import 'package:main_computer/src/subsystems/subsystems.dart';
import 'package:space_traders/api.dart' as api;
import 'package:protobuf/protobuf.dart' as pb;

class SystemProviderService extends SystemProviderServiceBase {
  GalaxySubsystem galaxySubsystem;

  SystemProviderService(this.galaxySubsystem);

  @override
  Future<System> getSystem(ServiceCall call, SystemRequest request) async {
    final system = await galaxySubsystem.getSystem(request.symbol);
    return system.toProtobuf();
  }
}

extension on api.System {
  System toProtobuf() => System(
    symbol: symbol,
    type: SystemType.values.findItem("SYSTEM_", type.value),
    constellation: constellation,
    name: name,
    waypoints: waypoints.map((wp) => wp.toProtobuf()).toList(),
    x: x,
    y: y,
  );
}

extension on api.SystemWaypoint {
  SystemWaypoint toProtobuf() => SystemWaypoint(
    orbitalsWaypoints: orbitals.map((orbit) => orbit.symbol).toList(),
    orbits: orbits,
    symbol: symbol,
    type: WaypointType.values.findItem("WAYPOINT_", type.value),
    x: x,
    y: y,
  );
}

extension ProtobufEnumList<T extends pb.ProtobufEnum> on List<T> {
  T findItem(String commonPrefix, String itemName) {
    return singleWhere(
      (pbItem) => pbItem.name.substring(commonPrefix.length) == itemName,
    );
  }
}
