import 'package:geolocator/geolocator.dart';

class LocationHelper {
  // This function will return the user's current location (latitude & longitude)
  static Future<Position?> getCurrentLocation() async {
    // Check if location services (like GPS) are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // If not enabled, return null
      return null;
    }

    // Check and request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // If permission is denied again, return null
        return null;
      }
    }

    // If permission is permanently denied
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // If everything is good, get the current location
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
