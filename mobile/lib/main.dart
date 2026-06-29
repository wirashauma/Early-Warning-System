import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/admin_navigation.dart';
import 'models/auth_provider.dart';
import 'models/auth_service.dart';
import 'models/admin_provider.dart';
import 'providers/telemetry_provider.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'localization/app_localizations.dart';
import 'localization/locale_provider.dart';

/// Global navigator key — digunakan NotificationService untuk navigasi
/// saat user tap notifikasi dari background/terminated state.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

FirebaseOptions _firebaseOptionsFromEnv() {
  final defaultOptions = DefaultFirebaseOptions.currentPlatform;

  return FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY']?.trim() ?? defaultOptions.apiKey,
    appId: dotenv.env['FIREBASE_APP_ID']?.trim() ?? defaultOptions.appId,
    messagingSenderId:
        dotenv.env['FIREBASE_MESSAGING_SENDER_ID']?.trim() ??
        defaultOptions.messagingSenderId,
    projectId:
        dotenv.env['FIREBASE_PROJECT_ID']?.trim() ?? defaultOptions.projectId,
    authDomain:
        dotenv.env['FIREBASE_AUTH_DOMAIN']?.trim() ?? defaultOptions.authDomain,
    storageBucket:
        dotenv.env['FIREBASE_STORAGE_BUCKET']?.trim() ??
        defaultOptions.storageBucket,
    measurementId:
        dotenv.env['FIREBASE_MEASUREMENT_ID']?.trim() ??
        defaultOptions.measurementId,
    iosBundleId:
        dotenv.env['FIREBASE_IOS_BUNDLE_ID']?.trim() ??
        defaultOptions.iosBundleId,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Peringatan: File .env tidak ditemukan.");
  }

  // Initialize Supabase only when the app is configured for it.
  final hasSupabaseConfig =
      (dotenv.env['SUPABASE_URL']?.trim().isNotEmpty ?? false) &&
      (dotenv.env['SUPABASE_ANON_KEY']?.trim().isNotEmpty ?? false);
  if (hasSupabaseConfig) {
    try {
      final supabase = SupabaseService();
      await supabase.initialize();
      supabase.subscribeToRealtime();
    } catch (e) {
      debugPrint("Supabase Realtime initialization error: $e");
    }
  } else {
    debugPrint('Supabase config not found; realtime bootstrap skipped.');
  }

  try {
    final useNativeFirebaseConfig =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    if (useNativeFirebaseConfig) {
      // Android menggunakan google-services.json secara native
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(options: _firebaseOptionsFromEnv());
    }

    // Initialize notification service — pass navigatorKey untuk handle tap
    try {
      await NotificationService.instance.init(
        navigatorKey: navigatorKey,
      );
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  try {
    await AuthService.instance.restoreSession();
  } catch (e) {
    debugPrint('Auth session restore error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(
          create: (_) => TelemetryProvider()..loadInitialData(),
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..loadLocale()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'EWS Flood Guard',
            theme: AppTheme.theme,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              // These delegates provide default localization for
              // widgets like Material components.
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => LoginScreen(
                onLoginSuccess: () {
                  final auth = context.read<AuthProvider>();
                  final currentRole = auth.userRole.toString().toUpperCase();
                  final isAdmin =
                      currentRole == 'ADMIN' ||
                      currentRole == 'SUPER_ADMIN' ||
                      currentRole.contains('ADMIN');

                  if (isAdmin) {
                    Navigator.pushReplacementNamed(context, '/admin');
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
              ),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const MainNavigation(),
              '/admin': (context) => const AdminNavigation(),
            },
          );
        },
      ),
    );
  }
}
