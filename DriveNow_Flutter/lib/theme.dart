import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// DriveNow design tokens — navy + electric blue brand from the iOS app,
/// refined into a layered dark theme.
class AppColors {
  // Brand
  static const primary = Color(0xFF4073FF); // (0.25, 0.45, 1.0) from iOS
  static const primaryDark = Color(0xFF2F58D6);
  static const primaryLight = Color(0xFF7A9CFF);

  // Surfaces (darkest -> lightest)
  static const bg = Color(0xFF061431);
  static const surface = Color(0xFF0D1F45);
  static const surfaceHigh = Color(0xFF152B58);
  static const surfaceHigher = Color(0xFF1E376B);
  static const border = Color(0x1FFFFFFF); // white 12%
  static const borderStrong = Color(0x33FFFFFF); // white 20%

  // Text
  static const text = Colors.white;
  static const textSecondary = Color(0xFFB3BED6);
  static const textMuted = Color(0xFF7D8BAA);

  // Status
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF38BDF8);
  static const star = Color(0xFFFBBF24);

  // Payment brands
  static const gcash = Color(0xFF0066CC);
  static const cardTop = Color(0xFF1B2A6B);
  static const cardBottom = Color(0xFF4073FF);

  // Legacy names (splash / logos)
  static const navy = Color(0xFF081C42);
  static const splashNavy = Color(0xFF1A3366);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B86FF), Color(0xFF2F58D6)],
  );

  static const carStageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E376B), Color(0xFF0D1F45)],
  );
}

class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

/// Text styles (Poppins).
class AppText {
  static const display = TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.text, height: 1.2);
  static const h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text, height: 1.25);
  static const h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text, height: 1.3);
  static const h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text, height: 1.35);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static const bodyStrong = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text, height: 1.45);
  static const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.4);
  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2);
  static const price = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.primaryLight,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    splashFactory: InkRipple.splashFactory,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: Color(0x554073FF),
      selectionHandleColor: AppColors.primary,
    ),
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
