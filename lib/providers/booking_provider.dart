import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/booking_api_service.dart';

enum ViewState { idle, busy }

class BookingProvider extends ChangeNotifier {
  final BookingApiService _apiService = BookingApiService();

  // State management
  ViewState _state = ViewState.idle;
  ViewState get state => _state;
  bool get isLoading => _state == ViewState.busy;

  void setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  // Bookings data
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  String _searchQuery = '';

  // Vehicle data
  List<Map<String, dynamic>> _vehicleNumbers = [];
  List<String> _vehicleTypes = [];

  // Filter variables
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedBookingType;
  String? _selectedStatus;
  String? _selectedVehicleType;
  List<String>? _selectedVehicleNumbers;
  List<String>? _selectedVehicleTypeList;

  // Filtered vehicles by type (for dropdown)
  List<Map<String, dynamic>> _filteredVehiclesByType = [];

  // Getters
  List<Map<String, dynamic>> get bookings => _bookings;
  List<Map<String, dynamic>> get filteredBookings => _filteredBookings;
  List<Map<String, dynamic>> get vehicleNumbers => _vehicleNumbers;
  List<String> get vehicleTypes => _vehicleTypes;
  List<Map<String, dynamic>> get filteredVehiclesByType =>
      _filteredVehiclesByType;

  // Load all initial data
  Future<void> loadAllData() async {
    setState(ViewState.busy);
    try {
      await Future.wait([
        loadBookings(),
        loadVehicleNumbers(),
        loadVehicleTypes(),
      ]);
    } catch (e) {
      debugPrint('Error loading all data: $e');
    } finally {
      setState(ViewState.idle);
    }
  }

  // Load bookings
  Future<void> loadBookings() async {
    try {
      debugPrint('Loading bookings from provider...');
      final response = await _apiService.getBookings();

      if (response.success && response.data != null) {
        _bookings = response.data!;
        debugPrint('Successfully loaded ${_bookings.length} bookings');

        if (_bookings.isNotEmpty) {
          debugPrint('First booking sample:');
          debugPrint('Vehicle: ${_bookings[0]['vehicle_number']}');
          debugPrint('Type: ${_bookings[0]['booking_type']}');
          debugPrint('Vehicle Type: ${_bookings[0]['vehicle_type']}');
        }

        _filteredBookings = List.from(_bookings);
      } else {
        debugPrint('Failed to load bookings: ${response.message}');
        _bookings = [];
        _filteredBookings = [];
      }
    } catch (e) {
      debugPrint('Error in loadBookings: $e');
      _bookings = [];
      _filteredBookings = [];
    }
    notifyListeners();
  }

  // Load vehicle numbers for dropdown
  Future<void> loadVehicleNumbers() async {
    try {
      final response = await _apiService.getVehicleNumbers();
      if (response.success) {
        _vehicleNumbers = response.data ?? [];
        debugPrint('Loaded ${_vehicleNumbers.length} vehicle numbers');
      } else {
        debugPrint('Failed to load vehicle numbers: ${response.message}');
        _vehicleNumbers = [];
      }
    } catch (e) {
      debugPrint('Error loading vehicle numbers: $e');
      _vehicleNumbers = [];
    }
    notifyListeners();
  }

  // Load vehicle types for dropdown
  Future<void> loadVehicleTypes() async {
    try {
      final response = await _apiService.getVehicleTypes();
      if (response.success) {
        _vehicleTypes = response.data ?? [];
        debugPrint('Loaded ${_vehicleTypes.length} vehicle types: $_vehicleTypes');
      } else {
        debugPrint('Failed to load vehicle types: ${response.message}');
        _vehicleTypes = [];
      }
    } catch (e) {
      debugPrint('Error loading vehicle types: $e');
      _vehicleTypes = [];
    }
    notifyListeners();
  }

  // Load vehicles filtered by type
  Future<void> loadVehiclesByType(String vehicleType) async {
    setState(ViewState.busy);
    try {
      debugPrint('Loading vehicles by type: $vehicleType');
      final response = await _apiService.getVehiclesByType(vehicleType);

      if (response.success && response.data != null) {
        _filteredVehiclesByType = response.data!;
        debugPrint(
            'Loaded ${_filteredVehiclesByType.length} vehicles for type: $vehicleType');
      } else {
        debugPrint('Failed to load vehicles by type: ${response.message}');
        _filteredVehiclesByType = [];
      }
    } catch (e) {
      debugPrint('Error in loadVehiclesByType: $e');
      _filteredVehiclesByType = [];
    } finally {
      setState(ViewState.idle);
    }
  }

  // Advanced server-side filtering with multiple parameters
  Future<void> applyServerFilters({
    DateTime? startDate,
    DateTime? endDate,
    String? bookingType,
    String? status,
    List<String>? vehicleNumbers,
    List<String>? vehicleTypes,
  }) async {
    setState(ViewState.busy);
    try {
      debugPrint('Applying server filters with:');
      debugPrint('- startDate: $startDate');
      debugPrint('- endDate: $endDate');
      debugPrint('- bookingType: $bookingType');
      debugPrint('- status: $status');
      debugPrint('- vehicleNumbers: $vehicleNumbers');
      debugPrint('- vehicleTypes: $vehicleTypes');

      // Store filter values
      _startDate = startDate;
      _endDate = endDate;
      _selectedBookingType = bookingType;
      _selectedStatus = status;
      _selectedVehicleNumbers = vehicleNumbers;
      _selectedVehicleTypeList = vehicleTypes;

      final response = await _apiService.getFilteredBookingsAdvanced(
        startDate: startDate,
        endDate: endDate,
        bookingType: bookingType,
        status: status,
        vehicleNumbers: vehicleNumbers,
        vehicleTypes: vehicleTypes,
      );

      if (response.success && response.data != null) {
        _filteredBookings = response.data!;
        debugPrint(
            'Server filter applied, got ${_filteredBookings.length} bookings');
      } else {
        debugPrint('Failed to apply server filters: ${response.message}');
        // Fall back to local filtering if server fails
        _applyLocalFilters();
      }
    } catch (e) {
      debugPrint('Error in applyServerFilters: $e');
      // Fall back to local filtering
      _applyLocalFilters();
    } finally {
      setState(ViewState.idle);
    }
  }

  // Original server filter method (for backward compatibility)
  Future<void> applyServerFiltersOld({
    DateTime? startDate,
    DateTime? endDate,
    String? bookingType,
    String? status,
    String? vehicleType,
  }) async {
    setState(ViewState.busy);
    try {
      debugPrint('Applying server filters (simple)...');

      // Store filter values
      _startDate = startDate;
      _endDate = endDate;
      _selectedBookingType = bookingType;
      _selectedStatus = status;
      _selectedVehicleType = vehicleType;

      final response = await _apiService.getFilteredBookings(
        vehicleType: vehicleType,
        startDate: startDate,
        endDate: endDate,
        bookingType: bookingType,
        status: status,
      );

      if (response.success && response.data != null) {
        _filteredBookings = response.data!;
        debugPrint(
            'Server filter applied, got ${_filteredBookings.length} bookings');
      } else {
        debugPrint('Failed to apply server filters: ${response.message}');
        // Fall back to local filtering if server fails
        applyFilters(
          startDate: startDate,
          endDate: endDate,
          bookingType: bookingType,
          status: status,
          vehicleType: vehicleType,
        );
      }
    } catch (e) {
      debugPrint('Error in applyServerFiltersOld: $e');
      // Fall back to local filtering
      applyFilters(
        startDate: startDate,
        endDate: endDate,
        bookingType: bookingType,
        status: status,
        vehicleType: vehicleType,
      );
    } finally {
      setState(ViewState.idle);
    }
  }

  // Search bookings
  void searchBookings(String query) {
    _searchQuery = query.toLowerCase();
    _applyLocalFilters();
  }

  // Apply local filters (client-side filtering)
  void applyFilters({
    DateTime? startDate,
    DateTime? endDate,
    String? bookingType,
    String? status,
    String? vehicleType,
  }) {
    _startDate = startDate;
    _endDate = endDate;
    _selectedBookingType = bookingType;
    _selectedStatus = status;
    _selectedVehicleType = vehicleType;
    _selectedVehicleNumbers = null;
    _selectedVehicleTypeList = null;

    _applyLocalFilters();
  }

  // Internal method for local filtering
  void _applyLocalFilters() {
    _filteredBookings = _bookings.where((booking) {
      bool matchesSearch = true;
      bool matchesDate = true;
      bool matchesType = true;
      bool matchesStatus = true;
      bool matchesVehicleType = true;
      bool matchesVehicleNumbers = true;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        matchesSearch = _matchesSearch(booking);
      }

      // Date filter
      if (_startDate != null || _endDate != null) {
        matchesDate = _matchesDateRange(booking);
      }

      // Booking type filter
      if (_selectedBookingType != null &&
          _selectedBookingType!.isNotEmpty &&
          _selectedBookingType != 'all') {
        matchesType = _matchesBookingType(booking);
      }

      // Status filter
      if (_selectedStatus != null &&
          _selectedStatus!.isNotEmpty &&
          _selectedStatus != 'all') {
        matchesStatus = _matchesStatus(booking);
      }

      // Vehicle type filter (single)
      if (_selectedVehicleType != null &&
          _selectedVehicleType!.isNotEmpty &&
          _selectedVehicleType != 'all') {
        matchesVehicleType = _matchesVehicleType(booking);
      }

      // Multiple vehicle numbers filter
      if (_selectedVehicleNumbers != null &&
          _selectedVehicleNumbers!.isNotEmpty) {
        matchesVehicleNumbers = _matchesVehicleNumbers(booking);
      }

      // Multiple vehicle types filter
      if (_selectedVehicleTypeList != null &&
          _selectedVehicleTypeList!.isNotEmpty) {
        matchesVehicleType = _matchesVehicleTypeList(booking);
      }

      return matchesSearch &&
          matchesDate &&
          matchesType &&
          matchesStatus &&
          matchesVehicleType &&
          matchesVehicleNumbers;
    }).toList();

    debugPrint('Filtered to ${_filteredBookings.length} bookings');
    debugPrint('Search query: "$_searchQuery"');
    debugPrint('Date range: $_startDate to $_endDate');
    debugPrint('Booking type: $_selectedBookingType');
    debugPrint('Status: $_selectedStatus');
    debugPrint('Vehicle type: $_selectedVehicleType');
    debugPrint('Vehicle numbers: $_selectedVehicleNumbers');
    debugPrint('Vehicle types list: $_selectedVehicleTypeList');

    notifyListeners();
  }

  // Helper methods for filtering
  bool _matchesSearch(Map<String, dynamic> booking) {
    final vehicleNumber =
        (booking['vehicle_number'] as String? ?? '').toLowerCase();
    final vehicleType =
        (booking['vehicle_type'] as String? ?? '').toLowerCase();

    // Get customer names from customer_details
    String customerNames = '';
    if (booking['customer_details'] is List) {
      final customers = booking['customer_details'] as List;
      customerNames = customers
          .map((c) => (c is Map ? (c['customer_name']?.toString() ?? '') : '').toLowerCase())
          .join(' ');
    }

    // Also search in customer_name field
    if (booking['customer_name'] is List) {
      final customerNameList = booking['customer_name'] as List;
      customerNames +=
          ' ${customerNameList.map((c) => (c?.toString() ?? '').toLowerCase()).join(' ')}';
    }

    final personalLocation =
        (booking['personal_location'] as String? ?? '').toLowerCase();
    final clientLocation = (booking['client_location'] is List)
        ? (booking['client_location'] as List)
            .map((loc) => (loc?.toString() ?? '').toLowerCase())
            .join(' ')
        : (booking['client_location'] as String? ?? '').toLowerCase();

    return vehicleNumber.contains(_searchQuery) ||
        vehicleType.contains(_searchQuery) ||
        customerNames.contains(_searchQuery) ||
        personalLocation.contains(_searchQuery) ||
        clientLocation.contains(_searchQuery);
  }

  bool _matchesDateRange(Map<String, dynamic> booking) {
    bool matches = true;

    if (_startDate != null && booking['from_date'] != null) {
      try {
        final bookingDateString = booking['from_date'].toString();
        final bookingDate = DateTime.parse(bookingDateString);
        final startDateOnly =
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final bookingDateOnly =
            DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

        matches = bookingDateOnly.isAtSameMomentAs(startDateOnly) ||
            bookingDateOnly.isAfter(startDateOnly);
      } catch (e) {
        matches = true;
      }
    }

    if (_endDate != null && booking['to_date'] != null && matches) {
      try {
        final bookingDateString = booking['to_date'].toString();
        final bookingDate = DateTime.parse(bookingDateString);
        final endDateOnly = DateTime(
            _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        final bookingDateOnly =
            DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

        matches = bookingDateOnly.isBefore(endDateOnly) ||
            bookingDateOnly.isAtSameMomentAs(endDateOnly);
      } catch (e) {
        matches = matches;
      }
    }

    return matches;
  }

  bool _matchesBookingType(Map<String, dynamic> booking) {
    final bookingType =
        (booking['booking_type'] as String? ?? '').toLowerCase();
    if (_selectedBookingType == 'office') {
      return bookingType == 'office' || bookingType == 'official';
    }
    return bookingType == _selectedBookingType;
  }

  bool _matchesStatus(Map<String, dynamic> booking) {
    final bookingStatus = (booking['status_color'] as String? ?? 'green')
        .toLowerCase()
        .replaceAll(' ', '');
    return bookingStatus == _selectedStatus!.toLowerCase();
  }

  bool _matchesVehicleType(Map<String, dynamic> booking) {
    final bookingVehicleType =
        (booking['vehicle_type'] as String? ?? '').toLowerCase();
    return bookingVehicleType == _selectedVehicleType!.toLowerCase();
  }

  bool _matchesVehicleNumbers(Map<String, dynamic> booking) {
    final bookingVehicleNumber =
        (booking['vehicle_number'] as String? ?? '').toLowerCase();
    return _selectedVehicleNumbers!
        .any((vNum) => vNum.toLowerCase() == bookingVehicleNumber);
  }

  bool _matchesVehicleTypeList(Map<String, dynamic> booking) {
    final bookingVehicleType =
        (booking['vehicle_type'] as String? ?? '').toLowerCase();
    return _selectedVehicleTypeList!
        .any((type) => type.toLowerCase() == bookingVehicleType);
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _startDate = null;
    _endDate = null;
    _selectedBookingType = null;
    _selectedStatus = null;
    _selectedVehicleType = null;
    _selectedVehicleNumbers = null;
    _selectedVehicleTypeList = null;
    _filteredBookings = List.from(_bookings);
    notifyListeners();
  }

  // Refresh bookings
  Future<void> refreshBookings() async {
    await loadBookings();
  }

  // Delete booking
  Future<bool> deleteBooking(String id) async {
    setState(ViewState.busy);
    try {
      final response = await _apiService.deleteBooking(id);
      if (response.success) {
        await loadBookings();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting booking: $e');
      return false;
    } finally {
      setState(ViewState.idle);
    }
  }

  // Create booking
  Future<Map<String, dynamic>?> createBooking(
      Map<String, dynamic> bookingData) async {
    setState(ViewState.busy);
    try {
      final response = await _apiService.createBooking(bookingData);
      if (response.success) {
        await loadBookings();
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      return null;
    } finally {
      setState(ViewState.idle);
    }
  }

  // Update booking
  Future<Map<String, dynamic>?> updateBooking(
      String id, Map<String, dynamic> bookingData) async {
    setState(ViewState.busy);
    try {
      final response = await _apiService.updateBooking(id, bookingData);
      if (response.success) {
        await loadBookings();
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error updating booking: $e');
      return null;
    } finally {
      setState(ViewState.idle);
    }
  }

  // Get booking by ID
  Map<String, dynamic>? getBookingById(String id) {
    try {
      return _bookings.firstWhere((booking) => booking['_id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Get statistics
  Map<String, dynamic> getStatistics() {
    final total = _filteredBookings.length;
    final office = _filteredBookings.where((b) {
      final type = (b['booking_type'] ?? '').toString().toLowerCase();
      return type == 'office' || type == 'official';
    }).length;
    final personal = _filteredBookings.where((b) {
      final type = (b['booking_type'] ?? '').toString().toLowerCase();
      return type == 'personal';
    }).length;
    final active = _filteredBookings.where((b) => b['isActive'] == true).length;
    final closed =
        _filteredBookings.where((b) => b['isActive'] == false).length;

    return {
      'total': total,
      'office': office,
      'personal': personal,
      'active': active,
      'closed': closed,
    };
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
