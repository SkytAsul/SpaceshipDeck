import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class DeckCard extends StatelessWidget {
  final Widget child;

  const DeckCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => FCard(
    child: Padding(padding: EdgeInsetsGeometry.all(8), child: child),
  );
}
