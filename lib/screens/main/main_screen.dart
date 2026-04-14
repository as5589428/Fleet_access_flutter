// lib/screens/main/main_screen.dart
import 'package:flutter/material.dart';
import 'package:fleet_management/widgets/custom_drawer.dart';
import 'package:fleet_management/widgets/custom_app_bar.dart';
import 'package:fleet_management/screens/dashboard/dashboard_screen.dart';
import 'package:fleet_management/screens/master/master_page.dart';
import 'package:fleet_management/screens/booking/booking_list_screen.dart';
import 'package:fleet_management/screens/maintenance/general_maintenance_screen.dart';
import 'package:fleet_management/screens/fuel/fuel.dart';
import 'package:fleet_management/screens/servicehistory/service_history_screen.dart';
import '../../screens/closing/closing_list_screen.dart';
// Import BookingFormScreen
import 'package:fleet_management/screens/booking/bookings_screen.dart';
// Import Time Extension Screen
import '../../screens/timeextension/time_extension_screen.dart';
import 'package:provider/provider.dart';
import 'package:fleet_management/providers/time_extension_provider.dart';
import 'package:fleet_management/providers/navigation_provider.dart';
import 'package:fleet_management/screens/master/service_master_screen.dart';
import 'package:fleet_management/screens/master/vehicle_start_screen.dart';
import 'package:fleet_management/screens/collection/collection_delivery_screen.dart';
import 'package:fleet_management/screens/master/action_alerts_screen.dart';
import 'package:fleet_management/screens/main/profile_screen.dart';

// Placeholder screens for other sections

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(child: Text('Trips Screen')),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(child: Text('Reports Screen')),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Track if we're in "create" or "edit" mode for any screen
  bool _isCreating = false;
  bool _isEditing = false;
  Map<String, dynamic>? _editingData;

  // Define all screens here - INCLUDING Time Extension
  final List<Widget> _screens = [
    const DashboardScreen(), // 0
    const VehicleMasterScreen(), // 1
    const ServiceMasterScreen(), // 2
    const BookingListScreen(onCreateTap: null, onEditTap: null), // 3
    const GeneralMaintenanceScreen(), // 4
    const FuelScreen(), // 5
    const ServiceHistoryScreen(), // 6
    const ProfileScreen(), // 7
    const VehicleStartScreen(), // 8
    const ClosingListScreen(), // 9
    ChangeNotifierProvider(
      // 10
      create: (context) => TimeExtensionProvider(),
      child: TimeExtensionScreen(),
    ),
    const CollectionDeliveryScreen(), // 11
    const ActionAlertsScreen(), // 12
  ];

  // Titles for AppBar based on selected index
  final List<String> _screenTitles = [
    'Dashboard',
    'Vehicle Master',
    'Service Master',
    'Booking',
    'Maintenance',
    'Fuel',
    'Service History',
    'Profile',
    'Vehicle Start',
    'Closing',
    'Time Extension',
    'Collection & Delivery',
    'Action Alerts',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isCreating = false;
      _isEditing = false;
      _editingData = null;
    });

    // Close drawer if open
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  // Callback for creating new items
  void _onCreateTap() {
    setState(() {
      _isCreating = true;
      _isEditing = false;
      _editingData = null;
    });
  }

  // Callback for editing items
  void _onEditTap(Map<String, dynamic> data) {
    setState(() {
      _isCreating = false;
      _isEditing = true;
      _editingData = data;
    });
  }

  // Callback to return to list view
  void _onBackToList() {
    setState(() {
      _isCreating = false;
      _isEditing = false;
      _editingData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    _selectedIndex = navProvider.selectedIndex;

    // Determine what to show in the content area
    Widget contentWidget;

    if (_selectedIndex == 3) {
      // Booking screen index
      if (_isCreating) {
        contentWidget = BookingFormScreen(
          onCancel: _onBackToList,
          onSave: _onBackToList,
        );
      } else if (_isEditing && _editingData != null) {
        contentWidget = BookingFormScreen(
          booking: _editingData,
          isEditing: true,
          onCancel: _onBackToList,
          onSave: _onBackToList,
        );
      } else {
        contentWidget = BookingListScreen(
          onCreateTap: _onCreateTap,
          onEditTap: _onEditTap,
        );
      }
    } else {
      contentWidget = _screens[_selectedIndex];
    }

    // Determine title
    String title;
    if (_isCreating) {
      title = 'Create New Booking';
    } else if (_isEditing) {
      title = 'Edit Booking';
    } else {
      title = _screenTitles[_selectedIndex];
    }

    bool hideAppBar =
        _selectedIndex == 2 || _selectedIndex == 8 || _selectedIndex == 12;

    return Scaffold(
      key: _scaffoldKey,
      appBar: hideAppBar
          ? null
          : CustomAppBar(
              title: title,
              // Profile icon completely removed - set to false for all screens
              showProfile: false,
              onMenuTap: () {
                if (_isCreating || _isEditing) {
                  _onBackToList();
                } else {
                  _scaffoldKey.currentState?.openDrawer();
                }
              },
              leading: _isCreating || _isEditing
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _onBackToList,
                    )
                  : null,
              actions: _buildAppBarActions(),
            ),
      drawer: CustomDrawer(
        onItemSelected: (index) {
          context.read<NavigationProvider>().setIndex(index);
          _onItemTapped(index);
        },
        selectedIndex: _selectedIndex,
      ),
      body: contentWidget,
    );
  }

  List<Widget> _buildAppBarActions() {
    // If we're in create/edit mode, show only Save button (if needed)
    if (_isCreating || _isEditing) {
      return [];
    }

    // Show actions based on selected screen
    switch (_selectedIndex) {
      case 0: // Dashboard
        return [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading dashboard report...')),
              );
            },
            tooltip: 'Download Report',
          ),
        ];
      case 1: // Vehicle Master
        return [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vehicle filtering coming soon!')),
              );
            },
            tooltip: 'Filter',
          ),
        ];
      case 2: // Service Master
        return [];
      case 3: // Booking
        return [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking filtering coming soon!')),
              );
            },
            tooltip: 'Filter',
          ),
        ];
      case 4: // Maintenance
        return [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Maintenance filtering coming soon!')),
              );
            },
            tooltip: 'Filter',
          ),
        ];
      case 5: // Fuel
        return [];
      case 6: // Service History
        return [];
      case 7: // Profile
        return [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
            tooltip: 'Edit Profile',
          ),
        ];
      case 8: // Vehicle Start
        return [];
      case 9: // Closing
        return [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting closing reports...')),
              );
            },
            tooltip: 'Download',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Closing entries filtering coming soon!')),
              );
            },
            tooltip: 'Filter',
          ),
        ];
      case 10: // Time Extension
        return [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Time extension filtering coming soon!')),
              );
            },
            tooltip: 'Filter',
          ),
        ];
      default:
        return [];
    }
  }
}
