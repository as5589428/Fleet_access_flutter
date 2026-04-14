import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/collection_delivery_model.dart';
import '../../services/collection_delivery_service.dart';

class CollectionDeliveryFormScreen extends StatefulWidget {
  final CollectionDeliveryModel? entry;
  final bool isEditing;

  const CollectionDeliveryFormScreen({
    super.key,
    this.entry,
    this.isEditing = false,
  });

  @override
  State<CollectionDeliveryFormScreen> createState() =>
      _CollectionDeliveryFormScreenState();
}

class _CollectionDeliveryFormScreenState
    extends State<CollectionDeliveryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CollectionDeliveryService();
  final _picker = ImagePicker();

  bool _isSubmitting = false;
  bool _fillEmployeeTaskData = true;

  // ───────────────── Section 0: Basic Info ─────────────────
  String _collectionType = 'collection';
  DateTime? _collectionDate;
  String? _plantId;
  String? _selectedClient;
  String? _contactPerson;
  String? _collectionRoute;
  String? _transferMode;
  String? _employeeAssigned;
  String _paymentCollection = 'No';
  final _instrumentCountCtrl = TextEditingController();

  // ───────────────── Section 1: DC & Item Details ─────────────────
  final _dcNumberCtrl = TextEditingController();
  final _qtyInDcCtrl = TextEditingController();
  final _qtyCollectedCtrl = TextEditingController();
  File? _dcImageFile;
  String? _instrumentId;
  final List<String> _enclosures =
      []; // Manual, Accessories, Drawing, Others, Nil

  // ───────────────── Section 2: Calibration Requirements ─────────────────
  String _requireStatement = 'No';
  String _specificDecision = 'No';
  String _serviceIfBad = 'No';
  String _witnessCalibration = 'No';
  String _nextDueDate = 'No';
  String _specificCalibPoint = 'No';
  final _remarksIfNotCollectedCtrl = TextEditingController();
  final _dcRemarksCtrl = TextEditingController();
  final _escalationRemarksCtrl = TextEditingController();
  final _instrumentIdSourceCtrl = TextEditingController();
  String _paymentCollected = 'No';
  File? _paymentPhotoFile;

  // ───────────────── Section 3: Travel & Performance ─────────────────
  String? _collectedBy;
  final _startKmCtrl = TextEditingController();
  File? _startKmPhotoFile;
  final _endKmCtrl = TextEditingController();
  File? _endKmPhotoFile;
  final _specialRemarksCtrl = TextEditingController();
  final _collectionModeCtrl = TextEditingController();
  int _employeeRating = 1;
  String _taskStatus = 'Pending';

  static const _primaryColor = Color(0xFF4A4494);

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.entry != null) {
      _loadExistingData();
    }
  }

  @override
  void dispose() {
    _instrumentCountCtrl.dispose();
    _dcNumberCtrl.dispose();
    _qtyInDcCtrl.dispose();
    _qtyCollectedCtrl.dispose();
    _remarksIfNotCollectedCtrl.dispose();
    _startKmCtrl.dispose();
    _endKmCtrl.dispose();
    _specialRemarksCtrl.dispose();
    _dcRemarksCtrl.dispose();
    _escalationRemarksCtrl.dispose();
    _instrumentIdSourceCtrl.dispose();
    _collectionModeCtrl.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final e = widget.entry!;
    _collectionType = (e.collectionType ?? 'collection').toLowerCase();
    _collectionDate =
        e.collectionDate != null ? DateTime.tryParse(e.collectionDate!) : null;
    _plantId = e.plantId;
    _selectedClient = e.selectedClient;
    _contactPerson = e.contactPerson;
    _collectionRoute = e.collectionRoute;
    _transferMode = e.transferMode;
    _employeeAssigned = e.employeeAssigned;
    _paymentCollection = _capitalize(e.paymentCollection ?? 'No');
    _instrumentCountCtrl.text = e.instrumentCount?.toString() ?? '';
    _dcNumberCtrl.text = e.dcNumber ?? '';
    _qtyInDcCtrl.text = e.qtyMentionedInDc ?? '';
    _qtyCollectedCtrl.text = e.qtyCollected ?? '';
    _instrumentId = e.instrumentId;
    if (e.enclosures != null) _enclosures.addAll(e.enclosures!);
    _requireStatement = _capitalize(e.requireStatementOfConformity ?? 'No');
    _specificDecision = _capitalize(e.specificDecisionRule ?? 'No');
    _serviceIfBad = _capitalize(e.serviceIfBadCondition ?? 'No');
    _witnessCalibration = _capitalize(e.witnessCalibration ?? 'No');
    _nextDueDate = _capitalize(e.nextDueDateRequired ?? 'No');
    _specificCalibPoint = _capitalize(e.specificCalibrationPoint ?? 'No');
    _remarksIfNotCollectedCtrl.text = e.remarksIfNotCollected ?? '';
    _paymentCollected = _capitalize(e.paymentCollected ?? 'No');
    _collectedBy = e.collectedBy;
    _startKmCtrl.text = e.startKm ?? '';
    _endKmCtrl.text = e.endKm ?? '';
    _specialRemarksCtrl.text = e.specialRemarks ?? '';
    _dcRemarksCtrl.text = e.dcRemarks ?? '';
    _escalationRemarksCtrl.text = e.escalationRemarks ?? '';
    _instrumentIdSourceCtrl.text = e.instrumentIdSource ?? '';
    _collectionModeCtrl.text = e.collectionMode ?? e.transferMode ?? '';
    _employeeRating = e.employeeRating ?? 1;
    _taskStatus = _capitalize(e.taskStatus ?? 'Pending');
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _collectionDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _collectionDate = picked);
    }
  }

  Future<void> _pickFile(String type) async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) {
      return;
    }
    setState(() {
      if (type == 'dc') _dcImageFile = File(img.path);
      if (type == 'startKm') _startKmPhotoFile = File(img.path);
      if (type == 'endKm') _endKmPhotoFile = File(img.path);
      if (type == 'payment') _paymentPhotoFile = File(img.path);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_collectionDate == null) {
      _showSnackBar('Please select a collection date', Colors.red);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final model = CollectionDeliveryModel(
        collectionType: _collectionType,
        collectionDate: _collectionDate!.toIso8601String(),
        plantId: _plantId,
        selectedClient: _selectedClient,
        contactPerson: _contactPerson,
        collectionRoute: _collectionRoute,
        instrumentCount: int.tryParse(_instrumentCountCtrl.text),
        transferMode: _transferMode,
        employeeAssigned: _employeeAssigned,
        paymentCollection: _paymentCollection,
        status: 'pending',
        dcNumber: _dcNumberCtrl.text,
        qtyMentionedInDc: _qtyInDcCtrl.text,
        qtyCollected: _qtyCollectedCtrl.text,
        instrumentId: _instrumentId,
        enclosures: List.from(_enclosures),
        requireStatementOfConformity: _requireStatement,
        specificDecisionRule: _specificDecision,
        serviceIfBadCondition: _serviceIfBad,
        witnessCalibration: _witnessCalibration,
        nextDueDateRequired: _nextDueDate,
        specificCalibrationPoint: _specificCalibPoint,
        remarksIfNotCollected: _remarksIfNotCollectedCtrl.text,
        paymentCollected: _paymentCollected,
        collectedBy: _collectedBy,
        startKm: _startKmCtrl.text,
        endKm: _endKmCtrl.text,
        specialRemarks: _specialRemarksCtrl.text,
        dcRemarks: _dcRemarksCtrl.text,
        escalationRemarks: _escalationRemarksCtrl.text,
        instrumentIdSource: _instrumentIdSourceCtrl.text,
        collectionMode: _collectionModeCtrl.text,
        employeeRating: _employeeRating,
        taskStatus: _taskStatus,
      );

      if (widget.isEditing && widget.entry?.id != null) {
        model.id = widget.entry!.id;
        model.companyId = widget.entry!.companyId;

        await _service.updateEntry(
          id: widget.entry!.id!,
          model: model,
          dcImage: _dcImageFile,
          startKmPhoto: _startKmPhotoFile,
          endKmPhoto: _endKmPhotoFile,
          paymentPhoto: _paymentPhotoFile,
        );
        _showSnackBar('Entry updated successfully', Colors.green);
      } else {
        await _service.createEntry(
          model: model,
          dcImage: _dcImageFile,
          startKmPhoto: _startKmPhotoFile,
          endKmPhoto: _endKmPhotoFile,
          paymentPhoto: _paymentPhotoFile,
        );
        _showSnackBar('Entry created successfully', Colors.green);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg, style: const TextStyle(color: Colors.white)),
          backgroundColor: color),
    );
  }

  // ─────────── Build Helpers ───────────

  InputDecoration _inputDec(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _primaryColor, width: 2)),
        filled: true,
        fillColor: Colors.white,
      );

  Widget _label(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Flexible(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151)),
                overflow: TextOverflow.ellipsis,
                maxLines: 2),
          ),
          if (required) const Text(' *', style: TextStyle(color: Colors.red)),
        ]),
      );

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool required = false,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label, required: required),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: _inputDec(''),
          validator: required ? (v) => v == null ? 'Required' : null : null,
        ),
      ]);

  Widget _textField({
    required String label,
    required TextEditingController ctrl,
    String hint = '',
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label, required: required),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: _inputDec(hint),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      ]);

  Widget _filePickerTile(String label, File? file, String type) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      InkWell(
        onTap: () => _pickFile(type),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.upload, size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(file != null ? file.path.split('/').last : 'Choose file',
                style: TextStyle(
                    color:
                        file != null ? _primaryColor : const Color(0xFF6B7280),
                    fontSize: 13)),
          ]),
        ),
      ),
    ]);
  }

  Widget _sectionHeader(String title) => Container(
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
        child: Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827))),
      );

  Widget _twoCol(Widget left, Widget right) => LayoutBuilder(
        builder: (context, c) => c.maxWidth > 500
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: left),
                const SizedBox(width: 16),
                Expanded(child: right),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                left,
                const SizedBox(height: 14),
                right,
              ]),
      );

  Widget _threeCol(Widget a, Widget b, Widget c) => LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth > 700
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: a),
                const SizedBox(width: 12),
                Expanded(child: b),
                const SizedBox(width: 12),
                Expanded(child: c),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                a,
                const SizedBox(height: 14),
                b,
                const SizedBox(height: 14),
                c,
              ]),
      );

  // ─────────── Sections ───────────

  Widget _buildBasicInfo() {
    if (widget.isEditing) {
      return const SizedBox.shrink();
    }
    return _card(Column(children: [
      _twoCol(
        _dropdownField(
          label: 'Collection / Delivery',
          value: _collectionType,
          items: const [
            DropdownMenuItem(value: 'collection', child: Text('Collection')),
            DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
          ],
          onChanged: (v) => setState(() => _collectionType = v ?? 'collection'),
        ),
        GestureDetector(
          onTap: _pickDate,
          child: AbsorbPointer(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Date to be Collected', required: true),
              TextFormField(
                readOnly: true,
                decoration: _inputDec(
                  _collectionDate == null
                      ? 'dd-mm-yyyy'
                      : DateFormat('dd-MM-yyyy').format(_collectionDate!),
                  suffix: const Icon(Icons.calendar_today,
                      size: 18, color: Color(0xFF6B7280)),
                ),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 14),
      _twoCol(
        _textField(
            label: 'Plant Name',
            ctrl: TextEditingController(text: _plantId),
            hint: 'Enter plant name'),
        _textField(
            label: 'Client',
            ctrl: TextEditingController(text: _selectedClient),
            hint: 'Enter client'),
      ),
      const SizedBox(height: 14),
      _twoCol(
        _textField(
            label: 'Contact Person',
            ctrl: TextEditingController(text: _contactPerson),
            hint: 'Enter contact person'),
        _textField(
            label: 'Collection Route',
            ctrl: TextEditingController(text: _collectionRoute),
            hint: 'Enter route'),
      ),
      const SizedBox(height: 14),
      _twoCol(
        _textField(
            label: 'No. of Instruments',
            ctrl: _instrumentCountCtrl,
            hint: 'Enter count',
            keyboardType: TextInputType.number),
        _dropdownField(
          label: 'Payment if any to be collected',
          value: _paymentCollection,
          items: const [
            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
            DropdownMenuItem(value: 'No', child: Text('No')),
          ],
          onChanged: (v) => setState(() => _paymentCollection = v ?? 'No'),
        ),
      ),
      const SizedBox(height: 16),
      if (!widget.isEditing)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fill Employee Task Data',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                        'Enable this to manually input the data normally collected by the employee via the app.',
                        style: TextStyle(
                            color: Colors.blue.shade700, fontSize: 12)),
                  ]),
            ),
            const SizedBox(width: 12),
            DropdownButton<bool>(
              value: _fillEmployeeTaskData,
              items: const [
                DropdownMenuItem(value: true, child: Text('Yes')),
                DropdownMenuItem(value: false, child: Text('No')),
              ],
              onChanged: (v) =>
                  setState(() => _fillEmployeeTaskData = v ?? true),
              style: const TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ]),
        ),
    ]));
  }

  Widget _buildDcDetails() {
    if (!widget.isEditing && !_fillEmployeeTaskData) {
      return const SizedBox.shrink();
    }
    return _card(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('1. DC & Item Details'),
      const SizedBox(height: 14),
      _threeCol(
        _textField(
            label: 'DC Number', ctrl: _dcNumberCtrl, hint: 'Enter DC Number'),
        _textField(
            label: 'Qty mentioned in DC',
            ctrl: _qtyInDcCtrl,
            hint: 'Enter Qty mentioned in DC'),
        _textField(
            label: 'Qty Collected',
            ctrl: _qtyCollectedCtrl,
            hint: 'Enter Qty Collected'),
      ),
      const SizedBox(height: 14),
      _twoCol(
        _filePickerTile('Upload DC Image', _dcImageFile, 'dc'),
        _textField(
            label: 'Instrument Id Source',
            ctrl: _instrumentIdSourceCtrl,
            hint: 'Select Instrument Id Source'),
      ),
      const SizedBox(height: 14),
      _twoCol(
        !widget.isEditing
            ? _textField(
                label: 'Instrument Id',
                ctrl: TextEditingController(text: _instrumentId),
                hint: 'Select Instrument Id')
            : const SizedBox.shrink(),
        _textField(
            label: 'DC Remarks',
            ctrl: _dcRemarksCtrl,
            hint: 'Enter DC Remarks'),
      ),
      const SizedBox(height: 14),
      _label('List of enclosures along with SRF'),
      Wrap(
        spacing: 12,
        runSpacing: 4,
        children:
            ['Manual', 'Accessories', 'Drawing', 'Others', 'Nil'].map((e) {
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Checkbox(
              value: _enclosures.contains(e),
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  _enclosures.add(e);
                } else {
                  _enclosures.remove(e);
                }
              }),
              activeColor: _primaryColor,
            ),
            Text(e, style: const TextStyle(fontSize: 13)),
          ]);
        }).toList(),
      ),
    ]));
  }

  Widget _buildCalibration() {
    if (!widget.isEditing && !_fillEmployeeTaskData) {
      return const SizedBox.shrink();
    }
    return _card(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('2. Calibration Requirements'),
      const SizedBox(height: 14),
      _threeCol(
        _yesNoDropdown('Require Statement of Conformity?', _requireStatement,
            (v) => setState(() => _requireStatement = v ?? 'No')),
        _yesNoDropdown('Specific Decision Rule applied?', _specificDecision,
            (v) => setState(() => _specificDecision = v ?? 'No')),
        _yesNoDropdown('Service if item is in bad condition?', _serviceIfBad,
            (v) => setState(() => _serviceIfBad = v ?? 'No')),
      ),
      const SizedBox(height: 14),
      _threeCol(
        _yesNoDropdown('Witness the Calibration?', _witnessCalibration,
            (v) => setState(() => _witnessCalibration = v ?? 'No')),
        _yesNoDropdown('Next due date required in report?', _nextDueDate,
            (v) => setState(() => _nextDueDate = v ?? 'No')),
        _yesNoDropdown('Specific calibration point?', _specificCalibPoint,
            (v) => setState(() => _specificCalibPoint = v ?? 'No')),
      ),
      const SizedBox(height: 14),
      _twoCol(
        !widget.isEditing
            ? _textField(
                label: 'Remarks if item not Collected',
                ctrl: _remarksIfNotCollectedCtrl,
                hint: 'Enter Remarks if item not Collected',
                maxLines: 2)
            : const SizedBox.shrink(),
        Column(children: [
          _yesNoDropdown('Payment Collected?', _paymentCollected,
              (v) => setState(() => _paymentCollected = v ?? 'No')),
          if (_paymentCollected == 'Yes') ...[
            const SizedBox(height: 12),
            _filePickerTile('Payment Photo', _paymentPhotoFile, 'payment'),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      _textField(
          label: 'Escalation Remarks',
          ctrl: _escalationRemarksCtrl,
          hint: 'Enter Escalation Remarks',
          maxLines: 2),
    ]));
  }

  Widget _yesNoDropdown(
          String label, String value, ValueChanged<String?> onChanged) =>
      _dropdownField(
        label: label,
        value: value,
        items: const [
          DropdownMenuItem(value: 'Yes', child: Text('Yes')),
          DropdownMenuItem(value: 'No', child: Text('No')),
        ],
        onChanged: onChanged,
      );

  Widget _buildTravelPerformance() {
    if (!widget.isEditing && !_fillEmployeeTaskData) {
      return const SizedBox.shrink();
    }
    return _card(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('3. Travel & Performance'),
      const SizedBox(height: 14),
      // Row 1: Collected By + Start KM + Start KM Photo
      LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        return isWide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!widget.isEditing) ...[
                  Expanded(
                      child: _textField(
                          label: 'Collected By',
                          ctrl: TextEditingController(text: _collectedBy),
                          hint: 'Select Collected By')),
                  const SizedBox(width: 12),
                ],
                Expanded(
                    child: _textField(
                        label: 'Start KM',
                        ctrl: _startKmCtrl,
                        hint: 'Enter Start KM',
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                    child: _filePickerTile(
                        'Start KM Photo', _startKmPhotoFile, 'startKm')),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!widget.isEditing) ...[
                  _textField(
                      label: 'Collected By',
                      ctrl: TextEditingController(text: _collectedBy),
                      hint: 'Select Collected By'),
                  const SizedBox(height: 12),
                ],
                _textField(
                    label: 'Start KM',
                    ctrl: _startKmCtrl,
                    hint: 'Enter Start KM',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _filePickerTile('Start KM Photo', _startKmPhotoFile, 'startKm'),
              ]);
      }),
      const SizedBox(height: 12),
      // Row 2: End KM + End KM Photo
      LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        return isWide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: _textField(
                        label: 'End KM',
                        ctrl: _endKmCtrl,
                        hint: 'Enter End KM',
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                    child: _filePickerTile(
                        'End KM Photo', _endKmPhotoFile, 'endKm')),
                const Expanded(child: SizedBox()), // spacer
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _textField(
                    label: 'End KM',
                    ctrl: _endKmCtrl,
                    hint: 'Enter End KM',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _filePickerTile('End KM Photo', _endKmPhotoFile, 'endKm'),
              ]);
      }),
      _twoCol(
        _textField(
            label: 'Collection Mode',
            ctrl: _collectionModeCtrl,
            hint: 'Enter mode'),
        const SizedBox.shrink(), // Placeholder to keep layout consistent
      ),
      const SizedBox(height: 14),
      _threeCol(
        _textField(
            label: 'Special Remarks',
            ctrl: _specialRemarksCtrl,
            hint: 'Enter Special Remarks',
            maxLines: 2),
        !widget.isEditing
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Employee Rating (1-5)'),
                DropdownButtonFormField<int>(
                  initialValue: _employeeRating,
                  items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                          value: i + 1, child: Text('${i + 1}'))),
                  onChanged: (v) => setState(() => _employeeRating = v ?? 1),
                  decoration: _inputDec(''),
                ),
              ])
            : const SizedBox.shrink(),
        !widget.isEditing
            ? _dropdownField(
                label: 'Select Status',
                value: _taskStatus,
                items: const [
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(
                      value: 'Completed', child: Text('Completed')),
                ],
                onChanged: (v) => setState(() => _taskStatus = v ?? 'Pending'),
              )
            : const SizedBox.shrink(),
      ),
    ]));
  }

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Task Entry' : 'Create New Task Entry',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _buildBasicInfo(),
            _buildDcDetails(),
            _buildCalibration(),
            _buildTravelPerformance(),

            // Action Buttons
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.pop(context),
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
                    backgroundColor: _primaryColor,
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
                      : Text(widget.isEditing ? 'Update' : 'Submit',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
            ]),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
