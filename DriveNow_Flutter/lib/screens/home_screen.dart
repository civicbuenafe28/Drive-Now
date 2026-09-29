import 'package:flutter/material.dart';

import '../models/car.dart';
import '../services/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/car_widgets.dart';
import '../widgets/ui.dart';
import 'favorites_screen.dart';
import 'main_shell.dart';

enum SortOption {
  recommended('Recommended'),
  priceLow('Price: Low to High'),
  priceHigh('Price: High to Low'),
  rating('Top Rated');

  const SortOption(this.label);
  final String label;
}

class CarFilters {
  const CarFilters({this.sort = SortOption.recommended, this.maxPrice = maxPriceLimit, this.minSeats = 0});
  final SortOption sort;
  final double maxPrice;
  final int minSeats;

  static const double minPriceLimit = 1900;
  static const double maxPriceLimit = 15000;

  bool get isActive => sort != SortOption.recommended || maxPrice < maxPriceLimit || minSeats > 0;
  int get activeCount =>
      (sort != SortOption.recommended ? 1 : 0) + (maxPrice < maxPriceLimit ? 1 : 0) + (minSeats > 0 ? 1 : 0);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  String _category = 'All';
  CarFilters _filters = const CarFilters();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _browsing => _category == 'All' && _search.text.trim().isEmpty && !_filters.isActive;

  List<Car> get _results {
    final q = _search.text.trim().toLowerCase();
    final list = CarCatalog.cars.where((c) {
      if (_category != 'All' && !c.belongsToCategory(_category)) return false;
      if (q.isNotEmpty &&
          !c.name.toLowerCase().contains(q) &&
          !c.category.toLowerCase().contains(q)) {
        return false;
      }
      if (c.priceAsDouble > _filters.maxPrice) return false;
      if (c.specifications.seats < _filters.minSeats) return false;
      return true;
    }).toList();

    switch (_filters.sort) {
      case SortOption.priceLow:
        list.sort((a, b) => a.priceAsDouble.compareTo(b.priceAsDouble));
      case SortOption.priceHigh:
        list.sort((a, b) => b.priceAsDouble.compareTo(a.priceAsDouble));
      case SortOption.rating:
        list.sort((a, b) {
          final r = b.rating.compareTo(a.rating);
          return r != 0 ? r : a.priceAsDouble.compareTo(b.priceAsDouble);
        });
      case SortOption.recommended:
        break;
    }
    return list;
  }

  List<Car> get _topRated {
    final list = CarCatalog.cars.where((c) => c.rating >= 5).toList()
      ..sort((a, b) => b.priceAsDouble.compareTo(a.priceAsDouble));
    return list.take(8).toList();
  }

  void _resetAll() {
    setState(() {
      _search.clear();
      _category = 'All';
      _filters = const CarFilters();
    });
  }

  Future<void> _openFilters() async {
    final result = await showAppSheet<CarFilters>(
      context,
      builder: (_) => _FilterSheet(initial: _filters),
    );
    if (result != null) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    final cars = _results;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              const SliverToBoxAdapter(child: _Header()),
              SliverToBoxAdapter(child: _searchRow()),
              SliverToBoxAdapter(child: _categories()),
              if (_browsing) ...[
                SliverToBoxAdapter(
                  child: SectionTitle('Top rated',
                      actionLabel: 'See all', onAction: () => setState(() => _filters = const CarFilters(sort: SortOption.rating))),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 216,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _topRated.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => CarFeaturedCard(car: _topRated[i]),
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: SectionTitle(
                  _browsing
                      ? 'All cars'
                      : '${plural(cars.length, 'car')} found${_category == 'All' ? '' : ' in $_category'}',
                  actionLabel: _browsing ? null : 'Clear all',
                  onAction: _resetAll,
                ),
              ),
              if (cars.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 320,
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No cars match',
                      message: 'Try a different search, category or price range.',
                      actionLabel: 'Clear filters',
                      onAction: _resetAll,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverToBoxAdapter(child: CarGrid(cars: cars)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search by name or brand',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                        onPressed: () => setState(_search.clear),
                      ),
                filled: true,
                fillColor: AppColors.surfaceHigh,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Badge(
            isLabelVisible: _filters.isActive,
            label: Text('${_filters.activeCount}'),
            backgroundColor: AppColors.danger,
            child: Material(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Ink(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: _openFilters,
                  child: const Icon(Icons.tune_rounded, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categories() {
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
        itemCount: CarCatalog.homeCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = CarCatalog.homeCategories[i];
          final selected = c == _category;
          final count = c == 'All' ? CarCatalog.cars.length : CarCatalog.cars.where((x) => x.category == c).length;
          return GestureDetector(
            onTap: () => setState(() => _category = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: selected ? AppColors.primaryGradient : null,
                color: selected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: selected ? Colors.transparent : AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(categoryIcon(c), size: 17, color: selected ? Colors.white : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(c,
                      style: TextStyle(
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white.fade(0.25) : AppColors.surfaceHigher,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count',
                        style: TextStyle(
                            color: selected ? Colors.white : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final data = AppData.instance;
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => MainShell.tab.value = 2,
                  child: Avatar(size: 46, bytes: data.profileImage, initials: data.initials),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${greeting()},', style: AppText.caption.copyWith(fontSize: 13)),
                      Text(data.firstName,
                          style: AppText.h3.copyWith(fontSize: 18)),
                    ],
                  ),
                ),
                Badge(
                  isLabelVisible: data.favorites.isNotEmpty,
                  label: Text('${data.favorites.length}'),
                  backgroundColor: AppColors.danger,
                  child: CircleIconButton(
                    icon: Icons.favorite_border_rounded,
                    tooltip: 'Favorites',
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text('Find your perfect ride', style: AppText.display),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final CarFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SortOption _sort = widget.initial.sort;
  late double _maxPrice = widget.initial.maxPrice;
  late int _minSeats = widget.initial.minSeats;

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.fade(0.18) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matching = CarCatalog.cars
        .where((c) => c.priceAsDouble <= _maxPrice && c.specifications.seats >= _minSeats)
        .length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Filter & sort', style: AppText.h2)),
              TextButton(
                onPressed: () => setState(() {
                  _sort = SortOption.recommended;
                  _maxPrice = CarFilters.maxPriceLimit;
                  _minSeats = 0;
                }),
                child: Text('Reset', style: AppText.label.copyWith(color: AppColors.primaryLight)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Sort by', style: AppText.h3),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in SortOption.values) _choice(s.label, _sort == s, () => setState(() => _sort = s)),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: Text('Max price per day', style: AppText.h3)),
              Text(_maxPrice >= CarFilters.maxPriceLimit ? 'Any' : peso(_maxPrice),
                  style: AppText.bodyStrong.copyWith(color: AppColors.primaryLight)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceHigher,
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.fade(0.2),
            ),
            child: Slider(
              value: _maxPrice,
              min: CarFilters.minPriceLimit,
              max: CarFilters.maxPriceLimit,
              divisions: 131,
              onChanged: (v) => setState(() => _maxPrice = (v / 100).round() * 100.0),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(peso(CarFilters.minPriceLimit), style: AppText.caption),
              Text(peso(CarFilters.maxPriceLimit), style: AppText.caption),
            ],
          ),
          const SizedBox(height: 22),
          Text('Seats', style: AppText.h3),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in const [0, 4, 5, 7, 12])
                _choice(s == 0 ? 'Any' : '$s+', _minSeats == s, () => setState(() => _minSeats = s)),
            ],
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'Show $matching ${matching == 1 ? 'car' : 'cars'}',
            onPressed: () => Navigator.of(context).pop(
              CarFilters(sort: _sort, maxPrice: _maxPrice, minSeats: _minSeats),
            ),
          ),
        ],
      ),
    );
  }
}
