// lib/models/special_maintenance_model.dart
class SpecialMaintenanceRecord {
  final String id;
  final String maintenanceId;
  final String vehicleId;
  final String vehicleNumber;
  final String vehicleType;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String maintenanceType; // Add this field from API

  final BatteryMaintenance? battery;
  final TyreMaintenance? tyre;
  final WheelBalancing? wheelBalancing;

  SpecialMaintenanceRecord({
    required this.id,
    required this.maintenanceId,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
    required this.maintenanceType, // Add to constructor
    this.battery,
    this.tyre,
    this.wheelBalancing,
  });

  factory SpecialMaintenanceRecord.fromJson(Map<String, dynamic> json) {
    // Determine maintenance type from API
    final apiMaintenanceType = json['maintenance_type']?.toString().toLowerCase() ?? '';
    
    // Parse nested data based on type
    BatteryMaintenance? batteryData;
    TyreMaintenance? tyreData;
    WheelBalancing? wheelBalancingData;
    
    if (apiMaintenanceType.contains('batery') || apiMaintenanceType.contains('battery')) {
      batteryData = json['battery'] != null
          ? BatteryMaintenance.fromJson(json['battery'])
          : null;
    } else if (apiMaintenanceType.contains('tyre')) {
      tyreData = json['tyre'] != null
          ? TyreMaintenance.fromJson(json['tyre'])
          : null;
    } else if (apiMaintenanceType.contains('wheel')) {
      wheelBalancingData = json['wheel_balancing'] != null
          ? WheelBalancing.fromJson(json['wheel_balancing'])
          : null;
    }

    return SpecialMaintenanceRecord(
      id: json['_id'] ?? '',
      maintenanceId: json['maintenance_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      vehicleType: json['vehicle_type'] ?? json['type_of_vehicle'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      maintenanceType: _getMaintenanceTypeLabel(apiMaintenanceType),
      battery: batteryData,
      tyre: tyreData,
      wheelBalancing: wheelBalancingData,
    );
  }

  static String _getMaintenanceTypeLabel(String apiType) {
    if (apiType.contains('batery') || apiType.contains('battery')) return 'Battery';
    if (apiType.contains('tyre')) return 'Tyre';
    if (apiType.contains('wheel')) return 'Wheel Balancing';
    return 'Unknown';
  }

  // Getter for UI display
  String get displayMaintenanceType {
    return maintenanceType;
  }

  double get cost {
    if (battery != null) return battery!.cost;
    if (tyre != null) return tyre!.cost;
    if (wheelBalancing != null) return wheelBalancing!.cost;
    return 0;
  }

  DateTime? get serviceDate {
    if (battery != null) return battery?.date;
    if (tyre != null) return tyre?.date;
    if (wheelBalancing != null) return wheelBalancing?.date;
    return null;
  }

  String? get serviceCenter {
    return battery?.serviceCenter ??
        tyre?.serviceCenter ??
        wheelBalancing?.serviceCenter;
  }

  bool get isReturned {
    if (battery != null) return battery?.isReturned ?? false;
    if (tyre != null) return tyre?.isReturned ?? false;
    if (wheelBalancing != null) return wheelBalancing?.isReturned ?? false;
    return false;
  }
}

class BatteryMaintenance {
  final DateTime date;
  final double cost;
  final String serviceCenter;
  final String batteryNumber;
  final DateTime warrantyDate;
  final DateTime? dateOfReturn;
  final String remarks;
  final List<String> billUpload;
  final String id;
  final int km;
  final bool isReturned; // Add this field
  final String typeOfVehicle;

  BatteryMaintenance({
    required this.date,
    required this.cost,
    required this.serviceCenter,
    required this.batteryNumber,
    required this.warrantyDate,
    this.dateOfReturn,
    required this.remarks,
    required this.billUpload,
    required this.id,
    required this.km,
    required this.isReturned,
    required this.typeOfVehicle,
  });

  factory BatteryMaintenance.fromJson(Map<String, dynamic> json) {
    return BatteryMaintenance(
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      serviceCenter: json['service_center'] ?? '',
      batteryNumber: json['si_no'] ?? json['battery_number'] ?? '',
      warrantyDate: json['warranty_date'] != null &&
              json['warranty_date'].toString().isNotEmpty
          ? DateTime.parse(json['warranty_date'])
          : DateTime.now().add(const Duration(days: 365)),
      dateOfReturn: json['date_of_return'] != null &&
              json['date_of_return'].toString().isNotEmpty
          ? DateTime.parse(json['date_of_return'])
          : null,
      remarks: json['remarks'] ?? '',
      billUpload: List<String>.from(json['bill_upload'] ?? []),
      id: json['_id'] ?? '',
      km: (json['km'] as num?)?.toInt() ?? 0,
      isReturned: json['is_returned'] ?? false,
      typeOfVehicle: json['type_of_vehicle'] ?? '',
    );
  }
}

class TyreMaintenance {
  final DateTime date;
  final double cost;
  final String serviceCenter;
  final String tyreNumber;
  final String tyreBrand;
  final DateTime? dateOfReturn;
  final String remarks;
  final List<String> billUpload;
  final String id;
  final int km;
  final int? dueKm; // Add dueKm field
  final bool isReturned; // Add isReturned field
  final String typeOfVehicle;

  TyreMaintenance({
    required this.date,
    required this.cost,
    required this.serviceCenter,
    required this.tyreNumber,
    required this.tyreBrand,
    this.dateOfReturn,
    required this.remarks,
    required this.billUpload,
    required this.id,
    required this.km,
    this.dueKm,
    required this.isReturned,
    required this.typeOfVehicle,
  });

  factory TyreMaintenance.fromJson(Map<String, dynamic> json) {
    return TyreMaintenance(
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      serviceCenter: json['service_center'] ?? '',
      tyreNumber: json['tyre_number'] ?? '',
      tyreBrand: json['tyre_brand'] ?? '',
      dateOfReturn: json['date_of_return'] != null &&
              json['date_of_return'].toString().isNotEmpty
          ? DateTime.parse(json['date_of_return'])
          : null,
      remarks: json['remarks'] ?? '',
      billUpload: List<String>.from(json['bill_upload'] ?? []),
      id: json['_id'] ?? '',
      km: (json['km'] as num?)?.toInt() ?? 0,
      dueKm: (json['due_km'] as num?)?.toInt(),
      isReturned: json['is_returned'] ?? false,
      typeOfVehicle: json['type_of_vehicle'] ?? '',
    );
  }
}

class WheelBalancing {
  final DateTime date;
  final double cost;
  final String serviceCenter;
  final DateTime? dateOfReturn;
  final String remarks;
  final List<String> billUpload;
  final String id;
  final int km;
  final int? dueKm; // Add dueKm field
  final bool isReturned; // Add isReturned field
  final String typeOfVehicle;

  WheelBalancing({
    required this.date,
    required this.cost,
    required this.serviceCenter,
    this.dateOfReturn,
    required this.remarks,
    required this.billUpload,
    required this.id,
    required this.km,
    this.dueKm,
    required this.isReturned,
    required this.typeOfVehicle,
  });

  factory WheelBalancing.fromJson(Map<String, dynamic> json) {
    return WheelBalancing(
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      serviceCenter: json['service_center'] ?? '',
      dateOfReturn: json['date_of_return'] != null &&
              json['date_of_return'].toString().isNotEmpty
          ? DateTime.parse(json['date_of_return'])
          : null,
      remarks: json['remarks'] ?? '',
      billUpload: List<String>.from(json['bill_upload'] ?? []),
      id: json['_id'] ?? '',
      km: (json['km'] as num?)?.toInt() ?? 0,
      dueKm: (json['due_km'] as num?)?.toInt(),
      isReturned: json['is_returned'] ?? false,
      typeOfVehicle: json['type_of_vehicle'] ?? '',
    );
  }
}
