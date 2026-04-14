// lib/services/maintenance/service_history_service.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});
}

class ServiceHistoryService {
  static const String baseUrl =
      'https://fleet-vehicle-mgmt-backend-2.onrender.com/api';
  static final ServiceHistoryService _instance =
      ServiceHistoryService._internal();
  factory ServiceHistoryService() => _instance;
  ServiceHistoryService._internal();

  final http.Client client = http.Client();

  // Headers for all requests
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // Get Service History - No parameters needed
  Future<ApiResponse<Map<String, dynamic>>> getServiceHistory() async {
    try {
      final uri = Uri.parse('$baseUrl/maintenance/service-history');

      debugPrint('Fetching service history from: $uri');

      final response = await client
          .get(
            uri,
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          // Process the data to group by service type
          final List<dynamic> services = responseData['data'] ?? [];

          // Initialize counters
          int batteryCount = 0;
          int tyreCount = 0;
          int wheelBalanceCount = 0;
          int generalCount = 0;
          double totalCost = 0;

          // Group services by type
          final Map<String, List<Map<String, dynamic>>> groupedServices = {
            'battery_change': [],
            'tyre_change': [],
            'wheel_balancing': [],
            'general_service': [],
          };

          // Process each service
          for (var service in services) {
            if (service is Map<String, dynamic>) {
              final serviceType = service['service_type']?.toString() ?? '';
              final cost = (service['cost'] as num?)?.toDouble() ?? 0;
              totalCost += cost;

              // Prepare service item
              final Map<String, dynamic> serviceItem = {
                ...service,
                'details': service['details'] ?? {},
              };

              // Add to appropriate group
              switch (serviceType) {
                case 'battery':
                  batteryCount++;
                  groupedServices['battery_change']!.add(serviceItem);
                  break;
                case 'tyre':
                  tyreCount++;
                  groupedServices['tyre_change']!.add(serviceItem);
                  break;
                case 'wheel_balancing':
                  wheelBalanceCount++;
                  groupedServices['wheel_balancing']!.add(serviceItem);
                  break;
                case 'general':
                  generalCount++;
                  groupedServices['general_service']!.add(serviceItem);
                  break;
              }
            }
          }

          // Create the result map
          final Map<String, dynamic> result = {
            'total_services': responseData['total_services'] ?? 0,
            'driven_km': responseData['driven_km'] ?? 0,
            'total_cost': responseData['total_cost']?.toDouble() ?? totalCost,
            'battery_change': groupedServices['battery_change']!,
            'tyre_change': groupedServices['tyre_change']!,
            'wheel_balancing': groupedServices['wheel_balancing']!,
            'general_service': groupedServices['general_service']!,
            'battery_count': batteryCount,
            'tyre_count': tyreCount,
            'wheel_balance_count': wheelBalanceCount,
            'general_count': generalCount,
            'all_services': services, // Keep all services for reference
          };

          return ApiResponse(
            success: true,
            message: 'Service history fetched successfully',
            data: result,
          );
        } else {
          return ApiResponse(
            success: false,
            message:
                responseData['message'] ?? 'Failed to fetch service history',
          );
        }
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to fetch service history: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error in getServiceHistory: $e');
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}
