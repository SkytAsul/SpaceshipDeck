import 'dart:math';

import 'package:commons/commons.dart';
import 'package:deck_controller/src/features/system/data/system_repository.dart';
import 'package:deck_controller/src/features/windows/presentation/widgets.dart';
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
  final Map<String, _LayoutedSystemWaypoint> _waypointsMap = {};
  Size? canvasSize;
  double scale = 1;

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
                          painter: _WaypointsOrbitsPainter(
                            waypoints: _waypointsMap.values,
                          ),
                          size: canvasSize!,
                        ),
                        ..._waypointsMap.values.map(
                          (waypoint) => _WaypointWidget(
                            waypoint: waypoint,
                            mapState: this,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ..._waypointsWithDescription.map((symbol) {
                var waypoint = _waypointsMap[symbol]!;
                return Positioned(
                  left: (waypoint.position!.dx + canvasSize!.width / 2) * scale,
                  top: (waypoint.position!.dy + canvasSize!.height / 2) * scale,
                  child: _WaypointInfoWidget(waypoint.waypoint),
                );
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
        child: CustomPaint(
          painter: _WaypointPainter(
            widget.waypoint,
            growScalar: hovered ? 3 : 0,
          ),
          size: widget.mapState.canvasSize!,
        ),
      ),
    );
  }
}

class _WaypointInfoWidget extends ConsumerStatefulWidget {
  final SystemWaypoint waypoint;

  const _WaypointInfoWidget(this.waypoint);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _WaypointInfoWidgetState();
}

class _WaypointInfoWidgetState extends ConsumerState<_WaypointInfoWidget> {
  bool fetchedInformation = false;

  @override
  void initState() {
    super.initState();
    fetchedInformation = ref.exists(
      fetchWaypointProvider(widget.waypoint.symbol),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DeckCard(
      child: Builder(
        builder: (context) {
          var theme = Theme.of(context);
          var textStyle = theme.textTheme.bodyMedium!;

          var widgets = <Widget>[
            Align(
              child: Text(
                widget.waypoint.symbol,
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: textStyle,
                children: [
                  TextSpan(
                    text: "Type: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: widget.waypoint.type.name),
                ],
              ),
            ),
          ];

          switch (fetchedInformation
              ? ref.watch(fetchWaypointProvider(widget.waypoint.symbol))
              : null) {
            case null:
              widgets += [
                SizedBox(height: 10),
                Align(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => fetchedInformation = true);
                    },
                    child: Text("Fetch info"),
                  ),
                ),
              ];
            case AsyncError(:final error):
              widgets.add(Text("Error: $error"));
            case AsyncData(value: final waypoint):
              if (waypoint.isUnderConstruction) {
                widgets.add(Text("Under construction"));
              }
              widgets += [
                Divider(color: theme.colorScheme.onSecondaryContainer),
                Text(
                  "Traits:",
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: waypoint.traits
                      .map((trait) => _WaypointTraitWidget(trait))
                      .toList(),
                ),
              ];
              if (waypoint.modifiers.isNotEmpty) {
                widgets += [
                  Divider(color: theme.colorScheme.onSecondaryContainer),
                  Text(
                    "Modifiers:",
                    style: textStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: waypoint.modifiers
                        .map((modifier) => _WaypointModifierWidget(modifier))
                        .toList(),
                  ),
                ];
              }
            case _:
              widgets.add(Align(child: CircularProgressIndicator()));
          }

          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300),
            // XXX somehow is always 300 because of the Align widgets inside
            child: DefaultTextStyle(
              style: textStyle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widgets,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WaypointTraitWidget extends StatelessWidget {
  final WaypointTrait trait;

  const _WaypointTraitWidget(this.trait);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: trait.description,
      child: Chip(label: Text(trait.name)),
    );
  }
}

class _WaypointModifierWidget extends StatelessWidget {
  final WaypointModifier modifier;

  const _WaypointModifierWidget(this.modifier);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: modifier.description,
      child: Chip(label: Text(modifier.name)),
    );
  }
}

class _WaypointTypeStyle {
  final double radius;
  final Color color;
  final double orbitStrokeWidth;

  const _WaypointTypeStyle({
    this.radius = 1,
    this.color = Colors.tealAccent,
    this.orbitStrokeWidth = 0.1,
  });
}

final _waypointTypeStyles = {
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
    color: Colors.blueGrey,
    orbitStrokeWidth: 0.15,
  ),
  WaypointType.WAYPOINT_ASTEROID: _WaypointTypeStyle(
    radius: 1.5,
    color: Colors.brown,
    orbitStrokeWidth: 0.05,
  ),
  WaypointType.WAYPOINT_ASTEROID_FIELD: _WaypointTypeStyle(
    radius: 3,
    color: Colors.teal,
  ),
  WaypointType.WAYPOINT_ASTEROID_BASE: _WaypointTypeStyle(
    radius: 1.2,
    color: Colors.red.shade900,
  ),
  WaypointType.WAYPOINT_FUEL_STATION: _WaypointTypeStyle(
    color: Colors.deepOrange,
  ),
  WaypointType.WAYPOINT_ORBITAL_STATION: _WaypointTypeStyle(color: Colors.red),
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
          ..strokeWidth = waypoint.style.orbitStrokeWidth
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaypointsOrbitsPainter oldDelegate) {
    return waypoints != oldDelegate.waypoints;
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
