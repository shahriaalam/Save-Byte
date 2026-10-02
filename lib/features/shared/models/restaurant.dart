import '../../../core/constants/app_constants.dart';

/// Restaurant model representing restaurants table (Section 11).
class Restaurant {
  const Restaurant({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.phone,
    this.address,
    this.division,
    this.area,
    this.imageUrl,
    this.cuisineType,
    this.openingTime,
    this.closingTime,
    this.status = AppConstants.statusPending,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? phone;
  final String? address;
  final String? division;
  final String? area;
  final String? imageUrl;
  final String? cuisineType;
  final String? openingTime;
  final String? closingTime;
  final String status;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isApproved => status == AppConstants.statusApproved;
  bool get isPending => status == AppConstants.statusPending;
  bool get isSuspended => status == AppConstants.statusSuspended;
  bool get isRejected => status == AppConstants.statusRejected;

  /// Profile completeness check:
  /// Requires restaurant name, phone, address, division, area, profile picture (imageUrl), and cuisine type.
  bool get isProfileComplete {
    return name.trim().isNotEmpty &&
        (phone != null && phone!.trim().isNotEmpty) &&
        (address != null && address!.trim().isNotEmpty) &&
        (division != null && division!.trim().isNotEmpty) &&
        (area != null && area!.trim().isNotEmpty) &&
        (imageUrl != null && imageUrl!.trim().isNotEmpty) &&
        (cuisineType != null && cuisineType!.trim().isNotEmpty);
  }

  /// Returns missing profile field names for user-facing prompts.
  List<String> get missingProfileFields {
    final missing = <String>[];
    if (name.trim().isEmpty) missing.add('Restaurant Name');
    if (phone == null || phone!.trim().isEmpty) missing.add('Phone Number');
    if (division == null || division!.trim().isEmpty) missing.add('Division');
    if (area == null || area!.trim().isEmpty) missing.add('Area');
    if (address == null || address!.trim().isEmpty) missing.add('Address');
    if (imageUrl == null || imageUrl!.trim().isEmpty) missing.add('Restaurant Profile Picture');
    if (cuisineType == null || cuisineType!.trim().isEmpty) missing.add('Cuisine Type');
    return missing;
  }

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      ownerId: (json['owner_id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      division: (json['division'] as String?) ?? 'Dhaka',
      area: json['area'] as String?,
      imageUrl: json['image_url'] as String?,
      cuisineType: json['cuisine_type'] as String?,
      openingTime: json['opening_time'] as String?,
      closingTime: json['closing_time'] as String?,
      status: (json['status'] as String?) ?? AppConstants.statusPending,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'phone': phone,
      'address': address,
      'division': division,
      'area': area,
      'image_url': imageUrl,
      'cuisine_type': cuisineType,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'status': status,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Restaurant copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? phone,
    String? address,
    String? division,
    String? area,
    String? imageUrl,
    String? cuisineType,
    String? openingTime,
    String? closingTime,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Restaurant(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      division: division ?? this.division,
      area: area ?? this.area,
      imageUrl: imageUrl ?? this.imageUrl,
      cuisineType: cuisineType ?? this.cuisineType,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
