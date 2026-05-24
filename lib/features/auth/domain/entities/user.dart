import 'package:equatable/equatable.dart';

import '../../../../shared/models/app_enums.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.role,
    required this.isActive,
    this.phone,
    this.email,
  });

  final String id;
  final String name;
  final UserRole role;
  final bool isActive;
  final String? phone;
  final String? email;

  bool get isOwner => role == UserRole.owner || role == UserRole.admin;
  bool get isAssistant => role == UserRole.assistant;

  @override
  List<Object?> get props => [id, name, role, isActive, phone, email];
}
