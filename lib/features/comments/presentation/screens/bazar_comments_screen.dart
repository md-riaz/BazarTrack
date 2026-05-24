import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../settings/presentation/widgets/settings_widgets.dart';
import '../../domain/entities/comment_thread_entry.dart';
import '../providers/comments_providers.dart';

class BazarCommentsScreen extends ConsumerWidget {
  const BazarCommentsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(bazarCommentsProvider);
    final draft = ref.watch(draftCommentProvider);
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'মন্তব্য',
        subtitle: 'CEO PERSONAL বাজার',
        leading: BackButton(onPressed: onBack),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Text(
              'মন্তব্য = অডিট নোট। দ্রুত যোগাযোগের জন্য WhatsApp ব্যবহার করুন।',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) => _CommentBubble(comments[index]),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: comments.length,
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const HAvatar(label: 'RU', size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface3,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (value) =>
                                ref.read(draftCommentProvider.notifier).state =
                                    value,
                            decoration: const InputDecoration(
                              hintText: 'মন্তব্য লিখুন…',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: draft.isEmpty
                              ? null
                              : () =>
                                    ref
                                            .read(draftCommentProvider.notifier)
                                            .state =
                                        '',
                          icon: const Icon(Icons.arrow_upward),
                          style: IconButton.styleFrom(
                            backgroundColor: draft.isEmpty
                                ? AppColors.surface3
                                : AppColors.primary,
                            foregroundColor: draft.isEmpty
                                ? AppColors.text4
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble(this.comment);

  final CommentThreadEntry comment;

  @override
  Widget build(BuildContext context) {
    final bg = comment.isOwner
        ? AppColors.negativeLight
        : AppColors.positiveLight;
    final fg = comment.isOwner
        ? AppColors.negativeDark
        : AppColors.positiveDark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HAvatar(
          label: comment.avatar,
          size: 32,
          backgroundColor: bg,
          foregroundColor: fg,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    comment.user,
                    style: AppTextStyles.bodyStrong.copyWith(fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(comment.timeLabel, style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
                child: Text(
                  comment.message,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
