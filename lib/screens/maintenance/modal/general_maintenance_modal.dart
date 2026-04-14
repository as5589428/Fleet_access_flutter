import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/maintenance_provider.dart';

class GeneralMaintenanceModal extends StatefulWidget {
  final GeneralMaintenanceRecord? editingRecord;
  final Function()? onRefresh;

  const GeneralMaintenanceModal({
    super.key,
    this.editingRecord,
    this.onRefresh,
  });

  @override
  State<GeneralMaintenanceModal> createState() =>
      _GeneralMaintenanceModalState();
}

class _GeneralMaintenanceModalState extends State<GeneralMaintenanceModal> {
  // Maintenance types with display names and backend values
  List<Map<String, String>> maintenanceTypes = [];
  bool _loadingTypes = false;

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Hardcoded Admin user
  final String _hardcodedAdminName = 'Admin';
  final String _hardcodedAdminId = 'U004';

  @override
  void initState() {
    super.initState();
    _fetchMaintenanceTypes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Future.microtask(() {
      if (!mounted) {
        return;
      }

      final provider =
          Provider.of<GeneralMaintenanceProvider>(context, listen: false);

      provider.loadDropdownData().then((_) {
        if (!mounted) {
          return;
        }

        if (widget.editingRecord != null) {
          provider.setFormDataFromRecord(widget.editingRecord!);
        } else {
          provider.resetForm();
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchMaintenanceTypes() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingTypes = true;
    });

    try {
      final provider =
          Provider.of<GeneralMaintenanceProvider>(context, listen: false);
      final types = await provider.getMaintenanceTypes();

      if (mounted) {
        setState(() {
          maintenanceTypes = types.map((type) {
            String display = '';
            switch (type) {
              case 'general':
                display = 'General Maintenance';
                break;
              case 'battery':
                display = 'Battery';
                break;
              case 'wheel_balancing':
                display = 'Wheel Balancing';
                break;
              case 'tyre':
                display = 'Tyre';
                break;
              default:
                display = type;
            }
            return {'display': display, 'value': type};
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          maintenanceTypes = [
            {'display': 'General Maintenance', 'value': 'general'},
            {'display': 'Battery', 'value': 'battery'},
            {'display': 'Wheel Balancing', 'value': 'wheel_balancing'},
            {'display': 'Tyre', 'value': 'tyre'},
          ];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingTypes = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });

        if (!mounted) return;

        final provider =
            Provider.of<GeneralMaintenanceProvider>(context, listen: false);
        List<String> filePaths =
            _selectedImages.map((file) => file.path).toList();
        provider.updateFormData('bill_upload', filePaths);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });

    final provider =
        Provider.of<GeneralMaintenanceProvider>(context, listen: false);
    List<String> filePaths = _selectedImages.map((file) => file.path).toList();
    provider.updateFormData('bill_upload', filePaths);
  }

  String _getDisplayType(String? type) {
    if (type == null || type.isEmpty) {
      return '';
    }

    final typeMap = {
      "general": "General Maintenance",
      "wheel_balancing": "Wheel Balancing",
      "tyre": "Tyre",
      "battery": "Battery",
      "batery": "Battery"
    };

    return typeMap[type] ?? type;
  }

  // Type-specific return fields (matching React)
  Widget _renderReturnedFields(GeneralMaintenanceProvider provider) {
    final maintenanceType = provider.formData['maintenance_type'];
    final formData = provider.formData;
    final errors = provider.formErrors;

    switch (maintenanceType) {
      case "general":
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "General Maintenance Return Details",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: "Next Service KM",
                          icon: Icons.speed,
                          value: formData['next_service_km'],
                          error: errors['next_service_km'],
                          onChanged: (value) {
                            provider.updateFormData('next_service_km', value);
                          },
                          hintText: "e.g., 50000",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          label: "Next Service Date",
                          icon: Icons.event_available,
                          value: formData['next_service_date'] as DateTime?,
                          error: errors['next_service_date'],
                          onChanged: (value) {
                            provider.updateFormData('next_service_date', value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextAreaField(
                    label: "Remarks",
                    icon: Icons.note_add,
                    value: formData['remarks'],
                    error: errors['remarks'],
                    onChanged: (value) {
                      provider.updateFormData('remarks', value);
                    },
                    hintText: "Enter any remarks for the returned item",
                  ),
                ],
              ),
            ),
          ],
        );

      case "battery":
      case "batery":
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Battery Return Details",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: "SI Number",
                          icon: Icons.numbers,
                          value: formData['si_no'],
                          error: errors['si_no'],
                          onChanged: (value) {
                            provider.updateFormData('si_no', value);
                          },
                          hintText: "Enter SI number",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          label: "Warranty Date",
                          icon: Icons.event,
                          value: formData['warranty_date'] as DateTime?,
                          error: errors['warranty_date'],
                          onChanged: (value) {
                            provider.updateFormData('warranty_date', value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextAreaField(
                    label: "Remarks",
                    icon: Icons.note_add,
                    value: formData['remarks'],
                    error: errors['remarks'],
                    onChanged: (value) {
                      provider.updateFormData('remarks', value);
                    },
                    hintText: "Enter any remarks for the returned battery",
                  ),
                ],
              ),
            ),
          ],
        );

      case "wheel_balancing":
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Wheel Balancing Return Details",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: "Due KM",
                    icon: Icons.speed,
                    value: formData['due_km'],
                    error: errors['due_km'],
                    onChanged: (value) {
                      provider.updateFormData('due_km', value);
                    },
                    hintText: "e.g., 50000",
                  ),
                  const SizedBox(height: 16),
                  _buildTextAreaField(
                    label: "Remarks",
                    icon: Icons.note_add,
                    value: formData['remarks'],
                    error: errors['remarks'],
                    onChanged: (value) {
                      provider.updateFormData('remarks', value);
                    },
                    hintText:
                        "Enter any remarks for the returned wheel balancing",
                  ),
                ],
              ),
            ),
          ],
        );

      case "tyre":
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tyre Return Details",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: "Due KM",
                    icon: Icons.speed,
                    value: formData['due_km'],
                    error: errors['due_km'],
                    onChanged: (value) {
                      provider.updateFormData('due_km', value);
                    },
                    hintText: "e.g., 50000",
                  ),
                  const SizedBox(height: 16),
                  _buildTextAreaField(
                    label: "Remarks",
                    icon: Icons.note_add,
                    value: formData['remarks'],
                    error: errors['remarks'],
                    onChanged: (value) {
                      provider.updateFormData('remarks', value);
                    },
                    hintText: "Enter any remarks for the returned tyre",
                  ),
                ],
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBillUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              "Upload Return Bill *",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.blue[300]!),
                      ),
                      icon: Icon(Icons.camera_alt, color: Colors.blue[700]),
                      label: Text(
                        "Camera",
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.blue[300]!),
                      ),
                      icon: Icon(Icons.photo_library, color: Colors.blue[700]),
                      label: Text(
                        "Gallery",
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Bill upload is mandatory when marking as returned",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  "Uploaded Files (${_selectedImages.length})",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
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
              if (_selectedImages.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "No bills uploaded",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _getUserInfoAndSetId(
      GeneralMaintenanceProvider provider, String userName) async {
    try {
      final userInfo = await provider.getUserInfo(userName);
      if (mounted) {
        provider.updateFormData('user_id', userInfo['user_id']);
      }
    } catch (e) {
      debugPrint('Error getting user info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            Container(
              height: 70,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.editingRecord != null
                                ? "Edit Maintenance"
                                : "New Maintenance",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.editingRecord != null
                                ? "Update existing record"
                                : "Add new maintenance record",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (widget.editingRecord != null)
                    Icon(
                      Icons.edit_note,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 28,
                    ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Consumer<GeneralMaintenanceProvider>(
                builder: (context, provider, child) {
                  final formData = provider.formData;
                  final errors = provider.formErrors;
                  final isReturned = formData['is_returned'] ?? false;
                  final maintenanceType =
                      formData['maintenance_type'] ?? 'general';

                  if (provider.dropdownLoading &&
                      provider.vehicleNumbers.isEmpty &&
                      provider.users.isEmpty &&
                      widget.editingRecord == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.secondary),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Loading dropdown data...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vehicle Information Section
                        _buildSectionHeader(
                          icon: Icons.directions_car_outlined,
                          title: "Vehicle Information",
                          subtitle: "Select vehicle for maintenance",
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (widget.editingRecord != null) ...[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.confirmation_number,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Vehicle Number *",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 14),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[50],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            formData['vehicle_number'] ?? '',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: provider.getVehicleColor(
                                                  formData['vehicle_number'] ??
                                                      ''),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Fixed',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                _buildVehicleDropdownField(
                                  context: context,
                                  label: "Vehicle Number",
                                  icon: Icons.confirmation_number,
                                  value: formData['vehicle_number'],
                                  error: errors['vehicle_number'],
                                  onChanged: (value) async {
                                    provider.updateFormData(
                                        'vehicle_number', value);
                                    if (value != null &&
                                        value.isNotEmpty &&
                                        widget.editingRecord == null) {
                                      final vehicleInfo =
                                          await provider.getVehicleInfo(value);
                                      if (mounted) {
                                        provider.updateFormData('vehicle_id',
                                            vehicleInfo['vehicle_id']);
                                        provider.updateFormData('vehicle_type',
                                            vehicleInfo['vehicle_type']);
                                        provider.updateFormData(
                                            'type_of_vehicle',
                                            vehicleInfo['vehicle_type']);
                                      }
                                    }
                                  },
                                ),
                              ],
                              if (formData['vehicle_id'] != null &&
                                  formData['vehicle_id'].toString().isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.green[100]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.directions_car,
                                          size: 16, color: Colors.green[700]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Vehicle ID: ${formData['vehicle_id']}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (formData['vehicle_type'] !=
                                                    null &&
                                                formData['vehicle_type']
                                                    .toString()
                                                    .isNotEmpty)
                                              Text(
                                                "Vehicle Type: ${formData['vehicle_type']}",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.green[600],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // User Information Section
                        _buildSectionHeader(
                          icon: Icons.person_outline,
                          title: "User Information",
                          subtitle: "Select user for this maintenance",
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildUserDropdownField(
                                context: context,
                                label: "User Name",
                                icon: Icons.person,
                                value: formData['user_name'],
                                error: errors['user_name'],
                                onChanged: (value) {
                                  provider.updateFormData('user_name', value);
                                  if (value == _hardcodedAdminName &&
                                      widget.editingRecord == null) {
                                    provider.updateFormData(
                                        'user_id', _hardcodedAdminId);
                                  } else if (value != null &&
                                      value.isNotEmpty &&
                                      widget.editingRecord == null) {
                                    _getUserInfoAndSetId(provider, value);
                                  }
                                },
                              ),
                              if (formData['user_id'] != null &&
                                  formData['user_id'].toString().isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.blue[100]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.badge,
                                          size: 16, color: Colors.blue[700]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "User ID: ${formData['user_id']}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Maintenance Type Section
                        _buildSectionHeader(
                          icon: Icons.build_outlined,
                          title: "Maintenance Details",
                          subtitle: "Select maintenance category",
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (widget.editingRecord != null) ...[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.build_circle_outlined,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Maintenance Type *",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 14),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[50],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _getDisplayType(
                                                formData['maintenance_type']),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            'Fixed',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                _buildMaintenanceTypeDropdownField(
                                  label: "Maintenance Type",
                                  icon: Icons.build_circle_outlined,
                                  value: formData['maintenance_type'],
                                  items: maintenanceTypes,
                                  error: errors['maintenance_type'],
                                  onChanged: (value) {
                                    provider.updateFormData(
                                        'maintenance_type', value);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Basic Information Section with Date and Date of Return
                        _buildSectionHeader(
                          icon: Icons.info_outline,
                          title: "Basic Information",
                          subtitle: "Enter basic maintenance details",
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWideScreen = constraints.maxWidth > 600;

                              if (isWideScreen) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildDateField(
                                        label: "Date",
                                        icon: Icons.calendar_today,
                                        value: formData['date'] as DateTime?,
                                        error: errors['date'],
                                        onChanged: (value) {
                                          provider.updateFormData(
                                              'date', value);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDateField(
                                        label: "Date of Return",
                                        icon: Icons.event_note,
                                        value: formData['date_of_return']
                                            as DateTime?,
                                        error: errors['date_of_return'],
                                        onChanged: (value) {
                                          provider.updateFormData(
                                              'date_of_return', value);
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildDateField(
                                      label: "Date",
                                      icon: Icons.calendar_today,
                                      value: formData['date'] as DateTime?,
                                      error: errors['date'],
                                      onChanged: (value) {
                                        provider.updateFormData('date', value);
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _buildDateField(
                                      label: "Date of Return",
                                      icon: Icons.event_note,
                                      value: formData['date_of_return']
                                          as DateTime?,
                                      error: errors['date_of_return'],
                                      onChanged: (value) {
                                        provider.updateFormData(
                                            'date_of_return', value);
                                      },
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Service Details Section
                        _buildSectionHeader(
                          icon: Icons.build,
                          title: "Service Details",
                          subtitle: "Enter service details",
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Service Center
                              _buildTextField(
                                label: "Service Center",
                                icon: Icons.location_on_outlined,
                                value: formData['service_center'],
                                error: errors['service_center'],
                                onChanged: (value) {
                                  provider.updateFormData(
                                      'service_center', value);
                                },
                                hintText: "Enter service center name",
                              ),

                              const SizedBox(height: 16),

                              // Cost and KM Reading in row
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWideScreen =
                                      constraints.maxWidth > 600;

                                  if (isWideScreen) {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            label: "Cost (₹)",
                                            icon: Icons.currency_rupee,
                                            value: formData['cost'],
                                            keyboardType: TextInputType.number,
                                            error: errors['cost'],
                                            onChanged: (value) {
                                              provider.updateFormData(
                                                  'cost', value);
                                            },
                                            hintText: "e.g., 2500",
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildTextField(
                                            label: "KM Reading",
                                            icon: Icons.speed,
                                            value: formData['km'],
                                            keyboardType: TextInputType.number,
                                            error: errors['km'],
                                            onChanged: (value) {
                                              provider.updateFormData(
                                                  'km', value);
                                            },
                                            hintText: "e.g., 45000",
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Column(
                                      children: [
                                        _buildTextField(
                                          label: "Cost (₹)",
                                          icon: Icons.currency_rupee,
                                          value: formData['cost'],
                                          keyboardType: TextInputType.number,
                                          error: errors['cost'],
                                          onChanged: (value) {
                                            provider.updateFormData(
                                                'cost', value);
                                          },
                                          hintText: "e.g., 2500",
                                        ),
                                        const SizedBox(height: 16),
                                        _buildTextField(
                                          label: "KM Reading",
                                          icon: Icons.speed,
                                          value: formData['km'],
                                          keyboardType: TextInputType.number,
                                          error: errors['km'],
                                          onChanged: (value) {
                                            provider.updateFormData(
                                                'km', value);
                                          },
                                          hintText: "e.g., 45000",
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),

                              // Service Reason - ONLY SHOW FOR GENERAL MAINTENANCE
                              if (maintenanceType == 'general' ||
                                  maintenanceType == 'general-maintenance') ...[
                                const SizedBox(height: 16),
                                _buildTextAreaField(
                                  label: "Service Reason",
                                  icon: Icons.receipt_long,
                                  value: formData['reason'],
                                  error: errors['reason'],
                                  onChanged: (value) {
                                    provider.updateFormData('reason', value);
                                  },
                                  hintText:
                                      "e.g., Oil Change, Brake Service, Regular Maintenance, etc.",
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Return Information Section
                        _buildSectionHeader(
                          icon: Icons.keyboard_return,
                          title: "Return Information",
                          subtitle:
                              "Vehicle return details (Bill upload required if returned)",
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Return Status Toggle
                              Container(
                                decoration: BoxDecoration(
                                  color: isReturned
                                      ? Colors.green[50]
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isReturned
                                        ? Colors.green[200]!
                                        : Colors.grey[200]!,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    provider.updateFormData(
                                        'is_returned', !isReturned);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isReturned
                                                ? Colors.green
                                                : Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isReturned
                                                ? Icons.check
                                                : Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isReturned
                                                    ? "Vehicle Returned"
                                                    : "Vehicle Not Returned",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isReturned
                                                      ? Colors.green[800]
                                                      : Colors.grey[800],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                isReturned
                                                    ? "Bill upload is required"
                                                    : "Mark as returned to upload bills",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isReturned
                                                      ? Colors.green[600]
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: isReturned
                                              ? Colors.green
                                              : Colors.grey,
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Show return fields only if is_returned is true
                              if (isReturned) ...[
                                const SizedBox(height: 20),

                                // Type-specific return fields
                                _renderReturnedFields(provider),

                                const SizedBox(height: 20),

                                // Bill Upload Section
                                _buildBillUploadSection(),
                              ],
                            ],
                          ),
                        ),

                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  side: BorderSide(
                                      color: Colors.grey[400]!, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: provider.isLoading
                                    ? null
                                    : () async {
                                        if (provider.validateForm()) {
                                          await _confirmAndSubmit(
                                              context, provider);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.secondary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 3,
                                  shadowColor:
                                      const Color(0xFF4A4494).withValues(alpha: 0.3),
                                ),
                                child: provider.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            widget.editingRecord != null
                                                ? Icons.update
                                                : Icons.save,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            widget.editingRecord != null
                                                ? "Update"
                                                : "Save",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
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

  // UI Helper Methods
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.secondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleDropdownField({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String? value,
    required String? error,
    required Function(String?) onChanged,
  }) {
    final provider =
        Provider.of<GeneralMaintenanceProvider>(context, listen: false);
    final items = provider.vehicleNumbers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              "$label *",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: error != null ? Colors.red : Colors.grey[300]!,
              width: error != null ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value?.isEmpty == true ? null : value,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              isDense: true,
              prefixIcon: Icon(icon, size: 18, color: Colors.grey[600]),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text(
                  "Select Vehicle Number",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
              ...items.map((vehicleNumber) {
                final vehicleInfo = provider.vehicleNumbersFullData.firstWhere(
                  (v) => v['vehicle_number'] == vehicleNumber,
                  orElse: () => {},
                );

                final vehicleId = vehicleInfo['vehicle_id'] ?? '';
                final textColor = provider.getVehicleColor(vehicleNumber);

                return DropdownMenuItem(
                  value: vehicleNumber,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vehicleNumber,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (vehicleId.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'ID: ${vehicleId.length > 8 ? '${vehicleId.substring(0, 8)}...' : vehicleId}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
            onChanged: onChanged,
            isExpanded: true,
            dropdownColor: Colors.white,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 12, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  error,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMaintenanceTypeDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<Map<String, String>> items,
    required String? error,
    required Function(String?) onChanged,
  }) {
    if (_loadingTypes) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                "$label *",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Loading maintenance types...",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    String? dropdownValue;
    if (value != null) {
      final matchingItem = items.firstWhere(
        (item) => item['value'] == value,
        orElse: () => {},
      );
      if (matchingItem.isNotEmpty) {
        dropdownValue = value;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              "$label *",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: error != null ? Colors.red : Colors.grey[300]!,
              width: error != null ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: dropdownValue,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              isDense: true,
              prefixIcon: Icon(icon, size: 18, color: Colors.grey[600]),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text(
                  "Select Maintenance Type",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
              ...items.map((type) {
                return DropdownMenuItem(
                  value: type['value'],
                  child: Text(
                    type['display']!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }),
            ],
            onChanged: onChanged,
            isExpanded: true,
            dropdownColor: Colors.white,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 12, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  error,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUserDropdownField({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String? value,
    required String? error,
    required Function(String?) onChanged,
  }) {
    final provider =
        Provider.of<GeneralMaintenanceProvider>(context, listen: false);

    final allUsers = [
      _hardcodedAdminName,
      ...provider.users.where((user) => user != _hardcodedAdminName)
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              "$label *",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: error != null ? Colors.red : Colors.grey[300]!,
              width: error != null ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value?.isEmpty == true ? null : value,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              isDense: true,
              prefixIcon: Icon(icon, size: 18, color: Colors.grey[600]),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text(
                  "Select User Name",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
              DropdownMenuItem(
                value: _hardcodedAdminName,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ADMIN',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _hardcodedAdminName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              ...allUsers
                  .where((user) => user != _hardcodedAdminName)
                  .map((user) {
                return DropdownMenuItem(
                  value: user,
                  child: Text(
                    user,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }),
            ],
            onChanged: onChanged,
            isExpanded: true,
            dropdownColor: Colors.white,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 12, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  error,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String? value,
    required String? error,
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              "$label *",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey[300]!,
                width: error != null ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey[300]!,
                width: error != null ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF14ADD6),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
            errorText: error,
            errorStyle: const TextStyle(fontSize: 11),
            prefixIcon: Icon(icon, size: 18, color: Colors.grey[600]),
            isDense: true,
            constraints: const BoxConstraints(
              minHeight: 44,
              maxHeight: 44,
            ),
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextAreaField({
    required String label,
    required IconData icon,
    required String? value,
    required String? error,
    String? hintText,
    required Function(String) onChanged,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              required ? "$label *" : label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          maxLines: 3,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey[300]!,
                width: error != null ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey[300]!,
                width: error != null ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF14ADD6),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
            errorText: error,
            errorStyle: const TextStyle(fontSize: 11),
            alignLabelWithHint: true,
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? value,
    required String? error,
    required Function(DateTime?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              "$label *",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppTheme.secondary,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.secondary,
                      ),
                    ),
                    dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              onChanged(pickedDate);
            }
          },
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(
                color: error != null ? Colors.red : Colors.grey[300]!,
                width: error != null ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value != null
                        ? DateFormat('dd MMM yyyy').format(value)
                        : "Select date",
                    style: TextStyle(
                      color: value != null ? Colors.black87 : Colors.grey[500],
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: error != null ? Colors.red : const Color(0xFF14ADD6),
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 12, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  error,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _confirmAndSubmit(
      BuildContext context, GeneralMaintenanceProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Icon(
              widget.editingRecord != null ? Icons.update : Icons.save,
              color: const Color(0xFF14ADD6),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              widget.editingRecord != null ? "Confirm Update" : "Confirm Save",
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          widget.editingRecord != null
              ? "Are you sure you want to update this maintenance record?"
              : "Are you sure you want to save this maintenance record?",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14ADD6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    widget.editingRecord != null ? "Update" : "Save",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      bool success;

      if (provider.formData['user_name'] == _hardcodedAdminName &&
          (provider.formData['user_id'] == null ||
              provider.formData['user_id'].toString().isEmpty)) {
        provider.updateFormData('user_id', _hardcodedAdminId);
      }

      if (widget.editingRecord != null) {
        success =
            await provider.updateGeneralMaintenance(widget.editingRecord!.id);
      } else {
        success = await provider.addGeneralMaintenance();
      }

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.editingRecord != null
                          ? "Maintenance record updated successfully!"
                          : "New maintenance record saved successfully!",
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );

          widget.onRefresh?.call();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        provider.apiError ??
                            'An error occurred. Please try again.',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    }
  }
}
