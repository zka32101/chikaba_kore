/// クチコミ投稿画面の入力中の下書き（施設ごとに1件）。Hive（CacheService）に
/// ローカル保存し、投稿完了前に画面を閉じても次回続きから書けるようにする。
class ReviewDraft {
  final int rating;
  final String text;

  const ReviewDraft({required this.rating, required this.text});

  /// 評価もコメントも未入力なら保存する意味がない下書き
  bool get isEmpty => rating == 0 && text.trim().isEmpty;

  factory ReviewDraft.fromJson(Map<String, dynamic> json) => ReviewDraft(
        rating: json['rating'] as int? ?? 0,
        text: json['text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'rating': rating, 'text': text};
}
