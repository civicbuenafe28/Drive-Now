import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/car.dart';
import '../models/purchase.dart';
import '../services/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/car_widgets.dart';
import '../widgets/ui.dart';
import 'booking_success_screen.dart';
import 'credit_card_payment_screen.dart';
import 'edit_profile_screen.dart';
import 'gcash_payment_screen.dart';
import 'legal.dart';
import 'location_picker_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.car});
  final Car car;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late DateTime _pickUp;
  late DateTime _return;
  PickedLocation? _location;
  late PaymentMethod _method = AppData.instance.defaultPayment;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Default: tomorrow 10:00 AM -> day after 10:00 AM (1 day)
    final t = DateTime.now().add(const Duration(days: 1));
    _pickUp = DateTime(t.year, t.month, t.day, 10);
    _return = _pickUp.add(const Duration(days: 1));
  }

  int get _days => calendarDaysBetween(_pickUp, _return);
  int get _rate => widget.car.priceAsDouble.toInt();
  int get _total => (_days < 0 ? 0 : _days) * _rate;

  DateTime _withTime(DateTime date, TimeOfDay t) => DateTime(date.year, date.month, date.day, t.hour, t.minute);

  /// Earliest allowed pick-up: now, rounded up to the next 15 minutes.
  DateTime get _earliestPickUp {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day, now.hour);
    return base.add(Duration(minutes: ((now.minute ~/ 15) + 1) * 15));
  }

  /// True when the chosen pick-up time has already passed (1 minute grace).
  bool get _pickUpInPast => _pickUp.isBefore(DateTime.now().subtract(const Duration(minutes: 1)));

  /// If the pick-up time is in the past, move it to the earliest slot and tell the user.
  void _fixPastPickUp({bool notify = true}) {
    if (!_pickUpInPast) return;
    final earliest = _earliestPickUp;
    final keepDays = _days < 1 ? 1 : _days;
    setState(() {
      _pickUp = earliest;
      if (calendarDaysBetween(_pickUp, _return) < keepDays) {
        _return = _withTime(_pickUp.add(Duration(days: keepDays)), TimeOfDay.fromDateTime(_return));
      }
    });
    if (notify && mounted) {
      showAppSnack(
        context,
        'That time has already passed. Pick-up set to ${dayMonth(earliest)}, ${timeShort(earliest)} — the earliest available.',
      );
    }
  }

  Future<void> _chooseDates() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: DateTime(_pickUp.year, _pickUp.month, _pickUp.day).isBefore(today)
            ? today
            : DateTime(_pickUp.year, _pickUp.month, _pickUp.day),
        end: DateTime(_return.year, _return.month, _return.day).isBefore(today)
            ? today.add(const Duration(days: 1))
            : DateTime(_return.year, _return.month, _return.day),
      ),
      helpText: 'Select pick-up and return dates',
      saveText: 'Done',
    );
    if (range == null) return;
    setState(() {
      _pickUp = _withTime(range.start, TimeOfDay.fromDateTime(_pickUp));
      _return = _withTime(range.end, TimeOfDay.fromDateTime(_return));
    });
    if (calendarDaysBetween(range.start, range.end) < 1) {
      if (mounted) {
        showAppSnack(context, 'Return date must be at least 1 day after pick-up', type: SnackType.error);
      }
      return;
    }
    // e.g. picked today but the kept time (10:00 AM) is already over
    _fixPastPickUp();
  }

  Future<void> _chooseTime({required bool pickUp}) async {
    final current = pickUp ? _pickUp : _return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: pickUp ? 'Pick-up time' : 'Return time',
    );
    if (t == null) return;
    setState(() {
      if (pickUp) {
        _pickUp = _withTime(_pickUp, t);
      } else {
        _return = _withTime(_return, t);
      }
    });
    if (pickUp) _fixPastPickUp();
  }

  Future<void> _chooseLocation() async {
    final loc = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => LocationPickerScreen(initial: _location)),
    );
    if (loc != null) setState(() => _location = loc);
  }

  String? _validationError() {
    if (_pickUpInPast) {
      return 'Your pick-up time (${timeShort(_pickUp)}) has already passed. '
          'Choose ${timeShort(_earliestPickUp)} or later.';
    }
    if (_days < 1) return 'Return date must be at least 1 day after pick-up.';
    if (_location == null) return 'Please choose a pick-up location on the map.';
    return null;
  }

  Future<void> _confirm() async {
    final data = AppData.instance;

    if (!data.isProfileComplete) {
      final go = await showAppDialog(
        context,
        icon: Icons.badge_rounded,
        iconColor: AppColors.warning,
        title: 'Complete your profile',
        message: 'Before booking, please add your ${data.missingProfileItems.join(', ')}.',
        confirmLabel: 'Complete profile',
        cancelLabel: 'Later',
      );
      if (go && mounted) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
        if (mounted) setState(() {});
      }
      return;
    }

    final error = _validationError();
    if (error != null) {
      showAppSnack(context, error, type: SnackType.error);
      return;
    }

    final overlap = data.overlappingBooking(widget.car, _pickUp, _return);
    if (overlap != null) {
      final proceed = await showAppDialog(
        context,
        icon: Icons.event_busy_rounded,
        iconColor: AppColors.warning,
        title: 'You already booked this car',
        message: 'Booking ${overlap.reference} for the ${widget.car.name} overlaps these dates '
            '(${monthDay(overlap.pickUpDate)} – ${monthDay(overlap.returnDate)}). Book anyway?',
        confirmLabel: 'Book anyway',
        cancelLabel: 'Change dates',
      );
      if (!proceed) return;
    }
    if (!mounted) return;

    String? transactionId;
    if (_method != PaymentMethod.cash) {
      transactionId = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _method == PaymentMethod.gcash
              ? GCashPaymentScreen(amount: peso(_total), carName: widget.car.name)
              : CreditCardPaymentScreen(amount: peso(_total), carName: widget.car.name),
        ),
      );
      if (transactionId == null) return; // payment cancelled
    }

    setState(() => _saving = true);
    final booking = await data.addBooking(
      car: widget.car,
      pickUpDate: _pickUp,
      returnDate: _return,
      location: _location!.address,
      method: _method,
      totalAmount: _total,
      transactionId: transactionId,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => BookingSuccessScreen(booking: booking)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = AppData.instance;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TopBar(title: 'Book your ride'),
            Expanded(
              child: ListenableBuilder(
                listenable: data,
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    _carSummary(),
                    if (!data.isProfileComplete) ...[
                      const SizedBox(height: 14),
                      AppCard(
                        color: AppColors.warning.fade(0.1),
                        borderColor: AppColors.warning.fade(0.35),
                        padding: const EdgeInsets.all(14),
                        onTap: () async {
                          await Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                          if (mounted) setState(() {});
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.badge_rounded, color: AppColors.warning),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Complete your profile to book',
                                      style: AppText.bodyStrong.copyWith(color: AppColors.warning)),
                                  Text('Add your ${data.missingProfileItems.join(', ')}.',
                                      style: AppText.caption.copyWith(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.warning),
                          ],
                        ),
                      ),
                    ],
                    const SectionTitle('Trip dates', padding: EdgeInsets.fromLTRB(0, 24, 0, 12)),
                    _datesCard(),
                    const SectionTitle('Pick-up location', padding: EdgeInsets.fromLTRB(0, 24, 0, 12)),
                    _locationCard(),
                    const SectionTitle('Payment method', padding: EdgeInsets.fromLTRB(0, 24, 0, 12)),
                    for (final m in PaymentMethod.values) ...[
                      _PaymentOption(method: m, selected: m == _method, onTap: () => setState(() => _method = m)),
                      const SizedBox(height: 10),
                    ],
                    const SectionTitle('Price details', padding: EdgeInsets.fromLTRB(0, 14, 0, 12)),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          KeyValueRow('Daily rate', widget.car.pricePerDay),
                          KeyValueRow('Rental duration', plural(_days < 0 ? 0 : _days, 'day')),
                          KeyValueRow('Subtotal', peso(_total)),
                          const KeyValueRow('Insurance', 'Included',
                              valueStyle: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                          const KeyValueRow('Service fee', '₱0',
                              valueStyle: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                          const Divider(color: AppColors.border, height: 20),
                          KeyValueRow('Total', peso(_total),
                              labelStyle: AppText.h3,
                              valueStyle: AppText.h2.copyWith(color: AppColors.primaryLight)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => showLegalSheet(context, LegalDoc.cancellation),
                      child: const InfoBanner(
                        icon: Icons.event_available_rounded,
                        color: AppColors.success,
                        message: 'Free cancellation until your pick-up time. Tap to read the policy.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _carSummary() {
    final car = widget.car;
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SizedBox(width: 120, child: CarStage(car: car, height: 78, padding: 6)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(car.name, style: AppText.h3),
                const SizedBox(height: 2),
                Text('${car.category} · ${car.specifications.seats} seats · ${car.specifications.transmission}',
                    style: AppText.caption),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(car.pricePerDay, style: AppText.price.copyWith(fontSize: 16)),
                      Text(' /day', style: AppText.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _datesCard() {
    Widget side(String label, DateTime d, bool pickUp) => Expanded(
          child: Column(
            crossAxisAlignment: pickUp ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(label, style: AppText.caption),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _chooseDates,
                child: Text(dayMonth(d), style: AppText.h3),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _chooseTime(pickUp: pickUp),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: AppColors.primaryLight),
                      const SizedBox(width: 5),
                      Text(timeShort(d), style: AppText.label.copyWith(color: AppColors.text)),
                      const SizedBox(width: 2),
                      const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.textMuted),
                    ],
                  ),
                ),
                ),
              ),
            ],
          ),
        );

    final valid = _days >= 1;
    return AppCard(
      onTap: _chooseDates,
      child: Column(
        children: [
          Row(
            children: [
              side('PICK-UP', _pickUp, true),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (valid ? AppColors.primary : AppColors.danger).fade(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(valid ? plural(_days, 'day') : 'Invalid',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: valid ? AppColors.primaryLight : AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted, size: 18),
                ],
              ),
              side('RETURN', _return, false),
            ],
          ),
          const Divider(color: AppColors.border, height: 24),
          Row(
            children: [
              const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Tap to change dates · tap a time to adjust',
                    style: AppText.caption.copyWith(color: AppColors.primaryLight)),
              ),
            ],
          ),
          if (_pickUpInPast) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Pick-up time has already passed.',
                      style: AppText.caption.copyWith(color: AppColors.danger)),
                ),
                TextButton(
                  onPressed: () => _fixPastPickUp(notify: false),
                  child: Text('Use ${timeShort(_earliestPickUp)}',
                      style: AppText.label.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationCard() {
    final has = _location != null;
    return AppCard(
      onTap: _chooseLocation,
      child: Row(
        children: [
          IconBadge(Icons.location_on_rounded, color: has ? AppColors.danger : AppColors.primaryLight, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(has ? 'Pick-up at' : 'Choose pick-up location', style: has ? AppText.caption : AppText.h3),
                const SizedBox(height: 2),
                Text(has ? _location!.address : 'Search or drop a pin on the map',
                    style: has ? AppText.bodyStrong : AppText.caption),
              ],
            ),
          ),
          Text(has ? 'Change' : '', style: AppText.label.copyWith(color: AppColors.primaryLight)),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        // push the button flush to the right edge
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total · ${plural(_days < 0 ? 0 : _days, 'day')}', style: AppText.caption),
                  Text(peso(_total), style: AppText.h1.copyWith(fontSize: 22)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: AppButton(
              label: _method == PaymentMethod.cash ? 'Confirm Booking' : 'Continue to Pay',
              icon: _method == PaymentMethod.cash ? Icons.check_rounded : Icons.lock_rounded,
              expand: true,
              height: 54,
              loading: _saving,
              onPressed: _saving ? null : _confirm,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({required this.method, required this.selected, required this.onTap});
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.fade(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                IconBadge(method.icon, color: method.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(method.label, style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w600)),
                      Text(method.subtitle, style: AppText.caption),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    key: ValueKey(selected),
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
