import 'package:json_annotation/json_annotation.dart';

part 'booking_model.g.dart';

@JsonSerializable()
class BookingModel {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String vehicleType;
  final String? vehicleId;
  final String? vehicleNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String purpose;
  final String status;
  final String? remarks;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BookingModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.vehicleType,
    this.vehicleId,
    this.vehicleNumber,
    required this.startDate,
    required this.endDate,
    required this.purpose,
    required this.status,
    this.remarks,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => _$BookingModelFromJson(json);
  Map<String, dynamic> toJson() => _$BookingModelToJson(this);

  BookingModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? vehicleType,
    String? vehicleId,
    String? vehicleNumber,
    DateTime? startDate,
    DateTime? endDate,
    String? purpose,
    String? status,
    String? remarks,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
