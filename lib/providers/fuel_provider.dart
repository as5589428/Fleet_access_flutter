import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../models/fuel_model.dart';
import '../core/constants/app_constants.dart';

class FuelProvider extends ChangeNotifier {
  List<FuelEntry> _fuelEntries = [];
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  bool _vehiclesLoading = false;
  String? _error;
  String? _apiError;

  List<FuelEntry> get fuelEntries => _fuelEntries;
  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  bool get vehiclesLoading => _vehiclesLoading;
  String? get error => _error;
  String? get apiError => _apiError;

  static const String baseUrl = AppConstants.baseUrl;
  static const String vehicleBaseUrl = '${AppConstants.baseUrl}/booking';

  Future<void> loadFuelEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fuel/get'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Load Fuel Entries Response: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map && responseData.containsKey('data')) {
          final entriesData = responseData['data'];
          if (entriesData is List) {
            _fuelEntries = entriesData.map<FuelEntry>((item) {
              final itemMap = item as Map<String, dynamic>;
              return FuelEntry.fromJson(itemMap);
            }).toList();
            debugPrint('Loaded ${_fuelEntries.length} fuel entries');
          } else {
            _error = 'Invalid data format: expected array';
          }
        } else if (responseData is List) {
          _fuelEntries = responseData.map<FuelEntry>((item) {
            final itemMap = item as Map<String, dynamic>;
            return FuelEntry.fromJson(itemMap);
          }).toList();
          debugPrint('Loaded ${_fuelEntries.length} fuel entries');
        } else {
          _error = 'Unexpected API response format';
        }
      } else {
        _error = 'Server error: ${response.statusCode} - ${response.body}';
        debugPrint('Server error: ${response.body}');
      }
    } catch (e) {
      _error = 'Failed to connect to server: $e';
      debugPrint('Error loading fuel entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch vehicle numbers from API
  Future<void> loadVehicles() async {
    _vehiclesLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$vehicleBaseUrl/dropdown/vehicleNumber'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Vehicle API Response Status: ${response.statusCode}');
      debugPrint('Vehicle API Response: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        _vehicles = [];

        if (data is Map && data.containsKey('data')) {
          final vehicleData = data['data'];
          if (vehicleData is List) {
            final List<Vehicle> loadedVehicles = [];
            final Set<String> seenNumbers = {};

            for (var item in vehicleData) {
              if (item is Map<String, dynamic>) {
                final vehicle = Vehicle.fromJson(item);
                if (vehicle.vehicleNumber.isNotEmpty && !seenNumbers.contains(vehicle.vehicleNumber)) {
                  loadedVehicles.add(vehicle);
                  seenNumbers.add(vehicle.vehicleNumber);
                }
              } else if (item is String && item.trim().isNotEmpty) {
                final number = item.trim();
                if (!seenNumbers.contains(number)) {
                  loadedVehicles.add(Vehicle(
                    vehicleId: number,
                    vehicleNumber: number,
                    vehicleType: '',
                    bookingColorCode: '',
                    fuelType: [],
                  ));
                  seenNumbers.add(number);
                }
              }
            }

            _vehicles = loadedVehicles;
            _vehicles.sort((a, b) => a.vehicleNumber.compareTo(b.vehicleNumber));
            debugPrint('Loaded ${_vehicles.length} unique vehicles with full data');
          }
        }
      } else {
        debugPrint('Failed to load vehicles: ${response.statusCode}');
        _vehicles = [];
      }
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
      _vehicles = [];
    } finally {
      _vehiclesLoading = false;
      notifyListeners();
    }
  }

  // Get vehicle by number
  Vehicle? getVehicleByNumber(String vehicleNumber) {
    try {
      return _vehicles.firstWhere(
        (vehicle) => vehicle.vehicleNumber == vehicleNumber,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> addFuelEntry(FuelEntry entry, {File? fuelBill}) async {
    _isLoading = true;
    _apiError = null;
    notifyListeners();

    try {
      // Create a multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/fuel/create'),
      );

      debugPrint('\n=== CREATING FUEL ENTRY (Based on Postman API) ===');
      debugPrint('Sending EXACT fields that API expects:');
      debugPrint('1. vehicle_id: ${entry.vehicleId}');
      debugPrint('2. vehicle_number: ${entry.vehicleNumber}');
      debugPrint('3. fuel_type: ${entry.fuelType}');
      debugPrint('4. price: ${entry.price} (as string: ${entry.price.toString()})');
      debugPrint('5. unit: ${entry.unit}');
      debugPrint('6. km: ${entry.km} (as string: ${entry.km.toString()})');
      debugPrint('7. bill_file: ${fuelBill != null ? "Yes" : "No"}');

      // **CRITICAL: Send EXACT fields that Postman shows**
      // All fields MUST be strings (as shown in Postman)
      request.fields['vehicle_id'] = entry.vehicleId;
      request.fields['vehicle_number'] = entry.vehicleNumber;
      request.fields['fuel_type'] = entry.fuelType;
      request.fields['price'] = entry.price.toString(); // Convert to string
      request.fields['unit'] = entry.unit;
      request.fields['km'] = entry.km.toString(); // Convert to string

      // **NOTE: Based on Postman, DO NOT send these fields:**
      // - remarks (not in Postman)
      // - date/created_at (not in Postman)
      // - added_by (not in Postman)

      // Only send remarks if API actually supports it (check your backend)
      // if (entry.remarks != null && entry.remarks!.isNotEmpty) {
      //   request.fields['remarks'] = entry.remarks!;
      // }

      // Add fuel bill if provided - Note: Postman shows field name as "bill_url"
      // but it's actually a file upload field
      if (fuelBill != null && await fuelBill.exists()) {
        try {
          final mimeType = lookupMimeType(fuelBill.path) ?? 'image/jpeg';
          final contentType = MediaType.parse(mimeType);

          final fileExtension = fuelBill.path.split('.').last.toLowerCase();
          final timestamp = DateTime.now().millisecondsSinceEpoch;

          var multipartFile = await http.MultipartFile.fromPath(
            'bill_url', // Field name from Postman (even though it says "bill_url", it's a file field)
            fuelBill.path,
            filename: 'fuel_bill_$timestamp.$fileExtension',
            contentType: contentType,
          );
          request.files.add(multipartFile);
          debugPrint('âœ… Added bill file: ${fuelBill.path}');
        } catch (e) {
          debugPrint('âŒ Error adding bill file: $e');
        }
      } else {
        debugPrint('â„¹ï¸ No bill file provided (optional)');
      }

      // Print all fields being sent
      debugPrint('\n=== FINAL REQUEST FIELDS ===');
      request.fields.forEach((key, value) {
        debugPrint('$key: $value (type: ${value.runtimeType})');
      });
      debugPrint('Files count: ${request.files.length}');
      debugPrint('===========================\n');

      // Send request
      debugPrint('ðŸš€ Sending POST request to: $baseUrl/fuel/create');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('ðŸ“¥ Response Status: ${response.statusCode}');
      debugPrint('ðŸ“¥ Response Body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseBody = response.body;

          if (responseBody.contains('<!DOCTYPE html>')) {
            _apiError =
                'Server returned HTML error page (500 Internal Server Error)';
            debugPrint('❌ Server returned 500 error');
            return false;
          }

          final dynamic data = json.decode(responseBody);
          debugPrint('✅ Success response! Parsing data...');

          if (data is Map) {
            final dataMap = Map<String, dynamic>.from(data);
            
            // Extract the actual fuel entry data
            Map<String, dynamic>? entryData;
            
            if (dataMap.containsKey('data') && dataMap['data'] is Map) {
              entryData = Map<String, dynamic>.from(dataMap['data']);
            } else if (dataMap.containsKey('fuelEntry') && dataMap['fuelEntry'] is Map) {
              entryData = Map<String, dynamic>.from(dataMap['fuelEntry']);
            } else if (dataMap.containsKey('_id') || dataMap.containsKey('id')) {
              // The map itself is the entry
              entryData = dataMap;
            }

            if (entryData != null) {
              final newEntry = FuelEntry.fromJson(entryData);
              _fuelEntries.insert(0, newEntry);
              notifyListeners();
              debugPrint('✅ Fuel entry added and parsed successfully!');
              return true;
            }

            // Fallback: If we can't find entry data but it's 200/201, it likely succeeded
            debugPrint('⚠️ Could not parse entry data from response, but status is success.');
            // Refresh list to be sure
            loadFuelEntries();
            return true;
          }

          return true; // Assume success for 200/201 even if not a Map
        } catch (e) {
          debugPrint('⚠️ Error parsing success response: $e');
          // Still return true because status was 200/201
          loadFuelEntries();
          return true;
        }
      } else {
        // Handle error
        _apiError = 'Server error: ${response.statusCode}';

        // Try to parse error message
        if (response.body.isNotEmpty) {
          if (response.body.contains('<!DOCTYPE html>')) {
            // HTML error page - backend crashed
            debugPrint('âŒ Backend server crashed with 500 error');
            debugPrint('This usually means:');
            debugPrint('1. Missing required field');
            debugPrint('2. Invalid data type');
            debugPrint('3. Database constraint violation');
            debugPrint('4. Backend validation error');

            // Try to extract more info
            final errorMatch =
                RegExp(r'<pre>(.*?)</pre>').firstMatch(response.body);
            if (errorMatch != null) {
              _apiError = 'Server error: ${errorMatch.group(1)}';
            }
          } else {
            try {
              final dynamic errorData = json.decode(response.body);
              if (errorData is Map) {
                final errorMap = errorData;
                _apiError = errorMap['message']?.toString() ??
                    errorMap['error']?.toString() ??
                    errorMap['errors']?.toString() ??
                    _apiError;
              }
            } catch (e) {
              // If can't parse as JSON, show raw body
              _apiError =
                  response.body.length < 500 ? response.body : _apiError;
            }
          }
        }

        debugPrint('âŒ API Error ($_apiError)');
        return false;
      }
    } catch (e) {
      _apiError = 'Failed to connect: $e';
      debugPrint('âŒ Exception: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateFuelEntry(String id, FuelEntry entry,
      {File? fuelBill}) async {
    _isLoading = true;
    _apiError = null;
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/fuel/update/$id'),
      );

      debugPrint('Updating fuel entry $id');

      // Get form data from entry
      final formData = entry.toFormData();
      formData.forEach((key, value) {
        request.fields[key] = value;
      });

      if (fuelBill != null && await fuelBill.exists()) {
        final mimeType = lookupMimeType(fuelBill.path) ?? 'image/jpeg';
        final contentType = MediaType.parse(mimeType);

        var multipartFile = await http.MultipartFile.fromPath(
          'fuel_bill',
          fuelBill.path,
          filename:
              'fuel_bill_${DateTime.now().millisecondsSinceEpoch}.${fuelBill.path.split('.').last}',
          contentType: contentType,
        );
        request.files.add(multipartFile);
        debugPrint('Adding file for update');
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('Update Fuel API Response: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        final Map<String, dynamic> entryData;

        if (data is Map) {
          final dataMap = data;
          if (dataMap.containsKey('data')) {
            final dynamic responseData = dataMap['data'];
            if (responseData is Map) {
              entryData = Map<String, dynamic>.from(responseData);
            } else {
              entryData = Map<String, dynamic>.from(dataMap);
            }
          } else {
            entryData = Map<String, dynamic>.from(dataMap);
          }

          final index = _fuelEntries.indexWhere((e) => e.id == id);
          if (index != -1) {
            final updatedEntry = FuelEntry.fromJson(entryData);
            _fuelEntries[index] = updatedEntry;
            notifyListeners();
          }
          return true;
        } else {
          _apiError = 'Invalid response format';
          return false;
        }
      } else {
        _apiError = 'Server error: ${response.statusCode} - ${response.body}';
        debugPrint('API Error: $_apiError');
        return false;
      }
    } catch (e) {
      _apiError = 'Failed to connect to server: $e';
      debugPrint('Exception: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteFuelEntry(String id) async {
    _isLoading = true;
    _apiError = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/fuel/delete/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Delete Fuel API Response: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _fuelEntries.removeWhere((e) => e.id == id);
        notifyListeners();
        return true;
      } else {
        _apiError = 'Server error: ${response.statusCode} - ${response.body}';
        return false;
      }
    } catch (e) {
      _apiError = 'Failed to connect to server: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    _apiError = null;
    notifyListeners();
  }

  void clearApiError() {
    _apiError = null;
    notifyListeners();
  }
}
