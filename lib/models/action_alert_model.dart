class ActionAlert {
  final String id;
  final String vehicleNumber;
  final String description;
  final String alertType;
  final String status;
  final String date;
  final String? person;
  final String? remarks;
  final String? actionTaken;
  final String? performedBy;
  final String? actionTakenDate;
  final String createdAt;

  ActionAlert({
    required this.id,
    required this.vehicleNumber,
    required this.description,
    required this.alertType,
    required this.status,
    required this.date,
    this.person,
    this.remarks,
    this.actionTaken,
    this.performedBy,
    this.actionTakenDate,
    required this.createdAt,
  });

  factory ActionAlert.fromJson(Map<String, dynamic> json) {
    return ActionAlert(
      id: json['_id'] ?? json['id'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      description: json['description'] ?? '',
      alertType: json['alert_type'] ?? '',
      status: json['status'] ?? 'Open',
      date: json['date'] ?? '',
      person: json['person'],
      remarks: json['remarks'],
      actionTaken: json['action_taken'],
      performedBy: json['performed_by'],
      actionTakenDate: json['action_taken_date'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'vehicle_number': vehicleNumber,
      'description': description,
      'alert_type': alertType,
      'status': status,
      'date': date,
      'person': person,
      'remarks': remarks,
      'action_taken': actionTaken,
      'performed_by': performedBy,
      'action_taken_date': actionTakenDate,
      'createdAt': createdAt,
    };
  }

  String get displayMessage => '$vehicleNumber: $description';

  bool get isOpen => status == 'Open';
  bool get isClosed => status == 'Closed';
}
