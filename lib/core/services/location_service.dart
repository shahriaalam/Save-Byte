import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/location_constants.dart';

/// Represents the coordinates of a Dhaka area centroid.
class AreaCoordinate {
  const AreaCoordinate(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;
}

/// Result of automatic location detection.
class DetectedLocationResult {
  const DetectedLocationResult({
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.city,
    this.division,
    this.isInsideDhaka = true,
    this.isExactMatch = true,
    this.hasGpsFix = true,
    this.source = 'GPS',
  });

  /// Name of the detected area or city (e.g., 'Mirpur', 'Uttara', 'Dhanmondi', or 'Chittagong' if outside Dhaka).
  final String area;
  final String? city;
  final String? division;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final bool isInsideDhaka;
  final bool isExactMatch;
  final bool hasGpsFix;
  final String source;
}

/// Service handling device geolocation, permission management, reverse geocoding,
/// and mapping device coordinates to the user's real city or nearest Dhaka neighborhood.
class LocationService {
  LocationService();

  static const String keyHasPromptedPermission = 'has_prompted_location_permission';
  static const String keyDetectedArea = 'user_detected_area';
  static const String keyDetectedCity = 'user_detected_city';
  static const String keyDetectedLat = 'user_detected_lat';
  static const String keyDetectedLng = 'user_detected_lng';
  static const String keyIsInsideDhaka = 'user_is_inside_dhaka';

  /// Central coordinate of Greater Dhaka (near Tejgaon / Mohakhali).
  static const double dhakaCenterLat = 23.7800;
  static const double dhakaCenterLng = 90.4000;
  static const double dhakaRadiusKm = 40.0;

  /// Centroid coordinates for Dhaka areas in [LocationConstants.dhakaAreas].
  static const List<AreaCoordinate> dhakaCentroids = [
    AreaCoordinate('Banasree', 23.7644, 90.4328),
    AreaCoordinate('Dhanmondi', 23.7461, 90.3742),
    AreaCoordinate('Gulshan', 23.7925, 90.4078),
    AreaCoordinate('Banani', 23.7937, 90.4066),
    AreaCoordinate('Mirpur', 23.8223, 90.3654),
    AreaCoordinate('Uttara', 23.8759, 90.3795),
    AreaCoordinate('Mohammadpur', 23.7658, 90.3585),
    AreaCoordinate('Badda', 23.7806, 90.4267),
    AreaCoordinate('Motijheel', 23.7330, 90.4172),
    AreaCoordinate('Khilgaon', 23.7540, 90.4240),
    AreaCoordinate('Old Dhaka', 23.7199, 90.3882),
    AreaCoordinate('Bashundhara R/A', 23.8191, 90.4526),
    AreaCoordinate('Tejgaon', 23.7600, 90.3950),
    AreaCoordinate('Mohakhali', 23.7780, 90.4000),
    AreaCoordinate('Malibagh', 23.7470, 90.4160),
    AreaCoordinate('Rampura', 23.7620, 90.4230),
    AreaCoordinate('Lalmatia', 23.7540, 90.3700),
    AreaCoordinate('Baridhara', 23.8030, 90.4190),
    AreaCoordinate('Shahbagh', 23.7380, 90.3960),
    AreaCoordinate('Elephant Road', 23.7410, 90.3850),
    AreaCoordinate('Cantonment', 23.8200, 90.3900),
    AreaCoordinate('Khilkhet', 23.8300, 90.4200),
    AreaCoordinate('Agargaon', 23.7750, 90.3750),
    AreaCoordinate('Shyamoli', 23.7720, 90.3630),
    AreaCoordinate('Basabo', 23.7400, 90.4300),
    AreaCoordinate('Keraniganj', 23.6800, 90.3800),
    AreaCoordinate('Savar', 23.8500, 90.2600),
  ];

  /// Checks whether the user has already been shown the 1st-time location permission prompt.
  Future<bool> hasPromptedPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(keyHasPromptedPermission) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Records that the user was shown the 1st-time location prompt.
  Future<void> markPermissionPromptShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyHasPromptedPermission, true);
    } catch (_) {}
  }

  /// Gets previously detected/saved area if available.
  Future<String?> getSavedDetectedArea() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyDetectedArea);
    } catch (_) {
      return null;
    }
  }

  /// Saves the detected area and parameters to persistent preferences.
  Future<void> saveDetectedLocation({
    required String area,
    required double lat,
    required double lng,
    String? city,
    bool isInsideDhaka = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyDetectedArea, area);
      if (city != null) {
        await prefs.setString(keyDetectedCity, city);
      }
      await prefs.setDouble(keyDetectedLat, lat);
      await prefs.setDouble(keyDetectedLng, lng);
      await prefs.setBool(keyIsInsideDhaka, isInsideDhaka);
    } catch (_) {}
  }

  /// Calculates the Haversine distance in kilometers between two geographic coordinates.
  double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Checks if coordinates are within Greater Dhaka boundary (~40 km of center).
  bool isWithinDhaka(double lat, double lng) {
    final dist = calculateDistanceKm(lat, lng, dhakaCenterLat, dhakaCenterLng);
    return dist <= dhakaRadiusKm;
  }

  /// Matches a reverse-geocoded Placemark against known Dhaka areas.
  String? matchPlacemarkToDhakaArea(Placemark place) {
    final searchTerms = [
      place.subLocality?.toLowerCase() ?? '',
      place.name?.toLowerCase() ?? '',
      place.street?.toLowerCase() ?? '',
      place.subAdministrativeArea?.toLowerCase() ?? '',
      place.locality?.toLowerCase() ?? '',
    ];

    final fullText = searchTerms.join(' ');

    if (fullText.contains('mirpur') || fullText.contains('pallabi') || fullText.contains('kazipara') || fullText.contains('shewrapara')) return 'Mirpur';
    if (fullText.contains('uttara') || fullText.contains('tongi')) return 'Uttara';
    if (fullText.contains('gulshan')) return 'Gulshan';
    if (fullText.contains('banani')) return 'Banani';
    if (fullText.contains('dhanmondi')) return 'Dhanmondi';
    if (fullText.contains('mohammadpur') || fullText.contains('adabor')) return 'Mohammadpur';
    if (fullText.contains('badda') || fullText.contains('merul')) return 'Badda';
    if (fullText.contains('bashundhara')) return 'Bashundhara R/A';
    if (fullText.contains('motijheel') || fullText.contains('dilkusha')) return 'Motijheel';
    if (fullText.contains('khilgaon') || fullText.contains('goran')) return 'Khilgaon';
    if (fullText.contains('old dhaka') ||
        fullText.contains('lalbagh') ||
        fullText.contains('sutrapur') ||
        fullText.contains('kotwali') ||
        fullText.contains('wari') ||
        fullText.contains('chowkbazar') ||
        fullText.contains('sadarghat')) {
      return 'Old Dhaka';
    }
    if (fullText.contains('tejgaon') || fullText.contains('farmgate')) return 'Tejgaon';
    if (fullText.contains('mohakhali')) return 'Mohakhali';
    if (fullText.contains('malibagh') || fullText.contains('moghbazar') || fullText.contains('eskaton')) {
      return 'Malibagh';
    }
    if (fullText.contains('banasree')) return 'Banasree';
    if (fullText.contains('rampura') || fullText.contains('aftabnagar')) {
      return 'Rampura';
    }
    if (fullText.contains('lalmatia')) return 'Lalmatia';
    if (fullText.contains('baridhara')) return 'Baridhara';
    if (fullText.contains('shahbagh') || fullText.contains('kawran bazar')) return 'Shahbagh';
    if (fullText.contains('elephant road') || fullText.contains('new market')) return 'Elephant Road';
    if (fullText.contains('cantonment')) return 'Cantonment';
    if (fullText.contains('khilkhet') || fullText.contains('nikunja')) return 'Khilkhet';
    if (fullText.contains('agargaon') || fullText.contains('taltola')) return 'Agargaon';
    if (fullText.contains('shyamoli') || fullText.contains('kalyanpur')) return 'Shyamoli';
    if (fullText.contains('basabo') || fullText.contains('mugda') || fullText.contains('madartek')) {
      return 'Basabo';
    }
    if (fullText.contains('keraniganj')) return 'Keraniganj';
    if (fullText.contains('savar') || fullText.contains('ashulia')) return 'Savar';

    // If subLocality has a value, check if any Dhaka area equals it
    for (final area in LocationConstants.dhakaAreas) {
      if (fullText.contains(area.toLowerCase())) {
        return area;
      }
    }

    return null;
  }

  /// Resolves any latitude and longitude into an accurate location result.
  /// If inside Dhaka, identifies the closest neighborhood.
  /// If outside Dhaka (e.g. Chittagong, Sylhet), identifies the actual city/region.
  DetectedLocationResult resolveLocation(
    double lat,
    double lng, {
    String? detectedCity,
    String? detectedRegion,
    String source = 'GPS',
    bool hasGpsFix = true,
  }) {
    final distToDhaka = calculateDistanceKm(lat, lng, dhakaCenterLat, dhakaCenterLng);
    final isInside = distToDhaka <= dhakaRadiusKm;

    if (!isInside) {
      // User is outside Dhaka (e.g. in Chittagong, Rajshahi, Sylhet, etc.)
      final displayName = detectedCity != null && detectedCity.isNotEmpty
          ? detectedCity
          : (detectedRegion != null && detectedRegion.isNotEmpty ? detectedRegion : 'Outside Dhaka');

      return DetectedLocationResult(
        area: displayName,
        city: detectedCity ?? displayName,
        division: detectedRegion,
        latitude: lat,
        longitude: lng,
        distanceKm: distToDhaka,
        isInsideDhaka: false,
        isExactMatch: true,
        hasGpsFix: hasGpsFix,
        source: source,
      );
    }

    // Inside Dhaka: find closest centroid
    AreaCoordinate? nearest;
    double minDistance = double.infinity;

    for (final centroid in dhakaCentroids) {
      final dist = calculateDistanceKm(lat, lng, centroid.latitude, centroid.longitude);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = centroid;
      }
    }

    final matchedArea = nearest?.name ?? 'Dhaka';

    return DetectedLocationResult(
      area: matchedArea,
      city: 'Dhaka',
      division: 'Dhaka',
      latitude: lat,
      longitude: lng,
      distanceKm: minDistance,
      isInsideDhaka: true,
      isExactMatch: minDistance <= 15.0,
      hasGpsFix: hasGpsFix,
      source: source,
    );
  }

  /// Backward-compatible alias for Dhaka area centroid lookup.
  DetectedLocationResult findNearestDhakaArea(double lat, double lng) {
    return resolveLocation(lat, lng, source: 'GeometricProximity');
  }

  /// Requests device location permission.
  Future<LocationPermission> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission;
    } catch (e) {
      debugPrint('LocationService requestPermission error: $e');
      return LocationPermission.denied;
    }
  }

  /// Checks the current location permission without requesting it.
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  /// Automatically fetches the user's real location:
  /// 1. Immediately checks device Last Known Position (instant cache).
  /// 2. Requests fresh GPS coordinates if cache is empty or stale.
  /// 3. Reverse geocodes to map coordinates to the accurate Dhaka neighborhood (e.g. Banasree).
  /// 4. Does NOT use misleading IP Geolocation that maps Bangladeshi ISPs to other divisions.
  Future<DetectedLocationResult> getCurrentLocationArea() async {
    Position? position;
    String locationSource = 'GPS';

    try {
      // 1. Ensure permission is obtained
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final isAllowed = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (isAllowed) {
        final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        debugPrint('LocationService: GPS serviceEnabled = $isServiceEnabled');

        // Step A: Immediately check last known position (fast & reliable on emulators/devices)
        try {
          position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            locationSource = 'LastKnownGPS';
            debugPrint('LocationService: lastKnownPosition found -> lat: ${position.latitude}, lng: ${position.longitude}');
          }
        } catch (e) {
          debugPrint('LocationService: getLastKnownPosition failed: $e');
        }

        // Step B: If no cached position, request fresh position with high accuracy
        if (position == null) {
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 8),
              ),
            ).timeout(const Duration(seconds: 9));
            locationSource = 'FreshGPS';
            debugPrint('LocationService: getCurrentPosition success -> lat: ${position.latitude}, lng: ${position.longitude}');
          } catch (e) {
            debugPrint('LocationService: getCurrentPosition high accuracy failed: $e. Retrying medium accuracy...');
            try {
              position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.medium,
                  timeLimit: Duration(seconds: 5),
                ),
              ).timeout(const Duration(seconds: 6));
              locationSource = 'MediumGPS';
            } catch (e2) {
              debugPrint('LocationService: medium accuracy also timed out or failed: $e2');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('LocationService getCurrentLocationArea unexpected error: $e');
    }

    // 2. If device GPS returned a position:
    if (position != null) {
      String? matchedCity;
      String? matchedRegion;
      String? matchedDhakaArea;

      // Attempt reverse geocoding
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 3));

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          debugPrint('LocationService: Placemark -> locality: ${place.locality}, subAdmin: ${place.subAdministrativeArea}, admin: ${place.administrativeArea}, subLocality: ${place.subLocality}');

          matchedDhakaArea = matchPlacemarkToDhakaArea(place);
          matchedCity = place.locality?.isNotEmpty == true
              ? place.locality
              : (place.subAdministrativeArea?.isNotEmpty == true ? place.subAdministrativeArea : null);
          matchedRegion = place.administrativeArea;
        }
      } catch (e) {
        debugPrint('LocationService: Reverse geocoding failed: $e');
      }

      final isInside = isWithinDhaka(position.latitude, position.longitude);

      if (isInside && matchedDhakaArea != null) {
        final dist = calculateDistanceKm(position.latitude, position.longitude, dhakaCenterLat, dhakaCenterLng);
        final result = DetectedLocationResult(
          area: matchedDhakaArea,
          city: 'Dhaka',
          division: 'Dhaka',
          latitude: position.latitude,
          longitude: position.longitude,
          distanceKm: dist,
          isInsideDhaka: true,
          isExactMatch: true,
          hasGpsFix: true,
          source: 'ReverseGeocoding',
        );
        await saveDetectedLocation(
          area: result.area,
          lat: result.latitude,
          lng: result.longitude,
          city: result.city,
          isInsideDhaka: true,
        );
        return result;
      }

      final result = resolveLocation(
        position.latitude,
        position.longitude,
        detectedCity: matchedCity,
        detectedRegion: matchedRegion,
        source: locationSource,
        hasGpsFix: true,
      );

      await saveDetectedLocation(
        area: result.area,
        lat: result.latitude,
        lng: result.longitude,
        city: result.city,
        isInsideDhaka: result.isInsideDhaka,
      );
      return result;
    }

    // 3. Fallback when device GPS is unavailable or disabled:
    // Check if user previously had a saved area, or default to Banasree, Dhaka
    final savedArea = await getSavedDetectedArea();
    final defaultArea = (savedArea != null && savedArea.isNotEmpty) ? savedArea : 'Banasree';

    debugPrint('LocationService: GPS fix unavailable on device. Defaulting to $defaultArea.');
    const defaultCentroid = AreaCoordinate('Banasree', 23.7644, 90.4328);

    final defaultResult = DetectedLocationResult(
      area: defaultArea,
      city: 'Dhaka',
      division: 'Dhaka',
      latitude: defaultCentroid.latitude,
      longitude: defaultCentroid.longitude,
      distanceKm: 0,
      isInsideDhaka: true,
      isExactMatch: true,
      hasGpsFix: false,
      source: 'DefaultArea',
    );

    await saveDetectedLocation(
      area: defaultResult.area,
      lat: defaultResult.latitude,
      lng: defaultResult.longitude,
      city: defaultResult.city,
      isInsideDhaka: true,
    );
    return defaultResult;
  }
}

/// Provider for [LocationService].
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
