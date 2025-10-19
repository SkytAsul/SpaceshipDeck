import 'dart:math';

import 'package:commons/commons.dart';
import 'package:deck_controller/src/features/system/data/system_repository.dart';
import 'package:deck_controller/src/features/windows/presentation/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'system_page_waypoints.dart';

class SystemPage extends ConsumerWidget {
  final SystemPageViewModel vm;

  SystemPage({super.key, required String symbol})
    : vm = SystemPageViewModel(symbol);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (vm.fetchSystem(ref)) {
      AsyncError(:final error) => Text("Error: $error"),
      AsyncData(value: final system) => Row(
        children: [
          Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 4),
            child: _SystemInfoCard(system),
          ),
          Expanded(child: _SystemMap(system)),
        ],
      ),
      _ => CircularProgressIndicator(),
    };
  }
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
  final transformationController = TransformationController();
  final Map<String, _LayoutedObject> _objectsMap = {};
  Size? canvasSize;
  double scale = 1;

  final Set<_LayoutedObject> _objectsWithDescription = {};

  void toggleDescriptionShown(_LayoutedObject object) {
    setState(() {
      if (!_objectsWithDescription.add(object)) {
        _objectsWithDescription.remove(object);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    var waypoints = widget.system.waypoints.toList();

    for (var waypoint in waypoints) {
      _objectsMap[waypoint.symbol] = _LayoutedWaypoint(waypoint, _objectsMap);
    }

    for (var layouted in _objectsMap.values) {
      layouted.computeOrbits();
    }
    for (var layouted in _objectsMap.values) {
      if (layouted.orbits == null) {
        layouted.computeTotalSizes();
        layouted.computePositions();
      }
    }
    final maxDistance = _objectsMap.values
        .map((object) => object.position!.distanceSquared)
        .reduce(max);
    canvasSize = Size.square(sqrt(maxDistance) * 2);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      transformationController.value = Matrix4.translationValues(
        -canvasSize!.width / 2 + context.size!.width / 2,
        -canvasSize!.height / 2 + context.size!.height / 2,
        0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: transformationController,
          alignment: Alignment.topLeft,
          constrained: false,
          scaleEnabled: false,
          boundaryMargin: EdgeInsets.all(16 * scale),
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              SizedBox.fromSize(
                size: canvasSize! * scale,
                child: OverflowBox(
                  // this box is needed because the CustomPaint instances can be
                  // bigger than the scaled SizedBox (when scale < 1)
                  alignment: Alignment.topLeft,
                  maxWidth: canvasSize!.width,
                  maxHeight: canvasSize!.height,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topLeft,
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: _SystemStarPainter(type: widget.system.type),
                          size: canvasSize!,
                        ),
                        CustomPaint(
                          painter: _OrbitsPainter(objects: _objectsMap.values),
                          size: canvasSize!,
                        ),
                        ..._objectsMap.values.map(
                          (object) => _LayoutedObjectWidget(
                            object: object,
                            mapState: this,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ..._objectsWithDescription.map((object) {
                return switch (object) {
                  _LayoutedWaypoint() => Positioned(
                    left: (object.position!.dx + canvasSize!.width / 2) * scale,
                    top: (object.position!.dy + canvasSize!.height / 2) * scale,
                    child: _WaypointInfoWidget(object.waypoint),
                  ),
                  _ => Placeholder(),
                };
              }),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: UnconstrainedBox(
            child: Slider(
              value: scale,
              min: 0.5,
              max: 2,
              onChanged: (value) {
                /// The translation represents the (scaled) difference between the
                /// top left of the InteractiveViewer and the top left of the canvas.
                final translation3 = transformationController.value
                    .getTranslation();
                final viewCenter = context.size!.center(Offset.zero);

                /// The focal point is the view center, relative to the origin of the canvas.
                final focalPoint =
                    viewCenter - Offset(translation3.x, translation3.y);
                // Quick math (do a drawing).
                final newTranslation3 = viewCenter - focalPoint / scale * value;
                transformationController.value = Matrix4.translationValues(
                  newTranslation3.dx,
                  newTranslation3.dy,
                  0,
                );
                setState(() {
                  scale = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _LayoutedObjectWidget extends StatefulWidget {
  final _LayoutedObject object;
  final _SystemMapState mapState;

  const _LayoutedObjectWidget({required this.object, required this.mapState});

  @override
  State<_LayoutedObjectWidget> createState() => _LayoutedObjectWidgetState();
}

class _LayoutedObjectWidgetState extends State<_LayoutedObjectWidget> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.mapState.toggleDescriptionShown(widget.object);
      },
      child: MouseRegion(
        hitTestBehavior: HitTestBehavior.deferToChild,
        onEnter: (event) => setState(() {
          hovered = true;
        }),
        onExit: (event) => setState(() {
          hovered = false;
        }),
        child: CustomPaint(
          painter: _ObjectPainter(widget.object, growScalar: hovered ? 3 : 0),
          size: widget.mapState.canvasSize!,
        ),
      ),
    );
  }
}

abstract class _LayoutedObjectStyle {
  final double radius;
  final Color orbitStrokeColor;
  final double orbitStrokeWidth;

  const _LayoutedObjectStyle({
    required this.radius,
    required this.orbitStrokeColor,
    required this.orbitStrokeWidth,
  });
}

abstract class _LayoutedObject {
  final Map<String, _LayoutedObject> objectsMap;

  final _LayoutedObjectStyle style;

  Offset? position;
  Offset? orbitCenter;
  double? orbitDistance;

  double? _totalSize;
  String? orbits;
  final List<_LayoutedObject> _orbitals = [];

  _LayoutedObject.orbits({
    required this.objectsMap,
    required String this.orbits,
    required this.style,
  });

  _LayoutedObject.positioned({
    required this.objectsMap,
    required Offset this.position,
    required this.style,
  });

  void computeOrbits() {
    if (orbits != null) {
      objectsMap[orbits]!._orbitals.add(this);
    }
  }

  void computeTotalSizes() {
    if (_totalSize != null) {
      return;
    }

    double maxChildrenSize = 0;
    for (var orbital in _orbitals) {
      orbital.computeTotalSizes();
      maxChildrenSize = max(maxChildrenSize, orbital._totalSize!);
    }

    _totalSize = style.radius + maxChildrenSize;
  }

  void computePositions() {
    if (orbitCenter != null) {
      return;
    }

    if (orbits != null) {
      final layoutedOrbits = objectsMap[orbits]!;
      orbitCenter = layoutedOrbits.position!;

      int siblingId = layoutedOrbits._orbitals.indexOf(this);
      int siblings = layoutedOrbits._orbitals.length;
      orbitDistance =
          layoutedOrbits.style.radius +
          1 +
          layoutedOrbits._orbitals
              .map((sibling) => sibling._totalSize!)
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
      assert(position != null);
      orbitCenter = Offset.zero;
      orbitDistance = position!.distance;
    }

    for (var orbital in _orbitals) {
      orbital.computePositions();
    }
  }
}

class _ObjectPainter extends CustomPainter {
  final _LayoutedObject object;
  final double growScalar;

  Size size = Size.zero;

  _ObjectPainter(this.object, {this.growScalar = 0});

  @override
  void paint(Canvas canvas, Size size) {
    this.size = size;
    canvas.translate(size.height / 2, size.width / 2);

    switch (object.style) {
      case _LayoutedWaypointStyle(:final radius, :final color):
        canvas.drawCircle(
          object.position!,
          radius + growScalar,
          Paint()..color = color,
        );
      case _:
        throw UnsupportedError("Object style not recognized");
    }
  }

  @override
  bool? hitTest(Offset position) {
    double rad = object.style.radius + growScalar;
    return (position.translate(-size.height / 2, -size.width / 2) -
                object.position!)
            .distanceSquared <=
        rad * rad;
  }

  @override
  bool shouldRepaint(covariant _ObjectPainter oldDelegate) {
    return object != oldDelegate.object || growScalar != oldDelegate.growScalar;
  }
}

/// The orbits painter is separate from the waypoint painter so all orbits are
/// drawn below all waypoints and other decorations.
class _OrbitsPainter extends CustomPainter {
  final Iterable<_LayoutedObject> objects;

  _OrbitsPainter({required this.objects});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.height / 2, size.width / 2);

    for (var object in objects) {
      canvas.drawCircle(
        object.orbitCenter!,
        object.orbitDistance!,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = object.style.orbitStrokeColor
          ..strokeWidth = object.style.orbitStrokeWidth
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitsPainter oldDelegate) {
    return objects != oldDelegate.objects;
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

class _SystemStarPainter extends CustomPainter {
  final SystemType type;

  const _SystemStarPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.height / 2, size.width / 2);

    /* final sunRadius =
        waypoints
            .where((w) => !w.waypoint.hasOrbits())
            .map((w) => w.orbitDistance! - w.orbitalsSize!)
            .reduce(min) -
        5; */
    final style = _systemTypeStyles[type]!;
    canvas.drawCircle(
      Offset.zero,
      style.radius,
      Paint()
        ..color = style.color
        ..style = PaintingStyle.fill,
    );
    if (style.outerLayerColor != null) {
      canvas.drawCircle(
        Offset.zero,
        style.radius,
        Paint()
          ..color = style.outerLayerColor!
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension on WaypointType {
  String get prettyName =>
      name.substring("WAYPOINT_".length).toLowerCase().replaceAll("_", " ");
}

extension on SystemType {
  String get prettyName =>
      name.substring("SYSTEM_".length).toLowerCase().replaceAll("_", " ");
}
