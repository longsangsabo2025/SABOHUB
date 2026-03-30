import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/sentry_config.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/network_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/error_tracker.dart' as tracker;
import 'utils/longsang_error_reporter.dart'; // 🔴 LONGSANG AUTO-FIX
import 'widgets/error_boundary.dart';
import 'widgets/keyboard_dismisser.dart';
// import 'utils/debug_utils.dart' if (dart.library.html) 'utils/debug_utils.dart';

void main() {
  LongSangErrorReporter.init(() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables with fallback
  // Production apps use .env, development uses .env.local
  try {
    await dotenv.load(fileName: '.env.local');
  } catch (_) {
    // Fallback to .env if .env.local not found (production)
    await dotenv.load(fileName: '.env');
  }
  
  // Initialize Vietnamese locale for date formatting
  await initializeDateFormatting('vi', null);

  // Initialize Debug System (temporarily disabled)
  // if (kDebugMode && kIsWeb) {
  //   DebugProvider().initialize();
  // }

  // Initialize Performance & Error Tracking
  await tracker.ErrorTracker().initialize();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushNotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase not fully configured: $e');
  }

  // Initialize Supabase with persistent session
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      // Auto refresh token khi sắp hết hạn
      autoRefreshToken: true,
    ),
    // Only enable debug in non-release builds
    debug: !kReleaseMode,
  );

  // Initialize Sentry if DSN is configured
    if (SentryConfig.isEnabled) {
      await SentryFlutter.init(
        (options) {
          options.dsn = SentryConfig.dsn;
          options.tracesSampleRate = SentryConfig.tracesSampleRate;
          options.environment = SentryConfig.environment;
          options.sendDefaultPii = false;
          options.attachScreenshot = true;
          options.debug = !kReleaseMode;
        },
        appRunner: () => runApp(const ProviderScope(child: SaboHubApp())),
      );
    } else {
      runApp(const ProviderScope(child: SaboHubApp()));
    }
  }, appName: 'sabo-hub');
}

class SaboHubApp extends ConsumerStatefulWidget {
  const SaboHubApp({super.key});

  @override
  ConsumerState<SaboHubApp> createState() => _SaboHubAppState();
}

class _SaboHubAppState extends ConsumerState<SaboHubApp> {
  @override
  void initState() {
    super.initState();
    // Load user from storage after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).loadUser();
    });
    
    // Set preferred orientations (portrait only for better UX)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Theme.of(context).colorScheme.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeModeAsync = ref.watch(themeProvider);

    // Wrap entire app with KeyboardDismisser for auto-hide keyboard on tap outside
    return KeyboardDismisser(
      child: NetworkStatusListener(
        child: ErrorBoundary(
          child: MaterialApp.router(
            title: 'SABOHUB Flutter',
            debugShowCheckedModeBanner: false,
            themeMode: themeModeAsync.value ?? ThemeMode.light,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            routerConfig: router,
            // Scroll behavior for better UX
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              // Enable scroll physics that feel native on both platforms
              physics: const BouncingScrollPhysics(),
            ),
            builder: (context, child) {
              // Apply global UI improvements
              // Fix iOS oversized display: lock textScaler to 1.0
              // This prevents iOS accessibility/dynamic type from enlarging the UI
              final mediaData = MediaQuery.of(context);
              final constrainedTextScaler = TextScaler.linear(
                mediaData.textScaler.scale(1.0).clamp(0.85, 1.0),
              );
              return MediaQuery(
                data: mediaData.copyWith(
                  textScaler: constrainedTextScaler,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          ),
        ),
      ),
    );
  }
}
