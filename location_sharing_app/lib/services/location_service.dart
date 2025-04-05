import 'package:geolocator/geolocator.dart';
import 'package:location_sharing_app/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class LocationService {
  Stream<Position>? _locationStream;
  StreamSubscription<Position>? _locationSubscription;
  final FirestoreService _firestoreService = FirestoreService();

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Stream<Position> getLocationStream() {
    _locationStream ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters
      ),
    );
    return _locationStream!;
  }

  void startSharingLocation(BuildContext context) {
    _locationSubscription = getLocationStream().listen((position) async {
      await _firestoreService.updateUserLocation(
        position.latitude,
        position.longitude,
      );
    });
  }

  void stopSharingLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void dispose() {
    _locationSubscription?.cancel();
  }
}