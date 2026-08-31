import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/shared_widgets.dart';

class WeatherCitiesScreen extends StatefulWidget {
  const WeatherCitiesScreen({super.key});
  @override
  State<WeatherCitiesScreen> createState() => _WeatherCitiesScreenState();
}

class _WeatherCitiesScreenState extends State<WeatherCitiesScreen> {
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _favorites = (prefs.getStringList('favorite_cities') ?? []).toSet());
  }

  Future<void> _toggleFavorite(String city) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (!_favorites.add(city)) _favorites.remove(city);
    });
    await prefs.setStringList('favorite_cities', _favorites.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: 'Cities', subtitle: '${_favorites.length} favorite${_favorites.length == 1 ? '' : 's'} saved', showBack: true),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final city = cities[i];
                final isFav = _favorites.contains(city.name);
                return AppCard(
                  onTap: () => Navigator.push(
                    context,
                    animatedRoute(WeatherDetailScreen(city: city, isFavorite: isFav, onToggleFavorite: () => _toggleFavorite(city.name))),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.steelAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(city.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.ink))),
                      if (isFav) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.star, color: AppTheme.forgeAmber, size: 18)),
                      const Icon(Icons.chevron_right, color: Color(0xFFC4CAD6)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherDetailScreen extends StatefulWidget {
  final City city;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  const WeatherDetailScreen({super.key, required this.city, required this.isFavorite, required this.onToggleFavorite});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  LoadState state = LoadState.loading;
  WeatherResult? result;
  String errorMessage = '';
  late bool isFav;

  @override
  void initState() {
    super.initState();
    isFav = widget.isFavorite;
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => state = LoadState.loading);
    try {
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=${widget.city.lat}&longitude=${widget.city.lon}&current_weather=true';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception('Server error (${res.statusCode})');
      final current = jsonDecode(res.body)['current_weather'];
      setState(() {
        result = WeatherResult(current['temperature'].toDouble(), current['windspeed'].toDouble(), weatherLabel(current['weathercode']));
        state = LoadState.success;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        state = LoadState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: widget.city.name, subtitle: 'Live weather', showBack: true),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(state),
                  child: switch (state) {
                    LoadState.loading => const Center(child: CircularProgressIndicator(color: AppTheme.navyPrimary)),
                    LoadState.error => Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.cloud_off, color: AppTheme.errorRed, size: 48),
                        const SizedBox(height: 12),
                        const Text("Couldn't load weather", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.ink)),
                        const SizedBox(height: 4),
                        Text(errorMessage, style: const TextStyle(fontSize: 12, color: AppTheme.slate), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        SizedBox(width: 140, child: AppButton(label: 'Retry', onPressed: _fetch, icon: Icons.refresh)),
                      ]),
                    ),
                    LoadState.success => Column(
                      children: [
                        AppCard(
                          child: Column(
                            children: [
                              Text('${result!.temp.toInt()}°C', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w600, color: AppTheme.ink)),
                              Text(result!.condition, style: const TextStyle(fontSize: 14, color: AppTheme.slate)),
                              const SizedBox(height: 12),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.air, color: AppTheme.steelAccent, size: 16),
                                const SizedBox(width: 6),
                                Text('${result!.wind} km/h wind', style: const TextStyle(fontSize: 12, color: AppTheme.slate)),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: isFav ? 'Saved to Favorites' : 'Save to Favorites',
                          onPressed: () {
                            widget.onToggleFavorite();
                            setState(() => isFav = !isFav);
                          },
                          variant: isFav ? AppButtonVariant.secondary : AppButtonVariant.primary,
                          icon: isFav ? Icons.star : Icons.star_border,
                        ),
                      ],
                    ),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
