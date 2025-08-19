import 'dart:math';

import 'package:commons/commons.dart';
import 'package:deck_controller/src/features/system/data/system_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final maxDistance = system.waypoints
        .map((waypoint) => waypoint.x * waypoint.x + waypoint.y * waypoint.y)
        .reduce(max);
    return InteractiveViewer(
      constrained: false,
      child: Stack(
        alignment: AlignmentDirectional.topStart,
        children: system.waypoints
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

class _WaypointPainter extends CustomPainter {
  static const waypointTypes = {
    WaypointType.WAYPOINT_PLANET: 5,
    WaypointType.WAYPOINT_GAS_GIANT: 10,
    WaypointType.WAYPOINT_MOON: 3,
    WaypointType.WAYPOINT_ASTEROID: 2,
    WaypointType.WAYPOINT_ASTEROID_BASE: 2,
    WaypointType.WAYPOINT_ASTEROID_FIELD: 4,
  };

  final SystemWaypoint waypoint;

  late final Offset offset = Offset(
    waypoint.x.toDouble(),
    waypoint.y.toDouble(),
  );
  late final double waypointSize =
      waypointTypes[waypoint.type]?.toDouble() ?? 1.0;

  Size size = Size.zero;

  _WaypointPainter(this.waypoint);

  @override
  void paint(Canvas canvas, Size size) {
    this.size = size;

    canvas.translate(size.height / 2, size.width / 2);

    canvas.drawCircle(
      Offset.zero,
      offset.distance,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.orange
        ..strokeWidth = .1,
    );
    canvas.drawCircle(
      offset,
      waypointSize.toDouble(),
      Paint()..color = Colors.yellow,
    );
  }

  @override
  bool? hitTest(Offset position) {
    return (position.translate(-size.height / 2, -size.width / 2) - offset)
            .distanceSquared <=
        waypointSize * waypointSize;
  }

  @override
  bool shouldRepaint(covariant _WaypointPainter oldDelegate) {
    return waypoint != oldDelegate.waypoint;
  }
}
