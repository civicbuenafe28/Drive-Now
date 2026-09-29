import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets/ui.dart';
import 'payment_receipt.dart';

/// Card brand from the first digits.
String cardBrand(String digits) {
  if (digits.startsWith('4')) return 'VISA';
  if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(digits)) return 'Mastercard';
  if (digits.startsWith('35')) return 'JCB';
  return '';
}

/// Luhn checksum — catches most typos in card numbers.
bool luhnValid(String digits) {
  if (digits.length != 16) return false;
  var sum = 0;
  for (var i = 0; i < digits.length; i++) {
    var d = int.parse(digits[digits.length - 1 - i]);
    if (i.isOdd) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
  }
  return sum % 10 == 0;
}

/// Simulated card payment. Pops with the transaction id on success.
class CreditCardPaymentScreen extends StatefulWidget {
  const CreditCardPaymentScreen({super.key, required this.amount, required this.carName});
  final String amount;
  final String carName;

  @override
  State<CreditCardPaymentScreen> createState() => _CreditCardPaymentScreenState();
}

class _CreditCardPaymentScreenState extends State<CreditCardPaymentScreen> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _name = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _cvvFocus = FocusNode();
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _cvvFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  String get _digits => _number.text.replaceAll(' ', '');

  String? _validateNumber(String? v) {
    final d = (v ?? '').replaceAll(' ', '');
    if (d.isEmpty) return 'Card number is required';
    if (d.length != 16) return 'Card number must be 16 digits';
    if (cardBrand(d).isEmpty) return 'We accept Visa, Mastercard and JCB';
    if (!luhnValid(d)) return 'This card number looks incorrect';
    return null;
  }

  String? _validateExpiry(String? v) {
    final value = v ?? '';
    if (value.length != 5) return 'Use MM/YY';
    final month = int.tryParse(value.substring(0, 2)) ?? 0;
    final year = 2000 + (int.tryParse(value.substring(3)) ?? 0);
    if (month < 1 || month > 12) return 'Invalid month';
    final now = DateTime.now();
    final lastDay = DateTime(year, month + 1, 0, 23, 59);
    if (lastDay.isBefore(now)) return 'Card has expired';
    if (year > now.year + 20) return 'Invalid year';
    return null;
  }

  Future<void> _pay() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final txn = 'CC${1000000 + Random().nextInt(9000000)}';
    setState(() => _processing = false);
    await showPaymentReceipt(
      context,
      amount: widget.amount,
      carName: widget.carName,
      method: '${cardBrand(_digits)} card',
      account: '•••• ${_digits.substring(12)}',
      transactionId: txn,
    );
    if (mounted) Navigator.of(context).pop(txn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              title: 'Card payment',
              subtitle: 'Pay ${widget.amount}',
              backIcon: Icons.close_rounded,
              onBack: _processing ? () {} : null,
            ),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    _CardPreview(
                      number: _number.text,
                      name: _name.text,
                      expiry: _expiry.text,
                      showBack: _cvvFocus.hasFocus,
                      cvv: _cvv.text,
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      controller: _number,
                      label: 'Card number',
                      hint: '1234 5678 9012 3456',
                      icon: Icons.credit_card_rounded,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        _CardNumberFormatter(),
                      ],
                      autofillHints: const [AutofillHints.creditCardNumber],
                      onChanged: (_) => setState(() {}),
                      validator: _validateNumber,
                      suffix: cardBrand(_digits).isEmpty
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Center(
                                widthFactor: 1,
                                child: Text(cardBrand(_digits),
                                    style: AppText.label.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _name,
                      label: 'Cardholder name',
                      hint: 'As shown on card',
                      icon: Icons.person_outline_rounded,
                      capitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.creditCardName],
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (v ?? '').trim().length < 3 ? 'Enter the name on the card' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _expiry,
                            label: 'Expiry',
                            hint: 'MM/YY',
                            icon: Icons.date_range_rounded,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              _ExpiryFormatter(),
                            ],
                            onChanged: (_) => setState(() {}),
                            validator: _validateExpiry,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AppTextField(
                            controller: _cvv,
                            focusNode: _cvvFocus,
                            label: 'CVV',
                            hint: '123',
                            icon: Icons.password_rounded,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _pay(),
                            validator: (v) => (v ?? '').length != 3 ? '3 digits' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: _processing ? 'Processing payment...' : 'Pay ${widget.amount}',
                      icon: Icons.lock_rounded,
                      loading: _processing,
                      onPressed: _processing ? null : _pay,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('Simulated payment · no real card is charged',
                              textAlign: TextAlign.center, style: AppText.caption),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Test card: 4242 4242 4242 4242', textAlign: TextAlign.center, style: AppText.caption),
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

class _CardPreview extends StatelessWidget {
  const _CardPreview({
    required this.number,
    required this.name,
    required this.expiry,
    required this.showBack,
    required this.cvv,
  });

  final String number;
  final String name;
  final String expiry;
  final bool showBack;
  final String cvv;

  @override
  Widget build(BuildContext context) {
    final digits = number.replaceAll(' ', '');
    final masked = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i > 0 && i % 4 == 0) masked.write('  ');
      masked.write(i < digits.length ? digits[i] : '•');
    }
    final brand = cardBrand(digits);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: AspectRatio(
        key: ValueKey(showBack),
        aspectRatio: 1.586,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.cardTop, AppColors.cardBottom],
            ),
            boxShadow: [BoxShadow(color: AppColors.primary.fade(0.35), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: showBack
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 10),
                    Container(height: 40, color: Colors.black.fade(0.7)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: Container(height: 36, color: Colors.white.fade(0.85))),
                        Container(
                          width: 64,
                          height: 36,
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: Text(cvv.isEmpty ? 'CVV' : cvv,
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, letterSpacing: 2)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(brand, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: const LinearGradient(colors: [Color(0xFFE8C872), Color(0xFFB8913A)]),
                          ),
                        ),
                        const Spacer(),
                        Text(brand.isEmpty ? 'DriveNow Pay' : brand,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(masked.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 21, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CARDHOLDER', style: TextStyle(color: Colors.white.fade(0.6), fontSize: 10)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(name.isEmpty ? 'YOUR NAME' : name.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('EXPIRES', style: TextStyle(color: Colors.white.fade(0.6), fontSize: 10)),
                            Text(expiry.isEmpty ? 'MM/YY' : expiry,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// "1234567812345678" -> "1234 5678 1234 5678"
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// "1227" -> "12/27"
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    final text = digits.length <= 2 ? digits : '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
