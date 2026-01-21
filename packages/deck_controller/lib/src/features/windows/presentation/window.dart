import 'package:flutter/material.dart';

class WindowWidget extends StatelessWidget {
  final String title;
  final Widget child;

  final double initialWidth;
  final double initialHeight;

  const WindowWidget({
    super.key,
    required this.title,
    required this.child,
    this.initialWidth = 600,
    this.initialHeight = 400,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: initialWidth,
      height: initialHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: BoxBorder.all(color: theme.colorScheme.secondary, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: theme.colorScheme.primaryContainer,
            padding: EdgeInsets.only(left: 8),
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
