// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TripModel _$TripModelFromJson(Map<String, dynamic> json) => TripModel(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      vehicleId: json['vehicleId'] as String,
      vehicleNumber: json['vehicleNumber'] as String,
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String?,
      status: json['status'] as String,
      startKm: (json['startKm'] as num?)?.toDouble(),
      endKm: (json['endKm'] as num?)?.toDouble(),
      startPhoto: json['startPhoto'] as String?,
      endPhoto: json['endPhoto'] as String?,
      startLocation: json['startLocation'] as String?,
      endLocation: json['endLocation'] as String?,
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      remarks: json['remarks'] as String?,
      extensionRequested: json['extensionRequested'] as bool?,
      extendedEndTime: json['extendedEndTime'] == null
          ? null
          : DateTime.parse(json['extendedEndTime'] as String),
      extensionReason: json['extensionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TripModelToJson(TripModel instance) => <String, dynamic>{
      'id': instance.id,
      'bookingId': instance.bookingId,
      'vehicleId': instance.vehicleId,
      'vehicleNumber': instance.vehicleNumber,
      'driverId': instance.driverId,
      'driverName': instance.driverName,
      'status': instance.status,
      'startKm': instance.startKm,
      'endKm': instance.endKm,
      'startPhoto': instance.startPhoto,
      'endPhoto': instance.endPhoto,
      'startLocation': instance.startLocation,
      'endLocation': instance.endLocation,
      'startTime': instance.startTime?.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'remarks': instance.remarks,
      'extensionRequested': instance.extensionRequested,
      'extendedEndTime': instance.extendedEndTime?.toIso8601String(),
      'extensionReason': instance.extensionReason,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
