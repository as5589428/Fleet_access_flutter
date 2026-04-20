// lib/services/booking/booking_api_service.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});
}

class BookingApiService {
  static const String baseUrl = AppConstants.baseUrl;

  static final BookingApiService _instance = BookingApiService._internal();
  factory BookingApiService() => _instance;
  BookingApiService._internal();

  http.Client get client => http.Client();
  void dispose() {
    client.close();
  }

  // Headers for all requests
  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey) ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  Future<ApiResponse<List<String>>> getVehicleTypes() async {
    try {
      debugPrint('Fetching vehicle types from: $baseUrl/booking/vehicle-types');

      final response = await client
          .get(
            Uri.parse('$baseUrl/booking/vehicle-types'),
            headers: await _headers,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Vehicle types response status: ${response.statusCode}');
      debugPrint('Vehicle types response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<String> vehicleTypes = [];

        if (decoded is Map && decoded['data'] is List) {
          final List<dynamic> dataList = decoded['data'] as List;

          for (var item in dataList) {
            if (item is Map && item['vehicle_type'] is List) {
              final types = item['vehicle_type'] as List;
              for (var type in types) {
                final typeStr = type?.toString();
                if (typeStr != null && typeStr.isNotEmpty) {
                  vehicleTypes.add(typeStr);
                }
              }
            }
          }
        } else if (decoded is List) {
          vehicleTypes = decoded.map((e) => e.toString()).toList();
        }

        // Remove duplicates
        vehicleTypes = vehicleTypes.toSet().toList();

        debugPrint('Successfully fetched vehicle types: $vehicleTypes');
        return ApiResponse(
          success: true,
          message: 'Vehicle types fetched successfully',
          data: vehicleTypes,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to fetch vehicle types: ${response.statusCode}',
          data: [],
        );
      }
    } catch (e) {
      debugPrint('Error fetching vehicle types: $e');
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
      );
    }
  }

  // Get Bookings
  Future<ApiResponse<List<Map<String, dynamic>>>> getBookings() async {
    try {
      debugPrint('Fetching bookings from: $baseUrl/booking/getAll');

      final response = await client
          .get(
            Uri.parse('$baseUrl/booking/getAll'),
            headers: await _headers,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint('Response type: ${decoded.runtimeType}');

        List<Map<String, dynamic>> bookings = [];

        if (decoded is List) {
          debugPrint('Response is a List with ${decoded.length} items');
          for (var item in decoded) {
            if (item is Map<String, dynamic>) {
              bookings.add(item);
            } else if (item is Map) {
              bookings.add(Map<String, dynamic>.from(item));
            }
          }
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            final dataList = decoded['data'] as List;
            debugPrint('Response has data field with ${dataList.length} items');
            for (var item in dataList) {
              if (item is Map<String, dynamic>) {
                bookings.add(item);
              } else if (item is Map) {
                bookings.add(Map<String, dynamic>.from(item));
              }
            }
          } else if (decoded.containsKey('_id')) {
            bookings.add(decoded);
          }
        }

        debugPrint('Successfully parsed ${bookings.length} bookings');
        return ApiResponse(
          success: true,
          message: 'Bookings fetched successfully',
          data: bookings,
        );
      } else {
        final errorMessage = 'Failed to fetch bookings: ${response.statusCode}';
        debugPrint(errorMessage);
        return ApiResponse(
          success: false,
          message: errorMessage,
          data: [],
        );
      }
    } catch (e) {
      debugPrint('Error in getBookings: $e');
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
      );
    }
  }

  // Get Vehicles with details (including status and seating capacity)
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicles() async {
    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/booking/dropdown/vehicleNumber'),
            headers: await _headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<Map<String, dynamic>> vehicles = [];

        if (decoded is Map && decoded['data'] is List) {
          final dataList = decoded['data'] as List;
          for (var item in dataList) {
            if (item is Map<String, dynamic>) {
              vehicles.add(item);
            } else if (item is Map) {
              vehicles.add(Map<String, dynamic>.from(item));
            }
          }
        }

        debugPrint('Fetched ${vehicles.length} vehicles with details');
        return ApiResponse(
          success: true,
          message: 'Vehicles fetched successfully',
          data: vehicles,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to fetch vehicles: ${response.statusCode}',
          data: [],
        );
      }
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
      );
    }
  }

  // Get Dropdown Data
  Future<ApiResponse<Map<String, List<String>>>> getDropdownData() async {
    try {
      final urls = [
        '$baseUrl/booking/dropdown/vehicleNumber',
        '$baseUrl/booking/vehicle-types',
        '$baseUrl/booking/dropdown/users',
        '$baseUrl/booking/dropdown/roles',
        '$baseUrl/booking/dropdown/client-supplier',
      ];

      final h = await _headers;
      final responses =
          await Future.wait(urls.map((url) => client.get(Uri.parse(url), headers: h)));

      Map<String, List<String>> dropdownData = {
        'vehicles': [],
        'vehicleTypes': [],
        'employees': [],
        'roles': [],
        'customers': [],
      };

      for (int i = 0; i < responses.length; i++) {
        if (responses[i].statusCode == 200) {
          try {
            final decoded = jsonDecode(responses[i].body);

            switch (i) {
              case 0: // vehicles
                if (decoded is Map && decoded['data'] is List) {
                  final List<dynamic> dataList = decoded['data'] as List;
                  final List<String> vehicles = [];
                  for (var item in dataList) {
                    if (item is Map) {
                      final vehicle = item['vehicle_number']?.toString();
                      if (vehicle != null && vehicle.isNotEmpty) {
                        vehicles.add(vehicle);
                      }
                    }
                  }
                  dropdownData['vehicles'] = vehicles;
                }
                break;

              case 1: // vehicle types
                if (decoded is Map && decoded['data'] is List) {
                  final List<dynamic> dataList = decoded['data'] as List;
                  final List<String> vehicleTypes = [];

                  for (var item in dataList) {
                    if (item is Map && item['vehicle_type'] is List) {
                      final types = item['vehicle_type'] as List;
                      for (var type in types) {
                        final typeStr = type?.toString();
                        if (typeStr != null && typeStr.isNotEmpty) {
                          vehicleTypes.add(typeStr);
                        }
                      }
                    }
                  }

                  dropdownData['vehicleTypes'] = vehicleTypes;
                }
                break;

              case 2: // employees
                if (decoded is Map && decoded['data'] is List) {
                  final List<dynamic> dataList = decoded['data'] as List;
                  final List<String> employees = [];
                  for (var item in dataList) {
                    if (item is Map) {
                      final name = item['employee_name']?.toString();
                      if (name != null && name.isNotEmpty) {
                        employees.add(name);
                      }
                    } else {
                      final emp = item?.toString();
                      if (emp != null && emp.isNotEmpty) {
                        employees.add(emp);
                      }
                    }
                  }
                  dropdownData['employees'] = employees;
                }
                break;

              case 3: // roles
                if (decoded is Map && decoded['data'] is List) {
                  final List<dynamic> dataList = decoded['data'] as List;
                  final List<String> roles = [];
                  for (var item in dataList) {
                    final role = item?.toString();
                    if (role != null && role.isNotEmpty) {
                      roles.add(role);
                    }
                  }
                  dropdownData['roles'] = roles;
                }
                break;

              case 4: // customers
                if (decoded is Map && decoded['data'] is List) {
                  final List<dynamic> dataList = decoded['data'] as List;
                  final List<String> customers = [];
                  for (var item in dataList) {
                    final customer = item?.toString();
                    if (customer != null && customer.isNotEmpty) {
                      customers.add(customer);
                    }
                  }
                  dropdownData['customers'] = customers;
                }
                break;
            }
          } catch (e) {
            debugPrint('Error parsing dropdown data $i: $e');
          }
        } else {
          debugPrint('Failed to fetch dropdown data $i: ${responses[i].statusCode}');
        }
      }

      debugPrint('Dropdown data loaded:');
      debugPrint('- Vehicles: ${dropdownData['vehicles']?.length ?? 0}');
      debugPrint('- Vehicle Types: ${dropdownData['vehicleTypes']?.length ?? 0}');
      debugPrint('- Employees: ${dropdownData['employees']?.length ?? 0}');
      debugPrint('- Roles: ${dropdownData['roles']?.length ?? 0}');
      debugPrint('- Customers: ${dropdownData['customers']?.length ?? 0}');

      return ApiResponse(
        success: true,
        message: 'Dropdown data fetched successfully',
        data: dropdownData,
      );
    } catch (e) {
      debugPrint('Network error in getDropdownData: $e');
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        data: {
          'vehicles': [],
          'vehicleTypes': [],
          'employees': [],
          'roles': [],
          'customers': [],
        },
      );
    }
  }

  // CREATE Booking
// CREATE Booking
  Future<ApiResponse<Map<String, dynamic>>> createBooking(
      Map<String, dynamic> bookingData) async {
    try {
      debugPrint('=== SENDING TO API ===');
      debugPrint('URL: $baseUrl/booking/create');
      debugPrint('Full bookingData: $bookingData');
      debugPrint('========================');

      if (bookingData['from_date'] is String &&
          bookingData['from_date'].contains('T')) {
        final dateTime = DateTime.parse(bookingData['from_date']);
        bookingData['from_date'] =
            '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      }

      if (bookingData['to_date'] is String &&
          bookingData['to_date'].contains('T')) {
        final dateTime = DateTime.parse(bookingData['to_date']);
        bookingData['to_date'] =
            '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      }

      // REMOVE THIS CONVERSION - don't change "office" to "Official"
      // if (bookingData['booking_type'] == 'office') {
      //   bookingData['booking_type'] = 'Official';
      // }

      debugPrint('=== FINAL JSON BEING SENT ===');
      final jsonString = jsonEncode(bookingData);
      debugPrint(jsonString);
      debugPrint('=============================');

      final response = await client
          .post(
            Uri.parse('$baseUrl/booking/create'),
            headers: await _headers,
            body: jsonString,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('=== API RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('===================');

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: responseData['message']?.toString() ??
              'Booking created successfully',
          data: responseData,
        );
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        return ApiResponse(
          success: false,
          message:
              responseData['message']?.toString() ?? 'Failed to create booking',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error in createBooking: $e');
      debugPrint('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // UPDATE Booking
  Future<ApiResponse<Map<String, dynamic>>> updateBooking(
      String id, Map<String, dynamic> bookingData) async {
    try {
      final response = await client
          .put(
            Uri.parse('$baseUrl/booking/update/$id'),
            headers: await _headers,
            body: jsonEncode(bookingData),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: responseData['message']?.toString() ??
              'Booking updated successfully',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message:
              responseData['message']?.toString() ?? 'Failed to update booking',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get Filtered Bookings
  Future<ApiResponse<List<Map<String, dynamic>>>> getFilteredBookings({
    String? vehicleType,
    DateTime? startDate,
    DateTime? endDate,
    String? bookingType,
    String? status,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (vehicleType != null && vehicleType.isNotEmpty) {
        queryParams['vehicle_type'] = vehicleType.toLowerCase();
      }

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }

      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      if (bookingType != null && bookingType.isNotEmpty) {
        queryParams['booking_type'] = bookingType;
      }

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final Uri uri = Uri.parse('$baseUrl/booking/filter').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      debugPrint('Fetching filtered bookings from: $uri');

      final response = await client
          .get(
            uri,
            headers: await _headers,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Filter response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint('Filter response type: ${decoded.runtimeType}');

        List<Map<String, dynamic>> bookings = [];

        if (decoded is List) {
          debugPrint('Filter response is a List with ${decoded.length} items');
          for (var item in decoded) {
            if (item is Map<String, dynamic>) {
              bookings.add(item);
            } else if (item is Map) {
              bookings.add(Map<String, dynamic>.from(item));
            }
          }
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            final dataList = decoded['data'] as List;
            debugPrint(
                'Filter response has data field with ${dataList.length} items');
            for (var item in dataList) {
              if (item is Map<String, dynamic>) {
                bookings.add(item);
              } else if (item is Map) {
                bookings.add(Map<String, dynamic>.from(item));
              }
            }
          } else if (decoded.containsKey('_id')) {
            bookings.add(decoded);
          }
        }

        debugPrint('Successfully parsed ${bookings.length} filtered bookings');
        return ApiResponse(
          success: true,
          message: 'Filtered bookings fetched successfully',
          data: bookings,
        );
      } else {
        final errorMessage =
            'Failed to fetch filtered bookings: ${response.statusCode}';
        debugPrint(errorMessage);
        return ApiResponse(
          success: false,
          message: errorMessage,
          data: [],
        );
      }
    } catch (e) {
      debugPrint('Error in getFilteredBookings: $e');
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
      );
    }
  }

  // DELETE Booking
  Future<ApiResponse<Map<String, dynamic>>> deleteBooking(String id) async {
    try {
      final response = await client
          .delete(
            Uri.parse('$baseUrl/booking/delete/$id'),
            headers: await _headers,
          )
          .timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: responseData['message']?.toString() ??
              'Booking deleted successfully',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message:
              responseData['message']?.toString() ?? 'Failed to delete booking',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
  // Add these methods to your BookingApiService class

// Get Vehicle Numbers for dropdown
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicleNumbers() async {
    try {
      debugPrint(
          'Fetching vehicle numbers from: $baseUrl/booking/dropdown/vehicleNumber');

      final response = await client
          .get(
            Uri.parse('$baseUrl/booking/dropdown/vehicleNumber'),
            headers: await _headers,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Vehicle numbers response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<Map<String, dynamic>> vehicles = [];

        if (decoded is Map && decoded['data'] is List) {
          final dataList = decoded['data'] as List;
          for (var item in dataList) {
            if (item is Map<String, dynamic>) {
              vehicles.add(item);
            } else if (item is Map) {
              vehicles.add(Map<String, dynamic>.from(item));
            }
          }
        }

        debugPrint('Successfully fetched ${vehicles.length} vehicle numbers');
        return ApiResponse(
          success: true,
          message: 'Vehicle numbers fetched successfully',
          data: vehicles,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to fetch vehicle numbers: ${response.statusCode}',
          data: [],
        );
      }
    } catch (e) {
      debugPrint('Error fetching vehicle numbers: $e');
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
      );
    }
  }

// Get filtered bookings with advanced filters
  Future<ApiResponse<List<Map<String, dynamic>>>> getFilteredBookingsAdvanced({
    DateTime? startDate,
    DateTime? endDate,
    String? bookingType,
    String? status,
    List<String>? vehicleNumbers,
    List<String>? vehicleTypes,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T').first;
      }

      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T').first;
      }

      if (bookingType != null &&
          bookingType.isNotEmpty &&
          bookingType != 'all') {
        queryParams['bookingType'] = bookingType;
      }

      if (status != null && status.isNotEmpty && status != 'all') {
        queryParams['status'] = status;
      }

      if (vehicleNumbers != null && vehicleNumbers.isNotEmpty) {
        queryParams['vehicleNumbers'] = vehicleNumbers.join(',');
      }

      if (vehicleTypes != null && vehicleTypes.isNotEmpty) {
        queryParams['vehicleTypes'] = vehicleTypes.join(',');
      }

      final Uri uri = Uri.parse('$baseUrl/booking/getAll').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      debugPrint('Fetching filtered bookings from: $uri');
      debugPrint('Query params: $queryParams');

      final response = await client
          .get(
            uri,
            headers: await _headers,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Filter response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<Map<String, dynamic>> bookings = [];

        if (decoded is List) {
          for (var item in decoded) {
            if (item is Map<String, dynamic>) {
              bookings.add(item);
            } else if (item is Map) {
              bookings.add(Map<String, dynamic>.from(item));
            }
          }
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            final dataList = decoded['data'] as List;
            for (var item in dataList) {
              if (item is Map<String, dynamic>) {
                bookings.add(item);
              } else if (item is Map) {
                bookings.add(Map<String, dynamic>.from(item));
              }
            }
          } else if (decoded.containsKey('_id')) {
            bookings.add(decoded);
          }
        }

        debugPrint('Successfully parsed ${bookings.length} filtered bookings');
        return ApiResponse(
          success: true,
          message: 'Filtered bookings fetched successfully',
          data: bookings,
        );
      } else {
        final errorMessage =
            'Failed to fetch filtered bookings: ${response.statusCode}';
        debugPrint(errorMessage);
        return ApiResponse(
          success: false,
          message: errorMessage,
          data: [],
        );
      }
    } catch (e) {
      debugPrint('Error in getFilteredBookingsAdvanced: $e');
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
      );
    }
  }
  // Add this method to BookingApiService class

// Get Vehicles filtered by type
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehiclesByType(
      String vehicleType) async {
    try {
      final uri = Uri.parse('$baseUrl/booking/dropdown/vehicleNumber')
          .replace(queryParameters: {'vehicle_type': vehicleType});

      debugPrint('Fetching vehicles by type: $vehicleType from: $uri');

      final response = await client
          .get(
            uri,
            headers: await _headers,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Vehicle by type response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<Map<String, dynamic>> vehicles = [];

        // Handle response structure (similar to React version)
        if (decoded is Map && decoded['data'] is List) {
          final dataList = decoded['data'] as List;
          for (var item in dataList) {
            if (item is Map<String, dynamic>) {
              vehicles.add(item);
            } else if (item is Map) {
              vehicles.add(Map<String, dynamic>.from(item));
            }
          }
        } else if (decoded is List) {
          for (var item in decoded) {
            if (item is Map<String, dynamic>) {
              vehicles.add(item);
            } else if (item is Map) {
              vehicles.add(Map<String, dynamic>.from(item));
            }
          }
        }

        debugPrint('Fetched ${vehicles.length} vehicles for type: $vehicleType');
        return ApiResponse(
          success: true,
          message: 'Vehicles fetched successfully',
          data: vehicles,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to fetch vehicles: ${response.statusCode}',
          data: [],
        );
      }
    } catch (e) {
      debugPrint('Error fetching vehicles by type: $e');
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
      );
    }
  }
}
