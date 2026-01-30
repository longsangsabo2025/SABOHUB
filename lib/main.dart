import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/network_provider.dart';
import 'utils/error_tracker.dart' as tracker;
import 'utils/longsang_error_reporter.dart'; // 🔴 LONGSANG AUTO-FIX
import 'widgets/error_boundary.dart';
import 'widgets/keyboard_dismisser.dart';
// import 'utils/debug_utils.dart' if (dart.library.html) 'utils/debug_utils.dart';

void main() {
  LongSangErrorReporter.init(() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env.local');
  
  // Initialize Vietnamese locale for date formatting
  await initializeDateFormatting('vi', null);

  // Initialize Debug System (temporarily disabled)
  // if (kDebugMode && kIsWeb) {
  //   DebugProvider().initialize();
  // }

  // Initialize Performance & Error Tracking
  await tracker.ErrorTracker().initialize();
  
  // Initialize Supabase with persistent session
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      // Auto refresh token khi sắp hết hạn
      autoRefreshToken: true,
    ),
    // Debug để xem session storage
    debug: true,
  );

  runApp(const ProviderScope(child: SaboHubApp()));
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    // Wrap entire app with KeyboardDismisser for auto-hide keyboard on tap outside
    return KeyboardDismisser(
      child: NetworkStatusListener(
        child: ErrorBoundary(
          child: MaterialApp.router(
            title: 'SABOHUB Flutter',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
            // Scroll behavior for better UX
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              // Enable scroll physics that feel native on both platforms
              physics: const BouncingScrollPhysics(),
            ),
            builder: (context, child) {
              // Apply global UI improvements
              return MediaQuery(
                // Prevent text scaling from breaking UI
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
                  ),
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
