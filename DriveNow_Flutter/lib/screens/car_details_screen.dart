import 'package:flutter/material.dart';

import '../models/car.dart';
import '../theme.dart';
import '../widgets/car_widgets.dart';
import '../widgets/ui.dart';
import 'booking_screen.dart';
import 'legal.dart';

class CarDetailsScreen extends StatelessWidget {
  const CarDetailsScreen({super.key, required this.car});
  final Car car;

  @override
  Widget build(BuildContext context) {
    final spec = car.specifications;
    final similar = CarCatalog.cars.where((c) => c.category == car.category && c.id != car.id).toList();

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _stage(context)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusChip(car.category, color: AppColors.primaryLight, icon: categoryIcon(car.category)),
                          StatusChip(car.priceTier, color: AppColors.star),
                          if (car.isPremium)
                            const StatusChip('Premium', color: AppColors.success, icon: Icons.verified_rounded),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(car.name, style: AppText.h1),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          StarRating(rating: car.rating, size: 18),
                          const SizedBox(width: 8),
                          Text('${car.clampedRating.toStringAsFixed(1)} rating', style: AppText.label),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: SpecTile(icon: Icons.event_seat_rounded, label: 'Seats', value: '${spec.seats}')),
                          const SizedBox(width: 10),
                          Expanded(
                              child: SpecTile(
                                  icon: Icons.settings_rounded, label: 'Transmission', value: spec.transmission)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: SpecTile(
                                  icon: Icons.local_gas_station_rounded, label: 'Fuel', value: spec.fuelType)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: SpecTile(icon: Icons.calendar_month_rounded, label: 'Model', value: spec.modelYear)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('About this car', style: AppText.h3),
                      const SizedBox(height: 8),
                      Text(car.description, style: AppText.body),
                      const SizedBox(height: 24),
                      const Text('Features', style: AppText.h3),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final f in car.features)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text(f, style: AppText.label.copyWith(color: AppColors.text))),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Good to know', style: AppText.h3),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Column(
                          children: [
                            _knowRow(Icons.event_available_rounded, AppColors.success, 'Free cancellation',
                                'Cancel any time before pick-up', () => showLegalSheet(context, LegalDoc.cancellation)),
                            _knowRow(Icons.shield_rounded, AppColors.info, 'Insured vehicle',
                                'Comprehensive insurance included', null),
                            _knowRow(Icons.badge_rounded, AppColors.warning, "Driver's license required",
                                'Bring a valid license and ID at pick-up', null),
                            _knowRow(Icons.eco_rounded, AppColors.primaryLight, 'Fuel efficiency',
                                _fuelEfficiency(spec.fuelType), null),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (similar.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SectionTitle('Similar cars', padding: EdgeInsets.fromLTRB(20, 28, 20, 12))),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 216,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: similar.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => CarFeaturedCard(car: similar[i], width: 250),
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 130)),
            ],
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _bottomBar(context)),
        ],
      ),
    );
  }

  static String _fuelEfficiency(String fuel) => switch (fuel) {
        'Hybrid' => 'Excellent · 35+ km/L',
        'Gasoline' => 'Good · 12–15 km/L',
        'Petrol' => 'Good · 10–14 km/L',
        'Diesel' => 'Very good · 15–20 km/L',
        _ => 'Standard',
      };

  Widget _knowRow(IconData icon, Color color, String title, String subtitle, VoidCallback? onTap) {
    return SettingsTile(icon: icon, color: color, title: title, subtitle: subtitle, onTap: onTap);
  }

  Widget _stage(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      height: 300 + top,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, 0.2),
          radius: 0.9,
          colors: [Color(0xFF24488F), AppColors.bg],
        ),
      ),
      child: Stack(
        children: [
          // floor shadow
          Positioned(
            left: 60,
            right: 60,
            bottom: 14,
            height: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [BoxShadow(color: Colors.black.fade(0.5), blurRadius: 24, spreadRadius: 2)],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 18,
            height: 210,
            child: Image.asset(car.imagePath, fit: BoxFit.contain),
          ),
          Positioned(
            top: top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text('Car details', textAlign: TextAlign.center, style: AppText.h3),
                ),
                FavoriteButton(car: car, size: 44, onDark: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: Colors.black.fade(0.4), blurRadius: 20, offset: const Offset(0, -4))],
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
                  Text('Price', style: AppText.caption),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(car.pricePerDay, style: AppText.h1.copyWith(fontSize: 22)),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(' /day', style: AppText.caption),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: AppButton(
              label: 'Book Now',
              icon: Icons.event_available_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BookingScreen(car: car)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
