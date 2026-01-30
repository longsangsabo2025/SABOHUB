import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App lifecycle manager that handles app state changes
/// 
/// Usage:
/// ```dart
/// class MyApp extends StatefulWidget {
///   @override
///   _MyAppState createState() => _MyAppState();
/// }
/// 
/// class _MyAppState extends State<MyApp> with AppLifecycleMixin {
///   @override
///   void onAppResumed() {
///     // Refresh data when app comes to foreground
///   }
///   
///   @override
///   void onAppPaused() {
///     // Save state when app goes to background
///   }
/// }
/// ```
mixin AppLifecycleMixin<T extends StatefulWidget> on State<T> implements WidgetsBindingObserver {
  AppLifecycleState _lastLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lastLifecycleState = state;
    
    switch (state) {
      case AppLifecycleState.resumed:
        onAppResumed();
        break;
      case AppLifecycleState.inactive:
        onAppInactive();
        break;
      case AppLifecycleState.paused:
        onAppPaused();
        break;
      case AppLifecycleState.detached:
        onAppDetached();
        break;
      case AppLifecycleState.hidden:
        onAppHidden();
        break;
    }
  }

  /// Called when the application is visible and responding to user input.
  void onAppResumed() {}

  /// Called when the application is in an inactive state and not receiving user input.
  void onAppInactive() {}

  /// Called when the application is not currently visible to the user.
  void onAppPaused() {}

  /// Called when the application is still hosted but detached from any host views.
  void onAppDetached() {}

  /// Called when all views of an application are hidden.
  void onAppHidden() {}

  /// Get the current lifecycle state
  AppLifecycleState get currentLifecycleState => _lastLifecycleState;

  /// Check if app is currently in foreground
  bool get isAppInForeground => _lastLifecycleState == AppLifecycleState.resumed;

  @override
  void didChangeAccessibilityFeatures() {}

  @override
  void didChangeLocales(List<Locale>? locales) {}

  @override
  void didChangeMetrics() {}

  @override
  void didChangePlatformBrightness() {}

  @override
  void didChangeTextScaleFactor() {}

  @override
  void didHaveMemoryPressure() {
    // Handle memory pressure - clear caches etc.
    onMemoryPressure();
  }

  @override
  Future<bool> didPopRoute() async => false;

  @override
  Future<bool> didPushRoute(String route) async => false;

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async => false;

  // Note: didRequestAppExit requires ui.AppExitResponse which may not be available
  // Remove this override if causing issues

  /// Called when system is low on memory
  void onMemoryPressure() {}
}

/// Widget that handles double-tap back button to exit app
class DoubleTapBackExit extends StatefulWidget {
  final Widget child;
  final Duration exitDuration;
  final String exitMessage;

  const DoubleTapBackExit({
    super.key,
    required this.child,
    this.exitDuration = const Duration(seconds: 2),
    this.exitMessage = 'Nhấn lần nữa để thoát',
  });

  @override
  State<DoubleTapBackExit> createState() => _DoubleTapBackExitState();
}

class _DoubleTapBackExitState extends State<DoubleTapBackExit> {
  DateTime? _lastBackPressTime;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > widget.exitDuration) {
      _lastBackPressTime = now;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.exitMessage),
          duration: widget.exitDuration,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: widget.child,
    );
  }
}

/// A wrapper that prevents accidental back navigation
/// 
/// Shows a confirmation dialog before allowing back navigation
class BackNavigationGuard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? message;
  final VoidCallback? onConfirm;
  final bool enabled;

  const BackNavigationGuard({
    super.key,
    required this.child,
    this.title,
    this.message,
    this.onConfirm,
    this.enabled = true,
  });

  Future<bool> _showConfirmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Xác nhận'),
        content: Text(message ?? 'Bạn có chắc muốn quay lại? Dữ liệu chưa lưu sẽ bị mất.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldPop = await _showConfirmDialog(context);
        if (shouldPop && context.mounted) {
          onConfirm?.call();
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
