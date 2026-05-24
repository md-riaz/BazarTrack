import 'package:equatable/equatable.dart';

class CommentThreadEntry extends Equatable {
  const CommentThreadEntry({
    required this.id,
    required this.user,
    required this.avatar,
    required this.timeLabel,
    required this.message,
    required this.isOwner,
  });

  final String id;
  final String user;
  final String avatar;
  final String timeLabel;
  final String message;
  final bool isOwner;

  @override
  List<Object?> get props => [id, user, avatar, timeLabel, message, isOwner];
}

class PriceHistoryEntry extends Equatable {
  const PriceHistoryEntry({
    required this.dateLabel,
    required this.quantityLabel,
    required this.price,
    required this.bazarName,
    required this.buyerName,
    required this.perUnit,
  });

  final String dateLabel;
  final String quantityLabel;
  final double price;
  final String bazarName;
  final String buyerName;
  final double perUnit;

  @override
  List<Object?> get props => [
    dateLabel,
    quantityLabel,
    price,
    bazarName,
    buyerName,
    perUnit,
  ];
}

class PriceHistorySummary extends Equatable {
  const PriceHistorySummary({
    required this.itemName,
    required this.unit,
    required this.entries,
  });

  final String itemName;
  final String unit;
  final List<PriceHistoryEntry> entries;

  double get latestPrice => entries.first.price;

  double get averagePerUnit {
    if (entries.isEmpty) {
      return 0;
    }
    final sum = entries.fold<double>(
      0,
      (total, entry) => total + entry.perUnit,
    );
    return (sum / entries.length * 100).roundToDouble() / 100;
  }

  double get maxPrice => entries.fold<double>(
    0,
    (max, entry) => entry.price > max ? entry.price : max,
  );

  @override
  List<Object?> get props => [itemName, unit, entries];
}
