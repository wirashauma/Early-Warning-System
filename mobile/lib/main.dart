import 'package:flutter/material.dart';
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
import 'models/admin_provider.dart';
import 'theme/app_theme.dart';

FirebaseOptions _firebaseOptionsFromEnv() {
  final defaultOptions = DefaultFirebaseOptions.currentPlatform;

  return FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY']?.trim() ?? defaultOptions.apiKey,
    appId: dotenv.env['FIREBASE_APP_ID']?.trim() ?? defaultOptions.appId,
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']?.trim() ??
        defaultOptions.messagingSenderId,
    projectId: dotenv.env['FIREBASE_PROJECT_ID']?.trim() ??
        defaultOptions.projectId,
    authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']?.trim() ??
        defaultOptions.authDomain,
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']?.trim() ??
        defaultOptions.storageBucket,
    measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID']?.trim() ??
        defaultOptions.measurementId,
    iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID']?.trim() ??
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

  try {
    await Firebase.initializeApp(
      options: _firebaseOptionsFromEnv(),
    );
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EWS Flood Guard',
        theme: AppTheme.theme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => LoginScreen(
                onLoginSuccess: () {
                  // MENGAMBIL DATA AKUN YANG BARU LOGIN
                  final auth = context.read<AuthProvider>();
                  
                  // CEK ROLE SECARA TEGAS (Mengantisipasi huruf besar/kecil,
                  // variabel enum backend, atau role berformat USERROLE.ADMIN)
                  final currentRole = auth.userRole.toString().toUpperCase();
                  final isAdmin = currentRole == 'ADMIN' ||
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
      ),
    );
  }
}