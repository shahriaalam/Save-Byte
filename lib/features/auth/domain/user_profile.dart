import '../../../core/constants/app_constants.dart';

/// User profile model according to SaveBite specification (Section 10).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String role; // 'customer', 'restaurant', 'admin'
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCustomer => role == AppConstants.roleCustomer;
  bool get isRestaurant => role == AppConstants.roleRestaurant;
  bool get isAdmin => role == AppConstants.roleAdmin;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      role: (json['role'] as String?) ?? AppConstants.roleCustomer,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
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
      'email': email,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? role,
    String? fullName,
    String? phone,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          role == other.role &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^ email.hashCode ^ role.hashCode ^ isActive.hashCode;

  @override
  String toString() =>
      'UserProfile(id: $id, email: $email, role: $role, isActive: $isActive)';
}
