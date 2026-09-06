# API & アーキテクチャドキュメント

**バージョン**: 1.0.0
**最終更新**: 2026年9月

## 目次

- [アーキテクチャ概要](#アーキテクチャ概要)
- [レイヤー構成](#レイヤー構成)
- [Firebase統合](#firebase統合)
- [Google Maps API](#google-maps-api)
- [データモデル](#データモデル)
- [API仕様](#api仕様)
- [状態管理（Riverpod）](#状態管理riverpod)
- [認証フロー](#認証フロー)

## アーキテクチャ概要

近場コレは、**クリーンアーキテクチャ** + **MVVM パターン**に基づいて設計されています。

```
┌─────────────────────────────────────┐
│         UI Layer (Views)            │  ← ユーザーインターフェース
├─────────────────────────────────────┤
│      ViewModel / View Model          │  ← ビジネスロジック
├─────────────────────────────────────┤
│      Repository & UseCase           │  ← ドメイン層
├─────────────────────────────────────┤
│    Service (Firebase, Maps, API)    │  ← 外部サービス連携
├─────────────────────────────────────┤
│      Data Source (Local, Remote)    │  ← データソース
└─────────────────────────────────────┘
```

## レイヤー構成

### 1. Views (UI層)

```
lib/views/
├── screens/           # 画面単位のウィジェット
│   ├── search_screen.dart
│   ├── facility_detail_screen.dart
│   ├── review_screen.dart
│   └── profile_screen.dart
├── widgets/           # 再利用可能なウィジェット
│   ├── facility_card.dart
│   ├── review_item.dart
│   └── rating_bar.dart
└── dialogs/           # ダイアログ・モーダル
    ├── facility_filter_dialog.dart
    └── report_dialog.dart
```

**主要ウィジェット:**

```dart
// 施設検索画面
class FacilitySearchScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilities = ref.watch(facilityProvider);
    // UI 実装
  }
}
```

### 2. ViewModel / Providers (Riverpod)

```
lib/providers/
├── auth_provider.dart          # 認証状態管理
├── facility_provider.dart      # 施設データ管理
├── review_provider.dart        # レビューデータ管理
├── location_provider.dart      # 位置情報管理
└── user_provider.dart          # ユーザープロフィール管理
```

**Provider例:**

```dart
// ユーザー認証状態
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

// 施設一覧（検索条件付き）
final facilityProvider = FutureProvider.autoDispose
  .family<List<Facility>, FacilitySearchQuery>((ref, query) async {
  final repository = ref.watch(facilityRepositoryProvider);
  return repository.searchFacilities(query);
});
```

### 3. Repository (データ層)

```
lib/repositories/
├── facility_repository.dart
├── review_repository.dart
├── user_repository.dart
└── auth_repository.dart
```

**Repository パターン:**

```dart
abstract class FacilityRepository {
  Future<List<Facility>> searchFacilities(FacilitySearchQuery query);
  Future<Facility> getFacilityDetail(String facilityId);
  Future<void> addFavorite(String facilityId);
  Future<void> removeFavorite(String facilityId);
}

class FacilityRepositoryImpl extends FacilityRepository {
  final FirestoreService _firestore;
  final LocalStorageService _localStorage;

  @override
  Future<List<Facility>> searchFacilities(FacilitySearchQuery query) async {
    // 実装
  }
}
```

### 4. Services (サービス層)

#### 4.1 Firebase Service

```dart
class FirestoreService {
  final FirebaseFirestore _firestore;

  // 読み取り
  Future<DocumentSnapshot> getDocument(
    String collection,
    String docId,
  ) async {
    return _firestore.collection(collection).doc(docId).get();
  }

  // 書き込み
  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(docId).set(data);
  }

  // クエリ
  Stream<QuerySnapshot> query(
    String collection,
    QueryBuilder builder,
  ) {
    Query query = _firestore.collection(collection);
    return builder(query).snapshots();
  }
}
```

**Firestore スキーマ:**

```
firestore:
├── users/
│   ├── {uid}
│   │   ├── email: string
│   │   ├── displayName: string
│   │   ├── profileImageUrl: string
│   │   ├── createdAt: timestamp
│   │   └── localBadge: boolean
│
├── facilities/
│   ├── {facilityId}
│   │   ├── name: string
│   │   ├── category: string
│   │   ├── location: GeoPoint
│   │   ├── address: string
│   │   ├── imageUrl: string
│   │   ├── rating: number (0-5)
│   │   ├── reviewCount: number
│   │   ├── createdAt: timestamp
│   │   └── tags: array
│
├── reviews/
│   ├── {reviewId}
│   │   ├── facilityId: string
│   │   ├── userId: string
│   │   ├── rating: number (1-5)
│   │   ├── text: string
│   │   ├── imageUrls: array
│   │   ├── likes: number
│   │   ├── createdAt: timestamp
│   │   └── updatedAt: timestamp
│
├── favorites/
│   ├── {uid}/
│   │   ├── want_to_visit: array<facilityId>
│   │   └── visiting_now: array<facilityId>
```

#### 4.2 Google Maps Service

```dart
class GoogleMapsService {
  final GoogleMapsFlutter _maps;

  // 現在地取得
  Future<LatLng> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  // 距離計算
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  // 逆ジオコーディング（座標→住所）
  Future<String> getAddressFromCoordinates(LatLng location) async {
    final placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );
    return placemarks.first.locality ?? 'Unknown';
  }

  // ルート検索
  Future<DirectionsResult> getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    return GoogleMapsRoutes.getDirections(origin, destination);
  }
}
```

#### 4.3 Authentication Service

```dart
class AuthService {
  final FirebaseAuth _auth;

  // メール認証
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Google Sign-In
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    final googleAuth = await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  // ログアウト
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      GoogleSignIn().signOut(),
    ]);
  }

  // トークン更新
  Future<String> getIdToken() async {
    return _auth.currentUser?.getIdToken() ?? '';
  }
}
```

### 5. Data Models

```dart
// 施設モデル
@freezed
class Facility with _$Facility {
  const factory Facility({
    required String id,
    required String name,
    required String category,
    required GeoPoint location,
    required String address,
    required double rating,
    required int reviewCount,
    required List<String> imageUrls,
    required List<String> tags,
    required DateTime createdAt,
  }) = _Facility;

  factory Facility.fromJson(Map<String, dynamic> json) =>
      _$FacilityFromJson(json);
}

// レビューモデル
@freezed
class Review with _$Review {
  const factory Review({
    required String id,
    required String facilityId,
    required String userId,
    required int rating,
    required String text,
    required List<String> imageUrls,
    required int likes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Review;

  factory Review.fromJson(Map<String, dynamic> json) =>
      _$ReviewFromJson(json);
}
```

## Firebase統合

### Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーデータ
    match /users/{userId} {
      allow read: if isLoggedIn();
      allow create: if isLoggedIn() && request.auth.uid == userId;
      allow update, delete: if request.auth.uid == userId;
    }

    // 施設データ（公開読み取り）
    match /facilities/{facilityId} {
      allow read;
      allow create, update, delete: if isAdmin();
    }

    // レビュー
    match /reviews/{reviewId} {
      allow read;
      allow create: if isLoggedIn();
      allow update, delete: if isReviewAuthor(reviewId);
    }

    // お気に入り
    match /favorites/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // ヘルパー関数
    function isLoggedIn() {
      return request.auth != null;
    }

    function isAdmin() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }

    function isReviewAuthor(reviewId) {
      return get(/databases/$(database)/documents/reviews/$(reviewId)).data.userId == request.auth.uid;
    }
  }
}
```

## Google Maps API

### API キー設定

**Android:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application>
  <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
</application>
```

**iOS:**
```swift
// ios/Runner/GeneratedPluginRegistrant.m
// Xcode で自動設定
```

### 使用例

```dart
// マップウィジェット
GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(35.6762, 139.6503), // 東京
    zoom: 15,
  ),
  markers: facilities.map((f) => Marker(
    markerId: MarkerId(f.id),
    position: f.location.toLatLng(),
    infoWindow: InfoWindow(title: f.name),
  )).toSet(),
  onMapCreated: (controller) {
    // マップコントローラー
  },
)
```

## データモデル

### 主要エンティティ関係図

```
┌──────────────────┐
│      User        │
├──────────────────┤
│ - id             │
│ - email          │
│ - displayName    │
│ - profileImage   │
└────────┬─────────┘
         │
         │ creates
         ▼
┌──────────────────┐         ┌──────────────────┐
│     Review       │◄───────►│    Facility      │
├──────────────────┤         ├──────────────────┤
│ - id             │         │ - id             │
│ - rating         │         │ - name           │
│ - text           │         │ - category       │
│ - imageUrls      │         │ - location       │
│ - likes          │         │ - rating (avg)   │
└──────────────────┘         │ - reviewCount    │
         ▲                    └──────────────────┘
         │
         │ likes
┌────────┴──────────┐
│   Favorite        │
├───────────────────┤
│ - userId          │
│ - facilityId      │
│ - type (want/go)  │
└───────────────────┘
```

## API仕様

### REST API エンドポイント

#### 施設検索

```http
GET /api/v1/facilities?
  latitude=35.6762
  &longitude=139.6503
  &radius=5000
  &category=cafe
  &limit=20
  &offset=0

Content-Type: application/json

{
  "data": [
    {
      "id": "fac_123",
      "name": "カフェ ABC",
      "category": "cafe",
      "location": {
        "latitude": 35.6762,
        "longitude": 139.6503
      },
      "rating": 4.5,
      "reviewCount": 42,
      "imageUrls": ["https://..."],
      "distance": 523
    }
  ],
  "total": 156,
  "hasMore": true
}
```

#### レビュー取得

```http
GET /api/v1/facilities/{facilityId}/reviews?
  limit=10
  &offset=0

{
  "data": [
    {
      "id": "rev_456",
      "userId": "usr_789",
      "rating": 5,
      "text": "素晴らしい雰囲気！",
      "imageUrls": ["https://..."],
      "likes": 12,
      "createdAt": "2026-09-01T10:30:00Z",
      "user": {
        "id": "usr_789",
        "displayName": "山田太郎",
        "profileImage": "https://...",
        "isLocalBadge": true
      }
    }
  ],
  "total": 42
}
```

#### レビュー投稿

```http
POST /api/v1/reviews

Content-Type: multipart/form-data

{
  "facilityId": "fac_123",
  "rating": 4,
  "text": "とても良かったです",
  "images": [File, File, File]
}

Response:
{
  "id": "rev_789",
  "facilityId": "fac_123",
  "userId": "usr_xyz",
  "rating": 4,
  "text": "とても良かったです",
  "imageUrls": ["https://...", "https://..."],
  "createdAt": "2026-09-02T12:00:00Z"
}
```

#### お気に入り管理

```http
POST /api/v1/favorites

{
  "facilityId": "fac_123",
  "type": "want_to_visit"  // or "visiting_now"
}

Response:
{
  "success": true,
  "favoriteId": "fav_123"
}
```

## 状態管理（Riverpod）

### Provider構成

```dart
// Service Provider
final authServiceProvider = Provider((ref) => AuthService());
final firestoreServiceProvider = Provider((ref) => FirestoreService());
final mapsServiceProvider = Provider((ref) => GoogleMapsService());

// Repository Provider
final facilityRepositoryProvider = Provider((ref) {
  return FacilityRepositoryImpl(
    firestore: ref.watch(firestoreServiceProvider),
  );
});

// State Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

// Data Provider（キャッシュ付き）
final currentLocationProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(mapsServiceProvider).getCurrentLocation();
});

final facilitiesProvider = FutureProvider.autoDispose
  .family<List<Facility>, SearchQuery>((ref, query) async {
  return ref.watch(facilityRepositoryProvider).searchFacilities(query);
});
```

## 認証フロー

### ログインフロー

```
┌─────────────────────────────────────────┐
│     ユーザーがログイン画面を訪問        │
└────────────────┬────────────────────────┘
                 │
         ┌───────▼────────┐
         │ ログイン方法選択 │
         └───┬──────┬─────┘
             │      │
    ┌────────┘      └────────┐
    │                         │
    ▼                         ▼
┌──────────────┐      ┌──────────────────┐
│ メール+パス  │      │ Google Sign-In   │
└────┬─────────┘      └────┬─────────────┘
     │                     │
     ▼                     ▼
┌──────────────────────────────────────────┐
│ Firebase Authentication                  │
│ - IDトークン取得                         │
│ - ローカルに保存                         │
└────┬────────────────────────────────────┘
     │
     ▼
┌──────────────────────────────────────────┐
│ Userドキュメント取得/作成                │
│ Firestore: /users/{uid}                  │
└────┬────────────────────────────────────┘
     │
     ▼
┌──────────────────────────────────────────┐
│ ホーム画面へ遷移                         │
│ authProvider更新                         │
└──────────────────────────────────────────┘
```

### トークン更新

```dart
// 自動トークン更新（Firebaseが管理）
FirebaseAuth.instance.idTokenChanges().listen((User? user) {
  if (user != null) {
    final token = await user.getIdToken();
    // API呼び出し時に使用
  }
});
```

---

このドキュメントは定期的に更新されます。
最終更新: 2026年9月
