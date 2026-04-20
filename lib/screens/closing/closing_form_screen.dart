import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../models/closing_model.dart';
import 'package:http_parser/http_parser.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class ClosingPage extends StatefulWidget {
  final ClosingRecord? editingRecord;
  final Function()? onBack;
  final Function()? onSave;
  final Function({
    required String title,
    required String message,
    required String type,
    String confirmText,
    Function? onConfirm,
  })? showAlert;
  final bool isMobile;

  const ClosingPage({
    super.key,
    this.editingRecord,
    this.onBack,
    this.onSave,
    this.showAlert,
    this.isMobile = false,
  });

  @override
  State<ClosingPage> createState() => _ClosingPageState();
}

class _ClosingPageState extends State<ClosingPage> {
  final _formKey = GlobalKey<FormState>();
  final List<File> _selectedPhotos = [];
  bool _isSubmitting = false;
  bool _isTogglingAlert = false;
  bool _loadingData = false;

  List<Map<String, dynamic>> _vehicles = [];
  List<String> _users = [];

  final TextEditingController _endKmController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  String? _selectedVehicleNumber;
  String? _selectedUserId;
  String _alertType = "Normal";
  String? _vehicleId;

  final ImagePicker _picker = ImagePicker();
  final String _apiBase = AppConstants.rootUrl;

  @override
  void initState() {
    super.initState();

    if (widget.editingRecord != null) {
      _selectedVehicleNumber = widget.editingRecord!.vehicleNumber;
      _selectedUserId = widget.editingRecord!.userId;
      _endKmController.text =
          widget.editingRecord!.endKm.toString(); // FIXED: added toString()
      _remarksController.text = widget.editingRecord!.remarks;
      _alertType = widget.editingRecord!.alertType ??
          "Normal"; // FIXED: changed from status to alertType
      _vehicleId = widget.editingRecord!.vehicleId;
    }

    if (widget.editingRecord == null) {
      _fetchDropdownData();
    }
  }

  Future<void> _fetchDropdownData() async {
    setState(() {
      _loadingData = true;
    });

    try {
      debugPrint('DEBUG: Fetching vehicles data...');
      // Fetch vehicles
      final vehiclesResponse = await http
          .get(Uri.parse('$_apiBase/api/booking/dropdown/vehicleNumber'));

      debugPrint('DEBUG: Vehicles response status: ${vehiclesResponse.statusCode}');
      debugPrint('DEBUG: Vehicles response body: ${vehiclesResponse.body}');

      if (vehiclesResponse.statusCode == 200) {
        final vehiclesData = jsonDecode(vehiclesResponse.body);
        debugPrint('DEBUG: Vehicles decoded data: $vehiclesData');

        if (vehiclesData is List) {
          debugPrint('DEBUG: Vehicles data is a List');
          setState(() {
            _vehicles = List<Map<String, dynamic>>.from(vehiclesData);
          });
        } else if (vehiclesData['data'] is List) {
          debugPrint('DEBUG: Vehicles data has data field which is a List');
          setState(() {
            _vehicles = List<Map<String, dynamic>>.from(vehiclesData['data']);
          });
        } else if (vehiclesData['vehicles'] is List) {
          debugPrint('DEBUG: Vehicles data has vehicles field which is a List');
          setState(() {
            _vehicles =
                List<Map<String, dynamic>>.from(vehiclesData['vehicles']);
          });
        } else {
          debugPrint('DEBUG: Unexpected vehicles response format');
          setState(() {
            _vehicles = [];
          });
        }
      }

      debugPrint('DEBUG: Fetching users data...');
      // Fetch users
      final usersResponse =
          await http.get(Uri.parse('$_apiBase/api/booking/dropdown/users'));

      debugPrint('DEBUG: Users response status: ${usersResponse.statusCode}');
      debugPrint('DEBUG: Users response body: ${usersResponse.body}');

      if (usersResponse.statusCode == 200) {
        final usersData = jsonDecode(usersResponse.body);
        debugPrint('DEBUG: Users decoded data: $usersData');

        List<String> processedUsers = [];

        if (usersData is List) {
          debugPrint('DEBUG: Users data is a List');
          processedUsers = usersData
              .where((user) => user is String && user.contains('_'))
              .map((user) {
            final parts = (user as String).split('_');
            return parts.length >= 2 ? '${parts[0]}_${parts[1]}' : user;
          }).toList();
        } else if (usersData['data'] is List) {
          debugPrint('DEBUG: Users data has data field which is a List');
          processedUsers = (usersData['data'] as List)
              .where((user) => user is String && user.contains('_'))
              .map((user) {
            final parts = (user as String).split('_');
            return parts.length >= 2 ? '${parts[0]}_${parts[1]}' : user;
          }).toList();
        } else if (usersData['users'] is List) {
          debugPrint('DEBUG: Users data has users field which is a List');
          processedUsers = (usersData['users'] as List)
              .where((user) => user is String && user.contains('_'))
              .map((user) {
            final parts = (user as String).split('_');
            return parts.length >= 2 ? '${parts[0]}_${parts[1]}' : user;
          }).toList();
        }

        debugPrint('DEBUG: Processed users: $processedUsers');
        setState(() {
          _users = processedUsers;
        });
      }
    } catch (error) {
      debugPrint('DEBUG: Error fetching data: $error');
      _showAlert('Error', 'Failed to load data: $error');
    } finally {
      setState(() {
        _loadingData = false;
      });
      debugPrint('DEBUG: Finished loading dropdown data');
      debugPrint('DEBUG: Vehicles count: ${_vehicles.length}');
      debugPrint('DEBUG: Users count: ${_users.length}');
    }
  }

  void _showAlert(String title, String message, {String type = 'error'}) {
    debugPrint(
        'DEBUG: Showing alert - Title: $title, Message: $message, Type: $type');
    if (widget.showAlert != null) {
      widget.showAlert!(
        title: title,
        message: message,
        type: type,
        confirmText: 'OK',
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    try {
      debugPrint('DEBUG: Picking images...');
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      debugPrint('DEBUG: Selected ${images.length} images');
      setState(() {
        _selectedPhotos.addAll(images.map((xFile) => File(xFile.path)));
      });
    } catch (e) {
      debugPrint('DEBUG: Error picking images: $e');
      _showAlert('Error', 'Failed to pick images: $e');
    }
  }

  void _removePhoto(int index) {
    debugPrint('DEBUG: Removing photo at index $index');
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _setAlertType(String type) async {
    if (type == _alertType) return;
    
    debugPrint(
        'DEBUG: Setting alert type from $_alertType to $type');

    if (widget.editingRecord == null) {
      setState(() {
        _alertType = type;
      });
      return;
    }

    if (widget.editingRecord?.id == null) {
      debugPrint('DEBUG: No record ID for alert update');
      return;
    }

    setState(() {
      _isTogglingAlert = true;
    });

    try {
      final url =
          '$_apiBase/api/vehicle-closing/update-alert/${widget.editingRecord!.id}';
      debugPrint('DEBUG: Alert update URL: $url');
      debugPrint('DEBUG: Alert update body: ${jsonEncode({
            'alert_type': type
          })}');

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'alert_type': type}),
      );

      debugPrint('DEBUG: Alert update response status: ${response.statusCode}');
      debugPrint('DEBUG: Alert update response body: ${response.body}');

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['status'] == 'success') {
        setState(() {
          _alertType = result['data']['alert_type'] ?? "Normal";
        });

        _showAlert(
          'Success',
          'Alert type changed to ${result['data']['alert_type'] ?? "Normal"}',
          type: 'success',
        );
      } else {
        _showAlert('Error', result['message'] ?? 'Failed to update alert type');
      }
    } catch (error) {
      debugPrint('DEBUG: Error updating alert type: $error');
      _showAlert('Error', 'Error updating alert type: $error');
    } finally {
      setState(() {
        _isTogglingAlert = false;
      });
    }
  }

  // CREATE API - /vehicle-closing/create (Form Data) - FIXED
  Future<Map<String, dynamic>> _createRecord() async {
    try {
      final url = '$_apiBase/api/vehicle-closing/create';
      debugPrint('DEBUG: Create record URL: $url');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Parse user_id to get just the ID part (before underscore)
      String userId = _selectedUserId ?? '';
      if (userId.contains('_')) {
        userId = userId.split('_')[0];
      }

      // Log all form data before sending
      debugPrint('DEBUG: === FORM DATA TO SEND ===');
      debugPrint('DEBUG: vehicle_id: ${_vehicleId ?? "NULL"}');
      debugPrint('DEBUG: vehicle_number: ${_selectedVehicleNumber ?? "NULL"}');
      debugPrint('DEBUG: user_id: $userId');
      debugPrint('DEBUG: endkm: ${_endKmController.text}');
      debugPrint('DEBUG: remarks: ${_remarksController.text}');
      debugPrint('DEBUG: is_remarks: true');
      debugPrint('DEBUG: alert_type: $_alertType');
      debugPrint('DEBUG: === END FORM DATA ===');

      // Add text fields - FIXED: Added all required fields
      request.fields['vehicle_id'] = _vehicleId ?? '';
      request.fields['vehicle_number'] = _selectedVehicleNumber ?? '';
      request.fields['user_id'] = userId;
      request.fields['endkm'] = _endKmController.text;
      request.fields['remarks'] = _remarksController.text;
      request.fields['is_remarks'] = 'true';
      request.fields['alert_type'] = _alertType;

      // Add photos
      debugPrint('DEBUG: Adding ${_selectedPhotos.length} photos');
      for (var photo in _selectedPhotos) {
        debugPrint('DEBUG: Adding photo: ${photo.path}');
        request.files.add(
          await http.MultipartFile.fromPath(
            'photos',
            photo.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      debugPrint('DEBUG: Sending create request...');
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('DEBUG: Create response status: ${response.statusCode}');
      debugPrint('DEBUG: Create response body: $responseBody');

      return jsonDecode(responseBody);
    } catch (e) {
      debugPrint('DEBUG: Error in create record: $e');
      return {
        'status': 'error',
        'message': 'Failed to create record: $e',
      };
    }
  }

  // UPDATE API - /vehicle-closing/update/{id} (Form Data)
  Future<Map<String, dynamic>> _updateRecord() async {
    try {
      final url =
          '$_apiBase/api/vehicle-closing/update/${widget.editingRecord!.id}';
      debugPrint('DEBUG: Update record URL: $url');

      var request = http.MultipartRequest('PUT', Uri.parse(url));

      // Parse user_id to get just the ID part (before underscore)
      String userId = _selectedUserId ?? '';
      if (userId.contains('_')) {
        userId = userId.split('_')[0];
      }

      request.fields['vehicle_id'] = _vehicleId ?? '';
      request.fields['vehicle_number'] = _selectedVehicleNumber ?? '';
      request.fields['user_id'] = userId;
      request.fields['endkm'] = _endKmController.text;
      request.fields['remarks'] = _remarksController.text;
      request.fields['is_remarks'] = 'true';
      request.fields['alert_type'] = _alertType;

      // Add photos if new ones are selected
      debugPrint('DEBUG: Adding ${_selectedPhotos.length} photos for update');
      for (var photo in _selectedPhotos) {
        debugPrint('DEBUG: Adding photo for update: ${photo.path}');
        request.files.add(
          await http.MultipartFile.fromPath(
            'photos',
            photo.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      debugPrint('DEBUG: Sending update request...');
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('DEBUG: Update response status: ${response.statusCode}');
      debugPrint('DEBUG: Update response body: $responseBody');

      return jsonDecode(responseBody);
    } catch (e) {
      debugPrint('DEBUG: Error in update record: $e');
      return {
        'status': 'error',
        'message': 'Failed to update record: $e',
      };
    }
  }

  Future<void> _submitForm() async {
    debugPrint('DEBUG: Submitting form...');

    if (!_formKey.currentState!.validate()) {
      debugPrint('DEBUG: Form validation failed');
      return;
    }

    if (widget.editingRecord == null && _selectedPhotos.isEmpty) {
      debugPrint('DEBUG: No photos selected for new record');
      _showAlert(
        'Error',
        'At least one photo/document is required for new records',
      );
      return;
    }

    if (_selectedVehicleNumber == null || _selectedVehicleNumber!.isEmpty) {
      debugPrint('DEBUG: No vehicle number selected');
      _showAlert('Error', 'Please select a vehicle number');
      return;
    }

    if (_selectedUserId == null || _selectedUserId!.isEmpty) {
      debugPrint('DEBUG: No user selected');
      _showAlert('Error', 'Please select a user');
      return;
    }

    if (_endKmController.text.isEmpty) {
      debugPrint('DEBUG: No end KM entered');
      _showAlert('Error', 'Please enter end kilometer');
      return;
    }

    // Validate vehicle ID exists
    if (_vehicleId == null || _vehicleId!.isEmpty) {
      debugPrint('DEBUG: No vehicle ID found');
      _showAlert(
          'Error', 'Vehicle ID is required. Please select a valid vehicle.');
      return;
    }

    debugPrint('DEBUG: All validations passed');
    debugPrint('DEBUG: Vehicle ID: $_vehicleId');
    debugPrint('DEBUG: Vehicle Number: $_selectedVehicleNumber');
    debugPrint('DEBUG: User ID: $_selectedUserId');
    debugPrint('DEBUG: End KM: ${_endKmController.text}');
    debugPrint('DEBUG: Alert Type: $_alertType');
    debugPrint('DEBUG: Photos count: ${_selectedPhotos.length}');

    setState(() {
      _isSubmitting = true;
    });

    try {
      Map<String, dynamic> result;

      if (widget.editingRecord != null) {
        // UPDATE existing record
        debugPrint(
            'DEBUG: Updating existing record with ID: ${widget.editingRecord!.id}');
        result = await _updateRecord();

        debugPrint('DEBUG: Update result: $result');

        if (result['status'] == 'success') {
          debugPrint('DEBUG: Update successful');

          // Show success snackbar for update
          _showSuccessSnackbar(
              result['message'] ?? 'Record updated successfully!');

          widget.onSave?.call();

          // Wait a bit for user to see the message, then go back
          await Future.delayed(Duration(milliseconds: 1500));

          // Navigate back
          _navigateBack();
        } else {
          debugPrint('DEBUG: Update failed: ${result['message']}');
          _showAlert('Error', result['message'] ?? 'Failed to update record');
        }
      } else {
        // CREATE new record
        debugPrint('DEBUG: Creating new record');
        result = await _createRecord();

        debugPrint('DEBUG: Create result: $result');

        if (result['status'] == 'success') {
          debugPrint('DEBUG: Create successful - 201 Created');

          // Show success snackbar for creation
          _showSuccessSnackbar(
              result['message'] ?? 'Vehicle closing saved successfully!');

          widget.onSave?.call();

          // Wait a bit for user to see the message, then go back
          await Future.delayed(Duration(milliseconds: 1500));

          // Navigate back
          _navigateBack();
        } else {
          debugPrint('DEBUG: Create failed: ${result['message']}');
          _showAlert('Error', result['message'] ?? 'Failed to create record');
        }
      }
    } catch (error) {
      debugPrint('DEBUG: Submission error: $error');

      // Show error snackbar
      _showErrorSnackbar('Submission failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      debugPrint('DEBUG: Form submission completed');
    }
  }

  // Helper method to show success snackbar
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Helper method to show error snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Helper method to navigate back
  void _navigateBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Map<String, dynamic>? get _selectedVehicle {
    if (_selectedVehicleNumber == null) return null;
    try {
      return _vehicles.firstWhere(
        (v) => v['vehicle_number'] == _selectedVehicleNumber,
      );
    } catch (e) {
      return null;
    }
  }

  String get _selectedUserDisplay {
    if (_selectedUserId == null) return '';
    final parts = _selectedUserId!.split('_');
    return parts.length > 1 ? parts[1] : _selectedUserId!;
  }

  String get _selectedUserIdDisplay {
    if (_selectedUserId == null) return '';
    final parts = _selectedUserId!.split('_');
    return parts.isNotEmpty ? parts[0] : _selectedUserId!;
  }

  Color _getAlertTypeColor(String type) {
    switch (type) {
      case "Normal":
        return Colors.green;
      case "Priority":
        return Colors.amber;
      case "Risk":
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String _getStatusDescription(String type) {
    switch (type) {
      case "Normal":
        return "Normal status - No issues reported";
      case "Priority":
        return "Priority status - Requires follow-up";
      case "Risk":
        return "Risk status - Requires immediate attention";
      default:
        return "Normal status - No issues reported";
    }
  }

  IconData _getStatusIcon(String type) {
    switch (type) {
      case "Normal":
        return Icons.check_circle;
      case "Priority":
        return Icons.warning;
      case "Risk":
        return Icons.error;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.editingRecord != null;
    debugPrint('DEBUG: Building UI - Edit mode: $isEditMode');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.secondary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isEditMode
                              ? 'Edit Vehicle Closing'
                              : 'Vehicle Closing',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          isEditMode
                              ? 'Update vehicle closing record'
                              : 'Create vehicle closing record',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[100],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        widget.onBack != null ? () => widget.onBack!() : null,
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: _loadingData && !isEditMode
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.secondary),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading vehicle and user data...',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Form Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditMode
                                        ? 'Edit Vehicle Closing Details'
                                        : 'Vehicle Closing Details',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                  SizedBox(height: 16),

                                  // Vehicle Number Dropdown
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Vehicle Number *',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedVehicleNumber,
                                        items: [
                                          DropdownMenuItem(
                                            value: null,
                                            child:
                                                Text('Select Vehicle Number'),
                                          ),
                                          ..._vehicles.map((vehicle) {
                                            return DropdownMenuItem(
                                              value: vehicle['vehicle_number']
                                                  ?.toString(),
                                              child: Text(
                                                '${vehicle['vehicle_number']} ${vehicle['vehicle_type'] != null ? '(${vehicle['vehicle_type']})' : ''}',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }),
                                        ],
                                        onChanged: (isEditMode &&
                                                widget.editingRecord
                                                        ?.vehicleNumber !=
                                                    null)
                                            ? null
                                            : (value) {
                                                debugPrint(
                                                    'DEBUG: Vehicle selected: $value');
                                                setState(() {
                                                  _selectedVehicleNumber =
                                                      value;
                                                  // Find and set vehicle_id when vehicle is selected
                                                  final selected =
                                                      _vehicles.firstWhere(
                                                    (v) =>
                                                        v['vehicle_number'] ==
                                                        value,
                                                    orElse: () => {},
                                                  );
                                                  _vehicleId =
                                                      selected['vehicle_id']
                                                          ?.toString();
                                                  debugPrint(
                                                      'DEBUG: Set vehicle_id to: $_vehicleId');

                                                  // Debug: Print the selected vehicle data
                                                  debugPrint(
                                                      'DEBUG: Selected vehicle data: $selected');

                                                  // Try alternative field names if vehicle_id is null
                                                  if (_vehicleId == null ||
                                                      _vehicleId!.isEmpty) {
                                                    debugPrint(
                                                        'DEBUG: Checking alternative field names for vehicle ID');
                                                    _vehicleId = selected['_id']
                                                            ?.toString() ??
                                                        selected['id']
                                                            ?.toString() ??
                                                        selected['vehicleId']
                                                            ?.toString() ??
                                                        '';
                                                    debugPrint(
                                                        'DEBUG: Alternative vehicle_id found: $_vehicleId');
                                                  }
                                                });
                                              },
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          errorStyle: TextStyle(fontSize: 11),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Vehicle number is required';
                                          }
                                          return null;
                                        },
                                      ),

                                      if (_vehicles.isEmpty && !_loadingData)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'No vehicles available. Please check the API connection.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.red[500],
                                            ),
                                          ),
                                        ),

                                      // Vehicle Details
                                      if (_selectedVehicle != null &&
                                          _selectedVehicle!.isNotEmpty)
                                        Container(
                                          margin: EdgeInsets.only(top: 8),
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: Colors.grey[200]!),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'Vehicle ID: ${_selectedVehicle!['vehicle_id'] ?? 'N/A'}',
                                                      style: TextStyle(
                                                          fontSize: 11),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      'Type: ${_selectedVehicle!['vehicle_type'] ?? 'N/A'}',
                                                      style: TextStyle(
                                                          fontSize: 11),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'Fuel Type: ${_selectedVehicle!['fuel_type'] != null ? (_selectedVehicle!['fuel_type'] is List ? (_selectedVehicle!['fuel_type'] as List).join(', ') : _selectedVehicle!['fuel_type'].toString()) : 'N/A'}',
                                                      style: TextStyle(
                                                          fontSize: 11),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      'Color Code: ${_selectedVehicle!['booking_color_code'] ?? 'N/A'}',
                                                      style: TextStyle(
                                                          fontSize: 11),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),

                                  SizedBox(height: 16),

                                  // User Dropdown
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'User *',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedUserId,
                                        items: [
                                          DropdownMenuItem(
                                            value: null,
                                            child: Text('Select User'),
                                          ),
                                          ..._users.map((user) {
                                            final parts = user.split('_');
                                            final userId = parts[0];
                                            final userName = parts.length > 1
                                                ? parts[1]
                                                : '';
                                            return DropdownMenuItem(
                                              value: user,
                                              child:
                                                  Text('$userName ($userId)'),
                                            );
                                          }),
                                        ],
                                        onChanged: (isEditMode &&
                                                widget.editingRecord?.userId !=
                                                    null)
                                            ? null
                                            : (value) {
                                                debugPrint(
                                                    'DEBUG: User selected: $value');
                                                setState(() {
                                                  _selectedUserId = value;
                                                });
                                              },
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          errorStyle: TextStyle(fontSize: 11),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'User is required';
                                          }
                                          return null;
                                        },
                                      ),

                                      if (_users.isEmpty && !_loadingData)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'No users available. Please check the API connection.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.red[500],
                                            ),
                                          ),
                                        ),

                                      // User Details
                                      if (_selectedUserId != null &&
                                          _selectedUserId!.isNotEmpty)
                                        Container(
                                          margin: EdgeInsets.only(top: 8),
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: Colors.grey[200]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'User ID: $_selectedUserIdDisplay',
                                                style: TextStyle(fontSize: 11),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'Full Name: $_selectedUserDisplay',
                                                style: TextStyle(fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),

                                  SizedBox(height: 16),

                                  // End KM
                                  TextFormField(
                                    controller: _endKmController,
                                    decoration: InputDecoration(
                                      labelText: 'End KM *',
                                      border: OutlineInputBorder(),
                                      hintText:
                                          'Enter end kilometer (e.g., 15000)',
                                      errorStyle: TextStyle(fontSize: 11),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'End KM is required';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Enter a valid number';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 16),

                                  // Remarks
                                  TextFormField(
                                    controller: _remarksController,
                                    decoration: InputDecoration(
                                      labelText: 'Remarks',
                                      border: OutlineInputBorder(),
                                      hintText:
                                          'Enter remarks (e.g., Vehicle returned in good condition)',
                                      alignLabelWithHint: true,
                                    ),
                                    maxLines: 3,
                                  ),

                                  SizedBox(height: 16),

                                  // Alert Type Selection
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Alert Status *',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        _getStatusDescription(_alertType),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          _buildRadioOption("Normal", Colors.green),
                                          SizedBox(width: 8),
                                          _buildRadioOption("Priority", Colors.amber),
                                          SizedBox(width: 8),
                                          _buildRadioOption("Risk", Colors.red),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _getAlertTypeColor(_alertType)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color:
                                                _getAlertTypeColor(_alertType)
                                                    .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _getStatusIcon(_alertType),
                                              color: _getAlertTypeColor(
                                                  _alertType),
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Current Status: $_alertType',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: _getAlertTypeColor(
                                                    _alertType),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_isTogglingAlert)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          AppTheme.secondary),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Updating alert status...',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),

                                  SizedBox(height: 16),

                                  // Photos Upload
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Upload Photos/Documents ${!isEditMode ? '* (Required - at least one)' : '(Optional)'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),

                                      SizedBox(height: 8),

                                      ElevatedButton(
                                        onPressed:
                                            _isSubmitting || _isTogglingAlert
                                                ? null
                                                : _pickImages,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[50],
                                          foregroundColor: Colors.grey[700],
                                          side: BorderSide(
                                              color: Colors.grey[300]!),
                                          minimumSize:
                                              Size(double.infinity, 48),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.camera_alt),
                                            SizedBox(width: 8),
                                            Text('Select Photos'),
                                          ],
                                        ),
                                      ),

                                      SizedBox(height: 4),

                                      Text(
                                        isEditMode
                                            ? 'Select files to update existing ones (optional)'
                                            : 'Select one or more files. Allowed formats: JPG, JPEG, PNG, PDF, GIF, BMP, WEBP',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),

                                      // Existing photos for edit mode
                                      if (isEditMode &&
                                          widget
                                              .editingRecord!.photos.isNotEmpty)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 16),
                                            Text(
                                              'Current Photos/Documents (${widget.editingRecord!.photos.length}):',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: widget
                                                  .editingRecord!.photos
                                                  .asMap()
                                                  .entries
                                                  .map((entry) {
                                                final index = entry.key;
                                                final photoUrl = entry.value;

                                                return InkWell(
                                                  onTap: () {
                                                    _openFile(photoUrl);
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      'Document ${index + 1}',
                                                      style: TextStyle(
                                                          color: Colors.blue),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),

                                        // Selected photos
                                        if (_selectedPhotos.isNotEmpty)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 16),
                                              Text(
                                                'New Files (${_selectedPhotos.length}):',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              GridView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 3,
                                                  crossAxisSpacing: 8,
                                                  mainAxisSpacing: 8,
                                                ),
                                                itemCount:
                                                    _selectedPhotos.length,
                                                itemBuilder: (context, index) {
                                                  return Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                        child: Image.file(
                                                          _selectedPhotos[index],
                                                          fit: BoxFit.cover,
                                                          width: double.infinity,
                                                          height: double.infinity,
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 4,
                                                        right: 4,
                                                        child: GestureDetector(
                                                          onTap: () =>
                                                              _removePhoto(index),
                                                          child: Container(
                                                            padding:
                                                                EdgeInsets.all(2),
                                                            decoration: BoxDecoration(
                                                              color: Colors.black54,
                                                              shape: BoxShape.circle,
                                                            ),
                                                            child: Icon(
                                                              Icons.close,
                                                              size: 16,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    
                                    SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              
              // Bottom Buttons
              if (!_loadingData || isEditMode)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting || _isTogglingAlert
                              ? null
                              : _navigateBack,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting || _isTogglingAlert
                              ? null
                              : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isEditMode
                                      ? 'Update Closing'
                                      : 'Create Closing',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
  }

  Widget _buildRadioOption(String label, Color color) {
    final isSelected = _alertType == label;
    return Expanded(
      child: GestureDetector(
        onTap: _isSubmitting || _isTogglingAlert
            ? null
            : () => _setAlertType(label),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 16,
                color: isSelected ? color : Colors.grey[500],
              ),
              SizedBox(width: 6),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? color : Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected) ...[
                      SizedBox(width: 4),
                      Icon(Icons.check, size: 12, color: color),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // File viewing methods
  Future<void> _openFile(String url) async {
    final cleanedUrl = url.trim();
    final uri = Uri.parse(cleanedUrl);
    final fileExtension = uri.path.split('.').last.toLowerCase();
    final isImage =
        ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileExtension);
    final isPdf = fileExtension == 'pdf';

    if (isImage) {
      _showImageDialog(cleanedUrl);
    } else if (isPdf) {
      // Show options dialog for PDFs (including the new View in-app option)
      _showPdfOptionsDialog(cleanedUrl);
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (!mounted) return;
        _showUrlDialog(cleanedUrl);
      }
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppTheme.secondary,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error,
                              color: Colors.white, size: 50),
                          const SizedBox(height: 10),
                          const Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              if (await canLaunchUrl(Uri.parse(imageUrl))) {
                                await launchUrl(
                                  Uri.parse(imageUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            child: const Text('Open in Browser'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.copy, color: Colors.white, size: 24),
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: imageUrl));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Image URL copied to clipboard'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfOptionsDialog(String pdfUrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PDF Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.remove_red_eye, color: Colors.blue),
                ),
                title: const Text('View PDF'),
                onTap: () async {
                  final viewerUrl =
                      'https://docs.google.com/viewer?url=${Uri.encodeComponent(pdfUrl)}&embedded=true';
                  final uri = Uri.parse(viewerUrl);
                  if (await canLaunchUrl(uri)) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await launchUrl(
                      uri,
                      mode: LaunchMode.inAppWebView,
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.open_in_browser,
                      color: Color(0xFF14ADD6)),
                ),
                title: const Text('Open in Browser'),
                onTap: () async {
                  final uri = Uri.parse(pdfUrl);
                  if (await canLaunchUrl(uri)) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy, color: Color(0xFF10B981)),
                ),
                title: const Text('Copy URL'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: pdfUrl));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF URL copied to clipboard'),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Document'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}
