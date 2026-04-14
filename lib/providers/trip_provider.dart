import 'package:flutter/material.dart';
import '../models/trip_model.dart';

class TripProvider extends ChangeNotifier {
  List<TripModel> _trips = [];
  bool _isLoading = false;
  String? _error;

  List<TripModel> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTrips({String? status, String? driverId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Demo data - replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      
      _trips = [
        TripModel(
          id: '1',
          bookingId: 'booking1',
          vehicleId: 'vehicle1',
          vehicleNumber: 'KA01AB1234',
          driverId: 'driver1',
          driverName: 'Driver One',
          status: 'IN_PROGRESS',
          startKm: 15000.0,
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
          startLocation: 'Office',
          createdAt: DateTime.now(),
        ),
        TripModel(
          id: '2',
          bookingId: 'booking2',
          vehicleId: 'vehicle2',
          vehicleNumber: 'KA01CD5678',
          driverId: 'driver2',
          driverName: 'Driver Two',
          status: 'COMPLETED',
          startKm: 12000.0,
          endKm: 12150.0,
          startTime: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          endTime: DateTime.now().subtract(const Duration(days: 1)),
          startLocation: 'Office',
          endLocation: 'Client Site',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> startTrip({
    required String tripId,
    required double startKm,
    String? startPhoto,
    String? startLocation,
    String? remarks,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final tripIndex = _trips.indexWhere((t) => t.id == tripId);
      if (tripIndex != -1) {
        _trips[tripIndex] = _trips[tripIndex].copyWith(
          status: 'IN_PROGRESS',
          startKm: startKm,
          startPhoto: startPhoto,
          startLocation: startLocation,
          remarks: remarks,
          startTime: DateTime.now(),
        );
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> endTrip({
    required String tripId,
    required double endKm,
    String? endPhoto,
    String? endLocation,
    String? remarks,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final tripIndex = _trips.indexWhere((t) => t.id == tripId);
      if (tripIndex != -1) {
        _trips[tripIndex] = _trips[tripIndex].copyWith(
          status: 'COMPLETED',
          endKm: endKm,
          endPhoto: endPhoto,
          endLocation: endLocation,
          remarks: remarks,
          endTime: DateTime.now(),
        );
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
