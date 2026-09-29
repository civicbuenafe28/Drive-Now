import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/app_data.dart';
import 'services/auth_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Port of AppDelegate: FirebaseApp.configure()
  final firebaseReady = await _initFirebase();
  debugPrint(firebaseReady
      ? 'Connected to Firebase'
      : 'Firebase not configured - running in offline mode');

  await AuthService.instance.init(firebase: firebaseReady);
  await AppData.instance.init();
  if (AuthService.instance.isSignedIn) {
    AppData.instance.loadForCurrentUser(); // splash screen covers the loading
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DriveNowApp());
}

Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    return true;
  } catch (_) {
    // Maybe only google-services.json was added (no firebase_options.dart).
    try {
      await Firebase.initializeApp();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class DriveNowApp extends StatelessWidget {
  const DriveNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveNow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Samsung phones often use a larger system font. Keep text readable but
      // cap the scale so layouts never overflow.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.1,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const SplashScreen(),
    );
  }
}
