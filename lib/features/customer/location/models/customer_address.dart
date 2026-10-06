import 'dart:convert';

/// Represents a customer's saved delivery address.
class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.city,
    this.area = 'Dhanmondi',
    this.division = 'Dhaka',
    this.isDefault = false,
    this.latitude = 23.8103,
    this.longitude = 90.4125,
  });

  final String id;
  final String label; // e.g. 'Home', 'Office', 'Current Location', 'Other'
  final String addressLine; // e.g. '2B, House 32, Road 3, Block C Road 3'
  final String city; // e.g. 'Dhaka'
  final String area; // e.g. 'Dhanmondi', 'Mirpur', 'Banani'
  final String division;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  /// Default Current Location address matching user specification (Banasree, Dhaka).
  static const defaultCurrentLocation = CustomerAddress(
    id: 'addr-current-gps',
    label: 'Current location',
    addressLine: 'Banasree, Dhaka',
    city: 'Dhaka',
    area: 'Banasree',
    division: 'Dhaka',
    isDefault: true,
    latitude: 23.7644,
    longitude: 90.4328,
  );

  /// Default Home address matching the user specification & screenshot.
  static const defaultHome = CustomerAddress(
    id: 'addr-home',
    label: 'Home',
    addressLine: '2B, House 32, Road 3, Block C Road 3',
    city: 'Dhaka',
    area: 'Mirpur',
    division: 'Dhaka',
    isDefault: false,
    latitude: 23.8041,
    longitude: 90.3685,
  );

  /// Default Office address.
  static const defaultOffice = CustomerAddress(
    id: 'addr-office',
    label: 'Office',
    addressLine: 'Level 5, Plot 12, Road 11, Banani',
    city: 'Dhaka',
    area: 'Banani',
    division: 'Dhaka',
    isDefault: false,
    latitude: 23.7937,
    longitude: 90.4066,
  );

  CustomerAddress copyWith({
    String? id,
    String? label,
    String? addressLine,
    String? city,
    String? area,
    String? division,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      area: area ?? this.area,
      division: division ?? this.division,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'addressLine': addressLine,
      'city': city,
      'area': area,
      'division': division,
      'isDefault': isDefault,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory CustomerAddress.fromMap(Map<String, dynamic> map) {
    return CustomerAddress(
      id: (map['id'] as String?) ?? 'addr-${DateTime.now().millisecondsSinceEpoch}',
      label: (map['label'] as String?) ?? 'Home',
      addressLine: (map['addressLine'] as String?) ?? '',
      city: (map['city'] as String?) ?? 'Dhaka',
      area: (map['area'] as String?) ?? 'Dhaka',
      division: (map['division'] as String?) ?? 'Dhaka',
      isDefault: (map['isDefault'] as bool?) ?? false,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 23.8103,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 90.4125,
    );
  }

  String toJson() => json.encode(toMap());

  factory CustomerAddress.fromJson(String source) =>
      CustomerAddress.fromMap(json.decode(source) as Map<String, dynamic>);
}
