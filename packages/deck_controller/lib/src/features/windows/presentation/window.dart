import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

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
    final colors = context.theme.colors;
    return Container(
      width: initialWidth,
      height: initialHeight,
      decoration: BoxDecoration(
        color: colors.background,
        border: BoxBorder.all(color: colors.secondary, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: colors.primary,
            padding: EdgeInsets.only(left: 8),
            child: Text(
              title,
              style: context.theme.typography.display.md.copyWith(
                color: colors.primaryForeground,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
