import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';

class Vehicle {
  final String number;
  final String bookingId;
  final DateTime? currentBookingEnd;

  Vehicle({
    required this.number,
    required this.bookingId,
    this.currentBookingEnd,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle &&
          runtimeType == other.runtimeType &&
          number == other.number;

  @override
  int get hashCode => number.hashCode;
}

class TimeExtensionProvider extends ChangeNotifier {
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _error;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchVehicles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
            '${AppConstants.baseUrl}/booking/getAll'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final Map<String, Vehicle> vehicleMap = {};

        for (var booking in data) {
          try {
            final vehicleNumber = booking['vehicle_number']?.toString();
            final bookingId =
                booking['_id']?.toString() ?? booking['id']?.toString();
            final toDateStr = booking['to_date']?.toString();

            if (vehicleNumber != null &&
                vehicleNumber.isNotEmpty &&
                bookingId != null) {
              DateTime? currentBookingEnd;

              if (toDateStr != null && toDateStr.isNotEmpty) {
                try {
                  // Try parsing the date string
                  currentBookingEnd = DateTime.parse(toDateStr);
                  // If parsing succeeds but year is 1, treat as null
                  if (currentBookingEnd.year == 1) {
                    currentBookingEnd = null;
                  }
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint('Error parsing date $toDateStr: $e');
                  }
                  currentBookingEnd = null;
                }
              }

              // Keep the booking with the latest end date
              final existingVehicle = vehicleMap[vehicleNumber];
              if (existingVehicle == null ||
                  (currentBookingEnd != null &&
                      (existingVehicle.currentBookingEnd == null ||
                          currentBookingEnd
                              .isAfter(existingVehicle.currentBookingEnd!)))) {
                vehicleMap[vehicleNumber] = Vehicle(
                  number: vehicleNumber,
                  bookingId: bookingId,
                  currentBookingEnd: currentBookingEnd,
                );
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error processing booking: $e');
            }
          }
        }

        _vehicles = vehicleMap.values.toList();
        _vehicles.sort((a, b) => a.number.compareTo(b.number));
      } else {
        _error = 'Failed to load vehicles: ${response.statusCode}';
        if (kDebugMode) {
          debugPrint('API Error: ${response.body}');
        }
      }
    } catch (e) {
      _error = 'Error fetching vehicles: ${e.toString()}';
      if (kDebugMode) {
        debugPrint('Network Error: $e');
      }
      _vehicles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitExtension({
    required String vehicleNumber,
    required String bookingId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final format = DateFormat('yyyy-MM-dd');

      final payload = {
        'vehicle_number': vehicleNumber,
        'from_date': format.format(fromDate),
        'to_date': format.format(toDate),
      };

      if (kDebugMode) {
        debugPrint('Submitting extension for booking: $bookingId');
        debugPrint('Payload: $payload');
      }

      final response = await http.put(
        Uri.parse(
            '${AppConstants.baseUrl}/booking/extend-time/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (kDebugMode) {
        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          if (kDebugMode) {
            debugPrint('API Error: $errorMessage');
          }
        } catch (_) {
          if (kDebugMode) {
            debugPrint('Raw error response: ${response.body}');
          }
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error submitting extension: $e');
      }
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearVehicles() {
    _vehicles = [];
    notifyListeners();
  }
}
