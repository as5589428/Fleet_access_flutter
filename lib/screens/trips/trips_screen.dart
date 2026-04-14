import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/status_badge.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Trips'),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: () => context.read<TripProvider>().loadTrips(),
        child: Consumer<TripProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.danger,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading trips',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(provider.error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.loadTrips(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (provider.trips.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 64,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No trips found',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text('Trips will appear here once they are assigned'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.trips.length,
              itemBuilder: (context, index) {
                final trip = provider.trips[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                trip.vehicleNumber,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            StatusBadge(status: trip.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (trip.driverName != null)
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Driver: ${trip.driverName}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        if (trip.startTime != null)
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Started: ${DateFormat('MMM dd, yyyy HH:mm').format(trip.startTime!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        if (trip.endTime != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.flag, size: 16, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Ended: ${DateFormat('MMM dd, yyyy HH:mm').format(trip.endTime!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                        if (trip.startKm != null || trip.endKm != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.neutral,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (trip.startKm != null)
                                  Text('Start: ${trip.startKm} km'),
                                if (trip.endKm != null)
                                  Text('End: ${trip.endKm} km'),
                                if (trip.startKm != null && trip.endKm != null)
                                  Text(
                                    'Distance: ${trip.totalKm.toStringAsFixed(1)} km',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        if (trip.status == 'PENDING') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showStartTripDialog(trip.id),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Trip'),
                            ),
                          ),
                        ],
                        if (trip.status == 'IN_PROGRESS') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showExtendTripDialog(trip.id),
                                  icon: const Icon(Icons.access_time),
                                  label: const Text('Extend'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.warning,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showEndTripDialog(trip.id),
                                  icon: const Icon(Icons.stop),
                                  label: const Text('End Trip'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showStartTripDialog(String tripId) {
    final startKmController = TextEditingController();
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: startKmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Start Kilometers',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (startKmController.text.isNotEmpty) {
                context.read<TripProvider>().startTrip(
                  tripId: tripId,
                  startKm: double.parse(startKmController.text),
                  remarks: remarksController.text.isNotEmpty ? remarksController.text : null,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showEndTripDialog(String tripId) {
    final endKmController = TextEditingController();
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: endKmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'End Kilometers',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (endKmController.text.isNotEmpty) {
                context.read<TripProvider>().endTrip(
                  tripId: tripId,
                  endKm: double.parse(endKmController.text),
                  remarks: remarksController.text.isNotEmpty ? remarksController.text : null,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('End Trip'),
          ),
        ],
      ),
    );
  }

  void _showExtendTripDialog(String tripId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Extension'),
        content: const Text('This feature allows requesting time extension for the current trip.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Extension request sent'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }
}
