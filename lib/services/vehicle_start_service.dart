import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_start_model.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';

class VehicleStartService {
  static const String _baseUrl = 'https://fleet-vehicle-mgmt-backend-2.onrender.com/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<VehicleDropdownModel>> getVehiclesForDropdown() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/booking/dropdown/vehicleNumber?status=booked'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          return (data['data'] as List)
              .map((item) => VehicleDropdownModel.fromJson(item))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to load vehicles');
      }
    } catch (e) {
      throw Exception('Error loading vehicles: $e');
    }
  }

  Future<List<VehicleStartModel>> getAllStartEntries() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/vehicle/start/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          return (data['data'] as List)
              .map((item) => VehicleStartModel.fromJson(item))
              .toList();
        } else if (data['status'] == 'success' && data['data'] is List) {
           return (data['data'] as List)
              .map((item) => VehicleStartModel.fromJson(item))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to load vehicle start entries');
      }
    } catch (e) {
      throw Exception('Error loading vehicle start entries: $e');
    }
  }

  Future<VehicleStartModel> createStartEntry({
    required VehicleStartModel startModel,
    required List<File> startPhotos,
    File? editPhoto,
    File? mapUpload,
  }) async {
    try {
      final token = await _getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/vehicle/start/create'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add text fields
      request.fields['vehicle_number'] = startModel.vehicleNumber ?? '';
      request.fields['start_km'] = startModel.startKm ?? '';
      request.fields['remarks'] = startModel.remarks ?? '';
      request.fields['alert_type'] = startModel.alertType ?? 'Normal';
      request.fields['is_edit'] = startModel.isEdit == true ? 'true' : 'false';
      request.fields['user_id'] = 'user_123'; // Hardcoded as per React code
      
      if (startModel.isEdit == true && startModel.updatedStartKm != null) {
        request.fields['updated_start_km'] = startModel.updatedStartKm!;
      }

      // Add multiple start photos
      for (var photoFile in startPhotos) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'start_photo', 
            photoFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      // Add map upload if available
      if (mapUpload != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'map_upload',
            mapUpload.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      // Add edit photo if available
      if (editPhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'edit_photo',
            editPhoto.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return VehicleStartModel.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to create vehicle start entry: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating vehicle start entry: $e');
    }
  }

  Future<VehicleStartModel> updateStartEntry({
    required String id,
    required VehicleStartModel startModel,
    List<File>? newStartPhotos,
    File? newEditPhoto,
    File? newMapUpload,
  }) async {
    try {
      final token = await _getToken();
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl/vehicle/start/$id'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add text fields
      request.fields['vehicle_number'] = startModel.vehicleNumber ?? '';
      request.fields['start_km'] = startModel.startKm ?? '';
      request.fields['remarks'] = startModel.remarks ?? '';
      request.fields['alert_type'] = startModel.alertType ?? 'Normal';
      request.fields['is_edit'] = startModel.isEdit == true ? 'true' : 'false';
      request.fields['user_id'] = 'user_123';
      
      if (startModel.isEdit == true && startModel.updatedStartKm != null) {
        request.fields['updated_start_km'] = startModel.updatedStartKm!;
      }

      // Add files if available
      if (newStartPhotos != null && newStartPhotos.isNotEmpty) {
        for (var photoFile in newStartPhotos) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'start_photo', 
              photoFile.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      }

      if (newMapUpload != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'map_upload',
            newMapUpload.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      if (newEditPhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'edit_photo',
            newEditPhoto.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VehicleStartModel.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to update vehicle start entry: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating vehicle start entry: $e');
    }
  }

  Future<void> deleteStartEntry(String id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/vehicle/start/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete vehicle start entry');
      }
    } catch (e) {
      throw Exception('Error deleting vehicle start entry: $e');
    }
  }
}
