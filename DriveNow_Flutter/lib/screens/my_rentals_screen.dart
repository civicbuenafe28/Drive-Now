import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'main_shell.dart';
import 'rental_details_screen.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  int _tab = 0; // 0 upcoming, 1 active, 2 past

  static const _tabs = ['Upcoming', 'Active', 'Past'];

  List<CarBooking> _filter(List<CarBooking> all, int tab) => switch (tab) {
        0 => all.where((b) => b.status == 'Upcoming').toList()
          ..sort((a, b) => a.pickUpDate.compareTo(b.pickUpDate)),
        1 => all.where((b) => b.status == 'Active').toList(),
        _ => all.where((b) => b.isPast).toList(),
      };

  @override
  Widget build(BuildContext context) {
    final data = AppData.instance;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: data,
          builder: (context, _) {
            final all = data.bookingsNewestFirst;
            final list = _filter(all, _tab);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    children: [
                      const Expanded(child: Text('My Rentals', style: AppText.h1)),
                      if (all.isNotEmpty) StatusChip(plural(all.length, 'booking'), color: AppColors.primaryLight),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < _tabs.length; i++)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _tab = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: _tab == i ? AppColors.primaryGradient : null,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_tabs[i],
                                        style: TextStyle(
                                            color: _tab == i ? Colors.white : AppColors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 6),
                                    Text('${_filter(all, i).length}',
                                        style: TextStyle(
                                            color: _tab == i ? Colors.white70 : AppColors.textMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? _empty(all.isEmpty)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _BookingCard(booking: list[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _empty(bool noBookingsAtAll) {
    if (noBookingsAtAll) {
      return EmptyState(
        icon: Icons.directions_car_filled_rounded,
        title: 'No rentals yet',
        message: 'Ready to hit the road? Explore our fleet and book your first ride.',
        actionLabel: 'Browse cars',
        onAction: () => MainShell.tab.value = 0,
      );
    }
    return switch (_tab) {
      0 => const EmptyState(
          icon: Icons.schedule_rounded,
          title: 'No upcoming trips',
          message: 'Bookings you make will show up here until pick-up day.'),
      1 => const EmptyState(
          icon: Icons.directions_car_rounded,
          title: 'No active rentals',
          message: 'Rentals appear here from pick-up until you return the car.'),
      _ => const EmptyState(
          icon: Icons.history_rounded,
          title: 'No past rentals',
          message: 'Completed and cancelled bookings will be listed here.'),
    };
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final CarBooking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final dim = b.status == 'Cancelled';
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RentalDetailsScreen(booking: b)),
      ),
      child: Opacity(
        opacity: dim ? 0.7 : 1,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 104,
                  height: 72,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppColors.carStageGradient,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Image.asset(b.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.directions_car_rounded, color: AppColors.textMuted, size: 36)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(b.carName,
                                style: AppText.h3.copyWith(fontSize: 15)),
                          ),
                          const SizedBox(width: 6),
                          StatusChip(b.status, color: b.statusColor, icon: CarBooking.statusIconFor(b.status)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text('${monthDay(b.pickUpDate)} → ${monthDay(b.returnDate)} · ${plural(b.rentalDays, 'day')}',
                                style: AppText.caption),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(b.location, style: AppText.caption),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 20),
            Row(
              children: [
                Text(b.reference, style: AppText.caption.copyWith(letterSpacing: 0.5)),
                const Spacer(),
                Text(peso(b.totalCost),
                    style: AppText.price.copyWith(
                        fontSize: 15, decoration: dim ? TextDecoration.lineThrough : null, color: AppColors.text)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
