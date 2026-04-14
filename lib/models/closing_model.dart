// closing_model.dart
class ClosingRecord {
  final String? id;
  final String vehicleId;
  final String vehicleNumber;
  final String userId;
  final int endKm;
  final String remarks;
  final bool isRemarks;
  final List<String> photos;
  final String? alertType;
  final String? createdAt;
  final String? updatedAt;

  ClosingRecord({
    this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.userId,
    required this.endKm,
    required this.remarks,
    required this.isRemarks,
    required this.photos,
    this.alertType,
    this.createdAt,
    this.updatedAt,
  });

  factory ClosingRecord.fromJson(Map<String, dynamic> json) {
    return ClosingRecord(
      id: json['_id'],
      vehicleId: json['vehicle_id'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      userId: json['user_id'] ?? '',
      endKm: json['endkm'] is int
          ? json['endkm']
          : int.tryParse(json['endkm'].toString()) ?? 0,
      remarks: json['remarks'] ?? '',
      isRemarks: json['is_remarks'] ?? false,
      photos: List<String>.from(json['photos'] ?? []),
      alertType: json['alert_type'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber,
      'user_id': userId,
      'endkm': endKm,
      'remarks': remarks,
      'is_remarks': isRemarks,
      'photos': photos,
      'alert_type': alertType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Helper method for update operations (optional)
  Map<String, dynamic> toUpdateJson() {
    return {
      'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber,
      'user_id': userId,
      'endkm': endKm,
      'remarks': remarks,
      'is_remarks': isRemarks,
      'alert_type': alertType,
      'photos': photos,
    };
  }
}
