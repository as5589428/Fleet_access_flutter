import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_master_model.dart';
import '../core/constants/app_constants.dart';

class ServiceMasterService {
  static const String _baseUrl = AppConstants.baseUrl;

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey) ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<ServiceMasterModel>> getAllServices() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/service-master'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        List<dynamic> servicesArray = [];
        if (data is List) {
          servicesArray = data;
        } else if (data is Map<String, dynamic>) {
          if (data['data'] is List) {
            servicesArray = data['data'];
          } else if (data.containsKey('_id') || data.containsKey('service_id')) {
             servicesArray = [data];
          } else if (data.keys.isNotEmpty) {
             servicesArray = data.values.where((item) => item != null && item is Map).toList();
          }
        }

        return servicesArray.map((json) => ServiceMasterModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load services: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<ServiceMasterModel> getServiceById(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/service-master/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return ServiceMasterModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load service: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<ServiceMasterModel> createService(ServiceMasterModel service) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/service-master'),
        headers: headers,
        body: json.encode(service.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ServiceMasterModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create service: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<ServiceMasterModel> updateService(String id, ServiceMasterModel service) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/service-master/$id'),
        headers: headers,
        body: json.encode(service.toJson()),
      );

      if (response.statusCode == 200) {
        return ServiceMasterModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update service: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteService(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/service-master/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete service: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
