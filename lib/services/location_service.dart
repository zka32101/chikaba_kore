import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  const LocationResult({required this.latitude, required this.longitude});
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          latitude: AppConstants.defaultLatitude,
          longitude: AppConstants.defaultLongitude,
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
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
