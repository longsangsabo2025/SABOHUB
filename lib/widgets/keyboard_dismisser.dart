import 'package:flutter/material.dart';

/// A widget that dismisses the keyboard when tapping outside of text fields.
/// 
/// Wrap your app or any widget tree with this to enable automatic keyboard dismissal
/// when the user taps anywhere outside of a TextField or other focusable widget.
/// 
/// Usage:
/// ```dart
/// KeyboardDismisser(
///   child: MaterialApp(...),
/// )
/// ```
class KeyboardDismisser extends StatelessWidget {
  final Widget child;
  
  /// If true, the keyboard will be dismissed when tapping on non-focusable areas
  final bool dismissOnTap;
  
  /// If true, the keyboard will be dismissed when dragging/scrolling
  final bool dismissOnDrag;

  const KeyboardDismisser({
    super.key,
    required this.child,
    this.dismissOnTap = true,
    this.dismissOnDrag = true,
  });

  void _dismissKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: dismissOnTap ? () => _dismissKeyboard(context) : null,
      onVerticalDragStart: dismissOnDrag ? (_) => _dismissKeyboard(context) : null,
      onHorizontalDragStart: dismissOnDrag ? (_) => _dismissKeyboard(context) : null,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

/// Extension method to easily dismiss keyboard from anywhere
extension KeyboardDismissExtension on BuildContext {
  /// Dismiss the keyboard if it's currently visible
  void dismissKeyboard() {
    final currentFocus = FocusScope.of(this);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
  
  /// Check if keyboard is currently visible
  bool get isKeyboardVisible {
    return MediaQuery.of(this).viewInsets.bottom > 0;
  }
}

/// A mixin that provides keyboard dismissal functionality for StatefulWidgets
mixin KeyboardDismissMixin<T extends StatefulWidget> on State<T> {
  void dismissKeyboard() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
  
  bool get isKeyboardVisible {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }
}
