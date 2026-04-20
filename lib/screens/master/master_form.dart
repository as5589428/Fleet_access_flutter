import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_theme.dart';

import 'package:http_parser/http_parser.dart'; // Add this import for MediaType
import '../../models/vehicle_model.dart';

class VehicleFormPage extends StatefulWidget {
  final String baseUrl;
  final dynamic vehicle;
  final bool isEditing;
  final VoidCallback? onVehicleCreated;
  final VoidCallback? onVehicleUpdated;

  const VehicleFormPage({
    super.key,
    required this.baseUrl,
    this.vehicle,
    this.isEditing = false,
    this.onVehicleCreated,
    this.onVehicleUpdated,
  });

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  // Mock users data
  final Color _primaryColor = AppTheme.primary;

  final List<Map<String, String>> mockUsers = const [
    {'id': '001', 'name': 'Admin'},
    {'id': '002', 'name': 'Manager'},
    {'id': '003', 'name': 'Driver'},
    {'id': '004', 'name': 'Supervisor'},
  ];

  // Form Data Structure
  Map<String, dynamic> formData = {
    'vehicle_number': '',
    'vehicle_type': 'Car',
    'ownership_name': '',
    'user_name': '',
    'user_id': '',
    'seating_capacity': '',
    'service_km_alert': '',
    'status': 'Active',
    'remarks': '',
    'current_km': '',
    'purchase_type': 'NEW',
    'vehicle_details': {
      'brand': '',
      'model': '',
      'registration_date': '',
      'year_of_purchase': DateTime.now().year,
      'fuel_type': <String>[],
      'rc_book_url': '',
      'insurance_url': '',
      'pollution_url': '',
      'battery_warranty_url': '',
      'status_documents_url': '',
      'maintenance_expiry_url': '',
      'tyre_expiry_url': '',
      'wheel_expiry_url': ''
    },
    'expiry_details': {
      'insurance_expiry': '',
      'pollution_expiry': '',
      'maintenance_expiry': '',
      'wheel_balancing_expiry': '',
      'tyre_change_expiry': '',
      'battery_expiry': ''
    },
    'purchase_details': {
      'new_vehicle': {
        'sup_name': '',
        'sup_add': '',
        'sup_cost': '',
        'sup_bill': null
      },
      'old_vehicle': {
        'per_name': '',
        'per_adh': '',
        'per_phone': '',
        'per_cost': '',
        'per_adhurl': null,
        'per_doc': null
      }
    },
    'resale_details': {
      'date_of_resale': '',
      'sale_amount': '',
      'pay_recieved': false,
      'purchaser_name': '',
      'sale_mob_no': '',
      'sale_adh': '',
      'sale_adhurl': null,
      'sale_dc': null
    },
    'theft_details': {
      'date_of_theft': '',
      'place_of_theft': '',
      'theft_name': '',
      'theft_mob_no': '',
      'theft_FIRurl': null
    },
    'scrap_details': {
      'date_of_scrap': '',
      'scr_name': '',
      'scr_address': '',
      'scrap_adh': '',
      'scrap_mob_no': '',
      'scrap_adhurl': null,
      'scrap_photo': null,
      'scrap_document': null
    }
  };

  Map<String, String> errors = {};
  bool submitLoading = false;
  bool loading = false;
  bool autoFillUser = false;
  bool isTogglingPurchase = false;

  // File uploads state
  Map<String, Uint8List?> fileUploads = {
    'rc_book': null,
    'insurance': null,
    'pollution': null,
    'status_document': null,
    'battery_warranty': null,
    'sup_bill': null,
    'per_adhurl': null,
    'per_doc': null,
    'sale_adhurl': null,
    'sale_dc': null,
    'theft_FIRurl': null,
    'scrap_adhurl': null,
    'scrap_photo': null,
    'scrap_document': null,
    'maintenance': null,
    'tyre': null,
    'wheel_balancing': null
  };

  Map<String, String> fileNames = {};

  // Gradient is removed in favor of solid color

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.vehicle != null) {
      populateFormData(widget.vehicle);
    }
  }

  void populateFormData(dynamic vehicleDataRaw) {
    debugPrint('Populating form data with: $vehicleDataRaw');

    // Convert VehicleModel to Map if needed
    final Map<String, dynamic> vehicleData =
        vehicleDataRaw is VehicleModel ? vehicleDataRaw.toJson() : vehicleDataRaw;

    String formatDateForInput(String? dateString) {
      if (dateString == null || dateString.isEmpty) return '';
      try {
        final date = DateTime.parse(dateString);
        return DateFormat('yyyy-MM-dd').format(date);
      } catch (e) {
        return '';
      }
    }

    String parseExpiryValue(dynamic value) {
      if (value == null) return '';
      if (value is num) return value.toString();
      if (value is String) {
        final numericString = value.replaceAll(RegExp(r'[^0-9.]'), '');
        if (numericString.isNotEmpty &&
            double.tryParse(numericString) != null) {
          return numericString;
        }
        try {
          final date = DateTime.parse(value);
          return DateFormat('yyyy-MM-dd').format(date);
        } catch (e) {
          return value;
        }
      }
      return value.toString();
    }

    List<String> fuelType = [];
    if (vehicleData['vehicle_details']?['fuel_type'] != null) {
      if (vehicleData['vehicle_details']['fuel_type'] is List) {
        fuelType =
            List<String>.from(vehicleData['vehicle_details']['fuel_type']);
      } else {
        fuelType = [vehicleData['vehicle_details']['fuel_type'].toString()];
      }
    }

    String purchaseType = 'NEW';
    if (vehicleData['purchase_details'] != null) {
      if (vehicleData['purchase_details']['purchase_type'] != null) {
        purchaseType = vehicleData['purchase_details']['purchase_type'];
      } else if (vehicleData['purchase_details']['new_vehicle'] != null) {
        final hasNewData =
            (vehicleData['purchase_details']['new_vehicle'] as Map)
                .values
                .any((val) => val != null && val != '');
        if (hasNewData) purchaseType = 'NEW';
      }
      if (vehicleData['purchase_details']['old_vehicle'] != null) {
        final hasOldData =
            (vehicleData['purchase_details']['old_vehicle'] as Map)
                .values
                .any((val) => val != null && val != '');
        if (hasOldData) purchaseType = 'OLD';
      }
    }

    setState(() {
      formData = {
        'vehicle_number': vehicleData['vehicle_number'] ?? '',
        'vehicle_type': vehicleData['vehicle_type'] ?? 'Car',
        'ownership_name': vehicleData['ownership_name'] ?? '',
        'user_name': vehicleData['user_name'] ?? '',
        'user_id': vehicleData['user_id'] ?? '',
        'seating_capacity': vehicleData['seating_capacity']?.toString() ?? '',
        'service_km_alert': vehicleData['service_km_alert']?.toString() ?? '',
        'current_km': vehicleData['current_km']?.toString() ?? '',
        'status': vehicleData['status'] ?? 'Active',
        'remarks': vehicleData['remarks'] ?? '',
        'purchase_type': purchaseType,
        'purchase_details': {
          'new_vehicle': {
            'sup_name': vehicleData['purchase_details']?['new_vehicle']
                    ?['sup_name'] ??
                '',
            'sup_add': vehicleData['purchase_details']?['new_vehicle']
                    ?['sup_add'] ??
                '',
            'sup_cost': vehicleData['purchase_details']?['new_vehicle']
                        ?['sup_cost']
                    ?.toString() ??
                '',
            'sup_bill': vehicleData['purchase_details']?['new_vehicle']
                ?['sup_bill'],
          },
          'old_vehicle': {
            'per_name': vehicleData['purchase_details']?['old_vehicle']
                    ?['per_name'] ??
                '',
            'per_adh': vehicleData['purchase_details']?['old_vehicle']
                    ?['per_adh'] ??
                '',
            'per_phone': vehicleData['purchase_details']?['old_vehicle']
                    ?['per_phone'] ??
                '',
            'per_cost': vehicleData['purchase_details']?['old_vehicle']
                        ?['per_cost']
                    ?.toString() ??
                '',
            'per_adhurl': vehicleData['purchase_details']?['old_vehicle']
                ?['per_adhurl'],
            'per_doc': vehicleData['purchase_details']?['old_vehicle']
                ?['per_doc'],
          }
        },
        'resale_details': {
          'date_of_resale': formatDateForInput(
              vehicleData['resale_details']?['date_of_resale']),
          'sale_amount':
              vehicleData['resale_details']?['sale_amount']?.toString() ?? '',
          'pay_recieved':
              vehicleData['resale_details']?['pay_recieved'] ?? false,
          'purchaser_name':
              vehicleData['resale_details']?['purchaser_name'] ?? '',
          'sale_mob_no': vehicleData['resale_details']?['sale_mob_no'] ?? '',
          'sale_adh': vehicleData['resale_details']?['sale_adh'] ?? '',
          'sale_adhurl': vehicleData['resale_details']?['sale_adhurl'],
          'sale_dc': vehicleData['resale_details']?['sale_dc'],
        },
        'theft_details': {
          'date_of_theft': formatDateForInput(
              vehicleData['theft_details']?['date_of_theft']),
          'place_of_theft':
              vehicleData['theft_details']?['place_of_theft'] ?? '',
          'theft_name': vehicleData['theft_details']?['theft_name'] ?? '',
          'theft_mob_no': vehicleData['theft_details']?['theft_mob_no'] ?? '',
          'theft_FIRurl': vehicleData['theft_details']?['theft_FIRurl'],
        },
        'scrap_details': {
          'date_of_scrap': formatDateForInput(
              vehicleData['scrap_details']?['date_of_scrap']),
          'scr_name': vehicleData['scrap_details']?['scr_name'] ?? '',
          'scr_address': vehicleData['scrap_details']?['scr_address'] ?? '',
          'scrap_adh': vehicleData['scrap_details']?['scrap_adh'] ?? '',
          'scrap_mob_no': vehicleData['scrap_details']?['scrap_mob_no'] ?? '',
          'scrap_adhurl': vehicleData['scrap_details']?['scrap_adhurl'],
          'scrap_photo': vehicleData['scrap_details']?['scrap_photo'],
          'scrap_document': vehicleData['scrap_details']?['scrap_document'],
        },
        'vehicle_details': {
          'brand': vehicleData['vehicle_details']?['brand'] ?? '',
          'model': vehicleData['vehicle_details']?['model'] ?? '',
          'registration_date': formatDateForInput(
              vehicleData['vehicle_details']?['registration_date']),
          'year_of_purchase': vehicleData['vehicle_details']
                  ?['year_of_purchase'] ??
              DateTime.now().year,
          'fuel_type': fuelType,
          'rc_book_url': vehicleData['vehicle_details']?['rc_book_url'] ?? '',
          'insurance_url':
              vehicleData['vehicle_details']?['insurance_url'] ?? '',
          'pollution_url':
              vehicleData['vehicle_details']?['pollution_url'] ?? '',
          'battery_warranty_url':
              vehicleData['vehicle_details']?['battery_warranty_url'] ?? '',
          'status_documents_url':
              vehicleData['vehicle_details']?['status_documents_url'] ?? '',
          'maintenance_expiry_url':
              vehicleData['vehicle_details']?['maintenance_expiry_url'] ?? '',
          'tyre_expiry_url':
              vehicleData['vehicle_details']?['tyre_expiry_url'] ?? '',
          'wheel_expiry_url':
              vehicleData['vehicle_details']?['wheel_expiry_url'] ?? ''
        },
        'expiry_details': {
          'insurance_expiry': formatDateForInput(
              vehicleData['expiry_details']?['insurance_expiry']),
          'pollution_expiry': formatDateForInput(
              vehicleData['expiry_details']?['pollution_expiry']),
          'maintenance_expiry': formatDateForInput(
              vehicleData['expiry_details']?['maintenance_expiry']),
          'wheel_balancing_expiry': parseExpiryValue(
              vehicleData['expiry_details']?['wheel_balancing_expiry']),
          'tyre_change_expiry': parseExpiryValue(
              vehicleData['expiry_details']?['tyre_change_expiry']),
          'battery_expiry': formatDateForInput(
              vehicleData['expiry_details']?['battery_expiry']),
        }
      };

      if (vehicleData['user_id'] == '001' &&
          vehicleData['user_name'] == 'Admin') {
        autoFillUser = true;
      }
    });
  }

  void handleInputChange(String fieldPath, dynamic value) {
    setState(() {
      _setNestedValue(formData, fieldPath.split('.'), value);
      if (errors.containsKey(fieldPath)) {
        errors.remove(fieldPath);
      }
    });

    if ((fieldPath == 'user_name' || fieldPath == 'user_id') && autoFillUser) {
      if (fieldPath == 'user_name' && value != 'Admin') {
        setState(() => autoFillUser = false);
      }
      if (fieldPath == 'user_id' && value != '001') {
        setState(() => autoFillUser = false);
      }
    }
  }

  void _setNestedValue(Map map, List<String> path, dynamic value) {
    if (path.length == 1) {
      map[path.first] = value;
      return;
    }
    if (map[path.first] == null) {
      map[path.first] = <String, dynamic>{};
    }
    _setNestedValue(map[path.first], path.sublist(1), value);
  }

  void handleFuelTypeChange(String value, bool checked) {
    setState(() {
      List<String> currentFuel =
          List<String>.from(formData['vehicle_details']['fuel_type']);
      if (checked) {
        if (!currentFuel.contains(value)) {
          currentFuel.add(value);
        }
      } else {
        currentFuel.remove(value);
      }
      formData['vehicle_details']['fuel_type'] = currentFuel;
    });
  }

  void handleFileUpload(String field, Uint8List? fileBytes, String fileName) {
    setState(() {
      fileUploads[field] = fileBytes;
      fileNames[field] = fileName;
      // Clear error for this field
      if (errors.containsKey(field)) {
        errors.remove(field);
      }
    });
    debugPrint('📁 File uploaded: $field - $fileName (${fileBytes?.length} bytes)');
  }

  void handleFileReset(String field) {
    setState(() {
      fileUploads[field] = null;
      fileNames.remove(field);
    });
  }

  void cyclePurchaseType() {
    setState(() {
      isTogglingPurchase = true;
      formData['purchase_type'] =
          formData['purchase_type'] == 'NEW' ? 'OLD' : 'NEW';
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          isTogglingPurchase = false;
        });
      }
    });
  }

  String getPurchaseTypeBgClass(String type) {
    switch (type) {
      case "NEW":
        return "bg-green-600";
      case "OLD":
        return "bg-yellow-500";
      default:
        return "bg-green-600";
    }
  }

  String getIndicatorPosition(String type) {
    switch (type) {
      case "NEW":
        return "left-1";
      case "OLD":
        return "right-1";
      default:
        return "left-1";
    }
  }

  String getStatusDescription(String type) {
    switch (type) {
      case "NEW":
        return "New vehicle - Purchased from supplier";
      case "OLD":
        return "Old vehicle - Purchased from individual";
      default:
        return "New vehicle - Purchased from supplier";
    }
  }

  Map<String, dynamic> getStatusDisplay(String type) {
    switch (type) {
      case "NEW":
        return {
          'icon': Icons.check_circle,
          'iconColor': Colors.green,
          'textColor': Colors.green,
          'bgColor': Colors.green.withValues(alpha: 0.1),
          'borderColor': Colors.green,
          'text': 'NEW'
        };
      case "OLD":
        return {
          'icon': Icons.warning,
          'iconColor': Colors.orange,
          'textColor': Colors.orange,
          'bgColor': Colors.orange.withValues(alpha: 0.1),
          'borderColor': Colors.orange,
          'text': 'OLD'
        };
      default:
        return {
          'icon': Icons.check_circle,
          'iconColor': Colors.green,
          'textColor': Colors.green,
          'bgColor': Colors.green.withValues(alpha: 0.1),
          'borderColor': Colors.green,
          'text': 'NEW'
        };
    }
  }

  Map<String, String> validateForm() {
    final errors = <String, String>{};

    if ((formData['vehicle_number'] as String?)?.trim().isEmpty ?? true) {
      errors['vehicle_number'] = 'Vehicle number is required';
    }
    if ((formData['vehicle_type'] as String?)?.isEmpty ?? true) {
      errors['vehicle_type'] = 'Vehicle type is required';
    }
    if ((formData['ownership_name'] as String?)?.trim().isEmpty ?? true) {
      errors['ownership_name'] = 'Ownership name is required';
    }
    if ((formData['vehicle_details']['brand'] as String?)?.trim().isEmpty ??
        true) {
      errors['brand'] = 'Brand is required';
    }
    if ((formData['vehicle_details']['model'] as String?)?.trim().isEmpty ??
        true) {
      errors['model'] = 'Model is required';
    }

    // RC BOOK IS REQUIRED for new vehicles
    if (!widget.isEditing && fileUploads['rc_book'] == null) {
      errors['rc_book'] = 'RC book document is required';
    }

    if (formData['vehicle_details']['year_of_purchase'] != null) {
      final currentYear = DateTime.now().year;
      final yearStr =
          formData['vehicle_details']['year_of_purchase'].toString();
      final year = int.tryParse(yearStr);
      if (year != null && (year < 1900 || year > currentYear + 1)) {
        errors['year_of_purchase'] = 'Please enter a valid year';
      }
    }

    if (formData['status'] == 'Resale') {
      if ((formData['resale_details']['date_of_resale'] as String?)?.isEmpty ??
          true) {
        errors['date_of_resale'] = 'Date of resale is required';
      }
      if ((formData['resale_details']['sale_amount'] as String?)?.isEmpty ??
          true) {
        errors['sale_amount'] = 'Resale amount is required';
      }
      if ((formData['resale_details']['purchaser_name'] as String?)
              ?.trim()
              .isEmpty ??
          true) {
        errors['purchaser_name'] = 'Purchaser name is required';
      }
    }

    if (formData['status'] == 'Theft') {
      if ((formData['theft_details']['date_of_theft'] as String?)?.isEmpty ??
          true) {
        errors['date_of_theft'] = 'Date of theft is required';
      }
      if ((formData['theft_details']['place_of_theft'] as String?)
              ?.trim()
              .isEmpty ??
          true) {
        errors['place_of_theft'] = 'Place of theft is required';
      }
      if ((formData['theft_details']['theft_name'] as String?)
              ?.trim()
              .isEmpty ??
          true) {
        errors['theft_name'] = 'Employee name is required';
      }
    }

    if (formData['status'] == 'Scrap') {
      if ((formData['scrap_details']['date_of_scrap'] as String?)?.isEmpty ??
          true) {
        errors['date_of_scrap'] = 'Date of scrap is required';
      }
      if ((formData['scrap_details']['scr_name'] as String?)?.trim().isEmpty ??
          true) {
        errors['scr_name'] = 'Supplier name is required';
      }
      if ((formData['scrap_details']['scr_address'] as String?)
              ?.trim()
              .isEmpty ??
          true) {
        errors['scr_address'] = 'Supplier address is required';
      }
    }

    return errors;
  }

  Future<void> submitForm() async {
    setState(() => submitLoading = true);

    try {
      var request = http.MultipartRequest(
        widget.isEditing ? 'PUT' : 'POST',
        Uri.parse(widget.isEditing
            ? '${widget.baseUrl}/vehicles/update/${widget.vehicle is VehicleModel ? widget.vehicle.id : widget.vehicle['_id']}'
            : '${widget.baseUrl}/vehicles/create'),
      );

      // Generate vehicle_id for new vehicles
      if (!widget.isEditing) {
        request.fields['vehicle_id'] =
            'V${DateTime.now().millisecondsSinceEpoch}';
        debugPrint(
            '📝 Generated vehicle_id: V${DateTime.now().millisecondsSinceEpoch}');
      }

      // Add all form fields
      _addFieldIfNotEmpty(
          request, 'vehicle_number', formData['vehicle_number']);
      _addFieldIfNotEmpty(request, 'vehicle_type', formData['vehicle_type']);
      _addFieldIfNotEmpty(
          request, 'ownership_name', formData['ownership_name']);
      _addFieldIfNotEmpty(request, 'user_name', formData['user_name']);
      _addFieldIfNotEmpty(request, 'user_id', formData['user_id']);
      _addFieldIfNotEmpty(request, 'status', formData['status']);
      _addFieldIfNotEmpty(request, 'remarks', formData['remarks']);
      _addFieldIfNotEmpty(request, 'service_km_alert',
          formData['service_km_alert']?.toString());
      _addFieldIfNotEmpty(
          request, 'current_km', formData['current_km']?.toString());
      _addFieldIfNotEmpty(request, 'seating_capacity',
          formData['seating_capacity']?.toString());

      // Purchase type
      _addFieldIfNotEmpty(request, 'purchase_details[purchase_type]',
          formData['purchase_type']);

      // Purchase details - NEW vehicle
      if (formData['purchase_type'] == 'NEW') {
        _addFieldIfNotEmpty(request, 'purchase_details[new_vehicle][sup_name]',
            formData['purchase_details']['new_vehicle']['sup_name']);
        _addFieldIfNotEmpty(request, 'purchase_details[new_vehicle][sup_add]',
            formData['purchase_details']['new_vehicle']['sup_add']);
        _addFieldIfNotEmpty(
            request,
            'purchase_details[new_vehicle][sup_cost]',
            formData['purchase_details']['new_vehicle']['sup_cost']
                ?.toString());
      }

      // Purchase details - OLD vehicle
      if (formData['purchase_type'] == 'OLD') {
        _addFieldIfNotEmpty(request, 'purchase_details[old_vehicle][per_name]',
            formData['purchase_details']['old_vehicle']['per_name']);
        _addFieldIfNotEmpty(request, 'purchase_details[old_vehicle][per_adh]',
            formData['purchase_details']['old_vehicle']['per_adh']);
        _addFieldIfNotEmpty(request, 'purchase_details[old_vehicle][per_phone]',
            formData['purchase_details']['old_vehicle']['per_phone']);
        _addFieldIfNotEmpty(
            request,
            'purchase_details[old_vehicle][per_cost]',
            formData['purchase_details']['old_vehicle']['per_cost']
                ?.toString());
      }

      // Vehicle details
      _addFieldIfNotEmpty(request, 'vehicle_details[brand]',
          formData['vehicle_details']['brand']);
      _addFieldIfNotEmpty(request, 'vehicle_details[model]',
          formData['vehicle_details']['model']);
      _addFieldIfNotEmpty(request, 'vehicle_details[registration_date]',
          formData['vehicle_details']['registration_date']);
      _addFieldIfNotEmpty(request, 'vehicle_details[year_of_purchase]',
          formData['vehicle_details']['year_of_purchase']?.toString());

      // Fuel type - take first if multiple
      if (formData['vehicle_details']['fuel_type'] != null &&
          (formData['vehicle_details']['fuel_type'] as List).isNotEmpty) {
        request.fields['vehicle_details[fuel_type]'] =
            (formData['vehicle_details']['fuel_type'] as List).first.toString();
      }

      // Expiry details
      _addFieldIfNotEmpty(request, 'expiry_details[insurance_expiry]',
          formData['expiry_details']['insurance_expiry']);
      _addFieldIfNotEmpty(request, 'expiry_details[pollution_expiry]',
          formData['expiry_details']['pollution_expiry']);
      _addFieldIfNotEmpty(request, 'expiry_details[maintenance_expiry]',
          formData['expiry_details']['maintenance_expiry']);
      _addFieldIfNotEmpty(request, 'expiry_details[wheel_balancing_expiry]',
          formData['expiry_details']['wheel_balancing_expiry']?.toString());
      _addFieldIfNotEmpty(request, 'expiry_details[tyre_change_expiry]',
          formData['expiry_details']['tyre_change_expiry']?.toString());
      _addFieldIfNotEmpty(request, 'expiry_details[battery_expiry]',
          formData['expiry_details']['battery_expiry']);

      // Status-specific details - Resale
      if (formData['status'] == 'Resale') {
        _addFieldIfNotEmpty(request, 'resale_details[date_of_resale]',
            formData['resale_details']['date_of_resale']);
        _addFieldIfNotEmpty(request, 'resale_details[sale_amount]',
            formData['resale_details']['sale_amount']?.toString());
        request.fields['resale_details[pay_recieved]'] =
            (formData['resale_details']['pay_recieved'] == true)
                ? 'true'
                : 'false';
        _addFieldIfNotEmpty(request, 'resale_details[purchaser_name]',
            formData['resale_details']['purchaser_name']);
        _addFieldIfNotEmpty(request, 'resale_details[sale_mob_no]',
            formData['resale_details']['sale_mob_no']);
        _addFieldIfNotEmpty(request, 'resale_details[sale_adh]',
            formData['resale_details']['sale_adh']);
      }

      // Status-specific details - Theft
      if (formData['status'] == 'Theft') {
        _addFieldIfNotEmpty(request, 'theft_details[date_of_theft]',
            formData['theft_details']['date_of_theft']);
        _addFieldIfNotEmpty(request, 'theft_details[place_of_theft]',
            formData['theft_details']['place_of_theft']);
        _addFieldIfNotEmpty(request, 'theft_details[theft_name]',
            formData['theft_details']['theft_name']);
        _addFieldIfNotEmpty(request, 'theft_details[theft_mob_no]',
            formData['theft_details']['theft_mob_no']);
      }

      // Status-specific details - Scrap
      if (formData['status'] == 'Scrap') {
        _addFieldIfNotEmpty(request, 'scrap_details[date_of_scrap]',
            formData['scrap_details']['date_of_scrap']);
        _addFieldIfNotEmpty(request, 'scrap_details[scr_name]',
            formData['scrap_details']['scr_name']);
        _addFieldIfNotEmpty(request, 'scrap_details[scr_address]',
            formData['scrap_details']['scr_address']);
        _addFieldIfNotEmpty(request, 'scrap_details[scrap_adh]',
            formData['scrap_details']['scrap_adh']);
        _addFieldIfNotEmpty(request, 'scrap_details[scrap_mob_no]',
            formData['scrap_details']['scrap_mob_no']);
      }

      // CRITICAL FIX: Add files one by one with explicit field names
      debugPrint('📁 Checking files to upload:');

      // RC Book - REQUIRED
      if (fileUploads['rc_book'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'rc_book',
            fileUploads['rc_book']!,
            filename: fileNames['rc_book'] ??
                'rc_book_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint(
              '✅ RC Book file added: ${fileNames['rc_book']} (${fileUploads['rc_book']?.length} bytes)');
        } catch (e) {
          debugPrint('❌ Error adding RC Book: $e');
        }
      } else {
        debugPrint('❌ RC Book file is missing!');
        if (!widget.isEditing) {
          setState(() {
            errors['rc_book'] = 'RC book document is required';
            submitLoading = false;
          });
          _showErrorSnackBar('RC book document is required');
          return;
        }
      }

      // Insurance
      if (fileUploads['insurance'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'insurance',
            fileUploads['insurance']!,
            filename: fileNames['insurance'] ??
                'insurance_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint('✅ Insurance file added: ${fileNames['insurance']}');
        } catch (e) {
          debugPrint('❌ Error adding Insurance: $e');
        }
      }

      // Pollution
      if (fileUploads['pollution'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'pollution',
            fileUploads['pollution']!,
            filename: fileNames['pollution'] ??
                'pollution_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint('✅ Pollution file added: ${fileNames['pollution']}');
        } catch (e) {
          debugPrint('❌ Error adding Pollution: $e');
        }
      }

      // Battery Warranty
      if (fileUploads['battery_warranty'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'battery_warranty',
            fileUploads['battery_warranty']!,
            filename: fileNames['battery_warranty'] ??
                'battery_warranty_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint(
              '✅ Battery Warranty file added: ${fileNames['battery_warranty']}');
        } catch (e) {
          debugPrint('❌ Error adding Battery Warranty: $e');
        }
      }

      // Maintenance
      if (fileUploads['maintenance'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'maintenance',
            fileUploads['maintenance']!,
            filename: fileNames['maintenance'] ??
                'maintenance_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint('✅ Maintenance file added: ${fileNames['maintenance']}');
        } catch (e) {
          debugPrint('❌ Error adding Maintenance: $e');
        }
      }

      // Tyre
      if (fileUploads['tyre'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'tyre',
            fileUploads['tyre']!,
            filename: fileNames['tyre'] ??
                'tyre_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint('✅ Tyre file added: ${fileNames['tyre']}');
        } catch (e) {
          debugPrint('❌ Error adding Tyre: $e');
        }
      }

      // Wheel Balancing
      if (fileUploads['wheel_balancing'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'wheel_balancing',
            fileUploads['wheel_balancing']!,
            filename: fileNames['wheel_balancing'] ??
                'wheel_balancing_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint(
              '✅ Wheel Balancing file added: ${fileNames['wheel_balancing']}');
        } catch (e) {
          debugPrint('❌ Error adding Wheel Balancing: $e');
        }
      }

      // Sup Bill (nested)
      if (fileUploads['sup_bill'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'purchase_details[new_vehicle][sup_bill]',
            fileUploads['sup_bill']!,
            filename: fileNames['sup_bill'] ??
                'sup_bill_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint('✅ Sup Bill file added: ${fileNames['sup_bill']}');
        } catch (e) {
          debugPrint('❌ Error adding Sup Bill: $e');
        }
      }

      // Per Aadhar (nested)
      if (fileUploads['per_adhurl'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'purchase_details[old_vehicle][per_adhurl]',
            fileUploads['per_adhurl']!,
            filename: fileNames['per_adhurl'] ??
                'per_adhurl_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint('✅ Per Aadhar file added: ${fileNames['per_adhurl']}');
        } catch (e) {
          debugPrint('❌ Error adding Per Aadhar: $e');
        }
      }

      // Per Doc (nested)
      if (fileUploads['per_doc'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'purchase_details[old_vehicle][per_doc]',
            fileUploads['per_doc']!,
            filename: fileNames['per_doc'] ??
                'per_doc_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint('✅ Per Doc file added: ${fileNames['per_doc']}');
        } catch (e) {
          debugPrint('❌ Error adding Per Doc: $e');
        }
      }

      // Sale Aadhar (nested)
      if (fileUploads['sale_adhurl'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'resale_details[sale_adhurl]',
            fileUploads['sale_adhurl']!,
            filename: fileNames['sale_adhurl'] ??
                'sale_adhurl_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint('✅ Sale Aadhar file added: ${fileNames['sale_adhurl']}');
        } catch (e) {
          debugPrint('❌ Error adding Sale Aadhar: $e');
        }
      }

      // Sale DC (nested)
      if (fileUploads['sale_dc'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'resale_details[sale_dc]',
            fileUploads['sale_dc']!,
            filename: fileNames['sale_dc'] ??
                'sale_dc_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint('✅ Sale DC file added: ${fileNames['sale_dc']}');
        } catch (e) {
          debugPrint('❌ Error adding Sale DC: $e');
        }
      }

      // Theft FIR (nested)
      if (fileUploads['theft_FIRurl'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'theft_details[theft_FIRurl]',
            fileUploads['theft_FIRurl']!,
            filename: fileNames['theft_FIRurl'] ??
                'theft_FIRurl_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint('✅ Theft FIR file added: ${fileNames['theft_FIRurl']}');
        } catch (e) {
          debugPrint('❌ Error adding Theft FIR: $e');
        }
      }

      // Scrap Aadhar (nested)
      if (fileUploads['scrap_adhurl'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'scrap_details[scrap_adhurl]',
            fileUploads['scrap_adhurl']!,
            filename: fileNames['scrap_adhurl'] ??
                'scrap_adhurl_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint('✅ Scrap Aadhar file added: ${fileNames['scrap_adhurl']}');
        } catch (e) {
          debugPrint('❌ Error adding Scrap Aadhar: $e');
        }
      }

      // Scrap Photo (nested)
      if (fileUploads['scrap_photo'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'scrap_details[scrap_photo]',
            fileUploads['scrap_photo']!,
            filename: fileNames['scrap_photo'] ??
                'scrap_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint('✅ Scrap Photo file added: ${fileNames['scrap_photo']}');
        } catch (e) {
          debugPrint('❌ Error adding Scrap Photo: $e');
        }
      }

      // Scrap Document (nested)
      if (fileUploads['scrap_document'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'scrap_details[scrap_document]',
            fileUploads['scrap_document']!,
            filename: fileNames['scrap_document'] ??
                'scrap_document_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint('✅ Scrap Document file added: ${fileNames['scrap_document']}');
        } catch (e) {
          debugPrint('❌ Error adding Scrap Document: $e');
        }
      }

      // Status Document
      if (fileUploads['status_document'] != null) {
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'status_documents',
            fileUploads['status_document']!,
            filename: fileNames['status_document'] ??
                'status_document_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
          debugPrint(
              '✅ Status Document file added: ${fileNames['status_document']}');
        } catch (e) {
          debugPrint('❌ Error adding Status Document: $e');
        }
      }

      // Log all fields being sent
      debugPrint('\n📤 FINAL REQUEST SUMMARY:');
      debugPrint('URL: ${request.url}');
      debugPrint('Method: ${widget.isEditing ? 'PUT' : 'POST'}');
      debugPrint('\n📤 FIELDS (${request.fields.length}):');
      request.fields.forEach((key, value) {
        debugPrint('   $key: $value');
      });
      debugPrint('\n📤 FILES (${request.files.length}):');
      for (var file in request.files) {
        debugPrint('   ${file.field}: ${file.filename} (${file.length} bytes)');
      }

      // Send request
      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      final response = await http.Response.fromStream(streamedResponse);
      if (!mounted) return;

      debugPrint('\n📥 RESPONSE:');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          _showSuccessSnackBar(result['message'] ??
              'Vehicle ${widget.isEditing ? 'updated' : 'created'} successfully!');

          if (widget.isEditing) {
            widget.onVehicleUpdated?.call();
          } else {
            widget.onVehicleCreated?.call();
          }

          if (mounted) Navigator.of(context).pop();
        } else {
          _showErrorSnackBar(result['message'] ?? 'Server returned error');
        }
      } else {
        _showErrorSnackBar(
            'Server error (${response.statusCode}): ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      _showErrorSnackBar('An error occurred: $e');
    } finally {
      if (mounted) setState(() => submitLoading = false);
    }
  }

  void _addFieldIfNotEmpty(
      http.MultipartRequest request, String key, dynamic value) {
    if (value != null && value.toString().trim().isNotEmpty) {
      request.fields[key] = value.toString().trim();
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickImage(String field) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null) return;
      if (!mounted) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      handleFileUpload(field, bytes, image.name);
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image');
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX 1: Get top padding for status bar
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    if (loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading vehicle data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // FIX 1: Header with top padding
              // Header with static color
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 12),
                color:
                    const Color(0xFF4A4494), // Static color instead of gradient
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEditing
                                ? 'Edit Vehicle'
                                : 'Create New Vehicle',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage vehicle information',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Basic Information
                        _buildSection('Basic Information', [
                          _buildTextField(
                            label: 'Vehicle Number *',
                            value: formData['vehicle_number'],
                            onChanged: (val) => handleInputChange(
                                'vehicle_number', val?.toUpperCase()),
                            error: errors['vehicle_number'],
                            enabled: !widget.isEditing,
                          ),
                          _buildDropdown(
                            label: 'Vehicle Type *',
                            value: formData['vehicle_type'],
                            items: const ['Car', 'Bike', 'Truck'],
                            onChanged: (val) =>
                                handleInputChange('vehicle_type', val),
                            error: errors['vehicle_type'],
                          ),
                          _buildTextField(
                            label: 'Ownership Name *',
                            value: formData['ownership_name'],
                            onChanged: (val) =>
                                handleInputChange('ownership_name', val),
                            error: errors['ownership_name'],
                          ),
                          _buildUserField(),
                          _buildTextField(
                            label: 'Seating Capacity',
                            value: formData['seating_capacity'],
                            onChanged: (val) =>
                                handleInputChange('seating_capacity', val),
                            keyboardType: TextInputType.number,
                          ),
                          _buildTextField(
                            label: 'Service KM Alert',
                            value: formData['service_km_alert'],
                            onChanged: (val) =>
                                handleInputChange('service_km_alert', val),
                            keyboardType: TextInputType.number,
                          ),
                        ]),

                        const SizedBox(height: 16),

                        // Section 2: Vehicle Details
                        _buildSection('Vehicle Details', [
                          _buildTextField(
                            label: 'Brand *',
                            value: formData['vehicle_details']['brand'],
                            onChanged: (val) =>
                                handleInputChange('vehicle_details.brand', val),
                            error: errors['brand'],
                          ),
                          _buildTextField(
                            label: 'Model *',
                            value: formData['vehicle_details']['model'],
                            onChanged: (val) =>
                                handleInputChange('vehicle_details.model', val),
                            error: errors['model'],
                          ),
                          _buildDateField(
                            label: 'Registration Date',
                            value: formData['vehicle_details']
                                ['registration_date'],
                            onChanged: (val) => handleInputChange(
                                'vehicle_details.registration_date', val),
                          ),
                          _buildTextField(
                            label: 'Purchase Year',
                            value: formData['vehicle_details']
                                    ['year_of_purchase']
                                .toString(),
                            onChanged: (val) {
                              if (val != null) {
                                handleInputChange(
                                    'vehicle_details.year_of_purchase',
                                    int.tryParse(val)?.toString() ??
                                        DateTime.now().year.toString());
                              }
                            },
                            keyboardType: TextInputType.number,
                            error: errors['year_of_purchase'],
                          ),
                          _buildFuelTypeField(),
                        ]),

                        const SizedBox(height: 16),

                        // Section: Purchase Details
                        _buildSection('Purchase Details', [
                          _buildPurchaseTypeField(),
                          if (formData['purchase_type'] == 'NEW') ...[
                            _buildTextField(
                              label: 'Supplier Name',
                              value: formData['purchase_details']['new_vehicle']
                                  ['sup_name'],
                              onChanged: (val) => handleInputChange(
                                  'purchase_details.new_vehicle.sup_name', val),
                            ),
                            _buildTextField(
                              label: 'Supplier Address',
                              value: formData['purchase_details']['new_vehicle']
                                  ['sup_add'],
                              onChanged: (val) => handleInputChange(
                                  'purchase_details.new_vehicle.sup_add', val),
                            ),
                            _buildTextField(
                              label: 'Cost',
                              value: formData['purchase_details']['new_vehicle']
                                  ['sup_cost'],
                              onChanged: (val) => handleInputChange(
                                  'purchase_details.new_vehicle.sup_cost', val),
                              keyboardType: TextInputType.number,
                            ),
                            _buildFileUploadField(
                              label: 'Bill Upload',
                              field: 'sup_bill',
                              fileName: fileNames['sup_bill'],
                              hasExisting: formData['purchase_details']
                                      ['new_vehicle']['sup_bill'] !=
                                  null,
                            ),
                          ],
                          if (formData['purchase_type'] == 'OLD') ...[
                            _buildTextField(
                              label: 'Person Name',
                              value: formData['purchase_details']['old_vehicle']
                                  ['per_name'],
                              onChanged: (val) => handleInputChange(
                                  'purchase_details.old_vehicle.per_name', val),
                            ),
                            _buildTextField(
                              label: 'Aadhar Number',
                              value: formData['purchase_details']['old_vehicle']
                                  ['per_adh'],
                              onChanged: (val) => handleInputChange(
                                  'purchase_details.old_vehicle.per_adh', val),
                            ),
                            _buildTextField(
                              label: 'Mobile Number',
                              value: formData['purchase_details']['old_vehicle']
                                  ['per_phone'],
                              onChanged: (val) => handleInputChange(
                                  'purchase_details.old_vehicle.per_phone',
                                  val),
                              keyboardType: TextInputType.phone,
                            ),
                            _buildTextField(
                              label: 'Cost',
                              value: formData['purchase_details']['old_vehicle']
                                  ['per_cost'],
                              onChanged: (val) => handleInputChange(
                                  'purchase_details.old_vehicle.per_cost', val),
                              keyboardType: TextInputType.number,
                            ),
                            _buildFileUploadField(
                              label: 'Aadhar Document',
                              field: 'per_adhurl',
                              fileName: fileNames['per_adhurl'],
                              hasExisting: formData['purchase_details']
                                      ['old_vehicle']['per_adhurl'] !=
                                  null,
                            ),
                            _buildFileUploadField(
                              label: 'Other Document',
                              field: 'per_doc',
                              fileName: fileNames['per_doc'],
                              hasExisting: formData['purchase_details']
                                      ['old_vehicle']['per_doc'] !=
                                  null,
                            ),
                          ],
                        ]),

                        const SizedBox(height: 16),

                        // Section 3: Expiry & Maintenance
                        _buildSection('Expiry & Maintenance', [
                          _buildDateField(
                            label: 'Insurance Expiry',
                            value: formData['expiry_details']
                                ['insurance_expiry'],
                            onChanged: (val) => handleInputChange(
                                'expiry_details.insurance_expiry', val),
                          ),
                          _buildDateField(
                            label: 'Pollution Expiry',
                            value: formData['expiry_details']
                                ['pollution_expiry'],
                            onChanged: (val) => handleInputChange(
                                'expiry_details.pollution_expiry', val),
                          ),
                          _buildDateField(
                            label: 'Maintenance Expiry',
                            value: formData['expiry_details']
                                ['maintenance_expiry'],
                            onChanged: (val) => handleInputChange(
                                'expiry_details.maintenance_expiry', val),
                          ),
                          _buildDateField(
                            label: 'Battery Expiry',
                            value: formData['expiry_details']['battery_expiry'],
                            onChanged: (val) => handleInputChange(
                                'expiry_details.battery_expiry', val),
                          ),
                          if (formData['vehicle_type'] != 'Bike') ...[
                            _buildTextField(
                              label: 'Wheel Balancing (KM)',
                              value: formData['expiry_details']
                                  ['wheel_balancing_expiry'],
                              onChanged: (val) => handleInputChange(
                                  'expiry_details.wheel_balancing_expiry', val),
                              keyboardType: TextInputType.number,
                            ),
                            _buildTextField(
                              label: 'Tyre Change (KM)',
                              value: formData['expiry_details']
                                  ['tyre_change_expiry'],
                              onChanged: (val) => handleInputChange(
                                  'expiry_details.tyre_change_expiry', val),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                          _buildTextField(
                            label: 'Current KM',
                            value: formData['current_km'],
                            onChanged: (val) =>
                                handleInputChange('current_km', val),
                            keyboardType: TextInputType.number,
                          ),
                        ]),

                        const SizedBox(height: 16),

                        // Section 4: Documents - RC Book is required
                        _buildSection('Document Uploads', [
                          _buildFileUploadField(
                            label: 'RC Book Document *',
                            field: 'rc_book',
                            fileName: fileNames['rc_book'],
                            hasExisting: formData['vehicle_details']
                                        ['rc_book_url']
                                    ?.isNotEmpty ==
                                true,
                            error: errors['rc_book'],
                          ),
                          _buildFileUploadField(
                            label: 'Insurance Document',
                            field: 'insurance',
                            fileName: fileNames['insurance'],
                            hasExisting: formData['vehicle_details']
                                        ['insurance_url']
                                    ?.isNotEmpty ==
                                true,
                          ),
                          _buildFileUploadField(
                            label: 'Pollution Certificate',
                            field: 'pollution',
                            fileName: fileNames['pollution'],
                            hasExisting: formData['vehicle_details']
                                        ['pollution_url']
                                    ?.isNotEmpty ==
                                true,
                          ),
                          _buildFileUploadField(
                            label: 'Battery Warranty Card',
                            field: 'battery_warranty',
                            fileName: fileNames['battery_warranty'],
                            hasExisting: formData['vehicle_details']
                                        ['battery_warranty_url']
                                    ?.isNotEmpty ==
                                true,
                          ),
                          _buildFileUploadField(
                            label: 'Maintenance Document',
                            field: 'maintenance',
                            fileName: fileNames['maintenance'],
                            hasExisting: formData['vehicle_details']
                                        ['maintenance_expiry_url']
                                    ?.isNotEmpty ==
                                true,
                          ),
                          if (formData['vehicle_type'] != 'Bike') ...[
                            _buildFileUploadField(
                              label: 'Tyre Document',
                              field: 'tyre',
                              fileName: fileNames['tyre'],
                              hasExisting: formData['vehicle_details']
                                          ['tyre_expiry_url']
                                      ?.isNotEmpty ==
                                  true,
                            ),
                            _buildFileUploadField(
                              label: 'Wheel Balancing Document',
                              field: 'wheel_balancing',
                              fileName: fileNames['wheel_balancing'],
                              hasExisting: formData['vehicle_details']
                                          ['wheel_expiry_url']
                                      ?.isNotEmpty ==
                                  true,
                            ),
                          ],
                          if (widget.isEditing)
                            _buildFileUploadField(
                              label: 'Status Document',
                              field: 'status_document',
                              fileName: fileNames['status_document'],
                              hasExisting: formData['vehicle_details']
                                          ['status_documents_url']
                                      ?.isNotEmpty ==
                                  true,
                            ),
                        ]),

                        const SizedBox(height: 16),

                        // Section 5: Additional Information
                        _buildSection('Additional Information', [
                          _buildDropdown(
                            label: 'Status',
                            value: formData['status'],
                            items: const [
                              'Active',
                              'Inactive',
                              'Scrap',
                              'Theft',
                              'Resale'
                            ],
                            onChanged: (val) =>
                                handleInputChange('status', val),
                          ),

                          // Resale Fields
                          if (formData['status'] == 'Resale') ...[
                            const Divider(),
                            const Text('Resale Details',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _buildDateField(
                              label: 'Date of Resale *',
                              value: formData['resale_details']
                                  ['date_of_resale'],
                              onChanged: (val) => handleInputChange(
                                  'resale_details.date_of_resale', val),
                              error: errors['date_of_resale'],
                            ),
                            _buildTextField(
                              label: 'Resale Amount *',
                              value: formData['resale_details']['sale_amount'],
                              onChanged: (val) => handleInputChange(
                                  'resale_details.sale_amount', val),
                              keyboardType: TextInputType.number,
                              error: errors['sale_amount'],
                            ),
                            _buildDropdown(
                              label: 'Payment Received',
                              value: formData['resale_details']
                                          ['pay_recieved'] ==
                                      true
                                  ? 'Bank'
                                  : 'Cash',
                              items: const ['Cash', 'Bank'],
                              onChanged: (val) => handleInputChange(
                                  'resale_details.pay_recieved', val == 'Bank'),
                            ),
                            _buildTextField(
                              label: 'Purchaser Name *',
                              value: formData['resale_details']
                                  ['purchaser_name'],
                              onChanged: (val) => handleInputChange(
                                  'resale_details.purchaser_name', val),
                              error: errors['purchaser_name'],
                            ),
                            _buildTextField(
                              label: 'Mobile Number',
                              value: formData['resale_details']['sale_mob_no'],
                              onChanged: (val) => handleInputChange(
                                  'resale_details.sale_mob_no', val),
                              keyboardType: TextInputType.phone,
                            ),
                            _buildTextField(
                              label: 'Aadhar Number',
                              value: formData['resale_details']['sale_adh'],
                              onChanged: (val) => handleInputChange(
                                  'resale_details.sale_adh', val),
                            ),
                            _buildFileUploadField(
                              label: 'Aadhar Document',
                              field: 'sale_adhurl',
                              fileName: fileNames['sale_adhurl'],
                              hasExisting: formData['resale_details']
                                      ['sale_adhurl'] !=
                                  null,
                            ),
                            _buildFileUploadField(
                              label: 'DC Copy',
                              field: 'sale_dc',
                              fileName: fileNames['sale_dc'],
                              hasExisting:
                                  formData['resale_details']['sale_dc'] != null,
                            ),
                          ],

                          // Theft Fields
                          if (formData['status'] == 'Theft') ...[
                            const Divider(),
                            const Text('Theft Details',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _buildDateField(
                              label: 'Date of Theft *',
                              value: formData['theft_details']['date_of_theft'],
                              onChanged: (val) => handleInputChange(
                                  'theft_details.date_of_theft', val),
                              error: errors['date_of_theft'],
                            ),
                            _buildTextField(
                              label: 'Place of Theft *',
                              value: formData['theft_details']
                                  ['place_of_theft'],
                              onChanged: (val) => handleInputChange(
                                  'theft_details.place_of_theft', val),
                              error: errors['place_of_theft'],
                            ),
                            _buildTextField(
                              label: 'Employee Name *',
                              value: formData['theft_details']['theft_name'],
                              onChanged: (val) => handleInputChange(
                                  'theft_details.theft_name', val),
                              error: errors['theft_name'],
                            ),
                            _buildTextField(
                              label: 'Employee Mobile Number',
                              value: formData['theft_details']['theft_mob_no'],
                              onChanged: (val) => handleInputChange(
                                  'theft_details.theft_mob_no', val),
                              keyboardType: TextInputType.phone,
                            ),
                            _buildFileUploadField(
                              label: 'FIR Document',
                              field: 'theft_FIRurl',
                              fileName: fileNames['theft_FIRurl'],
                              hasExisting: formData['theft_details']
                                      ['theft_FIRurl'] !=
                                  null,
                            ),
                          ],

                          // Scrap Fields
                          if (formData['status'] == 'Scrap') ...[
                            const Divider(),
                            const Text('Scrap Details',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _buildDateField(
                              label: 'Date of Scrap *',
                              value: formData['scrap_details']['date_of_scrap'],
                              onChanged: (val) => handleInputChange(
                                  'scrap_details.date_of_scrap', val),
                              error: errors['date_of_scrap'],
                            ),
                            _buildTextField(
                              label: 'Supplier Name *',
                              value: formData['scrap_details']['scr_name'],
                              onChanged: (val) => handleInputChange(
                                  'scrap_details.scr_name', val),
                              error: errors['scr_name'],
                            ),
                            _buildTextField(
                              label: 'Supplier Address *',
                              value: formData['scrap_details']['scr_address'],
                              onChanged: (val) => handleInputChange(
                                  'scrap_details.scr_address', val),
                              error: errors['scr_address'],
                            ),
                            _buildTextField(
                              label: 'Aadhar Number',
                              value: formData['scrap_details']['scrap_adh'],
                              onChanged: (val) => handleInputChange(
                                  'scrap_details.scrap_adh', val),
                            ),
                            _buildTextField(
                              label: 'Mobile Number',
                              value: formData['scrap_details']['scrap_mob_no'],
                              onChanged: (val) => handleInputChange(
                                  'scrap_details.scrap_mob_no', val),
                              keyboardType: TextInputType.phone,
                            ),
                            _buildFileUploadField(
                              label: 'Aadhar Card',
                              field: 'scrap_adhurl',
                              fileName: fileNames['scrap_adhurl'],
                              hasExisting: formData['scrap_details']
                                      ['scrap_adhurl'] !=
                                  null,
                            ),
                            _buildFileUploadField(
                              label: 'Scrap Photo',
                              field: 'scrap_photo',
                              fileName: fileNames['scrap_photo'],
                              hasExisting: formData['scrap_details']
                                      ['scrap_photo'] !=
                                  null,
                            ),
                            _buildFileUploadField(
                              label: 'Scrap Documents',
                              field: 'scrap_document',
                              fileName: fileNames['scrap_document'],
                              hasExisting: formData['scrap_details']
                                      ['scrap_document'] !=
                                  null,
                            ),
                          ],

                          const Divider(),
                          _buildTextField(
                            label: 'Remarks',
                            value: formData['remarks'],
                            onChanged: (val) =>
                                handleInputChange('remarks', val),
                            maxLines: 3,
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // Action Buttons
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: submitLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                      color: _primaryColor), // #4A4494 border
                                  foregroundColor:
                                      _primaryColor, // #4A4494 text
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: submitLoading
                                    ? null
                                    : () async {
                                        final validationErrors = validateForm();
                                        if (validationErrors.isNotEmpty) {
                                          setState(
                                              () => errors = validationErrors);
                                          _showErrorSnackBar(
                                              'Please fix the validation errors before submitting.');
                                          return;
                                        }
                                        await submitForm();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _primaryColor, // # background
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: Text(widget.isEditing
                                    ? 'Update Vehicle'
                                    : 'Create Vehicle'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Extra bottom padding
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // FIX 2: Loading overlay with proper styling and opacity
          if (submitLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        widget.isEditing
                            ? 'Updating Vehicle...'
                            : 'Creating Vehicle...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please wait while we save your changes',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String? value,
    required Function(String?) onChanged,
    String? error,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value,
            onChanged: onChanged,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              errorText: error,
              errorStyle: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    String? error,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: error != null ? Colors.red : Colors.grey.shade300,
                width: error != null ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item.isEmpty ? 'Select' : item),
                );
              }).toList(),
              onChanged: (val) => onChanged(val!),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required Function(String) onChanged,
    String? error,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    value.isNotEmpty ? DateTime.parse(value) : DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                onChanged(DateFormat('yyyy-MM-dd').format(date));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: error != null ? Colors.red : Colors.grey.shade300,
                  width: error != null ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.isNotEmpty ? value : 'dd-mm-yyyy',
                      style: TextStyle(
                        color: value.isNotEmpty ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today, size: 16),
                ],
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileUploadField({
    required String label,
    required String field,
    String? fileName,
    bool hasExisting = false,
    String? error,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: error != null ? Colors.red : null,
                ),
              ),
              if (fileUploads[field] != null)
                TextButton(
                  onPressed: () => handleFileReset(field),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                  ),
                  child: const Text('Reset',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _pickImage(field),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: error != null ? Colors.red : Colors.grey.shade300,
                  width: error != null ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName ?? 'No file chosen',
                      style: TextStyle(
                        color: fileName != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(Icons.attach_file, size: 16),
                ],
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ),
          if (hasExisting && fileUploads[field] == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '✓ Document exists',
                style: const TextStyle(color: Colors.green, fontSize: 11),
              ),
            ),
          if (fileUploads[field] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '✓ New file selected',
                style: const TextStyle(color: Colors.green, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'User Name',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  Checkbox(
                    value: autoFillUser,
                    onChanged: (val) {
                      setState(() => autoFillUser = val ?? false);
                      if (val == true) {
                        handleInputChange('user_name', 'Admin');
                        handleInputChange('user_id', '001');
                      } else {
                        handleInputChange('user_name', '');
                        handleInputChange('user_id', '');
                      }
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Text('Auto-fill as Admin',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: formData['user_name'],
            onChanged: (val) => handleInputChange('user_name', val),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          if (formData['user_id']?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text(
                    'User ID: ${formData['user_id']}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFuelTypeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fuel Type',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: ['Petrol', 'Diesel', 'CNG', 'Electric'].map((fuel) {
              final isSelected =
                  (formData['vehicle_details']['fuel_type'] as List)
                      .contains(fuel);
              return FilterChip(
                label: Text(fuel),
                selected: isSelected,
                onSelected: (selected) => handleFuelTypeChange(fuel, selected),
                backgroundColor: Colors.grey.shade100,
                selectedColor: AppTheme.secondary.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.secondary,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.secondary : Colors.black,
                  fontSize: 12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          const Text(
            'Note: Only the first selected fuel type will be submitted',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseTypeField() {
    final display = getStatusDisplay(formData['purchase_type']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vehicle Purchase Type',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    getStatusDescription(formData['purchase_type']),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Click to cycle:', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isTogglingPurchase ? null : cyclePurchaseType,
                    child: Container(
                      width: 64,
                      height: 24,
                      decoration: BoxDecoration(
                        color: formData['purchase_type'] == 'NEW'
                            ? Colors.green
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            left: formData['purchase_type'] == 'NEW' ? 4 : 36,
                            top: 4,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 6,
                            child: Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 10,
                                color: formData['purchase_type'] == 'NEW'
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 6,
                            child: Text(
                              'OLD',
                              style: TextStyle(
                                fontSize: 10,
                                color: formData['purchase_type'] == 'OLD'
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: formData['purchase_type'] == 'NEW'
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
              Text(
                'OLD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: formData['purchase_type'] == 'OLD'
                      ? Colors.orange
                      : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  display['bgColor'] as Color? ?? Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: display['borderColor'] as Color? ?? Colors.green,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  display['icon'] as IconData? ?? Icons.info,
                  color: display['iconColor'] as Color? ?? Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Purchase Type: ${display['text']}',
                  style: TextStyle(
                    color: display['textColor'] as Color? ?? Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
