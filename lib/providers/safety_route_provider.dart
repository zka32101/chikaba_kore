import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_route_search_service.dart';
import '../models/route_result.dart';
import '../services/road_network_repository.dart';
import '../services/route_search_service.dart';
import 'auth_provider.dart';
import 'firebase_provider.dart';
import 'location_provider.dart';

final roadNetworkRepositoryProvider = Provider<RoadNetworkRepository>(
  (ref) => RoadNetworkRepository(),
);

final routeSearchServiceProvider = Provider<RouteSearchService>((ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  if (!firebaseAvailable) {
    return LocalRouteSearchService(ref.watch(roadNetworkRepositoryProvider));
  }
  return RemoteRouteSearchService(
    FirebaseFunctions.instance,
    ref.watch(authServiceProvider),
  );
});

/// 現在地周辺の安心ルート（あんしんみち由来の機能）を検索する。
/// 地図タブの「安全ルートを探す」モード（`docs/PHASE3_MODE_INTEGRATION_DESIGN.md`参照）で使用。
final safetyRouteProvider = FutureProvider.autoDispose<RouteResult?>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  final service = ref.watch(routeSearchServiceProvider);
  return service.searchNearbyComfortRoute(
    currentLat: location.latitude,
    currentLon: location.longitude,
  );
});
