import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService.authInstance;

  Future<Map<String, dynamic>> login(String employeeCode, String password) async {
    try {
      final response = await _apiService.post('/auth/login', data: {
        'email': employeeCode,
        'password': password,
      });

      developer.log('Login response: ${response.data}', name: 'AuthService');

      if (response.data['success'] == true) {
        final Map<String, dynamic> responseData = response.data['data'];
        
        final rawUser = responseData['user'] as Map<String, dynamic>;
        final userJson = _mapUserJson(rawUser);

        return {
          'token': responseData['token'],
          'user': UserModel.fromJson(userJson),
          'permissions': responseData['permissions'],
        };
      } else {
        final msg = response.data is Map ? (response.data['message'] ?? 'Login failed') : 'Login failed';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiService.get('/auth/me');
      return UserModel.fromJson(_mapUserJson(response.data['user'] as Map<String, dynamic>));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiService.put('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    developer.log(
      'DioException: ${e.message} | status: ${e.response?.statusCode} | data: ${e.response?.data}',
      name: 'AuthService',
    );
    if (e.response != null) {
      final data = e.response!.data;
      String message = 'An error occurred';
      if (data is Map) {
        message = data['message']?.toString() ?? message;
      } else if (data is String && data.isNotEmpty) {
        // Avoid dumping raw HTML
        message = data.length < 200 ? data : 'Server error (${e.response!.statusCode})';
      } else {
        message = 'Server error (${e.response!.statusCode})';
      }
      return Exception(message);
    } else {
      return Exception('Network error. Please check your connection.');
    }
  }

  Map<String, dynamic> _mapUserJson(Map<String, dynamic> json) {
    final userJson = Map<String, dynamic>.from(json);
    
    // Fallbacks for missing fields required by UserModel
    if (!userJson.containsKey('name')) {
      final title = userJson['title'] ?? '';
      final firstName = userJson['firstName'] ?? '';
      final lastName = userJson['lastName'] ?? '';
      userJson['name'] = '$title $firstName $lastName'.trim();
    }
    if (userJson['name'] == null || userJson['name'].toString().isEmpty) {
      userJson['name'] = userJson['username'] ?? userJson['empCode'] ?? 'User';
    }
    
    if (!userJson.containsKey('phone') && userJson.containsKey('contactNumber')) {
      userJson['phone'] = userJson['contactNumber'].toString();
    }

    if (!userJson.containsKey('role')) {
      userJson['role'] = 'ADMIN';
    }
    if (!userJson.containsKey('id')) {
      userJson['id'] = userJson['_id'] ?? 'unknown';
    }
    if (!userJson.containsKey('createdAt')) {
      userJson['createdAt'] = DateTime.now().toIso8601String();
    }
    
    return userJson;
  }
}
