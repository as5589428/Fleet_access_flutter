import 'package:flutter/material.dart';

class VehicleForm extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onSubmit;
  final Map<String, dynamic>? initialData;
  final bool isEdit;
  final bool loading;

  const VehicleForm({
    super.key,
    this.onSubmit,
    this.initialData,
    this.isEdit = false,
    this.loading = false,
  });

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> formData;
  Map<String, String> errors = {};

  static const List<String> vehicleTypes = ['Car', 'Bike'];
  static const List<String> ownershipTypes = ['Owned', 'Office'];
  static const List<String> vehicleStatus = ['Active', 'Resale', 'Theft'];

  @override
  void initState() {
    super.initState();
    formData = Map<String, dynamic>.from(widget.initialData ?? {});
  }

  void handleChange(String key, dynamic value) {
    setState(() {
      formData[key] = value;
    });
  }

  void handleSubmit() {
    errors.clear();
    if (!_formKey.currentState!.validate()) {
      setState(() {});
      return;
    }
    widget.onSubmit?.call(formData);
  }

  String? validateField(String key, String? value) {
    if (key == 'vehicle_number' && (value == null || value.isEmpty)) {
      return 'Vehicle number is required';
    }
    if (key == 'vehicle_type' && (value == null || value.isEmpty)) {
      return 'Vehicle type is required';
    }
    if (key == 'ownership_type' && (value == null || value.isEmpty)) {
      return 'Ownership type is required';
    }
    if (key == 'user_name' && (value == null || value.isEmpty)) {
      return 'User name is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information
            Text('Basic Information',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Vehicle Number *'),
              initialValue: formData['vehicle_number'] ?? '',
              enabled: !widget.isEdit,
              validator: (v) => validateField('vehicle_number', v),
              onChanged: (v) => handleChange('vehicle_number', v),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Vehicle Type *'),
              initialValue: formData['vehicle_type'],
              items: vehicleTypes
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              validator: (v) => validateField('vehicle_type', v),
              onChanged: (v) => handleChange('vehicle_type', v),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Ownership Type *'),
              initialValue: formData['ownership_type'],
              items: ownershipTypes
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              validator: (v) => validateField('ownership_type', v),
              onChanged: (v) => handleChange('ownership_type', v),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'User Name *'),
              initialValue: formData['user_name'] ?? '',
              validator: (v) => validateField('user_name', v),
              onChanged: (v) => handleChange('user_name', v),
            ),
            const SizedBox(height: 16),
            // Vehicle Details
            Text('Vehicle Details',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Brand'),
              initialValue: formData['brand'] ?? '',
              onChanged: (v) => handleChange('brand', v),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Model'),
              initialValue: formData['model'] ?? '',
              onChanged: (v) => handleChange('model', v),
            ),
            const SizedBox(height: 16),
            // Status Section
            Text('Status Information',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Status'),
              initialValue: formData['status'] ?? 'Active',
              items: vehicleStatus
                  .map((status) =>
                      DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (v) => handleChange('status', v),
            ),
            if (formData['status'] == 'Theft') ...[
              const SizedBox(height: 8),
              Text('Theft Details',
                  style: Theme.of(context).textTheme.titleSmall),
              // Add theft detail fields here
            ],
            if (formData['status'] == 'Resale') ...[
              const SizedBox(height: 8),
              Text('Resale Details',
                  style: Theme.of(context).textTheme.titleSmall),
              // Add resale detail fields here
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.loading ? null : handleSubmit,
                child: Text(widget.loading
                    ? 'Saving...'
                    : (widget.isEdit ? 'Update Vehicle' : 'Create Vehicle')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
