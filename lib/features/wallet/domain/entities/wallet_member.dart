import 'package:equatable/equatable.dart';

class WalletMember extends Equatable {
  const WalletMember({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String walletId;
  final String userId;
  final String role;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, walletId, userId, role, createdAt];
}
