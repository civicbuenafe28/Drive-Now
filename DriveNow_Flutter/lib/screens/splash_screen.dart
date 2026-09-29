import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import 'getting_started_screen.dart';
import 'main_shell.dart';

/// Port of ContentView: two animated splash screens, then the app.
///
///  1. White screen — blue logo scales + fades in
///  2. Cross-fade to navy — white logo scales in with a soft glow
///  3. Fade/zoom transition into Get Started (or Home if already logged in)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _stage = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    setState(() => _stage = 1);
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;

    final next = AuthService.instance.isSignedIn ? const MainShell() : const GettingStartedScreen();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 900),
      pageBuilder: (_, __, ___) => next,
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 1.06, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _stage == 0
          ? const _SplashStage(
              key: ValueKey(0),
              background: Colors.white,
              asset: 'assets/images/logo-blue.jpg',
              glow: false,
            )
          : const _SplashStage(
              key: ValueKey(1),
              background: AppColors.splashNavy,
              asset: 'assets/images/logo-white.png',
              glow: true,
            ),
    );
  }
}

/// One splash screen: the logo pops in (scale + fade) and slowly "breathes".
class _SplashStage extends StatefulWidget {
  const _SplashStage({super.key, required this.background, required this.asset, required this.glow});
  final Color background;
  final String asset;
  final bool glow;

  @override
  State<_SplashStage> createState() => _SplashStageState();
}

class _SplashStageState extends State<_SplashStage> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intro = CurvedAnimation(parent: _c, curve: const Interval(0, 0.45, curve: Curves.easeOutBack));
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.35, curve: Curves.easeOut));
    final breathe = CurvedAnimation(parent: _c, curve: const Interval(0.45, 1, curve: Curves.easeInOut));

    return Container(
      color: widget.background,
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final scale = 0.7 + 0.3 * intro.value + 0.04 * breathe.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.glow)
                Opacity(
                  opacity: (fade.value * 0.9).clamp(0.0, 1.0),
                  child: Container(
                    width: 340 * (0.8 + 0.2 * breathe.value),
                    height: 340 * (0.8 + 0.2 * breathe.value),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [Color(0x554073FF), Color(0x004073FF)]),
                    ),
                  ),
                ),
              Opacity(
                opacity: fade.value.clamp(0.0, 1.0),
                child: Transform.scale(scale: scale, child: child),
              ),
            ],
          );
        },
        child: Image.asset(widget.asset, width: 300, height: 300, fit: BoxFit.contain),
      ),
    );
  }
}
