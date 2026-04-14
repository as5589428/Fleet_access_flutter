import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/booking_api_service.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class BookingListScreen extends StatefulWidget {
  final VoidCallback? onCreateTap;
  final Function(Map<String, dynamic>)? onEditTap;

  const BookingListScreen({
    super.key,
    this.onCreateTap,
    this.onEditTap,
  });

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  final BookingApiService _apiService = BookingApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _isLoadingMore = false;

  // Filter variables
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedBookingType = 'all';
  String _selectedStatus = 'all';
  String _selectedVehicleType = 'all';
  // UI States
  bool _isGridView = false; // Toggle between grid and list view

  // Filter options
  List<Map<String, dynamic>> _filterVehicles = [];
  List<Map<String, dynamic>> _filterVehicleTypes = [];

  // Available vehicle types with icons
  final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'label': 'All',
      'value': 'all',
      'icon': Icons.all_inclusive,
      'color': Colors.grey
    },
    {
      'label': 'Bike',
      'value': 'bike',
      'icon': Icons.two_wheeler,
      'color': Colors.orange
    },
    {
      'label': 'Car',
      'value': 'car',
      'icon': Icons.directions_car,
      'color': AppTheme.secondary
    },
    {
      'label': 'Van',
      'value': 'van',
      'icon': Icons.airport_shuttle,
      'color': Colors.green
    },
    {
      'label': 'Truck',
      'value': 'truck',
      'icon': Icons.local_shipping,
      'color': Colors.red
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
      _loadFilterOptions();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    
    // Set loading state immediately to prevent multiple calls
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final totalBookings = bookingProvider.filteredBookings.length;
      final totalPages = (totalBookings / _itemsPerPage).ceil();

      if (_currentPage < totalPages) {
        if (mounted) {
          setState(() {
            _currentPage++;
          });
        }

        // Simulate loading
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadBookings() async {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    await bookingProvider.loadBookings();
    if (mounted) {
      setState(() {
        _currentPage = 1;
      });
    }
  }

  Future<void> _loadFilterOptions() async {
    try {
      // Load vehicles for filter
      final vehicleResponse = await _apiService.getVehicleNumbers();
      if (vehicleResponse.success) {
        final vehicles = (vehicleResponse.data ?? [])
            .map((v) => {
                  'value': v['vehicle_number']?.toString() ?? '',
                  'label': v['vehicle_number']?.toString() ?? '',
                  'selected': false,
                })
            .toList();
        if (mounted) {
          setState(() {
            _filterVehicles = List<Map<String, dynamic>>.from(vehicles);
          });
        }
      }

      // Load vehicle types for filter
      final typeResponse = await _apiService.getVehicleTypes();
      if (typeResponse.success) {
        final types = (typeResponse.data ?? [])
            .map((type) => {
                  'value': type,
                  'label': type,
                  'selected': false,
                })
            .toList();
        if (mounted) {
          setState(() {
            _filterVehicleTypes = List<Map<String, dynamic>>.from(types);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading filter options: $e');
    }
  }

  void _onSearchChanged() {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    bookingProvider.searchBookings(_searchController.text);
    setState(() {
      _currentPage = 1;
    });
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedBookingType = 'all';
      _selectedStatus = 'all';
      _selectedVehicleType = 'all';
      _searchController.clear();

      for (var vehicle in _filterVehicles) {
        vehicle['selected'] = false;
      }
      for (var type in _filterVehicleTypes) {
        type['selected'] = false;
      }
    });
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    bookingProvider.clearFilters();
  }

  void _applyFilters() {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);

    final selectedVehicles = _filterVehicles
        .where((v) => v['selected'] == true)
        .map((v) => v['value'].toString())
        .where((v) => v.isNotEmpty)
        .toList();

    final selectedTypes = _filterVehicleTypes
        .where((t) => t['selected'] == true)
        .map((t) => t['value'].toString())
        .where((t) => t.isNotEmpty)
        .toList();

    if (selectedVehicles.isNotEmpty || selectedTypes.isNotEmpty) {
      bookingProvider.applyServerFilters(
        startDate: _startDate,
        endDate: _endDate,
        bookingType:
            _selectedBookingType == 'all' ? null : _selectedBookingType,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        vehicleNumbers: selectedVehicles.isNotEmpty ? selectedVehicles : null,
        vehicleTypes: selectedTypes.isNotEmpty ? selectedTypes : null,
      );
    } else {
      bookingProvider.applyFilters(
        startDate: _startDate,
        endDate: _endDate,
        bookingType:
            _selectedBookingType == 'all' ? null : _selectedBookingType,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        vehicleType:
            _selectedVehicleType == 'all' ? null : _selectedVehicleType,
      );
    }

    setState(() {
      _currentPage = 1;
    });
  }

  Future<void> _refreshBookings() async {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    await bookingProvider.refreshBookings();
    if (mounted) {
      setState(() {
        _currentPage = 1;
      });
    }
  }

  Future<void> _showDeleteDialog(Map<String, dynamic> booking) async {
    final vehicleNumber = booking['vehicle_number'] ?? 'Unknown';
    final bookingId = booking['_id'] ?? '';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Booking'),
          content: Text(
              'Are you sure you want to delete booking for vehicle $vehicleNumber?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.pop(context);
                await _deleteBooking(bookingId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBooking(String bookingId) async {
    if (bookingId.isEmpty) return;

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final success = await bookingProvider.deleteBooking(bookingId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Booking deleted successfully'
            : 'Failed to delete booking'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Map<String, dynamic> _getLocationDisplay(Map<String, dynamic> booking) {
    if (booking['booking_type'] == 'office') {
      final locations = _getAllLocations(booking);
      return {
        'locations': locations,
        'primaryLocation': locations.isNotEmpty ? locations.first : '-',
        'hasMultiple': locations.length > 1,
        'count': locations.length,
      };
    } else {
      return {
        'locations': [booking['personal_location'] ?? '-'],
        'primaryLocation': booking['personal_location'] ?? '-',
        'hasMultiple': false,
        'count': 1,
        'purpose': booking['personal_purpose'],
      };
    }
  }

  List<String> _getAllLocations(Map<String, dynamic> booking) {
    if (booking['booking_type'] == 'office') {
      final customerDetails = booking['customer_details'];
      if (customerDetails is! List) return [];
      
      final locations = customerDetails.expand((customer) {
        if (customer is! Map) return [];
        final locs = customer['customer_location'];
        if (locs is! List) return [];
        return locs.where((loc) =>
            loc != null && loc.toString().trim().isNotEmpty);
      }).toList();

      return locations.map((loc) => loc.toString()).toSet().toList();
    } else {
      return booking['personal_location'] != null
          ? [booking['personal_location'].toString()]
          : [];
    }
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString.toString());
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString.toString();
    }
  }

  IconData _getVehicleTypeIcon(String? vehicleType) {
    if (vehicleType == null) return Icons.directions_car;

    switch (vehicleType.toLowerCase()) {
      case 'bike':
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'car':
      case 'sedan':
        return Icons.directions_car;
      case 'van':
      case 'minivan':
        return Icons.airport_shuttle;
      case 'truck':
      case 'lorry':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  Color _getVehicleTypeColor(String? vehicleType) {
    if (vehicleType == null) return AppTheme.secondary;

    switch (vehicleType.toLowerCase()) {
      case 'bike':
        return Colors.orange;
      case 'car':
        return AppTheme.secondary;
      case 'van':
        return Colors.green;
      case 'truck':
        return Colors.red;
      default:
        return AppTheme.secondary;
    }
  }

  void _showTravelersModal(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final travelers = booking['travelers'] as List? ?? [];

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.people, color: AppTheme.secondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Travelers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${booking['vehicle_number']} • ${travelers.length} travelers',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Travelers List
                Expanded(
                  child: travelers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'No travelers',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: travelers.length,
                          itemBuilder: (context, index) {
                            final traveler = travelers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppTheme.secondary.withValues(alpha: 0.1),
                                  child: const Icon(Icons.person,
                                      color: AppTheme.secondary, size: 20),
                                ),
                                title: Text(
                                  traveler['employee_name'] ??
                                      traveler['name'] ??
                                      'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (traveler['employee_id'] != null)
                                      Text('ID: ${traveler['employee_id']}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600])),
                                    if (traveler['role'] != null)
                                      Text('Role: ${traveler['role']}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600])),
                                  ],
                                ),
                                trailing: traveler['traveler_status'] == 'green'
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Text('Active',
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 11)),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getPaginatedBookings(
      List<Map<String, dynamic>> bookings) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    if (startIndex >= bookings.length) {
      return [];
    }
    return bookings.sublist(
        startIndex, endIndex > bookings.length ? bookings.length : endIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        final allBookings = bookingProvider.filteredBookings;
        final paginatedBookings = _getPaginatedBookings(allBookings);
        final isLoading = bookingProvider.isLoading;
        final statistics = bookingProvider.getStatistics();

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: const Text(
              'Booking Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondary,
              ),
            ),
            actions: [
              // View Toggle
              IconButton(
                icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                onPressed: () => setState(() => _isGridView = !_isGridView),
                color: AppTheme.primary,
              ),
              // Filter Button
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded),
                    onPressed: _showFilterBottomSheet,
                    color: AppTheme.primary,
                    tooltip: 'Filter Bookings',
                  ),
                  if (_selectedVehicleType != 'all' ||
                      _selectedBookingType != 'all' ||
                      _selectedStatus != 'all' ||
                      _startDate != null ||
                      _endDate != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search vehicles, customers...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    isDense: true,
                  ),
                ),
              ),
              // Stats Cards
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        statistics['total'].toString(),
                        AppTheme.secondary,
                        Icons.calendar_month,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Office',
                        statistics['office'].toString(),
                        AppTheme.info,
                        Icons.business,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Personal',
                        statistics['personal'].toString(),
                        Colors.green,
                        Icons.person,
                      ),
                    ),
                  ],
                ),
              ),

              // Bookings List/Grid
              Expanded(
                child: isLoading && allBookings.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : allBookings.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _refreshBookings,
                            child: _isGridView
                                ? _buildGridView(paginatedBookings)
                                : _buildListView(
                                    paginatedBookings, allBookings.length),
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: widget.onCreateTap,
            icon: const Icon(Icons.add, size: 22),
            label: const Text(
              'Add Booking',
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
      },
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> bookings, int totalCount) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: bookings.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == bookings.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final booking = bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> bookings) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _buildGridBookingCard(bookings[index]);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final locationDisplay = _getLocationDisplay(booking);
    final isActive = booking['isActive'] == true;
    final bookingType =
        (booking['booking_type'] ?? '').toString().toLowerCase();
    final isOffice = bookingType == 'office' || bookingType == 'official';
    final vehicleType = booking['vehicle_type']?.toString() ?? '';
    final vehicleIcon = _getVehicleTypeIcon(vehicleType);
    final vehicleColor = _getVehicleTypeColor(vehicleType);
    final travelers = booking['travelers'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => widget.onEditTap?.call(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with vehicle and status
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: vehicleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(vehicleIcon, color: vehicleColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['vehicle_number'] ?? 'No Vehicle',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          vehicleType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive ? 'Active' : 'Closed',
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Booking Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOffice
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOffice ? Icons.business : Icons.home,
                      size: 12,
                      color: isOffice ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOffice ? 'Office' : 'Personal',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOffice ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Date Range
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_formatDate(booking['from_date'])} - ${_formatDate(booking['to_date'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationDisplay['primaryLocation'],
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (locationDisplay['hasMultiple'])
                          Text(
                            '+${locationDisplay['count'] - 1} more locations',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF4A4494),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Travelers and Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Travelers
                  if (travelers.isNotEmpty)
                    InkWell(
                      onTap: () => _showTravelersModal(booking),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A4494).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people,
                                size: 12, color: Color(0xFF4A4494)),
                            const SizedBox(width: 4),
                            Text(
                              '${travelers.length} Travelers',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4A4494),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            size: 18, color: Colors.blue),
                        onPressed: () => widget.onEditTap?.call(booking),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 18, color: Colors.red),
                        onPressed: () => _showDeleteDialog(booking),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),

              // Purpose for personal bookings
              if (!isOffice && booking['personal_purpose'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking['personal_purpose'],
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildGridBookingCard(Map<String, dynamic> booking) {
    final locationDisplay = _getLocationDisplay(booking);
    final isActive = booking['isActive'] == true;
    final bookingType =
        (booking['booking_type'] ?? '').toString().toLowerCase();
    final isOffice = bookingType == 'office' || bookingType == 'official';
    final vehicleType = booking['vehicle_type']?.toString() ?? '';
    final vehicleIcon = _getVehicleTypeIcon(vehicleType);
    final vehicleColor = _getVehicleTypeColor(vehicleType);
    final travelers = booking['travelers'] as List? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => widget.onEditTap?.call(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Closed',
                    style: TextStyle(
                      fontSize: 9,
                      color: isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Vehicle Icon and Number
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: vehicleColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(vehicleIcon, color: vehicleColor, size: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking['vehicle_number'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      vehicleType,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Booking Type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isOffice
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOffice ? Icons.business : Icons.home,
                      size: 10,
                      color: isOffice ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        isOffice ? 'Office' : 'Personal',
                        style: TextStyle(
                          fontSize: 9,
                          color: isOffice ? Colors.blue : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Date
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 10, color: Colors.grey),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      _formatDate(booking['from_date']),
                      style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Location
              Row(
                children: [
                  const Icon(Icons.location_on, size: 10, color: Colors.grey),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      locationDisplay['primaryLocation'],
                      style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Travelers
              if (travelers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.people,
                          size: 10, color: Color(0xFF4A4494)),
                      const SizedBox(width: 2),
                      Text(
                        '${travelers.length}',
                        style: const TextStyle(
                          fontSize: 9,
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
      ),
    );
  }

  Widget _buildFilterDateButton(
      String label, DateTime? date, IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                date == null ? label : DateFormat('dd/MM/yyyy').format(date),
                style: TextStyle(
                    fontSize: 11,
                    color: date == null ? Colors.grey[600] : Colors.black),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Bookings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset All'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Vehicle Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _vehicleTypes.map((type) {
                      final isSelected = _selectedVehicleType == type['value'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(type['label']),
                          avatar: Icon(
                            type['icon'],
                            size: 16,
                            color: isSelected ? Colors.white : type['color'],
                          ),
                          onSelected: (_) {
                            setModalState(() {
                              _selectedVehicleType = type['value'];
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: AppTheme.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDateButton(
                        'Start Date',
                        _startDate,
                        Icons.calendar_today_rounded,
                        () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setModalState(() => _startDate = date);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterDateButton(
                        'End Date',
                        _endDate,
                        Icons.calendar_today_rounded,
                        () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setModalState(() => _endDate = date);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'No bookings found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pull down to refresh or Tap + to add',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
