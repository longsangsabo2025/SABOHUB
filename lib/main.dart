import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'utils/error_tracker.dart' as tracker;
import 'utils/longsang_error_reporter.dart'; // 🔴 LONGSANG AUTO-FIX
import 'widgets/error_boundary.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return ErrorBoundary(
      child: MaterialApp.router(
        title: 'SABOHUB Flutter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }
}
