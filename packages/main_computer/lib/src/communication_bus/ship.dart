import 'package:commons/src/generated/google/protobuf/empty.pb.dart';
import 'package:commons/src/generated/ship.pbgrpc.dart';
import 'package:grpc/src/server/call.dart';
import 'package:main_computer/src/communication_bus/utils.dart';
import 'package:main_computer/src/subsystems/subsystems.dart';
import 'package:space_traders/api.dart' as api;

class ShipsProviderService extends ShipsProviderServiceBase {
  ShipsSubsystem shipsSubsystem;

  ShipsProviderService(this.shipsSubsystem);

  @override
  Future<ShipsResponse> getMyShips(ServiceCall call, Empty request) async {
    final ships = await shipsSubsystem.getMyShips();
    return ShipsResponse(ships: ships.map((s) => s.toProtobuf()));
  }
}

extension on api.Ship {
  Ship toProtobuf() =>
      Ship(symbol: symbol, nav: nav.toProtobuf(), frame: frame.toProtobuf());
}

extension on api.ShipNav {
  ShipNav toProtobuf() => ShipNav(
    systemSymbol: systemSymbol,
    waypointSymbol: waypointSymbol,
    status: ShipNavStatus.values.findItem("SHIP_NAV_", status.value),
    route: route.toProtobuf(),
  );
}

extension on api.ShipNavRoute {
  ShipNavRoute toProtobuf() => ShipNavRoute(
    originSymbol: origin.symbol,
    destinationSymbol: destination.symbol,
    departure: departureTime.toProtobuf(),
    arrival: arrival.toProtobuf(),
  );
}

extension on api.ShipFrame {
  ShipFrame toProtobuf() => ShipFrame(
    symbol: ShipFrameSymbol.values.findItem("SHIP_FRAME_", symbol.value),
    name: name,
    condition: condition,
    integrity: integrity,
    description: description,
  );
}
