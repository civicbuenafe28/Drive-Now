import 'package:flutter/material.dart';

import '../services/app_data.dart';
import '../utils/format.dart';
import '../widgets/car_widgets.dart';
import '../widgets/ui.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = AppData.instance;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: data,
          builder: (context, _) {
            final favs = data.favorites;
            return Column(
              children: [
                TopBar(
                  title: 'Favorites',
                  subtitle: favs.isEmpty ? null : plural(favs.length, 'saved car'),
                ),
                Expanded(
                  child: favs.isEmpty
                      ? EmptyState(
                          icon: Icons.favorite_border_rounded,
                          title: 'No favorites yet',
                          message: 'Tap the heart on any car to save it here for quick access later.',
                          actionLabel: 'Browse cars',
                          onAction: () => Navigator.of(context).pop(),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          child: CarGrid(cars: favs),
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
