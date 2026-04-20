// lib/screens/bookings/bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/booking_api_service.dart';
import '../../models/vehicle_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

// Traveler class
class Traveler {
  String employeeId;
  String employeeName;
  String role;

  Traveler({
    required this.employeeId,
    required this.employeeName,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'role': role,
    };
  }

  factory Traveler.fromJson(Map<String, dynamic> json) {
    return Traveler(
      employeeId: json['employee_id'] ?? '',
      employeeName: json['employee_name'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

class BookingFormScreen extends StatefulWidget {
  final Map<String, dynamic>? booking;
  final bool isEditing;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  const BookingFormScreen({
    super.key,
    this.booking,
    this.isEditing = false,
    this.onCancel,
    this.onSave,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final BookingApiService _apiService = BookingApiService();
  final http.Client _client = http.Client();

  static const String baseUrl = AppConstants.baseUrl;

  bool _isLoading = false;
  bool _isReferral = false;
  String _bookingType = 'office';
  String _capacityError = '';

  // Form controllers
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _fromDateTimeController = TextEditingController();
  final TextEditingController _toDateTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _referredCustomerNameController =
      TextEditingController();
  final TextEditingController _referredByController = TextEditingController();
  final TextEditingController _referredClientLocationController =
      TextEditingController();
  final TextEditingController _personalLocationController =
      TextEditingController();
  final TextEditingController _personalPurposeController =
      TextEditingController();

  // Dropdown data
  List<VehicleModel> _vehicles = [];
  List<Map<String, dynamic>> _filteredVehicles = [];
  List<String> _vehicleTypeOptions = [];
  List<String> _employees = [];
  List<String> _roles = [];
  List<String> _customers = [];

  // Selected vehicle and type
  VehicleModel? _selectedVehicle;
  String? _selectedVehicleType;
  bool _loadingVehicles = false;
  bool _isLoadingVehicleTypes = false;
  String? _vehicleTypeError;
  bool _isVehicleSelected = false;

  // Traveler management
  String _selectedEmployee = '';
  String _selectedTravelStatus = 'driver';
  List<Traveler> _travelers = [];

  // Multi-select customers
  List<String> _selectedCustomers = [];

  // Loading states
  bool _loadingVehicleInfo = false;

  // Scroll controller for the main form
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
    _loadDropdownData();
    if (widget.isEditing && widget.booking != null) {
      _populateForm();
    }
  }

  Future<void> _loadVehicleTypes() async {
    setState(() {
      _isLoadingVehicleTypes = true;
      _vehicleTypeError = null;
    });

    try {
      debugPrint('Fetching vehicle types from: $baseUrl/booking/vehicle-types');

      final response = await _client.get(
        Uri.parse('$baseUrl/booking/vehicle-types'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      debugPrint('Vehicle types response status: ${response.statusCode}');
      debugPrint('Vehicle types response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<String> vehicleTypes = [];

        if (decoded is Map && decoded['data'] is List) {
          final List<dynamic> dataList = decoded['data'] as List;

          for (var item in dataList) {
            if (item is Map && item['vehicle_type'] is List) {
              final types = item['vehicle_type'] as List;
              for (var type in types) {
                final typeStr = type?.toString();
                if (typeStr != null && typeStr.isNotEmpty) {
                  vehicleTypes.add(typeStr);
                }
              }
            }
          }
        } else if (decoded is List) {
          vehicleTypes = decoded.map((e) => e.toString()).toList();
        }

        // Remove duplicates
        vehicleTypes = vehicleTypes.toSet().toList();

        setState(() {
          _vehicleTypeOptions = vehicleTypes;
        });
        debugPrint('Successfully fetched vehicle types: $_vehicleTypeOptions');
      } else {
        if (mounted) {
          setState(() {
            _vehicleTypeError =
                'Failed to load vehicle types: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading vehicle types: $e');
      if (mounted) {
        setState(() {
          _vehicleTypeError = 'Network error loading vehicle types';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVehicleTypes = false;
        });
      }
    }
  }

  Future<void> _loadDropdownData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all vehicles initially
      debugPrint('Fetching all vehicles...');
      final response = await _client.get(
        Uri.parse('$baseUrl/booking/dropdown/vehicleNumber'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['data'] != null && decoded['data'] is List) {
          final List<dynamic> vehicleList = decoded['data'];
          _vehicles = vehicleList.map((v) {
            return VehicleModel.fromJson({
              '_id': v['vehicle_id'] ?? '',
              'vehicle_id': v['vehicle_id'] ?? '',
              'vehicle_number': (v['vehicle_number'] ?? '').toString().trim(),
              'vehicle_type': (v['vehicle_type'] ?? '').toString().trim(),
              'status': v['booking_color_code'] ?? 'green',
              'seating_capacity':
                  (v['seating_capacity'] ?? '4').toString().trim(),
              'fuel_type': v['fuel_type'] ?? [],
              'current_km': v['current_km'],
              'alerts': v['alerts'] ?? [],
            });
          }).toList();
        }
      }

      // Load other dropdown data
      final dropdownResponse = await _apiService.getDropdownData();
      if (dropdownResponse.success && dropdownResponse.data != null) {
        setState(() {
          _employees = dropdownResponse.data!['employees'] ?? [];
          _roles = dropdownResponse.data!['roles'] ?? [];
          _customers = dropdownResponse.data!['customers'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      _showErrorSnackBar('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchVehiclesByType(String vehicleType) async {
    if (vehicleType.isEmpty) {
      setState(() {
        _filteredVehicles = [];
        _vehicleNumberController.clear();
        _selectedVehicle = null;
        _travelers.clear();
        _isVehicleSelected = false;
      });
      return;
    }

    setState(() {
      _loadingVehicles = true;
      _vehicleNumberController.clear();
      _selectedVehicle = null;
      _travelers.clear();
      _capacityError = '';
      _isVehicleSelected = false;
    });

    try {
      // Filter vehicles by type from the already loaded vehicles
      final filtered = _vehicles
          .where(
              (v) => v.vehicleType.toLowerCase() == vehicleType.toLowerCase())
          .toList();

      // Ensure unique vehicles by number
      final uniqueFiltered = <String, Map<String, dynamic>>{};
      for (var v in filtered) {
        final number = v.vehicleNumber.toString().trim();
        if (number.isNotEmpty && !uniqueFiltered.containsKey(number)) {
          uniqueFiltered[number] = {
            'vehicle_id': v.vehicleId,
            'vehicle_number': number,
            'vehicle_type': v.vehicleType,
            'booking_color_code': v.status,
            'status': v.status,
            'seating_capacity': v.seatingCapacity,
            'alerts': v.alerts,
          };
        }
      }

      setState(() {
        _filteredVehicles = uniqueFiltered.values.toList();
      });

      debugPrint('Found ${filtered.length} vehicles for type: $vehicleType');
    } catch (e) {
      debugPrint('Error filtering vehicles: $e');
      if (mounted) _showValidationAlert('Error loading vehicles');
    } finally {
      if (mounted) {
        setState(() {
          _loadingVehicles = false;
        });
      }
    }
  }

  void _populateForm() {
    final booking = widget.booking!;

    _vehicleNumberController.text = booking['vehicle_number'] ?? '';
    _vehicleTypeController.text = booking['vehicle_type'] ?? '';

    // Handle booking type
    final bookingTypeFromApi =
        booking['booking_type']?.toLowerCase() ?? 'office';
    _bookingType = bookingTypeFromApi;

    // Set selected vehicle type
    _selectedVehicleType = booking['vehicle_type'] ?? '';

    // Find selected vehicle
    if (_vehicleNumberController.text.isNotEmpty) {
      _selectedVehicle = VehicleModel.fromJson({
        '_id': booking['vehicle_id'] ?? '',
        'vehicle_id': booking['vehicle_id'] ?? '',
        'vehicle_number': _vehicleNumberController.text,
        'vehicle_type': _vehicleTypeController.text,
        'status': booking['status_color'] ?? 'green',
        'seating_capacity': booking['seating_capacity'] ?? '4',
        'alerts': booking['alerts'] ?? [],
      });
      _isVehicleSelected = true;
    }

    // Handle dates
    if (booking['from_date'] != null) {
      _fromDateTimeController.text = _formatDateForInput(booking['from_date']);
    }
    if (booking['to_date'] != null) {
      _toDateTimeController.text = _formatDateForInput(booking['to_date']);
    }

    // Handle location based on booking type
    if (_bookingType == 'office') {
      // Handle customer names
      if (booking['customer_name'] != null) {
        if (booking['customer_name'] is List) {
          _selectedCustomers = List<String>.from(booking['customer_name']);
        } else if (booking['customer_name'] is String) {
          _selectedCustomers = [booking['customer_name']];
        }
      }

      // Handle office location
      if (booking['client_location'] != null) {
        if (booking['client_location'] is List) {
          final locations = booking['client_location'] as List;
          if (locations.isNotEmpty) {
            _locationController.text = locations.first?.toString() ?? '';
          }
        } else {
          _locationController.text =
              booking['client_location']?.toString() ?? '';
        }
      }

      // Handle referral data
      _isReferral =
          (booking['referred_customer_name']?.toString().isNotEmpty ?? false);
      if (_isReferral) {
        _referredCustomerNameController.text =
            booking['referred_customer_name'] ?? '';
        _referredByController.text = booking['referred_by'] ?? '';
        _referredClientLocationController.text =
            booking['referred_client_location'] ?? '';
      }
    } else {
      // Personal booking
      _personalLocationController.text = booking['personal_location'] ?? '';
      _personalPurposeController.text = booking['personal_purpose'] ?? '';
    }

    // Handle travelers
    if (booking['travelers'] != null && booking['travelers'] is List) {
      _travelers = List<Map<String, dynamic>>.from(booking['travelers'])
          .map((t) => Traveler.fromJson(t))
          .toList();
    }
  }

  String _formatDateForInput(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showValidationAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text('Validation Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text('Success'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onSave?.call();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Submission'),
          content: const Text('Are you sure you want to submit this booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _executeSubmission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showCapacityWarning(int capacity, int current) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text('Capacity Warning'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vehicle capacity is $capacity persons.'),
              const SizedBox(height: 8),
              Text('Current travelers: $current'),
              const SizedBox(height: 8),
              Text(
                'You cannot add more than $capacity travelers.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showUnavailableVehicleDialog(String vehicleNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade700, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Vehicle Cannot Be Booked',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      const TextSpan(
                        text: 'The selected vehicle ',
                      ),
                      TextSpan(
                        text: vehicleNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const TextSpan(
                        text: ' cannot be booked because its status is ',
                      ),
                      const TextSpan(
                        text: 'Unavailable (RED)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const TextSpan(
                        text: '. Please select a different vehicle with ',
                      ),
                      const TextSpan(
                        text: 'Available (GREEN)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const TextSpan(
                        text: ' status to proceed with the booking smoothly.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Only vehicles with GREEN status are available for booking.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'OK, Got It',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  void _showMaintenanceVehicleDialog(String vehicleNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.build, color: Colors.orange.shade700, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Vehicle Under Maintenance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      const TextSpan(
                        text: 'The selected vehicle ',
                      ),
                      TextSpan(
                        text: vehicleNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const TextSpan(
                        text: ' is currently under ',
                      ),
                      const TextSpan(
                        text: 'Maintenance (ORANGE)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const TextSpan(
                        text: '. Please select a different vehicle with ',
                      ),
                      const TextSpan(
                        text: 'Available (GREEN)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const TextSpan(
                        text: ' status to proceed with the booking.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.orange.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'OK, Got It',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  void _showGreyVehicleInfo(String vehicleNumber) {
    if (!mounted) return;
    // Show snackbar for grey vehicle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Booking not allowed â€” Vehicle status GREY',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _checkVehicleAvailabilityAndSelect(String vehicleNumber) {
    // Find the selected vehicle
    final vehicleData = _filteredVehicles.firstWhere(
      (v) => v['vehicle_number'] == vehicleNumber,
      orElse: () => {},
    );

    if (vehicleData.isNotEmpty) {
      final status =
          vehicleData['booking_color_code']?.toString().toLowerCase() ??
              vehicleData['status']?.toString().toLowerCase() ??
              'green';

      // Red and Orange vehicles - show dialog and don't select
      if (status == 'red') {
        _showUnavailableVehicleDialog(vehicleNumber);
        return;
      }

      if (status == 'orange') {
        _showMaintenanceVehicleDialog(vehicleNumber);
        return;
      }
    }

    // For grey and green vehicles, proceed with selection
    _onVehicleSelected(vehicleNumber);
  }

  void _onVehicleSelected(String? vehicleNumber) {
    if (vehicleNumber == null || vehicleNumber.isEmpty) return;

    setState(() {
      _vehicleNumberController.text = vehicleNumber.trim();
      _selectedVehicle = null;
      _travelers.clear();
      _capacityError = '';
      _loadingVehicleInfo = true;
      _isVehicleSelected = true; // Set to true immediately when a number is provided
    });

    // Find the selected vehicle from filtered vehicles
    final vehicleData = _filteredVehicles.firstWhere(
      (v) => v['vehicle_number'].toString().trim() == vehicleNumber.trim(),
      orElse: () => {},
    );

    if (vehicleData.isNotEmpty) {
      final vehicle = VehicleModel.fromJson({
        '_id': vehicleData['vehicle_id'] ?? '',
        'vehicle_id': vehicleData['vehicle_id'] ?? '',
        'vehicle_number': vehicleData['vehicle_number'] ?? vehicleNumber,
        'vehicle_type': vehicleData['vehicle_type'] ?? _selectedVehicleType ?? '',
        'status': vehicleData['booking_color_code'] ?? 'green',
        'seating_capacity': vehicleData['seating_capacity'] ?? '4',
        'alerts': vehicleData['alerts'] ?? [],
      });

      if (mounted) {
        setState(() {
          _selectedVehicle = vehicle;
          _vehicleTypeController.text = vehicle.vehicleType;
          _isVehicleSelected = true;
          _loadingVehicleInfo = false;
        });
      }

      // Show warning for grey vehicles
      if (vehicle.status.toLowerCase() == 'grey' ||
          vehicle.status.toLowerCase() == 'gray') {
        _showGreyVehicleInfo(vehicle.vehicleNumber);
      }
    } else {
      if (mounted) {
        setState(() {
          _loadingVehicleInfo = false;
        });
      }
    }
  }

  void _addTraveler() {
    setState(() {
      _capacityError = '';
    });

    // Check if vehicle is selected
    if (!_isVehicleSelected || _vehicleNumberController.text.isEmpty) {
      _showValidationAlert('Please select a vehicle first');
      return;
    }

    // Check if employee is selected
    if (_selectedEmployee.isEmpty) {
      _showValidationAlert('Please select an employee');
      return;
    }

    // Check seating capacity
    if (_selectedVehicle != null) {
      final seatingCapacity = int.tryParse(_selectedVehicle!.seatingCapacity);
      if (seatingCapacity != null && _travelers.length >= seatingCapacity) {
        _showCapacityWarning(seatingCapacity, _travelers.length);
        setState(() {
          _capacityError =
              'You can\'t add more travelers. Vehicle capacity is $seatingCapacity persons';
        });
        return;
      }
    }

    // Check if there's already a driver when trying to add another driver
    if (_selectedTravelStatus.toLowerCase() == 'driver') {
      final hasDriver = _travelers.any((t) => t.role.toLowerCase() == 'driver');
      if (hasDriver) {
        _showValidationAlert(
            'A driver is already assigned. Only one driver allowed.');
        return;
      }
    }

    final newTraveler = Traveler(
      employeeId: DateTime.now().millisecondsSinceEpoch.toString(),
      employeeName: _selectedEmployee,
      role: _selectedTravelStatus,
    );

    setState(() {
      _travelers.add(newTraveler);
      _selectedEmployee = '';
      _selectedTravelStatus = 'driver';
    });
  }

  void _removeTraveler(int index) {
    setState(() {
      _travelers.removeAt(index);
      _capacityError = '';
    });
  }

  bool _hasDriver() {
    return _travelers.any((t) => t.role.toLowerCase() == 'driver');
  }

  int? _getRemainingCapacity() {
    if (_selectedVehicle == null) return null;

    final seatingCapacity = int.tryParse(_selectedVehicle!.seatingCapacity);
    if (seatingCapacity == null) return null;

    return seatingCapacity - _travelers.length;
  }

  String _getTravelerCountText() {
    if (_selectedVehicle == null) {
      return '${_travelers.length} travelers added';
    }

    final seatingCapacity = int.tryParse(_selectedVehicle!.seatingCapacity);
    if (seatingCapacity == null) {
      return '${_travelers.length} travelers added';
    }

    return '${_travelers.length}/$seatingCapacity travelers added';
  }

  String? _validateForm() {
    if (_selectedVehicleType == null || _selectedVehicleType!.isEmpty) {
      return 'Vehicle type is required';
    }
    if (!_isVehicleSelected || _vehicleNumberController.text.isEmpty) {
      return 'Vehicle number is required';
    }
    if (_fromDateTimeController.text.isEmpty) {
      return 'From date and time is required';
    }
    if (_toDateTimeController.text.isEmpty) {
      return 'To date and time is required';
    }

    // Validate dates
    try {
      final fromDate = DateTime.parse(_fromDateTimeController.text);
      final toDate = DateTime.parse(_toDateTimeController.text);

      if (toDate.isBefore(fromDate)) {
        return 'To date cannot be before from date';
      }
    } catch (e) {
      return 'Invalid date format';
    }

    // Check if vehicle is grey (booking not allowed)
    if (_selectedVehicle != null &&
        (_selectedVehicle!.status.toLowerCase() == 'grey' ||
            _selectedVehicle!.status.toLowerCase() == 'gray')) {
      return 'Booking not allowed â€” Vehicle status GREY';
    }

    if (_bookingType == 'office') {
      if (_selectedCustomers.isEmpty) {
        return 'At least one customer is required for office booking';
      }
      if (_locationController.text.isEmpty) {
        return 'Location is required for office booking';
      }
      if (_isReferral) {
        if (_referredCustomerNameController.text.isEmpty) {
          return 'Referral customer name is required';
        }
        if (_referredByController.text.isEmpty) {
          return 'Referred by is required';
        }
        if (_referredClientLocationController.text.isEmpty) {
          return 'Referral client location is required';
        }
      }
    }

    if (_bookingType == 'personal') {
      if (_personalLocationController.text.isEmpty) {
        return 'Location is required for personal booking';
      }
      if (_personalPurposeController.text.isEmpty) {
        return 'Purpose is required for personal booking';
      }
    }

    // Travelers validation
    if (_travelers.isEmpty) {
      return 'At least one traveler is required';
    }

    // Check if there's at least one driver
    if (!_hasDriver()) {
      return 'At least one traveler must be a driver';
    }

    return null;
  }

  Map<String, dynamic> _prepareBookingData() {
    final fromDate = DateTime.parse(_fromDateTimeController.text);
    final toDate = DateTime.parse(_toDateTimeController.text);

    final List<Map<String, dynamic>> travelersJson = _travelers.map((traveler) {
      return {
        'employee_id': traveler.employeeId,
        'employee_name': traveler.employeeName,
        'role': traveler.role,
      };
    }).toList();

    Map<String, dynamic> data = {
      'vehicle_type': _vehicleTypeController.text,
      'vehicle_number': _vehicleNumberController.text,
      'from_date':
          '${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}',
      'to_date':
          '${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}',
      'booking_type': _bookingType,
      'travelers': travelersJson,
      'status_color': _selectedVehicle?.status ?? 'green',
    };

    if (_bookingType == 'office') {
      data['customer_name'] = _selectedCustomers;

      if (_locationController.text.isNotEmpty) {
        final locations = _locationController.text
            .split(',')
            .map((loc) => loc.trim())
            .where((loc) => loc.isNotEmpty)
            .toList();
        data['client_location'] = locations;
      } else {
        data['client_location'] = [];
      }

      if (_isReferral) {
        data['referred_customer_name'] = _referredCustomerNameController.text;
        data['referred_by'] = _referredByController.text;
        data['referred_client_location'] =
            _referredClientLocationController.text;
      }
    } else {
      data['personal_location'] = _personalLocationController.text;
      data['personal_purpose'] = _personalPurposeController.text;
      data['customer_name'] = [];
      data['client_location'] = [];
    }

    return data;
  }

  Future<void> _executeSubmission() async {
    // Double check for grey vehicles before submitting
    if (_selectedVehicle != null &&
        (_selectedVehicle!.status.toLowerCase() == 'grey' ||
            _selectedVehicle!.status.toLowerCase() == 'gray')) {
      _showValidationAlert('Booking not allowed â€” Vehicle status GREY');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final bookingData = _prepareBookingData();

    final response = widget.isEditing
        ? await _apiService.updateBooking(widget.booking!['_id'], bookingData)
        : await _apiService.createBooking(bookingData);

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      _showSuccessAlert(response.message);
    } else {
      _showValidationAlert(response.message);
    }
  }

  void _submitBooking() {
    final errorMessage = _validateForm();
    if (errorMessage != null) {
      _showValidationAlert(errorMessage);
      return;
    }

    // Show confirmation dialog
    _showConfirmationDialog();
  }

  void _clearForm() {
    widget.onCancel?.call();
  }

  Future<void> _selectCustomers() async {
    List<String> tempSelected = List.from(_selectedCustomers);

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Customers'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_customers.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('No customers available'),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final customer = _customers[index];
                            final isSelected = tempSelected.contains(customer);
                            return CheckboxListTile(
                              title: Text(customer),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    if (!tempSelected.contains(customer)) {
                                      tempSelected.add(customer);
                                    }
                                  } else {
                                    tempSelected.remove(customer);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, tempSelected);
              },
              child: Text('Confirm (${tempSelected.length})'),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedCustomers = selected;
      });
    }
  }

  // Color helpers
  Color _getVehicleStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'grey':
      case 'gray':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getVehicleStatusBackgroundColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'green':
        return Colors.green.shade50;
      case 'red':
        return Colors.red.shade50;
      case 'orange':
        return Colors.orange.shade50;
      case 'grey':
      case 'gray':
        return Colors.grey.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  IconData _getVehicleStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'green':
        return Icons.check_circle;
      case 'red':
        return Icons.cancel;
      case 'orange':
        return Icons.warning;
      case 'grey':
      case 'gray':
        return Icons.info;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isEditing
                                    ? 'Edit Booking'
                                    : 'Create New Booking',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.isEditing
                                    ? 'Update the booking details below'
                                    : 'Fill in the details below to create a vehicle booking',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: _clearForm,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Scrollable Form Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle & Booking Information Card
                          _buildSectionCard(
                            title: 'ðŸš— Vehicle & Booking Information',
                            children: [
                              const SizedBox(height: 16),

                              // Vehicle Type Dropdown
                              _buildVehicleTypeDropdown(),

                              const SizedBox(height: 16),

                              // Vehicle Number Dropdown (filtered by type)
                              _buildVehicleNumberDropdown(),

                              if (_loadingVehicleInfo)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Loading vehicle details...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 16),

                              // Vehicle Type (auto-filled)
                              TextFormField(
                                controller: _vehicleTypeController,
                                decoration: InputDecoration(
                                  labelText: 'Vehicle Type *',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.directions_car),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  hintText:
                                      'Auto-filled from vehicle selection',
                                ),
                                readOnly: true,
                              ),

                              const SizedBox(height: 16),

                              // Date & Time Row
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth > 600) {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: _buildDateTimeField(
                                            controller: _fromDateTimeController,
                                            label: 'From Date & Time *',
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildDateTimeField(
                                            controller: _toDateTimeController,
                                            label: 'To Date & Time *',
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Column(
                                      children: [
                                        _buildDateTimeField(
                                          controller: _fromDateTimeController,
                                          label: 'From Date & Time *',
                                        ),
                                        const SizedBox(height: 16),
                                        _buildDateTimeField(
                                          controller: _toDateTimeController,
                                          label: 'To Date & Time *',
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),

                              // Vehicle Info Card
                              _buildVehicleInfoCard(),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Booking Type Card
                          _buildSectionCard(
                            title: 'ðŸ“‹ Booking Type *',
                            children: [
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildBookingTypeButton(
                                      icon: Icons.business,
                                      label: 'Office Booking',
                                      description: 'Business purposes',
                                      isSelected: _bookingType == 'office',
                                      selectedColor: AppTheme.secondary,
                                      onTap: () {
                                        setState(() {
                                          _bookingType = 'office';
                                          _isReferral = false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildBookingTypeButton(
                                      icon: Icons.home,
                                      label: 'Personal Booking',
                                      description: 'Personal use',
                                      isSelected: _bookingType == 'personal',
                                      selectedColor: Colors.green,
                                      onTap: () {
                                        setState(() {
                                          _bookingType = 'personal';
                                          _isReferral = false;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Dynamic Fields based on Booking Type
                          if (_bookingType == 'office') ...[
                            _buildOfficeBookingFields(),
                            const SizedBox(height: 16),
                          ],

                          if (_bookingType == 'personal') ...[
                            _buildPersonalBookingFields(),
                            const SizedBox(height: 16),
                          ],

                          // Traveler Management Card
                          _buildTravelerManagementCard(),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fixed Action Buttons at Bottom
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _clearForm,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.close, size: 18),
                              SizedBox(width: 8),
                              Text('Cancel'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      widget.isEditing
                                          ? Icons.edit
                                          : Icons.save,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.isEditing
                                          ? 'Update Booking'
                                          : 'Create Booking',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Helper Widgets
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4494),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleTypeDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _vehicleTypeError != null ? Colors.red : Colors.grey.shade300,
          width: _vehicleTypeError != null ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(
                  color: _vehicleTypeError != null
                      ? Colors.red
                      : Colors.grey.shade300,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Select Vehicle Type *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (_isLoadingVehicleTypes) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
          if (_isLoadingVehicleTypes)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Loading vehicle types...'),
            )
          else if (_vehicleTypeOptions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No vehicle types available',
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (_vehicleTypeError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error,
                              color: Colors.red.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _vehicleTypeError!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedVehicleType,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Choose vehicle type...'),
              icon: const Icon(Icons.arrow_drop_down),
              isExpanded: true,
              items: _vehicleTypeOptions.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? type) {
                setState(() {
                  _selectedVehicleType = type;
                  _vehicleTypeController.text = type ?? '';
                  _vehicleTypeError = null;
                });
                if (type != null) {
                  _fetchVehiclesByType(type);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleNumberDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedVehicleType == null
              ? Colors.grey.shade300
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: const Text(
              'Select Vehicle Number *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          if (_loadingVehicles)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Loading vehicles...'),
            )
          else if (_selectedVehicleType == null)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('First select vehicle type...'),
            )
          else if (_filteredVehicles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No vehicles available for this type'),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _vehicleNumberController.text.isNotEmpty
                  ? _vehicleNumberController.text
                  : null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.arrow_drop_down),
              isExpanded: true,
              hint: const Text('Choose a vehicle number...'),
              // Ensure items are unique by vehicle_number to prevent crashes
              items: () {
                final seen = <String>{};
                return _filteredVehicles.where((v) {
                  final number = v['vehicle_number']?.toString() ?? '';
                  if (number.isEmpty || seen.contains(number)) return false;
                  seen.add(number);
                  return true;
                }).map((vehicle) {
                  final status =
                      vehicle['booking_color_code']?.toString().toLowerCase() ??
                          vehicle['status']?.toString().toLowerCase() ??
                          'green';
                  final vehicleNumber =
                      vehicle['vehicle_number']?.toString() ?? '';

                  // Determine status text and color
                  String statusText = 'Available';
                  Color statusColor = Colors.green;
                  Color textColor = Colors.green;
                  bool isEnabled = true;

                  if (status == 'red') {
                    statusText = 'Unavailable';
                    statusColor = Colors.red;
                    textColor = Colors.red;
                    isEnabled = false;
                  } else if (status == 'orange') {
                    statusText = 'Maintenance';
                    statusColor = Colors.orange;
                    textColor = Colors.orange;
                    isEnabled = false;
                  } else if (status == 'grey' || status == 'gray') {
                    statusText = 'Booked';
                    statusColor = Colors.grey;
                    textColor = Colors.grey;
                    isEnabled = true;
                  } else {
                    statusText = 'Available';
                    statusColor = Colors.green;
                    textColor = Colors.green;
                    isEnabled = true;
                  }

                  return DropdownMenuItem<String>(
                    value: vehicleNumber,
                    enabled: isEnabled,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: isEnabled ? Colors.black : Colors.grey,
                              ),
                              children: [
                                TextSpan(
                                  text: vehicleNumber,
                                  style: TextStyle(
                                    color: isEnabled ? textColor : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ($statusText)',
                                  style: TextStyle(
                                    color:
                                        isEnabled ? statusColor : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isEnabled)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.block,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList();
              }(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _checkVehicleAvailabilityAndSelect(newValue);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDateTimeField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      readOnly: true,
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );

        if (pickedDate != null) {
          if (!mounted) return;
          final TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );

          if (pickedTime != null) {
            final datetime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            setState(() {
              controller.text =
                  '${datetime.year}-${datetime.month.toString().padLeft(2, '0')}-${datetime.day.toString().padLeft(2, '0')}T${datetime.hour.toString().padLeft(2, '0')}:${datetime.minute.toString().padLeft(2, '0')}';
            });
          }
        }
      },
    );
  }

  Widget _buildBookingTypeButton({
    required IconData icon,
    required String label,
    required String description,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? selectedColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? selectedColor : Colors.grey.shade700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    if (_selectedVehicle == null) return const SizedBox.shrink();

    final vehicle = _selectedVehicle!;
    final statusColor = _getVehicleStatusColor(vehicle.status);
    final bgColor = _getVehicleStatusBackgroundColor(vehicle.status);
    final statusIcon = _getVehicleStatusIcon(vehicle.status);
    final seatingCapacity = int.tryParse(vehicle.seatingCapacity);

    // Get status text
    String statusText = 'Available';
    String statusMessage = '';

    if (vehicle.status.toLowerCase() == 'red') {
      statusText = 'Unavailable';
      statusMessage =
          'This vehicle is currently unavailable for booking. Please select a different vehicle.';
    } else if (vehicle.status.toLowerCase() == 'orange') {
      statusText = 'Maintenance';
      statusMessage = 'This vehicle is under maintenance and cannot be booked.';
    } else if (vehicle.status.toLowerCase() == 'grey' ||
        vehicle.status.toLowerCase() == 'gray') {
      statusText = 'Booked Status';
      statusMessage =
          'This vehicle is currently booked. Existing booking data has been loaded and can be edited.';
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Vehicle Status & Information',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Seating Capacity
          if (seatingCapacity != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Seating Capacity: $seatingCapacity persons',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],

          // Status-specific message
          if (statusMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      statusMessage,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Alerts
          if (vehicle.hasAlerts) ...[
            const SizedBox(height: 12),
            ...vehicle.alerts.map((alert) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.toString(),
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildOfficeBookingFields() {
    return _buildSectionCard(
      title: 'ðŸ¢ Office Booking Details',
      children: [
        const SizedBox(height: 16),

        // Customer Selection
        InkWell(
          onTap: _selectCustomers,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people, color: AppTheme.secondary),
                    const SizedBox(width: 8),
                    const Text(
                      'Customers *',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _selectedCustomers.isEmpty
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedCustomers.length} selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedCustomers.isEmpty
                              ? Colors.orange.shade800
                              : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_selectedCustomers.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedCustomers.map((customer) {
                      return Chip(
                        label: Text(customer),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedCustomers.remove(customer);
                          });
                        },
                        backgroundColor:
                            AppTheme.secondary.withValues(alpha: 0.1),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    'Tap to select customers...',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Location Field
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Location *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_on),
            filled: true,
            fillColor: Colors.grey.shade50,
            hintText: 'Enter destination address...',
          ),
        ),
        const SizedBox(height: 16),

        // Referral Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.orange.shade50,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Referral Booking',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enable for referral customers',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isReferral,
                    onChanged: (value) {
                      setState(() {
                        _isReferral = value;
                      });
                    },
                    activeThumbColor: Colors.orange,
                  ),
                ],
              ),
              if (_isReferral) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.orange.shade300,
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link,
                              color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Referral Information',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referredCustomerNameController,
                        decoration: InputDecoration(
                          labelText: 'Referral Customer Name *',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_add,
                              color: Colors.orange.shade700),
                          filled: true,
                          fillColor: Colors.orange.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referredByController,
                        decoration: InputDecoration(
                          labelText: 'Referred By Employee *',
                          border: const OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.people, color: Colors.orange.shade700),
                          filled: true,
                          fillColor: Colors.orange.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referredClientLocationController,
                        decoration: InputDecoration(
                          labelText: 'Referral Client Location *',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city,
                              color: Colors.orange.shade700),
                          filled: true,
                          fillColor: Colors.orange.shade50,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalBookingFields() {
    return _buildSectionCard(
      title: 'ðŸ  Personal Booking Details',
      children: [
        const SizedBox(height: 16),
        TextFormField(
          controller: _personalLocationController,
          decoration: InputDecoration(
            labelText: 'Destination Location *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_on, color: Colors.green),
            filled: true,
            fillColor: Colors.green.shade50,
            hintText: 'Enter destination address...',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _personalPurposeController,
          decoration: InputDecoration(
            labelText: 'Trip Purpose *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.flag, color: Colors.green),
            filled: true,
            fillColor: Colors.green.shade50,
            hintText: 'Describe the purpose of your trip...',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTravelerManagementCard() {
    return _buildSectionCard(
      title: 'ðŸ‘¥ Traveler Management',
      children: [
        const SizedBox(height: 16),

        // Add Traveler Form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildEmployeeDropdown(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRoleDropdown(),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: ElevatedButton.icon(
                            onPressed: _addTraveler,
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildEmployeeDropdown(),
                        const SizedBox(height: 12),
                        _buildRoleDropdown(),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addTraveler,
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('Add Traveler'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),

        // Capacity Error
        if (_capacityError.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capacity Limit Reached',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _capacityError,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Driver Warning
        if (!_hasDriver() && _travelers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver Required',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'At least one traveler must be assigned as a driver',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Travelers List
        if (_travelers.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Colors.purple.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _getTravelerCountText(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Show remaining capacity badge
              if (_getRemainingCapacity() != null &&
                  _getRemainingCapacity()! > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_getRemainingCapacity()} seats left',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ..._travelers.asMap().entries.map((entry) {
            final index = entry.key;
            final traveler = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade50, Colors.white],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: traveler.role.toLowerCase() == 'driver'
                        ? AppTheme.secondary
                        : Colors.green,
                  ),
                ),
                title: Row(
                  children: [
                    Icon(
                      traveler.role.toLowerCase() == 'driver'
                          ? Icons.drive_eta
                          : Icons.person,
                      size: 18,
                      color: traveler.role.toLowerCase() == 'driver'
                          ? AppTheme.secondary
                          : Colors.purple.shade300,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      traveler.employeeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: traveler.role.toLowerCase() == 'driver'
                              ? AppTheme.secondary.withValues(alpha: 0.1)
                              : Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: traveler.role.toLowerCase() == 'driver'
                                ? AppTheme.secondary.withValues(alpha: 0.3)
                                : Colors.purple.shade200,
                          ),
                        ),
                        child: Text(
                          traveler.role,
                          style: TextStyle(
                            fontSize: 11,
                            color: traveler.role.toLowerCase() == 'driver'
                                ? AppTheme.secondary
                                : Colors.purple.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _removeTraveler(index),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildEmployeeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedEmployee.isNotEmpty ? _selectedEmployee : null,
      decoration: InputDecoration(
        labelText: 'Select Employee',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: () {
        final seen = <String>{};
        return _employees.where((employee) {
          if (employee.isEmpty || seen.contains(employee)) return false;
          seen.add(employee);
          return true;
        }).map((employee) {
          return DropdownMenuItem<String>(
            value: employee,
            child: Text(employee),
          );
        }).toList();
      }(),
      onChanged: (value) {
        setState(() {
          _selectedEmployee = value ?? '';
        });
      },
      hint: const Text('Choose an employee...'),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedTravelStatus,
      decoration: InputDecoration(
        labelText: 'Select Role',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: () {
        final seen = <String>{};
        return (_roles.isNotEmpty
                ? _roles
                : ['driver', 'passenger', 'driver & traveler'])
            .where((role) {
          final r = role.toLowerCase();
          if (r.isEmpty || seen.contains(r)) return false;
          seen.add(r);
          return true;
        }).map((role) {
          return DropdownMenuItem<String>(
            value: role.toLowerCase(),
            child: Text(role),
          );
        }).toList();
      }(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedTravelStatus = value;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _client.close();
    _scrollController.dispose();
    _vehicleNumberController.dispose();
    _vehicleTypeController.dispose();
    _fromDateTimeController.dispose();
    _toDateTimeController.dispose();
    _locationController.dispose();
    _personalLocationController.dispose();
    _personalPurposeController.dispose();
    _referredCustomerNameController.dispose();
    _referredByController.dispose();
    _referredClientLocationController.dispose();
    super.dispose();
  }
}
