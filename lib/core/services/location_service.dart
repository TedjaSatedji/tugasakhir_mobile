import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  LocationService._internal();

  factory LocationService() => _instance;

  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Reverse geocodes coordinates to a short place name.
  /// Returns e.g. "Kelapa Gading, Jakarta" or the raw coordinates as fallback.
  Future<String> getPlaceName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return _coordFallback(latitude, longitude);

      final place = placemarks.first;
      final parts = <String>[
        if (place.name != null && place.name!.isNotEmpty && place.name != place.street)
          place.name!,
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          place.subLocality!,
        if (place.locality != null && place.locality!.isNotEmpty)
          place.locality!,
      ];

      if (parts.isEmpty) return _coordFallback(latitude, longitude);
      return parts.take(2).join(', ');
    } catch (_) {
      return _coordFallback(latitude, longitude);
    }
  }

  String _coordFallback(double lat, double lng) =>
      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
}