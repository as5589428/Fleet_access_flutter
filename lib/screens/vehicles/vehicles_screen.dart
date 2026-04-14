import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class Vehicle {
  final int id;
  final String number;
  final String type;
  final String brand;
  final String model;
  final String status;
  final String fuel;
  final String transmission;
  final int year;
  final int seats;
  final String price;
  final String image;
  final String mileage;
  final List<String> features;

  Vehicle({
    required this.id,
    required this.number,
    required this.type,
    required this.brand,
    required this.model,
    required this.status,
    required this.fuel,
    required this.transmission,
    required this.year,
    required this.seats,
    required this.price,
    required this.image,
    required this.mileage,
    required this.features,
  });
}

class VehicleFleetScreen extends StatefulWidget {
  const VehicleFleetScreen({super.key});

  @override
  State<VehicleFleetScreen> createState() => _VehicleFleetScreenState();
}

class _VehicleFleetScreenState extends State<VehicleFleetScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showStats = true;
  double _lastScrollOffset = 0;

  final List<Vehicle> vehicles = [
    Vehicle(
      id: 1,
      number: 'KA-01-AB-1234',
      type: 'Sedan',
      brand: 'Toyota',
      model: 'Camry',
      status: 'Available',
      fuel: 'Petrol',
      transmission: 'Automatic',
      year: 2023,
      seats: 5,
      price: '\$45/day',
      image: 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=400&h=300&fit=crop',
      mileage: '15 kmpl',
      features: ['AC', 'Bluetooth', 'GPS', 'Camera'],
    ),
    Vehicle(
      id: 2,
      number: 'KA-01-CD-5678',
      type: 'SUV',
      brand: 'Honda',
      model: 'CR-V',
      status: 'Booked',
      fuel: 'Petrol',
      transmission: 'Automatic',
      year: 2024,
      seats: 7,
      price: '\$65/day',
      image: 'https://images.unsplash.com/photo-1603584173870-7f23fdae1b7a?w=400&h=300&fit=crop',
      mileage: '12 kmpl',
      features: ['AC', 'Sunroof', 'Camera', 'Leather'],
    ),
    Vehicle(
      id: 3,
      number: 'KA-01-EF-9012',
      type: 'Hatchback',
      brand: 'Hyundai',
      model: 'i20',
      status: 'Maintenance',
      fuel: 'Diesel',
      transmission: 'Manual',
      year: 2023,
      seats: 5,
      price: '\$35/day',
      image: 'https://images.unsplash.com/photo-1621135802920-133df287f89c?w=400&h=300&fit=crop',
      mileage: '20 kmpl',
      features: ['AC', 'Music', 'Parking'],
    ),
    Vehicle(
      id: 4,
      number: 'KA-01-GH-3456',
      type: 'SUV',
      brand: 'Ford',
      model: 'EcoSport',
      status: 'Available',
      fuel: 'Petrol',
      transmission: 'Automatic',
      year: 2023,
      seats: 5,
      price: '\$50/day',
      image: 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=400&h=300&fit=crop',
      mileage: '14 kmpl',
      features: ['AC', 'GPS', 'Camera'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    
    if (currentOffset > _lastScrollOffset + 20 && currentOffset > 100) {
      // Scrolling down - hide stats
      if (_showStats) {
        setState(() {
          _showStats = false;
        });
      }
    } else if (currentOffset < _lastScrollOffset - 10) {
      // Scrolling up - show stats
      if (!_showStats) {
        setState(() {
          _showStats = true;
        });
      }
    }
    
    _lastScrollOffset = currentOffset;
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return AppTheme.success;
      case 'Booked':
        return AppTheme.info;
      case 'Maintenance':
        return AppTheme.warning;
      default:
        return AppTheme.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Vehicle Fleet'),
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              elevation: 0,
              pinned: true,
              floating: true,
              snap: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: AppTheme.primary),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.filter_list_rounded, color: AppTheme.primary),
                  onPressed: () {},
                ),
                Container(
                  margin: EdgeInsets.only(right: 12, left: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add, color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ];
        },
        body: Column(
          children: [
            // Stats Section - Animated
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: _showStats ? null : 0,
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Summary Cards
                    // Filter Chips
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      height: 46,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('All Vehicles', true),
                          SizedBox(width: 8),
                          _buildFilterChip('Available', false),
                          SizedBox(width: 8),
                          _buildFilterChip('Booked', false),
                          SizedBox(width: 8),
                          _buildFilterChip('Maintenance', false),
                          SizedBox(width: 8),
                          _buildFilterChip('SUV', false),
                          SizedBox(width: 8),
                          _buildFilterChip('Sedan', false),
                        ],
                      ),
                    ),

                    SizedBox(height: 12),

                    // Vehicle Count
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${vehicles.length} Vehicles',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Showing all',
                            style: TextStyle(
                              color: AppTheme.neutral,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Vehicles List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  return _vehicleCard(context, vehicles[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFilterChip(String label, bool selected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppTheme.primary : AppTheme.neutral.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppTheme.neutral,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _vehicleCard(BuildContext context, Vehicle vehicle) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Status
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  vehicle.image,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Status Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor(vehicle.status).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vehicle.status,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Price Tag
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    vehicle.price,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${vehicle.brand} ${vehicle.model}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${vehicle.year} • ${vehicle.type}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.neutral,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        vehicle.number,
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Specifications
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _specItem(Icons.local_gas_station, vehicle.fuel),
                    _specItem(Icons.speed, vehicle.mileage),
                    _specItem(Icons.people, '${vehicle.seats}'),
                    _specItem(Icons.settings, vehicle.transmission),
                  ],
                ),

                SizedBox(height: 8),

                // Features
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: vehicle.features.map((feature) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.neutral.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.neutral,
                      ),
                    ),
                  )).toList(),
                ),

                SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.remove_red_eye, size: 14),
                        label: Text('Details', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Colors.white, size: 16),
                        onPressed: () {},
                        padding: EdgeInsets.all(6),
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete_outline, color: AppTheme.danger, size: 16),
                        onPressed: () {},
                        padding: EdgeInsets.all(6),
                      ),
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

  Widget _specItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 14, color: AppTheme.primary),
        SizedBox(height: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            color: AppTheme.neutral,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
