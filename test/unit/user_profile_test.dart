import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/features/auth/domain/user_profile.dart';

void main() {
  group('UserProfile Model', () {
    test('serializes and deserializes correctly', () {
      final json = {
        'id': 'user-123',
        'email': 'customer@example.com',
        'role': 'customer',
        'first_name': 'Rahim',
        'last_name': 'Ahmed',
        'gender': 'Male',
        'full_name': 'Rahim Ahmed',
        'phone': '01711111111',
        'avatar_url': 'https://example.com/avatar.jpg',
        'address': 'House 14, Road 7, Banasree',
        'city': 'Dhaka',
        'date_of_birth': '1998-05-15',
        'is_active': true,
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'user-123');
      expect(profile.email, 'customer@example.com');
      expect(profile.role, 'customer');
      expect(profile.firstName, 'Rahim');
      expect(profile.lastName, 'Ahmed');
      expect(profile.gender, 'Male');
      expect(profile.fullName, 'Rahim Ahmed');
      expect(profile.phone, '01711111111');
      expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
      expect(profile.address, 'House 14, Road 7, Banasree');
      expect(profile.city, 'Dhaka');
      expect(profile.dateOfBirth, '1998-05-15');
      expect(profile.isActive, isTrue);
      expect(profile.isCustomer, isTrue);
      expect(profile.isRestaurant, isFalse);
      expect(profile.isAdmin, isFalse);

      final output = profile.toJson();
      expect(output['id'], 'user-123');
      expect(output['role'], 'customer');
      expect(output['first_name'], 'Rahim');
      expect(output['last_name'], 'Ahmed');
      expect(output['gender'], 'Male');
      expect(output['full_name'], 'Rahim Ahmed');
      expect(output['address'], 'House 14, Road 7, Banasree');
      expect(output['city'], 'Dhaka');
      expect(output['date_of_birth'], '1998-05-15');
    });

    test('derives fullName from firstName and lastName when full_name is omitted', () {
      final json = {
        'id': 'user-456',
        'email': 'karim@example.com',
        'role': 'customer',
        'first_name': 'Karim',
        'last_name': 'Uddin',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.fullName, 'Karim Uddin');
    });

    test('role helper getters work properly', () {
      const customer = UserProfile(
        id: '1',
        email: 'c@test.com',
        role: AppConstants.roleCustomer,
      );
      expect(customer.isCustomer, isTrue);
      expect(customer.isRestaurant, isFalse);
      expect(customer.isAdmin, isFalse);

      const restaurant = UserProfile(
        id: '2',
        email: 'r@test.com',
        role: AppConstants.roleRestaurant,
      );
      expect(restaurant.isCustomer, isFalse);
      expect(restaurant.isRestaurant, isTrue);
      expect(restaurant.isAdmin, isFalse);

      const admin = UserProfile(
        id: '3',
        email: 'a@test.com',
        role: AppConstants.roleAdmin,
      );
      expect(admin.isCustomer, isFalse);
      expect(admin.isRestaurant, isFalse);
      expect(admin.isAdmin, isTrue);
    });
  });
}
