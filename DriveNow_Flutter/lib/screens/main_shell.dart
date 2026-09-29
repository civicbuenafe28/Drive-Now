import 'package:flutter/material.dart';

import '../services/app_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'home_screen.dart';
import 'my_rentals_screen.dart';
import 'profile_screen.dart';

/// Home / My Rentals / Profile with a floating pill navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Lets other screens switch tabs (e.g. "Browse cars" in My Rentals).
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    MainShell.tab.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MainShell.tab,
      builder: (context, index, _) => PopScope(
        canPop: index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) MainShell.tab.value = 0;
        },
        child: Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: index,
            children: const [HomeScreen(), MyRentalsScreen(), ProfileScreen()],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              height: 68,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh.fade(0.97),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.fade(0.45), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: ListenableBuilder(
                listenable: AppData.instance,
                builder: (context, _) => Row(
                  children: [
                    _NavItem(
                        icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', index: 0, selected: index),
                    _NavItem(
                      icon: Icons.receipt_long_outlined,
                      activeIcon: Icons.receipt_long_rounded,
                      label: 'My Rentals',
                      index: 1,
                      selected: index,
                      badge: AppData.instance.activeTrips,
                    ),
                    _NavItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Profile',
                        index: 2,
                        selected: index),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selected,
    this.badge = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selected;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final active = index == selected;
    return Expanded(
      flex: active ? 5 : 3,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => MainShell.tab.value = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: active ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: badge > 0 && !active,
                label: Text('$badge', style: const TextStyle(fontSize: 10)),
                backgroundColor: AppColors.danger,
                child: Icon(active ? activeIcon : icon, color: active ? Colors.white : AppColors.textMuted, size: 24),
              ),
              if (active) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
