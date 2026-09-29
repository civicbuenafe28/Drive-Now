import 'package:flutter/material.dart';

import '../models/car.dart';
import '../screens/car_details_screen.dart';
import '../services/app_data.dart';
import '../theme.dart';
import 'ui.dart';

IconData categoryIcon(String category) => switch (category) {
      'All' => Icons.apps_rounded,
      'SUV' => Icons.directions_car_filled_rounded,
      'Sedan' => Icons.directions_car_rounded,
      'Pickup' => Icons.local_shipping_rounded,
      'Luxury' => Icons.diamond_rounded,
      'Sports' => Icons.speed_rounded,
      'Van' => Icons.airport_shuttle_rounded,
      _ => Icons.directions_car_rounded,
    };

void openCarDetails(BuildContext context, Car car) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => CarDetailsScreen(car: car)));
}

/// Car photo on the soft "stage" gradient.
class CarStage extends StatelessWidget {
  const CarStage({super.key, required this.car, this.height = 120, this.radius = AppRadius.md, this.padding = 10});
  final Car car;
  final double height;
  final double radius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.carStageGradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: EdgeInsets.all(padding),
      child: Image.asset(
        car.imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.directions_car_rounded, size: 48, color: AppColors.textMuted)),
      ),
    );
  }
}

/// Heart button that toggles a favorite and shows a snackbar.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.car, this.size = 34, this.onDark = true});
  final Car car;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final data = AppData.instance;
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final fav = data.isFavorite(car);
        return Material(
          color: onDark ? Colors.black.fade(0.35) : AppColors.surfaceHigh,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              final added = await data.toggleFavorite(car);
              if (context.mounted) {
                showAppSnack(context, added ? 'Added to favorites' : 'Removed from favorites',
                    type: added ? SnackType.success : SnackType.info);
              }
            },
            child: SizedBox(
              width: size,
              height: size,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Icon(
                  fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  key: ValueKey(fav),
                  color: fav ? AppColors.danger : Colors.white,
                  size: size * 0.55,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Card used in the 2-column grid on Home and Favorites.
class CarGridCard extends StatelessWidget {
  const CarGridCard({super.key, required this.car});
  final Car car;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      radius: AppRadius.lg,
      onTap: () => openCarDetails(context, car),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CarStage(car: car, height: 104),
              Positioned(top: 6, left: 6, child: RatingBadge(rating: car.clampedRating, dark: true)),
              Positioned(top: 4, right: 4, child: FavoriteButton(car: car, size: 30)),
            ],
          ),
          Expanded(
            child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(car.name,
                    style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(categoryIcon(car.category), size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text('${car.category} · ${car.specifications.seats} seats',
                          style: AppText.caption),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(
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
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}

/// Two-column car grid where each row is as tall as its tallest card, so long
/// names wrap onto a second line instead of being cut off or overflowing.
class CarGrid extends StatelessWidget {
  const CarGrid({super.key, required this.cars});
  final List<Car> cars;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < cars.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: CarGridCard(car: cars[i])),
                  const SizedBox(width: 12),
                  Expanded(child: i + 1 < cars.length ? CarGridCard(car: cars[i + 1]) : const SizedBox()),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Wide card for the "Top rated" carousel.
class CarFeaturedCard extends StatelessWidget {
  const CarFeaturedCard({super.key, required this.car, this.width = 270});
  final Car car;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.all(10),
        onTap: () => openCarDetails(context, car),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C3A7A), Color(0xFF0F2350)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Image.asset(car.imagePath, fit: BoxFit.contain),
                ),
                Positioned(top: 0, left: 0, child: StatusChip(car.priceTier, color: AppColors.star)),
                Positioned(top: 0, right: 0, child: FavoriteButton(car: car, size: 30)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(car.name, style: AppText.h3),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.star, size: 15),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text('${car.clampedRating.toStringAsFixed(1)} · ${car.category}',
                                style: AppText.caption),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(car.pricePerDay, style: AppText.price.copyWith(fontSize: 16)),
                    Text('per day', style: AppText.caption),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small tile with an icon, value and label (car specs).
class SpecTile extends StatelessWidget {
  const SpecTile({super.key, required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppText.bodyStrong.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: AppText.caption.copyWith(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
