// lib/screens/maintenance/modal/special_maintenance_modal.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/special_maintenance_provider.dart';
import '../../../models/special_maintenance_model.dart';
import '../../../core/constants/app_constants.dart';

class SpecialMaintenanceModal extends StatefulWidget {
  final SpecialMaintenanceRecord? editingRecord;
  final VoidCallback? onRefresh;

  const SpecialMaintenanceModal({
    super.key,
    this.editingRecord,
    this.onRefresh,
  });

  @override
  State<SpecialMaintenanceModal> createState() =>
      _SpecialMaintenanceModalState();
}

class _SpecialMaintenanceModalState extends State<SpecialMaintenanceModal> {
  final _formKey = GlobalKey<FormState>();
  final SpecialMaintenanceProvider _provider = SpecialMaintenanceProvider();
  final ImagePicker _picker = ImagePicker();

  // Form fields
  String _vehicleNumber = '';
  String _vehicleType = 'Car';
  String _vehicleId = '';
  String _maintenanceType = 'Battery';
  DateTime _date = DateTime.now();
  DateTime? _dateOfReturn;
  String _userName = '';
  String _userId = '';
  double _cost = 0.0;

  // Battery specific
  String _siNo = '';
  DateTime? _warrantyDate;
  String _remarks = '';

  // Tyre specific
  int _km = 0;
  int _dueKm = 0;

  // Wheel Balancing specific
  String _serviceCenter = '';

  // File upload
  List<String> _billUpload = []; // For existing URLs from API
  final List<File> _newFiles = []; // For newly picked files

  // Loading states
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isUploadingFiles = false;

  // Dropdown data
  List<Map<String, dynamic>> _vehicles = [];
  List<String> _users = [];

  // Maintenance types
  final List<Map<String, String>> _maintenanceTypes = [
    {'id': 'Battery', 'label': 'Battery', 'apiType': 'battery'},
    {
      'id': 'Wheel Balancing',
      'label': 'Wheel Balancing',
      'apiType': 'wheel-balancing'
    },
    {'id': 'Tyre', 'label': 'Tyre', 'apiType': 'tyre'},
  ];

  // Vehicle types
  final List<String> _vehicleTypes = ['Car', 'Truck', 'Bike', 'Van'];

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    _initializeForm();
  }

  Future<void> _loadDropdownData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await _provider.loadDropdownData();

      if (mounted) {
        setState(() {
          _users = _provider.users;
          _vehicles = _provider.vehicles;
        });
      }
    } catch (e) {
      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dropdown data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeForm() {
    if (widget.editingRecord != null) {
      final record = widget.editingRecord!;

      setState(() {
        _vehicleNumber = record.vehicleNumber;
        _vehicleType = record.vehicleType;
        _vehicleId = record.vehicleId;
        _maintenanceType = record.displayMaintenanceType;
        _userName = record.userName;
        _userId = record.userId;
        _date = record.serviceDate ?? DateTime.now();

        // Set type-specific data
        if (record.battery != null) {
          _siNo = record.battery!.batteryNumber;
          _warrantyDate = record.battery!.warrantyDate;
          _cost = record.battery!.cost;
          _remarks = record.battery!.remarks;
          _billUpload = record.battery!.billUpload;
          _dateOfReturn = record.battery!.dateOfReturn;
          _km = record.battery!.km;
          _serviceCenter = record.battery!.serviceCenter;
        } else if (record.tyre != null) {
          _km = record.tyre!.km;
          _dueKm = record.tyre!.dueKm ?? 0;
          _cost = record.tyre!.cost;
          _remarks = record.tyre!.remarks;
          _billUpload = record.tyre!.billUpload;
          _dateOfReturn = record.tyre!.dateOfReturn;
          _serviceCenter = record.tyre!.serviceCenter;
        } else if (record.wheelBalancing != null) {
          _km = record.wheelBalancing!.km;
          _dueKm = record.wheelBalancing!.dueKm ?? 0;
          _cost = record.wheelBalancing!.cost;
          _serviceCenter = record.wheelBalancing!.serviceCenter;
          _billUpload = record.wheelBalancing!.billUpload;
          _dateOfReturn = record.wheelBalancing!.dateOfReturn;
          _remarks = record.wheelBalancing!.remarks;
        }
      });
    } else {
      // Set default values for new record
      setState(() {
        _warrantyDate = DateTime.now().add(const Duration(days: 365));
        _dateOfReturn = DateTime.now().add(const Duration(days: 3));
      });
    }
  }

  Future<void> _pickFiles() async {
    // Show options for camera or gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Source'),
        content: const Text('Choose where to pick images from'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (source == null || !mounted) return;

    try {
      if (source == ImageSource.camera) {
        // Pick single image from camera
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        if (image != null && mounted) {
          setState(() {
            _newFiles.add(File(image.path));
          });
        }
      } else {
        // Pick multiple images from gallery
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        if (images.isNotEmpty && mounted) {
          setState(() {
            _newFiles.addAll(images.map((file) => File(file.path)));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to get file extension
  String _getFileExtension(String path) {
    final parts = path.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return 'jpg'; // Default extension
  }

  // Upload files to server and get URLs
  Future<List<String>> _uploadFiles() async {
    if (_newFiles.isEmpty) return _billUpload;

    setState(() => _isUploadingFiles = true);

    try {
      final List<String> uploadedUrls = [];

      for (final file in _newFiles) {
        try {
          // Get auth token
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(AppConstants.tokenKey) ?? '';

          if (token.isEmpty) {
            throw Exception(
                'Authentication token not found. Please login again.');
          }

          // Create multipart request for your backend
          final baseUrl = AppConstants.rootUrl;
          final uri = Uri.parse('$baseUrl/api/upload/bill');

          // Create request
          final request = http.MultipartRequest('POST', uri);

          // Add headers
          request.headers['Authorization'] = 'Bearer $token';

          // Add file
          final fileStream = http.ByteStream(file.openRead());
          final fileLength = await file.length();

          // Generate filename like: TN01AB1234_billupload_1769153472197.jpg
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final extension = _getFileExtension(file.path);
          final filename = '${_vehicleNumber}_billupload_$timestamp.$extension';

          final multipartFile = http.MultipartFile(
            'bill', // Field name from your API
            fileStream,
            fileLength,
            filename: filename,
          );

          request.files.add(multipartFile);

          // Add vehicle number as form field if required
          if (_vehicleNumber.isNotEmpty) {
            request.fields['vehicle_number'] = _vehicleNumber;
          }

          // Send request
          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          debugPrint('File upload response: ${response.statusCode}');
          debugPrint('Response body: ${response.body}');

          if (!mounted) return [];

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);

            if (responseData['status'] == 'success') {
              // Extract URL from response - check different possible response formats
              String? fileUrl;

              // Try different possible response formats
              if (responseData['fileUrl'] != null) {
                fileUrl = responseData['fileUrl'];
              } else if (responseData['url'] != null) {
                fileUrl = responseData['url'];
              } else if (responseData['data'] != null &&
                  responseData['data'] is Map) {
                fileUrl = responseData['data']['url'];
              } else if (responseData['message'] != null &&
                  responseData['message'].toString().contains('http')) {
                // Sometimes the URL is in the message
                fileUrl = responseData['message'];
              }

              // If no URL found in response, construct it based on your pattern
              if (fileUrl == null || fileUrl.isEmpty) {
                fileUrl =
                    '$baseUrl/storage/$_vehicleNumber/billupload/$filename';
              }

              uploadedUrls.add(fileUrl);
              debugPrint('File uploaded successfully: $fileUrl');
            } else {
              throw Exception('Upload failed: ${responseData['message']}');
            }
          } else {
            throw Exception(
                'Upload failed with status: ${response.statusCode} - ${response.body}');
          }
        } catch (e) {
          debugPrint('Error uploading file ${file.path}: $e');
          // Show error for this specific file
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload ${file.path.split('/').last}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          // Continue with other files
        }
      }

      // Return existing URLs + newly uploaded URLs
      return [..._billUpload, ...uploadedUrls];
    } catch (e) {
      debugPrint('File upload error: $e');

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Return existing URLs only if upload fails
      return _billUpload;
    } finally {
      if (mounted) {
        setState(() => _isUploadingFiles = false);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      // Upload files first
      List<String> uploadedFiles = await _uploadFiles();
      if (!mounted) return;

      // Get vehicle details
      final selectedVehicle = _vehicles.firstWhere(
        (v) => v['vehicle_number'] == _vehicleNumber,
        orElse: () => {},
      );

      // Prepare common form data
      Map<String, dynamic> formData = {
        'vehicle_id': selectedVehicle['vehicle_id']?.toString() ?? _vehicleId,
        'vehicle_number': _vehicleNumber,
        'user_id': _userId,
        'user_name': _userName,
        'date': DateFormat('yyyy-MM-dd').format(_date),
        'cost': _cost,
        'type_of_vehicle': _vehicleType,
        'bill_upload': uploadedFiles, // Use uploaded file URLs
        'is_returned': false, // Always false for new records
      };

      // Add date_of_return if available
      if (_dateOfReturn != null) {
        formData['date_of_return'] =
            DateFormat('yyyy-MM-dd').format(_dateOfReturn!);
      }

      // Add type-specific fields
      if (_maintenanceType == 'Battery') {
        formData['service_center'] = _serviceCenter;
        formData['remarks'] = _remarks;
        formData['km'] = _km;
        formData['si_no'] = _siNo;
        if (_warrantyDate != null) {
          formData['warranty_date'] =
              DateFormat('yyyy-MM-dd').format(_warrantyDate!);
        }
      } else if (_maintenanceType == 'Tyre') {
        formData['service_center'] = _serviceCenter;
        formData['km'] = _km;
        formData['due_km'] = _dueKm;
        formData['remarks'] = _remarks;
      } else if (_maintenanceType == 'Wheel Balancing') {
        formData['service_center'] = _serviceCenter;
        formData['km'] = _km;
        formData['due_km'] = _dueKm;
        formData['remarks'] = _remarks;
      }

      Map<String, dynamic> result;

      if (widget.editingRecord != null) {
        // Update existing record
        if (_maintenanceType == 'Battery') {
          result = await _provider.updateBatteryMaintenance(
              widget.editingRecord!.id, formData);
        } else if (_maintenanceType == 'Tyre') {
          result = await _provider.updateTyreMaintenance(
              widget.editingRecord!.id, formData);
        } else {
          result = await _provider.updateWheelBalancing(
              widget.editingRecord!.id, formData);
        }
      } else {
        // Create new record
        if (_maintenanceType == 'Battery') {
          result = await _provider.addBatteryMaintenance(formData);
        } else if (_maintenanceType == 'Tyre') {
          result = await _provider.addTyreMaintenance(formData);
        } else {
          result = await _provider.addWheelBalancing(formData);
        }
      }

      // Show API message in snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                (widget.editingRecord != null
                    ? 'Record updated'
                    : 'Record created')),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Close the modal and refresh - FIXED: Don't call provider method, just close modal
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e, stackTrace) {
      debugPrint('Error details: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildVehicleDropdown() {
    // Ensure unique vehicles by vehicle_number
    final uniqueVehiclesMap = <String, Map<String, dynamic>>{};
    for (var v in _vehicles) {
      final vNumber = v['vehicle_number']?.toString();
      if (vNumber != null && vNumber.isNotEmpty) {
        uniqueVehiclesMap[vNumber] = v;
      }
    }
    final uniqueVehicles = uniqueVehiclesMap.values.toList();
    if (_vehicleNumber.isNotEmpty && !uniqueVehiclesMap.containsKey(_vehicleNumber)) {
      uniqueVehicles.add({'vehicle_number': _vehicleNumber});
    }

    return DropdownButtonFormField<String>(
      initialValue: _vehicleNumber.isNotEmpty ? _vehicleNumber : null,
      decoration: const InputDecoration(
        labelText: 'Vehicle Number *',
        border: OutlineInputBorder(),
        hintText: 'Select vehicle',
      ),
      items: uniqueVehicles.map<DropdownMenuItem<String>>((vehicle) {
        return DropdownMenuItem<String>(
          value: vehicle['vehicle_number'],
          child: Text(vehicle['vehicle_number'] ?? ''),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _vehicleNumber = value);
        }
      },
      validator: (value) => value == null ? 'Please select a vehicle' : null,
    );
  }

  Widget _buildUserDropdown() {
    // Ensure unique users and include current value if not present
    final uniqueUsers = _users.toSet().toList();
    if (_userName.isNotEmpty && !uniqueUsers.contains(_userName)) {
      uniqueUsers.add(_userName);
    }

    return DropdownButtonFormField<String>(
      initialValue: _userName.isNotEmpty ? _userName : null,
      decoration: const InputDecoration(
        labelText: 'User Name *',
        border: OutlineInputBorder(),
        hintText: 'Select user',
      ),
      items: uniqueUsers.map<DropdownMenuItem<String>>((user) {
        return DropdownMenuItem<String>(
          value: user,
          child: Text(user),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _userName = value;
            _userId = value; // For now, use name as ID
          });
        }
      },
      validator: (value) => value == null ? 'Please select a user' : null,
    );
  }

  Widget _buildVehicleTypeDropdown() {
    final uniqueVehicleTypes = _vehicleTypes.toSet().toList();
    if (_vehicleType.isNotEmpty && !uniqueVehicleTypes.contains(_vehicleType)) {
      uniqueVehicleTypes.add(_vehicleType);
    }

    return DropdownButtonFormField<String>(
      initialValue: _vehicleType,
      decoration: const InputDecoration(
        labelText: 'Vehicle Type *',
        border: OutlineInputBorder(),
        hintText: 'Select vehicle type',
      ),
      items: uniqueVehicleTypes.map<DropdownMenuItem<String>>((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _vehicleType = value);
        }
      },
      validator: (value) => value == null ? 'Please select vehicle type' : null,
    );
  }

  Widget _buildMaintenanceTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _maintenanceType,
      decoration: const InputDecoration(
        labelText: 'Maintenance Type *',
        border: OutlineInputBorder(),
        hintText: 'Select maintenance type',
      ),
      items: _maintenanceTypes.map<DropdownMenuItem<String>>((type) {
        return DropdownMenuItem<String>(
          value: type['id'],
          child: Text(type['label']!),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _maintenanceType = value);
        }
      },
      validator: (value) =>
          value == null ? 'Please select maintenance type' : null,
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate,
      ValueChanged<DateTime?> onDateSelected) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null && mounted) {
          onDateSelected(pickedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '$label *',
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          selectedDate != null
              ? DateFormat('dd MMM yyyy').format(selectedDate)
              : 'Select date',
          style: TextStyle(
              color: selectedDate != null ? Colors.black : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildBatteryFields() {
    return Column(
      children: [
        TextFormField(
          initialValue: _siNo,
          decoration: const InputDecoration(
            labelText: 'Battery Number',
            border: OutlineInputBorder(),
            hintText: 'Enter battery number',
          ),
          onChanged: (value) => setState(() => _siNo = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _remarks,
          decoration: const InputDecoration(
            labelText: 'Remarks',
            border: OutlineInputBorder(),
            hintText: 'Enter remarks',
          ),
          onChanged: (value) => setState(() => _remarks = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _km == 0 ? '' : _km.toString(),
          decoration: const InputDecoration(
            labelText: 'KM *',
            border: OutlineInputBorder(),
            hintText: 'Enter current KM',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => setState(() => _km = int.tryParse(value) ?? 0),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter KM';
            if (int.tryParse(value!) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDatePicker('Warranty Date', _warrantyDate, (date) {
          if (mounted) setState(() => _warrantyDate = date);
        }),
        const SizedBox(height: 16),
        _buildDatePicker('Date of Return', _dateOfReturn, (date) {
          if (mounted) setState(() => _dateOfReturn = date);
        }),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _serviceCenter,
          decoration: const InputDecoration(
            labelText: 'Service Center',
            border: OutlineInputBorder(),
            hintText: 'Enter service center name',
          ),
          onChanged: (value) => setState(() => _serviceCenter = value),
        ),
      ],
    );
  }

  Widget _buildTyreFields() {
    return Column(
      children: [
        TextFormField(
          initialValue: _km == 0 ? '' : _km.toString(),
          decoration: const InputDecoration(
            labelText: 'KM *',
            border: OutlineInputBorder(),
            hintText: 'Enter current KM',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => setState(() => _km = int.tryParse(value) ?? 0),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter KM';
            if (int.tryParse(value!) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _dueKm == 0 ? '' : _dueKm.toString(),
          decoration: const InputDecoration(
            labelText: 'Due KM',
            border: OutlineInputBorder(),
            hintText: 'Enter due KM',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) =>
              setState(() => _dueKm = int.tryParse(value) ?? 0),
        ),
        const SizedBox(height: 16),
        _buildDatePicker('Date of Return', _dateOfReturn, (date) {
          if (mounted) setState(() => _dateOfReturn = date);
        }),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _serviceCenter,
          decoration: const InputDecoration(
            labelText: 'Service Center',
            border: OutlineInputBorder(),
            hintText: 'Enter service center name',
          ),
          onChanged: (value) => setState(() => _serviceCenter = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _remarks,
          decoration: const InputDecoration(
            labelText: 'Remarks',
            border: OutlineInputBorder(),
            hintText: 'Enter remarks',
          ),
          onChanged: (value) => setState(() => _remarks = value),
        ),
      ],
    );
  }

  Widget _buildWheelBalancingFields() {
    return Column(
      children: [
        TextFormField(
          initialValue: _km == 0 ? '' : _km.toString(),
          decoration: const InputDecoration(
            labelText: 'KM *',
            border: OutlineInputBorder(),
            hintText: 'Enter current KM',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => setState(() => _km = int.tryParse(value) ?? 0),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter KM';
            if (int.tryParse(value!) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _dueKm == 0 ? '' : _dueKm.toString(),
          decoration: const InputDecoration(
            labelText: 'Due KM',
            border: OutlineInputBorder(),
            hintText: 'Enter due KM',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) =>
              setState(() => _dueKm = int.tryParse(value) ?? 0),
        ),
        const SizedBox(height: 16),
        _buildDatePicker('Date of Return', _dateOfReturn, (date) {
          if (mounted) setState(() => _dateOfReturn = date);
        }),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _serviceCenter,
          decoration: const InputDecoration(
            labelText: 'Service Center *',
            border: OutlineInputBorder(),
            hintText: 'Enter service center name',
          ),
          onChanged: (value) => setState(() => _serviceCenter = value),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter service center' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _remarks,
          decoration: const InputDecoration(
            labelText: 'Remarks',
            border: OutlineInputBorder(),
            hintText: 'Enter remarks',
          ),
          onChanged: (value) => setState(() => _remarks = value),
        ),
      ],
    );
  }

  Widget _buildCostField() {
    return TextFormField(
      initialValue: _cost == 0 ? '' : _cost.toStringAsFixed(2),
      decoration: const InputDecoration(
        labelText: 'Cost (₹) *',
        border: OutlineInputBorder(),
        prefixText: '₹ ',
        hintText: '0.00',
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) =>
          setState(() => _cost = double.tryParse(value) ?? 0.0),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Please enter cost';
        if (double.tryParse(value!) == null) {
          return 'Please enter a valid amount';
        }
        return null;
      },
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Bill',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploadingFiles ? null : _pickFiles,
                icon: const Icon(Icons.upload_file),
                label: const Text('Select Files'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_newFiles.isNotEmpty)
              ElevatedButton(
                onPressed: _isUploadingFiles
                    ? null
                    : () {
                        setState(() => _newFiles.clear());
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                child: const Icon(Icons.clear_all, color: Colors.white),
              ),
          ],
        ),

        if (_isUploadingFiles)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),

        const SizedBox(height: 16),

        // Show selected files
        if (_billUpload.isNotEmpty || _newFiles.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected files: ${_billUpload.length + _newFiles.length}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              // Existing files from API
              ..._billUpload.map((url) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: _getFileIcon(url),
                      title: Text(
                        _getFileName(url),
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Existing file',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.open_in_new, size: 20),
                            onPressed: () {
                              _viewFile(url);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red, size: 20),
                            onPressed: () {
                              if (mounted) {
                                setState(() => _billUpload.remove(url));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  )),

              // New files
              ..._newFiles.asMap().entries.map((entry) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file,
                          color: AppTheme.secondary),
                      title: Text(
                        entry.value.path.split('/').last,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'New file (${_formatFileSize(entry.value)})',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.red, size: 20),
                        onPressed: () {
                          if (mounted) {
                            setState(() => _newFiles.removeAt(entry.key));
                          }
                        },
                      ),
                    ),
                  )),
            ],
          ),
      ],
    );
  }

  void _viewFile(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getFileName(url)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (url.toLowerCase().contains('.jpg') ||
                    url.toLowerCase().contains('.jpeg') ||
                    url.toLowerCase().contains('.png'))
                  Image.network(url, fit: BoxFit.contain)
                else
                  const Text('Preview not available for this file type'),
                const SizedBox(height: 16),
                Text('URL: $url', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Icon _getFileIcon(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('.pdf')) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (lowerUrl.contains('.jpg') ||
        lowerUrl.contains('.jpeg') ||
        lowerUrl.contains('.png')) {
      return const Icon(Icons.image, color: Colors.green);
    } else {
      return const Icon(Icons.insert_drive_file, color: AppTheme.secondary);
    }
  }

  String _getFileName(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : url;
    } catch (e) {
      return url;
    }
  }

  String _formatFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown size';
    }
  }

  Future<void> _deleteRecord() async {
    if (widget.editingRecord == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete this ${_maintenanceType.toLowerCase()} maintenance record for $_vehicleNumber?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSubmitting = true);

      try {
        final result = await _provider.deleteSpecialMaintenance(
            widget.editingRecord!.id, _maintenanceType);

        if (result['success'] && mounted) {
          Navigator.pop(context, true);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Record deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Delete failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingRecord != null
            ? 'Edit Special Maintenance'
            : 'Add Special Maintenance'),
        actions: [
          if (widget.editingRecord != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isSubmitting ? null : _deleteRecord,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Basic Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Basic Information',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),

                            // Maintenance Type Dropdown
                            _buildMaintenanceTypeDropdown(),
                            const SizedBox(height: 16),

                            // User Name Dropdown
                            _buildUserDropdown(),
                            const SizedBox(height: 16),

                            // Vehicle Number Dropdown
                            _buildVehicleDropdown(),
                            const SizedBox(height: 16),

                            // Vehicle Type Dropdown
                            _buildVehicleTypeDropdown(),
                            const SizedBox(height: 16),

                            // Date
                            _buildDatePicker('Date', _date, (date) {
                              if (mounted && date != null) {
                                setState(() => _date = date);
                              }
                            }),
                            const SizedBox(height: 16),

                            // Cost
                            _buildCostField(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Type-specific Details
                    if (_maintenanceType == 'Battery')
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Battery Details',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              _buildBatteryFields(),
                            ],
                          ),
                        ),
                      )
                    else if (_maintenanceType == 'Tyre')
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tyre Details',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              _buildTyreFields(),
                            ],
                          ),
                        ),
                      )
                    else if (_maintenanceType == 'Wheel Balancing')
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Wheel Balancing Details',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              _buildWheelBalancingFields(),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // File Upload Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildFileUploadSection(),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: (_isSubmitting || _isUploadingFiles)
                          ? null
                          : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting || _isUploadingFiles
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              widget.editingRecord != null
                                  ? 'Update Record'
                                  : 'Save Record',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                    ),

                    const SizedBox(height: 8),

                    // Cancel Button
                    OutlinedButton(
                      onPressed: (_isSubmitting || _isUploadingFiles)
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
