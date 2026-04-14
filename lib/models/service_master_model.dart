class ServiceMasterModel {
  final String? id;
  final String? serviceId;
  final String? serviceCenterName;
  final String? address;
  final String? contactPersonName;
  final String? designation;
  final String? mobileNumber;
  final String? landlineNumber;
  final String? emailIdPersonal;
  final String? emailIdOffice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceMasterModel({
    this.id,
    this.serviceId,
    this.serviceCenterName,
    this.address,
    this.contactPersonName,
    this.designation,
    this.mobileNumber,
    this.landlineNumber,
    this.emailIdPersonal,
    this.emailIdOffice,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceMasterModel.fromJson(Map<String, dynamic> json) {
    return ServiceMasterModel(
      id: json['_id'] as String?,
      serviceId: json['service_id'] as String?,
      serviceCenterName: json['service_center_name'] as String?,
      address: json['address'] as String?,
      contactPersonName: json['contact_person_name'] as String?,
      designation: json['designation'] as String?,
      mobileNumber: json['mobile_number'] as String?,
      landlineNumber: json['landline_number'] as String?,
      emailIdPersonal: json['email_id_personal'] as String?,
      emailIdOffice: json['email_id_office'] as String?,
      createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['_id'] = id;
    if (serviceId != null) data['service_id'] = serviceId;
    if (serviceCenterName != null) data['service_center_name'] = serviceCenterName;
    if (address != null) data['address'] = address;
    if (contactPersonName != null) data['contact_person_name'] = contactPersonName;
    if (designation != null) data['designation'] = designation;
    if (mobileNumber != null) data['mobile_number'] = mobileNumber;
    if (landlineNumber != null) data['landline_number'] = landlineNumber;
    if (emailIdPersonal != null) data['email_id_personal'] = emailIdPersonal;
    if (emailIdOffice != null) data['email_id_office'] = emailIdOffice;
    if (createdAt != null) data['createdAt'] = createdAt!.toIso8601String();
    if (updatedAt != null) data['updatedAt'] = updatedAt!.toIso8601String();
    return data;
  }

  ServiceMasterModel copyWith({
    String? id,
    String? serviceId,
    String? serviceCenterName,
    String? address,
    String? contactPersonName,
    String? designation,
    String? mobileNumber,
    String? landlineNumber,
    String? emailIdPersonal,
    String? emailIdOffice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceMasterModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceCenterName: serviceCenterName ?? this.serviceCenterName,
      address: address ?? this.address,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      designation: designation ?? this.designation,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      landlineNumber: landlineNumber ?? this.landlineNumber,
      emailIdPersonal: emailIdPersonal ?? this.emailIdPersonal,
      emailIdOffice: emailIdOffice ?? this.emailIdOffice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
