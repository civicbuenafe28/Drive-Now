import 'package:flutter/material.dart';

import '../theme.dart';

/// Port of PaymentMethodScreen.PaymentMethod
enum PaymentMethod {
  cash('Cash', 'Pay at pick-up', Icons.payments_rounded, AppColors.success),
  gcash('GCash', 'E-wallet · instant', Icons.account_balance_wallet_rounded, AppColors.info),
  creditCard('Credit Card', 'Visa · Mastercard · JCB', Icons.credit_card_rounded, AppColors.warning);

  const PaymentMethod(this.label, this.subtitle, this.icon, this.color);
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  static PaymentMethod fromLabel(String label) => PaymentMethod.values.firstWhere(
        (m) => m.label == label,
        orElse: () => PaymentMethod.cash,
      );
}

/// Port of PurchaseHistoryItem (+ status).
class PurchaseHistoryItem {
  final String id;
  final String paymentMethod;
  final DateTime date;
  final String carName;
  final String totalAmount; // plain number string, e.g. "7500"
  final String transactionID;

  /// "Paid", "Pay at pick-up", "Refunded" or "Cancelled"
  String status;

  PurchaseHistoryItem({
    required this.id,
    required this.paymentMethod,
    required this.date,
    required this.carName,
    required this.totalAmount,
    required this.transactionID,
    String? status,
  }) : status = status ?? (paymentMethod == 'Cash' ? 'Pay at pick-up' : 'Paid');

  int get amount => int.tryParse(totalAmount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  Color get statusColor => switch (status) {
        'Paid' => AppColors.success,
        'Refunded' => AppColors.info,
        'Cancelled' => AppColors.danger,
        _ => AppColors.warning,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'paymentMethod': paymentMethod,
        'date': date.millisecondsSinceEpoch,
        'carName': carName,
        'totalAmount': totalAmount,
        'transactionID': transactionID,
        'status': status,
      };

  factory PurchaseHistoryItem.fromJson(Map<String, dynamic> j) => PurchaseHistoryItem(
        id: j['id'] as String,
        paymentMethod: j['paymentMethod'] as String,
        date: DateTime.fromMillisecondsSinceEpoch((j['date'] as num).toInt()),
        carName: j['carName'] as String,
        totalAmount: j['totalAmount'] as String,
        transactionID: j['transactionID'] as String,
        status: j['status'] as String?,
      );
}
