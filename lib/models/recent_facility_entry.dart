import 'facility_model.dart';

/// 「最近見た施設」のローカル履歴1件分。一覧カード表示に必要な最小限の
/// フィールドのみを保持し、Hive（CacheService）にJSONとして保存する。
class RecentFacilityEntry {
  final String id;
  final String name;
  final String category;
  final String thumbnailUrl;

  const RecentFacilityEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.thumbnailUrl,
  });

  factory RecentFacilityEntry.fromFacility(FacilityModel facility) =>
      RecentFacilityEntry(
        id: facility.id,
        name: facility.name,
        category: facility.category,
        thumbnailUrl: facility.thumbnailUrl,
      );

  factory RecentFacilityEntry.fromJson(Map<String, dynamic> json) =>
      RecentFacilityEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? 'service',
        thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'thumbnailUrl': thumbnailUrl,
      };
}
