import 'package:flutter/material.dart';

import '../services/app_data.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'delete_account_screen.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'legal.dart';
import 'login_signup_screen.dart';
import 'main_shell.dart';
import 'profile_photo.dart';
import 'security_privacy_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggingOut = false;

  void _open(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  Future<void> _logout() async {
    final yes = await showAppDialog(
      context,
      icon: Icons.logout_rounded,
      title: 'Log out?',
      message: "You'll need to log in again to see your bookings.",
      confirmLabel: 'Log out',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (!yes || !mounted) return;
    setState(() => _loggingOut = true);
    await Future.delayed(const Duration(milliseconds: 1600));
    await AuthService.instance.signOut();
    AppData.instance.clearInMemory();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginSignUpScreen()),
      (_) => false,
    );
  }

  void _showHelp() {
    showAppSheet<void>(
      context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          const Text('Help & FAQ', style: AppText.h2),
          const SizedBox(height: 16),
          for (final (q, a) in const [
            ('How do I book a car?', 'Open a car, tap Book Now, choose your dates, pick-up location and payment method, then confirm.'),
            ('Can I cancel?', 'Yes — upcoming bookings can be cancelled for free from My Rentals › booking › Cancel booking.'),
            ('What do I bring at pick-up?', "Your driver's license, one valid ID, and cash if you chose Cash payment."),
            ('Why must I complete my profile?', "We need your mobile number and driver's license to confirm a rental."),
            ('How do I change my password?', 'Go to Profile › Change password.'),
          ]) ...[
            Text(q, style: AppText.h3),
            const SizedBox(height: 4),
            Text(a, style: AppText.body),
            const SizedBox(height: 14),
          ],
          AppButton(label: 'Close', variant: ButtonVariant.secondary, onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = AppData.instance;
    final offline = !AuthService.instance.firebaseEnabled;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListenableBuilder(
              listenable: data,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                children: [
                  const Text('Profile', style: AppText.h1),
                  const SizedBox(height: 18),

                  // Header card
                  AppCard(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E3F85), Color(0xFF102657)],
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: EditableAvatar(size: 92)),
                        const SizedBox(height: 14),
                        // Full name: centered, full width, wraps if long (never cut off)
                        Text(
                          data.fullName,
                          textAlign: TextAlign.center,
                          style: AppText.h2.copyWith(fontSize: 20, height: 1.25),
                        ),
                        const SizedBox(height: 4),
                        // Email: long addresses shrink to fit on one line
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mail_outline_rounded, size: 15, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(data.email, style: AppText.body.copyWith(fontSize: 13.5)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: StatusChip('Member since ${data.joinedDate}',
                              color: AppColors.primaryLight, icon: Icons.calendar_month_rounded),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: AppButton(
                            label: 'Edit profile',
                            icon: Icons.edit_rounded,
                            variant: ButtonVariant.outline,
                            expand: false,
                            height: 42,
                            onPressed: () => _open(const EditProfileScreen()),
                          ),
                        ),
                        const Divider(color: Color(0x26FFFFFF), height: 32),
                        Row(
                          children: [
                            _Stat(value: '${data.completedTrips}', label: 'Trips'),
                            _divider(),
                            _Stat(value: '${data.activeTrips}', label: 'Upcoming'),
                            _divider(),
                            _Stat(value: '${data.favorites.length}', label: 'Favorites'),
                            _divider(),
                            _Stat(value: peso(data.totalSpent), label: 'Spent'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (!data.isProfileComplete) ...[
                    const SizedBox(height: 14),
                    AppCard(
                      color: AppColors.warning.fade(0.1),
                      borderColor: AppColors.warning.fade(0.35),
                      padding: const EdgeInsets.all(14),
                      onTap: () => _open(const EditProfileScreen()),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_rounded, color: AppColors.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Complete your profile',
                                    style: AppText.bodyStrong.copyWith(color: AppColors.warning)),
                                Text('Add your ${data.missingProfileItems.join(', ')} to start booking.',
                                    style: AppText.caption.copyWith(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.warning),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 26),
                  SettingsGroup(title: 'Account', children: [
                    SettingsTile(
                      icon: Icons.person_rounded,
                      title: 'Edit profile',
                      subtitle: 'Name, mobile number, driver\'s license',
                      onTap: () => _open(const EditProfileScreen()),
                    ),
                    SettingsTile(
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.success,
                      title: 'Payments & transactions',
                      subtitle: data.purchases.isEmpty ? 'No payments yet' : plural(data.purchases.length, 'transaction'),
                      onTap: () => _open(const TransactionsScreen()),
                    ),
                    SettingsTile(
                      icon: Icons.favorite_rounded,
                      color: AppColors.danger,
                      title: 'Favorites',
                      subtitle: plural(data.favorites.length, 'saved car'),
                      onTap: () => _open(const FavoritesScreen()),
                    ),
                    SettingsTile(
                      icon: Icons.directions_car_rounded,
                      color: AppColors.info,
                      title: 'My rentals',
                      subtitle: plural(data.bookings.length, 'booking'),
                      onTap: () => MainShell.tab.value = 1,
                    ),
                  ]),
                  const SizedBox(height: 22),
                  SettingsGroup(title: 'Security & preferences', children: [
                    SettingsTile(
                      icon: Icons.lock_rounded,
                      color: AppColors.warning,
                      title: 'Change password',
                      subtitle: 'Keep your account secure',
                      onTap: () => _open(const SecurityPrivacyScreen()),
                    ),
                    SettingsTile(
                      icon: Icons.settings_rounded,
                      color: AppColors.primaryLight,
                      title: 'Settings',
                      subtitle: 'Notifications, default payment, data',
                      onTap: () => _open(const SettingsScreen()),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  SettingsGroup(title: 'Support', children: [
                    SettingsTile(
                      icon: Icons.help_rounded,
                      color: AppColors.info,
                      title: 'Help & FAQ',
                      onTap: _showHelp,
                    ),
                    SettingsTile(
                      icon: Icons.description_rounded,
                      color: AppColors.textSecondary,
                      title: 'Terms of Service',
                      onTap: () => showLegalSheet(context, LegalDoc.terms),
                    ),
                    SettingsTile(
                      icon: Icons.privacy_tip_rounded,
                      color: AppColors.textSecondary,
                      title: 'Privacy Policy',
                      onTap: () => showLegalSheet(context, LegalDoc.privacy),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  SettingsGroup(children: [
                    SettingsTile(
                      icon: Icons.delete_forever_rounded,
                      title: 'Delete account',
                      subtitle: 'Permanently remove your account and data',
                      destructive: true,
                      onTap: () => _open(const DeleteAccountScreen()),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Log out',
                    icon: Icons.logout_rounded,
                    variant: ButtonVariant.outline,
                    onPressed: _logout,
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'DriveNow v2.0 · ${offline ? 'Offline mode' : 'Cloud sync on'}',
                      style: AppText.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loggingOut)
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.bg.fade(0.94),
                child: const Center(child: LoadingLogo(message: 'Logging out...')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: Colors.white.fade(0.15));
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppText.h3.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: AppText.caption.copyWith(fontSize: 11))),
        ],
      ),
    );
  }
}
