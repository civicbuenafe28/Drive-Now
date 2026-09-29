import 'package:flutter/material.dart';

import '../theme.dart';

/// Port of CarBooking.swift (+ cancellation, reference no. and transaction id).
class CarBooking {
  final String id;
  final String carName;
  final String imageName;
  final String pricePerDay;
  final DateTime pickUpDate;
  final DateTime returnDate;
  final String location;
  final DateTime createdAt;
  final String paymentMethod;
  final String? transactionId;
  bool cancelled;
  DateTime? cancelledAt;

  /// Firestore document id (users/{uid}/bookings/{firestoreId}), if synced.
  String? firestoreId;

  CarBooking({
    required this.id,
    required this.carName,
    required this.imageName,
    required this.pricePerDay,
    required this.pickUpDate,
    required this.returnDate,
    required this.location,
    required this.createdAt,
    this.paymentMethod = 'Cash',
    this.transactionId,
    this.cancelled = false,
    this.cancelledAt,
    this.firestoreId,
  });

  String get imagePath => 'assets/images/$imageName.png';

  /// Short booking reference shown to the user, e.g. "DN-482913".
  String get reference {
    final digits = id.replaceAll(RegExp(r'[^0-9]'), '');
    final tail = digits.length >= 6 ? digits.substring(digits.length - 6) : digits.padLeft(6, '0');
    return 'DN-$tail';
  }

  /// Whole calendar days between pick-up and return (minimum 1).
  int get rentalDays {
    final d = calendarDaysBetween(pickUpDate, returnDate);
    return d < 1 ? 1 : d;
  }

  int get pricePerDayValue => int.tryParse(pricePerDay.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  int get totalCost => rentalDays * pricePerDayValue;

  /// "Upcoming", "Active", "Completed" or "Cancelled"
  String get status {
    if (cancelled) return 'Cancelled';
    final now = DateTime.now();
    if (now.isBefore(pickUpDate)) return 'Upcoming';
    if (!now.isAfter(returnDate)) return 'Active';
    return 'Completed';
  }

  bool get isPast => status == 'Completed' || status == 'Cancelled';

  /// Free cancellation any time before pick-up.
  bool get canBeCancelled => status == 'Upcoming';

  Color get statusColor => statusColorFor(status);

  static Color statusColorFor(String status) => switch (status) {
        'Active' => AppColors.success,
        'Upcoming' => AppColors.primaryLight,
        'Cancelled' => AppColors.danger,
        _ => AppColors.textMuted,
      };

  static IconData statusIconFor(String status) => switch (status) {
        'Active' => Icons.directions_car_rounded,
        'Upcoming' => Icons.schedule_rounded,
        'Cancelled' => Icons.cancel_rounded,
        _ => Icons.check_circle_rounded,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'carName': carName,
        'imageName': imageName,
        'pricePerDay': pricePerDay,
        'pickUpDate': pickUpDate.millisecondsSinceEpoch,
        'returnDate': returnDate.millisecondsSinceEpoch,
        'location': location,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'cancelled': cancelled,
        'cancelledAt': cancelledAt?.millisecondsSinceEpoch,
        'firestoreId': firestoreId,
      };

  factory CarBooking.fromJson(Map<String, dynamic> j) => CarBooking(
        id: j['id'] as String,
        carName: j['carName'] as String,
        imageName: j['imageName'] as String,
        pricePerDay: j['pricePerDay'] as String,
        pickUpDate: DateTime.fromMillisecondsSinceEpoch((j['pickUpDate'] as num).toInt()),
        returnDate: DateTime.fromMillisecondsSinceEpoch((j['returnDate'] as num).toInt()),
        location: j['location'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch((j['createdAt'] as num).toInt()),
        paymentMethod: (j['paymentMethod'] as String?) ?? 'Cash',
        transactionId: j['transactionId'] as String?,
        cancelled: (j['cancelled'] as bool?) ?? false,
        cancelledAt: j['cancelledAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((j['cancelledAt'] as num).toInt()),
        firestoreId: j['firestoreId'] as String?,
      );
}

/// Number of calendar days from [a] to [b], ignoring the time of day.
int calendarDaysBetween(DateTime a, DateTime b) {
  final da = DateTime.utc(a.year, a.month, a.day);
  final db = DateTime.utc(b.year, b.month, b.day);
  return db.difference(da).inDays;
}
