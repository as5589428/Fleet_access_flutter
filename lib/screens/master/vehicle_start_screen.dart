import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vehicle_start_model.dart';
import '../../services/vehicle_start_service.dart';
import 'vehicle_start_form_screen.dart';
import '../../core/theme/app_theme.dart';
// import 'package:url_launcher/url_launcher.dart'; // Optional: for opening URLs directly

class VehicleStartScreen extends StatefulWidget {
  const VehicleStartScreen({super.key});

  @override
  State<VehicleStartScreen> createState() => _VehicleStartScreenState();
}

class _VehicleStartScreenState extends State<VehicleStartScreen> {
  final VehicleStartService _service = VehicleStartService();
  List<VehicleStartModel> _entries = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final entries = await _service.getAllStartEntries();
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteEntry(String id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this vehicle start entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteStartEntry(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Entry deleted successfully',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green),
        );
        _fetchEntries();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete: $e',
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToForm({VehicleStartModel? entry}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleStartFormScreen(
          startEntry: entry,
          isEditing: entry != null,
        ),
      ),
    );

    if (result == true) {
      _fetchEntries();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Widget _buildEntriesList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.secondary));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              'Failed to load entries',
              style: TextStyle(color: Colors.red.shade700, fontSize: 16),
            ),
            Text(_errorMessage,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchEntries,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.car_crash_outlined, color: Colors.grey, size: 60),
            const SizedBox(height: 16),
            const Text(
              'No start entries found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get started by adding a new vehicle start entry.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToForm(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Vehicle Start',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return _buildWebTable();
        } else {
          return _buildMobileList();
        }
      },
    );
  }

  Widget _buildWebTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                margin: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.resolveWith(
                        (states) => AppTheme.secondary),
                    headingTextStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    dataRowMaxHeight: 60,
                    columns: const [
                      DataColumn(label: Text('Vehicle Number')),
                      DataColumn(label: Text('Start KM')),
                      DataColumn(label: Text('Created Date')),
                      DataColumn(label: Text('Photos')),
                      DataColumn(label: Text('Map Upload')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: List.generate(_entries.length, (index) {
                      final entry = _entries[index];
                      return DataRow(
                        cells: [
                          DataCell(Text(entry.vehicleNumber ?? 'N/A',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                          DataCell(Text(entry.startKm ?? 'N/A')),
                          DataCell(Text(_formatDate(entry.createdAt))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (entry.startPhotos?.isNotEmpty ?? false)
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      (entry.startPhotos?.isNotEmpty ?? false)
                                          ? Colors.blue.shade200
                                          : Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt,
                                    size: 14,
                                    color:
                                        (entry.startPhotos?.isNotEmpty ?? false)
                                            ? Colors.blue
                                            : Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  (entry.startPhotos?.isNotEmpty ?? false)
                                      ? 'View ${entry.startPhotos!.length} Photos'
                                      : 'No Photos',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: (entry.startPhotos?.isNotEmpty ??
                                              false)
                                          ? Colors.blue
                                          : Colors.grey),
                                ),
                              ],
                            ),
                          )),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: entry.locationConfirmed == true
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: entry.locationConfirmed == true
                                      ? Colors.green.shade200
                                      : Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map,
                                    size: 14,
                                    color: entry.locationConfirmed == true
                                        ? Colors.green
                                        : Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  entry.locationConfirmed == true
                                      ? 'View Map'
                                      : 'No Map',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: entry.locationConfirmed == true
                                          ? Colors.green
                                          : Colors.grey),
                                ),
                              ],
                            ),
                          )),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _navigateToForm(entry: entry),
                                    tooltip: 'Edit'),
                                IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteEntry(entry.id!),
                                    tooltip: 'Delete'),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.directions_car_filled,
                          color: AppTheme.secondary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.vehicleNumber ?? 'Unnamed Vehicle',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.speed,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                '${entry.startKm ?? '0'} KM',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.calendar_today,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(entry.createdAt).split(',').first,
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'edit') {
                          _navigateToForm(entry: entry);
                        } else if (value == 'delete') {
                          _deleteEntry(entry.id!);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_outlined,
                                  color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text('Edit')
                            ])),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red))
                            ])),
                      ],
                    ),
                  ],
                ),
              ),
              if (entry.remarks != null && entry.remarks!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.remarks!,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.4),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildBadge(
                        icon: Icons.camera_alt_outlined,
                        text: (entry.startPhotos?.isNotEmpty ?? false)
                            ? '${entry.startPhotos!.length} Photos'
                            : 'No Photos',
                        color: (entry.startPhotos?.isNotEmpty ?? false)
                            ? Colors.blue
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBadge(
                        icon: Icons.location_on_outlined,
                        text: entry.locationConfirmed == true
                            ? 'Verified'
                            : 'Pending',
                        color: entry.locationConfirmed == true
                            ? Colors.green
                            : Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(
      {required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    const Expanded(
                      child: Text(
                        'Vehicle Start',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchEntries,
              color: AppTheme.secondary,
              child: _buildEntriesList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Add Start',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF4A4494),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
      ),
    );
  }
}
