import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'profile_photo.dart';
import 'signup_screen.dart' show validateFullName, validatePhMobile;

/// LTO driver's license number, e.g. "N01-23-456789".
final _licensePattern = RegExp(r'^[A-Z][0-9]{2}-[0-9]{2}-[0-9]{6}$');

String? validateLicense(String? v) {
  final value = (v ?? '').trim();
  if (value.isEmpty) return null; // optional until booking
  if (!_licensePattern.hasMatch(value)) return 'Use the LTO format, e.g. N01-23-456789';
  return null;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _data = AppData.instance;
  late final _name = TextEditingController(text: _data.fullName);
  late final _email = TextEditingController(text: _data.email);
  late final _phone = TextEditingController(text: _data.phoneNumber);
  late final _license = TextEditingController(text: _data.licenseInfo);
  late final _city = TextEditingController(text: _data.city);
  late DateTime? _expiry = _data.licenseExpiry;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _license.dispose();
    _city.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _name.text.trim() != _data.fullName ||
      _phone.text != _data.phoneNumber ||
      _license.text.trim() != _data.licenseInfo ||
      _city.text.trim() != _data.city ||
      _expiry != _data.licenseExpiry;

  Future<void> _pickExpiry() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry != null && _expiry!.isAfter(now) ? _expiry! : now.add(const Duration(days: 365)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 11),
      helpText: 'License expiry date',
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) {
      showAppSnack(context, 'Please fix the highlighted fields', type: SnackType.error);
      return;
    }
    if (_license.text.trim().isNotEmpty && _expiry == null) {
      showAppSnack(context, 'Please add your license expiry date', type: SnackType.error);
      return;
    }
    setState(() => _saving = true);
    await _data.saveProfile(
      fullName: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
      phoneNumber: _phone.text,
      licenseInfo: _license.text.trim(),
      licenseExpiry: _expiry,
      city: _city.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    showAppSnack(context, 'Profile updated', type: SnackType.success);
    Navigator.of(context).pop();
  }

  Future<void> _confirmLeave() async {
    final discard = await showAppDialog(
      context,
      icon: Icons.edit_note_rounded,
      iconColor: AppColors.warning,
      title: 'Discard changes?',
      message: "You have unsaved changes. If you leave now they'll be lost.",
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      destructive: true,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _expiry != null && _expiry!.isBefore(DateTime.now());
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              TopBar(title: 'Edit profile', onBack: () => Navigator.of(context).maybePop()),
              Expanded(
                child: Form(
                  key: _form,
                  onChanged: () => setState(() {}),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      const Center(child: EditableAvatar(size: 104)),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () => changeProfilePhoto(context),
                          child: Text('Change photo', style: AppText.label.copyWith(color: AppColors.primaryLight)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('PERSONAL INFORMATION',
                          style: AppText.caption.copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _name,
                        label: 'Full name',
                        icon: Icons.person_outline_rounded,
                        capitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: validateFullName,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _email,
                        label: 'Email address',
                        icon: Icons.mail_outline_rounded,
                        readOnly: true,
                        suffix: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted),
                        helper: 'Your login email can\'t be changed here.',
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _phone,
                        label: 'Mobile number',
                        hint: '917 123 4567',
                        icon: Icons.phone_iphone_rounded,
                        prefixText: '+63  ',
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        validator: (v) => validatePhMobile(v, required: false),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _city,
                        label: 'City (optional)',
                        hint: 'e.g. Lucena City',
                        icon: Icons.location_city_rounded,
                        capitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 28),
                      Text("DRIVER'S LICENSE",
                          style: AppText.caption.copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _license,
                        label: 'License number',
                        hint: 'N01-23-456789',
                        icon: Icons.badge_outlined,
                        capitalization: TextCapitalization.characters,
                        inputFormatters: [_LicenseFormatter()],
                        validator: validateLicense,
                        helper: 'Required to book a car.',
                      ),
                      const SizedBox(height: 16),
                      Text('Expiry date', style: AppText.label),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: _pickExpiry,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: expired ? AppColors.danger : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_rounded, color: AppColors.textMuted, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _expiry == null ? 'Select expiry date' : dateLong(_expiry!),
                                  style: TextStyle(
                                    color: _expiry == null ? AppColors.textMuted : AppColors.text,
                                    fontSize: 15,
                                    fontWeight: _expiry == null ? FontWeight.w400 : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_expiry != null)
                                StatusChip(expired ? 'Expired' : 'Valid',
                                    color: expired ? AppColors.danger : AppColors.success),
                            ],
                          ),
                        ),
                      ),
                      if (expired)
                        const Padding(
                          padding: EdgeInsets.only(top: 6, left: 4),
                          child: Text('This license has expired. Please renew it before booking.',
                              style: TextStyle(color: AppColors.danger, fontSize: 12)),
                        ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Save changes',
                        loading: _saving,
                        onPressed: _dirty && !_saving ? _save : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uppercases and inserts dashes: "n0123456789" -> "N01-23-456789".
class _LicenseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final clipped = raw.length > 11 ? raw.substring(0, 11) : raw;
    final buf = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i == 3 || i == 5) buf.write('-');
      buf.write(clipped[i]);
    }
    final text = buf.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
