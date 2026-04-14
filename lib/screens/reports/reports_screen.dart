import 'package:flutter/material.dart';
import 'package:fleet_management/widgets/custom_drawer.dart'; // Adjust the path as needed
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> clientReports = [
      {
        'title': 'Monthly Mileage Summary',
        'description': 'Total distance traveled, fuel consumption, and cost analysis',
        'date': 'Dec 2024',
        'status': 'Generated',
      },
      {
        'title': 'Vehicle Utilization Report',
        'description': 'Usage patterns, idle time, and efficiency metrics',
        'date': 'Dec 2024',
        'status': 'Pending',
      },
      {
        'title': 'Maintenance Schedule',
        'description': 'Upcoming services and maintenance requirements',
        'date': 'Nov 2024',
        'status': 'Generated',
      },
    ];

    final List<Map<String, String>> ownerReports = [
      {
        'title': 'Fleet Performance Dashboard',
        'description': 'Overall fleet efficiency and performance metrics',
        'date': 'Dec 2024',
        'status': 'Generated',
      },
      {
        'title': 'Cost Analysis Report',
        'description': 'Fuel costs, maintenance expenses, and total ownership cost',
        'date': 'Dec 2024',
        'status': 'Generated',
      },
      {
        'title': 'Driver Behavior Analysis',
        'description': 'Speed patterns, braking habits, and safety metrics',
        'date': 'Nov 2024',
        'status': 'Pending',
      },
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(), // Make sure to import CustomDrawer
      appBar: AppBar(
        title: const Text('Reports'),
        automaticallyImplyLeading: false, // This removes the back button
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open the drawer using the key
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Client Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...clientReports.map((report) => _buildReportCard(report)),
            const SizedBox(height: 24),
            const Text('Owner Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...ownerReports.map((report) => _buildReportCard(report)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, String> report) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(report['title'] ?? ''),
        subtitle: Text(report['description'] ?? ''),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: report['status'] == 'Generated' ? Colors.green[100] : Colors.yellow[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            report['status'] ?? '',
            style: TextStyle(
              color: report['status'] == 'Generated' ? Colors.green[800] : Colors.yellow[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
