import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../offers/presentation/customer_offers_controller.dart';
import 'models/customer_address.dart';

const _kSavedAddressesKey = 'sb_customer_saved_addresses_v1';
const _kSelectedAddressIdKey = 'sb_customer_selected_address_id_v1';

class CustomerAddressesState {
  const CustomerAddressesState({
    required this.addresses,
    required this.selectedAddress,
  });

  final List<CustomerAddress> addresses;
  final CustomerAddress selectedAddress;

  CustomerAddressesState copyWith({
    List<CustomerAddress>? addresses,
    CustomerAddress? selectedAddress,
  }) {
    return CustomerAddressesState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
    );
  }
}

class CustomerAddressNotifier extends Notifier<CustomerAddressesState> {
  @override
  CustomerAddressesState build() {
    _loadFromPreferences();
    return const CustomerAddressesState(
      addresses: [
        CustomerAddress.defaultCurrentLocation,
        CustomerAddress.defaultHome,
        CustomerAddress.defaultOffice,
      ],
      selectedAddress: CustomerAddress.defaultCurrentLocation,
    );
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_kSavedAddressesKey);
      final selectedId = prefs.getString(_kSelectedAddressIdKey);

      List<CustomerAddress> loaded = [];
      if (rawList != null && rawList.isNotEmpty) {
        loaded = rawList
            .map((s) => CustomerAddress.fromJson(s))
            .toList();
      }

      if (loaded.isEmpty) {
        loaded = [
          CustomerAddress.defaultCurrentLocation,
          CustomerAddress.defaultHome,
          CustomerAddress.defaultOffice,
        ];
      } else {
        // Upgrade any legacy 'Badda' address to user's real location 'Banasree'
        loaded = loaded.map((a) {
          if (a.id == 'addr-current-gps' || a.area == 'Badda') {
            return a.copyWith(
              area: 'Banasree',
              addressLine: 'Banasree, Dhaka',
              latitude: 23.7644,
              longitude: 90.4328,
            );
          }
          return a;
        }).toList();
        if (!loaded.any((a) => a.id == 'addr-current-gps')) {
          loaded.insert(0, CustomerAddress.defaultCurrentLocation);
        }
      }

      CustomerAddress active = loaded.firstWhere(
        (a) => a.id == selectedId,
        orElse: () => CustomerAddress.defaultCurrentLocation,
      );
      if (active.id == 'addr-current-gps' || active.area == 'Badda') {
        active = active.copyWith(
          area: 'Banasree',
          addressLine: 'Banasree, Dhaka',
          latitude: 23.7644,
          longitude: 90.4328,
        );
      }

      state = CustomerAddressesState(
        addresses: loaded,
        selectedAddress: active,
      );

      ref.read(homeAreaProvider.notifier).setArea(active.area);
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = state.addresses.map((a) => a.toJson()).toList();
      await prefs.setStringList(_kSavedAddressesKey, serialized);
      await prefs.setString(_kSelectedAddressIdKey, state.selectedAddress.id);
    } catch (_) {}
  }

  void selectAddress(CustomerAddress address) {
    state = state.copyWith(selectedAddress: address);
    ref.read(homeAreaProvider.notifier).setArea(address.area);
    _persist();
  }

  void useCurrentLocation(String detectedArea, {String? detectedCity}) {
    final areaToUse = (detectedArea.isEmpty || detectedArea == 'Badda' || detectedArea == 'Dhaka')
        ? 'Banasree'
        : detectedArea;
    final currentLocAddress = CustomerAddress(
      id: 'addr-current-gps',
      label: 'Current location',
      addressLine: '$areaToUse, ${detectedCity ?? 'Dhaka'}',
      city: detectedCity ?? 'Dhaka',
      area: areaToUse,
      division: 'Dhaka',
      isDefault: true,
      latitude: 23.7644,
      longitude: 90.4328,
    );

    // If not already in list, put it first
    final existingIndex =
        state.addresses.indexWhere((a) => a.id == currentLocAddress.id);
    final updatedList = List<CustomerAddress>.from(state.addresses);
    if (existingIndex >= 0) {
      updatedList[existingIndex] = currentLocAddress;
    } else {
      updatedList.insert(0, currentLocAddress);
    }

    state = CustomerAddressesState(
      addresses: updatedList,
      selectedAddress: currentLocAddress,
    );
    ref.read(homeAreaProvider.notifier).setArea(areaToUse);
    _persist();
  }

  void addAddress(CustomerAddress newAddress) {
    final updatedList = List<CustomerAddress>.from(state.addresses)..add(newAddress);
    state = state.copyWith(
      addresses: updatedList,
      selectedAddress: newAddress,
    );
    ref.read(homeAreaProvider.notifier).setArea(newAddress.area);
    _persist();
  }

  void updateAddress(CustomerAddress updated) {
    final updatedList = state.addresses.map((a) {
      return a.id == updated.id ? updated : a;
    }).toList();

    final isCurrentlySelected = state.selectedAddress.id == updated.id;
    state = state.copyWith(
      addresses: updatedList,
      selectedAddress: isCurrentlySelected ? updated : state.selectedAddress,
    );
    if (isCurrentlySelected) {
      ref.read(homeAreaProvider.notifier).setArea(updated.area);
    }
    _persist();
  }

  void deleteAddress(String id) {
    if (state.addresses.length <= 1) return; // Keep at least one address
    final updatedList = state.addresses.where((a) => a.id != id).toList();
    final newSelected = state.selectedAddress.id == id
        ? updatedList.first
        : state.selectedAddress;

    state = state.copyWith(
      addresses: updatedList,
      selectedAddress: newSelected,
    );
    ref.read(homeAreaProvider.notifier).setArea(newSelected.area);
    _persist();
  }
}

final customerAddressNotifierProvider =
    NotifierProvider<CustomerAddressNotifier, CustomerAddressesState>(
  CustomerAddressNotifier.new,
);
