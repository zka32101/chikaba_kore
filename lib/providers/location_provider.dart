import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'facility_provider.dart';

final currentLocationProvider = FutureProvider((ref) async {
  final service = ref.watch(locationServiceProvider);
  return service.getCurrentLocation();
});
