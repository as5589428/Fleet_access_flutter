// lib/providers/maintenance_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';

class GeneralMaintenanceRecord {
  final String id;
  final String vehicleId;
  final String vehicleNumber;
  final String vehicleType;
  final String userId;
  final String userName;
  final DateTime date;
  final int km;
  final double cost;
  final String reason;
  final String remarks;
  final int nextServiceKm;
  final DateTime? nextServiceDate;
  final List<String> billUpload;
  final DateTime createdAt;

  // NEW FIELDS
  final String? maintenanceType;
  final String? serviceCenter;
  final DateTime? dateOfReturn;
  final bool isReturned;
  final String? typeOfVehicle;

  // Type-specific fields
  final String? siNo;
  final DateTime? warrantyDate;
  final int? dueKm;

  GeneralMaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.userId,
    required this.userName,
    required this.date,
    required this.km,
    required this.cost,
    required this.reason,
    required this.remarks,
    required this.nextServiceKm,
    this.nextServiceDate,
    required this.billUpload,
    required this.createdAt,

    // NEW FIELDS
    this.maintenanceType,
    this.serviceCenter,
    this.dateOfReturn,
    this.isReturned = false,
    this.typeOfVehicle,

    // Type-specific fields
    this.siNo,
    this.warrantyDate,
    this.dueKm,
  });

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber,
      'type_of_vehicle': vehicleType,
      'user_id': userId,
      'user_name': userName,
      'date': date.toIso8601String().split('T')[0],
      'km': km,
      'cost': cost,
      'reason': reason,
      'remarks': remarks,
      'next_service_km': nextServiceKm,
      'next_service_date': nextServiceDate?.toIso8601String().split('T')[0],
      'bill_upload': billUpload,
      'maintenance_type': maintenanceType,
      'service_center': serviceCenter,
      'date_of_return': dateOfReturn?.toIso8601String().split('T')[0],
      'is_returned': isReturned,
      'si_no': siNo,
      'warranty_date': warrantyDate?.toIso8601String().split('T')[0],
      'due_km': dueKm,
    };
  }

  factory GeneralMaintenanceRecord.fromJson(Map<String, dynamic> json) {
    // Determine maintenance type from nested structure (like React's extractNestedData)
    String maintType = json['maintenance_type'] ?? 'general';
    if (maintType.isEmpty) {
      if (json['general_maintenance'] != null) {
        maintType = 'general';
      } else if (json['tyre'] != null) {
        maintType = 'tyre';
      } else if (json['wheel_balancing'] != null) {
        maintType = 'wheel_balancing';
      } else if (json['battery'] != null) {
        maintType = 'batery';
      }
    }

    // Get nested data based on type (like React's nestedData)
    Map<String, dynamic> nestedData = {};
    if (maintType == 'general' && json['general_maintenance'] != null) {
      nestedData = json['general_maintenance'];
    } else if (maintType == 'tyre' && json['tyre'] != null) {
      nestedData = json['tyre'];
    } else if (maintType == 'wheel_balancing' &&
        json['wheel_balancing'] != null) {
      nestedData = json['wheel_balancing'];
    } else if ((maintType == 'battery' || maintType == 'batery') &&
        json['battery'] != null) {
      nestedData = json['battery'];
    }

    return GeneralMaintenanceRecord(
      id: json['_id'] ?? json['id'] ?? '',
      vehicleId: json['vehicle_id'] ?? nestedData['vehicle_id'] ?? '',
      vehicleNumber:
          json['vehicle_number'] ?? nestedData['vehicle_number'] ?? '',
      vehicleType: json['vehicle_type'] ?? nestedData['type_of_vehicle'] ?? '',
      userId: json['user_id'] ?? nestedData['user_id'] ?? '',
      userName: json['user_name'] ?? nestedData['user_name'] ?? '',
      date: DateTime.parse(json['date'] ??
          nestedData['date'] ??
          DateTime.now().toIso8601String()),
      km: json['km'] ?? nestedData['km'] ?? 0,
      cost: (json['cost'] ?? nestedData['cost'] ?? 0).toDouble(),
      reason: json['reason'] ?? nestedData['reason'] ?? '',
      remarks: json['remarks'] ?? nestedData['remarks'] ?? '',
      nextServiceKm:
          json['next_service_km'] ?? nestedData['next_service_km'] ?? 0,
      nextServiceDate: json['next_service_date'] != null
          ? DateTime.parse(json['next_service_date'])
          : nestedData['next_service_date'] != null
              ? DateTime.parse(nestedData['next_service_date'])
              : null,
      billUpload: List<String>.from(
          json['bill_upload'] ?? nestedData['bill_upload'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),

      // NEW FIELDS
      maintenanceType: maintType == 'batery' ? 'batery' : maintType,
      serviceCenter:
          json['service_center'] ?? nestedData['service_center'] ?? '',
      dateOfReturn: json['date_of_return'] != null
          ? DateTime.parse(json['date_of_return'])
          : nestedData['date_of_return'] != null
              ? DateTime.parse(nestedData['date_of_return'])
              : null,
      isReturned: json['is_returned'] ?? nestedData['is_returned'] ?? false,
      typeOfVehicle:
          json['type_of_vehicle'] ?? nestedData['type_of_vehicle'] ?? 'Car',

      // Type-specific fields
      siNo: json['si_no'] ?? nestedData['si_no'] ?? '',
      warrantyDate: json['warranty_date'] != null
          ? DateTime.parse(json['warranty_date'])
          : nestedData['warranty_date'] != null
              ? DateTime.parse(nestedData['warranty_date'])
              : null,
      dueKm:
          json['due_km'] ?? nestedData['due_km'] ?? nestedData['Due_km'] ?? 0,
    );
  }
}

class GeneralMaintenanceProvider extends ChangeNotifier {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  List<GeneralMaintenanceRecord> _records = [];
  bool _isLoading = false;
  bool _dropdownLoading = false;
  String? _error;
  String? _apiError;
  List<String> _vehicleNumbers = [];
  List<String> _users = [];

  // Store full vehicle data including color codes
  List<Map<String, dynamic>> _vehicleNumbersFullData = [];
  List<Map<String, dynamic>> get vehicleNumbersFullData =>
      _vehicleNumbersFullData;

  // Store full user data to get user_id
  List<Map<String, dynamic>> _usersFullData = [];

  // API Configuration - Using single base URL like React
  static const String _baseUrl = AppConstants.baseUrl;
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // Form state - matching React's formData structure
  final Map<String, dynamic> _formData = {
    'vehicle_id': '',
    'vehicle_number': '',
    'vehicle_type': '',
    'user_id': '',
    'user_name': '',
    'date': DateTime.now(),
    'km': '',
    'cost': '',
    'reason': '',
    'remarks': '',
    'service_center': '',
    'date_of_return': null,
    'is_returned': false,
    'type_of_vehicle': '',
    'maintenance_type': 'general',

    // Type-specific fields
    'next_service_km': '',
    'next_service_date': null,
    'si_no': '',
    'warranty_date': null,
    'due_km': '',
    'bill_upload': [],
  };

  final Map<String, String> _formErrors = {};

  List<GeneralMaintenanceRecord> get records => _records;
  bool get isLoading => _isLoading;
  bool get dropdownLoading => _dropdownLoading;
  String? get error => _error;
  String? get apiError => _apiError;
  List<String> get vehicleNumbers => _vehicleNumbers;
  List<String> get users => _users;
  Map<String, dynamic> get formData => Map.from(_formData);
  Map<String, String> get formErrors => Map.from(_formErrors);

  // Map for color codes to text colors (matching React's getVehicleColorClass)
  Color _getVehicleColor(String? colorCode) {
    if (colorCode == null || colorCode.isEmpty) return const Color(0xFF374151);

    switch (colorCode) {
      case "Red":
        return const Color(0xFFDC2626);
      case "Blue":
        return const Color(0xFF2563EB);
      case "Green":
        return const Color(0xFF16A34A);
      case "Yellow":
        return const Color(0xFFCA8A04);
      case "Orange":
        return const Color(0xFFEA580C);
      case "Purple":
        return const Color(0xFF9333EA);
      case "Pink":
        return const Color(0xFFDB2777);
      case "Grey":
      case "Gray":
        return const Color(0xFF4B5563);
      case "Black":
        return const Color(0xFF000000);
      case "White":
        return const Color(0xFF1F2937);
      case "Brown":
        return const Color(0xFF92400E);
      case "Cyan":
        return const Color(0xFF0891B2);
      case "Teal":
        return const Color(0xFF0D9488);
      case "Indigo":
        return const Color(0xFF4F46E5);
      default:
        return const Color(0xFF374151);
    }
  }

  Color getVehicleColor(String vehicleNumber) {
    try {
      final vehicle = _vehicleNumbersFullData.firstWhere(
        (v) => v['vehicle_number'] == vehicleNumber,
      );
      final colorCode = vehicle['booking_color_code']?.toString();
      return _getVehicleColor(colorCode);
    } catch (e) {
      return const Color(0xFF374151);
    }
  }

  // Get API endpoint based on maintenance type
  String _getMaintenanceEndpoint(String? maintenanceType) {
    switch (maintenanceType) {
      case "general":
        return "/maintenance/general";
      case "battery":
      case "batery":
        return "/maintenance/battery";
      case "wheel_balancing":
        return "/maintenance/wheel-balancing";
      case "tyre":
        return "/maintenance/tyre";
      default:
        return "/maintenance/general";
    }
  }

  // ==================== MAINTENANCE TYPES API ====================

  Future<List<String>> getMaintenanceTypes() async {
    debugPrint('ðŸ”µ Fetching maintenance types from API...');
    final url = '$_baseUrl/maintenance/maintenance-types';
    debugPrint('ðŸ“¡ Full URL: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      debugPrint('ðŸ“¡ Response status: ${response.statusCode}');
      debugPrint('ðŸ“¡ Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<String> types = [];

        if (data is Map && data.containsKey('data')) {
          final dataList = data['data'];
          if (dataList is List) {
            types = dataList.map((item) => item.toString()).toList();
            debugPrint('âœ… Successfully fetched maintenance types: $types');
            return types;
          }
        } else if (data['status'] == "success" && data['data'] is List) {
          types = List<String>.from(data['data']);
          debugPrint('âœ… Successfully fetched maintenance types: $types');
          return types;
        }
      }

      debugPrint('âš ï¸ Using default maintenance types');
      return ["general", "battery", "wheel_balancing", "tyre"];
    } catch (e) {
      debugPrint('âŒ Error fetching maintenance types: $e');
      return ["general", "battery", "wheel_balancing", "tyre"];
    }
  }

  // ==================== DROPDOWN DATA ====================

  Future<void> loadDropdownData() async {
    _dropdownLoading = true;
    _error = null;
    _vehicleNumbers = [];
    _users = [];
    _usersFullData = [];
    _vehicleNumbersFullData = [];
    notifyListeners();

    debugPrint('ðŸ”µ Starting to load dropdown data...');

    try {
      // Load vehicle numbers
      debugPrint(
          'ðŸ“¡ Fetching vehicle numbers from: $_baseUrl/booking/dropdown/vehicleNumber');
      final vehicleResponse = await http.get(
        Uri.parse('$_baseUrl/booking/dropdown/vehicleNumber'),
        headers: _headers,
      );

      debugPrint('ðŸ“¡ Vehicle response status: ${vehicleResponse.statusCode}');

      if (vehicleResponse.statusCode == 200) {
        final vehicleData = json.decode(vehicleResponse.body);
        debugPrint('ðŸ“¡ Vehicle response body: $vehicleData');

        if (vehicleData is Map && vehicleData.containsKey('data')) {
          final vehicleList = vehicleData['data'];
          if (vehicleList is List) {
            final Set<String> uniqueVehicles = {};

            for (var item in vehicleList) {
              if (item is Map) {
                final vehicleNumber = item['vehicle_number']?.toString().trim();
                final vehicleId = item['vehicle_id']?.toString().trim();
                final vehicleType = item['vehicle_type']?.toString().trim();
                final bookingColorCode =
                    item['booking_color_code']?.toString().trim();

                if (vehicleNumber != null && vehicleNumber.isNotEmpty) {
                  uniqueVehicles.add(vehicleNumber);
                  _vehicleNumbersFullData.add({
                    'vehicle_number': vehicleNumber,
                    'vehicle_id': vehicleId ?? '',
                    'vehicle_type': vehicleType ?? '',
                    'booking_color_code': bookingColorCode ?? '',
                  });
                  debugPrint(
                      'âœ… Added vehicle: $vehicleNumber with color: $bookingColorCode');
                }
              }
            }

            _vehicleNumbers = uniqueVehicles.toList()..sort();
            debugPrint('âœ… Total vehicles loaded: ${_vehicleNumbers.length}');
          }
        }
      } else {
        debugPrint('âŒ Failed to load vehicles: ${vehicleResponse.statusCode}');
      }

      // Load users
      debugPrint('ðŸ“¡ Fetching users from: $_baseUrl/booking/dropdown/users');
      final usersResponse = await http.get(
        Uri.parse('$_baseUrl/booking/dropdown/users'),
        headers: _headers,
      );

      debugPrint('ðŸ“¡ Users response status: ${usersResponse.statusCode}');

      if (usersResponse.statusCode == 200) {
        final usersData = json.decode(usersResponse.body);
        debugPrint('ðŸ“¡ Users response body: $usersData');

        if (usersData is Map && usersData.containsKey('data')) {
          final usersList = usersData['data'];
          if (usersList is List) {
            final Set<String> uniqueUserNames = {};

            for (var item in usersList) {
              if (item != null) {
                if (item is Map) {
                  final userName = item['user_name']?.toString().trim();
                  final userId = item['user_id']?.toString().trim() ?? '';

                  if (userName != null && userName.isNotEmpty) {
                    uniqueUserNames.add(userName);
                    _usersFullData.add({
                      'user_name': userName,
                      'user_id': userId,
                    });
                    debugPrint('âœ… Added user: $userName with ID: $userId');
                  }
                } else if (item is String) {
                  final trimmed = item.trim();
                  if (trimmed.isNotEmpty) {
                    uniqueUserNames.add(trimmed);
                    _usersFullData.add({
                      'user_name': trimmed,
                      'user_id': '',
                    });
                    debugPrint('âœ… Added user: $trimmed');
                  }
                }
              }
            }

            _users = uniqueUserNames.toList()..sort();
            debugPrint('âœ… Total users loaded: ${_users.length}');
          }
        }
      } else {
        debugPrint('âŒ Failed to load users: ${usersResponse.statusCode}');
      }

      // Fetch maintenance types
      await getMaintenanceTypes();
    } catch (e) {
      _error = 'Failed to load dropdown data: $e';
      debugPrint('âŒ Error in loadDropdownData: $e');
    } finally {
      _dropdownLoading = false;
      notifyListeners();
      debugPrint('ðŸ”µ Finished loading dropdown data');
    }
  }

  // ==================== GENERAL MAINTENANCE CRUD ====================

  Future<void> loadGeneralMaintenanceRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/maintenance/general'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map && data.containsKey('data')) {
          final entriesData = data['data'];
          if (entriesData is List) {
            _records = entriesData
                .map((item) => GeneralMaintenanceRecord.fromJson(item))
                .toList();
          }
        } else if (data is List) {
          _records = data
              .map((item) => GeneralMaintenanceRecord.fromJson(item))
              .toList();
        }
      }

      await loadDropdownData();
    } catch (e) {
      _error = 'Failed to connect to server: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addGeneralMaintenance() async {
    if (!validateForm()) return false;

    _isLoading = true;
    _apiError = null;
    notifyListeners();

    try {
      final maintenanceType = _formData['maintenance_type'] ?? 'general';
      final endpoint = _getMaintenanceEndpoint(maintenanceType);
      final url = '$_baseUrl$endpoint';

      debugPrint('ðŸ”µ Adding maintenance record...');
      debugPrint('ðŸ“¡ URL: $url');
      debugPrint('ðŸ“¦ Maintenance Type: $maintenanceType');

      // Build payload matching React structure
      final Map<String, dynamic> payload = {
        'vehicle_id': _formData['vehicle_id']?.toString() ?? '',
        'vehicle_number': _formData['vehicle_number']?.toString() ?? '',
        'type_of_vehicle': _formData['type_of_vehicle']?.toString() ?? '',
        'user_id': _formData['user_id']?.toString() ?? '',
        'user_name': _formData['user_name']?.toString() ?? '',
        'maintenance_type': maintenanceType,
        'date': _formData['date'] != null
            ? DateFormat('yyyy-MM-dd').format(_formData['date'] as DateTime)
            : DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'date_of_return': _formData['date_of_return'] != null
            ? DateFormat('yyyy-MM-dd')
                .format(_formData['date_of_return'] as DateTime)
            : null,
        'km': int.tryParse(_formData['km']?.toString() ?? '0') ?? 0,
        'cost': double.tryParse(_formData['cost']?.toString() ?? '0') ?? 0,
        'service_center': _formData['service_center']?.toString() ?? '',
        'is_returned': _formData['is_returned'] ?? false,
        'remarks': _formData['remarks']?.toString() ?? '',
      };

      // Add type-specific fields based on maintenance type
      switch (maintenanceType) {
        case "general":
          payload.addAll({
            'reason': _formData['reason']?.toString() ?? '',
            'next_service_km':
                int.tryParse(_formData['next_service_km']?.toString() ?? '0') ??
                    0,
            'next_service_date': _formData['next_service_date'] != null
                ? DateFormat('yyyy-MM-dd')
                    .format(_formData['next_service_date'] as DateTime)
                : null,
          });
          break;
        case "battery":
        case "batery":
          payload.addAll({
            'reason': _formData['reason']?.toString() ?? '',
            'si_no': _formData['si_no']?.toString() ?? '',
            'warranty_date': _formData['warranty_date'] != null
                ? DateFormat('yyyy-MM-dd')
                    .format(_formData['warranty_date'] as DateTime)
                : null,
          });
          break;
        case "wheel_balancing":
          payload.addAll({
            'reason': _formData['reason']?.toString() ?? '',
            'due_km': _formData['due_km'] != null &&
                    _formData['due_km'].toString().isNotEmpty
                ? int.tryParse(_formData['due_km'].toString())
                : null,
          });
          break;
        case "tyre":
          payload.addAll({
            'reason': _formData['reason']?.toString() ?? '',
            'due_km': _formData['due_km'] != null &&
                    _formData['due_km'].toString().isNotEmpty
                ? int.tryParse(_formData['due_km'].toString())
                : null,
          });
          break;
      }

      // Remove any null values
      payload.removeWhere((key, value) => value == null);

      debugPrint('ðŸ“¦ Final Payload:');
      payload.forEach((key, value) {
        debugPrint('   $key: $value');
      });

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(payload),
      );

      debugPrint('ðŸ“¡ Response status: ${response.statusCode}');
      debugPrint('ðŸ“¡ Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data is Map && data['status'] == 'success') {
          await loadGeneralMaintenanceRecords();
          resetForm();
          notifyListeners();
          return true;
        } else {
          _apiError = data['message'] ?? 'Unknown error occurred';
          return false;
        }
      } else {
        _apiError = 'Server error: ${response.statusCode} - ${response.body}';
        return false;
      }
    } catch (e) {
      _apiError = 'Failed to connect to server: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateGeneralMaintenance(String recordId) async {
    if (!validateForm()) return false;

    _isLoading = true;
    _apiError = null;
    notifyListeners();

    try {
      final maintenanceType = _formData['maintenance_type'] ?? 'general';
      final endpoint = _getMaintenanceEndpoint(maintenanceType);
      final url = '$_baseUrl$endpoint/$recordId';

      debugPrint('ðŸ”µ Updating maintenance record: $recordId');
      debugPrint('ðŸ“¡ URL: $url');
      debugPrint('ðŸ“¦ Maintenance Type: $maintenanceType');

      final Map<String, dynamic> payload = {
        'vehicle_id': _formData['vehicle_id']?.toString() ?? '',
        'vehicle_number': _formData['vehicle_number']?.toString() ?? '',
        'type_of_vehicle': _formData['type_of_vehicle']?.toString() ?? '',
        'user_id': _formData['user_id']?.toString() ?? '',
        'user_name': _formData['user_name']?.toString() ?? '',
        'maintenance_type': maintenanceType,
        'date': _formData['date'] != null
            ? DateFormat('yyyy-MM-dd').format(_formData['date'] as DateTime)
            : DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'date_of_return': _formData['date_of_return'] != null
            ? DateFormat('yyyy-MM-dd')
                .format(_formData['date_of_return'] as DateTime)
            : null,
        'km': int.tryParse(_formData['km']?.toString() ?? '0') ?? 0,
        'cost': double.tryParse(_formData['cost']?.toString() ?? '0') ?? 0,
        'service_center': _formData['service_center']?.toString() ?? '',
        'is_returned': _formData['is_returned'] ?? false,
        'remarks': _formData['remarks']?.toString() ?? '',
      };

      switch (maintenanceType) {
        case "general":
          payload.addAll({
            'reason': _formData['reason']?.toString() ?? '',
            'next_service_km':
                int.tryParse(_formData['next_service_km']?.toString() ?? '0') ??
                    0,
            'next_service_date': _formData['next_service_date'] != null
                ? DateFormat('yyyy-MM-dd')
                    .format(_formData['next_service_date'] as DateTime)
                : null,
          });
          break;
        case "battery":
        case "batery":
          payload.addAll({
            'reason': _formData['reason']?.toString() ?? '',
            'si_no': _formData['si_no']?.toString() ?? '',
            'warranty_date': _formData['warranty_date'] != null
                ? DateFormat('yyyy-MM-dd')
                    .format(_formData['warranty_date'] as DateTime)
                : null,
          });
          break;
        case "wheel_balancing":
          payload.addAll({
            'reason': _formData['reason']?.toString() ?? '',
            'due_km': _formData['due_km'] != null &&
                    _formData['due_km'].toString().isNotEmpty
                ? int.tryParse(_formData['due_km'].toString())
                : null,
          });
          break;
        case "tyre":
          payload.addAll({
            'reason': _formData['reason']?.toString() ?? '',
            'due_km': _formData['due_km'] != null &&
                    _formData['due_km'].toString().isNotEmpty
                ? int.tryParse(_formData['due_km'].toString())
                : null,
          });
          break;
      }

      payload.removeWhere((key, value) => value == null);

      debugPrint('ðŸ“¦ Final Payload:');
      payload.forEach((key, value) {
        debugPrint('   $key: $value');
      });

      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(payload),
      );

      debugPrint('ðŸ“¡ Response status: ${response.statusCode}');
      debugPrint('ðŸ“¡ Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map && data['status'] == 'success') {
          await loadGeneralMaintenanceRecords();
          resetForm();
          notifyListeners();
          return true;
        } else {
          _apiError = data['message'] ?? 'Unknown error occurred';
          return false;
        }
      } else {
        _apiError = 'Server error: ${response.statusCode} - ${response.body}';
        return false;
      }
    } catch (e) {
      _apiError = 'Failed to connect to server: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteGeneralMaintenance(String recordId) async {
    _isLoading = true;
    _apiError = null;
    notifyListeners();

    try {
      final record = _records.firstWhere(
        (r) => r.id == recordId,
        orElse: () => throw Exception('Record not found'),
      );

      final maintenanceType = record.maintenanceType ?? 'general';
      final endpoint = _getMaintenanceEndpoint(maintenanceType);
      final url = '$_baseUrl$endpoint/$recordId';

      debugPrint('ðŸ”µ Deleting maintenance record: $recordId');
      debugPrint('ðŸ“¡ URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: _headers,
      );

      debugPrint('ðŸ“¡ Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _records.removeWhere((record) => record.id == recordId);
        notifyListeners();
        return true;
      } else {
        _apiError = 'Server error: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _apiError = 'Failed to delete record: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== VEHICLE & USER INFO ====================

  Future<Map<String, dynamic>> getVehicleInfo(String vehicleNumber) async {
    try {
      for (var vehicle in _vehicleNumbersFullData) {
        if (vehicle['vehicle_number'] == vehicleNumber) {
          return {
            'vehicle_id': vehicle['vehicle_id'] ?? '',
            'vehicle_type': vehicle['vehicle_type'] ?? '',
          };
        }
      }
      return {'vehicle_id': '', 'vehicle_type': ''};
    } catch (e) {
      return {'vehicle_id': '', 'vehicle_type': ''};
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String userName) async {
    try {
      for (var user in _usersFullData) {
        if (user['user_name'] == userName) {
          return {'user_id': user['user_id'] ?? ''};
        }
      }
      return {'user_id': ''};
    } catch (e) {
      return {'user_id': ''};
    }
  }

  // ==================== FORM HANDLING ====================

  void updateFormData(String field, dynamic value) {
    _formData[field] = value;
    if (_formErrors.containsKey(field)) {
      _formErrors.remove(field);
    }
    notifyListeners();
  }

  void setFormDataFromRecord(GeneralMaintenanceRecord record) {
    String maintenanceType = record.maintenanceType ?? 'general';
    if (maintenanceType == 'batery' || maintenanceType == 'battery') {
      maintenanceType = 'batery';
    }

    _formData['vehicle_id'] = record.vehicleId;
    _formData['vehicle_number'] = record.vehicleNumber;
    _formData['vehicle_type'] = record.vehicleType;
    _formData['user_id'] = record.userId;
    _formData['user_name'] = record.userName;
    _formData['date'] = record.date;
    _formData['km'] = record.km.toString();
    _formData['cost'] = record.cost.toString();
    _formData['reason'] = record.reason;
    _formData['remarks'] = record.remarks;
    _formData['service_center'] = record.serviceCenter ?? '';
    _formData['date_of_return'] = record.dateOfReturn;
    _formData['is_returned'] = record.isReturned;
    _formData['type_of_vehicle'] = record.typeOfVehicle ?? '';
    _formData['maintenance_type'] = maintenanceType;

    // Type-specific fields
    _formData['next_service_km'] = record.nextServiceKm.toString();
    _formData['next_service_date'] = record.nextServiceDate;
    _formData['si_no'] = record.siNo ?? '';
    _formData['warranty_date'] = record.warrantyDate;
    _formData['due_km'] = record.dueKm?.toString() ?? '';

    notifyListeners();
  }

  bool validateForm() {
    final errors = <String, String>{};
    final maintenanceType = _formData['maintenance_type'] ?? 'general';

    // Always required fields (matching React)
    const alwaysRequired = [
      'vehicle_number',
      'user_name',
      'date',
      'date_of_return',
      'service_center',
      'cost',
      'km',
    ];

    for (final field in alwaysRequired) {
      final value = _formData[field];
      if (value == null || (value is String && value.trim().isEmpty)) {
        errors[field] = 'This field is required';
      }
    }

    // Reason is required only for general maintenance
    if (maintenanceType == 'general' &&
        (_formData['reason'] == null ||
            _formData['reason'].toString().trim().isEmpty)) {
      errors['reason'] = 'Service Reason is required for General Maintenance';
    }

    // If returned, validate based on type
    if (_formData['is_returned'] == true) {
      if (maintenanceType == 'general') {
        if (_formData['next_service_km'] == null ||
            _formData['next_service_km'].toString().trim().isEmpty) {
          errors['next_service_km'] =
              'Next Service KM is required for General Maintenance when returned';
        }
        if (_formData['next_service_date'] == null) {
          errors['next_service_date'] =
              'Next Service Date is required for General Maintenance when returned';
        }
      } else if (maintenanceType == 'battery' || maintenanceType == 'batery') {
        if (_formData['si_no'] == null ||
            _formData['si_no'].toString().trim().isEmpty) {
          errors['si_no'] = 'SI Number is required for Battery when returned';
        }
        if (_formData['warranty_date'] == null) {
          errors['warranty_date'] =
              'Warranty Date is required for Battery when returned';
        }
      }

      if ((_formData['bill_upload'] as List?)?.isEmpty ?? true) {
        errors['bill_upload'] =
            'At least one bill document is required when marking as returned';
      }
    }

    // Validate numeric fields
    final numberFields = ['km', 'cost', 'next_service_km', 'due_km'];
    for (final field in numberFields) {
      final value = _formData[field];
      if (value != null && value.toString().isNotEmpty) {
        if (field == 'cost') {
          if (double.tryParse(value.toString()) == null) {
            errors[field] = 'Must be a valid number';
          }
        } else {
          if (int.tryParse(value.toString()) == null) {
            errors[field] = 'Must be a valid number';
          }
        }
      }
    }

    _formErrors.clear();
    _formErrors.addAll(errors);
    notifyListeners();
    return errors.isEmpty;
  }

  void resetForm() {
    _formData.clear();
    _formData.addAll({
      'vehicle_id': '',
      'vehicle_number': '',
      'vehicle_type': '',
      'user_id': '',
      'user_name': '',
      'date': DateTime.now(),
      'km': '',
      'cost': '',
      'reason': '',
      'remarks': '',
      'service_center': '',
      'date_of_return': null,
      'is_returned': false,
      'type_of_vehicle': '',
      'maintenance_type': 'general',

      // Type-specific fields
      'next_service_km': '',
      'next_service_date': null,
      'si_no': '',
      'warranty_date': null,
      'due_km': '',
      'bill_upload': [],
    });
    _formErrors.clear();
    notifyListeners();
  }
}
