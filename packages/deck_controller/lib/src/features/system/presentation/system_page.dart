import 'dart:math';

import 'package:commons/commons.dart';
import 'package:deck_controller/src/features/system/data/system_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _logger = Logger("Deck Controller.System Widgets");

class SystemPage extends ConsumerWidget {
  final SystemPageViewModel vm;

  SystemPage({super.key, required String symbol})
    : vm = SystemPageViewModel(symbol);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (vm.fetchSystem(ref)) {
      AsyncError(:final error) => Text("Error: $error"),
      AsyncData(:final value) => Row(
        children: [
          Column(
            children: [
              Text("""
System information:
${value.symbol}
Type: ${value.type.name}
"""),
              if (value.hasName()) Text("Name: ${value.name}"),
            ],
          ),
          Expanded(child: InteractiveViewer(child: _SystemMap(value))),
        ],
      ),
      _ => CircularProgressIndicator(),
    };
  }
}

class SystemPageViewModel {
  final String symbol;

  SystemPageViewModel(this.symbol);

  AsyncValue<System> fetchSystem(WidgetRef ref) =>
      ref.watch(fetchSystemProvider(symbol));
}

class _SystemMap extends StatelessWidget {
  final System system;

  const _SystemMap(this.system);

  @override
  Widget build(BuildContext context) {
    var waypoints = system.waypoints.toList();
    /*waypoints = [
      SystemWaypoint(
        symbol: "a",
        type: WaypointType.WAYPOINT_PLANET,
        x: 20,
        y: 5,
        orbitalsWaypoints: ["b"],
      ),
      SystemWaypoint(
        symbol: "b",
        type: WaypointType.WAYPOINT_MOON,
        x: 20,
        y: 5,
        orbits: "a",
      ),
    ];*/

    final waypointsMap = <String, _LayoutedSystemWaypoint>{};
    for (var waypoint in waypoints) {
      waypointsMap[waypoint.symbol] = _LayoutedSystemWaypoint(
        waypoint,
        waypointsMap,
      );
    }

    for (var layoutedWaypoint in waypointsMap.values) {
      if (!layoutedWaypoint.waypoint.hasOrbits()) {
        layoutedWaypoint.computeOrbitalSizes();
        layoutedWaypoint.computePositions();
      }
    }
    final maxDistance = waypointsMap.values
        .map((waypoint) => waypoint.position!.distanceSquared)
        .reduce(max);

    return InteractiveViewer(
      constrained: false,
      maxScale: 3,
      minScale: 0.5,
      child: Stack(
        alignment: AlignmentDirectional.topStart,
        children: waypointsMap.values
            .map(
              (waypoint) => GestureDetector(
                onTap: () {
                  // TODO
                },
                child: CustomPaint(
                  painter: _WaypointPainter(waypoint),
                  size: Size.square(sqrt(maxDistance) * 2),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _WaypointTypeStyle {
  final double radius;
  final Color color;
  final double orbitStrokeWidth;

  const _WaypointTypeStyle({
    this.radius = 1,
    this.color = Colors.grey,
    this.orbitStrokeWidth = 0.1,
  });
}

const _waypointTypeStyles = {
  WaypointType.WAYPOINT_PLANET: _WaypointTypeStyle(
    radius: 5,
    color: Colors.green,
    orbitStrokeWidth: 0.2,
  ),
  WaypointType.WAYPOINT_GAS_GIANT: _WaypointTypeStyle(
    radius: 7,
    color: Colors.blue,
    orbitStrokeWidth: 0.2,
  ),
  WaypointType.WAYPOINT_MOON: _WaypointTypeStyle(
    radius: 3,
    color: Colors.yellow,
    orbitStrokeWidth: 0.15,
  ),
  WaypointType.WAYPOINT_ASTEROID: _WaypointTypeStyle(
    radius: 1.5,
    color: Colors.brown,
    orbitStrokeWidth: 0.05,
  ),
  WaypointType.WAYPOINT_ASTEROID_BASE: _WaypointTypeStyle(radius: 1.2),
  WaypointType.WAYPOINT_ASTEROID_FIELD: _WaypointTypeStyle(
    radius: 3,
    color: Colors.teal,
  ),
};

class _LayoutedSystemWaypoint {
  final SystemWaypoint waypoint;
  final Map<String, _LayoutedSystemWaypoint> waypointsMap;

  late final _WaypointTypeStyle style =
      _waypointTypeStyles[waypoint.type] ?? const _WaypointTypeStyle();

  Offset? position;
  Offset? orbitCenter;
  double? orbitDistance;
  double? orbitalsSize;

  _LayoutedSystemWaypoint(this.waypoint, this.waypointsMap);

  void computeOrbitalSizes() {
    if (orbitalsSize != null) {
      return;
    }

    double maxChildrenSize = 0;
    for (var orbital in waypoint.orbitalsWaypoints) {
      var layoutedOrbital = waypointsMap[orbital]!;
      layoutedOrbital.computeOrbitalSizes();
      maxChildrenSize = max(maxChildrenSize, layoutedOrbital.orbitalsSize!);
    }

    orbitalsSize = style.radius + maxChildrenSize;
  }

  void computePositions() {
    if (position != null) {
      return;
    }

    if (waypoint.hasOrbits()) {
      var layoutedOrbits = waypointsMap[waypoint.orbits]!;

      if (waypoint.x != layoutedOrbits.waypoint.x ||
          waypoint.y != layoutedOrbits.waypoint.y) {
        _logger.warning(
          "Waypoint ${waypoint.symbol} does not have the same coordinates as the waypoint it orbits.",
        );
      }

      orbitCenter = layoutedOrbits.position!;

      int siblingId = layoutedOrbits.waypoint.orbitalsWaypoints.indexOf(
        waypoint.symbol,
      );
      int siblings = layoutedOrbits.waypoint.orbitalsWaypoints.length;
      orbitDistance =
          layoutedOrbits.style.radius +
          1 +
          layoutedOrbits.waypoint.orbitalsWaypoints
              .map((sibling) => waypointsMap[sibling]!.orbitalsSize!)
              .reduce(max);

      double initialAngle =
          layoutedOrbits.position.hashCode.toDouble() % (2 * pi);
      position =
          orbitCenter! +
          Offset.fromDirection(
            initialAngle + 2 * pi * siblingId / siblings,
            orbitDistance!,
          );
    } else {
      orbitCenter = Offset.zero;
      position = Offset(waypoint.x.toDouble(), waypoint.y.toDouble());
      orbitDistance = position!.distance;
    }

    for (var orbital in waypoint.orbitalsWaypoints) {
      var layoutedOrbital = waypointsMap[orbital]!;
      layoutedOrbital.computePositions();
    }

    var samePosition = waypointsMap.values
        .where((other) => other != this && other.position == position)
        .firstOrNull;
    if (samePosition != null) {
      _logger.warning(
        "${waypoint.symbol} is at the same position that ${samePosition.waypoint.symbol}",
      );
    }
  }
}

class _WaypointPainter extends CustomPainter {
  final _LayoutedSystemWaypoint waypoint;

  Size size = Size.zero;

  _WaypointPainter(this.waypoint);

  @override
  void paint(Canvas canvas, Size size) {
    this.size = size;
    canvas.translate(size.height / 2, size.width / 2);

    canvas.drawCircle(
      waypoint.orbitCenter!,
      waypoint.orbitDistance!,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = waypoint.style.color
        ..strokeWidth = waypoint.style.orbitStrokeWidth,
    );
    canvas.drawCircle(
      waypoint.position!,
      waypoint.style.radius,
      Paint()..color = waypoint.style.color,
    );
  }

  @override
  bool? hitTest(Offset position) {
    return (position.translate(-size.height / 2, -size.width / 2) -
                waypoint.position!)
            .distanceSquared <=
        waypoint.style.radius * waypoint.style.radius;
  }

  @override
  bool shouldRepaint(covariant _WaypointPainter oldDelegate) {
    return waypoint != oldDelegate.waypoint;
  }
}
