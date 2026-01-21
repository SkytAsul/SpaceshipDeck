import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class Starfield {
  final _stars = <_Star>[];

  Starfield.random(int starCount, Size size) {
    final random = Random();
    for (int i = 0; i < starCount; i++) {
      _stars.add(
        _Star(
          position: Offset(
            random.nextDouble() * size.width - size.width / 2,
            random.nextDouble() * size.height - size.height / 2,
          ),
          radius: random.nextDouble(),
          color: Colors.lightBlue[(random.nextInt(6) + 1) * 100]!.withAlpha(
            210,
          ),
        ),
      );
    }
  }
}

class _Star {
  final Offset position;
  final double radius;
  final Color color;

  _Star({required this.position, required this.radius, required this.color});
}

class StarfieldPainter extends CustomPainter {
  final Matrix4 transform;

  final Starfield starfield;

  StarfieldPainter({required this.transform, required this.starfield});

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in starfield._stars) {
      final position = _worldToScreen(star.position);
      canvas.drawCircle(position, star.radius, Paint()..color = star.color);
    }
  }

  Offset _worldToScreen(Offset worldPoint) {
    final vector = Vector3(worldPoint.dx, worldPoint.dy, 0);
    vector.applyMatrix4(transform);
    return Offset(vector.x, vector.y);
  }

  @override
  bool shouldRepaint(StarfieldPainter old) => old.transform != transform;
}
