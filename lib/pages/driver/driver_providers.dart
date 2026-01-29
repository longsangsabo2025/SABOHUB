// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to notify when route has been optimized
/// Other pages can watch this to refresh their data
/// Using Riverpod 3.x Notifier pattern
final routeOptimizedProvider = NotifierProvider<RouteOptimizedNotifier, int>(
  RouteOptimizedNotifier.new,
);

class RouteOptimizedNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void notifyOptimized() {
    state++;
  }
}

/// Helper to trigger route optimized notification
void notifyRouteOptimized(WidgetRef ref) {
  ref.read(routeOptimizedProvider.notifier).notifyOptimized();
}
