import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/ui.dart';

enum LegalDoc { terms, privacy, cancellation }

const _content = <LegalDoc, (String, List<(String, String)>)>{
  LegalDoc.terms: (
    'Terms of Service',
    [
      ('Eligibility', 'Renters must be at least 21 years old and hold a valid, non-expired driver\'s license.'),
      ('Bookings', 'A booking is confirmed once payment is completed or, for cash, once the booking is placed. '
          'Please bring your license and a valid ID at pick-up.'),
      ('Vehicle use', 'Vehicles must not be used for racing, towing beyond rated capacity, or any illegal activity. '
          'Smoking inside the vehicle is not allowed.'),
      ('Fuel & returns', 'Return the vehicle with the same fuel level and on the agreed return date and time. '
          'Late returns may be charged an extra day.'),
      ('Damage', 'All vehicles are insured. The renter is responsible for the deductible in case of damage '
          'caused by negligence.'),
    ]
  ),
  LegalDoc.privacy: (
    'Privacy Policy',
    [
      ('What we collect', 'Your name, email, mobile number, driver\'s license number, bookings and favorites.'),
      ('How we use it', 'Only to manage your account and bookings and to contact you about your rentals.'),
      ('Storage', 'Data is stored securely in the cloud (Firebase) or, in offline mode, only on your phone.'),
      ('Your control', 'You can edit your profile at any time and permanently delete your account and all data '
          'from Profile › Delete account.'),
    ]
  ),
  LegalDoc.cancellation: (
    'Cancellation Policy',
    [
      ('Free cancellation', 'Cancel any time before your pick-up date and time at no cost.'),
      ('Refunds', 'GCash and card payments are refunded in full to the original payment method within 3–5 '
          'business days. Cash bookings are simply cancelled.'),
      ('After pick-up', 'Active rentals can no longer be cancelled in the app. Please contact the car owner.'),
    ]
  ),
};

Future<void> showLegalSheet(BuildContext context, LegalDoc doc) {
  final (title, sections) = _content[doc]!;
  return showAppSheet<void>(
    context,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Text(title, style: AppText.h2),
          const SizedBox(height: 4),
          Text('Last updated September 2026', style: AppText.caption),
          const SizedBox(height: 16),
          for (final (heading, body) in sections) ...[
            Text(heading, style: AppText.h3),
            const SizedBox(height: 4),
            Text(body, style: AppText.body),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 8),
          AppButton(label: 'Close', variant: ButtonVariant.secondary, onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    ),
  );
}
