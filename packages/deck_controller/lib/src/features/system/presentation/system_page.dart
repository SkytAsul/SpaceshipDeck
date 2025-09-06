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

class _SystemMap extends StatefulWidget {
  final System system;

  const _SystemMap(this.system);

  @override
  State<_SystemMap> createState() => _SystemMapState();
}

class _SystemMapState extends State<_SystemMap> {
  final Map<String, _LayoutedSystemWaypoint> _waypointsMap = {};
  Size? canvasSize;

  final Set<String> _waypointsWithDescription = {};

  void toggleWaypointDescriptionShown(_LayoutedSystemWaypoint waypoint) {
    setState(() {
      if (!_waypointsWithDescription.add(waypoint.waypoint.symbol)) {
        _waypointsWithDescription.remove(waypoint.waypoint.symbol);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    var waypoints = widget.system.waypoints.toList();
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

    for (var waypoint in waypoints) {
      _waypointsMap[waypoint.symbol] = _LayoutedSystemWaypoint(
        waypoint,
        _waypointsMap,
      );
    }

    for (var layoutedWaypoint in _waypointsMap.values) {
      if (!layoutedWaypoint.waypoint.hasOrbits()) {
        layoutedWaypoint.computeOrbitalSizes();
        layoutedWaypoint.computePositions();
      }
    }
    final maxDistance = _waypointsMap.values
        .map((waypoint) => waypoint.position!.distanceSquared)
        .reduce(max);
    canvasSize = Size.square(sqrt(maxDistance) * 2);
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      constrained: false,
      maxScale: 3,
      minScale: 0.5,
      scaleEnabled: false,
      // TODO separate scale from InteractiveViewer, only to size canvas so text
      // remains the same size no matter the zoom level.
      child: Stack(
        alignment: AlignmentDirectional.topStart,
        children: [
          CustomPaint(
            painter: _WaypointsOrbitsPainter(waypoints: _waypointsMap.values),
            size: canvasSize!,
          ),
          ..._waypointsMap.values.map(
            (waypoint) => _WaypointWidget(waypoint: waypoint, mapState: this),
          ),
          ..._waypointsWithDescription.map((symbol) {
            var waypoint = _waypointsMap[symbol]!;
            return Positioned(
              left: waypoint.position!.dx + canvasSize!.width / 2,
              top: waypoint.position!.dy + canvasSize!.height / 2,
              child: _WaypointInfoWidget(waypoint.waypoint),
            );
          }),
        ],
      ),
    );
  }
}

class _WaypointWidget extends StatefulWidget {
  final _LayoutedSystemWaypoint waypoint;
  final _SystemMapState mapState;

  const _WaypointWidget({required this.waypoint, required this.mapState});

  @override
  State<_WaypointWidget> createState() => _WaypointWidgetState();
}

class _WaypointWidgetState extends State<_WaypointWidget> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.mapState.toggleWaypointDescriptionShown(widget.waypoint);
      },
      child: MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        onEnter: (event) => setState(() {
          hovered = true;
        }),
        onExit: (event) => setState(() {
          hovered = false;
        }),
        child: Stack(
          children: [
            CustomPaint(
              painter: _WaypointPainter(
                widget.waypoint,
                growScalar: hovered ? 3 : 0,
              ),
              size: widget.mapState.canvasSize!,
            ),
          ],
        ),
      ),
    );
  }
}

class _WaypointInfoWidget extends StatelessWidget {
  final SystemWaypoint waypoint;

  const _WaypointInfoWidget(this.waypoint);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        border: BoxBorder.all(color: theme.colorScheme.secondary),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text("""
${waypoint.symbol}

Type: ${waypoint.type.name}"""),
      ),
    );
    // TODO: button to fetch complete information on waypoint
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
  final double growScalar;

  Size size = Size.zero;

  _WaypointPainter(this.waypoint, {this.growScalar = 0});

  @override
  void paint(Canvas canvas, Size size) {
    this.size = size;
    canvas.translate(size.height / 2, size.width / 2);

    canvas.drawCircle(
      waypoint.position!,
      waypoint.style.radius + growScalar,
      Paint()..color = waypoint.style.color,
    );
  }

  @override
  bool? hitTest(Offset position) {
    double rad = waypoint.style.radius + growScalar;
    return (position.translate(-size.height / 2, -size.width / 2) -
                waypoint.position!)
            .distanceSquared <=
        rad * rad;
  }

  @override
  bool shouldRepaint(covariant _WaypointPainter oldDelegate) {
    return waypoint != oldDelegate.waypoint ||
        growScalar != oldDelegate.growScalar;
  }
}

/// The orbits painter is separate from the waypoint painter so all orbits are
/// drawn below all waypoints and other decorations.
class _WaypointsOrbitsPainter extends CustomPainter {
  final Iterable<_LayoutedSystemWaypoint> waypoints;

  _WaypointsOrbitsPainter({required this.waypoints});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.height / 2, size.width / 2);

    for (var waypoint in waypoints) {
      canvas.drawCircle(
        waypoint.orbitCenter!,
        waypoint.orbitDistance!,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = waypoint.style.color
          ..strokeWidth = waypoint.style.orbitStrokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaypointsOrbitsPainter oldDelegate) {
    return waypoints != oldDelegate.waypoints;
  }
}
