// dashboard_model.dart
import 'package:flutter/foundation.dart';
import 'vehicle_model.dart';

class DashboardVehicle {
  final String id;
  final String vehicleNumber;
  final String vehicleType;
  final String bookingStatus;
  final String status;
  final String? userName;
  final DateTime? updatedAt;
  final VehicleDetails vehicleDetails;
  final ExpiryDetails expiryDetails;
  final String? ownershipName;
  final String seatingCapacity;
  final int? sNo;

  DashboardVehicle({
    required this.id,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.bookingStatus,
    required this.status,
    this.userName,
    this.updatedAt,
    required this.vehicleDetails,
    required this.expiryDetails,
    this.ownershipName,
    required this.seatingCapacity,
    this.sNo,
  });

  factory DashboardVehicle.fromVehicleModel(VehicleModel vehicle, {int? sNo}) {
    return DashboardVehicle(
      id: vehicle.id,
      vehicleNumber: vehicle.vehicleNumber,
      vehicleType: vehicle.vehicleType,
      bookingStatus: vehicle.bookingStatus,
      status: vehicle.status,
      userName: vehicle.userName.isNotEmpty ? vehicle.userName : null,
      updatedAt: vehicle.updatedAt,
      vehicleDetails: vehicle.vehicleDetails,
      expiryDetails: vehicle.expiryDetails,
      ownershipName:
          vehicle.ownershipName.isNotEmpty ? vehicle.ownershipName : null,
      seatingCapacity: vehicle.seatingCapacity,
      sNo: sNo,
    );
  }

  factory DashboardVehicle.fromJson(Map<String, dynamic> json) {
    try {
      // Handle vehicle_details if it exists
      VehicleDetails details;
      if (json['vehicle_details'] != null && json['vehicle_details'] is Map) {
        details = VehicleDetails.fromJson(
            Map<String, dynamic>.from(json['vehicle_details']));
      } else {
        // Create from root level fields - WITHOUT variant
        details = VehicleDetails(
          brand: json['brand'] ?? json['make'] ?? '',
          model: json['model'] ?? json['model_name'] ?? '',
          fuelType: _parseFuelType(json),
          registrationDate: parseDateTimeFromJson(
              json['registration_date'] ?? json['date_of_registration']),
          yearOfPurchase: _parseYearOfPurchase(json),
        );
      }

      // Handle expiry_details
      ExpiryDetails expiry;
      if (json['expiry_details'] != null && json['expiry_details'] is Map) {
        expiry = ExpiryDetails.fromJson(
            Map<String, dynamic>.from(json['expiry_details']));
      } else {
        expiry = ExpiryDetails(
          insuranceExpiry: parseDateTimeFromJson(
              json['insurance_due'] ?? json['insurance_expiry']),
          maintenanceExpiry: parseDateTimeFromJson(json['maintenance_due'] ??
              json['maintenance_expiry'] ??
              json['service_given_date']),
          pollutionExpiry: parseDateTimeFromJson(
              json['pollution_due'] ?? json['pollution_expiry']),
        );
      }

      return DashboardVehicle(
        id: json['_id'] ?? json['id'] ?? json['s_no']?.toString() ?? '',
        vehicleNumber: json['vehicle_number'] ?? '',
        vehicleType: json['vehicle_type'] ?? json['type'] ?? '',
        bookingStatus: json['booking_status'] ??
            json['maintenance_type'] ??
            json['status'] ??
            'Unknown',
        status: json['status'] ??
            json['booking_color_code'] ??
            json['vehicle_status'] ??
            'Under Maintenance',
        userName: json['user_name'] ??
            json['userName'] ??
            json['service_given_by'] ??
            json['assigned_to'] ??
            '',
        updatedAt: parseDateTimeFromJson(
            json['updatedAt'] ?? json['updated_at'] ?? json['date_of_return']),
        vehicleDetails: details,
        expiryDetails: expiry,
        ownershipName: json['ownership_name'] ??
            json['service_center_name'] ??
            json['registered_name'] ??
            json['owner'],
        seatingCapacity: json['seating_capacity']?.toString() ??
            json['capacity']?.toString() ??
            '4',
      );
    } catch (e) {
      debugPrint('Error parsing DashboardVehicle: $e');
      // Return a default vehicle if parsing fails - WITHOUT variant
      return DashboardVehicle(
        id: '',
        vehicleNumber: 'Unknown',
        vehicleType: 'Unknown',
        bookingStatus: 'Unknown',
        status: 'Unknown',
        vehicleDetails: VehicleDetails(
          brand: '',
          model: '',
          fuelType: [],
          registrationDate: null,
          yearOfPurchase: 0,
        ),
        expiryDetails: ExpiryDetails(
          insuranceExpiry: null,
          maintenanceExpiry: null,
          pollutionExpiry: null,
        ),
        seatingCapacity: '0',
      );
    }
  }

  // Helper method to parse fuel type
  static List<String> _parseFuelType(Map<String, dynamic> json) {
    if (json['fuel_type'] != null) {
      if (json['fuel_type'] is List) {
        return List<String>.from(json['fuel_type'] as List);
      } else if (json['fuel_type'] is String) {
        return [json['fuel_type'].toString()];
      }
    }
    return [];
  }

  // Helper method to parse year of purchase
  static int _parseYearOfPurchase(Map<String, dynamic> json) {
    final yearValue = json['year_of_purchase'] ?? json['purchase_year'] ?? 0;
    if (yearValue is int) return yearValue;
    if (yearValue is String) return int.tryParse(yearValue) ?? 0;
    return 0;
  }

  // Convenience getters
  String get brand => vehicleDetails.brand;
  String get model => vehicleDetails.model;
  String? get fuelType => vehicleDetails.fuelType.isNotEmpty
      ? vehicleDetails.fuelType.first
      : 'Petrol';
  String? get yearOfPurchase => vehicleDetails.yearOfPurchase.toString();
  DateTime? get insuranceExpiry => expiryDetails.insuranceExpiry;
  DateTime? get maintenanceExpiry => expiryDetails.maintenanceExpiry;
  DateTime? get pollutionExpiry => expiryDetails.pollutionExpiry;
  dynamic get registrationDate => vehicleDetails.registrationDate;
}

// PaginatedVehicleResponse class remains the same
class PaginatedVehicleResponse {
  final List<DashboardVehicle> data;
  final int total;
  final int page;
  final int limit;

  PaginatedVehicleResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory PaginatedVehicleResponse.fromJson(Map<String, dynamic> json) {
    List<DashboardVehicle> vehicles = [];
    int total = 0;
    int page = 1;
    int limit = 10;

    try {
      if (json.containsKey('data') && json['data'] is List) {
        final List<dynamic> dataList = json['data'] as List;
        vehicles = dataList
            .where((item) => item != null)
            .map((item) => DashboardVehicle.fromJson(
                item is Map ? Map<String, dynamic>.from(item) : {}))
            .toList();
      }

      if (json.containsKey('pagination') && json['pagination'] is Map) {
        final pagination = Map<String, dynamic>.from(json['pagination']);
        total = pagination['total'] ?? vehicles.length;
        page = pagination['page'] ?? 1;
        limit = pagination['limit'] ?? 10;
      } else if (json.containsKey('total')) {
        final totalValue = json['total'];
        if (totalValue is int) {
          total = totalValue;
        } else if (totalValue is String) {
          total = int.tryParse(totalValue) ?? vehicles.length;
        } else {
          total = vehicles.length;
        }
      } else {
        total = vehicles.length;
      }

      if (json.containsKey('page')) {
        final pageValue = json['page'];
        if (pageValue is int) {
          page = pageValue;
        } else if (pageValue is String) {
          page = int.tryParse(pageValue) ?? 1;
        }
      }

      if (json.containsKey('limit')) {
        final limitValue = json['limit'];
        if (limitValue is int) {
          limit = limitValue;
        } else if (limitValue is String) {
          limit = int.tryParse(limitValue) ?? 10;
        }
      }
    } catch (e) {
      debugPrint('Error parsing PaginatedVehicleResponse: $e');
    }

    return PaginatedVehicleResponse(
      data: vehicles,
      total: total,
      page: page,
      limit: limit,
    );
  }
}
