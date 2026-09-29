import 'package:flutter/material.dart';

import '../services/app_data.dart';
import '../services/auth_service.dart';
import '../services/credential_store.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// Change password (Firebase re-authentication or local account).
class SecurityPrivacyScreen extends StatefulWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  State<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends State<SecurityPrivacyScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _filled => _current.text.isNotEmpty && _new.text.isNotEmpty && _confirm.text.isNotEmpty;

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;

    setState(() => _processing = true);
    try {
      await AuthService.instance.changePassword(_current.text, _new.text);
      // keep "Remember me" in sync with the new password
      await CredentialStore.instance.updatePasswordIfSaved(AppData.instance.email, _new.text);
      if (!mounted) return;
      _current.clear();
      _new.clear();
      _confirm.clear();
      await showAppDialog(
        context,
        icon: Icons.verified_user_rounded,
        iconColor: AppColors.success,
        title: 'Password updated',
        message: 'Your password has been changed. Use your new password the next time you log in.',
        confirmLabel: 'Done',
      );
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = (e.code == 'wrong-password' || e.code == 'invalid-credential')
          ? 'Your current password is incorrect.'
          : AuthService.messageFor(e));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _sendReset() async {
    final email = AppData.instance.email;
    try {
      await AuthService.instance.sendPasswordReset(email);
      if (mounted) showAppSnack(context, 'Reset link sent to $email', type: SnackType.success);
    } on AuthException catch (e) {
      if (mounted) showAppSnack(context, AuthService.messageFor(e), type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Change password'),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    const InfoBanner(
                      icon: Icons.shield_rounded,
                      message: 'Use a unique password you don\'t use on other apps. '
                          'You\'ll stay logged in on this phone after changing it.',
                    ),
                    const SizedBox(height: 22),
                    if (_error != null) ...[
                      InfoBanner(message: _error!, icon: Icons.error_outline_rounded, color: AppColors.danger),
                      const SizedBox(height: 18),
                    ],
                    AppTextField(
                      controller: _current,
                      label: 'Current password',
                      hint: 'Enter your current password',
                      icon: Icons.lock_outline_rounded,
                      password: true,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (v ?? '').isEmpty ? 'Enter your current password' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _sendReset,
                        child: Text('Forgot current password?',
                            style: AppText.label.copyWith(color: AppColors.primaryLight)),
                      ),
                    ),
                    AppTextField(
                      controller: _new,
                      label: 'New password',
                      hint: 'Create a strong password',
                      icon: Icons.lock_reset_rounded,
                      password: true,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final p = v ?? '';
                        if (!PasswordRules.allMet(p)) return 'Password does not meet all requirements';
                        if (p == _current.text) return 'New password must be different from the current one';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    PasswordStrength(password: _new.text),
                    const SizedBox(height: 18),
                    AppTextField(
                      controller: _confirm,
                      label: 'Confirm new password',
                      hint: 'Re-enter the new password',
                      icon: Icons.lock_outline_rounded,
                      password: true,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _changePassword(),
                      validator: (v) => v != _new.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 28),
                    AppButton(
                      label: 'Update password',
                      loading: _processing,
                      onPressed: _filled && !_processing ? _changePassword : null,
                    ),
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
