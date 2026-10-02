class FoodPhotoPreset {
  const FoodPhotoPreset({
    required this.name,
    required this.category,
    required this.url,
  });

  final String name;
  final String category;
  final String url;
}

const List<FoodPhotoPreset> kFoodPhotoPresets = [
  FoodPhotoPreset(
    name: 'Biryani / Tehari',
    category: 'Rice',
    url: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&auto=format&fit=crop&q=80',
  ),
  FoodPhotoPreset(
    name: 'Burger & Fries',
    category: 'Burger',
    url: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop&q=80',
  ),
  FoodPhotoPreset(
    name: 'Artisan Pizza',
    category: 'Pizza',
    url: 'https://images.unsplash.com/photo-1604382355076-af4b0eb60143?w=600&auto=format&fit=crop&q=80',
  ),
  FoodPhotoPreset(
    name: 'Bakery Pastries',
    category: 'Bakery',
    url: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600&auto=format&fit=crop&q=80',
  ),
  FoodPhotoPreset(
    name: 'Evening Snacks',
    category: 'Snacks',
    url: 'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?w=600&auto=format&fit=crop&q=80',
  ),
  FoodPhotoPreset(
    name: 'Desserts & Sweets',
    category: 'Dessert',
    url: 'https://images.unsplash.com/photo-1587314168485-3236d6710814?w=600&auto=format&fit=crop&q=80',
  ),
];
