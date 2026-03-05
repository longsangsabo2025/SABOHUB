import 'dart:async';
import 'package:flutter/foundation.dart';

/// 🔴 LONGSANG Error Reporter
/// Wraps the app entry point with zone-level error catching
class LongSangErrorReporter {
  /// Initialize error reporting zone and run the app
  static void init(Future<void> Function() appRunner, {String appName = 'app'}) {
    runZonedGuarded(
      () async {
        try {
          await appRunner();
        } catch (error, stackTrace) {
          debugPrint('[$appName] Startup error: $error');
          debugPrint('$stackTrace');
        }
      },
      (error, stackTrace) {
        debugPrint('[$appName] Uncaught error: $error');
        debugPrint('$stackTrace');
      },
    );
  }
}
