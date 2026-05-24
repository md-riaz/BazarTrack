import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/bazar_entities.dart';

class ActivityTimelineWidget extends StatelessWidget {
  const ActivityTimelineWidget({required this.events, super.key});

  final List<ActivityEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('এখনও কোনো activity নেই', style: AppTextStyles.bodySmall),
      );
    }

    return Column(
      children: events
          .map(
            (event) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _labelFor(event.action),
                          style: AppTextStyles.bodyStrong,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            event.userName,
                            _timeLabel(event.createdAt),
                          ].whereType<String>().join(' · '),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _labelFor(String action) {
    switch (action) {
      case 'item.purchased':
        return 'আইটেম কেনা হয়েছে';
      case 'item.not_found':
        return 'আইটেম পাওয়া যায়নি';
      case 'item.updated':
        return 'আইটেম আপডেট হয়েছে';
      case 'bazar.started':
        return 'বাজার শুরু হয়েছে';
      case 'bazar.closed':
        return 'বাজার শেষ হয়েছে';
      default:
        return action;
    }
  }

  String _timeLabel(DateTime value) {
    final now = DateTime.now();
    final difference = now.difference(value);
    if (difference.inMinutes < 1) {
      return 'এইমাত্র';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} মিনিট আগে';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} ঘন্টা আগে';
    }
    return '${difference.inDays} দিন আগে';
  }
}
