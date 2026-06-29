import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/facility_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../repositories/facility_repository.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

final facilityRepositoryProvider = Provider<FacilityRepository>(
  (ref) => FacilityRepository(
    ref.watch(firestoreServiceProvider),
    ref.watch(locationServiceProvider),
  ),
);

final selectedCategoryProvider = StateProvider<String>((ref) => 'dining');

final facilityFeedProvider =
    FutureProvider.family<List<FacilityModel>, String>((ref, category) async {
  final repo = ref.watch(facilityRepositoryProvider);
  return repo.getFeedByCategory(category);
});

final nearbyFacilitiesProvider = FutureProvider<List<FacilityModel>>((ref) async {
  final repo = ref.watch(facilityRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  return repo.getNearby(category: category);
});

final facilityDetailProvider =
    FutureProvider.family<FacilityModel?, String>((ref, id) async {
  final repo = ref.watch(facilityRepositoryProvider);
  return repo.getById(id);
});
