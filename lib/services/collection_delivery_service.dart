import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collection_delivery_model.dart';

class CollectionDeliveryService {
  static const String _baseUrl = 'https://keerainnovations.com/erpbackend/api';

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? prefs.getString('user_id');
  }

  /// Fetch all collection/delivery records for a user.
  /// If [startDate] and [endDate] are null, the API returns today's tasks.
  Future<CollectionApiResponse> getAllEntries({
    required String type, // 'collection' or 'delivery'
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final userId = await _getUserId();

      final Map<String, String> queryParams = {
        'userId': userId ?? '',
        'type': type,
      };
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('$_baseUrl/transaction/collection/getAll')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<CollectionDeliveryModel> entries = data['success'] == true && data['data'] is List
            ? (data['data'] as List).map((item) => CollectionDeliveryModel.fromJson(item)).toList()
            : [];
        final dashboardInfo = data['dashboardInfo'] != null
            ? DashboardInfo.fromJson(data['dashboardInfo'])
            : const DashboardInfo();
        return CollectionApiResponse(data: entries, dashboardInfo: dashboardInfo);
      } else {
        throw Exception('Failed to load entries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading entries: $e');
    }
  }

  /// Create a new collection/delivery task entry (multipart for file uploads)
  Future<CollectionDeliveryModel> createEntry({
    required CollectionDeliveryModel model,
    File? dcImage,
    File? startKmPhoto,
    File? endKmPhoto,
    File? paymentPhoto,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/transaction/collection/create'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      // Add JSON fields
      final jsonBody = model.toJson();
      jsonBody.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value is List
              ? json.encode(value)
              : value.toString();
        }
      });

      // Add file uploads
      if (dcImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'dc_image',
          dcImage.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      if (startKmPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'start_km_photo',
          startKmPhoto.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      if (endKmPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'end_km_photo',
          endKmPhoto.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      if (paymentPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'payment_photo',
          paymentPhoto.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return CollectionDeliveryModel.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to create entry: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating entry: $e');
    }
  }

  /// Update an existing entry
  Future<CollectionDeliveryModel> updateEntry({
    required String id,
    required CollectionDeliveryModel model,
    File? dcImage,
    File? startKmPhoto,
    File? endKmPhoto,
    File? paymentPhoto,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl/transaction/collection/update/$id'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      final updateData = model.toUpdateJson();
      
      // The API expects the entire JSON string inside a 'data' field.
      request.fields['data'] = json.encode(updateData);

      // Add file uploads with specific field names
      if (dcImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'upload_dc',
          dcImage.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      if (startKmPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'start_km_photo',
          startKmPhoto.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      if (endKmPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'end_km_photo',
          endKmPhoto.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      if (paymentPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'payment_photo',
          paymentPhoto.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CollectionDeliveryModel.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to update entry: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating entry: $e');
    }
  }
}
