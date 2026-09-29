import 'package:flutter/material.dart';

import '../services/app_data.dart';
import '../services/auth_service.dart';
import '../services/credential_store.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'login_signup_screen.dart';

/// Permanently deletes the account: shows what will be lost, requires
/// acknowledgement + password, wipes cloud + local data, then signs out.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _password = TextEditingController();
  bool _understood = false;
  bool _busy = false;
  String? _reason;
  String? _error;
  bool _wrongPassword = false;

  static const _reasons = [
    "I don't use it anymore",
    'Found another service',
    'Privacy concerns',
    'Too expensive',
    'Other',
  ];

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  bool get _canDelete => _understood && _password.text.isNotEmpty && !_busy;

  Future<void> _delete() async {
    FocusScope.of(context).unfocus();
    final sure = await showAppDialog(
      context,
      icon: Icons.delete_forever_rounded,
      destructive: true,
      title: 'Delete account permanently?',
      message: 'This is your last chance. Your account and all data will be erased and cannot be recovered.',
      confirmLabel: 'Delete forever',
      cancelLabel: 'Go back',
    );
    if (!sure || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
      _wrongPassword = false;
    });
    final data = AppData.instance;
    try {
      await AuthService.instance.deleteAccount(
        _password.text,
        beforeDelete: data.deleteRemoteData, // cloud data first, while still signed in
      );
      await data.deleteLocalDataForCurrentUser();
      await CredentialStore.instance.clear();
      if (_reason != null) debugPrint('Account deleted. Reason: $_reason');
      if (!mounted) return;
      await showAppDialog(
        context,
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        title: 'Account deleted',
        message: "Your account and data have been permanently removed. We're sorry to see you go.",
        confirmLabel: 'OK',
        dismissible: false,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginSignUpScreen()),
        (_) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      final lower = e.message.toLowerCase();
      setState(() {
        if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential' ||
            lower.contains('malformed') ||
            lower.contains('expired')) {
          _wrongPassword = true;
          _password.clear();
        } else {
          _error = AuthService.messageFor(e);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Deletion failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = AppData.instance;
    final upcoming = data.activeTrips;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Delete account'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  const Center(child: IconBadge(Icons.warning_amber_rounded, color: AppColors.danger, size: 72)),
                  const SizedBox(height: 16),
                  const Text("We're sorry to see you go", textAlign: TextAlign.center, style: AppText.h2),
                  const SizedBox(height: 6),
                  Text('Deleting your account is permanent and cannot be undone.',
                      textAlign: TextAlign.center, style: AppText.body),
                  const SizedBox(height: 22),
                  SettingsGroup(title: 'What will be deleted', children: [
                    SettingsTile(
                        icon: Icons.person_rounded,
                        color: AppColors.danger,
                        title: 'Profile & photo',
                        subtitle: '${data.fullName} · ${data.email}'),
                    SettingsTile(
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.danger,
                        title: plural(data.bookings.length, 'booking'),
                        subtitle: 'All rental records'),
                    SettingsTile(
                        icon: Icons.payments_rounded,
                        color: AppColors.danger,
                        title: plural(data.purchases.length, 'transaction'),
                        subtitle: 'Your payment history'),
                    SettingsTile(
                        icon: Icons.favorite_rounded,
                        color: AppColors.danger,
                        title: plural(data.favorites.length, 'favorite'),
                        subtitle: 'Saved cars'),
                  ]),
                  if (upcoming > 0) ...[
                    const SizedBox(height: 16),
                    InfoBanner(
                      icon: Icons.event_busy_rounded,
                      color: AppColors.warning,
                      title: 'You have ${plural(upcoming, 'active or upcoming rental')}',
                      message: 'These will be cancelled when your account is deleted.',
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text('Why are you leaving? (optional)', style: AppText.label),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in _reasons)
                        ChoiceChip(
                          label: Text(r),
                          selected: _reason == r,
                          onSelected: (sel) => setState(() => _reason = sel ? r : null),
                          labelStyle: TextStyle(
                              color: _reason == r ? Colors.white : AppColors.textSecondary, fontSize: 12.5),
                          selectedColor: AppColors.danger.fade(0.25),
                          backgroundColor: AppColors.surfaceHigh,
                          side: BorderSide(color: _reason == r ? AppColors.danger : AppColors.border),
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    InfoBanner(message: _error!, icon: Icons.error_outline_rounded, color: AppColors.danger),
                    const SizedBox(height: 16),
                  ],
                  AppTextField(
                    controller: _password,
                    label: 'Confirm with your password',
                    hint: 'Enter your password',
                    icon: Icons.lock_outline_rounded,
                    password: true,
                    onChanged: (_) => setState(() => _wrongPassword = false),
                  ),
                  if (_wrongPassword)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 4),
                      child: Text('The password you entered is incorrect.',
                          style: TextStyle(color: AppColors.danger, fontSize: 12)),
                    ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: () => setState(() => _understood = !_understood),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _understood,
                              activeColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.textMuted, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              onChanged: (v) => setState(() => _understood = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'I understand that my account, bookings and payment history will be permanently deleted.',
                              style: AppText.label,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Delete my account',
                    icon: Icons.delete_forever_rounded,
                    variant: ButtonVariant.danger,
                    loading: _busy,
                    onPressed: _canDelete ? _delete : null,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Keep my account',
                    variant: ButtonVariant.ghost,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
