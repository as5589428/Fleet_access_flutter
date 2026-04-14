// dashboard_api_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/dashboard_model.dart';
import '../models/vehicle_model.dart';

class DashboardApiService {
  static const String baseUrl =
      'https://fleet-vehicle-mgmt-backend-2.onrender.com/api';

  final String? authToken;

  DashboardApiService({this.authToken});

  // Fetch main dashboard data (stats, recent bookings, etc.)
  Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      // Fetch all vehicles for stats calculation
      final vehicles = await fetchVehicleData();

      // Fetch recent bookings separately if needed
      final recentBookings = await fetchRecentBookings();

      // Fetch maintenance totals directly using the dedicated endpoints!
      final underMaintenance = await _fetchUnderMaintenance(page: 1, limit: 1);
      final upcomingMaintenance = await _fetchUpcomingMaintenance(page: 1, limit: 1);

      return {
        'vehicles': vehicles,
        'recentBookings': recentBookings,
        'underMaintenanceCount': underMaintenance.total,
        'upcomingMaintenanceCount': upcomingMaintenance.total,
      };
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      throw Exception('Error fetching dashboard data: $e');
    }
  }

  // Fetch all vehicles for stats
  Future<List<VehicleModel>> fetchVehicleData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/filter'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);

        // Handle different response structures
        List<dynamic> vehiclesList = [];
        if (jsonData is Map) {
          vehiclesList = jsonData['data'] ?? [];
        } else if (jsonData is List) {
          vehiclesList = jsonData;
        }

        if (vehiclesList.isNotEmpty) {
          return vehiclesList
              .where((item) => item != null)
              .map((item) => VehicleModel.fromJson(
                  item is Map ? Map<String, dynamic>.from(item) : {}))
              .toList();
        }
        return [];
      } else {
        debugPrint('Failed to fetch vehicle data: ${response.statusCode}');
        throw Exception('Failed to fetch vehicle data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching vehicle data: $e');
      throw Exception('Error fetching vehicle data: $e');
    }
  }

  // Fetch filtered vehicles with pagination
  Future<PaginatedVehicleResponse> fetchFilteredVehicles({
    required String filter,
    int page = 1,
    int limit = 10,
    Map<String, String>? additionalParams,
  }) async {
    try {
      // Parse the filter string and build URL
      if (filter == 'maintenance-insurance') {
        // Special handling for combined maintenance & insurance
        return await _fetchUpcomingMaintenance(
          page: page,
          limit: limit,
          additionalParams: additionalParams,
        );
      } else if (filter == 'MAINTENANCE') {
        // Fetch vehicles under maintenance
        return await _fetchUnderMaintenance(
          page: page,
          limit: limit,
          additionalParams: additionalParams,
        );
      } else {
        // Regular vehicle filter endpoint
        return await _fetchRegularVehicles(
          filter: filter,
          page: page,
          limit: limit,
          additionalParams: additionalParams,
        );
      }
    } catch (e) {
      debugPrint('Error fetching filtered vehicles: $e');
      throw Exception('Failed to fetch filtered vehicles: $e');
    }
  }

  // Fetch regular vehicles with filter
  Future<PaginatedVehicleResponse> _fetchRegularVehicles({
    required String filter,
    required int page,
    required int limit,
    Map<String, String>? additionalParams,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Add filter parameters if filter is not empty
      if (filter.isNotEmpty) {
        final filterParams = filter.split('&');
        for (var param in filterParams) {
          final parts = param.split('=');
          if (parts.length == 2) {
            queryParams[parts[0]] = parts[1];
          }
        }
      }

      // Add any additional params
      if (additionalParams != null) {
        queryParams.addAll(additionalParams);
      }

      final uri = Uri.parse('$baseUrl/vehicles/filter').replace(
        queryParameters: queryParams,
      );

      debugPrint('Fetching regular vehicles: $uri');

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        return _parsePaginatedResponse(jsonData);
      } else {
        debugPrint('Failed to fetch filtered vehicles: ${response.statusCode}');
        throw Exception(
            'Failed to fetch filtered vehicles: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in _fetchRegularVehicles: $e');
      rethrow;
    }
  }

  // Fetch upcoming maintenance vehicles
  Future<PaginatedVehicleResponse> _fetchUpcomingMaintenance({
    required int page,
    required int limit,
    Map<String, String>? additionalParams,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'vehicle_number': additionalParams?['vehicle_number'] ?? '',
        'vehicle_type': additionalParams?['vehicle_type'] ?? '',
        'maintenance_type': additionalParams?['maintenance_type'] ?? '',
        'page': page,
        'limit': limit,
      };

      debugPrint('Fetching upcoming maintenance with body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/vehicles/getUpcomingMaintenanceList'),
        headers: _getHeaders(),
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        return _parsePaginatedResponse(jsonData);
      } else {
        debugPrint(
            'Failed to fetch upcoming maintenance: ${response.statusCode}');
        throw Exception(
            'Failed to fetch upcoming maintenance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in _fetchUpcomingMaintenance: $e');
      rethrow;
    }
  }

  // Fetch vehicles under maintenance
  Future<PaginatedVehicleResponse> _fetchUnderMaintenance({
    required int page,
    required int limit,
    Map<String, String>? additionalParams,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (additionalParams != null) {
        if (additionalParams.containsKey('vehicle_number') &&
            additionalParams['vehicle_number']!.isNotEmpty) {
          queryParams['vehicle_number'] = additionalParams['vehicle_number']!;
        }
        if (additionalParams.containsKey('vehicle_type') &&
            additionalParams['vehicle_type']!.isNotEmpty) {
          queryParams['vehicle_type'] = additionalParams['vehicle_type']!;
        }
      }

      final uri = Uri.parse('$baseUrl/vehicles/getUnderMaintenance').replace(
        queryParameters: queryParams,
      );

      debugPrint('Fetching under maintenance: $uri');

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        return _parsePaginatedResponse(jsonData);
      } else {
        debugPrint('Failed to fetch under maintenance: ${response.statusCode}');
        throw Exception(
            'Failed to fetch under maintenance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in _fetchUnderMaintenance: $e');
      rethrow;
    }
  }

  // Parse paginated response
  PaginatedVehicleResponse _parsePaginatedResponse(dynamic jsonData) {
    List<DashboardVehicle> vehicles = [];
    int total = 0;
    int page = 1;
    int limit = 10;

    try {
      // Handle different response structures
      if (jsonData is Map) {
        // Convert to Map<String, dynamic>
        final Map<String, dynamic> dataMap =
            Map<String, dynamic>.from(jsonData);

        // Check if data is in the response
        if (dataMap.containsKey('data') && dataMap['data'] is List) {
          final List<dynamic> dataList = dataMap['data'] as List;
          vehicles = dataList
              .where((item) => item != null)
              .map((item) => DashboardVehicle.fromJson(
                  item is Map ? Map<String, dynamic>.from(item) : {}))
              .toList();
        }

        // Get pagination info
        if (dataMap.containsKey('pagination') && dataMap['pagination'] is Map) {
          final pagination = Map<String, dynamic>.from(dataMap['pagination']);
          total = pagination['total'] ?? vehicles.length;
          page = pagination['page'] ?? 1;
          limit = pagination['limit'] ?? vehicles.length;
        } else if (dataMap.containsKey('total')) {
          total = dataMap['total'] is int
              ? dataMap['total']
              : int.tryParse(dataMap['total'].toString()) ?? vehicles.length;
        } else {
          total = vehicles.length;
        }

        // Get page and limit from response if available
        if (dataMap.containsKey('page')) {
          page = dataMap['page'] is int
              ? dataMap['page']
              : int.tryParse(dataMap['page'].toString()) ?? 1;
        }

        if (dataMap.containsKey('limit')) {
          limit = dataMap['limit'] is int
              ? dataMap['limit']
              : int.tryParse(dataMap['limit'].toString()) ?? 10;
        }
      } else if (jsonData is List) {
        // If response is directly a list
        vehicles = jsonData
            .where((item) => item != null)
            .map((item) => DashboardVehicle.fromJson(
                item is Map ? Map<String, dynamic>.from(item) : {}))
            .toList();
        total = vehicles.length;
      }
    } catch (e) {
      debugPrint('Error parsing paginated response: $e');
    }

    return PaginatedVehicleResponse(
      data: vehicles,
      total: total,
      page: page,
      limit: limit,
    );
  }

  // Fetch recent bookings
  Future<List<Map<String, dynamic>>> fetchRecentBookings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/booking/getAll'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);

        // Handle different response structures
        List<dynamic> bookings = [];
        if (jsonData is Map) {
          final dataMap = Map<String, dynamic>.from(jsonData);
          bookings = dataMap['data'] ?? [];
        } else if (jsonData is List) {
          bookings = jsonData;
        }

        if (bookings.isNotEmpty) {
          // Filter active bookings and cast to Map<String, dynamic>
          return bookings
              .where((item) =>
                  item is Map &&
                  (item['isactive'] == true || item['isActive'] == true))
              .take(5)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }
        return [];
      } else {
        debugPrint('Failed to fetch recent bookings: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching recent bookings: $e');
      return [];
    }
  }

  // Fetch vehicle numbers for dropdown
  Future<List<Map<String, dynamic>>> fetchVehicleNumbers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/booking/dropdown/vehicleNumber'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);

        // Handle different response structures
        List<dynamic> apiData = [];
        if (jsonData is Map) {
          final dataMap = Map<String, dynamic>.from(jsonData);
          apiData = dataMap['data'] ?? [];
        } else if (jsonData is List) {
          apiData = jsonData;
        }

        if (apiData.isNotEmpty) {
          // Remove duplicates based on vehicle_number
          final Map<String, Map<String, dynamic>> uniqueMap = {};
          for (var item in apiData) {
            if (item is Map && item['vehicle_number'] != null) {
              final mapItem = Map<String, dynamic>.from(item);
              final vehicleNumber = mapItem['vehicle_number'].toString();
              if (!uniqueMap.containsKey(vehicleNumber)) {
                uniqueMap[vehicleNumber] = mapItem;
              }
            }
          }
          return uniqueMap.values.toList();
        }
        return [];
      } else {
        debugPrint('Failed to fetch vehicle numbers: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching vehicle numbers: $e');
      return [];
    }
  }

  // Fetch vehicle types for dropdown
  Future<List<Map<String, dynamic>>> fetchVehicleTypes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/booking/dropdown/vehicleNumber'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);

        // Handle different response structures
        List<dynamic> apiData = [];
        if (jsonData is Map) {
          final dataMap = Map<String, dynamic>.from(jsonData);
          apiData = dataMap['data'] ?? [];
        } else if (jsonData is List) {
          apiData = jsonData;
        }

        if (apiData.isNotEmpty) {
          // Extract unique vehicle types
          final Map<String, Map<String, dynamic>> uniqueTypes = {};
          for (var item in apiData) {
            if (item is Map) {
              final vehicleType = item['vehicle_type'] ?? item['type'];
              if (vehicleType != null) {
                final typeStr = vehicleType.toString();
                if (!uniqueTypes.containsKey(typeStr)) {
                  uniqueTypes[typeStr] = {
                    'vehicle_type': typeStr,
                    'booking_color_code': item['booking_color_code'] ?? 'Gray',
                  };
                }
              }
            }
          }
          return uniqueTypes.values.toList();
        }
        return [];
      } else {
        debugPrint('Failed to fetch vehicle types: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching vehicle types: $e');
      return [];
    }
  }

  // Fetch booking statuses for dropdown
  Future<List<Map<String, dynamic>>> fetchBookingStatuses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/filter'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);

        // Handle different response structures
        List<dynamic> vehicles = [];
        if (jsonData is Map) {
          final dataMap = Map<String, dynamic>.from(jsonData);
          vehicles = dataMap['data'] ?? [];
        } else if (jsonData is List) {
          vehicles = jsonData;
        }

        if (vehicles.isNotEmpty) {
          final Set<String> statusSet = {};
          for (var vehicle in vehicles) {
            if (vehicle is Map && vehicle['booking_status'] != null) {
              statusSet.add(vehicle['booking_status'].toString());
            }
          }
          return statusSet.map((status) => {'status': status}).toList();
        }
        return [];
      } else {
        // Return default statuses if API fails
        return [
          {'status': 'Available'},
          {'status': 'Booked'},
          {'status': 'Not Available'},
        ];
      }
    } catch (e) {
      debugPrint('Error fetching booking statuses: $e');
      return [
        {'status': 'Available'},
        {'status': 'Booked'},
        {'status': 'Not Available'},
      ];
    }
  }

  // Headers helper method
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (authToken?.isNotEmpty == true) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }
}
