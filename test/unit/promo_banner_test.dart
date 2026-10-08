import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:save_bite/features/shared/data/promo_banner_repository.dart';
import 'package:save_bite/features/shared/models/promo_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PromoBanner Model & Repository Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('PromoBanner serializes and deserializes correctly', () {
      const banner = PromoBanner(
        id: 'banner_1',
        badge: '🔥 70% OFF',
        title: 'MEGA DEAL',
        subtitle: 'Great discount',
        ctaText: 'Claim Deal',
        code: 'Code: TEST70',
        iconType: 'flame',
        targetRoute: '/customer/hot-deals',
        themeKey: 'teal',
        bgStartColor: '0xFF09504B',
        bgEndColor: '0xFF0F766E',
        imageUrl: 'assets/images/coffee_cup.jpg',
        logoUrl: 'assets/images/northend_logo.jpg',
      );

      final map = banner.toMap();
      final fromMap = PromoBanner.fromMap(map);

      expect(fromMap.id, 'banner_1');
      expect(fromMap.badge, '🔥 70% OFF');
      expect(fromMap.title, 'MEGA DEAL');
      expect(fromMap.subtitle, 'Great discount');
      expect(fromMap.ctaText, 'Claim Deal');
      expect(fromMap.code, 'Code: TEST70');
      expect(fromMap.iconType, 'flame');
      expect(fromMap.targetRoute, '/customer/hot-deals');
      expect(fromMap.themeKey, 'teal');
      expect(fromMap.bgStartColor, '0xFF09504B');
      expect(fromMap.bgEndColor, '0xFF0F766E');
      expect(fromMap.imageUrl, 'assets/images/coffee_cup.jpg');
      expect(fromMap.logoUrl, 'assets/images/northend_logo.jpg');
      expect(fromMap.startColor.toARGB32(), 0xFF09504B);
    });

    test('PromoBanner copyWith updates specific fields properly', () {
      final defaultBanner = PromoBanner.defaultBanners.first;
      final updated = defaultBanner.copyWith(
        title: 'UPDATED TITLE',
        ctaText: 'Grab Now',
        themeKey: 'yellow',
        bgStartColor: '0xFFB45309',
        bgEndColor: '0xFFD97706',
        imageUrl: 'https://example.com/image.png',
        clearLogoUrl: true,
      );

      expect(updated.title, 'UPDATED TITLE');
      expect(updated.ctaText, 'Grab Now');
      expect(updated.badge, defaultBanner.badge);
      expect(updated.id, defaultBanner.id);
      expect(updated.themeKey, 'yellow');
      expect(updated.bgStartColor, '0xFFB45309');
      expect(updated.bgEndColor, '0xFFD97706');
      expect(updated.imageUrl, 'https://example.com/image.png');
      expect(updated.logoUrl, isNull);
    });

    test('PromoBannerRepository loads default banners initially', () async {
      final repo = PromoBannerRepository();
      final banners = await repo.getBanners();

      expect(banners.length, 3);
      expect(banners[0].id, 'banner_1');
      expect(banners[1].id, 'banner_2');
      expect(banners[2].id, 'banner_3');
    });

    test('PromoBannerRepository updates and persists an individual banner',
        () async {
      final repo = PromoBannerRepository();
      final banners = await repo.getBanners();
      final updatedFirst = banners[0].copyWith(
        title: 'NEW ADMIN PROMO TITLE',
        badge: '⚡ FLASH SALE',
      );

      await repo.updateBanner(updatedFirst);

      final reloaded = await repo.getBanners();
      expect(reloaded[0].title, 'NEW ADMIN PROMO TITLE');
      expect(reloaded[0].badge, '⚡ FLASH SALE');
      expect(reloaded[1].title, banners[1].title);
    });

    test('PromoBannerRepository resets to default banners correctly', () async {
      final repo = PromoBannerRepository();
      final banners = await repo.getBanners();
      await repo.updateBanner(
        banners[0].copyWith(title: 'MODIFIED DEAL'),
      );

      var modified = await repo.getBanners();
      expect(modified[0].title, 'MODIFIED DEAL');

      await repo.resetToDefaults();
      final restored = await repo.getBanners();
      expect(restored[0].title, PromoBanner.defaultBanners[0].title);
    });

    test('Partner Banner submission, approval, and end workflow', () async {
      final repo = PromoBannerRepository();

      // Restaurant submits banner
      const partnerBanner = PromoBanner(
        id: 'banner_partner_1',
        title: 'Special 20% Off Weekend Buffet',
        subtitle: 'Artisanal dishes available in Banasree',
        restaurantId: 'rest_blue_bell',
        restaurantName: 'Blue Bell Café',
        status: 'pending',
      );

      await repo.submitRestaurantBanner(partnerBanner);
      var banners = await repo.getBanners();
      final pending = banners.firstWhere((b) => b.id == 'banner_partner_1');
      expect(pending.isPending, isTrue);
      expect(pending.isApproved, isFalse);
      expect(pending.status, 'pending');

      // Admin approves banner
      await repo.approveBanner('banner_partner_1');
      banners = await repo.getBanners();
      final approved = banners.firstWhere((b) => b.id == 'banner_partner_1');
      expect(approved.isApproved, isTrue);
      expect(approved.status, 'approved');
      expect(approved.startsAt, isNotNull);

      // Admin ends campaign
      await repo.endBanner('banner_partner_1');
      banners = await repo.getBanners();
      final ended = banners.firstWhere((b) => b.id == 'banner_partner_1');
      expect(ended.isEnded, isTrue);
      expect(ended.status, 'ended');
      expect(ended.endsAt, isNotNull);
    });
  });
}
