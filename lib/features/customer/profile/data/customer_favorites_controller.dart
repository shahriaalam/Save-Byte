import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteRestaurant {
  final String id;
  final String name;
  final String subtitle;
  final String rating;
  final String? imageUrl;

  const FavoriteRestaurant({
    required this.id,
    required this.name,
    required this.subtitle,
    this.rating = '4.8 ★',
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'rating': rating,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

  factory FavoriteRestaurant.fromJson(Map<String, dynamic> json) =>
      FavoriteRestaurant(
        id: json['id'] as String,
        name: json['name'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        rating: json['rating'] as String? ?? '4.8 ★',
        imageUrl: json['imageUrl'] as String?,
      );
}

class CustomerFavoritesController extends Notifier<List<FavoriteRestaurant>> {
  static const _storageKey = 'customer_favorite_restaurants_v2';

  static const List<FavoriteRestaurant> defaultFavorites = [
    FavoriteRestaurant(
      id: 'fav-sultans',
      name: "Sultan's Dine",
      subtitle: 'Dhanmondi • Biryani & Kebabs',
      rating: '4.9 ★',
    ),
    FavoriteRestaurant(
      id: 'fav-chillox',
      name: 'Chillox Burgers',
      subtitle: 'Banani • Gourmet Burgers',
      rating: '4.8 ★',
    ),
    FavoriteRestaurant(
      id: 'fav-secret',
      name: 'Secret Recipe',
      subtitle: 'Gulshan • Cakes & Pastries',
      rating: '4.7 ★',
    ),
  ];

  @override
  List<FavoriteRestaurant> build() {
    _loadFromStorage();
    return defaultFavorites;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((item) =>
                FavoriteRestaurant.fromJson(item as Map<String, dynamic>))
            .toList();
        state = list;
      }
    } catch (_) {}
  }

  Future<void> _persist(List<FavoriteRestaurant> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(list.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  bool isFavorite(String restaurantId) {
    return state.any((fav) => fav.id == restaurantId);
  }

  Future<void> toggleFavorite({
    required String id,
    required String name,
    required String subtitle,
    String rating = '4.8 ★',
    String? imageUrl,
  }) async {
    if (isFavorite(id)) {
      await removeFavorite(id);
    } else {
      await addFavorite(FavoriteRestaurant(
        id: id,
        name: name,
        subtitle: subtitle,
        rating: rating,
        imageUrl: imageUrl,
      ));
    }
  }

  Future<void> addFavorite(FavoriteRestaurant fav) async {
    if (isFavorite(fav.id)) return;
    final updated = [fav, ...state];
    state = updated;
    await _persist(updated);
  }

  Future<void> removeFavorite(String restaurantId) async {
    final updated = state.where((fav) => fav.id != restaurantId).toList();
    state = updated;
    await _persist(updated);
  }
}

final customerFavoritesProvider =
    NotifierProvider<CustomerFavoritesController, List<FavoriteRestaurant>>(
  CustomerFavoritesController.new,
);
