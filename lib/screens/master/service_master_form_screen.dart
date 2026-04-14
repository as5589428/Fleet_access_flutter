import 'package:flutter/material.dart';
import '../../models/service_master_model.dart';
import '../../services/service_master_service.dart';

class ServiceMasterFormScreen extends StatefulWidget {
  final ServiceMasterModel? service;
  final bool isEditing;

  const ServiceMasterFormScreen({
    super.key,
    this.service,
    this.isEditing = false,
  });

  @override
  State<ServiceMasterFormScreen> createState() =>
      _ServiceMasterFormScreenState();
}

class _ServiceMasterFormScreenState extends State<ServiceMasterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceMasterService = ServiceMasterService();

  bool _isLoading = false;

  final TextEditingController _serviceCenterNameController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactPersonNameController =
      TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _landlineNumberController =
      TextEditingController();
  final TextEditingController _emailIdPersonalController =
      TextEditingController();
  final TextEditingController _emailIdOfficeController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.service != null) {
      _serviceCenterNameController.text =
          widget.service!.serviceCenterName ?? '';
      _addressController.text = widget.service!.address ?? '';
      _contactPersonNameController.text =
          widget.service!.contactPersonName ?? '';
      _designationController.text = widget.service!.designation ?? '';
      _mobileNumberController.text = widget.service!.mobileNumber ?? '';
      _landlineNumberController.text = widget.service!.landlineNumber ?? '';
      _emailIdPersonalController.text = widget.service!.emailIdPersonal ?? '';
      _emailIdOfficeController.text = widget.service!.emailIdOffice ?? '';
    }
  }

  @override
  void dispose() {
    _serviceCenterNameController.dispose();
    _addressController.dispose();
    _contactPersonNameController.dispose();
    _designationController.dispose();
    _mobileNumberController.dispose();
    _landlineNumberController.dispose();
    _emailIdPersonalController.dispose();
    _emailIdOfficeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final serviceData = ServiceMasterModel(
        id: widget.isEditing ? widget.service!.id : null,
        serviceCenterName: _serviceCenterNameController.text.trim(),
        address: _addressController.text.trim(),
        contactPersonName: _contactPersonNameController.text.trim(),
        designation: _designationController.text.trim(),
        mobileNumber: _mobileNumberController.text.trim(),
        landlineNumber: _landlineNumberController.text.trim(),
        emailIdPersonal: _emailIdPersonalController.text.trim(),
        emailIdOffice: _emailIdOfficeController.text.trim(),
      );

      if (widget.isEditing) {
        await _serviceMasterService.updateService(
            widget.service!.id!, serviceData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Service center updated successfully!',
                    style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.green),
          );
        }
      } else {
        await _serviceMasterService.createService(serviceData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Service center created successfully!',
                    style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.green),
          );
        }
      }

      if (mounted) {
        Navigator.pop(
            context, true); // Return true to indicate successful submit
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}',
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _buildInputDecoration(String label,
      {String? hintText, IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: const Color(0xFF4A4494))
          : null,
      labelStyle: const TextStyle(color: Colors.black87),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4A4494), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine layout based on width
                bool isWide = constraints.maxWidth > 600;

                if (isWide) {
                  // Wide layout (e.g. tablet), use Grid
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3, // Adjust aspect ratio as needed
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: children,
                  );
                } else {
                  // Narrow layout (e.g. phone), use Column
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < children.length; i++) ...[
                        children[i],
                        if (i < children.length - 1) const SizedBox(height: 16),
                      ],
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Service Center' : 'Add New Service Center',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF4A4494),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSection('Basic Information', [
                  TextFormField(
                    controller: _serviceCenterNameController,
                    decoration: _buildInputDecoration(
                      'Service Center Name *',
                      hintText: 'e.g., ABC Motors',
                      prefixIcon: Icons.store,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Service center name is required';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: _buildInputDecoration(
                      'Address',
                      hintText: 'e.g., Chennai',
                      prefixIcon: Icons.location_on,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.next,
                  ),
                ]),
                _buildSection('Contact Person Details', [
                  TextFormField(
                    controller: _contactPersonNameController,
                    decoration: _buildInputDecoration(
                      'Contact Person Name',
                      hintText: 'e.g., Ramesh',
                      prefixIcon: Icons.person,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  TextFormField(
                    controller: _designationController,
                    decoration: _buildInputDecoration(
                      'Designation',
                      hintText: 'e.g., Manager',
                      prefixIcon: Icons.badge,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ]),
                _buildSection('Contact Information', [
                  TextFormField(
                    controller: _mobileNumberController,
                    decoration: _buildInputDecoration(
                      'Mobile Number *',
                      hintText: '9876543210',
                      prefixIcon: Icons.phone_android,
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Mobile number is required';
                      }
                      if (value.trim().length != 10 ||
                          !RegExp(r'^\d+$').hasMatch(value)) {
                        return 'Mobile number must be 10 digits';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  TextFormField(
                    controller: _landlineNumberController,
                    decoration: _buildInputDecoration(
                      'Landline Number',
                      hintText: '044-12345678',
                      prefixIcon: Icons.phone,
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final numberStr =
                            value.replaceAll(RegExp(r'[-\s]'), '');
                        if (numberStr.length < 10 ||
                            !RegExp(r'^\d+$').hasMatch(numberStr)) {
                          return 'Invalid landline number';
                        }
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailIdPersonalController,
                    decoration: _buildInputDecoration(
                      'Personal Email',
                      hintText: 'ramesh@gmail.com',
                      prefixIcon: Icons.email,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                          return 'Invalid email format';
                        }
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailIdOfficeController,
                    decoration: _buildInputDecoration(
                      'Office Email',
                      hintText: 'office@company.com',
                      prefixIcon: Icons.business_center,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                          return 'Invalid email format';
                        }
                      }
                      return null;
                    },
                  ),
                ]),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A4494),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.isEditing
                      ? 'Update Service Center'
                      : 'Create Service Center',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
