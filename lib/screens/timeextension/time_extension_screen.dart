import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/time_extension_provider.dart';
import '../../core/theme/app_theme.dart';

class TimeExtensionScreen extends StatefulWidget {
  const TimeExtensionScreen({super.key});

  @override
  State<TimeExtensionScreen> createState() => _TimeExtensionScreenState();
}

class _TimeExtensionScreenState extends State<TimeExtensionScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _fromDate;
  DateTime? _toDate;
  Vehicle? _selectedVehicle;
  bool _isSubmitting = false;
  bool _isEditingFromDate = false;
  DateTime? _originalFromDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVehicles();
    });
  }

  Future<void> _loadVehicles() async {
    await context.read<TimeExtensionProvider>().fetchVehicles();
  }

  void _onVehicleSelected(Vehicle vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _originalFromDate = vehicle.currentBookingEnd;
      _fromDate = vehicle.currentBookingEnd;
      _toDate = null;
      _isEditingFromDate = false;
    });
  }

  Future<void> _selectFromDate(BuildContext context) async {
    if (_selectedVehicle == null && !_isEditingFromDate) {
      _showErrorSnackbar('Please select a vehicle first');
      return;
    }

    final initialDate = _fromDate ?? DateTime.now();
    final firstDate = _isEditingFromDate
        ? DateTime.now()
        : (_originalFromDate ?? DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (picked != null) {
      if (!context.mounted) return;
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_fromDate ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _fromDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          _toDate = null;
        });
      }
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    if (_fromDate == null) {
      _showErrorSnackbar('Please select From Date first');
      return;
    }

    final minDate = _fromDate!.add(Duration(days: 1));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? minDate,
      firstDate: minDate,
      lastDate: DateTime(DateTime.now().year + 2),
    );

    if (picked != null) {
      if (!context.mounted) return;
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_toDate ?? minDate),
      );

      if (time != null) {
        final selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        if (selectedDateTime.isBefore(_fromDate!) ||
            selectedDateTime.isAtSameMomentAs(_fromDate!)) {
          _showErrorSnackbar('To Date must be later than From Date');
          return;
        }

        setState(() {
          _toDate = selectedDateTime;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 10),
            Text('Success'),
          ],
        ),
        content: Text('Time extension applied successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: Text('OK', style: TextStyle(color: AppTheme.secondary)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showEditConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24),
            SizedBox(width: 10),
            Text('Edit From Date'),
          ],
        ),
        content: Text(
            'You are about to edit the auto-filled from date. Do you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isEditingFromDate = false;
              });
            },
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isEditingFromDate = true;
              });
            },
            child:
                Text('Yes, Edit', style: TextStyle(color: AppTheme.secondary)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.save, color: Colors.blue, size: 24),
            SizedBox(width: 10),
            Text('Save Changes'),
          ],
        ),
        content: Text(
            'You have changed the from date. Do you want to save these changes?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isEditingFromDate = false;
              });
            },
            child: Text('Save', style: TextStyle(color: AppTheme.secondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _fromDate = _originalFromDate;
                _isEditingFromDate = false;
              });
            },
            child: Text('Discard', style: TextStyle(color: Colors.grey)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleEditFromDate() {
    if (!_isEditingFromDate && _originalFromDate != null) {
      _showEditConfirmationDialog();
    } else if (_isEditingFromDate && _fromDate != _originalFromDate) {
      _showSaveConfirmationDialog();
    } else {
      setState(() {
        _isEditingFromDate = !_isEditingFromDate;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _selectedVehicle = null;
      _fromDate = null;
      _toDate = null;
      _isSubmitting = false;
      _isEditingFromDate = false;
      _originalFromDate = null;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicle == null || _fromDate == null || _toDate == null) {
      _showErrorSnackbar('Please fill all required fields');
      return;
    }

    if (_toDate!.isBefore(_fromDate!) ||
        _toDate!.isAtSameMomentAs(_fromDate!)) {
      _showErrorSnackbar('To Date must be later than From Date');
      return;
    }

    if (_isEditingFromDate) {
      _showErrorSnackbar('Please save or cancel edit mode before submitting');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success =
          await context.read<TimeExtensionProvider>().submitExtension(
                vehicleNumber: _selectedVehicle!.number,
                bookingId: _selectedVehicle!.bookingId,
                fromDate: _fromDate!,
                toDate: _toDate!,
              );

      if (mounted) {
        if (success) {
          _showSuccessDialog();
        } else {
          _showErrorSnackbar('Failed to apply time extension');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _calculateDuration() {
    if (_fromDate == null || _toDate == null) return null;

    final difference = _toDate!.difference(_fromDate!);
    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);
    final minutes = difference.inMinutes.remainder(60);

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  String? _getFromDateStatus() {
    if (_fromDate == null) return null;

    if (_isEditingFromDate) {
      return '⚠ Editing mode enabled';
    } else if (_originalFromDate != null && _fromDate == _originalFromDate) {
      return '✓ Auto-filled from current booking end date';
    } else if (_originalFromDate != null && _fromDate != _originalFromDate) {
      return '⚠ Modified from original date';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimeExtensionProvider>();

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Extension',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Manage vehicle booking extensions',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (provider.isLoading)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.secondary),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4A4494),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Main Content
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Form Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Card Header with gradient background
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4A4494),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Time Extension Request',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Fill in the vehicle details below',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Form Content
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Vehicle Selection
                                  _buildVehicleDropdown(provider),
                                  SizedBox(height: 20),

                                  // From Date with Edit Button
                                  _buildFromDateField(),
                                  SizedBox(height: 20),

                                  // To Date
                                  _buildToDateField(),

                                  // Duration Display
                                  if (_fromDate != null && _toDate != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 20),
                                      child: _buildDurationCard(),
                                    ),

                                  SizedBox(height: 30),

                                  // Action Buttons
                                  _buildActionButtons(),
                                ],
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildVehicleDropdown(TimeExtensionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.directions_car, color: AppTheme.secondary, size: 18),
            SizedBox(width: 8),
            Text(
              'Vehicle Number *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Vehicle>(
              isExpanded: true,
              value: _selectedVehicle,
              hint: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  provider.isLoading
                      ? 'Loading vehicles...'
                      : 'Select a vehicle',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
              icon: Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
              ),
              items: provider.vehicles.map((vehicle) {
                return DropdownMenuItem<Vehicle>(
                  value: vehicle,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.number,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (vehicle.currentBookingEnd != null)
                          Text(
                            'Current booking ends: ${DateFormat('MMM dd, yyyy HH:mm').format(vehicle.currentBookingEnd!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (Vehicle? value) {
                if (value != null) {
                  _onVehicleSelected(value);
                }
              },
            ),
          ),
        ),
        SizedBox(height: 4),
        if (_selectedVehicle != null)
          Text(
            '✓ Selected: ${_selectedVehicle!.number}',
            style: TextStyle(fontSize: 12, color: Colors.green[600]),
          ),
      ],
    );
  }

  Widget _buildFromDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppTheme.secondary, size: 18),
                SizedBox(width: 8),
                Text(
                  'From Date *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (_fromDate != null && _originalFromDate != null)
              GestureDetector(
                onTap: _toggleEditFromDate,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                        _isEditingFromDate ? Colors.green : AppTheme.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isEditingFromDate ? Icons.check : Icons.edit,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _isEditingFromDate ? 'Save' : 'Edit',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: _isEditingFromDate ||
                  (_selectedVehicle != null && !_isEditingFromDate)
              ? () => _selectFromDate(context)
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: _isEditingFromDate
                    ? Colors.blue
                    : (_selectedVehicle != null && !_isEditingFromDate)
                        ? Colors.grey[300]!
                        : Colors.grey[200]!,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: _isEditingFromDate
                  ? Colors.white
                  : (_selectedVehicle != null && !_isEditingFromDate)
                      ? Colors.white
                      : Colors.grey[100],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: (_isEditingFromDate ||
                          (_selectedVehicle != null && !_isEditingFromDate))
                      ? Colors.grey[600]
                      : Colors.grey[400],
                  size: 18,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _fromDate != null
                        ? DateFormat('MMM dd, yyyy - HH:mm').format(_fromDate!)
                        : 'Select date and time',
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          _fromDate != null ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 4),
        if (_getFromDateStatus() != null)
          Text(
            _getFromDateStatus()!,
            style: TextStyle(
              fontSize: 12,
              color: _getFromDateStatus()!.startsWith('⚠')
                  ? Colors.orange[600]
                  : _getFromDateStatus()!.startsWith('✓')
                      ? Colors.green[600]
                      : Colors.grey[500],
            ),
          ),
      ],
    );
  }

  Widget _buildToDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time, color: AppTheme.secondary, size: 18),
            SizedBox(width: 8),
            Text(
              'To Date *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: _fromDate != null ? () => _selectToDate(context) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: _toDate != null && _fromDate != null
                    ? (_toDate!.isAfter(_fromDate!)
                        ? Colors.grey[300]!
                        : Colors.red[300]!)
                    : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(8),
              color: _fromDate != null ? Colors.white : Colors.grey[100],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color:
                      _fromDate != null ? Colors.grey[600] : Colors.grey[400],
                  size: 18,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _toDate != null
                        ? DateFormat('MMM dd, yyyy - HH:mm').format(_toDate!)
                        : 'Select date and time',
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          _toDate != null ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          _fromDate == null
              ? 'Select From Date first'
              : _toDate != null && _toDate!.isBefore(_fromDate!)
                  ? '⚠ To Date must be later than From Date'
                  : _toDate != null
                      ? '✓ Valid extension date'
                      : 'Select date after ${_fromDate != null ? DateFormat('MMM dd, yyyy').format(_fromDate!) : ''}',
          style: TextStyle(
            fontSize: 12,
            color: _fromDate == null
                ? Colors.grey[500]
                : _toDate != null && _toDate!.isBefore(_fromDate!)
                    ? Colors.red[600]
                    : _toDate != null
                        ? Colors.green[600]
                        : AppTheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationCard() {
    final duration = _calculateDuration();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Extension Duration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                duration!,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Duration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                duration,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isFormValid = _selectedVehicle != null &&
        _fromDate != null &&
        _toDate != null &&
        _toDate!.isAfter(_fromDate!) &&
        !_isEditingFromDate;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : _resetForm,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: Text(
              'Reset',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting || !isFormValid ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Apply Extension',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
