import 'package:flutter/material.dart';

import '../models/purchase.dart';
import '../services/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';

/// Payment history (the "Purchase Log History" from the iOS app).
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = AppData.instance;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: data,
          builder: (context, _) {
            final list = data.purchases;
            final refunded = list.where((p) => p.status == 'Refunded').fold(0, (s, p) => s + p.amount);
            return Column(
              children: [
                const TopBar(title: 'Payments'),
                Expanded(
                  child: list.isEmpty
                      ? const EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: 'No payments yet',
                          message: 'Your booking payments and receipts will appear here.',
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                          children: [
                            AppCard(
                              gradient: AppColors.primaryGradient,
                              borderColor: null,
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Total spent', style: AppText.label.copyWith(color: Colors.white70)),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(peso(data.totalSpent), style: AppText.display.copyWith(fontSize: 28)),
                                        ),
                                        if (refunded > 0)
                                          Text('${peso(refunded)} refunded',
                                              style: AppText.caption.copyWith(color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${list.length}', style: AppText.h1),
                                      Text(list.length == 1 ? 'payment' : 'payments',
                                          style: AppText.caption.copyWith(color: Colors.white70)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SectionTitle('History', padding: EdgeInsets.fromLTRB(0, 22, 0, 10)),
                            for (final p in list) ...[
                              _PaymentRow(purchase: p),
                              const SizedBox(height: 10),
                            ],
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
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.purchase});
  final PurchaseHistoryItem purchase;

  @override
  Widget build(BuildContext context) {
    final method = PaymentMethod.fromLabel(purchase.paymentMethod);
    final crossed = purchase.status == 'Refunded' || purchase.status == 'Cancelled';
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBadge(method.icon, color: method.color, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(purchase.carName,
                    style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${purchase.paymentMethod} · ${dateTimeCompact(purchase.date)}', style: AppText.caption),
                Text('ID ${purchase.transactionID}', style: AppText.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(peso(purchase.amount),
                  style: AppText.price.copyWith(
                    fontSize: 15,
                    decoration: crossed ? TextDecoration.lineThrough : null,
                    color: crossed ? AppColors.textMuted : AppColors.text,
                  )),
              const SizedBox(height: 4),
              StatusChip(purchase.status, color: purchase.statusColor),
            ],
          ),
        ],
      ),
    );
  }
}
