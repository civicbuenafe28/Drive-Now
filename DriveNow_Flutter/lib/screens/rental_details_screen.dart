import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/booking.dart';
import '../models/purchase.dart';
import '../services/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'legal.dart';

class RentalDetailsScreen extends StatelessWidget {
  const RentalDetailsScreen({super.key, required this.booking});
  final CarBooking booking;

  int get _seed {
    var h = 0;
    for (final u in booking.id.codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    return h;
  }

  // "Random but consistent per booking" owner info, as in the iOS app.
  String get _ownerName {
    const first = ['Maria', 'Juan', 'Jose', 'Ana', 'Carlos', 'Elena', 'Miguel', 'Sofia', 'Roberto', 'Carmen', 'Luis', 'Isabella', 'Diego', 'Gabriela', 'Antonio'];
    const last = ['Santos', 'Reyes', 'Cruz', 'Bautista', 'Garcia', 'Gonzales', 'Ramos', 'Flores', 'Mendoza', 'Torres', 'Rivera', 'Morales', 'Aquino', 'Dela Cruz', 'Villanueva'];
    final s = _seed;
    return '${first[s % first.length]} ${last[(s ~/ first.length) % last.length]}';
  }

  String get _contactNumber {
    const prefixes = ['0917', '0918', '0919', '0920', '0921', '0922', '0923', '0924', '0925', '0926', '0927', '0928', '0929', '0939', '0949', '0998', '0999'];
    final s = _seed;
    final suffix = ((s % 9000000) + 1000000).toString().padLeft(7, '0');
    return '${prefixes[s % prefixes.length]} ${suffix.substring(0, 3)} ${suffix.substring(3)}';
  }

  Future<void> _cancel(BuildContext context) async {
    final paidOnline = booking.paymentMethod != 'Cash';
    final confirmed = await showAppDialog(
      context,
      icon: Icons.event_busy_rounded,
      destructive: true,
      title: 'Cancel this booking?',
      message: paidOnline
          ? 'Your ${booking.carName} booking will be cancelled and ${peso(booking.totalCost)} will be refunded '
              'to your ${booking.paymentMethod} within 3–5 business days.'
          : 'Your ${booking.carName} booking will be cancelled. No payment was collected.',
      confirmLabel: 'Yes, cancel',
      cancelLabel: 'Keep booking',
    );
    if (!confirmed || !context.mounted) return;
    await AppData.instance.cancelBooking(booking);
    if (!context.mounted) return;
    showAppSnack(context, paidOnline ? 'Booking cancelled · refund on the way' : 'Booking cancelled',
        type: SnackType.success);
  }

  @override
  Widget build(BuildContext context) {
    final data = AppData.instance;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: data,
          builder: (context, _) {
            final b = booking;
            final status = b.status;
            final purchase = data.purchaseFor(b);
            final method = PaymentMethod.fromLabel(b.paymentMethod);
            return Column(
              children: [
                TopBar(title: 'Rental details', subtitle: b.reference),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: [
                      // Hero card
                      AppCard(
                        gradient: AppColors.carStageGradient,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(height: 130, child: Image.asset(b.imagePath, fit: BoxFit.contain)),
                            const SizedBox(height: 10),
                            Text(b.carName, textAlign: TextAlign.center, style: AppText.h2),
                            const SizedBox(height: 10),
                            StatusChip(status,
                                color: b.statusColor, icon: CarBooking.statusIconFor(status), large: true),
                            if (status == 'Upcoming') ...[
                              const SizedBox(height: 10),
                              Text(_countdown(b.pickUpDate), style: AppText.caption),
                            ],
                          ],
                        ),
                      ),
                      const SectionTitle('Trip', padding: EdgeInsets.fromLTRB(0, 22, 0, 10)),
                      AppCard(
                        child: Column(
                          children: [
                            _TimelineRow(
                              icon: Icons.login_rounded,
                              color: AppColors.success,
                              title: 'Pick-up',
                              value: dateTimeShort(b.pickUpDate),
                              showLine: true,
                            ),
                            _TimelineRow(
                              icon: Icons.logout_rounded,
                              color: AppColors.warning,
                              title: 'Return',
                              value: dateTimeShort(b.returnDate),
                            ),
                            const Divider(color: AppColors.border, height: 24),
                            Row(
                              children: [
                                const IconBadge(Icons.location_on_rounded, color: AppColors.danger, size: 36),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Pick-up location', style: AppText.caption),
                                      Text(b.location, style: AppText.bodyStrong),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SectionTitle('Car owner', padding: EdgeInsets.fromLTRB(0, 22, 0, 10)),
                      AppCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.success.fade(0.2),
                              child: Text(_ownerName.split(' ').map((p) => p[0]).take(2).join(),
                                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_ownerName, style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w600)),
                                  Text(_contactNumber, style: AppText.caption),
                                ],
                              ),
                            ),
                            CircleIconButton(
                              icon: Icons.copy_rounded,
                              tooltip: 'Copy number',
                              size: 40,
                              iconSize: 18,
                              onTap: () async {
                                await Clipboard.setData(ClipboardData(text: _contactNumber.replaceAll(' ', '')));
                                if (context.mounted) showAppSnack(context, 'Contact number copied');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SectionTitle('Payment', padding: EdgeInsets.fromLTRB(0, 22, 0, 10)),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Method + status header
                            Row(
                              children: [
                                IconBadge(method.icon, color: method.color, size: 44),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(method == PaymentMethod.cash ? 'Cash at pick-up' : b.paymentMethod,
                                          style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w600)),
                                      if (b.transactionId != null)
                                        Text('Transaction ID · ${b.transactionId}', style: AppText.caption),
                                    ],
                                  ),
                                ),
                                if (purchase != null) ...[
                                  const SizedBox(width: 8),
                                  StatusChip(purchase.status, color: purchase.statusColor),
                                ],
                              ],
                            ),
                            const Divider(color: AppColors.border, height: 28),
                            KeyValueRow('Daily rate', b.pricePerDay),
                            KeyValueRow('Rental duration', plural(b.rentalDays, 'day')),
                            const KeyValueRow('Insurance', 'Included',
                                valueStyle: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                            const Divider(color: AppColors.border, height: 24),
                            KeyValueRow('Total', peso(b.totalCost),
                                labelStyle: AppText.h3,
                                valueStyle: AppText.h2.copyWith(color: AppColors.primaryLight)),
                            const Divider(color: AppColors.border, height: 24),
                            KeyValueRow('Booked on', dateTimeShort(b.createdAt),
                                labelStyle: AppText.caption, valueStyle: AppText.caption),
                            if (b.cancelledAt != null)
                              KeyValueRow('Cancelled on', dateTimeShort(b.cancelledAt!),
                                  labelStyle: AppText.caption,
                                  valueStyle: AppText.caption.copyWith(color: AppColors.danger)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (b.canBeCancelled) ...[
                        AppButton(
                          label: 'Cancel booking',
                          variant: ButtonVariant.outline,
                          icon: Icons.close_rounded,
                          onPressed: () => _cancel(context),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () => showLegalSheet(context, LegalDoc.cancellation),
                            child: Text('Free cancellation until pick-up · View policy',
                                style: AppText.caption.copyWith(color: AppColors.primaryLight)),
                          ),
                        ),
                      ] else if (status == 'Active')
                        const InfoBanner(
                          icon: Icons.support_agent_rounded,
                          message: 'This rental is in progress. To end it early or report a problem, '
                              'please contact the car owner.',
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _countdown(DateTime pickUp) {
    final diff = pickUp.difference(DateTime.now());
    if (diff.inDays >= 1) return 'Pick-up in ${plural(diff.inDays, 'day')}';
    if (diff.inHours >= 1) return 'Pick-up in ${plural(diff.inHours, 'hour')}';
    return 'Pick-up in ${plural(diff.inMinutes.clamp(1, 59).toInt(), 'minute')}';
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.showLine = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              IconBadge(icon, color: color, size: 36),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? 18 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.caption),
                  Text(value, style: AppText.bodyStrong),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
