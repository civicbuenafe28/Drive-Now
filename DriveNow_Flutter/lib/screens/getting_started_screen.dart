import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/ui.dart';
import 'login_signup_screen.dart';

/// Plays a fade + slide for [child] during the [start]..[end] part of [anim].
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.anim,
    required this.start,
    required this.end,
    required this.child,
    this.from = const Offset(0, 0.25),
  });

  final Animation<double> anim;
  final double start;
  final double end;
  final Offset from;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: anim, curve: Interval(start, end, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(position: Tween(begin: from, end: Offset.zero).animate(curved), child: child),
    );
  }
}

/// Onboarding: hero cars, headline, three selling points, Get Started.
/// Everything animates in on first open (staggered).
class GettingStartedScreen extends StatefulWidget {
  const GettingStartedScreen({super.key});

  @override
  State<GettingStartedScreen> createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));

  @override
  void initState() {
    super.initState();
    // small delay so it starts after the splash fade finishes
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _next(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginSignUpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF12306B), AppColors.bg, AppColors.bg],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                // Fill the screen when there's room; scroll when there isn't (never overflows).
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
                        child: Row(
                          children: [
                            _Reveal(
                              anim: _anim,
                              start: 0,
                              end: 0.3,
                              from: const Offset(0, -0.4),
                              child: Image.asset('assets/images/logoonly-white.png', height: 28),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _next(context),
                              child: Text('Skip', style: AppText.label.copyWith(color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _HeroCars(width: MediaQuery.of(context).size.width, anim: _anim),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Reveal(
                              anim: _anim,
                              start: 0.40,
                              end: 0.65,
                              child: const StatusChip('Car rental made simple', color: AppColors.primaryLight),
                            ),
                            const SizedBox(height: 14),
                            _Reveal(
                              anim: _anim,
                              start: 0.45,
                              end: 0.72,
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text('Experience driving\nlike never before', style: AppText.display),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _Reveal(
                              anim: _anim,
                              start: 0.52,
                              end: 0.78,
                              child: Text('Choose from 30 cars across 6 categories and book in under a minute.',
                                  style: AppText.body.copyWith(fontSize: 15)),
                            ),
                            const SizedBox(height: 20),
                            _Reveal(
                              anim: _anim,
                              start: 0.58,
                              end: 0.84,
                              from: const Offset(-0.15, 0),
                              child: const _Point(Icons.verified_user_rounded, 'Fully insured, verified vehicles'),
                            ),
                            _Reveal(
                              anim: _anim,
                              start: 0.63,
                              end: 0.89,
                              from: const Offset(-0.15, 0),
                              child: const _Point(Icons.event_available_rounded, 'Free cancellation before pick-up'),
                            ),
                            _Reveal(
                              anim: _anim,
                              start: 0.68,
                              end: 0.94,
                              from: const Offset(-0.15, 0),
                              child: const _Point(Icons.payments_rounded, 'Pay with Cash, GCash or Card'),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: _Reveal(
                          anim: _anim,
                          start: 0.75,
                          end: 1.0,
                          from: const Offset(0, 0.6),
                          child: AppButton(
                            label: 'Get Started',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () => _next(context),
                          ),
                        ),
                      ),
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

/// The two hero cars. Both photos are cropped on one side, so each is pinned
/// to the screen edge on its cropped side: the red Ferrari (cropped rear) on
/// the left, the silver G-Wagon (cropped side) on the right. They face each other.
class _HeroCars extends StatelessWidget {
  const _HeroCars({required this.width, required this.anim});
  final double width;
  final Animation<double> anim;

  // Trimmed image sizes (px) — used to keep the aspect ratio exact.
  static const _gwagonRatio = 244 / 299; // height / width
  static const _ferrariRatio = 172 / 373;

  @override
  Widget build(BuildContext context) {
    final gw = width * 0.60; // G-Wagon width
    final gh = gw * _gwagonRatio;
    final fw = width * 0.74; // Ferrari width (in front, a bit bigger)
    final fh = fw * _ferrariRatio;
    final height = gh + fh * 0.45;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // soft glow behind the cars
          Positioned(
            left: width * 0.15,
            right: width * 0.15,
            top: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: const Interval(0.1, 0.6, curve: Curves.easeOut)),
              child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.fade(0.32), AppColors.primary.fade(0)],
                ),
              ),
            ),
            ),
          ),
          // Silver G-Wagon: right edge, back row
          Positioned(
            right: 0,
            top: 0,
            width: gw,
            height: gh,
            child: _Reveal(
              anim: anim,
              start: 0.05,
              end: 0.5,
              from: const Offset(0.6, 0), // glides in from the right
              child: Image.asset('assets/images/onboard-gwagon.png',
                  fit: BoxFit.contain, alignment: Alignment.centerRight),
            ),
          ),
          // Red Ferrari: left edge, front row
          Positioned(
            left: 0,
            bottom: 0,
            width: fw,
            height: fh,
            child: _Reveal(
              anim: anim,
              start: 0.18,
              end: 0.62,
              from: const Offset(-0.7, 0), // drives in from the left
              child: Image.asset('assets/images/onboard-ferrari.png',
                  fit: BoxFit.contain, alignment: Alignment.centerLeft),
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          IconBadge(icon, size: 32, color: AppColors.primaryLight),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.bodyStrong.copyWith(color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
