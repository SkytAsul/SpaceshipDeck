part of 'system_page.dart';

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

class _LayoutedWaypoint extends _LayoutedObject {
  final SystemWaypoint waypoint;

  _LayoutedWaypoint.orbits({
    required this.waypoint,
    required super.objectsMap,
    required super.orbits,
    required super.style,
  }) : super.orbits();
  _LayoutedWaypoint.positioned({
    required this.waypoint,
    required super.objectsMap,
    required super.position,
    required super.style,
  }) : super.positioned();

  factory _LayoutedWaypoint(
    SystemWaypoint waypoint,
    Map<String, _LayoutedObject> objectsMap,
  ) {
    final style =
        _waypointTypeStyles[waypoint.type] ?? const _LayoutedWaypointStyle();
    if (waypoint.hasOrbits()) {
      return _LayoutedWaypoint.orbits(
        waypoint: waypoint,
        objectsMap: objectsMap,
        orbits: waypoint.orbits,
        style: style,
      );
    } else {
      return _LayoutedWaypoint.positioned(
        waypoint: waypoint,
        objectsMap: objectsMap,
        position: Offset(waypoint.x.toDouble(), waypoint.y.toDouble()),
        style: style,
      );
    }
  }
}

class _LayoutedWaypointStyle extends _LayoutedObjectStyle {
  final Color color;

  const _LayoutedWaypointStyle({
    super.radius = 1,
    this.color = Colors.tealAccent,
    super.orbitStrokeWidth = 0.1,
  }) : super(orbitStrokeColor: color);
}

final _waypointTypeStyles = {
  WaypointType.WAYPOINT_PLANET: _LayoutedWaypointStyle(
    radius: 5,
    color: Colors.green,
    orbitStrokeWidth: 0.2,
  ),
  WaypointType.WAYPOINT_GAS_GIANT: _LayoutedWaypointStyle(
    radius: 7,
    color: Colors.blue,
    orbitStrokeWidth: 0.2,
  ),
  WaypointType.WAYPOINT_MOON: _LayoutedWaypointStyle(
    radius: 3,
    color: Colors.blueGrey,
    orbitStrokeWidth: 0.15,
  ),
  WaypointType.WAYPOINT_ASTEROID: _LayoutedWaypointStyle(
    radius: 1.5,
    color: Colors.brown,
    orbitStrokeWidth: 0.05,
  ),
  WaypointType.WAYPOINT_ASTEROID_FIELD: _LayoutedWaypointStyle(
    radius: 3,
    color: Colors.teal,
  ),
  WaypointType.WAYPOINT_ASTEROID_BASE: _LayoutedWaypointStyle(
    radius: 1.2,
    color: Colors.red.shade900,
  ),
  WaypointType.WAYPOINT_FUEL_STATION: _LayoutedWaypointStyle(
    color: Colors.deepOrange,
  ),
  WaypointType.WAYPOINT_ORBITAL_STATION: _LayoutedWaypointStyle(
    color: Colors.red,
  ),
};
