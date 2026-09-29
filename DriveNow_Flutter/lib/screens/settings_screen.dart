import 'package:flutter/material.dart';

import '../models/purchase.dart';
import '../services/app_data.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'legal.dart';

/// App preferences: notifications, default payment method, data & about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _switch(bool value, ValueChanged<bool> onChanged) => Switch(
        value: value,
        onChanged: onChanged,
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.surfaceHigher),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      );

  Future<void> _chooseDefaultPayment(BuildContext context) async {
    final data = AppData.instance;
    final picked = await showAppSheet<PaymentMethod>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Text('Default payment method', style: AppText.h2),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Text('Pre-selected whenever you book. You can still change it per booking.',
                  style: AppText.caption),
            ),
            for (final m in PaymentMethod.values)
              SettingsTile(
                icon: m.icon,
                color: m.color,
                title: m.label,
                subtitle: m.subtitle,
                trailing: Icon(
                  m == data.defaultPayment ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: m == data.defaultPayment ? AppColors.primary : AppColors.textMuted,
                ),
                onTap: () => Navigator.of(ctx).pop(m),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await data.setPreferences(defaultPayment: picked);
      if (context.mounted) showAppSnack(context, 'Default payment set to ${picked.label}', type: SnackType.success);
    }
  }

  Future<void> _clearHistory(BuildContext context) async {
    final ok = await showAppDialog(
      context,
      icon: Icons.cleaning_services_rounded,
      title: 'Clear rental history?',
      message: 'Completed and cancelled rentals and their payment records will be removed from this device. '
          'Upcoming and active bookings are kept.',
      confirmLabel: 'Clear',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (!ok) return;
    await AppData.instance.clearHistory();
    if (context.mounted) showAppSnack(context, 'Rental history cleared', type: SnackType.success);
  }

  @override
  Widget build(BuildContext context) {
    final data = AppData.instance;
    final cloud = AuthService.instance.firebaseEnabled;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Settings'),
            Expanded(
              child: ListenableBuilder(
                listenable: data,
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    SettingsGroup(title: 'Notifications', children: [
                      SettingsTile(
                        icon: Icons.notifications_active_rounded,
                        title: 'Booking reminders',
                        subtitle: 'Remind me before pick-up and return',
                        trailing: _switch(data.bookingReminders, (v) => data.setPreferences(bookingReminders: v)),
                      ),
                      SettingsTile(
                        icon: Icons.local_offer_rounded,
                        color: AppColors.star,
                        title: 'Deals & promotions',
                        subtitle: 'Discounts and seasonal offers',
                        trailing: _switch(data.promotions, (v) => data.setPreferences(promotions: v)),
                      ),
                    ]),
                    const SizedBox(height: 22),
                    SettingsGroup(title: 'Booking', children: [
                      SettingsTile(
                        icon: data.defaultPayment.icon,
                        color: data.defaultPayment.color,
                        title: 'Default payment method',
                        subtitle: data.defaultPayment.label,
                        onTap: () => _chooseDefaultPayment(context),
                      ),
                      SettingsTile(
                        icon: Icons.policy_rounded,
                        color: AppColors.success,
                        title: 'Cancellation policy',
                        onTap: () => showLegalSheet(context, LegalDoc.cancellation),
                      ),
                    ]),
                    const SizedBox(height: 22),
                    SettingsGroup(title: 'Data', children: [
                      SettingsTile(
                        icon: cloud ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        color: cloud ? AppColors.success : AppColors.textMuted,
                        title: cloud ? 'Cloud sync is on' : 'Offline mode',
                        subtitle: cloud
                            ? 'Bookings and favorites are backed up to your account'
                            : 'Data is saved on this phone only',
                      ),
                      SettingsTile(
                        icon: Icons.cleaning_services_rounded,
                        color: AppColors.warning,
                        title: 'Clear rental history',
                        subtitle: 'Remove past rentals from this device',
                        onTap: () => _clearHistory(context),
                      ),
                    ]),
                    const SizedBox(height: 22),
                    SettingsGroup(title: 'About', children: [
                      const SettingsTile(
                        icon: Icons.info_rounded,
                        color: AppColors.info,
                        title: 'Version',
                        trailing: Text('2.0.0', style: AppText.caption),
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
                    const SizedBox(height: 20),
                    Center(child: Text('©2025 Buenafe Inc. All Rights Reserved', style: AppText.caption)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
