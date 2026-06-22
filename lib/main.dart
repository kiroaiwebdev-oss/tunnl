import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/services/app_settings_service.dart';
import 'core/services/language_service.dart';
import 'features/splash/splash_screen.dart';

void main() {
  // Wrap everything in a guarded zone so any uncaught async error during
  // boot doesn't silently kill the process (which is the #1 reason a
  // release APK shows the launcher icon and then closes immediately).
  runZonedGuarded<void>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Show the framework error UI in red instead of a blank screen so we
    // can at least see what blew up on a real device.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
    };

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF070B14),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    } catch (e, st) {
      debugPrint('[main] system chrome setup failed: $e\n$st');
    }

    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeController(),
        child: const TunnelApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('[ZoneError] $error');
    debugPrint('[ZoneStack] $stack');
  });
}

class TunnelApp extends StatefulWidget {
  const TunnelApp({super.key});

  @override
  State<TunnelApp> createState() => _TunnelAppState();
}

class _TunnelAppState extends State<TunnelApp> with WidgetsBindingObserver {
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
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Quietly re-fetch app settings so admin changes (price, razorpay
      // keys, banners, maintenance flag, force-update version, etc.)
      // reflect without requiring a restart.
      AppSettingsService.instance.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    // Rebuild the whole app when the user switches language (English ⇄ Hindi)
    // from Profile, so static UI strings update instantly without a restart.
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => MaterialApp(
        title: 'Tunnl',
        debugShowCheckedModeBanner: false,
        themeMode: themeController.themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const SplashScreen(),
        builder: (context, child) {
          // Wrap with a no-overflow MediaQuery clamp so big-fonts users don't
          // explode our hand-tuned layouts.
          final mq = MediaQuery.of(context);
          final clamped = mq.textScaler.clamp(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.15,
          );
          return MediaQuery(
            data: mq.copyWith(textScaler: clamped),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
