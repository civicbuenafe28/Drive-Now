import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets/ui.dart';
import 'payment_receipt.dart';
import 'signup_screen.dart' show validatePhMobile;

/// Simulated GCash payment. Pops with the transaction id on success.
class GCashPaymentScreen extends StatefulWidget {
  const GCashPaymentScreen({super.key, required this.amount, required this.carName});
  final String amount;
  final String carName;

  @override
  State<GCashPaymentScreen> createState() => _GCashPaymentScreenState();
}

class _GCashPaymentScreenState extends State<GCashPaymentScreen> {
  final _mobileForm = GlobalKey<FormState>();
  final _mobile = TextEditingController();
  final _pin = TextEditingController();
  int _step = 0; // 0 = mobile, 1 = PIN
  bool _processing = false;

  @override
  void dispose() {
    _mobile.dispose();
    _pin.dispose();
    super.dispose();
  }

  String get _mobileDisplay {
    final d = _mobile.text;
    if (d.length != 10) return '+63 $d';
    return '+63 ${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6)}';
  }

  void _continue() {
    if (!_mobileForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = 1);
  }

  Future<void> _pay() async {
    FocusScope.of(context).unfocus();
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final txn = 'GC${100000 + Random().nextInt(900000)}';
    setState(() => _processing = false);
    await showPaymentReceipt(
      context,
      amount: widget.amount,
      carName: widget.carName,
      method: 'GCash',
      account: _mobileDisplay,
      transactionId: txn,
    );
    if (mounted) Navigator.of(context).pop(txn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gcash, Color(0xFF003F8A), AppColors.bg],
            stops: [0, 0.35, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              TopBar(
                title: 'GCash',
                subtitle: 'Secure checkout',
                backIcon: Icons.close_rounded,
                onBack: _processing ? () {} : null,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.fade(0.25), blurRadius: 16)],
                        ),
                        alignment: Alignment.center,
                        child: const Text('G',
                            style: TextStyle(color: AppColors.gcash, fontSize: 44, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Amount due', textAlign: TextAlign.center, style: AppText.label.copyWith(color: Colors.white70)),
                    Text(widget.amount, textAlign: TextAlign.center, style: AppText.display.copyWith(fontSize: 36)),
                    Text(widget.carName, textAlign: TextAlign.center, style: AppText.body.copyWith(color: Colors.white70)),
                    const SizedBox(height: 28),
                    _Steps(step: _step),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _step == 0 ? _mobileStep() : _pinStep(),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('Simulated payment · no real money is charged',
                              textAlign: TextAlign.center, style: AppText.caption),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileStep() {
    return AppCard(
      key: const ValueKey('mobile'),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _mobileForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your GCash number', style: AppText.h3),
            const SizedBox(height: 14),
            AppTextField(
              controller: _mobile,
              hint: '917 123 4567',
              icon: Icons.phone_iphone_rounded,
              prefixText: '+63  ',
              keyboardType: TextInputType.phone,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              validator: validatePhMobile,
              onSubmitted: (_) => _continue(),
            ),
            const SizedBox(height: 18),
            AppButton(label: 'Continue', color: AppColors.gcash, onPressed: _continue),
          ],
        ),
      ),
    );
  }

  Widget _pinStep() {
    final ok = _pin.text.length == 6;
    return AppCard(
      key: const ValueKey('pin'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter your 6-digit MPIN', style: AppText.h3),
          const SizedBox(height: 4),
          Text('Paying from $_mobileDisplay', style: AppText.caption),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: Stack(
              children: [
                // Invisible field on top of the boxes: tapping the boxes focuses it.
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _pin,
                      autofocus: true,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                    ),
                  ),
                ),
                IgnorePointer(child: _PinBoxes(length: _pin.text.length)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: _processing ? 'Processing...' : 'Pay ${widget.amount}',
            color: AppColors.gcash,
            loading: _processing,
            onPressed: ok && !_processing ? _pay : null,
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: _processing
                  ? null
                  : () => setState(() {
                        _step = 0;
                        _pin.clear();
                      }),
              child: Text('Change number', style: AppText.label.copyWith(color: AppColors.primaryLight)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    Widget dot(int i, String label) {
      final done = step > i;
      final active = step == i;
      return Column(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: done || active ? AppColors.gcash : AppColors.surfaceHigher,
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.caption.copyWith(color: active ? Colors.white : AppColors.textMuted)),
        ],
      );
    }

    return Row(
      children: [
        dot(0, 'Mobile'),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 18, left: 8, right: 8),
            color: step > 0 ? AppColors.gcash : AppColors.surfaceHigher,
          ),
        ),
        dot(1, 'MPIN'),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 18, left: 8, right: 8),
            color: AppColors.surfaceHigher,
          ),
        ),
        dot(2, 'Done'),
      ],
    );
  }
}

class _PinBoxes extends StatelessWidget {
  const _PinBoxes({required this.length});
  final int length;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        final filled = i < length;
        final current = i == length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 42,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: current ? AppColors.gcash : (filled ? AppColors.primaryLight : AppColors.border),
              width: current ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: filled
              ? Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
              : null,
        );
      }),
    );
  }
}
