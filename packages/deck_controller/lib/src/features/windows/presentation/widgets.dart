import 'package:flutter/material.dart';

class DeckCard extends StatelessWidget {
  final Widget child;

  const DeckCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        border: BoxBorder.all(color: theme.colorScheme.secondary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Theme(
          data: theme.copyWith(
            textTheme: theme.textTheme.apply(
              bodyColor: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
