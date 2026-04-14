
// lib/providers/special_maintenance_provider.dart
import 'package:flutter/material.dart';
import '../services/special_maintenance_service.dart';
import '../models/special_maintenance_model.dart';

class SpecialMaintenanceProvider extends ChangeNotifier {
  final SpecialMaintenanceService _service = SpecialMaintenanceService();

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

  List<SpecialMaintenanceRecord> _batteryRecords = [];
  List<SpecialMaintenanceRecord> _tyreRecords = [];
  List<SpecialMaintenanceRecord> _wheelBalancingRecords = [];

  bool _isLoading = false;
  String? _error;
  String? _apiError;

  List<SpecialMaintenanceRecord> get batteryRecords => _batteryRecords;
  List<SpecialMaintenanceRecord> get tyreRecords => _tyreRecords;
  List<SpecialMaintenanceRecord> get wheelBalancingRecords =>
      _wheelBalancingRecords;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get apiError => _apiError;

  List<String> _users = [];
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoadingDropdowns = false;

  List<String> get users => _users;
  List<Map<String, dynamic>> get vehicles => _vehicles;
  bool get isLoadingDropdowns => _isLoadingDropdowns;

  Future<void> loadDropdownData() async {
    _isLoadingDropdowns = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadUsers(),
        _loadVehicles(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingDropdowns = false;
      notifyListeners();
    }
  }

  Future<void> _loadUsers() async {
    try {
      _users = await _service.getUsersDropdown();
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  Future<void> _loadVehicles() async {
    try {
      _vehicles = await _service.getVehicleNumbersDropdown();
    } catch (e) {
      throw Exception('Failed to load vehicles: $e');
    }
  }

  // Combined list for display
  List<SpecialMaintenanceRecord> get allRecords {
    return [
      ..._batteryRecords,
      ..._tyreRecords,
      ..._wheelBalancingRecords,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Get counts by type
  int get batteryCount => _batteryRecords.length;
  int get tyreCount => _tyreRecords.length;
  int get wheelBalancingCount => _wheelBalancingRecords.length;
  int get totalCount => allRecords.length;

  // Load all records
  Future<void> loadAllSpecialMaintenanceRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadBatteryRecords(),
        _loadTyreRecords(),
        _loadWheelBalancingRecords(),
      ]);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading special maintenance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load individual records
  Future<void> _loadBatteryRecords() async {
    try {
      final response = await _service.getBatteryMaintenance();

      if (response['status'] == 'success') {
        final List<dynamic> data = response['data'];
        _batteryRecords = data
            .map((item) => SpecialMaintenanceRecord.fromJson(item))
            .toList();
        _apiError = null;
      } else {
        throw Exception(
            'Failed to load battery records: ${response['message']}');
      }
    } catch (e) {
      _apiError = e.toString();
      debugPrint('Error loading battery records: $e');
      rethrow;
    }
  }

  Future<void> _loadTyreRecords() async {
    try {
      final response = await _service.getTyreMaintenance();

      if (response['status'] == 'success') {
        final List<dynamic> data = response['data'];
        _tyreRecords = data
            .map((item) => SpecialMaintenanceRecord.fromJson(item))
            .toList();
        _apiError = null;
      } else {
        throw Exception('Failed to load tyre records: ${response['message']}');
      }
    } catch (e) {
      _apiError = e.toString();
      debugPrint('Error loading tyre records: $e');
      rethrow;
    }
  }

  Future<void> _loadWheelBalancingRecords() async {
    try {
      final response = await _service.getWheelBalancing();

      if (response['status'] == 'success') {
        final List<dynamic> data = response['data'];
        _wheelBalancingRecords = data
            .map((item) => SpecialMaintenanceRecord.fromJson(item))
            .toList();
        _apiError = null;
      } else {
        throw Exception(
            'Failed to load wheel balancing records: ${response['message']}');
      }
    } catch (e) {
      _apiError = e.toString();
      debugPrint('Error loading wheel balancing records: $e');
      rethrow;
    }
  }

  // Prepare battery maintenance data for API - UPDATED FOR NEW API FORMAT
  Map<String, dynamic> _prepareBatteryData(Map<String, dynamic> formData) {
    return {
      'vehicle_id': formData['vehicle_id'],
      'vehicle_number': formData['vehicle_number'],
      'user_id': formData['user_id'],
      'user_name': formData['user_name'],
      'date': formData['date'],
      'maintenance_type': 'batery',
      'km': formData['km'] ?? 0,
      'cost': formData['cost'],
      'date_of_return': formData['date_of_return'] ?? '',
      'type_of_vehicle': formData['type_of_vehicle'] ?? 'Car',
      'service_center': formData['service_center'] ?? '',
      'warranty_date': formData['warranty_date'] ?? '',
      'remarks': formData['remarks'] ?? '',
      'bill_upload': formData['bill_upload'] ?? [],
      'is_returned': formData['is_returned'] ?? false,
    };
  }

  // Prepare tyre maintenance data for API - UPDATED FOR NEW API FORMAT
  Map<String, dynamic> _prepareTyreData(Map<String, dynamic> formData) {
    return {
      'vehicle_id': formData['vehicle_id'],
      'vehicle_number': formData['vehicle_number'],
      'user_id': formData['user_id'],
      'user_name': formData['user_name'],
      'date': formData['date'],
      'maintenance_type': 'tyre',
      'km': formData['km'] ?? 0,
      'due_km': formData['due_km'] ?? 0,
      'cost': formData['cost'],
      'date_of_return': formData['date_of_return'] ?? '',
      'type_of_vehicle': formData['type_of_vehicle'] ?? 'Car',
      'service_center': formData['service_center'] ?? '',
      'tyre_number': formData['tyre_number'] ?? '',
      'tyre_brand': formData['tyre_brand'] ?? '',
      'bill_upload': formData['bill_upload'] ?? [],
      'is_returned': formData['is_returned'] ?? false,
    };
  }

  // Prepare wheel balancing data for API - UPDATED FOR NEW API FORMAT
  Map<String, dynamic> _prepareWheelBalancingData(
      Map<String, dynamic> formData) {
    return {
      'vehicle_id': formData['vehicle_id'],
      'vehicle_number': formData['vehicle_number'],
      'user_id': formData['user_id'],
      'user_name': formData['user_name'],
      'date': formData['date'],
      'maintenance_type': 'wheel_balancing',
      'km': formData['km'] ?? 0,
      'due_km': formData['due_km'] ?? 0,
      'cost': formData['cost'],
      'date_of_return': formData['date_of_return'] ?? '',
      'type_of_vehicle': formData['type_of_vehicle'] ?? 'Car',
      'service_center': formData['service_center'] ?? '',
      'bill_upload': formData['bill_upload'] ?? [],
      'is_returned': formData['is_returned'] ?? false,
    };
  }

  // Add new records with proper data preparation
  Future<Map<String, dynamic>> addBatteryMaintenance(Map<String, dynamic> formData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final apiData = _prepareBatteryData(formData);
      final response = await _service.addBatteryMaintenance(apiData);

      if (response['status'] == 'success') {
        await _loadBatteryRecords();
        return {
          'success': true,
          'message': response['message'] ?? 'Battery maintenance created'
        };
      } else {
        throw Exception(
            response['message'] ?? 'Failed to add battery maintenance');
      }
    } catch (e) {
      _apiError = e.toString();
      return {
        'success': false,
        'message': e.toString()
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> addTyreMaintenance(Map<String, dynamic> formData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final apiData = _prepareTyreData(formData);
      final response = await _service.addTyreMaintenance(apiData);

      if (response['status'] == 'success') {
        await _loadTyreRecords();
        return {
          'success': true,
          'message': response['message'] ?? 'Tyre maintenance created'
        };
      } else {
        throw Exception(
            response['message'] ?? 'Failed to add tyre maintenance');
      }
    } catch (e) {
      _apiError = e.toString();
      return {
        'success': false,
        'message': e.toString()
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> addWheelBalancing(Map<String, dynamic> formData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final apiData = _prepareWheelBalancingData(formData);
      final response = await _service.addWheelBalancing(apiData);

      if (response['status'] == 'success') {
        await _loadWheelBalancingRecords();
        return {
          'success': true,
          'message': response['message'] ?? 'Wheel balancing created'
        };
      } else {
        throw Exception(response['message'] ?? 'Failed to add wheel balancing');
      }
    } catch (e) {
      _apiError = e.toString();
      return {
        'success': false,
        'message': e.toString()
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update records with proper data preparation
  Future<Map<String, dynamic>> updateBatteryMaintenance(
      String id, Map<String, dynamic> formData) async {
    try {
      _isLoading = true;
      notifyListeners();

      // For update, set is_returned to true
      final apiData = _prepareBatteryData(formData);
      apiData['is_returned'] = true;
      
      final response = await _service.updateBatteryMaintenance(id, apiData);

      if (response['status'] == 'success') {
        await _loadBatteryRecords();
        return {
          'success': true,
          'message': response['message'] ?? 'Battery maintenance updated'
        };
      } else {
        throw Exception(
            response['message'] ?? 'Failed to update battery maintenance');
      }
    } catch (e) {
      _apiError = e.toString();
      return {
        'success': false,
        'message': e.toString()
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateTyreMaintenance(
      String id, Map<String, dynamic> formData) async {
    try {
      _isLoading = true;
      notifyListeners();

      // For update, set is_returned to true
      final apiData = _prepareTyreData(formData);
      apiData['is_returned'] = true;
      
      final response = await _service.updateTyreMaintenance(id, apiData);

      if (response['status'] == 'success') {
        await _loadTyreRecords();
        return {
          'success': true,
          'message': response['message'] ?? 'Tyre maintenance updated'
        };
      } else {
        throw Exception(
            response['message'] ?? 'Failed to update tyre maintenance');
      }
    } catch (e) {
      _apiError = e.toString();
      return {
        'success': false,
        'message': e.toString()
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateWheelBalancing(
      String id, Map<String, dynamic> formData) async {
    try {
      _isLoading = true;
      notifyListeners();

      // For update, set is_returned to true
      final apiData = _prepareWheelBalancingData(formData);
      apiData['is_returned'] = true;
      
      final response = await _service.updateWheelBalancing(id, apiData);

      if (response['status'] == 'success') {
        await _loadWheelBalancingRecords();
        return {
          'success': true,
          'message': response['message'] ?? 'Wheel balancing updated'
        };
      } else {
        throw Exception(
            response['message'] ?? 'Failed to update wheel balancing');
      }
    } catch (e) {
      _apiError = e.toString();
      return {
        'success': false,
        'message': e.toString()
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete records
  Future<Map<String, dynamic>> deleteSpecialMaintenance(String id, String type) async {
    try {
      _isLoading = true;
      notifyListeners();

      Map<String, dynamic> response;
      switch (type.toLowerCase()) {
        case 'battery':
          response = await _service.deleteBatteryMaintenance(id);
          _batteryRecords.removeWhere((record) => record.id == id);
          break;
        case 'tyre':
          response = await _service.deleteTyreMaintenance(id);
          _tyreRecords.removeWhere((record) => record.id == id);
          break;
        case 'wheel-balancing':
        case 'wheel balancing':
          response = await _service.deleteWheelBalancing(id);
          _wheelBalancingRecords.removeWhere((record) => record.id == id);
          break;
        default:
          throw Exception('Invalid maintenance type');
      }

      _apiError = null;
      return {
        'success': true,
        'message': response['message'] ?? 'Record deleted successfully'
      };
    } catch (e) {
      _apiError = e.toString();
      return {
        'success': false,
        'message': e.toString()
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear errors
  void clearError() {
    _error = null;
    _apiError = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadAllSpecialMaintenanceRecords();
  }
}
