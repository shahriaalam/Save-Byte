import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../offers/presentation/customer_offers_controller.dart';

/// State of the customer's detected location.
@immutable
class UserLocationState {
  const UserLocationState({
    this.detectedArea,
    this.detectedCity,
    this.detectedDivision,
    this.isInsideDhaka = true,
    this.isDetecting = false,
    this.isAutoDetected = false,
    this.hasPermission = false,
    this.permissionDenied = false,
    this.hasGpsFix = true,
    this.statusMessage,
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  final String? detectedArea;
  final String? detectedCity;
  final String? detectedDivision;
  final bool isInsideDhaka;
  final bool isDetecting;
  final bool isAutoDetected;
  final bool hasPermission;
  final bool permissionDenied;
  final bool hasGpsFix;
  final String? statusMessage;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  UserLocationState copyWith({
    String? detectedArea,
    String? detectedCity,
    String? detectedDivision,
    bool? isInsideDhaka,
    bool? isDetecting,
    bool? isAutoDetected,
    bool? hasPermission,
    bool? permissionDenied,
    bool? hasGpsFix,
    String? statusMessage,
    double? latitude,
    double? longitude,
    double? distanceKm,
  }) {
    return UserLocationState(
      detectedArea: detectedArea ?? this.detectedArea,
      detectedCity: detectedCity ?? this.detectedCity,
      detectedDivision: detectedDivision ?? this.detectedDivision,
      isInsideDhaka: isInsideDhaka ?? this.isInsideDhaka,
      isDetecting: isDetecting ?? this.isDetecting,
      isAutoDetected: isAutoDetected ?? this.isAutoDetected,
      hasPermission: hasPermission ?? this.hasPermission,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      hasGpsFix: hasGpsFix ?? this.hasGpsFix,
      statusMessage: statusMessage ?? this.statusMessage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

/// Notifier managing customer automatic location detection and synchronization with [homeAreaProvider].
class UserLocationNotifier extends Notifier<UserLocationState> {
  LocationService get _locationService => ref.read(locationServiceProvider);

  @override
  UserLocationState build() {
    _loadSavedLocation();
    return const UserLocationState();
  }

  Future<void> _loadSavedLocation() async {
    final savedArea = await _locationService.getSavedDetectedArea();
    if (savedArea != null && savedArea.isNotEmpty) {
      state = state.copyWith(
        detectedArea: savedArea,
        isAutoDetected: true,
        statusMessage: 'Location: $savedArea',
      );
      ref.read(homeAreaProvider.notifier).setArea(savedArea);
    }
  }

  /// Checks if location permission has already been prompted to the user.
  Future<bool> hasPromptedPermission() async {
    return _locationService.hasPromptedPermission();
  }

  /// Marks that the 1st-time location prompt has been shown.
  Future<void> markPromptShown() async {
    await _locationService.markPermissionPromptShown();
  }

  /// Requests location permission from the device and automatically detects the user's real location.
  /// Works across devices, emulators (via IP geolocation fallback), and real GPS hardware.
  Future<String> requestPermissionAndDetect() async {
    state = state.copyWith(isDetecting: true, statusMessage: 'Detecting location...');

    try {
      await _locationService.markPermissionPromptShown();
      final permission = await _locationService.requestPermission();

      final isAllowed = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      state = state.copyWith(
        hasPermission: isAllowed,
        permissionDenied: !isAllowed,
        statusMessage: isAllowed ? 'Pinpointing location...' : 'Using default location',
      );

      final result = await _locationService.getCurrentLocationArea();
      state = state.copyWith(
        isDetecting: false,
        detectedArea: result.area,
        detectedCity: result.city,
        detectedDivision: result.division,
        isInsideDhaka: result.isInsideDhaka,
        isAutoDetected: result.isExactMatch,
        hasGpsFix: result.hasGpsFix,
        latitude: result.latitude,
        longitude: result.longitude,
        distanceKm: result.distanceKm,
        statusMessage: result.isInsideDhaka
            ? 'Located in ${result.area}'
            : 'Located in ${result.area} (Outside Dhaka)',
      );

      // If inside Dhaka, set specific neighborhood.
      // If outside Dhaka (e.g. Chittagong, Sylhet), set to 'All' so Dhaka food offers display.
      if (result.isInsideDhaka) {
        ref.read(homeAreaProvider.notifier).setArea(result.area);
      } else {
        ref.read(homeAreaProvider.notifier).setArea('All');
      }
      return result.area;
    } catch (e) {
      debugPrint('Error in requestPermissionAndDetect: $e');
      const fallbackArea = 'Dhaka';
      state = state.copyWith(
        isDetecting: false,
        detectedArea: fallbackArea,
        isInsideDhaka: true,
        hasGpsFix: false,
        statusMessage: 'Location set to $fallbackArea',
      );
      ref.read(homeAreaProvider.notifier).setArea('All');
      return fallbackArea;
    }
  }

  /// Silently checks if permission is already granted and refreshes current location.
  Future<String> refreshCurrentLocation() async {
    state = state.copyWith(isDetecting: true, statusMessage: 'Pinpointing location...');

    try {
      final result = await _locationService.getCurrentLocationArea();
      state = state.copyWith(
        isDetecting: false,
        detectedArea: result.area,
        detectedCity: result.city,
        detectedDivision: result.division,
        isInsideDhaka: result.isInsideDhaka,
        isAutoDetected: result.isExactMatch,
        hasPermission: true,
        hasGpsFix: result.hasGpsFix,
        latitude: result.latitude,
        longitude: result.longitude,
        distanceKm: result.distanceKm,
        statusMessage: result.isInsideDhaka
            ? 'Located in ${result.area}'
            : 'Located in ${result.area} (Outside Dhaka)',
      );

      if (result.isInsideDhaka) {
        ref.read(homeAreaProvider.notifier).setArea(result.area);
      } else {
        ref.read(homeAreaProvider.notifier).setArea('All');
      }
      return result.area;
    } catch (e) {
      debugPrint('Error in refreshCurrentLocation: $e');
      final current = state.detectedArea ?? 'Dhaka';
      state = state.copyWith(
        isDetecting: false,
        statusMessage: 'Located in $current',
      );
      return current;
    }
  }

  /// Sets manual area when user picks from dropdown/list.
  void setManualArea(String area) {
    state = state.copyWith(
      detectedArea: area,
      isAutoDetected: false,
      isInsideDhaka: true,
      statusMessage: 'Area set to $area',
    );
    ref.read(homeAreaProvider.notifier).setArea(area);
  }
}

/// Provider for [UserLocationNotifier].
final userLocationControllerProvider =
    NotifierProvider<UserLocationNotifier, UserLocationState>(
  UserLocationNotifier.new,
);
