import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/comments_mock_data_source.dart';
import '../../domain/entities/comment_thread_entry.dart';

final commentsMockDataSourceProvider = Provider<CommentsMockDataSource>((ref) {
  return const CommentsMockDataSource();
});

final bazarCommentsProvider = Provider<List<CommentThreadEntry>>((ref) {
  return ref.watch(commentsMockDataSourceProvider).comments();
});

final draftCommentProvider = StateProvider<String>((ref) => '');

final priceHistoryProvider = Provider<PriceHistorySummary>((ref) {
  return ref.watch(commentsMockDataSourceProvider).priceHistory();
});
