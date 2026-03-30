// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:altemby/app_router.dart';
import 'package:altemby/core/theme/app_theme.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  runApp(const ProviderScope(child: AltEmbyApp()));
}

class AltEmbyApp extends ConsumerStatefulWidget {
  const AltEmbyApp({super.key});

  @override
  ConsumerState<AltEmbyApp> createState() => _AltEmbyAppState();
}

class _AltEmbyAppState extends ConsumerState<AltEmbyApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize device ID on the interceptor
    final deviceUtils = ref.read(deviceUtilsProvider);
    final deviceId = await deviceUtils.getOrCreateDeviceId();
    ref.read(embyAuthInterceptorProvider).deviceId = deviceId;

    // Try to restore previous session
    await ref.read(authNotifierProvider.notifier).tryRestoreSession();

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AltEmby',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
