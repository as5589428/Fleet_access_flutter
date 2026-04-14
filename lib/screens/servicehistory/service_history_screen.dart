// lib/screens/maintenance/service_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/service_history_provider.dart';
import '../../core/theme/app_theme.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  // Filter state
  String _selectedFilter = 'All';
  final List<Map<String, dynamic>> _filterOptions = [
    {'label': 'All', 'icon': Icons.all_inclusive, 'color': Colors.grey},
    {
      'label': 'Battery',
      'icon': Icons.battery_charging_full,
      'color': Colors.green
    },
    {'label': 'Tyre', 'icon': Icons.directions_car, 'color': Colors.red},
    {'label': 'Wheel', 'icon': Icons.settings, 'color': Colors.blue},
    {'label': 'General', 'icon': Icons.build, 'color': Colors.orange},
  ];

  // Helper function to safely parse dates
  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Helper function to safely format dates
  String _formatDate(String? dateString, {String format = 'dd MMM yyyy'}) {
    final date = _parseDate(dateString);
    if (date == null) return 'N/A';
    return DateFormat(format).format(date);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<ServiceHistoryProvider>(context, listen: false);
      provider.loadServiceHistory();
    });
  }

  Widget _buildFilterChip() {
    final selectedOption = _filterOptions.firstWhere(
      (option) => option['label'] == _selectedFilter,
      orElse: () => _filterOptions[0],
    );

    return GestureDetector(
      onTap: _showFilterDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedFilter == 'All'
              ? Colors.grey[100]
              : selectedOption['color'].withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedFilter == 'All'
                ? Colors.grey[300]!
                : selectedOption['color'],
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selectedOption['icon'],
              size: 16,
              color: _selectedFilter == 'All'
                  ? Colors.grey
                  : selectedOption['color'],
            ),
            const SizedBox(width: 8),
            Text(
              _selectedFilter,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _selectedFilter == 'All'
                    ? Colors.grey
                    : selectedOption['color'],
              ),
            ),
            if (_selectedFilter != 'All') ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = 'All';
                  });
                },
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: selectedOption['color'],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter by Service Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Filter Options
              Column(
                children: _filterOptions.map((option) {
                  final label = option['label'] as String;
                  final icon = option['icon'] as IconData;
                  final color = option['color'] as Color;
                  final isSelected = _selectedFilter == label;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                    title: Text(
                      label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? color : Colors.black,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: color, size: 20)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedFilter = label;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filter'),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> data) {
    final totalCost = data['total_cost'] ?? 0;
    final drivenKm = data['driven_km'] ?? 0;
    final totalServices = data['total_services'] ?? 0;
    final batteryCount = data['battery_count'] ?? 0;
    final tyreCount = data['tyre_count'] ?? 0;
    final wheelCount = data['wheel_balance_count'] ?? 0;
    final generalCount = data['general_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.assessment, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total Services: $totalServices',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total Cost Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Cost',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${NumberFormat('#,##0').format(totalCost)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.speed,
                              size: 14, color: AppTheme.secondary),
                          const SizedBox(width: 6),
                          Text(
                            '${NumberFormat('#,##0').format(drivenKm)} km',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Service Type Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(batteryCount, 'Battery',
                  Icons.battery_charging_full, Colors.green),
              _buildStatItem(
                  tyreCount, 'Tyres', Icons.directions_car, Colors.red),
              _buildStatItem(wheelCount, 'Wheel', Icons.settings, Colors.blue),
              _buildStatItem(
                  generalCount, 'Service', Icons.build, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(int count, String title, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceSection({
    required String title,
    required List<dynamic> items,
    required IconData icon,
    required Color color,
  }) {
    // Filter items based on selected filter
    final filteredItems = _selectedFilter == 'All'
        ? items
        : items.where((item) {
            final serviceType = item['service_type']?.toString() ?? '';
            switch (_selectedFilter) {
              case 'Battery':
                return serviceType == 'battery';
              case 'Tyre':
                return serviceType == 'tyre';
              case 'Wheel':
                return serviceType == 'wheel_balancing';
              case 'General':
                return serviceType == 'general';
              default:
                return true;
            }
          }).toList();

    if (filteredItems.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredItems.length}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Service Items
          Column(
            children: filteredItems
                .map((item) => _buildServiceItem(
                      item: item as Map<String, dynamic>,
                      color: color,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required Map<String, dynamic> item,
    required Color color,
  }) {
    final serviceType = item['service_type']?.toString() ?? '';
    final details = item['details'] as Map<String, dynamic>? ?? {};
    final cost = (item['cost'] as num?)?.toDouble() ?? 0;
    final date = item['date']?.toString();
    final vehicleNumber = item['vehicle_number']?.toString() ?? 'N/A';
    final remarks = item['remarks']?.toString() ?? '';
    final billUpload = details['bill_upload'] as List? ?? [];

    // Get service title
    String getServiceTitle() {
      switch (serviceType) {
        case 'battery':
          return 'Battery Replacement';
        case 'tyre':
          return 'Tyre Change';
        case 'wheel_balancing':
          return 'Wheel Balancing';
        case 'general':
          return 'General Service';
        default:
          return 'Service';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[100]!,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getServiceTitle(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.directions_car,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vehicleNumber,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '₹${NumberFormat('#,##0').format(cost)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Service-specific details
              if (serviceType == 'battery') ..._buildBatteryDetails(details),
              if (serviceType == 'tyre') ..._buildTyreDetails(details),
              if (serviceType == 'wheel_balancing')
                ..._buildWheelDetails(details),
              if (serviceType == 'general') ..._buildGeneralDetails(details),

              // Remarks
              if (remarks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.message, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          remarks,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Bill Image
          if (billUpload.isNotEmpty &&
              billUpload.first.toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildBillImageButton(billUpload.first.toString()),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildBatteryDetails(Map<String, dynamic> details) {
    return [
      if (details['si_no'] != null && details['si_no'].toString().isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.receipt, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                'SI: ${details['si_no']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      if (details['warranty_date'] != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.verified, size: 12, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                'Warranty: ${_formatDate(details['warranty_date']?.toString())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildTyreDetails(Map<String, dynamic> details) {
    return [
      if (details['km'] != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.speed, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                '${details['km']} km',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildWheelDetails(Map<String, dynamic> details) {
    return [
      if (details['km'] != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.speed, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                '${details['km']} km',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      if (details['due_km'] != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.timeline, size: 12, color: Colors.blue),
              const SizedBox(width: 6),
              Text(
                'Due at: ${details['due_km']} km',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildGeneralDetails(Map<String, dynamic> details) {
    return [
      if (details['reason'] != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.info, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                details['reason'].toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      if (details['next_service_date'] != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.date_range, size: 12, color: Colors.orange),
              const SizedBox(width: 6),
              Text(
                'Next: ${_formatDate(details['next_service_date']?.toString())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _buildBillImageButton(String imageUrl) {
    return GestureDetector(
      onTap: () => _showImageDialog(imageUrl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt, size: 14, color: Colors.blue[600]),
            const SizedBox(width: 6),
            Text(
              'View Bill',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                0.8, // Limit to 80% of screen height
          ),
          child: Stack(
            children: [
              // Image Container
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: _getFullImageUrl(imageUrl),
                        fit: BoxFit.contain,
                        placeholder: (context, url) => SizedBox(
                          height: 200, // Reduced height
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => SizedBox(
                          height: 200, // Reduced height
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.grey[400],
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Close Button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFullImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // Check if it's a local file path or a relative path
    if (imagePath.startsWith('/') || imagePath.contains('storage')) {
      // Construct full URL for uploaded images
      return 'https://fleet-vehicle-mgmt-backend-2.onrender.com/${imagePath.replaceFirst('undefined/', '')}';
    }

    // If it's just a filename, construct the full URL
    return 'https://fleet-vehicle-mgmt-backend-2.onrender.com/storage/$imagePath';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Service History...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final provider =
                    Provider.of<ServiceHistoryProvider>(context, listen: false);
                provider.loadServiceHistory();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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

  Widget _buildEmptyState({bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_toggle_off,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isFiltered ? 'No Matching Services' : 'No Service History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isFiltered
                  ? 'No services found for the selected filter'
                  : 'Service history will appear here once available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'All';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear Filter'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<ServiceHistoryProvider>(
        builder: (context, provider, child) {
          // Show loading
          if (provider.isLoading) {
            return _buildLoadingState();
          }

          // Show error
          if (provider.errorMessage != null) {
            return _buildErrorState(provider.errorMessage!);
          }

          final data = provider.serviceHistory;

          if (data == null) {
            return _buildEmptyState();
          }

          // Check if we have any services
          final batteryServices = data['battery_change'] as List? ?? [];
          final tyreServices = data['tyre_change'] as List? ?? [];
          final wheelServices = data['wheel_balancing'] as List? ?? [];
          final generalServices = data['general_service'] as List? ?? [];

          // Apply filter to determine if any sections have items
          final hasBatteryServices =
              _selectedFilter == 'All' || _selectedFilter == 'Battery'
                  ? batteryServices.isNotEmpty
                  : false;

          final hasTyreServices =
              _selectedFilter == 'All' || _selectedFilter == 'Tyre'
                  ? tyreServices.isNotEmpty
                  : false;

          final hasWheelServices =
              _selectedFilter == 'All' || _selectedFilter == 'Wheel'
                  ? wheelServices.isNotEmpty
                  : false;

          final hasGeneralServices =
              _selectedFilter == 'All' || _selectedFilter == 'General'
                  ? generalServices.isNotEmpty
                  : false;

          final hasServices = hasBatteryServices ||
              hasTyreServices ||
              hasWheelServices ||
              hasGeneralServices;

          if (!hasServices) {
            return _buildEmptyState(isFiltered: _selectedFilter != 'All');
          }

          // Create list of all sections with their data
          final List<Map<String, dynamic>> sections = [];

          if (hasBatteryServices) {
            sections.add({
              'title': 'Battery Changes',
              'items': batteryServices,
              'icon': Icons.battery_charging_full,
              'color': Colors.green,
            });
          }

          if (hasTyreServices) {
            sections.add({
              'title': 'Tyre Changes',
              'items': tyreServices,
              'icon': Icons.directions_car,
              'color': Colors.red,
            });
          }

          if (hasWheelServices) {
            sections.add({
              'title': 'Wheel Balancing',
              'items': wheelServices,
              'icon': Icons.settings,
              'color': Colors.blue,
            });
          }

          if (hasGeneralServices) {
            sections.add({
              'title': 'General Services',
              'items': generalServices,
              'icon': Icons.build,
              'color': Colors.orange,
            });
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadServiceHistory(),
            color: AppTheme.secondary,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Custom Header
                  Container(
                    padding: const EdgeInsets.only(
                        top: 40, bottom: 20, left: 24, right: 24),
                    decoration: const BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service History',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Filter Section
                        Row(
                          children: [
                            Text(
                              'Filter by:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildFilterChip(),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Summary Card (always show, but with filtered counts)
                  if (_selectedFilter == 'All') _buildSummaryCard(data),

                  // Service Sections
                  ...sections.map((section) => _buildServiceSection(
                        title: section['title'],
                        items: section['items'],
                        icon: section['icon'],
                        color: section['color'],
                      )),

                  const SizedBox(height: 30),

                  // Filter Status Info
                  if (_selectedFilter != 'All')
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _filterOptions
                            .firstWhere(
                              (opt) => opt['label'] == _selectedFilter,
                              orElse: () => _filterOptions[0],
                            )['color']
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _filterOptions
                              .firstWhere(
                                (opt) => opt['label'] == _selectedFilter,
                                orElse: () => _filterOptions[0],
                              )['color']
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_alt,
                            size: 14,
                            color: _filterOptions.firstWhere(
                              (opt) => opt['label'] == _selectedFilter,
                              orElse: () => _filterOptions[0],
                            )['color'],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Showing only $_selectedFilter services',
                              style: TextStyle(
                                fontSize: 12,
                                color: _filterOptions.firstWhere(
                                  (opt) => opt['label'] == _selectedFilter,
                                  orElse: () => _filterOptions[0],
                                )['color'],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = 'All';
                              });
                            },
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 12,
                                color: _filterOptions.firstWhere(
                                  (opt) => opt['label'] == _selectedFilter,
                                  orElse: () => _filterOptions[0],
                                )['color'],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Bottom Info
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pull down to refresh service history',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
