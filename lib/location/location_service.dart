import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<bool> _checkPermission() async {
    final status = await Permission.locationWhenInUse.status;

    if (status.isGranted) return true;

    final result = await Permission.locationWhenInUse.request();
    return result.isGranted;
  }

  Future<Position> getCurrentPosition() async {
    final hasPermission = await _checkPermission();

    if (!hasPermission) {
      throw Exception('Permiso de ubicación denegado');
    }

    final isLocationEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!isLocationEnabled) {
      throw Exception('GPS desactivado');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print(position);
    return position;
  }
}
