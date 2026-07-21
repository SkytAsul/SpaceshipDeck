import 'dart:math';
import 'dart:ui';

import 'package:canvas_kit/canvas_kit.dart';
import 'package:commons/commons.dart';
import 'package:deck_controller/src/features/system/data/system_repository.dart';
import 'package:deck_controller/src/utils/widgets/gravitational_layout.dart';
import 'package:deck_controller/src/features/system/presentation/starfield.dart';
import 'package:deck_controller/src/features/system/presentation/waypoint.dart';
import 'package:deck_controller/src/features/windows/presentation/widgets.dart';
import 'package:deck_controller/src/utils/widgets/sizing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Colors, Tooltip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:forui/forui.dart';

class SystemWindow extends ConsumerWidget {
  final SystemWindowViewModel vm;

  SystemWindow({super.key, required String symbol})
    : vm = SystemWindowViewModel(symbol);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch ((vm.fetchSystem(ref), vm.fetchShips(ref))) {
      (_, AsyncError(:final error)) ||
      (AsyncError(:final error), _) => Text("Error: $error"),
      (AsyncData(value: final system), AsyncData(value: final ships)) => FTheme(
        data: context.theme.copyWith(
          cardStyle: .delta(
            decoration: .boxDelta(
              color: context.theme.cardStyle.decoration.color?.withAlpha(200),
            ),
          ),
        ),
        child: SystemMap(system, ships),
      ),
      _ => FCircularProgress(size: .lg),
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
    System system = this.system;

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
          final typography = context.theme.typography;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: typography.display.lg,
                    children: [
                      TextSpan(
                        text: system.symbol,
                        style: typography.display.lg.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (system.hasName())
                        TextSpan(
                          text: "\n${system.name}",
                          style: typography.display.md.copyWith(
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
                  style: typography.body.sm,
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

class SystemMap extends StatefulWidget {
  final System system;
  final List<Ship> ships;

  const SystemMap(this.system, this.ships, {super.key});

  @override
  State<SystemMap> createState() => SystemMapState();
}

class _WaypointData {
  SystemWaypoint waypoint;

  _WaypointData(this.waypoint);
}

class PopupData {
  final String id;
  final WidgetBuilder builder;
  final Offset? linkedTo;
  Offset? worldPosition;
  Offset? viewportPosition;

  PopupData.world({
    required this.id,
    required this.builder,
    required Offset this.worldPosition,
    this.linkedTo,
  }) : viewportPosition = null;

  PopupData.viewport({
    required this.id,
    required this.builder,
    required Offset this.viewportPosition,
    this.linkedTo,
  }) : worldPosition = null;
}

class _Popup {
  final PopupData data;
  bool enabled = false;
  Size? size;

  _Popup(this.data);
}

class SystemMapState extends State<SystemMap> {
  late final Starfield _starfield;
  late final Size largeSize;

  final _canvasItemsSizes = <String, Size>{};
  final _canvasController = CanvasKitController();

  final _waypointsHierarchy = <String, List<String>>{};
  final _waypointsIndex = <String, _WaypointData>{};

  final _popups = <String, _Popup>{};

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

    registerPopup(
      PopupData.viewport(
        id: "star",
        builder: (context) => _SystemInfoCard(widget.system),
        viewportPosition: Offset(40, 40),
        linkedTo: Offset.zero,
      ),
    );
    togglePopup("star");
  }

  void registerPopup(PopupData popup) {
    _popups[popup.id] = _Popup(popup);
  }

  void togglePopup(String id) {
    _Popup popup = _popups[id]!;
    setState(() {
      popup.enabled = !popup.enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CanvasKit(
        controller: _canvasController,
        maxZoom: 5,
        minZoom: 0.5,
        autoFitToBounds: true,
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
          (transform) => _PopupConnectionsPainter(
            transform,
            _popups.values.where((popup) => popup.enabled),
          ),
        ],
        children: [
          _positionCanvasItemCentered(
            id: "star",
            centerPosition: Offset.zero,
            widgetToCenter: _SystemStarWidget(
              starName: widget.system.name,
              type: widget.system.type,
            ),
          ),
          for (var waypointSymbol in _waypointsHierarchy.keys)
            _getWaypointCanvasItem(waypointSymbol),
          for (var popup in _popups.values.where((popup) => popup.enabled))
            _getPopupCanvasItem(popup),
        ],
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
          ..color = Colors.white.withAlpha(100)
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

    return _positionCanvasItemCentered(
      id: waypointSymbol,
      centerPosition: waypointData.waypoint.position,
      widgetToCenter: widget,
    );
  }

  CanvasItem _getPopupCanvasItem(_Popup popup) {
    Offset worldPosition;
    Offset? viewportPosition;
    CanvasAnchor anchor;

    if (popup.data.worldPosition == null) {
      anchor = CanvasAnchor.viewport;
      worldPosition = Offset.zero;
      // bug in CanvasKit, worldPosition cannot be null
      viewportPosition = popup.data.viewportPosition;
    } else {
      anchor = CanvasAnchor.world;
      worldPosition = popup.data.worldPosition!;
      viewportPosition = null;
    }

    return CanvasItem(
      id: "${popup.data.id}-popup",
      anchor: anchor,
      lockZoom: true,
      worldPosition: worldPosition,
      viewportPosition: viewportPosition,
      draggable: true,
      onWorldMoved: (value) => setState(() => popup.data.worldPosition = value),
      onViewportMoved: (value) =>
          setState(() => popup.data.viewportPosition = value),
      child: MeasureSize(
        onChange: (size) {
          setState(() => popup.size = size);
        },
        child: popup.data.builder(context),
      ),
    );
  }

  static SystemMapState of(BuildContext context) =>
      context.findAncestorStateOfType<SystemMapState>()!;
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
  final String starName;
  final SystemType type;

  _SystemTypeStyle get style => _systemTypeStyles[type]!;

  const _SystemStarWidget({required this.starName, required this.type});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => SystemMapState.of(context).togglePopup("star"),
    child: Tooltip(
      message: "$starName (${type.prettyName})",
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
  final Iterable<_Popup> popups;

  _PopupConnectionsPainter(this.transform, this.popups);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (_Popup popup in popups) {
      if (popup.data.linkedTo == null) continue;

      Offset start;
      if (popup.data.worldPosition == null) {
        start = popup.data.viewportPosition!;
      } else {
        start = _worldToScreen(popup.data.worldPosition!);
      }

      final end = _worldToScreen(popup.data.linkedTo!);

      var rect = Rect.fromLTWH(
        start.dx,
        start.dy,
        popup.size!.width,
        popup.size!.height,
      );
      if (rect.contains(end)) continue; // point lies inside the popup

      double edgeX, edgeY;
      if (end.dx > rect.center.dx) {
        // point lies at the right
        edgeX = rect.right;
      } else {
        // point lies at the left
        edgeX = rect.left;
      }
      if (end.dy > rect.center.dy) {
        // point lies at the top
        edgeY = rect.bottom;
      } else {
        // point lies at the bottom
        edgeY = rect.top;
      }

      Offset heightCenter = Offset(edgeX, rect.top + rect.height / 2.0);
      Offset widthCenter = Offset(rect.left + rect.width / 2.0, edgeY);

      Offset bestEdge;
      if (rect.contains(Offset(end.dx, rect.top))) {
        // point lies under or above the popup (not in a corner)
        bestEdge = widthCenter;
      } else if (rect.contains(Offset(rect.left, end.dy))) {
        // point lies at the left/right of the popup (not in a corner)
        bestEdge = heightCenter;
      } else {
        // point lies in a corner: we choose the shortest Manhattan path
        double pathCost(Offset off) {
          Offset path = end - off;
          return path.dx.abs() + path.dy.abs();
        }

        bestEdge = pathCost(heightCenter) > pathCost(widthCenter)
            ? widthCenter
            : heightCenter;
      }

      final points = _lineToOrthogonalComponents(
        bestEdge,
        end,
        startHorizontal: bestEdge == heightCenter,
      );
      for (var i = 1; i < points.length; i++) {
        canvas.drawDashedLine(points[i - 1], points[i], paint, [5, 5]);
      }
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

List<Offset> _lineToOrthogonalComponents(
  Offset p1,
  Offset p2, {
  bool? startHorizontal,
}) {
  if (p1.dx == p2.dx || p1.dy == p2.dy) return [p1, p2];
  double dx = p2.dx - p1.dx;
  double dy = p2.dy - p1.dy;

  if (startHorizontal ?? dx.abs() > dy.abs()) {
    return [p1, p1 + Offset(dx / 2, 0), p2 - Offset(dx / 2, 0), p2];
  } else {
    return [p1, p1 + Offset(0, dy / 2), p2 - Offset(0, dy / 2), p2];
  }
}

extension on Canvas {
  void drawDashedLine(
    Offset p1,
    Offset p2,
    Paint paint,
    Iterable<double> pattern,
  ) {
    assert(pattern.length.isEven);
    final distance = (p2 - p1).distance;
    final normalizedPattern = pattern.map((width) => width / distance).toList();
    final points = <Offset>[];
    double t = 0;
    int i = 0;
    while (t < 1) {
      points.add(Offset.lerp(p1, p2, t)!);
      t += normalizedPattern[i++]; // dashWidth
      points.add(Offset.lerp(p1, p2, t.clamp(0, 1))!);
      t += normalizedPattern[i++]; // dashSpace
      i %= normalizedPattern.length;
    }
    drawPoints(PointMode.lines, points, paint);
  }
}
