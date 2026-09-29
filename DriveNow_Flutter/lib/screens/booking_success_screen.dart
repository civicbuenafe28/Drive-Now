import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/purchase.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'main_shell.dart';

class BookingSuccessScreen extends StatefulWidget {
  const BookingSuccessScreen({super.key, required this.booking});
  final CarBooking booking;

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _goTo(int tab) {
    MainShell.tab.value = tab;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final method = PaymentMethod.fromLabel(b.paymentMethod);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(1);
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              Center(
                child: ScaleTransition(
                  scale: CurvedAnimation(parent: _anim, curve: Curves.elasticOut),
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.fade(0.15),
                      border: Border.all(color: AppColors.success.fade(0.4), width: 2),
                    ),
                    child: const Icon(Icons.check_rounded, color: AppColors.success, size: 60),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Booking confirmed!', textAlign: TextAlign.center, style: AppText.h1),
              const SizedBox(height: 8),
              Text(
                method == PaymentMethod.cash
                    ? 'Your ${b.carName} is reserved. Please pay ${peso(b.totalCost)} in cash at pick-up.'
                    : 'Payment received. Your ${b.carName} is reserved and ready for you.',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
              const SizedBox(height: 16),
              Center(child: StatusChip('Ref: ${b.reference}', color: AppColors.primaryLight, large: true)),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 96,
                          height: 60,
                          child: Image.asset(b.imagePath, fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(b.carName, style: AppText.h3)),
                      ],
                    ),
                    const Divider(color: AppColors.border, height: 24),
                    KeyValueRow('Pick-up', dateTimeShort(b.pickUpDate)),
                    KeyValueRow('Return', dateTimeShort(b.returnDate)),
                    KeyValueRow('Duration', plural(b.rentalDays, 'day')),
                    KeyValueRow('Location', b.location),
                    KeyValueRow('Payment', method == PaymentMethod.cash ? 'Cash at pick-up' : b.paymentMethod),
                    if (b.transactionId != null) KeyValueRow('Transaction ID', b.transactionId!),
                    const Divider(color: AppColors.border, height: 24),
                    KeyValueRow('Total', peso(b.totalCost),
                        labelStyle: AppText.h3, valueStyle: AppText.h2.copyWith(color: AppColors.primaryLight)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const InfoBanner(
                icon: Icons.badge_rounded,
                message: "Bring your driver's license and one valid ID when you pick up the car.",
              ),
              const SizedBox(height: 28),
              AppButton(label: 'View My Rentals', icon: Icons.receipt_long_rounded, onPressed: () => _goTo(1)),
              const SizedBox(height: 12),
              AppButton(label: 'Back to Home', variant: ButtonVariant.outline, onPressed: () => _goTo(0)),
            ],
          ),
        ),
      ),
    );
  }
}
