class VehicleStartModel {
  String? id;
  String? vehicleId;
  String? vehicleNumber;
  String? startKm;
  List<String>? startPhotos; // List of URLs for start photos (max 5)
  String? mapUpload; // URL for map screenshot
  String? editPhoto; // URL for edit photo (required if KM is edited)
  String? remarks;
  String? alertType;
  bool? isEdit;
  String? updatedStartKm;
  bool? locationConfirmed;
  String? createdAt;
  String? updatedAt;

  VehicleStartModel({
    this.id,
    this.vehicleId,
    this.vehicleNumber,
    this.startKm,
    this.startPhotos,
    this.mapUpload,
    this.editPhoto,
    this.remarks,
    this.alertType,
    this.isEdit,
    this.updatedStartKm,
    this.locationConfirmed,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleStartModel.fromJson(Map<String, dynamic> json) {
    // Handle start photos which could be a String or List<dynamic>
    List<String> photos = [];
    if (json['start_photo'] != null) {
      if (json['start_photo'] is List) {
        photos = List<String>.from(json['start_photo']);
      } else if (json['start_photo'] is String) {
        photos = [json['start_photo']];
      }
    }

    // Handle map upload correctly depending on API response format
    String? mapUrl;
    bool locationConfirmed = false;
    if (json['map_upload'] != null) {
      if (json['map_upload'] is Map) {
        mapUrl = json['map_upload']['url'];
        locationConfirmed = json['map_upload']['location_confirmed'] == true ||
            json['map_upload']['location_confirmed'] == 'true';
      } else if (json['map_upload'] is String) {
        mapUrl = json['map_upload'];
      }
    }
    
    // Handle edit photo correctly depending on API response format
    String? editUrl;
    if (json['edit_photo'] != null) {
      if (json['edit_photo'] is Map) {
         editUrl = json['edit_photo']['url'];
      } else if (json['edit_photo'] is String) {
        editUrl = json['edit_photo'];
      }
    }

    return VehicleStartModel(
      id: json['_id'] ?? json['id'],
      vehicleId: json['vehicle_id'],
      vehicleNumber: json['vehicle_number'],
      startKm: json['start_km']?.toString(),
      startPhotos: photos,
      mapUpload: mapUrl,
      editPhoto: editUrl,
      remarks: json['remarks'],
      alertType: json['alert_type'] ?? 'Normal',
      isEdit: json['is_edit'] == true || json['is_edit'] == 'true',
      updatedStartKm: json['updated_start_km']?.toString(),
      locationConfirmed: locationConfirmed,
      createdAt: json['createdAt'] ?? json['created_at'],
      updatedAt: json['updatedAt'] ?? json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber,
      'start_km': startKm,
      if (remarks != null) 'remarks': remarks,
      'alert_type': alertType ?? 'Normal',
      'is_edit': isEdit ?? false,
      if (updatedStartKm != null) 'updated_start_km': updatedStartKm,
    };
  }
}

class VehicleDropdownModel {
  String? id;
  String? vehicleNumber;
  String? currentKm;

  VehicleDropdownModel({
    this.id,
    this.vehicleNumber,
    this.currentKm,
  });

  factory VehicleDropdownModel.fromJson(dynamic json) {
    if (json is String) {
      return VehicleDropdownModel(
        id: json,
        vehicleNumber: json,
        currentKm: '',
      );
    }
    
    if (json is Map<String, dynamic>) {
      return VehicleDropdownModel(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        vehicleNumber: json['vehicle_number']?.toString() ?? 
                       json['vehicleNumber']?.toString() ?? 
                       json['vehicle_id']?.toString() ?? '',
        currentKm: json['current_km']?.toString() ?? 
                   json['currentKm']?.toString() ?? '',
      );
    }
    
    return VehicleDropdownModel(vehicleNumber: 'Unknown');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleDropdownModel &&
          runtimeType == other.runtimeType &&
          vehicleNumber == other.vehicleNumber;

  @override
  int get hashCode => vehicleNumber.hashCode;
}
