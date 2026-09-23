import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

/// 位置情報の許可状態。姉妹アプリ「あんしんみち」(project-039) の
/// LocationPermissionState と同じ語彙を使い、将来の統合時にAPIを揃えやすくしている。
enum LocationPermissionState {
  notRequested,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class LocationResult {
  final double latitude;
  final double longitude;
  const LocationResult({required this.latitude, required this.longitude});
}

class LocationService {
  /// 位置情報許可を確認・要求する。
  Future<LocationPermissionState> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionState.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationPermissionState.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionState.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionState.granted;
    }
  }

  /// 現在地取得。chikaba_mapは地図全体を常に表示するため、権限が無い場合や
  /// 取得に失敗した場合はデフォルト座標（東京）にフォールバックする。
  Future<LocationResult> getCurrentLocation() async {
    final permissionState = await requestPermission();
    if (permissionState != LocationPermissionState.granted) {
      return const LocationResult(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult(latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      appLogger.w('Location error, using default', error: e);
      return const LocationResult(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
      );
    }
  }

  Stream<LocationResult> watchLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).map((p) => LocationResult(latitude: p.latitude, longitude: p.longitude));
  }
}
