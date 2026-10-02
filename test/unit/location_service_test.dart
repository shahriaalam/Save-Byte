import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/services/location_service.dart';

void main() {
  group('LocationService Unit Tests', () {
    late LocationService service;

    setUp(() {
      service = LocationService();
    });

    test('calculateDistanceKm calculates distance between coordinates correctly', () {
      // Dhanmondi (23.7461, 90.3742) to Gulshan (23.7925, 90.4078) is approx 6-7 km
      final dist = service.calculateDistanceKm(23.7461, 90.3742, 23.7925, 90.4078);
      expect(dist, greaterThan(4.0));
      expect(dist, lessThan(10.0));
    });

    test('findNearestDhakaArea maps Banasree coordinates to Banasree', () {
      final result = service.findNearestDhakaArea(23.7644, 90.4328);
      expect(result.area, equals('Banasree'));
      expect(result.distanceKm, lessThan(0.2));
    });

    test('findNearestDhakaArea maps Dhanmondi coordinates to Dhanmondi', () {
      final result = service.findNearestDhakaArea(23.7465, 90.3740);
      expect(result.area, equals('Dhanmondi'));
      expect(result.distanceKm, lessThan(0.5));
    });

    test('findNearestDhakaArea maps Banani coordinates to Banani', () {
      final result = service.findNearestDhakaArea(23.7937, 90.4066);
      expect(result.area, equals('Banani'));
      expect(result.distanceKm, lessThan(0.2));
    });

    test('findNearestDhakaArea maps Gulshan coordinates to Gulshan', () {
      final result = service.findNearestDhakaArea(23.7920, 90.4080);
      expect(result.area, equals('Gulshan'));
      expect(result.distanceKm, lessThan(0.5));
    });

    test('findNearestDhakaArea maps Mirpur coordinates to Mirpur', () {
      final result = service.findNearestDhakaArea(23.8223, 90.3654);
      expect(result.area, equals('Mirpur'));
      expect(result.distanceKm, lessThan(0.2));
    });

    test('findNearestDhakaArea maps Uttara coordinates to Uttara', () {
      final result = service.findNearestDhakaArea(23.8759, 90.3795);
      expect(result.area, equals('Uttara'));
      expect(result.distanceKm, lessThan(0.2));
    });

    test('isWithinDhaka identifies Dhaka coordinates and rejects outside cities', () {
      // Mirpur is within Dhaka
      expect(service.isWithinDhaka(23.8223, 90.3654), isTrue);
      // Dhanmondi is within Dhaka
      expect(service.isWithinDhaka(23.7461, 90.3742), isTrue);
      // Chittagong is outside Dhaka (> 200 km)
      expect(service.isWithinDhaka(22.3453, 91.8154), isFalse);
      // Sylhet is outside Dhaka
      expect(service.isWithinDhaka(24.8949, 91.8687), isFalse);
    });

    test('resolveLocation identifies Chittagong when outside Dhaka', () {
      final result = service.resolveLocation(
        22.3453,
        91.8154,
        detectedCity: 'Chittagong',
        detectedRegion: 'Chittagong',
      );
      expect(result.isInsideDhaka, isFalse);
      expect(result.area, equals('Chittagong'));
      expect(result.city, equals('Chittagong'));
      expect(result.distanceKm, greaterThan(150.0));
    });

    test('resolveLocation identifies Sylhet when outside Dhaka', () {
      final result = service.resolveLocation(
        24.8949,
        91.8687,
        detectedCity: 'Sylhet',
        detectedRegion: 'Sylhet',
      );
      expect(result.isInsideDhaka, isFalse);
      expect(result.area, equals('Sylhet'));
      expect(result.distanceKm, greaterThan(150.0));
    });

    test('getCurrentLocationArea resolves accurately without forcing Dhanmondi', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final result = await service.getCurrentLocationArea();
      expect(result.area, isNotEmpty);
      if (result.isInsideDhaka) {
        expect(result.city, equals('Dhaka'));
      } else {
        expect(result.distanceKm, greaterThan(40.0));
      }
    });
  });
}
