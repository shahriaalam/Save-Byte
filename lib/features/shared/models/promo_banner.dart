import 'dart:convert';
import 'package:flutter/material.dart';

/// Promotional hero banner displayed on the customer home screen carousel.
/// Managed exclusively by platform administrators.
class PromoBanner {
  const PromoBanner({
    required this.id,
    this.name,
    this.badge = '',
    this.title = '',
    this.subtitle = '',
    this.ctaText = 'Claim Deal',
    this.code,
    this.iconType = 'food',
    this.targetRoute = '/customer/hot-deals',
    this.themeKey = 'coffee',
    this.bgStartColor = '0xFF3E2723',
    this.bgEndColor = '0xFF5D4037',
    this.imageUrl,
    this.logoUrl,
    this.restaurantId,
    this.restaurantName,
    this.status = 'approved',
    this.rejectionReason,
    this.createdAt,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String? name; // Direct banner name assigned by admin
  final String badge;
  final String title;
  final String subtitle;
  final String ctaText;
  final String? code;
  final String iconType; // 'moped', 'flame', 'gift', 'bolt', 'food'
  final String targetRoute;
  final String themeKey; // 'coffee', 'burgundy', 'teal', 'yellow', 'purple', 'navy', 'charcoal'
  final String bgStartColor;
  final String bgEndColor;
  final String? imageUrl; // Direct banner image (PNG/JPG asset or URL)
  final String? logoUrl; // Brand/Partner logo image (optional)
  final String? restaurantId;
  final String? restaurantName;
  final String status; // 'approved', 'pending', 'rejected', 'ended'
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isEnded => status == 'ended';
  bool get isRejected => status == 'rejected';

  /// Effective banner display name
  String get bannerName {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (title.trim().isNotEmpty) return title.trim();
    return 'Promotional Banner';
  }

  Color get startColor => Color(int.parse(bgStartColor));
  Color get endColor => Color(int.parse(bgEndColor));

  LinearGradient get gradient => LinearGradient(
        colors: [startColor, endColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  PromoBanner copyWith({
    String? id,
    String? name,
    String? badge,
    String? title,
    String? subtitle,
    String? ctaText,
    String? code,
    String? iconType,
    String? targetRoute,
    String? themeKey,
    String? bgStartColor,
    String? bgEndColor,
    String? imageUrl,
    String? logoUrl,
    String? restaurantId,
    String? restaurantName,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? startsAt,
    DateTime? endsAt,
    bool clearImageUrl = false,
    bool clearLogoUrl = false,
    bool clearCode = false,
  }) {
    final effectiveName = name ?? this.name ?? this.title;
    return PromoBanner(
      id: id ?? this.id,
      name: effectiveName,
      badge: badge ?? this.badge,
      title: title ?? (name ?? this.title),
      subtitle: subtitle ?? this.subtitle,
      ctaText: ctaText ?? this.ctaText,
      code: clearCode ? null : (code ?? this.code),
      iconType: iconType ?? this.iconType,
      targetRoute: targetRoute ?? this.targetRoute,
      themeKey: themeKey ?? this.themeKey,
      bgStartColor: bgStartColor ?? this.bgStartColor,
      bgEndColor: bgEndColor ?? this.bgEndColor,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      logoUrl: clearLogoUrl ? null : (logoUrl ?? this.logoUrl),
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name ?? title,
      'badge': badge,
      'title': title.isNotEmpty ? title : (name ?? ''),
      'subtitle': subtitle,
      'ctaText': ctaText,
      'code': code,
      'iconType': iconType,
      'targetRoute': targetRoute,
      'themeKey': themeKey,
      'bgStartColor': bgStartColor,
      'bgEndColor': bgEndColor,
      'imageUrl': imageUrl,
      'logoUrl': logoUrl,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt?.toIso8601String(),
      'startsAt': startsAt?.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
    };
  }

  factory PromoBanner.fromMap(Map<String, dynamic> map) {
    final rawName = (map['name'] as String?) ?? (map['title'] as String?) ?? 'Promotional Banner';
    final rawTitle = (map['title'] as String?) ?? rawName;
    return PromoBanner(
      id: (map['id'] as String?) ?? 'banner_1',
      name: rawName,
      badge: (map['badge'] as String?) ?? rawName,
      title: rawTitle,
      subtitle: (map['subtitle'] as String?) ?? '',
      ctaText: (map['ctaText'] as String?) ?? 'Claim Deal',
      code: map['code'] as String?,
      iconType: (map['iconType'] as String?) ?? 'food',
      targetRoute: (map['targetRoute'] as String?) ?? '/customer/hot-deals',
      themeKey: (map['themeKey'] as String?) ?? 'coffee',
      bgStartColor: (map['bgStartColor'] as String?) ?? '0xFF3E2723',
      bgEndColor: (map['bgEndColor'] as String?) ?? '0xFF5D4037',
      imageUrl: map['imageUrl'] as String?,
      logoUrl: map['logoUrl'] as String?,
      restaurantId: map['restaurantId'] as String?,
      restaurantName: map['restaurantName'] as String?,
      status: (map['status'] as String?) ?? 'approved',
      rejectionReason: map['rejectionReason'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'] as String) : null,
      startsAt: map['startsAt'] != null ? DateTime.tryParse(map['startsAt'] as String) : null,
      endsAt: map['endsAt'] != null ? DateTime.tryParse(map['endsAt'] as String) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PromoBanner.fromJson(String source) =>
      PromoBanner.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Available background themes for Admin selection.
  static const Map<String, ({String name, String start, String end, String emoji})>
      availableThemes = {
    'coffee': (
      name: 'Coffee Roast (North End)',
      start: '0xFF3E2723',
      end: '0xFF5D4037',
      emoji: '☕',
    ),
    'burgundy': (
      name: 'Burgundy (SS 2)',
      start: '0xFF6E001A',
      end: '0xFF8B001F',
      emoji: '🍷',
    ),
    'teal': (
      name: 'Teal Mart (SS 3)',
      start: '0xFF09504B',
      end: '0xFF0F766E',
      emoji: '🥬',
    ),
    'yellow': (
      name: 'Warm Yellow (SS 4)',
      start: '0xFFB45309',
      end: '0xFFD97706',
      emoji: '🧀',
    ),
    'purple': (
      name: 'Royal Purple',
      start: '0xFF581C87',
      end: '0xFF7E22CE',
      emoji: '🍇',
    ),
    'navy': (
      name: 'Ocean Blue',
      start: '0xFF1E3A8A',
      end: '0xFF2563EB',
      emoji: '🌊',
    ),
    'charcoal': (
      name: 'Midnight Black',
      start: '0xFF18181B',
      end: '0xFF27272A',
      emoji: '🖤',
    ),
  };

  /// Initial high-converting promotional banners matching user requirements.
  /// 1st Banner: International Coffee Day North End 10% OFF with BYTE100 coupon.
  static List<PromoBanner> get defaultBanners => const [
        PromoBanner(
          id: 'banner_1',
          name: 'International Coffee Day - North End 10% OFF',
          title: '10% OFF AT NORTH END',
          badge: '☕ INTERNATIONAL COFFEE DAY',
          subtitle: 'Valid across all North End branches on coffee day',
          code: 'Use Code: BYTE100 • 10% OFF',
          ctaText: 'Claim 10% Off',
          iconType: 'food',
          themeKey: 'coffee',
          bgStartColor: '0xFF3E2723',
          bgEndColor: '0xFF5D4037',
          imageUrl: 'assets/images/coffee_day_banner.jpg',
          logoUrl: 'assets/images/northend_logo.jpg',
          targetRoute: '/customer/hot-deals',
        ),
        PromoBanner(
          id: 'banner_2',
          name: 'Fresh Surplus & Groceries',
          title: 'SAVE EXTRA ON BASKETS',
          badge: '🥬 FRESH SURPLUS & GROCERIES',
          subtitle: 'Fresh bakery, fruits & evening surplus drops',
          code: 'Code: SURPLUS50 • Instant Pickup',
          ctaText: 'Explore Mart',
          iconType: 'food',
          themeKey: 'teal',
          bgStartColor: '0xFF09504B',
          bgEndColor: '0xFF0F766E',
          imageUrl: 'assets/images/fresh_surplus_banner.jpg',
          targetRoute: '/customer/hot-deals',
        ),
        PromoBanner(
          id: 'banner_3',
          name: 'Pay Day Special - 55% to 75% OFF',
          title: '55% - 75% OFF FEAST',
          badge: '🎉 PAY DAY SPECIAL',
          subtitle: 'Kacchi Biryani, Burgers & Platters for Everyone',
          code: 'Code: PAYDAY • All Cuisines, Full Happiness',
          ctaText: 'Order Surplus',
          iconType: 'flame',
          themeKey: 'yellow',
          bgStartColor: '0xFFB45309',
          bgEndColor: '0xFFD97706',
          imageUrl: 'assets/images/payday_feast_banner.jpg',
          targetRoute: '/customer/hot-deals',
        ),
      ];
}
