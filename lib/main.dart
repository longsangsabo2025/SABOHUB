import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'widgets/error_boundary.dart';
// import 'utils/debug_utils.dart' if (dart.library.html) 'utils/debug_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Debug System (temporarily disabled)
  // if (kDebugMode && kIsWeb) {
  //   DebugProvider().initialize();
  // }

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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B82F6),
            brightness: Brightness.light,
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}
