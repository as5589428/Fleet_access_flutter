// dashboard_provider.dart
import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../models/vehicle_model.dart';
import '../services/dashboard_api_service.dart';

class DashboardStats {
  final String title;
  final String value;
  final String description;
  final String filter;
  final Color color;
  final IconData icon;

  DashboardStats({
    required this.title,
    required this.value,
    required this.description,
    required this.filter,
    required this.color,
    required this.icon,
  });
}

class DashboardProvider extends ChangeNotifier {
  final DashboardApiService _apiService = DashboardApiService();

  List<DashboardStats> _stats = [];
  List<Map<String, dynamic>> _recentBookings = [];
  List<Map<String, dynamic>> _vehicleStatus = [];
  List<VehicleModel> _vehicles = [];

  bool _isLoading = true;
  String? _error;
  String _timePeriod = 'today';

  // Pagination states for different overlays
  final Map<String, int> _currentPages = {};
  final Map<String, int> _itemsPerPage = {};
  final Map<String, int> _totalRecords = {};

  List<DashboardStats> get stats => _stats;
  List<Map<String, dynamic>> get recentBookings => _recentBookings;
  List<Map<String, dynamic>> get vehicleStatus => _vehicleStatus;
  List<VehicleModel> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get timePeriod => _timePeriod;

  // Color configurations matching React version
  static const Map<String, Color> _colorConfigs = {
    'teal': Color(0xFF0D9488),
    'emerald': Color(0xFF059669),
    'orange': Color(0xFFF97316),
    'amber': Color(0xFFF59E0B),
    'red': Color(0xFFEF4444),
    'purple': Color(0xFF8B5CF6),
    'blue': Color(0xFF3B82F6),
    'indigo': Color(0xFF6366F1),
    'pink': Color(0xFFEC4899),
    'green': Color(0xFF10B981),
    'yellow': Color(0xFFFBBF24),
  };

  // Filter configurations (matching your React code)
  static const Map<String, String> _filterConfigs = {
    'TOTAL': '',
    'AVAILABLE': 'booking_status=Available',
    'BOOKED': 'booking_status=Booked',
    'MAINTENANCE': '',
    'MAINTENANCE_INSURANCE': 'maintenance-insurance',
  };

  DashboardProvider() {
    // Initialize pagination defaults
    const filters = [
      'TOTAL',
      'AVAILABLE',
      'BOOKED',
      'MAINTENANCE',
      'MAINTENANCE_INSURANCE'
    ];
    for (var filter in filters) {
      _currentPages[filter] = 1;
      _itemsPerPage[filter] = 10;
      _totalRecords[filter] = 0;
    }
  }

  // Pagination getters
  int getCurrentPage(String filterKey) => _currentPages[filterKey] ?? 1;
  int getItemsPerPage(String filterKey) => _itemsPerPage[filterKey] ?? 10;
  int getTotalRecords(String filterKey) => _totalRecords[filterKey] ?? 0;
  int getTotalPages(String filterKey) {
    final total = getTotalRecords(filterKey);
    final perPage = getItemsPerPage(filterKey);
    return (total / perPage).ceil();
  }

  // Pagination methods
  void setCurrentPage(String filterKey, int page) {
    _currentPages[filterKey] = page;
  }

  void setItemsPerPage(String filterKey, int items) {
    _itemsPerPage[filterKey] = items;
    _currentPages[filterKey] = 1; // Reset to first page
  }

  void nextPage(String filterKey) {
    final current = getCurrentPage(filterKey);
    final total = getTotalPages(filterKey);
    if (current < total) {
      _currentPages[filterKey] = current + 1;
    }
  }

  void prevPage(String filterKey) {
    final current = getCurrentPage(filterKey);
    if (current > 1) {
      _currentPages[filterKey] = current - 1;
    }
  }

  void firstPage(String filterKey) {
    _currentPages[filterKey] = 1;
  }

  void lastPage(String filterKey) {
    _currentPages[filterKey] = getTotalPages(filterKey);
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.fetchDashboardData();
      _vehicles = data['vehicles'] ?? [];
      _recentBookings = data['recentBookings'] ?? [];

      final underMaintenanceCount = data['underMaintenanceCount'] ?? 0;
      final upcomingMaintenanceCount = data['upcomingMaintenanceCount'] ?? 0;

      _processDashboardData(_vehicles, underMaintenanceCount, upcomingMaintenanceCount);
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      _error = 'Failed to load dashboard data. Please try again.';
      _setErrorState();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _processDashboardData(List<VehicleModel> vehicles, int underMaintenanceCount, int upcomingMaintenanceCount) {
    // Calculate counts using your VehicleModel properties
    final totalVehicles = vehicles.length;
    final availableVehicles =
        vehicles.where((v) => v.bookingStatus == 'Available').length;
    final bookedVehicles =
        vehicles.where((v) => v.bookingStatus == 'Booked').length;
    final notAvailableVehicles =
        vehicles.where((v) => v.bookingStatus == 'Not Available').length;
    final maintenanceVehicles = underMaintenanceCount;

    final insuranceDueVehicles = upcomingMaintenanceCount;
    final maintenanceDueVehicles = 0;

    // Generate stats - MUST be a List<DashboardStats>
    _stats = [
      DashboardStats(
        title: 'Total Vehicles',
        value: totalVehicles.toString(),
        description: 'All vehicles in fleet',
        filter: _filterConfigs['TOTAL']!,
        color: _colorConfigs['teal']!,
        icon: Icons.directions_car_outlined,
      ),
      DashboardStats(
        title: 'Available',
        value: availableVehicles.toString(),
        description: 'Ready for booking',
        filter: _filterConfigs['AVAILABLE']!,
        color: _colorConfigs['emerald']!,
        icon: Icons.check_circle_outline,
      ),
      DashboardStats(
        title: 'Booked',
        value: bookedVehicles.toString(),
        description: 'Currently in use',
        filter: _filterConfigs['BOOKED']!,
        color: _colorConfigs['orange']!,
        icon: Icons.event_available_outlined,
      ),
      DashboardStats(
        title: 'Under Maintenance',
        value: maintenanceVehicles.toString(),
        description: 'Currently in service',
        filter: _filterConfigs['MAINTENANCE']!,
        color: _colorConfigs['amber']!,
        icon: Icons.build_circle_outlined,
      ),
      DashboardStats(
        title: 'Upcoming Maintenance',
        value: (insuranceDueVehicles + maintenanceDueVehicles).toString(),
        description: 'Maintenance & insurance due',
        filter: _filterConfigs['MAINTENANCE_INSURANCE']!,
        color: _colorConfigs['purple']!,
        icon: Icons.calendar_today_outlined,
      ),
    ];

    // Generate vehicle status
    _vehicleStatus = [
      {
        'id': 'status-available',
        'status': 'Available',
        'count': '$availableVehicles Vehicles',
        'color': Colors.green,
        'filter': _filterConfigs['AVAILABLE']!,
      },
      {
        'id': 'status-booked',
        'status': 'Booked',
        'count': '$bookedVehicles Vehicles',
        'color': Colors.blue,
        'filter': _filterConfigs['BOOKED']!,
      },
      {
        'id': 'status-maintenance',
        'status': 'Maintenance',
        'count': '$maintenanceVehicles Vehicles',
        'color': Colors.amber,
        'filter': _filterConfigs['MAINTENANCE']!,
      },
      {
        'id': 'status-not-available',
        'status': 'Not Available',
        'count': '$notAvailableVehicles Vehicles',
        'color': Colors.red,
        'filter': 'booking_status=Not Available',
      },
      {
        'id': 'status-insurance-due',
        'status': 'Insurance Due',
        'count': '$insuranceDueVehicles Vehicles',
        'color': Colors.purple,
        'filter': 'maintenance-insurance&maintenance_type=insurance',
      },
    ];

    // Generate recent bookings
    final bookedVehiclesData =
        vehicles.where((v) => v.bookingStatus == 'Booked').toList();
    _recentBookings = bookedVehiclesData.take(3).map((vehicle) {
      return {
        'id': vehicle.id,
        'vehicle_number': vehicle.vehicleNumber,
        'vehicle_type': vehicle.vehicleType,
        'fuel_type': vehicle.vehicleDetails.fuelType.isNotEmpty
            ? vehicle.vehicleDetails.fuelType.first
            : 'Petrol',
        'client':
            vehicle.userName.isNotEmpty ? vehicle.userName : 'Unknown Client',
        'time': vehicle.updatedAt != null
            ? '${vehicle.updatedAt!.hour.toString().padLeft(2, '0')}:${vehicle.updatedAt!.minute.toString().padLeft(2, '0')}'
            : 'N/A',
        'status': 'Active',
        'vehicle': vehicle,
      };
    }).toList();
  }

  void _setErrorState() {
    // Ensure we're returning a List
    _stats = _filterConfigs.entries.map((entry) {
      return DashboardStats(
        title: entry.key.replaceAll('_', ' '),
        value: '0',
        description: 'Data unavailable',
        filter: entry.value,
        color: Colors.grey,
        icon: Icons.error_outline,
      );
    }).toList();

    _recentBookings = [
      {
        'id': 'error-booking',
        'vehicle_number': 'Error loading data',
        'client': 'Please try refreshing',
        'time': 'N/A',
        'status': 'Error',
      }
    ];

    _vehicleStatus = [];
  }

  void setTimePeriod(String period) {
    _timePeriod = period;
    notifyListeners();
  }

  Future<PaginatedVehicleResponse> fetchFilteredVehicles({
    required String filter,
    int page = 1,
    int limit = 10,
    Map<String, String>? additionalParams,
  }) async {
    try {
      return await _apiService.fetchFilteredVehicles(
        filter: filter,
        page: page,
        limit: limit,
        additionalParams: additionalParams,
      );
    } catch (e) {
      debugPrint('Filter fetch error: $e');
      throw Exception('Failed to fetch filtered vehicles: $e');
    }
  }
}
