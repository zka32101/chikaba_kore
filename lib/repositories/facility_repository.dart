import '../models/facility_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class FacilityRepository {
  final FirestoreService _firestore;
  final LocationService _location;

  FacilityRepository(this._firestore, this._location);

  Future<List<FacilityModel>> getFeedByCategory(
    String category, {
    int limit = 20,
    int offset = 0,
  }) =>
      _firestore.getFacilitiesByCategory(category, limit: limit, offset: offset);

  Future<List<FacilityModel>> getNearby({String? category}) async {
    final loc = await _location.getCurrentLocation();
    return _firestore.getNearbyFacilities(
      lat: loc.latitude,
      lng: loc.longitude,
      category: category,
    );
  }

  Future<FacilityModel?> getById(String id) => _firestore.getFacility(id);

  Future<List<FacilityModel>> search({
    required String query,
    String? category,
    bool openNowOnly = false,
  }) =>
      _firestore.searchFacilities(
        query: query,
        category: category,
        openNowOnly: openNowOnly,
      );

  /// ガチャ用：フィルタなしで全施設を取得
  Future<List<FacilityModel>> getAllFacilities() =>
      _firestore.getAllFacilities();
}
