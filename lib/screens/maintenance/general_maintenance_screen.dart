// lib/screens/maintenance/general_maintenance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/special_maintenance_provider.dart';
import '../../core/theme/app_theme.dart';
import './modal/general_maintenance_modal.dart';
import './special_maintenance_screen.dart'; // Import the special maintenance screen

class GeneralMaintenanceScreen extends StatelessWidget {
  const GeneralMaintenanceScreen({super.key});

  @override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Full gradient background like app bar
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primary,
            ),
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: TabBar(
                    tabs: const [
                      Tab(text: 'General'),
                      Tab(text: 'Special'),
                    ],
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white, // Solid white for selected
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: const Color(0xFF4A4494), // Purple text for selected
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(2),
                  ),
                ),
              ),
            ),
          ),
          // Tab Content
          const Expanded(
            child: TabBarView(
              children: [
                _GeneralMaintenanceTab(),
                _SpecialMaintenanceTab(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _GeneralMaintenanceTab extends StatelessWidget {
  const _GeneralMaintenanceTab();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GeneralMaintenanceProvider(),
      child: const _GeneralMaintenanceScreenContent(),
    );
  }
}

class _SpecialMaintenanceTab extends StatelessWidget {
  const _SpecialMaintenanceTab();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SpecialMaintenanceProvider(),
      child: const SpecialMaintenanceScreen(),
    );
  }
}

// Rest of your existing code for _GeneralMaintenanceScreenContent
class _GeneralMaintenanceScreenContent extends StatefulWidget {
  const _GeneralMaintenanceScreenContent();

  @override
  State<_GeneralMaintenanceScreenContent> createState() => _GeneralMaintenanceScreenContentState();
}

class _GeneralMaintenanceScreenContentState extends State<_GeneralMaintenanceScreenContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeneralMaintenanceProvider>().loadGeneralMaintenanceRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralMaintenanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${provider.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadGeneralMaintenanceRecords(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              // Records Count (now at the top)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'General Maintenance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${provider.records.length} Records',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Records List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.loadGeneralMaintenanceRecords(),
                  child: provider.records.isEmpty
                      ? ListView( // Use ListView to enable pull-to-refresh on empty state
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 200),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.build_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No maintenance records found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Pull down to refresh or Tap + to add',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.records.length,
                          itemBuilder: (context, index) {
                            final record = provider.records[index];
                            return _buildMaintenanceCard(context, record);
                          },
                        ),
                ),
              ),
            ],
          ),
          // Floating Action Button for adding new records
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const GeneralMaintenanceModal(),
            ),
          );
        },
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
      },
    );
  }

  Widget _buildMaintenanceCard(BuildContext context, GeneralMaintenanceRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with vehicle info and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A4494).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              record.vehicleNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A4494),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            record.userName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.directions_car_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            record.vehicleType,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => GeneralMaintenanceModal(
                            editingRecord: record,
                            onRefresh: () => context.read<GeneralMaintenanceProvider>().loadGeneralMaintenanceRecords(),
                          ),
                        ),
                      );
                    } else if (value == 'delete') {
                      _showDeleteDialog(record);
                    }
                  },
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Details
            Column(
              children: [
                _buildDetailRow(
                  Icons.calendar_today_outlined,
                  'Date',
                  DateFormat('dd MMM yyyy').format(record.date),
                ),
                _buildDetailRow(
                  Icons.speed_outlined,
                  'KM Reading',
                  '${record.km} km',
                ),
                _buildDetailRow(
                  Icons.currency_rupee_outlined,
                  'Cost',
                  '₹${record.cost.toStringAsFixed(2)}',
                ),
                _buildDetailRow(
                  Icons.description_outlined,
                  'Reason',
                  record.reason,
                ),
                if (record.nextServiceKm > 0)
                  _buildDetailRow(
                    Icons.settings_suggest_outlined,
                    'Next Service',
                    '${record.nextServiceKm} km',
                  ),
                if (record.nextServiceDate != null)
                  _buildDetailRow(
                    Icons.event_outlined,
                    'Next Service Date',
                    DateFormat('dd MMM yyyy').format(record.nextServiceDate!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(GeneralMaintenanceRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this general maintenance record for ${record.vehicleNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<GeneralMaintenanceProvider>(context, listen: false);
      
      await provider.deleteGeneralMaintenance(record.id);
      
      if (mounted) {
        if (provider.apiError == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Record deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: ${provider.apiError}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
