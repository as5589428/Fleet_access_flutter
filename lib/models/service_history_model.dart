// lib/models/service_history_model.dart
class ServiceItem {
  final String id;
  final String userId;
  final String userName;
  final String vehicleId;
  final String vehicleNumber;
  final String date;
  final int? km;
  final double cost;
  final String? remarks;
  final String? serviceType; // For categorization

  ServiceItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.date,
    this.km,
    required this.cost,
    this.remarks,
    this.serviceType,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json, {String? type}) {
    return ServiceItem(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      date: json['date'] ?? '',
      km: json['km'] != null ? int.tryParse(json['km'].toString()) : null,
      cost: json['cost'] != null
          ? double.tryParse(json['cost'].toString()) ?? 0.0
          : 0.0,
      remarks: json['remarks'] ?? '',
      serviceType: type,
    );
  }
}

class BatteryChange extends ServiceItem {
  final String siNo;
  final String warrantyDate;

  BatteryChange({
    required super.id,
    required super.userId,
    required super.userName,
    required super.vehicleId,
    required super.vehicleNumber,
    required super.date,
    super.cost = 0.0,
    super.remarks,
    required this.siNo,
    required this.warrantyDate,
  }) : super(
          serviceType: 'battery',
        );

  factory BatteryChange.fromJson(Map<String, dynamic> json) {
    return BatteryChange(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      date: json['date'] ?? '',
      cost: json['cost'] != null
          ? double.tryParse(json['cost'].toString()) ?? 0.0
          : 0.0,
      remarks: json['remarks'] ?? '',
      siNo: json['si_no'] ?? '',
      warrantyDate: json['warranty_date'] ?? '',
    );
  }
}

class TyreChange extends ServiceItem {
  final String typeOfVehicle;

  TyreChange({
    required super.id,
    required super.userId,
    required super.userName,
    required super.vehicleId,
    required super.vehicleNumber,
    required super.date,
    super.km,
    super.cost = 0.0,
    super.remarks,
    required this.typeOfVehicle,
  }) : super(
          serviceType: 'tyre',
        );

  factory TyreChange.fromJson(Map<String, dynamic> json) {
    return TyreChange(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      date: json['date'] ?? '',
      km: json['km'] != null ? int.tryParse(json['km'].toString()) : null,
      cost: json['cost'] != null
          ? double.tryParse(json['cost'].toString()) ?? 0.0
          : 0.0,
      remarks: json['remarks'] ?? '',
      typeOfVehicle: json['type_of_vehicle'] ?? '',
    );
  }
}

class WheelBalancing extends ServiceItem {
  final int dueKm;

  WheelBalancing({
    required super.id,
    required super.userId,
    required super.userName,
    required super.vehicleId,
    required super.vehicleNumber,
    required super.date,
    super.km,
    super.cost = 0.0,
    super.remarks,
    required this.dueKm,
  }) : super(
          serviceType: 'wheel',
        );

  factory WheelBalancing.fromJson(Map<String, dynamic> json) {
    return WheelBalancing(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      date: json['date'] ?? '',
      km: json['km'] != null ? int.tryParse(json['km'].toString()) : null,
      cost: json['cost'] != null
          ? double.tryParse(json['cost'].toString()) ?? 0.0
          : 0.0,
      remarks: json['remarks'] ?? '',
      dueKm: json['due_km'] != null
          ? int.tryParse(json['due_km'].toString()) ?? 0
          : 0,
    );
  }
}
