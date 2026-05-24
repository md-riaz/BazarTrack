import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
    required this.createdAt,
    this.createdBy,
  });

  final String id;
  final String name;
  final String type;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;

  String get shortName {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length.clamp(0, 2))
          .toUpperCase();
    }
    return words
        .take(2)
        .map((word) => word.isEmpty ? '' : word[0])
        .join()
        .toUpperCase();
  }

  @override
  List<Object?> get props => [id, name, type, isActive, createdBy, createdAt];
}
