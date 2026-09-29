import 'package:flutter/material.dart';

import '../services/app_data.dart';
import '../services/auth_service.dart';
import '../services/credential_store.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'login_loading_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.prefillEmail});
  final String? prefillEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _remember = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.text = widget.prefillEmail ?? '';
    _loadSaved();
  }

  /// Fills in the saved email + password if "Remember me" was used before.
  Future<void> _loadSaved() async {
    final saved = await CredentialStore.instance.load();
    if (!mounted || saved == null) return;
    // Don't overwrite a different email passed in (e.g. right after sign-up).
    if (widget.prefillEmail != null &&
        widget.prefillEmail!.trim().toLowerCase() != saved.$1.toLowerCase()) {
      return;
    }
    setState(() {
      _email.text = saved.$1;
      _password.text = saved.$2;
      _remember = true;
    });
  }

  Future<void> _toggleRemember(bool value) async {
    setState(() => _remember = value);
    if (!value) {
      // Unchecking forgets the saved login right away.
      await CredentialStore.instance.clear();
      if (mounted) showAppSnack(context, 'Saved login removed from this phone');
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final auth = AuthService.instance;
      await auth.signIn(_email.text, _password.text);
      if (_remember) {
        await CredentialStore.instance.save(_email.text, _password.text);
      } else {
        await CredentialStore.instance.clear();
      }
      await AppData.instance.loadForCurrentUser();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginLoadingScreen()),
        (_) => false,
      );
    } on AuthException catch (e) {
      setState(() => _error = AuthService.messageFor(e));
    } catch (e) {
      setState(() => _error = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final sentTo = await showAppSheet<String>(
      context,
      builder: (_) => _ResetPasswordSheet(initialEmail: _email.text.trim()),
    );
    if (sentTo != null && mounted) {
      showAppSnack(context, 'Password reset link sent to $sentTo', type: SnackType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(title: ''),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _form,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/images/logoonly-white.png', height: 44),
                        const SizedBox(height: 28),
                        const Text('Welcome back 👋', style: AppText.h1),
                        const SizedBox(height: 6),
                        Text('Log in to manage your bookings and favorites.', style: AppText.body),
                        const SizedBox(height: 28),
                        if (_error != null) ...[
                          InfoBanner(message: _error!, icon: Icons.error_outline_rounded, color: AppColors.danger),
                          const SizedBox(height: 18),
                        ],
                        AppTextField(
                          controller: _email,
                          label: 'Email address',
                          hint: 'you@example.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: validateEmail,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          controller: _password,
                          focusNode: _passwordFocus,
                          label: 'Password',
                          hint: 'Enter your password',
                          icon: Icons.lock_outline_rounded,
                          password: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          validator: (v) => (v ?? '').isEmpty ? 'Password is required' : null,
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _remember,
                                activeColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.textMuted, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                onChanged: (v) => _toggleRemember(v ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _toggleRemember(!_remember),
                                child: Text('Remember me', style: AppText.label),
                              ),
                            ),
                            TextButton(
                              onPressed: _forgotPassword,
                              child: Text('Forgot password?',
                                  style: AppText.label.copyWith(color: AppColors.primaryLight)),
                            ),
                          ],
                        ),
                        if (_remember)
                          Padding(
                            padding: const EdgeInsets.only(left: 32, top: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_rounded, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text('Your email and password will be saved securely on this phone.',
                                      style: AppText.caption.copyWith(fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        AppButton(label: 'Log In', loading: _busy, onPressed: _busy ? null : _login),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text("Don't have an account?", style: AppText.body),
                            TextButton(
                              onPressed: () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const SignUpScreen()),
                              ),
                              child: Text('Sign up',
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

String? validateEmail(String? v) {
  final value = (v ?? '').trim();
  if (value.isEmpty) return 'Email is required';
  if (!AuthService.isValidEmail(value)) return 'Enter a valid email address';
  return null;
}

class _ResetPasswordSheet extends StatefulWidget {
  const _ResetPasswordSheet({required this.initialEmail});
  final String initialEmail;

  @override
  State<_ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<_ResetPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await AuthService.instance.sendPasswordReset(_email.text);
      if (mounted) Navigator.of(context).pop(_email.text.trim());
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = AuthService.messageFor(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBadge(Icons.lock_reset_rounded, size: 52),
            const SizedBox(height: 16),
            const Text('Reset your password', style: AppText.h2),
            const SizedBox(height: 6),
            Text("Enter your account email and we'll send you a link to set a new password.",
                style: AppText.body),
            const SizedBox(height: 20),
            if (_error != null) ...[
              InfoBanner(message: _error!, icon: Icons.error_outline_rounded, color: AppColors.danger),
              const SizedBox(height: 14),
            ],
            AppTextField(
              controller: _email,
              label: 'Email address',
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
            ),
            const SizedBox(height: 20),
            AppButton(label: 'Send reset link', loading: _sending, onPressed: _sending ? null : _send),
          ],
        ),
      ),
    );
  }
}
