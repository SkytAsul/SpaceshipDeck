import 'package:commons/commons.dart';
import 'package:flutter/material.dart' show Tooltip;
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';

class ShipWidget extends StatelessWidget {
  final Ship ship;

  static const radius = 4.0;

  const ShipWidget(this.ship, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // SystemMapState.of(context).togglePopup(widget.waypoint.symbol);
      },
      child: Tooltip(
        message: ship.symbol,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          padding: .zero,
          decoration: BoxDecoration(
            shape: .circle,
            color: context.theme.colors.primary.withAlpha(150),
          ),
          alignment: .center,
          child: FaIcon(
            FontAwesomeIcons.rocket,
            size: radius * 1.2,
            color: context.theme.colors.primaryForeground,
          ),
        ),
      ),
    );
  }
}
