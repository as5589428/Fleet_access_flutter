import 'package:flutter/material.dart';

// Enhanced date parser that handles all your API's invalid dates
DateTime? parseDateTimeFromJson(dynamic value) {
  if (value == null) return null;

  try {
    if (value is String) {
      final dateString = value.trim();

      // Quick checks for null/empty values
      if (dateString.isEmpty ||
          dateString == 'null' ||
          dateString == 'undefined' ||
          dateString.contains('undefined') ||
          dateString == 'Invalid Date' ||
          dateString == 'NaT') {
        debugPrint(
            '⚠️ Empty/invalid date string: "$dateString", returning null');
        return null;
      }

      // Check for invalid year patterns
      if (dateString.length >= 4) {
        final yearPart = dateString.substring(0, 4);

        // Try to parse year
        final year = int.tryParse(yearPart);
        if (year != null) {
          // Check for obviously invalid years
          if (year < 1900 || year > 2100) {
            debugPrint(
                '⚠️ Invalid year $year in date: "$dateString", returning null');
            return null;
          }

          // Check for specific invalid years
          final invalidYears = [789, 3434, 2344, 4576, 3000, 6000, 67789];
          if (invalidYears.contains(year)) {
            debugPrint(
                '⚠️ Known invalid year $year in date: "$dateString", returning null');
            return null;
          }
        } else if (dateString.startsWith('+')) {
          debugPrint('⚠️ Date starts with +: "$dateString", returning null');
          return null;
        }
      }

      // Check for 1970 dates with time components (invalid sentinel dates)
      if (dateString.startsWith('1970-01-01T')) {
        debugPrint(
            '⚠️ Invalid 1970 date with time: "$dateString", returning null');
        return null;
      }

      // Try to parse the date string
      try {
        return DateTime.parse(dateString);
      } catch (parseError) {
        debugPrint(
            '⚠️ DateTime.parse failed for: "$dateString", error: $parseError');

        // Try to extract just the date part if the time is malformed
        if (dateString.contains('T')) {
          try {
            final datePart = dateString.split('T').first;
            return DateTime.parse(datePart);
          } catch (e) {
            debugPrint('⚠️ Failed to parse date part only: $e');
          }
        }

        return null;
      }
    }

    return null;
  } catch (e) {
    debugPrint('⚠️ Unexpected error parsing date: "$value", error: $e');
    return null;
  }
}

class ExpiryColor {
  final String? insurance;
  final String? rcBook;
  final String? maintenance;
  final String? wheelBalancing;
  final String? pollution;

  ExpiryColor({
    this.insurance,
    this.rcBook,
    this.maintenance,
    this.wheelBalancing,
    this.pollution,
  });

  factory ExpiryColor.fromJson(Map<String, dynamic> json) {
    return ExpiryColor(
      insurance: json['insurance']?.toString(),
      rcBook: json['rc_book']?.toString(),
      maintenance: json['maintenance']?.toString(),
      wheelBalancing: json['wheel_balancing']?.toString(),
      pollution: json['pollution']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'insurance': insurance,
      'rc_book': rcBook,
      'maintenance': maintenance,
      'wheel_balancing': wheelBalancing,
      'pollution': pollution,
    };
  }
}

class VehicleDetails {
  final String brand;
  final String model;
  final DateTime? registrationDate;
  final int yearOfPurchase;
  final List<String> fuelType;
  final String? rcBookUrl;
  final String? insuranceUrl;
  final String? pollutionUrl;
  final String? batteryWarrantyUrl;
  final String? statusDocumentsUrl;
  final String? maintenanceExpiryUrl;
  final String? tyreExpiryUrl;
  final String? wheelExpiryUrl;

  VehicleDetails({
    required this.brand,
    required this.model,
    required this.registrationDate,
    required this.yearOfPurchase,
    required this.fuelType,
    this.rcBookUrl,
    this.insuranceUrl,
    this.pollutionUrl,
    this.batteryWarrantyUrl,
    this.statusDocumentsUrl,
    this.maintenanceExpiryUrl,
    this.tyreExpiryUrl,
    this.wheelExpiryUrl,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      registrationDate: parseDateTimeFromJson(json['registration_date']),
      yearOfPurchase: (json['year_of_purchase'] as num?)?.toInt() ?? 0,
      fuelType: (json['fuel_type'] is List)
          ? List<String>.from(json['fuel_type'].map((e) => e.toString()))
          : (json['fuel_type'] != null ? [json['fuel_type'].toString()] : []),
      rcBookUrl: json['rc_book_url']?.toString(),
      insuranceUrl: json['insurance_url']?.toString(),
      pollutionUrl: json['pollution_url']?.toString(),
      batteryWarrantyUrl: json['battery_warranty_url']?.toString(),
      statusDocumentsUrl: json['status_documents_url']?.toString(),
      maintenanceExpiryUrl: json['maintenance_expiry_url']?.toString(),
      tyreExpiryUrl: json['tyre_expiry_url']?.toString(),
      wheelExpiryUrl: json['wheel_expiry_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      'registration_date': registrationDate?.toIso8601String(),
      'year_of_purchase': yearOfPurchase,
      'fuel_type': fuelType,
      'rc_book_url': rcBookUrl,
      'insurance_url': insuranceUrl,
      'pollution_url': pollutionUrl,
      'battery_warranty_url': batteryWarrantyUrl,
      'status_documents_url': statusDocumentsUrl,
      'maintenance_expiry_url': maintenanceExpiryUrl,
      'tyre_expiry_url': tyreExpiryUrl,
      'wheel_expiry_url': wheelExpiryUrl,
    };
  }
}

class ExpiryDetails {
  final DateTime? insuranceExpiry;
  final DateTime? rcBookExpiry;
  final DateTime? maintenanceExpiry;
  final DateTime? wheelBalancingExpiry;
  final DateTime? pollutionExpiry;
  final DateTime? tyreExpiry;
  final DateTime? batteryExpiry;
  final String? wheelBalancingExpiryKm;
  final String? tyreChangeExpiryKm;

  ExpiryDetails({
    this.insuranceExpiry,
    this.rcBookExpiry,
    this.maintenanceExpiry,
    this.wheelBalancingExpiry,
    this.pollutionExpiry,
    this.tyreExpiry,
    this.batteryExpiry,
    this.wheelBalancingExpiryKm,
    this.tyreChangeExpiryKm,
  });

  factory ExpiryDetails.fromJson(Map<String, dynamic> json) {
    return ExpiryDetails(
      insuranceExpiry: parseDateTimeFromJson(json['insurance_expiry']),
      rcBookExpiry: parseDateTimeFromJson(json['rc_book_expiry']),
      maintenanceExpiry: parseDateTimeFromJson(json['maintenance_expiry']),
      wheelBalancingExpiry:
          parseDateTimeFromJson(json['wheel_balancing_expiry']),
      pollutionExpiry: parseDateTimeFromJson(json['pollution_expiry']),
      tyreExpiry: parseDateTimeFromJson(json['tyre_expiry']),
      batteryExpiry: parseDateTimeFromJson(json['battery_expiry']),
      wheelBalancingExpiryKm: json['wheel_balancing_expiry']?.toString(),
      tyreChangeExpiryKm: json['tyre_change_expiry']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'insurance_expiry': insuranceExpiry?.toIso8601String(),
      'rc_book_expiry': rcBookExpiry?.toIso8601String(),
      'maintenance_expiry': maintenanceExpiry?.toIso8601String(),
      'wheel_balancing_expiry': wheelBalancingExpiry?.toIso8601String() ?? wheelBalancingExpiryKm,
      'pollution_expiry': pollutionExpiry?.toIso8601String(),
      'tyre_expiry': tyreExpiry?.toIso8601String(),
      'battery_expiry': batteryExpiry?.toIso8601String(),
      'tyre_change_expiry': tyreChangeExpiryKm,
    };
  }
}

class PurchaseDetails {
  final Map<String, dynamic> newVehicle;
  final Map<String, dynamic> oldVehicle;

  PurchaseDetails({
    required this.newVehicle,
    required this.oldVehicle,
  });

  factory PurchaseDetails.fromJson(Map<String, dynamic> json) {
    return PurchaseDetails(
      newVehicle: json['new_vehicle'] as Map<String, dynamic>? ?? {},
      oldVehicle: json['old_vehicle'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'new_vehicle': newVehicle,
      'old_vehicle': oldVehicle,
    };
  }
}

class ResaleDetails {
  final DateTime? dateOfResale;
  final String? saleAmount;
  final bool payReceived;
  final String? purchaserName;
  final String? saleMobNo;
  final String? saleAdh;
  final String? saleAdhurl;
  final String? saleDc;

  ResaleDetails({
    this.dateOfResale,
    this.saleAmount,
    required this.payReceived,
    this.purchaserName,
    this.saleMobNo,
    this.saleAdh,
    this.saleAdhurl,
    this.saleDc,
  });

  factory ResaleDetails.fromJson(Map<String, dynamic> json) {
    return ResaleDetails(
      dateOfResale: parseDateTimeFromJson(json['date_of_resale']),
      saleAmount: json['sale_amount']?.toString(),
      payReceived: json['pay_recieved'] == true,
      purchaserName: json['purchaser_name']?.toString(),
      saleMobNo: json['sale_mob_no']?.toString(),
      saleAdh: json['sale_adh']?.toString(),
      saleAdhurl: json['sale_adhurl']?.toString(),
      saleDc: json['sale_dc']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_of_resale': dateOfResale?.toIso8601String(),
      'sale_amount': saleAmount,
      'pay_recieved': payReceived,
      'purchaser_name': purchaserName,
      'sale_mob_no': saleMobNo,
      'sale_adh': saleAdh,
      'sale_adhurl': saleAdhurl,
      'sale_dc': saleDc,
    };
  }
}

class TheftDetails {
  final DateTime? dateOfTheft;
  final DateTime? dateOfComplaint;
  final String? placeOfTheft;
  final String? theftName;
  final String? theftMobNo;
  final String? theftFIRurl;

  TheftDetails({
    this.dateOfTheft,
    this.dateOfComplaint,
    this.placeOfTheft,
    this.theftName,
    this.theftMobNo,
    this.theftFIRurl,
  });

  factory TheftDetails.fromJson(Map<String, dynamic> json) {
    return TheftDetails(
      dateOfTheft: parseDateTimeFromJson(json['date_of_theft']),
      dateOfComplaint: parseDateTimeFromJson(json['date_of_complaint']),
      placeOfTheft: json['place_of_theft']?.toString() ??
          json['palce_of_theft']?.toString(),
      theftName: json['theft_name']?.toString(),
      theftMobNo: json['theft_mob_no']?.toString(),
      theftFIRurl: json['theft_FIRurl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_of_theft': dateOfTheft?.toIso8601String(),
      'date_of_complaint': dateOfComplaint?.toIso8601String(),
      'place_of_theft': placeOfTheft,
      'theft_name': theftName,
      'theft_mob_no': theftMobNo,
      'theft_FIRurl': theftFIRurl,
    };
  }
}

class ScrapDetails {
  final DateTime? dateOfScrap;
  final String? scrName;
  final String? scrAddress;
  final String? scrapAdh;
  final String? scrapMobNo;
  final String? scrapAdhurl;
  final String? scrapPhoto;
  final String? scrapDocument;

  ScrapDetails({
    this.dateOfScrap,
    this.scrName,
    this.scrAddress,
    this.scrapAdh,
    this.scrapMobNo,
    this.scrapAdhurl,
    this.scrapPhoto,
    this.scrapDocument,
  });

  factory ScrapDetails.fromJson(Map<String, dynamic> json) {
    return ScrapDetails(
      dateOfScrap: parseDateTimeFromJson(json['date_of_scrap']),
      scrName: json['scr_name']?.toString(),
      scrAddress: json['scr_address']?.toString(),
      scrapAdh: json['scrap_adh']?.toString(),
      scrapMobNo: json['scrap_mob_no']?.toString(),
      scrapAdhurl: json['scrap_adhurl']?.toString(),
      scrapPhoto: json['scrap_photo']?.toString(),
      scrapDocument: json['scrap_document']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_of_scrap': dateOfScrap?.toIso8601String(),
      'scr_name': scrName,
      'scr_address': scrAddress,
      'scrap_adh': scrapAdh,
      'scrap_mob_no': scrapMobNo,
      'scrap_adhurl': scrapAdhurl,
      'scrap_photo': scrapPhoto,
      'scrap_document': scrapDocument,
    };
  }
}

class MaintenanceDetails {
  final bool isUnderMaintenance;
  final String maintenanceStatus;
  final bool battery;
  final bool tyre;
  final bool wheelBalancing;
  final bool general;

  MaintenanceDetails({
    required this.isUnderMaintenance,
    required this.maintenanceStatus,
    required this.battery,
    required this.tyre,
    required this.wheelBalancing,
    required this.general,
  });

  factory MaintenanceDetails.fromJson(Map<String, dynamic> json) {
    return MaintenanceDetails(
      isUnderMaintenance: json['is_under_maintenance'] == true,
      maintenanceStatus: json['maintenance_status']?.toString() ?? '',
      battery: json['battery'] == true,
      tyre: json['tyre'] == true,
      wheelBalancing: json['wheel_balancing'] == true,
      general: json['general'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_under_maintenance': isUnderMaintenance,
      'maintenance_status': maintenanceStatus,
      'battery': battery,
      'tyre': tyre,
      'wheel_balancing': wheelBalancing,
      'general': general,
    };
  }
}

class VehicleModel {
  final String id;
  final String vehicleId;
  final String vehicleNumber;
  final String vehicleType;
  final String ownershipName;
  final String userName;
  final String userId;
  final String status;
  final String remarks;
  final String bookingStatus;
  final String bookedBy;
  final String bookingColorCode;
  final String serviceKmAlert;
  final String seatingCapacity;
  final String? currentKm;
  final String purchaseType;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<dynamic> alerts;
  final VehicleDetails vehicleDetails;
  final ExpiryDetails expiryDetails;
  final PurchaseDetails purchaseDetails;
  final ResaleDetails resaleDetails;
  final TheftDetails theftDetails;
  final ScrapDetails scrapDetails;
  final MaintenanceDetails maintenanceDetails;
  final ExpiryColor? expiryColor;

  VehicleModel({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.ownershipName,
    required this.userName,
    required this.userId,
    required this.status,
    required this.remarks,
    required this.bookingStatus,
    required this.bookedBy,
    required this.bookingColorCode,
    required this.serviceKmAlert,
    required this.seatingCapacity,
    this.currentKm,
    required this.purchaseType,
    required this.createdAt,
    required this.updatedAt,
    required this.vehicleDetails,
    required this.expiryDetails,
    required this.purchaseDetails,
    required this.resaleDetails,
    required this.theftDetails,
    required this.scrapDetails,
    required this.maintenanceDetails,
    this.expiryColor,
    this.alerts = const [],
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse alerts - handle different formats
      List<dynamic> alertsList = [];
      if (json['alerts'] != null) {
        if (json['alerts'] is List) {
          alertsList = json['alerts'] as List;
        } else if (json['alerts'] is String) {
          alertsList = [json['alerts']];
        } else if (json['alerts'] is Map) {
          alertsList = (json['alerts'] as Map).values.toList();
        }
      }

      return VehicleModel(
        id: json['_id']?.toString() ?? '',
        vehicleId: json['vehicle_id']?.toString() ??
            json['id']?.toString() ??
            json['_id']?.toString() ??
            '',
        vehicleNumber: json['vehicle_number']?.toString() ?? '',
        vehicleType: json['vehicle_type']?.toString() ?? '',
        ownershipName: json['ownership_name']?.toString() ?? '',
        userName: json['user_name']?.toString() ?? '',
        userId: json['user_id']?.toString() ??
            json['userId']?.toString() ??
            json['assigned_to']?.toString() ??
            '',
        status: json['status']?.toString() ??
            json['booking_color_code']?.toString() ??
            'green',
        remarks: json['remarks']?.toString() ?? '',
        bookingStatus: json['booking_status']?.toString() ?? 'Available',
        bookedBy: json['booked_by']?.toString() ?? '',
        bookingColorCode: json['booking_color_code']?.toString() ?? 'green',
        serviceKmAlert: json['service_km_alert']?.toString() ?? '',
        seatingCapacity: json['seating_capacity']?.toString() ?? '4',
        currentKm: json['current_km']?.toString(),
        purchaseType: json['purchase_type']?.toString() ?? 'NEW',
        createdAt: parseDateTimeFromJson(json['created_at']),
        updatedAt: parseDateTimeFromJson(json['updated_at']),
        vehicleDetails: VehicleDetails.fromJson(json['vehicle_details'] ?? {}),
        expiryDetails: ExpiryDetails.fromJson(json['expiry_details'] ?? {}),
        purchaseDetails:
            PurchaseDetails.fromJson(json['purchase_details'] ?? {}),
        resaleDetails: ResaleDetails.fromJson(json['resale_details'] ?? {}),
        theftDetails: TheftDetails.fromJson(json['theft_details'] ?? {}),
        scrapDetails: ScrapDetails.fromJson(json['scrap_details'] ?? {}),
        maintenanceDetails:
            MaintenanceDetails.fromJson(json['maintenance'] ?? {}),
        expiryColor: json['expiry_color'] != null
            ? ExpiryColor.fromJson(json['expiry_color'])
            : null,
        alerts: alertsList,
      );
    } catch (e) {
      debugPrint('❌ Error parsing vehicle ${json['vehicle_number']}: $e');
      
      // Create a minimal valid vehicle object as fallback
      return VehicleModel(
        id: json['_id']?.toString() ?? 'error',
        vehicleId: json['vehicle_id']?.toString() ?? 'error',
        vehicleNumber: json['vehicle_number']?.toString() ?? 'ERROR',
        vehicleType: json['vehicle_type']?.toString() ?? '',
        ownershipName: json['ownership_name']?.toString() ?? '',
        userName: json['user_name']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'green',
        remarks: json['remarks']?.toString() ?? '',
        bookingStatus: json['booking_status']?.toString() ?? 'Available',
        bookedBy: json['booked_by']?.toString() ?? '',
        bookingColorCode: json['booking_color_code']?.toString() ?? 'green',
        serviceKmAlert: json['service_km_alert']?.toString() ?? '',
        seatingCapacity: json['seating_capacity']?.toString() ?? '4',
        purchaseType: json['purchase_type']?.toString() ?? 'NEW',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        vehicleDetails: VehicleDetails.fromJson(json['vehicle_details'] ?? {}),
        expiryDetails: ExpiryDetails.fromJson(json['expiry_details'] ?? {}),
        purchaseDetails: PurchaseDetails.fromJson(json['purchase_details'] ?? {}),
        resaleDetails: ResaleDetails.fromJson(json['resale_details'] ?? { 'pay_recieved': false }),
        theftDetails: TheftDetails.fromJson(json['theft_details'] ?? {}),
        scrapDetails: ScrapDetails.fromJson(json['scrap_details'] ?? {}),
        maintenanceDetails: MaintenanceDetails.fromJson(json['maintenance'] ?? {}),
        alerts: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType,
      'ownership_name': ownershipName,
      'user_name': userName,
      'user_id': userId,
      'status': status,
      'remarks': remarks,
      'booking_status': bookingStatus,
      'booked_by': bookedBy,
      'booking_color_code': bookingColorCode,
      'service_km_alert': serviceKmAlert,
      'seating_capacity': seatingCapacity,
      'current_km': currentKm,
      'purchase_type': purchaseType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'alerts': alerts,
      'vehicle_details': vehicleDetails.toJson(),
      'expiry_details': expiryDetails.toJson(),
      'purchase_details': purchaseDetails.toJson(),
      'resale_details': resaleDetails.toJson(),
      'theft_details': theftDetails.toJson(),
      'scrap_details': scrapDetails.toJson(),
      'maintenance': maintenanceDetails.toJson(),
      'expiry_color': expiryColor?.toJson(),
    };
  }

  // Alias for fromJsonManual
  factory VehicleModel.fromJsonManual(Map<String, dynamic> json) {
    return VehicleModel.fromJson(json);
  }

  // Convenience getters
  String get brand => vehicleDetails.brand;
  String get model => vehicleDetails.model;
  List<String> get fuelType => vehicleDetails.fuelType;
  DateTime? get insuranceExpiry => expiryDetails.insuranceExpiry;
  DateTime? get rcBookExpiry => expiryDetails.rcBookExpiry;
  DateTime? get maintenanceExpiry => expiryDetails.maintenanceExpiry;
  DateTime? get pollutionExpiry => expiryDetails.pollutionExpiry;
  DateTime? get tyreExpiry => expiryDetails.tyreExpiry;
  DateTime? get batteryExpiry => expiryDetails.batteryExpiry;

  bool get hasAlerts => alerts.isNotEmpty;

  bool get isActive => status == 'Active' || status.toLowerCase() == 'green';
  bool get needsMaintenance =>
      status == 'Maintenance' ||
      status.toLowerCase() == 'orange' ||
      status.toLowerCase() == 'red';
  bool get isAvailable =>
      bookingStatus.toLowerCase() == 'available' && !needsMaintenance;

  bool get isInsuranceExpiring {
    if (insuranceExpiry == null) return false;
    final now = DateTime.now();
    final diff = insuranceExpiry!.difference(now).inDays;
    return diff <= 30 && diff > 0;
  }

  bool get isMaintenanceExpiring {
    if (maintenanceExpiry == null) return false;
    final now = DateTime.now();
    final diff = maintenanceExpiry!.difference(now).inDays;
    return diff <= 30 && diff > 0;
  }

  bool get isPollutionExpiring {
    if (pollutionExpiry == null) return false;
    final now = DateTime.now();
    final diff = pollutionExpiry!.difference(now).inDays;
    return diff <= 30 && diff > 0;
  }

  bool get isRcBookExpiring {
    if (rcBookExpiry == null) return false;
    final now = DateTime.now();
    final diff = rcBookExpiry!.difference(now).inDays;
    return diff <= 30 && diff > 0;
  }

  // Get status color for UI
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'green':
      case 'active':
        return Colors.green;
      case 'orange':
      case 'maintenance':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'grey':
      case 'gray':
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Get background color for status
  Color getStatusBackgroundColor() {
    switch (status.toLowerCase()) {
      case 'green':
      case 'active':
        return Colors.green.shade50;
      case 'orange':
      case 'maintenance':
        return Colors.orange.shade50;
      case 'red':
        return Colors.red.shade50;
      case 'grey':
      case 'gray':
      case 'inactive':
        return Colors.grey.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  // Get icon for status
  IconData getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'green':
      case 'active':
        return Icons.check_circle;
      case 'orange':
      case 'maintenance':
        return Icons.warning_amber;
      case 'red':
        return Icons.error;
      case 'grey':
      case 'gray':
      case 'inactive':
        return Icons.info;
      default:
        return Icons.info;
    }
  }

  // Check if any expiry is due soon
  bool get hasExpiringSoon {
    return isInsuranceExpiring ||
        isMaintenanceExpiring ||
        isPollutionExpiring ||
        isRcBookExpiring;
  }

  // Get all expiring items with their days left
  Map<String, int> getExpiringItems() {
    final now = DateTime.now();
    final expiring = <String, int>{};

    if (insuranceExpiry != null) {
      final days = insuranceExpiry!.difference(now).inDays;
      if (days <= 30 && days > 0) expiring['Insurance'] = days;
    }

    if (maintenanceExpiry != null) {
      final days = maintenanceExpiry!.difference(now).inDays;
      if (days <= 30 && days > 0) expiring['Maintenance'] = days;
    }

    if (pollutionExpiry != null) {
      final days = pollutionExpiry!.difference(now).inDays;
      if (days <= 30 && days > 0) expiring['Pollution'] = days;
    }

    if (rcBookExpiry != null) {
      final days = rcBookExpiry!.difference(now).inDays;
      if (days <= 30 && days > 0) expiring['RC Book'] = days;
    }

    return expiring;
  }

  // Copy with method for updating specific fields
  VehicleModel copyWith({
    String? id,
    String? vehicleId,
    String? vehicleNumber,
    String? vehicleType,
    String? ownershipName,
    String? userName,
    String? userId,
    String? status,
    String? remarks,
    String? bookingStatus,
    String? bookedBy,
    String? bookingColorCode,
    String? serviceKmAlert,
    String? seatingCapacity,
    String? currentKm,
    String? purchaseType,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<dynamic>? alerts,
    VehicleDetails? vehicleDetails,
    ExpiryDetails? expiryDetails,
    PurchaseDetails? purchaseDetails,
    ResaleDetails? resaleDetails,
    TheftDetails? theftDetails,
    ScrapDetails? scrapDetails,
    MaintenanceDetails? maintenanceDetails,
    ExpiryColor? expiryColor,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      ownershipName: ownershipName ?? this.ownershipName,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      bookedBy: bookedBy ?? this.bookedBy,
      bookingColorCode: bookingColorCode ?? this.bookingColorCode,
      serviceKmAlert: serviceKmAlert ?? this.serviceKmAlert,
      seatingCapacity: seatingCapacity ?? this.seatingCapacity,
      currentKm: currentKm ?? this.currentKm,
      purchaseType: purchaseType ?? this.purchaseType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      vehicleDetails: vehicleDetails ?? this.vehicleDetails,
      expiryDetails: expiryDetails ?? this.expiryDetails,
      purchaseDetails: purchaseDetails ?? this.purchaseDetails,
      resaleDetails: resaleDetails ?? this.resaleDetails,
      theftDetails: theftDetails ?? this.theftDetails,
      scrapDetails: scrapDetails ?? this.scrapDetails,
      maintenanceDetails: maintenanceDetails ?? this.maintenanceDetails,
      expiryColor: expiryColor ?? this.expiryColor,
      alerts: alerts ?? this.alerts,
    );
  }
}
