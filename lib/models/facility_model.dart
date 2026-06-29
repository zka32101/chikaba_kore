import 'package:cloud_firestore/cloud_firestore.dart';

class FacilityModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String address;
  final String phone;
  final String? website;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final Map<String, String> businessHours;
  final bool isOpenNow;
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  // 差別化機能：穴波スコア関連
  final double eccentricityScore; // 0-100 (評価高い × レビュー少ない × 地元民率高い)
  final double localReviewRatio; // 0-100 (地元民レビュー数 / 総レビュー数)
  final int localReviewCount; // 地元民からのレビュー数

  const FacilityModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.phone,
    this.website,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.businessHours,
    required this.isOpenNow,
    required this.averageRating,
    required this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
    this.eccentricityScore = 0.0,
    this.localReviewRatio = 0.0,
    this.localReviewCount = 0,
  });

  factory FacilityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['location'] as GeoPoint;
    return FacilityModel(
      id: doc.id,
      name: data['name'] as String,
      category: data['category'] as String,
      description: data['description'] as String? ?? '',
      address: data['address'] as String,
      phone: data['phone'] as String? ?? '',
      website: data['website'] as String?,
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      businessHours: Map<String, String>.from(data['businessHours'] as Map? ?? {}),
      isOpenNow: data['isOpenNow'] as bool? ?? false,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      eccentricityScore: (data['eccentricityScore'] as num?)?.toDouble() ?? 0.0,
      localReviewRatio: (data['localReviewRatio'] as num?)?.toDouble() ?? 0.0,
      localReviewCount: data['localReviewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'description': description,
        'address': address,
        'phone': phone,
        'website': website,
        'location': GeoPoint(latitude, longitude),
        'imageUrls': imageUrls,
        'businessHours': businessHours,
        'isOpenNow': isOpenNow,
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'eccentricityScore': eccentricityScore,
        'localReviewRatio': localReviewRatio,
        'localReviewCount': localReviewCount,
      };

  String get thumbnailUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
}
