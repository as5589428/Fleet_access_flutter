import 'package:json_annotation/json_annotation.dart';

part 'trip_model.g.dart';

@JsonSerializable()
class TripModel {
  final String id;
  final String bookingId;
  final String vehicleId;
  final String vehicleNumber;
  final String driverId;
  final String? driverName;
  final String status;
  final double? startKm;
  final double? endKm;
  final String? startPhoto;
  final String? endPhoto;
  final String? startLocation;
  final String? endLocation;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? remarks;
  final bool? extensionRequested;
  final DateTime? extendedEndTime;
  final String? extensionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TripModel({
    required this.id,
    required this.bookingId,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.driverId,
    this.driverName,
    required this.status,
    this.startKm,
    this.endKm,
    this.startPhoto,
    this.endPhoto,
    this.startLocation,
    this.endLocation,
    this.startTime,
    this.endTime,
    this.remarks,
    this.extensionRequested,
    this.extendedEndTime,
    this.extensionReason,
    required this.createdAt,
    this.updatedAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) => _$TripModelFromJson(json);
  Map<String, dynamic> toJson() => _$TripModelToJson(this);

  double get totalKm => (endKm ?? 0) - (startKm ?? 0);
  
  Duration? get tripDuration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  TripModel copyWith({
    String? id,
    String? bookingId,
    String? vehicleId,
    String? vehicleNumber,
    String? driverId,
    String? driverName,
    String? status,
    double? startKm,
    double? endKm,
    String? startPhoto,
    String? endPhoto,
    String? startLocation,
    String? endLocation,
    DateTime? startTime,
    DateTime? endTime,
    String? remarks,
    bool? extensionRequested,
    DateTime? extendedEndTime,
    String? extensionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      status: status ?? this.status,
      startKm: startKm ?? this.startKm,
      endKm: endKm ?? this.endKm,
      startPhoto: startPhoto ?? this.startPhoto,
      endPhoto: endPhoto ?? this.endPhoto,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      remarks: remarks ?? this.remarks,
      extensionRequested: extensionRequested ?? this.extensionRequested,
      extendedEndTime: extendedEndTime ?? this.extendedEndTime,
      extensionReason: extensionReason ?? this.extensionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
