import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/fuel_provider.dart';
import '../../models/fuel_model.dart';
import '../../core/theme/app_theme.dart';

class AddFuelDialog extends StatefulWidget {
  final FuelEntry? initialData;
  const AddFuelDialog({super.key, this.initialData});

  @override
  State<AddFuelDialog> createState() => _AddFuelDialogState();
}

class _AddFuelDialogState extends State<AddFuelDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final List<String> _fuelTypes = ['Diesel', 'Petrol', 'CNG', 'Electric'];
  final List<String> _units = ["Litre", "Kg", "Kwh"];

  String? _selectedVehicleNumber;
  Vehicle? _selectedVehicle;
  late String _selectedFuelType;
  late String _selectedUnit;
  late TextEditingController _kmController;
  late TextEditingController _priceController;
  late TextEditingController _remarksController;
  File? _selectedBill;
  String? _billUrl;
  bool _isLoadingVehicles = false;

  @override
  void initState() {
    super.initState();
    _selectedFuelType = widget.initialData?.fuelType ?? 'Diesel';
    _selectedUnit = widget.initialData?.unit ?? 'Litre';
    _billUrl = widget.initialData?.billUrl;

    if (!_units.contains(_selectedUnit)) {
      _selectedUnit = _units.first;
    }
    if (!_fuelTypes.contains(_selectedFuelType)) {
      _selectedFuelType = _fuelTypes.first;
    }

    _kmController = TextEditingController(
        text: widget.initialData?.km.toStringAsFixed(2) ?? '');
    _priceController = TextEditingController(
        text: widget.initialData?.price.toStringAsFixed(2) ?? '');
    _remarksController =
        TextEditingController(text: widget.initialData?.remarks ?? '');
    _selectedVehicleNumber = widget.initialData?.vehicleNumber;

    // Try to find the vehicle in the list for edit mode
    if (_selectedVehicleNumber != null && widget.initialData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<FuelProvider>();
        final vehicle = provider.getVehicleByNumber(_selectedVehicleNumber!);
        if (vehicle != null) {
          setState(() {
            _selectedVehicle = vehicle;
          });
        }
      });
    }

    // Load vehicles when dialog opens for ADD mode
    if (widget.initialData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadVehicles();
      });
    }
  }

  Future<void> _loadVehicles() async {
    final provider = context.read<FuelProvider>();
    if (provider.vehicles.isEmpty && !provider.vehiclesLoading) {
      setState(() => _isLoadingVehicles = true);
      await provider.loadVehicles();
      setState(() => _isLoadingVehicles = false);
    }
  }

  void _onVehicleSelected(String? vehicleNumber) {
    if (vehicleNumber == null) return;

    final provider = context.read<FuelProvider>();
    final vehicle = provider.getVehicleByNumber(vehicleNumber);

    setState(() {
      _selectedVehicleNumber = vehicleNumber;
      _selectedVehicle = vehicle;

      // Auto-select fuel type if vehicle has fuel types defined
      if (vehicle != null && vehicle.fuelType.isNotEmpty) {
        _selectedFuelType = vehicle.fuelType.first;
      }
    });
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedBill = File(image.path);
        _billUrl = null;
      });
    }
  }

  Future<void> _captureImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedBill = File(image.path);
        _billUrl = null;
      });
    }
  }

  void _removeBill() {
    setState(() {
      _selectedBill = null;
      _billUrl = null;
    });
  }

  Widget _buildBillUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.receipt, color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Fuel Bill',
              style: TextStyle(
                color: AppTheme.neutral.withValues(alpha: 0.8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_billUrl != null && _selectedBill == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt, color: AppTheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Existing Bill',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to replace',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutral.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: AppTheme.danger, size: 20),
                  onPressed: _removeBill,
                ),
              ],
            ),
          ),
        if (_selectedBill != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt, color: AppTheme.success, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill Selected',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedBill!.path.split('/').last,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutral.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: AppTheme.danger, size: 20),
                  onPressed: _removeBill,
                ),
              ],
            ),
          ),
        if (_billUrl == null && _selectedBill == null)
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.neutral.withValues(alpha: 0.15)),
                  ),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _captureImageFromCamera,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Camera',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.neutral.withValues(alpha: 0.15)),
                  ),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _pickImageFromGallery,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            Icon(
                              Icons.photo_library,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gallery',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FuelProvider>();

    if (_selectedVehicleNumber == null || _selectedVehicleNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vehicle number'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // **IMPORTANT: Check if vehicle ID is valid**
    // The vehicle ID should be a proper ID, not just the vehicle number
    String vehicleId;
    if (_selectedVehicle != null && _selectedVehicle!.vehicleId.isNotEmpty) {
      vehicleId = _selectedVehicle!.vehicleId;
    } else {
      // Try to extract ID from vehicle number
      // This depends on your API - you might need to get the actual vehicle ID
      vehicleId = _selectedVehicleNumber!;
    }

    debugPrint('Selected Vehicle ID: $vehicleId');
    debugPrint('Selected Vehicle Number: $_selectedVehicleNumber');

    // Create FuelEntry - send ONLY fields that API expects
    final fuelEntry = FuelEntry(
      id: widget.initialData?.id,
      vehicleId: vehicleId, // Use the proper vehicle ID
      vehicleNumber: _selectedVehicleNumber!,
      fuelType: _selectedFuelType,
      km: double.parse(_kmController.text),
      price: double.parse(_priceController.text),
      unit: _selectedUnit,
      // Do NOT send remarks unless API supports it
      // remarks: _remarksController.text.trim().isNotEmpty
      //     ? _remarksController.text.trim()
      //     : null,
      // Do NOT send billUrl (it's for file upload, not string)
      // Do NOT send createdAt (API doesn't expect it)
      // Do NOT send added_by (API doesn't expect it)
    );

    // **Debug: Print what we're about to send**
    debugPrint('Fuel Entry to send: ${fuelEntry.toFormData()}');

    bool success;
    if (widget.initialData?.id != null) {
      success = await provider.updateFuelEntry(
        widget.initialData!.id!,
        fuelEntry,
        fuelBill: _selectedBill,
      );
    } else {
      success = await provider.addFuelEntry(
        fuelEntry,
        fuelBill: _selectedBill,
      );
    }

    if (success && provider.apiError == null) {
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialData != null
                ? 'Fuel entry updated successfully!'
                : 'Fuel entry added successfully!',
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (provider.apiError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.apiError}'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildVehicleField(BuildContext context, FuelProvider provider) {
    if (widget.initialData != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Vehicle Number',
                style: TextStyle(
                  color: AppTheme.neutral.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.neutral.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.neutral.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.directions_car,
                      color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedVehicleNumber ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      if (_selectedVehicle != null)
                        Text(
                          '${_selectedVehicle!.vehicleType} • ${_selectedVehicle!.fuelType.join(", ")}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.neutral.withValues(alpha: 0.6),
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
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Vehicle Number *',
                style: TextStyle(
                  color: AppTheme.neutral.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.neutral.withValues(alpha: 0.15)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedVehicleNumber,
                isExpanded: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  prefixIcon: Container(
                    margin: const EdgeInsets.only(left: 8, right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.directions_car,
                        color: AppTheme.primary, size: 20),
                  ),
                  suffixIcon: _isLoadingVehicles
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : provider.vehicles.isEmpty
                          ? IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: _loadVehicles,
                              tooltip: 'Reload vehicles',
                            )
                          : null,
                  filled: true,
                  fillColor: Colors.white,
                  constraints: const BoxConstraints(
                    minHeight: 56,
                  ),
                ),
                items: _buildVehicleDropdownItems(provider.vehicles),
                onChanged: _isLoadingVehicles ? null : _onVehicleSelected,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a vehicle number';
                  }
                  return null;
                },
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                icon: Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: const Icon(Icons.arrow_drop_down,
                      color: AppTheme.primary, size: 24),
                ),
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Select Vehicle Number',
                    style: TextStyle(
                      color: AppTheme.neutral.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  List<DropdownMenuItem<String>> _buildVehicleDropdownItems(
      List<Vehicle> vehicles) {
    final items = <DropdownMenuItem<String>>[];

    if (vehicles.isEmpty) {
      items.add(
        DropdownMenuItem<String>(
          value: null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'No vehicles available',
              style: TextStyle(
                color: AppTheme.neutral.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
      return items;
    }

    for (var vehicle in vehicles) {
      if (vehicle.vehicleNumber.isNotEmpty) {
        items.add(
          DropdownMenuItem<String>(
            value: vehicle.vehicleNumber,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.vehicleNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (vehicle.vehicleType.isNotEmpty ||
                      vehicle.fuelType.isNotEmpty)
                    const SizedBox(height: 4),
                  if (vehicle.vehicleType.isNotEmpty)
                    Text(
                      vehicle.vehicleType,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (vehicle.fuelType.isNotEmpty)
                    Text(
                      'Fuel: ${vehicle.fuelType.join(", ")}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return items;
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    IconData? icon,
    bool isRequired = true,
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                '$label${isRequired ? ' *' : ''}',
                style: TextStyle(
                  color: AppTheme.neutral.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(
            minHeight: 56,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppTheme.neutral.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppTheme.neutral.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.danger, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.danger, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              prefixIcon: icon != null
                  ? Container(
                      margin: const EdgeInsets.only(left: 8, right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: AppTheme.primary, size: 20),
                    )
                  : null,
              fillColor: Colors.white,
              filled: true,
              hintStyle: TextStyle(
                color: AppTheme.neutral.withValues(alpha: 0.5),
                fontSize: 16,
              ),
              isCollapsed: true,
            ),
            validator: validator,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    required String? Function(String?) validator,
    IconData? icon,
  }) {
    final uniqueItems = items.toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                '$label *',
                style: TextStyle(
                  color: AppTheme.neutral.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(
            minHeight: 56,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: value,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppTheme.neutral.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppTheme.neutral.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.danger, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.danger, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                prefixIcon: icon != null
                    ? Container(
                        margin: const EdgeInsets.only(left: 8, right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: AppTheme.primary, size: 20),
                      )
                    : null,
                fillColor: Colors.white,
                filled: true,
                constraints: const BoxConstraints(
                  minHeight: 56,
                ),
              ),
              items: uniqueItems.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
              validator: validator,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              icon: Container(
                margin: const EdgeInsets.only(right: 8),
                child: const Icon(Icons.arrow_drop_down,
                    color: AppTheme.primary, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FuelProvider>();
    final isEditMode = widget.initialData != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 400 ? 12 : 20,
        vertical: screenHeight * 0.02,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9,
          maxWidth: 500,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_gas_station,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditMode ? 'Edit Fuel Entry' : 'Add Fuel Entry',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close,
                            size: 20, color: Colors.white),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVehicleField(context, provider),
                      const SizedBox(height: 20),
                      _buildDropdownField(
                        label: 'Fuel Type',
                        value: _selectedFuelType,
                        items: _selectedVehicle?.fuelType.isNotEmpty == true
                            ? _selectedVehicle!.fuelType
                            : _fuelTypes,
                        onChanged: (value) =>
                            setState(() => _selectedFuelType = value),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select fuel type';
                          }
                          return null;
                        },
                        icon: Icons.local_gas_station,
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 400;
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Odometer (km)',
                                    controller: _kmController,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter odometer';
                                      }
                                      final km = double.tryParse(value);
                                      if (km == null || km <= 0) {
                                        return 'Enter valid number > 0';
                                      }
                                      return null;
                                    },
                                    keyboardType: TextInputType.number,
                                    icon: Icons.straighten,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Price (₹)',
                                    controller: _priceController,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter price';
                                      }
                                      final price = double.tryParse(value);
                                      if (price == null || price <= 0) {
                                        return 'Enter valid number > 0';
                                      }
                                      return null;
                                    },
                                    keyboardType: TextInputType.number,
                                    icon: Icons.currency_rupee,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextField(
                                  label: 'Odometer (km)',
                                  controller: _kmController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter odometer';
                                    }
                                    final km = double.tryParse(value);
                                    if (km == null || km <= 0) {
                                      return 'Enter valid number > 0';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,
                                  icon: Icons.straighten,
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  label: 'Price (₹)',
                                  controller: _priceController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter price';
                                    }
                                    final price = double.tryParse(value);
                                    if (price == null || price <= 0) {
                                      return 'Enter valid number > 0';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,
                                  icon: Icons.currency_rupee,
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildDropdownField(
                        label: 'Unit',
                        value: _selectedUnit,
                        items: _units,
                        onChanged: (value) =>
                            setState(() => _selectedUnit = value),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select unit';
                          }
                          return null;
                        },
                        icon: Icons.straighten,
                      ),
                      const SizedBox(height: 20),
                      _buildBillUploadSection(),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: 'Remarks',
                        controller: _remarksController,
                        validator: (value) => null,
                        keyboardType: TextInputType.multiline,
                        icon: Icons.note,
                        isRequired: false,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppTheme.neutral.withValues(alpha: 0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: provider.isLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.neutral,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.secondary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    provider.isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: provider.isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isEditMode
                                                ? Icons.check_circle
                                                : Icons.add_circle,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              isEditMode
                                                  ? 'Update'
                                                  : 'Add Entry',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
