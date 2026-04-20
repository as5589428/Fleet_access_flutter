import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/vehicle_start_model.dart';
import '../../services/vehicle_start_service.dart';

class VehicleStartFormScreen extends StatefulWidget {
  final VehicleStartModel? startEntry;
  final bool isEditing;

  const VehicleStartFormScreen({
    super.key,
    this.startEntry,
    this.isEditing = false,
  });

  @override
  State<VehicleStartFormScreen> createState() => _VehicleStartFormScreenState();
}

class _VehicleStartFormScreenState extends State<VehicleStartFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleStartService = VehicleStartService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isSubmitting = false;

  // Dropdown data
  List<VehicleDropdownModel> _vehicles = [];
  VehicleDropdownModel? _selectedVehicle;

  // Form Field Controllers
  final TextEditingController _startKmController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  String _alertType = 'Normal';

  // Edit KM logic
  bool _isEditingKm = false;
  String _originalKm = '';

  // File variables
  final List<File> _startPhotos = [];
  File? _editPhoto;
  File? _mapUpload;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
    if (widget.isEditing && widget.startEntry != null) {
      _loadExistingData();
    }
  }

  @override
  void dispose() {
    _startKmController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdownData() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await _vehicleStartService.getVehiclesForDropdown();
      setState(() {
        _vehicles = vehicles;
        if (widget.isEditing && widget.startEntry != null) {
          _selectedVehicle = _vehicles
                  .where((v) =>
                      v.vehicleNumber == widget.startEntry!.vehicleNumber)
                  .firstOrNull ??
              VehicleDropdownModel(
                  vehicleNumber: widget.startEntry!.vehicleNumber);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load vehicles: $e');
    }
  }

  void _loadExistingData() {
    final entry = widget.startEntry!;
    _startKmController.text = entry.startKm ?? '';
    _remarksController.text = entry.remarks ?? '';
    _alertType = entry.alertType ?? 'Normal';
    _originalKm = entry.startKm ?? '';
    _isEditingKm = entry.isEdit ?? false;

    // We can't easily populate files from URLs for editing in a simple File input setup
    // without downloading them first, so we'll leave them empty for updates or show labels.
    // In a real app, you'd show a network image preview and clear the `File` variable.
  }

  Future<void> _pickImages() async {
    if (_startPhotos.length >= 5) {
      _showErrorSnackBar('Maximum 5 photos allowed.');
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (images.isNotEmpty) {
        setState(() {
          int availableSlots = 5 - _startPhotos.length;
          _startPhotos.addAll(
              images.take(availableSlots).map((xfile) => File(xfile.path)));
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking images: $e');
    }
  }

  Future<void> _pickSingleImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          if (type == 'edit') {
            _editPhoto = File(image.path);
          } else if (type == 'map') {
            _mapUpload = File(image.path);
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicle == null) {
      _showErrorSnackBar('Please select a vehicle');
      return;
    }
    if (_startPhotos.isEmpty && !widget.isEditing) {
      _showErrorSnackBar('Please upload at least 1 start photo');
      return;
    }
    if (_isEditingKm && _editPhoto == null && !widget.isEditing) {
      // Allow passing if editing existing entry perhaps
      _showErrorSnackBar('Please upload an edit photo when modifying start KM');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final model = VehicleStartModel(
        vehicleId: _selectedVehicle?.id,
        vehicleNumber: _selectedVehicle?.vehicleNumber,
        startKm: _isEditingKm ? _startKmController.text : _originalKm,
        remarks: _remarksController.text,
        alertType: _alertType,
        isEdit: _isEditingKm,
        updatedStartKm: _isEditingKm ? _startKmController.text : null,
      );

      if (widget.isEditing && widget.startEntry != null) {
        await _vehicleStartService.updateStartEntry(
          id: widget.startEntry!.id!,
          startModel: model,
          newStartPhotos: _startPhotos.isNotEmpty ? _startPhotos : null,
          newEditPhoto: _editPhoto,
          newMapUpload: _mapUpload,
        );
        _showSuccessSnackBar('Vehicle Start Entry updated successfully');
      } else {
        await _vehicleStartService.createStartEntry(
          startModel: model,
          startPhotos: _startPhotos,
          editPhoto: _editPhoto,
          mapUpload: _mapUpload,
        );
        _showSuccessSnackBar('Vehicle Start Entry created successfully');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4A4494), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<DropdownMenuItem<dynamic>> items,
    required dynamic value,
    required Function(dynamic) onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151))),
        const SizedBox(height: 8),
        DropdownButtonFormField<dynamic>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF4A4494), width: 2)),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (v) => v == null ? 'This field is required' : null,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
    bool readOnly = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151))),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF4A4494), width: 2)),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
            widget.isEditing ? 'Edit Vehicle Start' : 'Vehicle Start Form',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF4A4494),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A4494)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                              'Basic Details', Icons.directions_car),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              bool isWide = constraints.maxWidth > 600;
                              return Flex(
                                direction:
                                    isWide ? Axis.horizontal : Axis.vertical,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: isWide ? 1 : 0,
                                    child: _buildDropdownField(
                                      label: 'Vehicle Number *',
                                      value: _selectedVehicle,
                                      hint: 'Select Vehicle',
                                      items: _vehicles.map((v) {
                                        return DropdownMenuItem(
                                          value: v,
                                          child: Text(v.vehicleNumber ?? ''),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedVehicle =
                                              value as VehicleDropdownModel;
                                          _originalKm =
                                              _selectedVehicle?.currentKm ?? '';
                                          _startKmController.text = _originalKm;
                                          _isEditingKm = false;
                                        });
                                      },
                                    ),
                                  ),
                                  if (isWide)
                                    const SizedBox(width: 16)
                                  else
                                    const SizedBox(height: 16),
                                  Expanded(
                                    flex: isWide ? 1 : 0,
                                    child: _buildTextField(
                                      label: 'Start KM',
                                      controller: _startKmController,
                                      isRequired: true,
                                      readOnly: !_isEditingKm,
                                      keyboardType: TextInputType.number,
                                      suffix: IconButton(
                                        icon: Icon(
                                            _isEditingKm
                                                ? Icons.check
                                                : Icons.edit,
                                            color: _isEditingKm
                                                ? Colors.green
                                                : const Color(0xFF4A4494)),
                                        onPressed: () {
                                          if (_selectedVehicle == null) return;
                                          setState(() {
                                            if (_isEditingKm) {
                                              // Save Action handled by checking form
                                            }
                                            _isEditingKm = !_isEditingKm;
                                            if (!_isEditingKm) {
                                              // Revert to original if cancelled
                                              _startKmController.text =
                                                  _originalKm;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(builder: (context, constraints) {
                            bool isWide = constraints.maxWidth > 600;
                            return Flex(
                              direction:
                                  isWide ? Axis.horizontal : Axis.vertical,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: isWide ? 1 : 0,
                                  child: _buildDropdownField(
                                    label: 'Alert Type',
                                    value: _alertType,
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'Normal',
                                          child: Text('Normal')),
                                      DropdownMenuItem(
                                          value: 'Priority',
                                          child: Text('Priority')),
                                      DropdownMenuItem(
                                          value: 'Risk', child: Text('Risk')),
                                    ],
                                    onChanged: (val) => setState(
                                        () => _alertType = val.toString()),
                                  ),
                                ),
                                if (isWide)
                                  const SizedBox(width: 16)
                                else
                                  const SizedBox(height: 16),
                                Expanded(
                                  flex: isWide ? 1 : 0,
                                  child: _buildTextField(
                                    label: 'Remarks',
                                    controller: _remarksController,
                                    hint: 'Optional notes',
                                  ),
                                ),
                              ],
                            );
                          })
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // File Upload Section
                    Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Required Photos & Attachments',
                                Icons.camera_alt),
                            const SizedBox(height: 16),
                            // Start Photos
                            Text('Start Photos * (Max: 5)',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151))),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ..._startPhotos.map((file) => Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            image: DecorationImage(
                                                image: FileImage(file),
                                                fit: BoxFit.cover),
                                          ),
                                        ),
                                        Positioned(
                                          right: -10,
                                          top: -10,
                                          child: IconButton(
                                            icon: const Icon(Icons.cancel,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _startPhotos.remove(file);
                                              });
                                            },
                                          ),
                                        )
                                      ],
                                    )),
                                if (_startPhotos.length < 5)
                                  InkWell(
                                    onTap: _pickImages,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey.shade300,
                                            style: BorderStyle.none),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo,
                                              color: Colors.grey),
                                          SizedBox(height: 4),
                                          Text('Add',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Edit Photo and Map Upload Layout
                            LayoutBuilder(builder: (context, constraints) {
                              bool isWide = constraints.maxWidth > 600;
                              return Flex(
                                direction:
                                    isWide ? Axis.horizontal : Axis.vertical,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isEditingKm) ...[
                                    Expanded(
                                      flex: isWide ? 1 : 0,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Edit Photo *',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF374151))),
                                          const SizedBox(height: 8),
                                          InkWell(
                                            onTap: () =>
                                                _pickSingleImage('edit'),
                                            child: Container(
                                              height: 120,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: _editPhoto != null
                                                    ? null
                                                    : Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: _editPhoto != null
                                                        ? Colors.transparent
                                                        : Colors.blue.shade200,
                                                    style: BorderStyle.solid),
                                                image: _editPhoto != null
                                                    ? DecorationImage(
                                                        image: FileImage(
                                                            _editPhoto!),
                                                        fit: BoxFit.cover)
                                                    : null,
                                              ),
                                              child: _editPhoto == null
                                                  ? const Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                            Icons.edit_document,
                                                            color: Colors.blue,
                                                            size: 32),
                                                        SizedBox(height: 8),
                                                        Text(
                                                            'Tap to upload Edit Photo',
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.blue,
                                                                fontSize: 13)),
                                                      ],
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isWide)
                                      const SizedBox(width: 16)
                                    else
                                      const SizedBox(height: 16),
                                  ],
                                  Expanded(
                                    flex: isWide ? 1 : 0,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Map Upload (Optional)',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF374151))),
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: () => _pickSingleImage('map'),
                                          child: Container(
                                            height: 120,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: _mapUpload != null
                                                  ? null
                                                  : Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: _mapUpload != null
                                                      ? Colors.transparent
                                                      : Colors.grey.shade300,
                                                  style: BorderStyle.solid),
                                              image: _mapUpload != null
                                                  ? DecorationImage(
                                                      image: FileImage(
                                                          _mapUpload!),
                                                      fit: BoxFit.cover)
                                                  : null,
                                            ),
                                            child: _mapUpload == null
                                                ? const Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.map,
                                                          color: Colors.grey,
                                                          size: 32),
                                                      SizedBox(height: 8),
                                                      Text(
                                                          'Tap to upload Map Screenshot',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                              fontSize: 13)),
                                                    ],
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            })
                          ],
                        )),

                    const SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    color: Color(0xFF374151),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A4494),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(
                                    widget.isEditing
                                        ? 'Update Entry'
                                        : 'Save Entry',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
