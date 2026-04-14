import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/closing_model.dart';

// ApiResponse class embedded in the same file
class ApiResponse {
  final String status;
  final String message;
  final dynamic data;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? 'Unknown error',
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data,
    };
  }

  bool get isSuccess => status.toLowerCase() == 'success';
  bool get isError => status.toLowerCase() == 'error';
}

class ClosingService {
  static const String baseUrl =
      'https://fleet-vehicle-mgmt-backend-2.onrender.com/api/vehicle-closing';

  // Fetch all records
  static Future<List<ClosingRecord>> fetchRecords() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/list'));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && result['data'] is List) {
          return (result['data'] as List)
              .map((item) => ClosingRecord.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load records: $e');
    }
  }

  // Create new record
  static Future<ApiResponse> createRecord(
    ClosingRecord record,
    List<File> photos,
  ) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/create'));

      // Add text fields
      request.fields['vehicle_id'] = record.vehicleId;
      request.fields['vehicle_number'] = record.vehicleNumber;
      request.fields['user_id'] = record.userId;
      request.fields['endkm'] = record.endKm.toString();
      request.fields['remarks'] = record.remarks;
      request.fields['is_remarks'] = record.isRemarks.toString();
      request.fields['alert_type'] = record.alertType ?? 'Normal';

      // Add photos
      for (var photo in photos) {
        request.files.add(
          await http.MultipartFile.fromPath('photos', photo.path),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      return ApiResponse.fromJson(jsonDecode(responseBody));
    } catch (e) {
      return ApiResponse(
        status: 'error',
        message: 'Failed to create record: $e',
      );
    }
  }

  // Update record
  static Future<ApiResponse> updateRecord(ClosingRecord record) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/update/${record.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(record.toJson()),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(
        status: 'error',
        message: 'Failed to update record: $e',
      );
    }
  }

  // Delete record
  static Future<ApiResponse> deleteRecord(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/delete/$id'));
      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(
        status: 'error',
        message: 'Failed to delete record: $e',
      );
    }
  }
}
