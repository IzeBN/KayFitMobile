import 'package:flutter/material.dart';

/// Wraps [child] in a [GestureDetector] that unfocuses the current focus
/// node (closing the keyboard) when the user taps on an area that is not
/// an interactive widget.
///
/// Uses [HitTestBehavior.opaque] so that taps on empty / background areas
/// are also captured, but Flutter's standard hit-test bubble still lets
/// taps pass through to child widgets (buttons, text fields, etc.).
///
/// Apply at the [Scaffold] level (wrap the whole Scaffold) rather than at
/// the [MaterialApp] level to avoid interfering with dialogs and sheets.
class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
  }
}
