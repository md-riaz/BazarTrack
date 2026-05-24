import 'package:equatable/equatable.dart';

class OfflineQueueEntry extends Equatable {
  const OfflineQueueEntry({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.entityLabel,
    required this.ageLabel,
    required this.retryCount,
    required this.status,
  });

  final String id;
  final String entityType;
  final String operation;
  final String entityLabel;
  final String ageLabel;
  final int retryCount;
  final OfflineQueueStatus status;

  @override
  List<Object?> get props => [
    id,
    entityType,
    operation,
    entityLabel,
    ageLabel,
    retryCount,
    status,
  ];
}

enum OfflineQueueStatus { waiting, failed }
