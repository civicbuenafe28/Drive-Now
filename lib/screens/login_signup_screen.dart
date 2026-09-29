import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Welcome screen: Log In / Create Account.
class LoginSignUpScreen extends StatelessWidget {
  const LoginSignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = !AuthService.instance.firebaseEnabled;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.1,
            colors: [Color(0xFF16357A), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
              children: [
                const SizedBox(height: 24),
                const Spacer(flex: 3),
                Image.asset('assets/images/logoonly-white.png', height: 110),
                const SizedBox(height: 24),
                const Text('Welcome to DriveNow', textAlign: TextAlign.center, style: AppText.h1),
                const SizedBox(height: 8),
                Text('Your next ride is just a few taps away.',
                    textAlign: TextAlign.center, style: AppText.body.copyWith(fontSize: 15)),
                const Spacer(flex: 4),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Log In',
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Create an Account',
                  variant: ButtonVariant.outline,
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpScreen())),
                ),
                const SizedBox(height: 20),
                if (offline)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('Offline mode · accounts are saved on this phone',
                              textAlign: TextAlign.center, style: AppText.caption),
                        ),
                      ],
                    ),
                  ),
                Text('©2025 Buenafe Inc. All Rights Reserved',
                    textAlign: TextAlign.center, style: AppText.caption.copyWith(fontSize: 11)),
                const SizedBox(height: 16),
              ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
