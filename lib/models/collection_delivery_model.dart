class DashboardInfo {
  final int scheduledCollection;
  final int collectedCount;
  final double collectedAmount;
  final int deliveredCount;
  final double deliveredAmount;
  final int pendingCollectedCount;
  final double pendingCollectedAmount;
  final int pendingDeliveryCount;
  final double pendingDeliveryAmount;
  final int todayTask;
  final int srfPending;

  const DashboardInfo({
    this.scheduledCollection = 0,
    this.collectedCount = 0,
    this.collectedAmount = 0,
    this.deliveredCount = 0,
    this.deliveredAmount = 0,
    this.pendingCollectedCount = 0,
    this.pendingCollectedAmount = 0,
    this.pendingDeliveryCount = 0,
    this.pendingDeliveryAmount = 0,
    this.todayTask = 0,
    this.srfPending = 0,
  });

  factory DashboardInfo.fromJson(Map<String, dynamic> json) {
    int i(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    double d(dynamic v) =>
        v is double ? v : double.tryParse(v?.toString() ?? '') ?? 0;

    final tc = json['totalCollected'] ?? {};
    final td = json['totalDelivered'] ?? {};
    final pc = json['pendingCollected'] ?? {};
    final pd = json['pendingDelivery'] ?? {};

    return DashboardInfo(
      scheduledCollection: i(json['scheduledCollection']),
      collectedCount: i(tc['count']),
      collectedAmount: d(tc['amount']),
      deliveredCount: i(td['count']),
      deliveredAmount: d(td['amount']),
      pendingCollectedCount: i(pc['count']),
      pendingCollectedAmount: d(pc['amount']),
      pendingDeliveryCount: i(pd['count']),
      pendingDeliveryAmount: d(pd['amount']),
      todayTask: i(json['todayTask']),
      srfPending: i(json['srfPending']),
    );
  }
}

class CollectionApiResponse {
  final List<CollectionDeliveryModel> data;
  final DashboardInfo dashboardInfo;

  CollectionApiResponse({required this.data, required this.dashboardInfo});
}

class CollectionDeliveryModel {
  String? id;
  String? companyId;
  String? plantId;
  String? plantName;
  String? collectionType; // "collection" or "delivery"
  String? collectionDate;
  String? selectedClient;
  String? clientName;
  String? contactPerson;
  String? contactPersonName;
  String? contactPersonEmail;
  String? contactPersonPhone;
  String? collectionRoute;
  String? routeDetails;
  int? instrumentCount;
  String? transferMode;
  String? mode; // mode label
  String? employeeAssigned;
  String? assignedEmployee;
  String? paymentCollection;
  double? collectedAmount;
  String? status; // "pending" or "completed"
  bool? isDelete;
  String? createdAt;
  String? updatedAt;

  // DC & Item Details (Section 1)
  String? dcNumber;
  String? qtyMentionedInDc;
  String? qtyCollected;
  String? dcImageUrl;
  String? instrumentId;
  List<String>? enclosures; // Manual, Accessories, Drawing, Others, Nil

  // Calibration Requirements (Section 2)
  String? requireStatementOfConformity;
  String? specificDecisionRule;
  String? serviceIfBadCondition;
  String? witnessCalibration;
  String? nextDueDateRequired;
  String? specificCalibrationPoint;
  String? remarksIfNotCollected;
  String? paymentCollected;

  // Travel & Performance (Section 3)
  String? collectedBy;
  String? startKm;
  String? startKmPhotoUrl;
  String? endKm;
  String? endKmPhotoUrl;
  String? specialRemarks;
  int? employeeRating;
  String? dcRemarks;
  String? instrumentIdSource;
  String? escalationRemarks;
  String? paymentPhotoUrl;
  String? collectionMode;
  String? taskStatus; // Pending or Completed

  CollectionDeliveryModel({
    this.id,
    this.companyId,
    this.plantId,
    this.plantName,
    this.collectionType,
    this.collectionDate,
    this.selectedClient,
    this.clientName,
    this.contactPerson,
    this.contactPersonName,
    this.contactPersonEmail,
    this.contactPersonPhone,
    this.collectionRoute,
    this.routeDetails,
    this.instrumentCount,
    this.transferMode,
    this.mode,
    this.employeeAssigned,
    this.assignedEmployee,
    this.paymentCollection,
    this.collectedAmount,
    this.status,
    this.isDelete,
    this.createdAt,
    this.updatedAt,
    this.dcNumber,
    this.qtyMentionedInDc,
    this.qtyCollected,
    this.dcImageUrl,
    this.instrumentId,
    this.enclosures,
    this.requireStatementOfConformity,
    this.specificDecisionRule,
    this.serviceIfBadCondition,
    this.witnessCalibration,
    this.nextDueDateRequired,
    this.specificCalibrationPoint,
    this.remarksIfNotCollected,
    this.paymentCollected,
    this.collectedBy,
    this.startKm,
    this.startKmPhotoUrl,
    this.endKm,
    this.endKmPhotoUrl,
    this.specialRemarks,
    this.employeeRating,
    this.dcRemarks,
    this.instrumentIdSource,
    this.escalationRemarks,
    this.paymentPhotoUrl,
    this.collectionMode,
    this.taskStatus,
  });

  factory CollectionDeliveryModel.fromJson(Map<String, dynamic> json) {
    return CollectionDeliveryModel(
      id: json['_id'] ?? json['id'],
      companyId: json['companyId'],
      plantId: json['plantId'],
      plantName: json['plant_name'],
      collectionType: json['collection_type'],
      collectionDate: json['collection_date'],
      selectedClient: json['selected_client'],
      clientName: json['client_name'],
      contactPerson: json['contact_person'],
      contactPersonName: json['contact_person_name'],
      contactPersonEmail: json['contact_person_email'],
      contactPersonPhone: json['contact_person_phone'],
      collectionRoute: json['collection_route'],
      routeDetails: json['route_details'],
      instrumentCount: json['instrument_count'] is int
          ? json['instrument_count']
          : int.tryParse(json['instrument_count']?.toString() ?? ''),
      transferMode: json['transfer_mode'],
      mode: json['mode'],
      employeeAssigned: json['employee_assigned'],
      assignedEmployee: json['assigned_employee'],
      paymentCollection: json['payment_collection'],
      collectedAmount: json['collected_amount'] is double
          ? json['collected_amount']
          : double.tryParse(json['collected_amount']?.toString() ?? ''),
      status: json['status'],
      isDelete: json['isDelete'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      // DC & Item Details
      dcNumber: json['dc_number'],
      qtyMentionedInDc: json['qty_mentioned_in_dc'],
      qtyCollected: json['qty_collected'],
      dcImageUrl: json['dc_image_url'],
      instrumentId: json['instrument_id'],
      enclosures: json['enclosures'] != null
          ? List<String>.from(json['enclosures'])
          : [],
      // Calibration
      requireStatementOfConformity:
          json['require_statement_of_conformity'] ?? 'No',
      specificDecisionRule: json['specific_decision_rule'] ?? 'No',
      serviceIfBadCondition: json['service_if_bad_condition'] ?? 'No',
      witnessCalibration: json['witness_calibration'] ?? 'No',
      nextDueDateRequired: json['next_due_date_required'] ?? 'No',
      specificCalibrationPoint: json['specific_calibration_point'] ?? 'No',
      remarksIfNotCollected: json['remarks_if_not_collected'],
      paymentCollected: json['payment_collected'],
      // Travel & Performance
      collectedBy: json['collected_by'],
      startKm: json['start_km']?.toString(),
      startKmPhotoUrl: json['start_km_photo_url'],
      endKm: json['end_km']?.toString(),
      endKmPhotoUrl: json['end_km_photo_url'],
      specialRemarks: json['special_remarks'],
      employeeRating: json['employee_rating'] is int
          ? json['employee_rating']
          : int.tryParse(json['employee_rating']?.toString() ?? ''),
      dcRemarks: json['dc_remarks'],
      instrumentIdSource: json['instrument_id_source'],
      escalationRemarks: json['escalation_remarks'],
      paymentPhotoUrl: json['payment_photo_url'] ?? json['payment_photo'],
      collectionMode: json['collection_mode'],
      taskStatus: json['task_status'] ?? json['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (companyId != null) 'companyId': companyId,
      if (plantId != null) 'plantId': plantId,
      'collection_type': collectionType,
      'collection_date': collectionDate,
      'selected_client': selectedClient,
      'contact_person': contactPerson,
      'collection_route': collectionRoute,
      'instrument_count': instrumentCount,
      'transfer_mode': transferMode,
      'employee_assigned': employeeAssigned,
      'payment_collection': paymentCollection,
      if (collectedAmount != null) 'collected_amount': collectedAmount,
      'status': status,
      if (dcNumber != null) 'dc_number': dcNumber,
      if (qtyMentionedInDc != null) 'qty_mentioned_in_dc': qtyMentionedInDc,
      if (qtyCollected != null) 'qty_collected': qtyCollected,
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (enclosures != null) 'enclosures': enclosures,
      'require_statement_of_conformity': requireStatementOfConformity ?? 'No',
      'specific_decision_rule': specificDecisionRule ?? 'No',
      'service_if_bad_condition': serviceIfBadCondition ?? 'No',
      'witness_calibration': witnessCalibration ?? 'No',
      'next_due_date_required': nextDueDateRequired ?? 'No',
      'specific_calibration_point': specificCalibrationPoint ?? 'No',
      if (remarksIfNotCollected != null)
        'remarks_if_not_collected': remarksIfNotCollected,
      if (paymentCollected != null) 'payment_collected': paymentCollected,
      if (collectedBy != null) 'collected_by': collectedBy,
      if (startKm != null) 'start_km': startKm,
      if (endKm != null) 'end_km': endKm,
      if (specialRemarks != null) 'special_remarks': specialRemarks,
      if (employeeRating != null) 'employee_rating': employeeRating,
      if (dcRemarks != null) 'dc_remarks': dcRemarks,
      if (instrumentIdSource != null)
        'instrument_id_source': instrumentIdSource,
      if (escalationRemarks != null) 'escalation_remarks': escalationRemarks,
      if (paymentPhotoUrl != null) 'payment_photo_url': paymentPhotoUrl,
      if (collectionMode != null) 'collection_mode': collectionMode,
      'task_status': taskStatus ?? 'Pending',
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      "_id": id,
      "companyId": companyId,
      "employee_entry": {
        "dc_number": dcNumber,
        "qty_in_dc": qtyMentionedInDc,
        "qty_collected": qtyCollected,
        "upload_dc": null,
        "dc_remarks": dcRemarks,
        "enclosures": enclosures,
        "instrument_id_source": instrumentIdSource,
        "require_conformity": requireStatementOfConformity,
        "specific_decision_rule": specificDecisionRule,
        "service_if_bad_condition": serviceIfBadCondition,
        "witness_calibration": witnessCalibration,
        "next_due_date_required": nextDueDateRequired,
        "specific_calibration_point": specificCalibrationPoint,
        "escalation_remarks": escalationRemarks,
        "payment_collected": paymentCollected,
        "payment_photo": null,
        "special_remarks": specialRemarks,
        "collection_mode": collectionMode,
        "start_km": startKm,
        "start_km_photo": null,
        "end_km": endKm,
        "end_km_photo": null,
      }
    };
  }
}
