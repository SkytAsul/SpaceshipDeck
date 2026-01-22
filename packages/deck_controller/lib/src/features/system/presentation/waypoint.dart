import 'package:commons/commons.dart';
import 'package:deck_controller/src/features/system/data/system_repository.dart';
import 'package:deck_controller/src/features/system/presentation/system_window.dart';
import 'package:deck_controller/src/features/windows/presentation/widgets.dart';
import 'package:deck_controller/src/utils/widgets/gravitational_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WaypointWidget extends StatelessWidget {
  final SystemWaypoint waypoint;

  _WaypointStyle get _style =>
      _waypointTypeStyles[waypoint.type] ?? _WaypointStyle();

  const WaypointWidget(this.waypoint, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = _style;
    return GestureDetector(
      onTap: () {
        var realPosition = waypoint.position;
        if (waypoint.hasOrbits()) {
          realPosition += GravitationalLayout.getWidgetPosition(context);
        }
        SystemMapState.of(context).togglePopup(
          id: waypoint.symbol,
          worldPosition: realPosition + Offset(20, 15),
          builder: (context) => WaypointInfoWidget(waypoint),
          linkedTo: realPosition,
        );
      },
      child: Tooltip(
        message: "${waypoint.symbol} (${waypoint.type.prettyName})",
        child: Container(
          width: style.radius * 2,
          height: style.radius * 2,
          decoration: BoxDecoration(shape: .circle, color: style.color),
        ),
      ),
    );
  }
}

class _WaypointStyle {
  final Color color;
  final double radius;
  final double orbitStrokeWidth;

  const _WaypointStyle({
    this.color = Colors.tealAccent,
    this.radius = 1,
    this.orbitStrokeWidth = 0.1,
  });
}

final _waypointTypeStyles = {
  WaypointType.WAYPOINT_PLANET: _WaypointStyle(
    radius: 5,
    color: Colors.green,
    orbitStrokeWidth: 0.2,
  ),
  WaypointType.WAYPOINT_GAS_GIANT: _WaypointStyle(
    radius: 7,
    color: Colors.blue,
    orbitStrokeWidth: 0.2,
  ),
  WaypointType.WAYPOINT_MOON: _WaypointStyle(
    radius: 3,
    color: Colors.blueGrey,
    orbitStrokeWidth: 0.15,
  ),
  WaypointType.WAYPOINT_ASTEROID: _WaypointStyle(
    radius: 1.5,
    color: Colors.brown,
    orbitStrokeWidth: 0.05,
  ),
  WaypointType.WAYPOINT_ASTEROID_FIELD: _WaypointStyle(
    radius: 3,
    color: Colors.teal,
  ),
  WaypointType.WAYPOINT_ASTEROID_BASE: _WaypointStyle(
    radius: 1.2,
    color: Colors.red.shade900,
  ),
  WaypointType.WAYPOINT_FUEL_STATION: _WaypointStyle(color: Colors.deepOrange),
  WaypointType.WAYPOINT_ORBITAL_STATION: _WaypointStyle(color: Colors.red),
};

class WaypointInfoWidget extends ConsumerStatefulWidget {
  final SystemWaypoint waypoint;

  const WaypointInfoWidget(this.waypoint, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _WaypointInfoWidgetState();
}

class _WaypointInfoWidgetState extends ConsumerState<WaypointInfoWidget> {
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
