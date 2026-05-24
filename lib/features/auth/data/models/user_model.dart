import 'package:bazar/shared/models/app_enums.dart';

import '../../domain/entities/user.dart' as domain;

class UserModel extends domain.User {
  const UserModel({
    required super.id,
    required super.name,
    required super.role,
    required super.isActive,
    super.phone,
    super.email,
  });

  factory UserModel.fromJson(Map<String, Object?> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      role: _roleFromString(json['role'] as String? ?? 'assistant'),
      isActive: json['isActive'] as bool? ?? true,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
      'isActive': isActive,
      'phone': phone,
      'email': email,
    };
  }

  static UserModel fromDomain(domain.User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      role: user.role,
      isActive: user.isActive,
      phone: user.phone,
      email: user.email,
    );
  }
}

UserRole _roleFromString(String value) {
  return UserRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => UserRole.assistant,
  );
}
