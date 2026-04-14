// dashboard_vehicle_overlay.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dashboard_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/theme/app_theme.dart';

class DashboardVehicleOverlay extends StatefulWidget {
  final String title;
  final String filter;
  final Color color;

  const DashboardVehicleOverlay({
    super.key,
    required this.title,
    required this.filter,
    required this.color,
  });

  @override
  State<DashboardVehicleOverlay> createState() =>
      _DashboardVehicleOverlayState();
}

class _DashboardVehicleOverlayState extends State<DashboardVehicleOverlay> {
  late Future<PaginatedVehicleResponse> _vehiclesFuture;
  int _currentPage = 1;
  final int _itemsPerPage = 1000;
  String? _selectedVehicleNumber;
  String? _selectedVehicleType;
  String? _selectedMaintenanceType;
  DashboardVehicle? _selectedVehicle;

  final GlobalKey _detailsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  void _refreshData() {
    setState(() {
      _loadVehicles();
      _selectedVehicle = null;
    });
  }

  void _loadVehicles() {
    final provider = Provider.of<DashboardProvider>(context, listen: false);

    Map<String, String>? additionalParams;

    // Handle special filters
    if (widget.filter == 'maintenance-insurance') {
      additionalParams = {
        'maintenance_type': _selectedMaintenanceType ?? '',
      };
    }

    _vehiclesFuture = provider.fetchFilteredVehicles(
      filter: widget.filter,
      page: _currentPage,
      limit: _itemsPerPage,
      additionalParams: additionalParams,
    );
  }

  void _viewVehicleDetails(DashboardVehicle vehicle) {
    setState(() {
      if (_selectedVehicle?.id == vehicle.id) {
        _selectedVehicle = null;
      } else {
        _selectedVehicle = vehicle;
        // Scroll to details after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToDetails();
        });
      }
    });
  }

  void _scrollToDetails() {
    final context = _detailsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedVehicleNumber = null;
      _selectedVehicleType = null;
      _selectedMaintenanceType = null;
      _selectedVehicle = null;
      _currentPage = 1;
      _loadVehicles();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            _buildHeader(),

            // Content
            Expanded(
              child: FutureBuilder<PaginatedVehicleResponse>(
                future: _vehiclesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                    return _buildEmptyState();
                  }

                  final response = snapshot.data!;
                  final vehicles = response.data;
                  final totalRecords = response.total;

                  return Column(
                    children: [
                      // Filters (hide if selected)
                      if (_selectedVehicle == null) _buildFilters(),

                      // Results summary (has clear selection button)
                      _buildResultsSummary(vehicles.length, totalRecords),

                      // Main area: Details or Table
                      Expanded(
                        child: _selectedVehicle != null
                            ? SingleChildScrollView(
                                child: _buildVehicleDetails(_selectedVehicle!),
                              )
                            : _buildVehicleTable(vehicles),
                      ),

                      // Pagination removed as requested
                    ],
                  );
                },
              ),
            ),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'View and manage vehicles',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDropdown(
                      label: 'Vehicle Number',
                      value: _selectedVehicleNumber,
                      items: const [
                        'All Vehicle Numbers',
                        'KA01AB1234',
                        'KA01CD5678'
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedVehicleNumber =
                              value == 'All Vehicle Numbers' ? null : value;
                          _currentPage = 1;
                          _loadVehicles();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Vehicle Type',
                      value: _selectedVehicleType,
                      items: const [
                        'All Vehicle Types',
                        'Car',
                        'Bike',
                        'Truck'
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedVehicleType =
                              value == 'All Vehicle Types' ? null : value;
                          _currentPage = 1;
                          _loadVehicles();
                        });
                      },
                    ),
                    if (widget.filter == 'maintenance-insurance') ...[
                      const SizedBox(height: 12),
                      _buildDropdown(
                        label: 'Maintenance Type',
                        value: _selectedMaintenanceType,
                        items: const ['All Types', 'maintenance', 'insurance'],
                        onChanged: (value) {
                          setState(() {
                            _selectedMaintenanceType =
                                value == 'All Types' ? null : value;
                            _currentPage = 1;
                            _loadVehicles();
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _clearFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Clear Filters',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                );
              }

              // Desktop/Tablet view
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Vehicle Number',
                      value: _selectedVehicleNumber,
                      items: const [
                        'All Vehicle Numbers',
                        'KA01AB1234',
                        'KA01CD5678'
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedVehicleNumber =
                              value == 'All Vehicle Numbers' ? null : value;
                          _currentPage = 1;
                          _loadVehicles();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Vehicle Type',
                      value: _selectedVehicleType,
                      items: const [
                        'All Vehicle Types',
                        'Car',
                        'Bike',
                        'Truck'
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedVehicleType =
                              value == 'All Vehicle Types' ? null : value;
                          _currentPage = 1;
                          _loadVehicles();
                        });
                      },
                    ),
                  ),
                  if (widget.filter == 'maintenance-insurance')
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Expanded(
                        child: _buildDropdown(
                          label: 'Maintenance Type',
                          value: _selectedMaintenanceType,
                          items: const [
                            'All Types',
                            'maintenance',
                            'insurance'
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedMaintenanceType =
                                  value == 'All Types' ? null : value;
                              _currentPage = 1;
                              _loadVehicles();
                            });
                          },
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _clearFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Clear Filters'),
                    ),
                  ),
                ],
              );
            },
          ),
          if (_selectedVehicleNumber != null ||
              _selectedVehicleType != null ||
              _selectedMaintenanceType != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list,
                        size: 16, color: AppTheme.secondary),
                    const SizedBox(width: 8),
                    const Text(
                      'Active Filters:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (_selectedVehicleNumber != null)
                            Chip(
                              label: Text('Vehicle: $_selectedVehicleNumber'),
                              onDeleted: () {
                                setState(() {
                                  _selectedVehicleNumber = null;
                                  _currentPage = 1;
                                  _loadVehicles();
                                });
                              },
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                  color: AppTheme.secondary.withValues(alpha: 0.3)),
                              deleteIconColor: AppTheme.secondary,
                            ),
                          if (_selectedVehicleType != null)
                            Chip(
                              label: Text('Type: $_selectedVehicleType'),
                              onDeleted: () {
                                setState(() {
                                  _selectedVehicleType = null;
                                  _currentPage = 1;
                                  _loadVehicles();
                                });
                              },
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                  color: AppTheme.secondary.withValues(alpha: 0.3)),
                              deleteIconColor: AppTheme.secondary,
                            ),
                          if (_selectedMaintenanceType != null)
                            Chip(
                              label: Text(
                                  'Maintenance: ${_selectedMaintenanceType!.toUpperCase()}'),
                              onDeleted: () {
                                setState(() {
                                  _selectedMaintenanceType = null;
                                  _currentPage = 1;
                                  _loadVehicles();
                                });
                              },
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                  color: AppTheme.secondary.withValues(alpha: 0.3)),
                              deleteIconColor: AppTheme.secondary,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                value: value ?? items.first,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111827),
                ),
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSummary(int showing, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  'Showing $showing of $total vehicles',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (_selectedVehicle != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Vehicle selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedVehicle != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedVehicle = null;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.close, size: 16),
                  SizedBox(width: 4),
                  Text('Clear Selection'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleTable(List<DashboardVehicle> vehicles) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        final isSelected = _selectedVehicle?.id == vehicle.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppTheme.secondary : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          color:
              isSelected ? AppTheme.secondary.withValues(alpha: 0.02) : Colors.white,
          child: InkWell(
            onTap: () => _viewVehicleDetails(vehicle),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getVehicleTypeColor(vehicle.vehicleType)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              vehicle.vehicleType.isNotEmpty
                                  ? vehicle.vehicleType
                                  : 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:
                                    _getVehicleTypeColor(vehicle.vehicleType),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            vehicle.vehicleNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.secondary
                              : AppTheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.close : Icons.visibility,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSelected ? 'Hide' : 'View',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Model',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              '${vehicle.vehicleDetails.brand} ${vehicle.vehicleDetails.model}'
                                      .trim()
                                      .isEmpty
                                  ? '-'
                                  : '${vehicle.vehicleDetails.brand} ${vehicle.vehicleDetails.model}',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fuel Type',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getFuelColor(vehicle.fuelType)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                vehicle.fuelType ?? '-',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _getFuelColor(vehicle.fuelType)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Owner',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              vehicle.ownershipName == null ||
                                      vehicle.ownershipName!.isEmpty
                                  ? '-'
                                  : vehicle.ownershipName!,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 8,
                    spacing: 8,
                    children: [
                      _buildDateInfo(
                          'Maintenance',
                          _formatDate(vehicle.maintenanceExpiry),
                          const Color(0xFFF59E0B)),
                      _buildDateInfo(
                          'Insurance',
                          _formatDate(vehicle.insuranceExpiry),
                          AppTheme.secondary),
                      _buildDateInfo(
                          'Pollution',
                          _formatDate(vehicle.pollutionExpiry),
                          AppTheme.secondary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateInfo(String label, String date, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleDetails(DashboardVehicle vehicle) {
    return Container(
      key: _detailsKey,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Vehicle Details - ${vehicle.vehicleNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Selected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Vehicle Info Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                // Split into two rows for mobile
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Vehicle Number',
                        vehicle.vehicleNumber,
                        icon: Icons.confirmation_number,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Type',
                        vehicle.vehicleType,
                        icon: Icons.category,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Model',
                        '${vehicle.brand} ${vehicle.model}',
                        icon: Icons.directions_car,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Status & Fuel',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(vehicle.bookingStatus)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                vehicle.bookingStatus,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(vehicle.bookingStatus),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getFuelColor(vehicle.fuelType)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                vehicle.fuelType ?? '-',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getFuelColor(vehicle.fuelType),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Registration Details
                const Text(
                  'Registration Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    _buildDetailCard(
                      'Registration Date',
                      _formatDate(vehicle.registrationDate),
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      'Purchase Year',
                      vehicle.yearOfPurchase ?? '-',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      'Registered Owner',
                      vehicle.ownershipName ?? 'N/A',
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Expiry Details
                const Text(
                  'Expiry Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    _buildExpiryCard(
                      'Maintenance Expiry',
                      _formatDate(vehicle.maintenanceExpiry),
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 12),
                    _buildExpiryCard(
                      'Insurance Expiry',
                      _formatDate(vehicle.insuranceExpiry),
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildExpiryCard(
                      'Pollution Expiry',
                      _formatDate(vehicle.pollutionExpiry),
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, dynamic value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (value is Widget)
            value
          else
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, {required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryCard(String label, String value, {required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value != '-' ? 'Due date' : 'No data',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading vehicles...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            child: Icon(
              Icons.directions_car,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No vehicles found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or criteria',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_selectedVehicleNumber != null ||
              _selectedVehicleType != null ||
              _selectedMaintenanceType != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: _clearFilters,
                style: TextButton.styleFrom(
                  foregroundColor: widget.color,
                ),
                child: const Text('Clear all filters'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: const Text(
              'Click on any vehicle to view details',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Close'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  // This would need access to the current vehicles list
                  // You might want to store the current vehicles in state
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: const Text('Export to CSV'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods for colors
  Color _getVehicleTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'car':
        return AppTheme.secondary;
      case 'bike':
        return Colors.green;
      case 'truck':
        return Colors.orange;
      case 'bus':
        return Colors.purple;
      case 'van':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getFuelColor(String? fuel) {
    switch (fuel?.toLowerCase()) {
      case 'diesel':
        return Colors.grey;
      case 'petrol':
        return Colors.orange;
      case 'electric':
        return Colors.green;
      case 'cng':
        return AppTheme.secondary;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'booked':
        return AppTheme.secondary;
      case 'not available':
        return Colors.red;
      case 'maintenance':
      case 'service':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

// Replace the existing _formatDate method with this one
  String _formatDate(dynamic date) {
    if (date == null) return '-';

    try {
      // If it's already a DateTime
      if (date is DateTime) {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }

      // If it's a String
      if (date is String) {
        // Check if it's empty or invalid
        if (date.isEmpty || date == '-' || date == 'N/A') return '-';

        // Try to parse the string to DateTime
        // Handle different date formats
        DateTime? parsedDate;

        // Try ISO format (yyyy-MM-dd)
        if (date.contains('-')) {
          parsedDate = DateTime.tryParse(date);
        }

        // Try dd/MM/yyyy format
        if (parsedDate == null && date.contains('/')) {
          final parts = date.split('/');
          if (parts.length == 3) {
            final day = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            final year = int.tryParse(parts[2]);
            if (day != null && month != null && year != null) {
              parsedDate = DateTime(year, month, day);
            }
          }
        }

        if (parsedDate != null) {
          return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
        }

        // If parsing fails, return the original string
        return date;
      }

      return '-';
    } catch (e) {
      return '-';
    }
  }
}
