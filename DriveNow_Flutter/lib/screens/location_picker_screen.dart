import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../theme.dart';
import '../widgets/ui.dart';

class PickedLocation {
  final LatLng point;
  final String address;
  const PickedLocation(this.point, this.address);
}

class _SearchResult {
  final String title;
  final String subtitle;
  final LatLng point;
  const _SearchResult(this.title, this.subtitle, this.point);
}

/// Map location picker (OpenStreetMap, no API key): search a place or tap the map.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});
  final PickedLocation? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _manila = LatLng(14.5995, 120.9842);
  static const _headers = {'User-Agent': 'DriveNow/2.0 (ph.edu.mseuf.drivenow)', 'Accept-Language': 'en'};

  final _map = MapController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  LatLng? _point;
  String _address = '';
  bool _looking = false;
  int _lookupId = 0;
  List<_SearchResult> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _point = widget.initial?.point;
    _address = widget.initial?.address ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ geocoding

  Future<void> _onTap(LatLng p) async {
    _searchFocus.unfocus();
    final id = ++_lookupId;
    setState(() {
      _results = [];
      _point = p;
      _address = '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
      _looking = true;
    });
    final name = await _reverseGeocode(p);
    if (!mounted || id != _lookupId) return;
    setState(() {
      if (name != null) _address = name;
      _looking = false;
    });
  }

  Future<String?> _reverseGeocode(LatLng p) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': p.latitude.toString(),
        'lon': p.longitude.toString(),
        'zoom': '17',
        'addressdetails': '1',
      });
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return _shortAddress(json);
    } catch (_) {
      return null;
    }
  }

  static String? _shortAddress(Map<String, dynamic> json) {
    final a = (json['address'] as Map?)?.cast<String, dynamic>() ?? {};
    final parts = <String>[];
    final name = json['name'] as String?;
    final road = a['road'] as String?;
    final first = (name != null && name.isNotEmpty) ? name : road;
    if (first != null && first.isNotEmpty) parts.add(first);
    final locality =
        (a['city'] ?? a['town'] ?? a['municipality'] ?? a['village'] ?? a['suburb']) as String?;
    if (locality != null && !parts.contains(locality)) parts.add(locality);
    final province = (a['state'] ?? a['region']) as String?;
    if (province != null && !parts.contains(province)) parts.add(province);
    if (parts.isEmpty) return json['display_name'] as String?;
    return parts.join(', ');
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 3) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _runSearch(q.trim()));
  }

  Future<void> _runSearch(String q) async {
    setState(() => _searching = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'q': q,
        'countrycodes': 'ph',
        'limit': '6',
        'addressdetails': '1',
      });
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (!mounted || _search.text.trim() != q) return;
      final list = res.statusCode == 200 ? jsonDecode(res.body) as List : const [];
      setState(() {
        _results = [
          for (final item in list.cast<Map>())
            _SearchResult(
              (item['name'] as String?)?.isNotEmpty == true
                  ? item['name'] as String
                  : (item['display_name'] as String).split(',').first,
              _shortAddress(item.cast<String, dynamic>()) ?? (item['display_name'] as String? ?? ''),
              LatLng(double.parse(item['lat'].toString()), double.parse(item['lon'].toString())),
            ),
        ];
        _searching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectResult(_SearchResult r) {
    _searchFocus.unfocus();
    _map.move(r.point, 16);
    setState(() {
      _point = r.point;
      _address = r.subtitle.isNotEmpty ? r.subtitle : r.title;
      _results = [];
      _search.text = r.title;
    });
  }

  void _zoom(double delta) {
    final cam = _map.camera;
    _map.move(cam.center, (cam.zoom + delta).clamp(3.0, 19.0).toDouble());
  }

  void _done() {
    if (_point == null) return;
    Navigator.of(context).pop(PickedLocation(_point!, _address));
  }

  // ------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _point ?? _manila,
              initialZoom: _point == null ? 12 : 16,
              onTap: (_, p) => _onTap(p),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ph.edu.mseuf.drivenow',
              ),
              if (_point != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _point!,
                    width: 48,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on, color: AppColors.danger, size: 48),
                  ),
                ]),
              RichAttributionWidget(
                attributions: [TextSourceAttribution('OpenStreetMap contributors')],
              ),
            ],
          ),

          // Top: back + search + results
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Close',
                        background: AppColors.surface,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Material(
                          elevation: 6,
                          shadowColor: Colors.black54,
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: TextField(
                            controller: _search,
                            focusNode: _searchFocus,
                            onChanged: _onSearchChanged,
                            onSubmitted: (q) {
                              if (q.trim().length >= 2) _runSearch(q.trim());
                            },
                            textInputAction: TextInputAction.search,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search a place, e.g. SM Lucena',
                              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                              suffixIcon: _searching
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_results.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8, left: 54),
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [BoxShadow(color: Colors.black.fade(0.4), blurRadius: 16)],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (_, i) {
                          final r = _results[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined, color: AppColors.primaryLight),
                            title: Text(r.title,
                                style: AppText.bodyStrong.copyWith(fontSize: 13)),
                            subtitle: Text(r.subtitle,
                                style: AppText.caption),
                            onTap: () => _selectResult(r),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Zoom controls
          Positioned(
            right: 16,
            bottom: 200,
            child: Column(
              children: [
                CircleIconButton(icon: Icons.add_rounded, background: AppColors.surface, onTap: () => _zoom(1)),
                const SizedBox(height: 8),
                CircleIconButton(icon: Icons.remove_rounded, background: AppColors.surface, onTap: () => _zoom(-1)),
              ],
            ),
          ),

          // Bottom card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 16 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                boxShadow: [BoxShadow(color: Colors.black.fade(0.4), blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconBadge(Icons.location_on_rounded,
                          color: _point == null ? AppColors.textMuted : AppColors.danger, size: 44),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_point == null ? 'No location selected' : 'Pick-up location',
                                style: AppText.caption),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (_looking)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: SizedBox(
                                        width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                Expanded(
                                  child: Text(
                                    _point == null ? 'Search above or tap anywhere on the map' : _address,
                                    style: AppText.bodyStrong,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Confirm Location',
                    icon: Icons.check_rounded,
                    onPressed: _point == null || _looking ? null : _done,
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
