// lib/screens/maintenance/special_maintenance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/special_maintenance_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/special_maintenance_model.dart';
import './modal/special_maintenance_modal.dart';

class SpecialMaintenanceScreen extends StatelessWidget {
  const SpecialMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SpecialMaintenanceProvider(),
      child: const _SpecialMaintenanceScreenContent(),
    );
  }
}

class _SpecialMaintenanceScreenContent extends StatefulWidget {
  const _SpecialMaintenanceScreenContent();

  @override
  State<_SpecialMaintenanceScreenContent> createState() =>
      _SpecialMaintenanceScreenContentState();
}

class _SpecialMaintenanceScreenContentState
    extends State<_SpecialMaintenanceScreenContent> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  String? _selectedFilter;
  final List<String> _filterOptions = [
    'All',
    'Battery',
    'Tyre',
    'Wheel Balancing'
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = 'All';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<SpecialMaintenanceProvider>();
    await provider.loadAllSpecialMaintenanceRecords();
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  void _navigateToEditForm(
      BuildContext context, SpecialMaintenanceRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SpecialMaintenanceModal(
          editingRecord: record,
          onRefresh: () => context
              .read<SpecialMaintenanceProvider>()
              .loadAllSpecialMaintenanceRecords(),
        ),
      ),
    );
  }

  void _navigateToAddForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SpecialMaintenanceModal(
          onRefresh: () => context
              .read<SpecialMaintenanceProvider>()
              .loadAllSpecialMaintenanceRecords(),
        ),
      ),
    );
  }

  List<SpecialMaintenanceRecord> _getFilteredRecords(
      SpecialMaintenanceProvider provider) {
    if (_selectedFilter == 'All' || _selectedFilter == null) {
      return provider.allRecords;
    }
    return provider.allRecords
        .where((record) => record.maintenanceType == _selectedFilter)
        .toList();
  }

  // Helper method to get remarks from a record
  String _getRemarks(SpecialMaintenanceRecord record) {
    if (record.battery != null) {
      return record.battery!.remarks;
    } else if (record.tyre != null) {
      return record.tyre!.remarks;
    } else if (record.wheelBalancing != null) {
      return record.wheelBalancing!.remarks;
    }
    return '';
  }

  // Helper method to get service center from a record
  String _getServiceCenter(SpecialMaintenanceRecord record) {
    if (record.battery != null) {
      return record.battery!.serviceCenter;
    } else if (record.tyre != null) {
      return record.tyre!.serviceCenter;
    } else if (record.wheelBalancing != null) {
      return record.wheelBalancing!.serviceCenter;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SpecialMaintenanceProvider>(
        builder: (context, provider, child) {
          final filteredRecords = _getFilteredRecords(provider);

          if (provider.isLoading && provider.allRecords.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Error: ${provider.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              slivers: [
                // App Bar with Filter
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  backgroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.grey.withValues(alpha: 0.2),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Special Maintenance',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedFilter,
                              icon: const Icon(Icons.filter_list,
                                  size: 20, color: Colors.grey),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedFilter = newValue;
                                });
                              },
                              items: _filterOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      _getFilterIcon(value),
                                      const SizedBox(width: 8),
                                      Text(value),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Statistics Summary
                SliverToBoxAdapter(
                  child: _buildStatistics(provider),
                ),

                // Filter Chip Bar
                SliverToBoxAdapter(
                  child: _buildFilterChips(),
                ),

                // Records List
                if (filteredRecords.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.build_circle_outlined,
                              size: 56,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No records found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedFilter == 'All'
                                ? 'Start by adding your first maintenance record'
                                : 'No $_selectedFilter records found',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => _navigateToAddForm(context),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              elevation: 2,
                            ).copyWith(
                              backgroundColor: WidgetStateProperty.all(
                                AppTheme.primary,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 20),
                                SizedBox(width: 8),
                                Text('Add Record'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final record = filteredRecords[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildMaintenanceCard(context, record),
                          );
                        },
                        childCount: filteredRecords.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddForm(context),
        icon: const Icon(Icons.add, size: 22),
        label: const Text(
          'Add Record',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildStatistics(SpecialMaintenanceProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Maintenance Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provider.allRecords.length} Total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                'Battery',
                provider.batteryRecords.length,
                Icons.battery_charging_full,
                const Color(0xFF4A4494),
              ),
              _buildStatCard(
                'Tyre',
                provider.tyreRecords.length,
                Icons.directions_car,
                AppTheme.secondary,
              ),
              _buildStatCard(
                'Wheel',
                provider.wheelBalancingRecords.length,
                Icons.settings,
                const Color(0xFF2E7D32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = selected ? filter : 'All';
                  });
                },
                backgroundColor: Colors.grey[50],
                selectedColor: AppTheme.primary.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primary : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                checkmarkColor: AppTheme.primary,
                showCheckmark: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.3)
                        : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                avatar: isSelected ? _getFilterIcon(filter) : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _getFilterIcon(String filter) {
    switch (filter) {
      case 'Battery':
        return const Icon(Icons.battery_charging_full,
            size: 16, color: AppTheme.primary);
      case 'Tyre':
        return const Icon(Icons.directions_car,
            size: 16, color: AppTheme.secondary);
      case 'Wheel Balancing':
        return const Icon(Icons.settings, size: 16, color: Color(0xFF2E7D32));
      default:
        return const Icon(Icons.all_inclusive, size: 16, color: Colors.grey);
    }
  }

  Widget _buildMaintenanceCard(
      BuildContext context, SpecialMaintenanceRecord record) {
    final remarks = _getRemarks(record);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRecordDetails(context, record),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getTypeColor(record.maintenanceType)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getTypeIcon(record.maintenanceType),
                              size: 20,
                              color: _getTypeColor(record.maintenanceType),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.maintenanceType,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        _getTypeColor(record.maintenanceType),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  record.vehicleNumber,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) =>
                          _handlePopupAction(context, value, record),
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        if (_hasBill(record))
                          const PopupMenuItem(
                            value: 'view_bill',
                            child: Row(
                              children: [
                                Icon(Icons.receipt_outlined,
                                    size: 18, color: Colors.green),
                                SizedBox(width: 8),
                                Text('View Bill'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Details Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailItem(
                      Icons.person_outline,
                      record.userName,
                      'Driver',
                    ),
                    _buildDetailItem(
                      Icons.calendar_today_outlined,
                      record.serviceDate != null
                          ? DateFormat('dd MMM').format(record.serviceDate!)
                          : 'N/A',
                      'Date',
                    ),
                    _buildDetailItem(
                      Icons.currency_rupee_outlined,
                      '₹${record.cost.toStringAsFixed(0)}',
                      'Cost',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Service Center
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _getServiceCenter(record),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Status/Bill Indicator
                if (_hasBill(record)) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green[100]!),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 12, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Bill Available',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // Remarks if available
                if (remarks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Remarks: $remarks',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  void _handlePopupAction(
      BuildContext context, String action, SpecialMaintenanceRecord record) {
    switch (action) {
      case 'edit':
        _navigateToEditForm(context, record);
        break;
      case 'view_bill':
        _viewBill(context, record);
        break;
      case 'delete':
        _showDeleteDialog(context, record);
        break;
    }
  }

  void _showRecordDetails(
      BuildContext context, SpecialMaintenanceRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildDetailsSheet(context, record),
    );
  }

  Widget _buildDetailsSheet(
      BuildContext context, SpecialMaintenanceRecord record) {
    final remarks = _getRemarks(record);
    final serviceCenter = _getServiceCenter(record);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getTypeColor(record.maintenanceType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(record.maintenanceType),
                  size: 24,
                  color: _getTypeColor(record.maintenanceType),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.maintenanceType,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getTypeColor(record.maintenanceType),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.vehicleNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Common Details
          _buildDetailRowSheet(Icons.person_outline, 'Driver', record.userName),
          _buildDetailRowSheet(
              Icons.date_range,
              'Date',
              record.serviceDate != null
                  ? DateFormat('dd MMM yyyy').format(record.serviceDate!)
                  : 'Not set'),
          _buildDetailRowSheet(Icons.currency_rupee, 'Cost',
              '₹${record.cost.toStringAsFixed(2)}'),
          _buildDetailRowSheet(
              Icons.location_on_outlined, 'Service Center', serviceCenter),

          // Type-specific details
          if (record.battery != null) ...[
            _buildDetailRowSheet(Icons.confirmation_number, 'Battery Number',
                record.battery!.batteryNumber),
            _buildDetailRowSheet(Icons.date_range, 'Warranty Date',
                DateFormat('dd MMM yyyy').format(record.battery!.warrantyDate)),
          ] else if (record.tyre != null) ...[
            _buildDetailRowSheet(Icons.confirmation_number, 'Tyre Number',
                record.tyre!.tyreNumber),
            _buildDetailRowSheet(
                Icons.branding_watermark, 'Brand', record.tyre!.tyreBrand),
            if (record.tyre!.dateOfReturn != null)
              _buildDetailRowSheet(Icons.date_range, 'Return Date',
                  DateFormat('dd MMM yyyy').format(record.tyre!.dateOfReturn!)),
          ] else if (record.wheelBalancing != null) ...[
            if (record.wheelBalancing!.dateOfReturn != null)
              _buildDetailRowSheet(
                  Icons.date_range,
                  'Return Date',
                  DateFormat('dd MMM yyyy')
                      .format(record.wheelBalancing!.dateOfReturn!)),
          ],

          // Remarks
          if (remarks.isNotEmpty)
            _buildDetailRowSheet(Icons.note_outlined, 'Remarks', remarks),

          // Bill Info
          if (_hasBill(record))
            _buildDetailRowSheet(Icons.receipt_outlined, 'Bill',
                'Available - ${_getBillCount(record)} file(s)'),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToEditForm(context, record);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.all(
                      const Color(0xFF4A4494),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowSheet(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Battery':
        return const Color(0xFF4A4494);
      case 'Tyre':
        return const Color(0xFF14ADD6);
      case 'Wheel Balancing':
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Battery':
        return Icons.battery_charging_full;
      case 'Tyre':
        return Icons.directions_car;
      case 'Wheel Balancing':
        return Icons.settings;
      default:
        return Icons.build;
    }
  }

  bool _hasBill(SpecialMaintenanceRecord record) {
    final billUploads = record.battery?.billUpload ??
        record.tyre?.billUpload ??
        record.wheelBalancing?.billUpload;
    return billUploads?.isNotEmpty == true;
  }

  int _getBillCount(SpecialMaintenanceRecord record) {
    final billUploads = record.battery?.billUpload ??
        record.tyre?.billUpload ??
        record.wheelBalancing?.billUpload;
    return billUploads?.length ?? 0;
  }

  Future<void> _viewBill(
      BuildContext context, SpecialMaintenanceRecord record) async {
    final billUploads = record.battery?.billUpload ??
        record.tyre?.billUpload ??
        record.wheelBalancing?.billUpload;

    if (billUploads != null && billUploads.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bill Documents'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: billUploads.length,
              itemBuilder: (context, index) {
                final url = billUploads[index];
                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text(url.split('/').last),
                  subtitle: Text(
                    url,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    // Open URL in browser or PDF viewer
                  },
                );
              },
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
  }

  Future<void> _showDeleteDialog(
      BuildContext context, SpecialMaintenanceRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record?'),
        content: Text(
            'This ${record.maintenanceType.toLowerCase()} record for ${record.vehicleNumber} will be permanently deleted.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) {
        return;
      }

      final provider =
          Provider.of<SpecialMaintenanceProvider>(context, listen: false);

      try {
        await provider.deleteSpecialMaintenance(
            record.id, record.maintenanceType.toLowerCase());

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Record deleted successfully'),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }
}
