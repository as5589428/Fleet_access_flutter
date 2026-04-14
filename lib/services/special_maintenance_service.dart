// lib/services/special_maintenance_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SpecialMaintenanceService {
  static const String _baseUrl =
      'https://fleet-vehicle-mgmt-backend-2.onrender.com/api';

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Battery Maintenance APIs
  Future<Map<String, dynamic>> getBatteryMaintenance() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/maintenance/battery'),
        headers: headers,
      );

      debugPrint('Battery GET Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception(
            'Failed to fetch battery maintenance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Battery GET Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> addBatteryMaintenance(
      Map<String, dynamic> data) async {
    try {
      final headers = await _getAuthHeaders();
      final body = json.encode(data);
      debugPrint('Battery POST Body: $body');

      final response = await http.post(
        Uri.parse('$_baseUrl/maintenance/battery'),
        headers: headers,
        body: body,
      );

      debugPrint('Battery POST Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception(
            'Failed to add battery maintenance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Battery POST Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> updateBatteryMaintenance(
      String id, Map<String, dynamic> data) async {
    try {
      final headers = await _getAuthHeaders();
      final body = json.encode(data);
      debugPrint('Battery PUT Body for ID $id: $body');

      final response = await http.put(
        Uri.parse('$_baseUrl/maintenance/battery/$id'),
        headers: headers,
        body: body,
      );

      debugPrint('Battery PUT Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception(
            'Failed to update battery maintenance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Battery PUT Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteBatteryMaintenance(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/maintenance/battery/$id'),
        headers: headers,
      );

      debugPrint(
          'Battery DELETE Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception(
            'Failed to delete battery maintenance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Battery DELETE Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Tyre Maintenance APIs
  Future<Map<String, dynamic>> getTyreMaintenance() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/maintenance/tyre'),
        headers: headers,
      );

      debugPrint('Tyre GET Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception(
            'Failed to fetch tyre maintenance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Tyre GET Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> addTyreMaintenance(
      Map<String, dynamic> data) async {
    try {
      final headers = await _getAuthHeaders();
      final body = json.encode(data);
      debugPrint('Tyre POST Body: $body');

      final response = await http.post(
        Uri.parse('$_baseUrl/maintenance/tyre'),
        headers: headers,
        body: body,
      );

      debugPrint('Tyre POST Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception(
            'Failed to add tyre maintenance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Tyre POST Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> updateTyreMaintenance(
      String id, Map<String, dynamic> data) async {
    try {
      final headers = await _getAuthHeaders();
      final body = json.encode(data);
      debugPrint('Tyre PUT Body for ID $id: $body');

      final response = await http.put(
        Uri.parse('$_baseUrl/maintenance/tyre/$id'),
        headers: headers,
        body: body,
      );

      debugPrint('Tyre PUT Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception(
            'Failed to update tyre maintenance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Tyre PUT Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteTyreMaintenance(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/maintenance/tyre/$id'),
        headers: headers,
      );

      debugPrint('Tyre DELETE Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception(
            'Failed to delete tyre maintenance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Tyre DELETE Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Wheel Balancing APIs
  Future<Map<String, dynamic>> getWheelBalancing() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/maintenance/wheel-balancing'),
        headers: headers,
      );

      debugPrint('Wheel Balancing GET Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception(
            'Failed to fetch wheel balancing: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Wheel Balancing GET Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> addWheelBalancing(
      Map<String, dynamic> data) async {
    try {
      final headers = await _getAuthHeaders();
      final body = json.encode(data);
      debugPrint('Wheel Balancing POST Body: $body');

      final response = await http.post(
        Uri.parse('$_baseUrl/maintenance/wheel-balancing'),
        headers: headers,
        body: body,
      );

      debugPrint(
          'Wheel Balancing POST Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception(
            'Failed to add wheel balancing: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Wheel Balancing POST Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> updateWheelBalancing(
      String id, Map<String, dynamic> data) async {
    try {
      final headers = await _getAuthHeaders();
      final body = json.encode(data);
      debugPrint('Wheel Balancing PUT Body for ID $id: $body');

      final response = await http.put(
        Uri.parse('$_baseUrl/maintenance/wheel-balancing/$id'),
        headers: headers,
        body: body,
      );

      debugPrint(
          'Wheel Balancing PUT Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception(
            'Failed to update wheel balancing: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Wheel Balancing PUT Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteWheelBalancing(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/maintenance/wheel-balancing/$id'),
        headers: headers,
      );

      debugPrint(
          'Wheel Balancing DELETE Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception(
            'Failed to delete wheel balancing: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Wheel Balancing DELETE Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<List<String>> getUsersDropdown() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/booking/dropdown/users'),
        headers: headers,
      );

      debugPrint('Users Dropdown Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        // Handle different response formats
        List<dynamic> usersList = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData['data'] is List) {
            usersList = responseData['data'];
          } else if (responseData['result'] is List) {
            usersList = responseData['result'];
          } else if (responseData['users'] is List) {
            usersList = responseData['users'];
          } else {
            final values = responseData.values.whereType<List>().toList();
            if (values.isNotEmpty) {
              usersList = values.first;
            }
          }
        } else if (responseData is List) {
          usersList = responseData;
        }

        final users = usersList
            .map<String>((item) {
              if (item is String) return item.trim();
              if (item is Map<String, dynamic>) {
                return (item['user_name'] ??
                        item['name'] ??
                        item['username'] ??
                        item['full_name'] ??
                        '')
                    .toString()
                    .trim();
              }
              return item.toString().trim();
            })
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();

        users.sort();

        return users;
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Users Dropdown Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getVehicleNumbersDropdown() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/booking/dropdown/vehicleNumber'),
        headers: headers,
      );

      debugPrint('Vehicles Dropdown Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        List<dynamic> vehiclesList = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData['data'] is List) {
            vehiclesList = responseData['data'];
          } else if (responseData['result'] is List) {
            vehiclesList = responseData['result'];
          } else if (responseData['vehicles'] is List) {
            vehiclesList = responseData['vehicles'];
          } else if (responseData['vehicleNumbers'] is List) {
            vehiclesList = responseData['vehicleNumbers'];
          } else {
            final values = responseData.values.whereType<List>().toList();
            if (values.isNotEmpty) {
              vehiclesList = values.first;
            }
          }
        } else if (responseData is List) {
          vehiclesList = responseData;
        }

        final vehicles = vehiclesList
            .map<Map<String, dynamic>>((item) {
              Map<String, dynamic> vehicleData = {
                'vehicle_number': '',
                'vehicle_id': '',
              };

              if (item is String) {
                vehicleData['vehicle_number'] = item.trim();
              } else if (item is Map<String, dynamic>) {
                vehicleData['vehicle_number'] = (item['vehicle_number'] ??
                        item['number'] ??
                        item['registration_number'] ??
                        item['plate_number'] ??
                        '')
                    .toString()
                    .trim();

                vehicleData['vehicle_id'] =
                    (item['vehicle_id'] ?? item['id'] ?? item['_id'] ?? '')
                        .toString();
              }

              return vehicleData;
            })
            .where((vehicle) => vehicle['vehicle_number']?.isNotEmpty ?? false)
            .toList();

        final uniqueVehicles = <String, Map<String, dynamic>>{};
        for (final vehicle in vehicles) {
          final vehicleNumber = vehicle['vehicle_number']!.toLowerCase();
          if (!uniqueVehicles.containsKey(vehicleNumber)) {
            uniqueVehicles[vehicleNumber] = vehicle;
          }
        }

        final sortedVehicles = uniqueVehicles.values.toList()
          ..sort((a, b) => a['vehicle_number'].compareTo(b['vehicle_number']));

        return sortedVehicles;
      } else {
        throw Exception('Failed to fetch vehicles: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Vehicles Dropdown Error: $e');
      throw Exception('Network error: $e');
    }
  }
}
