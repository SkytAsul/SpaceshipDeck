import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ShipWidget extends StatelessWidget {
  final Ship ship;

  static const radius = 5;

  const ShipWidget(this.ship, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(shape: .circle, color: Colors.yellow),
      child: Icon(Icons.airplanemode_active),
    );
  }
}
