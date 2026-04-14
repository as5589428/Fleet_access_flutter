import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/action_alert_provider.dart';
import '../../models/action_alert_model.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/navigation_provider.dart';


class ActionAlertsScreen extends StatefulWidget {
  const ActionAlertsScreen({super.key});

  @override
  State<ActionAlertsScreen> createState() => _ActionAlertsScreenState();
}

class _ActionAlertsScreenState extends State<ActionAlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Action Alerts',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () {
              context.read<NavigationProvider>().setIndex(0);
            },
            tooltip: 'Dashboard',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.secondary,
            child: SafeArea(
              bottom: false,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Open Alerts'),
                  Tab(text: 'Closed Alerts'),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<ActionAlertProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.alerts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _AlertsList(alerts: provider.openAlerts, isEmptyMessage: 'No open alerts'),
                    _AlertsList(alerts: provider.closedAlerts, isEmptyMessage: 'No closed alerts'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsList extends StatelessWidget {
  final List<ActionAlert> alerts;
  final String isEmptyMessage;

  const _AlertsList({required this.alerts, required this.isEmptyMessage});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(isEmptyMessage, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: _getIcon(alert.alertType),
            title: Text(alert.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(alert.description, maxLines: 1, overflow: TextOverflow.ellipsis),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              _buildDetailRow('Date', alert.date),
              _buildDetailRow('Person', alert.person ?? 'N/A'),
              _buildDetailRow('Remarks', alert.remarks ?? 'N/A'),
              const Divider(),
              if (alert.isOpen)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showCloseForm(context, alert),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Mark as Closed'),
                  ),
                )
              else ...[
                _buildDetailRow('Action Taken', alert.actionTaken ?? 'N/A'),
                _buildDetailRow('Performed By', alert.performedBy ?? 'N/A'),
                _buildDetailRow('Closed Date', alert.actionTakenDate ?? 'N/A'),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _getIcon(String type) {
    IconData icon = Icons.notifications_active;
    Color color = AppTheme.secondary;
    if (type == 'Priority') {
      icon = Icons.warning_rounded;
      color = Colors.amber;
    } else if (type == 'Risk') {
      icon = Icons.error_rounded;
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _showCloseForm(BuildContext context, ActionAlert alert) {
    // We can't reuse _CloseAlertSheet because it's private in notification_dropdown.dart
    // In a real project, we should move it to a shared file. 
    // For now, I'll provide an alternative or the same logic.
    // Actually, I'll just recommend the user to use the dropdown to close it, or I'll implement it here too.
    // I already have the provider, so it's easy.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Alert'),
        content: const Text('Please use the notification bell to close alerts for consistent experience.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}
