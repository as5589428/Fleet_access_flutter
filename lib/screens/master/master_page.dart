import 'package:fleet_management/models/vehicle_model.dart';
import './master_form.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/app_constants.dart';


class VehicleMasterScreen extends StatefulWidget {
  const VehicleMasterScreen({super.key});

  @override
  State<VehicleMasterScreen> createState() => _VehicleMasterScreenState();
}

class _VehicleMasterScreenState extends State<VehicleMasterScreen>
    with SingleTickerProviderStateMixin {
  final String baseUrl = AppConstants.baseUrl;

  List<VehicleModel> vehicles = [];
  List<VehicleModel> filteredVehicles = [];
  bool isLoading = true;
  bool isRefreshing = false;
  String searchQuery = '';
  String selectedFilter = 'All Vehicles';

  // Pagination
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalVehicles = 0;
  int totalPages = 1;

  // Sorting
  String? sortColumn;
  bool sortAscending = true;

  // Column visibility
  Map<String, bool> visibleColumns = {
    'srNo': true,
    'vehicleNumber': true,
    'type': true,
    'ownership': true,
    'userName': true,
    'brandModel': true,
    'capacity': true,
    'fuel': true,
    'serviceAlert': true,
    'status': true,
    'booking': true,
    'insurance': true,
    'pollution': true,
    'remarks': true,
    'actions': true,
  };

  // UI State
  bool showColumnSettings = false;
  bool showExportMenu = false;
  String? openActionMenuId;
  OverlayEntry? _overlayEntry;

  // Animation for refresh
  late AnimationController _refreshController;

  // Filter options
  final List<String> filterOptions = [
    'All Vehicles',
    'Active',
    'Inactive',
    'Maintenance',
    'Theft',
    'Resale',
    'Scrap',
    'Available',
  ];

  // Status colors
  final Map<String, Color> statusColors = {
    'Active': Colors.green,
    'Inactive': Colors.red,
    'Maintenance': Colors.orange,
    'Theft': Colors.grey,
    'Resale': Colors.purple,
    'Scrap': Colors.brown,
    'Good': Colors.blue,
  };

  // Fuel type colors
  final Map<String, Color> fuelColors = {
    'Diesel': Colors.blue.shade100,
    'Petrol': Colors.green.shade100,
    'Electric': Colors.red.shade100,
    'CNG': Colors.yellow.shade100,
  };

  // Booking status colors
  final Map<String, Color> bookingColors = {
    'green': Colors.green,
    'red': Colors.red,
    'grey': Colors.grey,
    'gray': Colors.grey,
    'yellow': Colors.amber,
    'blue': Colors.blue,
  };

  // Static color for app bar
  final Color _primaryColor = const Color(0xFF4A4494);

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadVehicles();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }


  // Load vehicles from API
  Future<void> _loadVehicles() async {
    setState(() {
      isLoading = true;
      _refreshController.repeat();
    });

    try {
      final queryParams = {
        'page': currentPage.toString(),
        'limit': itemsPerPage.toString(),
        if (sortColumn != null) 'sort': sortColumn!,
        if (sortColumn != null) 'order': sortAscending ? 'asc' : 'desc',
      };

      final uri = Uri.parse('$baseUrl/vehicles/list')
          .replace(queryParameters: queryParams);

      debugPrint('ðŸ“¡ Loading vehicles from: $uri');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['status'] == 'success') {
          final List<dynamic> data = result['data'] ?? [];

          List<VehicleModel> parsedVehicles = [];
          for (var item in data) {
            try {
              parsedVehicles.add(VehicleModel.fromJsonManual(item));
            } catch (e) {
              debugPrint('âŒ Error parsing vehicle: $e');
            }
          }

          setState(() {
            vehicles = parsedVehicles;
            _applyFilters();

            // Update pagination info
            if (result['pagination'] != null) {
              totalVehicles =
                  result['pagination']['total'] ?? parsedVehicles.length;
              totalPages = result['pagination']['totalPages'] ?? 1;
            } else {
              totalVehicles = parsedVehicles.length;
              totalPages = (totalVehicles / itemsPerPage).ceil();
            }
          });

          debugPrint('âœ… Loaded ${vehicles.length} vehicles');
        }
      } else {
        throw Exception('Failed to load vehicles');
      }
    } catch (e) {
      debugPrint('âŒ Error: $e');
      _showSnackBar('Error loading vehicles', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          _refreshController.stop();
        });
      }
    }
  }

  void _applyFilters() {
    List<VehicleModel> filtered = List.from(vehicles);

    // Apply search
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((v) {
        return v.vehicleNumber
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            v.brand.toLowerCase().contains(searchQuery.toLowerCase()) ||
            v.model.toLowerCase().contains(searchQuery.toLowerCase()) ||
            v.ownershipName.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (selectedFilter != 'All Vehicles') {
      if (selectedFilter == 'Available') {
        filtered =
            filtered.where((v) => v.bookingStatus == 'Available').toList();
      } else {
        filtered = filtered.where((v) => v.status == selectedFilter).toList();
      }
    }

    setState(() {
      filteredVehicles = filtered;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openCreateForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleFormPage(
          baseUrl: baseUrl,
          onVehicleCreated: _loadVehicles,
        ),
      ),
    );
  }

  void _openEditForm(VehicleModel vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleFormPage(
          baseUrl: baseUrl,
          vehicle: vehicle,
          isEditing: true,
          onVehicleUpdated: _loadVehicles,
        ),
      ),
    );
  }

  Future<void> _deleteVehicle(VehicleModel vehicle) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
            'Are you sure you want to delete vehicle ${vehicle.vehicleNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await http.delete(
                  Uri.parse('$baseUrl/vehicles/delete?id=${vehicle.id}'),
                );

                if (response.statusCode == 200) {
                  _showSnackBar('Vehicle deleted successfully');
                  _loadVehicles();
                } else {
                  _showSnackBar('Failed to delete vehicle', isError: true);
                }
              } catch (e) {
                _showSnackBar('Error deleting vehicle', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showActionMenu(
      BuildContext context, VehicleModel vehicle, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx - 100,
        position.dy,
        position.dx,
        position.dy + 100,
      ),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        _openEditForm(vehicle);
      } else if (value == 'delete') {
        _deleteVehicle(vehicle);
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  bool _isExpired(DateTime? date) {
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  Color _getStatusColor(String status) {
    return statusColors[status] ?? Colors.grey;
  }


  Color _getBookingColor(String? colorCode) {
    return bookingColors[colorCode?.toLowerCase()] ?? Colors.grey;
  }


  void _handleSort(String column) {
    setState(() {
      if (sortColumn == column) {
        sortAscending = !sortAscending;
      } else {
        sortColumn = column;
        sortAscending = true;
      }
    });
    _loadVehicles();
  }

  Widget _buildSortIcon(String column) {
    if (sortColumn != column) {
      return Icon(Icons.swap_vert,
          size: 14, color: Colors.white.withValues(alpha: 0.5));
    }
    return Icon(
      sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
      size: 14,
      color: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final safeTopPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header with Static Color
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, safeTopPadding + 16, 20, 16),
            color: _primaryColor,
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
                          'Vehicle Master',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your vehicle fleet efficiently',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Export Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.download,
                                color: Colors.white, size: 20),
                            onPressed: () {
                              _showSnackBar('Export feature coming soon');
                            },
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        _applyFilters();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search vehicles...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon:
                          Icon(Icons.search, color: _primaryColor, size: 18),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filterOptions.length,
              itemBuilder: (context, index) {
                final filter = filterOptions[index];
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(filter, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedFilter = filter;
                        _applyFilters();
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: _primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                );
              },
            ),
          ),

          // Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredVehicles.length} Vehicles',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Total: $totalVehicles records',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadVehicles,
              color: _primaryColor,
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RotationTransition(
                            turns: Tween(begin: 0.0, end: 1.0)
                                .animate(_refreshController),
                            child: Icon(
                              Icons.refresh,
                              size: 32,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Loading vehicles...',
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    )
                  : filteredVehicles.isEmpty
                      ? ListView(
                          children: [_buildEmptyState()],
                        )
                      : screenWidth > 900
                          ? _buildTableView()
                          : _buildCompactCardView(),
            ),
          ),

          // Pagination
          if (filteredVehicles.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Items per page
                  Row(
                    children: [
                      const Text('Show', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButton<int>(
                          value: itemsPerPage,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, size: 18),
                          items: [5, 10, 20, 50, 100].map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value.toString(),
                                  style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              itemsPerPage = value!;
                              currentPage = 1;
                            });
                            _loadVehicles();
                          },
                        ),
                      ),
                    ],
                  ),

                  // Page controls
                  Row(
                    children: [
                      Text(
                        '$currentPage/$totalPages',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.first_page, size: 18),
                        onPressed: currentPage > 1
                            ? () {
                                setState(() => currentPage = 1);
                                _loadVehicles();
                              }
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 18),
                        onPressed: currentPage > 1
                            ? () {
                                setState(() => currentPage--);
                                _loadVehicles();
                              }
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 18),
                        onPressed: currentPage < totalPages
                            ? () {
                                setState(() => currentPage++);
                                _loadVehicles();
                              }
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.last_page, size: 18),
                        onPressed: currentPage < totalPages
                            ? () {
                                setState(() => currentPage = totalPages);
                                _loadVehicles();
                              }
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),

                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateForm,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Add Vehicle',
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

  Widget _buildTableView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DataTable(
            columnSpacing: 16,
            headingRowColor: WidgetStateProperty.all(_primaryColor),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            columns: [
              if (visibleColumns['srNo'] == true)
                const DataColumn(label: Text('S.No')),
              if (visibleColumns['vehicleNumber'] == true)
                DataColumn(
                  label: Row(
                    children: [
                      const Text('Vehicle No'),
                      const SizedBox(width: 2),
                      _buildSortIcon('vehicle_number'),
                    ],
                  ),
                  onSort: (columnIndex, ascending) =>
                      _handleSort('vehicle_number'),
                ),
              if (visibleColumns['type'] == true)
                const DataColumn(label: Text('Type')),
              if (visibleColumns['status'] == true)
                const DataColumn(label: Text('Status')),
              if (visibleColumns['booking'] == true)
                const DataColumn(label: Text('Booking')),
              if (visibleColumns['actions'] == true)
                const DataColumn(label: Text('Actions')),
            ],
            rows: filteredVehicles.asMap().entries.map((entry) {
              final index = entry.key;
              final vehicle = entry.value;
              final rowIndex = (currentPage - 1) * itemsPerPage + index + 1;

              return DataRow(
                cells: [
                  if (visibleColumns['srNo'] == true)
                    DataCell(Text(rowIndex.toString())),
                  if (visibleColumns['vehicleNumber'] == true)
                    DataCell(
                      Text(
                        vehicle.vehicleNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  if (visibleColumns['type'] == true)
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          vehicle.vehicleType,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  if (visibleColumns['status'] == true)
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(vehicle.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _getStatusColor(vehicle.status)),
                        ),
                        child: Text(
                          vehicle.status,
                          style: TextStyle(
                            color: _getStatusColor(vehicle.status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (visibleColumns['booking'] == true)
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getBookingColor(vehicle.bookingColorCode)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          vehicle.bookingStatus,
                          style: TextStyle(
                            color: _getBookingColor(vehicle.bookingColorCode),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  if (visibleColumns['actions'] == true)
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 16),
                        onPressed: () {
                          final RenderBox button =
                              context.findRenderObject() as RenderBox;
                          final position = button.localToGlobal(Offset.zero);
                          _showActionMenu(context, vehicle, position);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Compact card view with reduced spacing
  Widget _buildCompactCardView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = filteredVehicles[index];
        final rowIndex = (currentPage - 1) * itemsPerPage + index + 1;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          rowIndex.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vehicle.vehicleNumber,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(vehicle.status)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _getStatusColor(vehicle.status),
                                      width: 1),
                                ),
                                child: Text(
                                  vehicle.status,
                                  style: TextStyle(
                                    color: _getStatusColor(vehicle.status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${vehicle.brand} ${vehicle.model} â€¢ ${vehicle.vehicleType}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 12, thickness: 0.5),

                // Details Grid - 3 columns
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  children: [
                    _buildCompactDetailItem(
                        Icons.person, vehicle.ownershipName, _primaryColor),
                    _buildCompactDetailItem(
                        Icons.person_outline,
                        vehicle.userName.isEmpty
                            ? 'Not Assigned'
                            : vehicle.userName,
                        _primaryColor),
                    _buildCompactDetailItem(Icons.people,
                        '${vehicle.seatingCapacity} seats', _primaryColor),
                    _buildCompactFuelItem(vehicle.fuelType),
                    _buildCompactDetailItem(Icons.speed,
                        '${vehicle.serviceKmAlert.isEmpty ? '-' : vehicle.serviceKmAlert} km', Colors.orange),
                    _buildCompactExpiryItem(
                        Icons.security,
                        _formatDate(vehicle.expiryDetails.insuranceExpiry),
                        _isExpired(vehicle.expiryDetails.insuranceExpiry)),
                    _buildCompactExpiryItem(
                        Icons.eco,
                        _formatDate(vehicle.expiryDetails.pollutionExpiry),
                        _isExpired(vehicle.expiryDetails.pollutionExpiry)),
                    _buildCompactBookingItem(
                        vehicle.bookingStatus,
                        _getBookingColor(vehicle.bookingColorCode),
                        vehicle.bookedBy),
                  ],
                ),

                // Remarks if available
                if (vehicle.remarks.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vehicle.remarks,
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openEditForm(vehicle),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child:
                            const Text('Edit', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _deleteVehicle(vehicle),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Delete',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactDetailItem(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFuelItem(List<String> fuels) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.local_gas_station, size: 12, color: Colors.orange),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              fuels.join(', '),
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactExpiryItem(IconData icon, String date, bool isExpired) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: isExpired ? Colors.red : Colors.green),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              date,
              style: TextStyle(
                fontSize: 11,
                color: isExpired ? Colors.red : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBookingItem(String status, Color color, String bookedBy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.book_online, size: 12, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              bookedBy.isEmpty ? status : '$status by $bookedBy',
              style: TextStyle(fontSize: 11, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 60,
              color: _primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? 'No vehicles found'
                  : 'No matching vehicles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              searchQuery.isEmpty
                  ? 'Add your first vehicle to get started'
                  : 'Try adjusting your search',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openCreateForm,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Vehicle', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
