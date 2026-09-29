import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_data.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'legal.dart';
import 'login_screen.dart';

/// Validates a PH mobile number entered after "+63" (10 digits, starts with 9).
String? validatePhMobile(String? v, {bool required = true}) {
  final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return required ? 'Mobile number is required' : null;
  if (digits.length != 10 || !digits.startsWith('9')) return 'Enter a valid mobile number, e.g. 917 123 4567';
  return null;
}

String? validateFullName(String? v) {
  final value = (v ?? '').trim();
  if (value.isEmpty) return 'Full name is required';
  if (value.length < 3) return 'Name is too short';
  if (!value.contains(' ')) return 'Please enter your first and last name';
  if (RegExp(r'[0-9]').hasMatch(value)) return 'Name cannot contain numbers';
  return null;
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agreed = false;
  bool _showTermsError = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _showTermsError = !_agreed;
    });
    final valid = _form.currentState!.validate();
    if (!valid || !_agreed) return;

    setState(() => _busy = true);
    final email = _email.text.trim();
    final name = _name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final phone = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    try {
      final auth = AuthService.instance;
      await auth.signUp(name, email, _password.text, dateLong(DateTime.now()));
      await AppData.instance.seedProfile(email: email, fullName: name, phone: phone);
      await auth.signOut(); // user logs in with the new credentials
      if (!mounted) return;
      await showAppDialog(
        context,
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        title: 'Account created!',
        message: 'Welcome to DriveNow, ${name.split(' ').first}. Log in with your new account to start booking.',
        confirmLabel: 'Continue to Log In',
        dismissible: false,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen(prefillEmail: email)),
      );
    } on AuthException catch (e) {
      setState(() => _error = AuthService.messageFor(e));
    } catch (e) {
      setState(() => _error = 'Sign up failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Create account'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                child: Form(
                  key: _form,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Join DriveNow', style: AppText.h1),
                        const SizedBox(height: 6),
                        Text('Create your account in less than a minute.', style: AppText.body),
                        const SizedBox(height: 24),
                        if (_error != null) ...[
                          InfoBanner(message: _error!, icon: Icons.error_outline_rounded, color: AppColors.danger),
                          const SizedBox(height: 18),
                        ],
                        AppTextField(
                          controller: _name,
                          label: 'Full name',
                          hint: 'Juan Dela Cruz',
                          icon: Icons.person_outline_rounded,
                          capitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          validator: validateFullName,
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          controller: _email,
                          label: 'Email address',
                          hint: 'you@example.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: validateEmail,
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          controller: _phone,
                          label: 'Mobile number',
                          hint: '917 123 4567',
                          icon: Icons.phone_iphone_rounded,
                          prefixText: '+63  ',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                          autofillHints: const [AutofillHints.telephoneNumberNational],
                          validator: validatePhMobile,
                          helper: "We'll use this to confirm your bookings.",
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          controller: _password,
                          label: 'Password',
                          hint: 'Create a strong password',
                          icon: Icons.lock_outline_rounded,
                          password: true,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final p = v ?? '';
                            if (p.isEmpty) return 'Password is required';
                            if (!PasswordRules.allMet(p)) return 'Password does not meet all requirements';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        PasswordStrength(password: _password.text),
                        const SizedBox(height: 18),
                        AppTextField(
                          controller: _confirm,
                          label: 'Confirm password',
                          hint: 'Re-enter your password',
                          icon: Icons.lock_outline_rounded,
                          password: true,
                          textInputAction: TextInputAction.done,
                          validator: (v) {
                            if ((v ?? '').isEmpty) return 'Please confirm your password';
                            if (v != _password.text) return 'Passwords do not match';
                            return null;
                          },
                          onSubmitted: (_) => _signUp(),
                        ),
                        const SizedBox(height: 20),
                        _TermsCheckbox(
                          value: _agreed,
                          showError: _showTermsError && !_agreed,
                          onChanged: (v) => setState(() {
                            _agreed = v;
                            if (v) _showTermsError = false;
                          }),
                        ),
                        const SizedBox(height: 24),
                        AppButton(label: 'Create Account', loading: _busy, onPressed: _busy ? null : _signUp),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('Already have an account?', style: AppText.body),
                            TextButton(
                              onPressed: () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              ),
                              child: Text('Log in',
                                  style: AppText.bodyStrong
                                      .copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged, required this.showError});
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final link = AppText.label.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                activeColor: AppColors.primary,
                side: BorderSide(color: showError ? AppColors.danger : AppColors.textMuted, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                onChanged: (v) => onChanged(v ?? false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => onChanged(!value),
                    child: Text('I agree to the ', style: AppText.label),
                  ),
                  GestureDetector(
                    onTap: () => showLegalSheet(context, LegalDoc.terms),
                    child: Text('Terms of Service', style: link),
                  ),
                  Text(' and ', style: AppText.label),
                  GestureDetector(
                    onTap: () => showLegalSheet(context, LegalDoc.privacy),
                    child: Text('Privacy Policy', style: link),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(left: 34, top: 6),
            child: Text('Please accept the terms to continue',
                style: TextStyle(color: AppColors.danger, fontSize: 12)),
          ),
      ],
    );
  }
}
