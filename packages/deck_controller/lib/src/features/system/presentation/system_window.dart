import 'dart:math';

import 'package:canvas_kit/canvas_kit.dart';
import 'package:commons/commons.dart';
import 'package:deck_controller/src/features/system/data/system_repository.dart';
import 'package:deck_controller/src/utils/widgets/gravitational_layout.dart';
import 'package:deck_controller/src/features/system/presentation/starfield.dart';
import 'package:deck_controller/src/features/system/presentation/waypoint.dart';
import 'package:deck_controller/src/features/windows/presentation/widgets.dart';
import 'package:deck_controller/src/utils/widgets/sizing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class SystemWindow extends ConsumerWidget {
  final SystemWindowViewModel vm;

  SystemWindow({super.key, required String symbol})
    : vm = SystemWindowViewModel(symbol);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch ((vm.fetchSystem(ref), vm.fetchShips(ref))) {
      (_, AsyncError(:final error)) ||
      (AsyncError(:final error), _) => Text("Error: $error"),
      (AsyncData(value: final system), AsyncData(value: final ships)) => Row(
        children: [
          Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 4),
            child: _SystemInfoCard(system),
          ),
          Expanded(child: _SystemMap(system, ships)),
        ],
      ),
      _ => CircularProgressIndicator(
        constraints: BoxConstraints.loose(Size.square(20)),
      ),
    };
  }
}

class SystemWindowViewModel {
  final String symbol;

  SystemWindowViewModel(this.symbol);

  AsyncValue<System> fetchSystem(WidgetRef ref) =>
      ref.watch(fetchSystemProvider(symbol));

  AsyncValue<List<Ship>> fetchShips(WidgetRef ref) =>
      ref.watch(fetchShipsProvider(symbol));
}

class _SystemInfoCard extends StatelessWidget {
  final System system;

  const _SystemInfoCard(this.system);

  @override
  Widget build(BuildContext context) {
    final waypointTypes = WaypointType.values
        .map(
          (wType) => (
            wType,
            system.waypoints.where((waypoint) => waypoint.type == wType).length,
          ),
        )
        .where((a) => a.$2 > 0)
        .toList();
    waypointTypes.sort((a, b) => b.$2.compareTo(a.$2));

    return DeckCard(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.titleLarge,
                    children: [
                      TextSpan(
                        text: system.symbol,
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (system.hasName())
                        TextSpan(
                          text: "\n${system.name}",
                          style: theme.textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: "Type: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: system.type.prettyName),
                    TextSpan(
                      text: "\nWaypoints:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: " (${system.waypoints.length})"),
                    for (final (wType, count) in waypointTypes)
                      TextSpan(text: "\n• $count ${wType.prettyName}"),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SystemMap extends StatefulWidget {
  final System system;
  final List<Ship> ships;

  const _SystemMap(this.system, this.ships);

  @override
  State<_SystemMap> createState() => _SystemMapState();
}

class _WaypointData {
  SystemWaypoint waypoint;

  _WaypointData(this.waypoint);
}

class _PopupData {
  final String id;
  final WidgetBuilder builder;
  final Offset? worldPosition;
  final Offset? linkedTo;

  // Will be used once viewport positioning algorithm implemented.
  // Offset? viewportPosition;

  _PopupData(this.id, this.builder, this.worldPosition, this.linkedTo);
}

class _SystemMapState extends State<_SystemMap> {
  late final Starfield _starfield;
  late final Size largeSize;

  final _canvasItemsSizes = <String, Size>{};
  final _canvasController = CanvasKitController();

  final _waypointsHierarchy = <String, List<String>>{};
  final _waypointsIndex = <String, _WaypointData>{};

  final _popups = <String, _PopupData>{};

  @override
  void initState() {
    super.initState();

    double maxOrbitRadiusSquared = widget.system.waypoints
        .map((waypoint) => waypoint.position.distanceSquared)
        .reduce(max);
    largeSize = Size.square((sqrt(maxOrbitRadiusSquared) + 100) * 2);
    _starfield = Starfield.random(100, largeSize);

    // First we create the top level waypoints with empty children lists
    for (var waypoint in widget.system.waypoints) {
      _waypointsIndex[waypoint.symbol] = _WaypointData(waypoint);

      if (waypoint.hasOrbits()) continue;
      _waypointsHierarchy[waypoint.symbol] = [];
    }

    // Then we populate the children lists
    for (var waypoint in widget.system.waypoints) {
      if (!waypoint.hasOrbits()) continue;
      assert(
        _waypointsHierarchy.containsKey(waypoint.orbits),
        "Waypoint orbited object is not top-level",
      );
      _waypointsHierarchy[waypoint.orbits]!.add(waypoint.symbol);
    }
  }

  void togglePopup({
    required String id,
    required WidgetBuilder builder,
    Offset? worldPosition,
    Offset? linkedTo,
  }) {
    if (_popups.containsKey(id)) {
      setState(() => _popups.remove(id));
    } else {
      setState(
        () => _popups[id] = _PopupData(id, builder, worldPosition, linkedTo),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Theme(
        data: ThemeData(scaffoldBackgroundColor: Colors.transparent),
        child: CanvasKit(
          controller: _canvasController,
          maxZoom: 5,
          minZoom: 0.5,
          autoFitToBounds: false,
          boundsFitPadding: 0,
          bounds: Rect.fromCenter(
            center: Offset.zero,
            width: largeSize.width,
            height: largeSize.height,
          ),
          backgroundBuilder: (transform) => CustomPaint(
            painter: StarfieldPainter(
              transform: transform,
              starfield: _starfield,
            ),
            foregroundPainter: _TopLevelOrbitsPainter(
              transform: transform,
              waypoints: _waypointsHierarchy.keys
                  .map((symbol) => _waypointsIndex[symbol]!)
                  .toList(),
            ),
            size: largeSize,
          ),
          foregroundLayers: [
            (transform) => _PopupConnectionsPainter(transform, _popups.values),
          ],
          children: [
            _positionCanvasItemCentered(
              id: "star",
              centerPosition: Offset.zero,
              widgetToCenter: _SystemStarWidget(type: widget.system.type),
            ),
            for (var waypointSymbol in _waypointsHierarchy.keys)
              _getWaypointCanvasItem(waypointSymbol),
            for (var popupData in _popups.values)
              _getPopupCanvasItem(popupData),
          ],
        ),
      ),
    );
  }

  CanvasItem _positionCanvasItemCentered({
    required String id,
    required Offset centerPosition,
    required Widget widgetToCenter,
    CanvasItem Function(Offset position, Widget centeredWidget)? builder,
  }) {
    Offset position = centerPosition;
    Size? size = _canvasItemsSizes[id];
    if (size != null) {
      position = _canvasItemsSizes[id]!.uncenter(position);
    }

    builder ??= (position, centeredWidget) => CanvasItem(
      id: id,
      worldPosition: position,
      child: centeredWidget,
      estimatedSize: size,
    );

    return builder(
      position,
      MeasureSize(
        onChange: (size) => setState(() {
          _canvasItemsSizes[id] = size;
        }),
        child: widgetToCenter,
      ),
    );
  }

  CanvasItem _getWaypointCanvasItem(String waypointSymbol) {
    var orbitals = _waypointsHierarchy[waypointSymbol]!;

    var waypointData = _waypointsIndex[waypointSymbol]!;
    Widget widget = WaypointWidget(waypointData.waypoint);
    if (orbitals.isNotEmpty) {
      widget = GravitationalLayout(
        initialAngle: waypointSymbol.hashCode.toDouble(),
        orbitSpacing: 3,
        orbitPaint: Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke,
        body: widget,
        orbiting: orbitals
            .map(
              (orbitalsSymbol) =>
                  WaypointWidget(_waypointsIndex[orbitalsSymbol]!.waypoint),
            )
            .toList(),
      );
    }

    // TODO move out, probably in the WaypointWidget directly
    widget = GestureDetector(
      onTap: () {
        togglePopup(
          id: waypointSymbol,
          worldPosition: waypointData.waypoint.position + Offset(20, 15),
          builder: (context) => WaypointInfoWidget(waypointData.waypoint),
          linkedTo: waypointData.waypoint.position,
        );
      },
      child: widget,
    );

    return _positionCanvasItemCentered(
      id: waypointSymbol,
      centerPosition: waypointData.waypoint.position,
      widgetToCenter: widget,
    );
  }

  CanvasItem _getPopupCanvasItem(_PopupData popup) {
    Offset worldPosition;
    Offset? viewportPosition;
    CanvasAnchor anchor;

    if (popup.worldPosition == null) {
      // should be placed in viewport position
      throw UnimplementedError();
    } else {
      anchor = CanvasAnchor.world;
      worldPosition = popup.worldPosition!;
      viewportPosition = null;
    }

    return CanvasItem(
      id: "${popup.id}-popup",
      anchor: anchor,
      lockZoom: true,
      worldPosition: worldPosition,
      viewportPosition: viewportPosition,
      child: popup.builder(context),
    );
  }
}

class _SystemTypeStyle {
  final double radius;
  final Color color;
  final Color? outerLayerColor;

  const _SystemTypeStyle({
    required this.radius,
    required this.color,
    this.outerLayerColor,
  });
}

class _SystemStarWidget extends StatelessWidget {
  final SystemType type;

  _SystemTypeStyle get style => _systemTypeStyles[type]!;

  const _SystemStarWidget({required this.type});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: type.prettyName,
    child: Container(
      width: style.radius * 2,
      height: style.radius * 2,
      decoration: BoxDecoration(
        shape: .circle,
        color: style.color,
        border: style.outerLayerColor == null
            ? null
            : BoxBorder.all(color: style.outerLayerColor!),
      ),
    ),
  );
}

final _systemTypeStyles = {
  SystemType.SYSTEM_BLACK_HOLE: _SystemTypeStyle(
    radius: 20,
    color: Colors.black,
    outerLayerColor: Colors.deepOrange,
  ),
  SystemType.SYSTEM_BLUE_STAR: _SystemTypeStyle(
    radius: 15,
    color: Colors.lightBlue,
  ),
  SystemType.SYSTEM_HYPERGIANT: _SystemTypeStyle(
    radius: 18,
    color: Colors.amber.shade100,
  ),
  SystemType.SYSTEM_NEBULA: _SystemTypeStyle(
    radius: 25,
    color: Colors.pinkAccent,
  ),
  SystemType.SYSTEM_NEUTRON_STAR: _SystemTypeStyle(
    radius: 25,
    color: Colors.cyan,
  ),
  SystemType.SYSTEM_ORANGE_STAR: _SystemTypeStyle(
    radius: 12,
    color: Colors.deepOrange,
  ),
  SystemType.SYSTEM_RED_STAR: _SystemTypeStyle(
    radius: 8,
    color: Colors.red.shade700,
  ),
  SystemType.SYSTEM_UNSTABLE: _SystemTypeStyle(
    radius: 10, // idk
    color: Colors.purpleAccent,
  ),
  SystemType.SYSTEM_WHITE_DWARF: _SystemTypeStyle(
    radius: 3,
    color: Colors.white,
    outerLayerColor: Colors.grey.shade800,
  ),
  SystemType.SYSTEM_YOUNG_STAR: _SystemTypeStyle(
    radius: 10,
    color: Colors.orangeAccent,
  ),
};

class _TopLevelOrbitsPainter extends CustomPainter {
  final Matrix4 transform;
  final List<_WaypointData> waypoints;

  _TopLevelOrbitsPainter({required this.transform, required this.waypoints});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    Offset center = _worldToScreen(Offset.zero);
    double scaling = transform.right.length;

    for (var waypoint in waypoints) {
      double radius = waypoint.waypoint.position.distance * scaling;
      canvas.drawCircle(center, radius, paint);
    }
  }

  Offset _worldToScreen(Offset worldPoint) {
    final vector = Vector3(worldPoint.dx, worldPoint.dy, 0);
    vector.applyMatrix4(transform);
    return Offset(vector.x, vector.y);
  }

  @override
  bool shouldRepaint(_TopLevelOrbitsPainter old) => old.transform != transform;
}

class _PopupConnectionsPainter extends CustomPainter {
  final Matrix4 transform;
  final Iterable<_PopupData> popups;

  _PopupConnectionsPainter(this.transform, this.popups);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (_PopupData popup in popups) {
      if (popup.linkedTo == null) continue;
      if (popup.worldPosition == null) throw UnimplementedError();

      final start = _worldToScreen(popup.worldPosition!);
      final end = _worldToScreen(popup.linkedTo!);

      canvas.drawLine(start, end, paint);
      // TODO break in orthogonal pieces
    }
  }

  Offset _worldToScreen(Offset worldPoint) {
    final vector = Vector3(worldPoint.dx, worldPoint.dy, 0);
    vector.applyMatrix4(transform);
    return Offset(vector.x, vector.y);
  }

  @override
  bool shouldRepaint(_PopupConnectionsPainter old) =>
      old.transform != transform || old.popups != popups;
}
