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

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      ownerId: (json['owner_id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
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
