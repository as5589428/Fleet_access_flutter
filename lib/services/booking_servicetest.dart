import 'package:dio/dio.dart';
import '../models/booking_model.dart';
import 'api_service.dart';

class BookingService {
  final ApiService _apiService = ApiService.instance;

  Future<List<BookingModel>> getBookings({
    int page = 1,
    int limit = 20,
    String? status,
    String? employeeId,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (employeeId != null) 'employeeId': employeeId,
      };

      final response = await _apiService.get('/bookings', queryParameters: queryParams);
      final List<dynamic> data = response.data['bookings'];
      return data.map((json) => BookingModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BookingModel> getBookingById(String id) async {
    try {
      final response = await _apiService.get('/bookings/$id');
      return BookingModel.fromJson(response.data['booking']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BookingModel> createBooking({
    required String vehicleType,
    required DateTime startDate,
    required DateTime endDate,
    required String purpose,
    String? remarks,
  }) async {
    try {
      final response = await _apiService.post('/bookings', data: {
        'vehicleType': vehicleType,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'purpose': purpose,
        'remarks': remarks,
      });
      return BookingModel.fromJson(response.data['booking']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BookingModel> updateBooking(String id, {
    String? status,
    String? vehicleId,
    String? remarks,
    String? rejectionReason,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (status != null) data['status'] = status;
      if (vehicleId != null) data['vehicleId'] = vehicleId;
      if (remarks != null) data['remarks'] = remarks;
      if (rejectionReason != null) data['rejectionReason'] = rejectionReason;

      final response = await _apiService.put('/bookings/$id', data: data);
      return BookingModel.fromJson(response.data['booking']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> cancelBooking(String id, String reason) async {
    try {
      await _apiService.put('/bookings/$id/cancel', data: {
        'reason': reason,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getBookingStats() async {
    try {
      final response = await _apiService.get('/bookings/stats');
      return response.data['stats'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      return data['message'] ?? 'An error occurred';
    } else {
      return 'Network error occurred';
    }
  }
}
