import '../../domain/entities/comment_thread_entry.dart';

class CommentsMockDataSource {
  const CommentsMockDataSource();

  List<CommentThreadEntry> comments() {
    return const [
      CommentThreadEntry(
        id: 'c1',
        user: 'CEO',
        avatar: 'CE',
        timeLabel: '১০:৩২ AM',
        message: 'দুধ Aarong full cream হলে ভালো, না পেলে Milk Vita চলবে।',
        isOwner: true,
      ),
      CommentThreadEntry(
        id: 'c2',
        user: 'Rahim',
        avatar: 'RU',
        timeLabel: '১০:৪৫ AM',
        message: 'Aarong পাওয়া গেছে। গরুর মাংস নেই, চিকেন নেব?',
        isOwner: false,
      ),
      CommentThreadEntry(
        id: 'c3',
        user: 'CEO',
        avatar: 'CE',
        timeLabel: '১০:৫২ AM',
        message: 'হ্যাঁ, চিকেন ১.৫ কেজি নাও।',
        isOwner: true,
      ),
      CommentThreadEntry(
        id: 'c4',
        user: 'Rahim',
        avatar: 'RU',
        timeLabel: '১১:২০ AM',
        message: '✓ চিকেন ১.৫ কেজি নেওয়া হয়েছে — ৳ ৩৬০',
        isOwner: false,
      ),
    ];
  }

  PriceHistorySummary priceHistory() {
    return const PriceHistorySummary(
      itemName: 'ডিম',
      unit: 'টা',
      entries: [
        PriceHistoryEntry(
          dateLabel: '২৩ মে ২০২৫',
          quantityLabel: '৩০টা',
          price: 210,
          bazarName: 'CEO Personal',
          buyerName: 'Rahim',
          perUnit: 7.0,
        ),
        PriceHistoryEntry(
          dateLabel: '১৫ মে ২০২৫',
          quantityLabel: '৩০টা',
          price: 200,
          bazarName: 'Office Lunch',
          buyerName: 'Karim',
          perUnit: 6.67,
        ),
        PriceHistoryEntry(
          dateLabel: '৮ মে ২০২৫',
          quantityLabel: '২০টা',
          price: 130,
          bazarName: 'CEO Personal',
          buyerName: 'Rahim',
          perUnit: 6.5,
        ),
        PriceHistoryEntry(
          dateLabel: '১ মে ২০২৫',
          quantityLabel: '৩০টা',
          price: 195,
          bazarName: 'Office Lunch',
          buyerName: 'Karim',
          perUnit: 6.5,
        ),
        PriceHistoryEntry(
          dateLabel: '২২ এপ্রিল',
          quantityLabel: '৩০টা',
          price: 190,
          bazarName: 'CEO Personal',
          buyerName: 'Rahim',
          perUnit: 6.33,
        ),
        PriceHistoryEntry(
          dateLabel: '১৫ এপ্রিল',
          quantityLabel: '৩০টা',
          price: 185,
          bazarName: 'Office Lunch',
          buyerName: 'Rahim',
          perUnit: 6.17,
        ),
      ],
    );
  }
}
