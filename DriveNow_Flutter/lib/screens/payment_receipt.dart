import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';

/// Shows the "Payment successful" receipt sheet. Resolves when the user taps Done.
Future<void> showPaymentReceipt(
  BuildContext context, {
  required String amount,
  required String carName,
  required String method,
  required String account,
  required String transactionId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.fade(0.15),
              border: Border.all(color: AppColors.success.fade(0.4), width: 2),
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('Payment successful', style: AppText.h2),
          const SizedBox(height: 4),
          Text(amount, style: AppText.display.copyWith(color: AppColors.success)),
          const SizedBox(height: 18),
          AppCard(
            color: AppColors.surfaceHigh,
            child: Column(
              children: [
                KeyValueRow('Paid for', carName),
                KeyValueRow('Method', method),
                KeyValueRow('Account', account),
                KeyValueRow('Date', dateTimeShort(DateTime.now())),
                const Divider(color: AppColors.border, height: 20),
                KeyValueRow('Transaction ID', transactionId,
                    valueStyle: AppText.bodyStrong.copyWith(letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton(label: 'Done', onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    ),
  );
}
