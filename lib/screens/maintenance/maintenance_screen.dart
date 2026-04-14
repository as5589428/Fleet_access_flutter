// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/maintenance_provider.dart';
// import '../../widgets/custom_app_bar.dart';
// import '../../widgets/custom_drawer.dart';
// import '../../core/theme/app_theme.dart';
// import 'package:intl/intl.dart';

// class MaintenanceScreen extends StatefulWidget {
//   const MaintenanceScreen({super.key});

//   @override
//   State<MaintenanceScreen> createState() => _MaintenanceScreenState();
// }

// class _MaintenanceScreenState extends State<MaintenanceScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<MaintenanceProvider>().loadMaintenanceRecords();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(
//         title: 'Maintenance',
//         actions: [
//           Container(
//             margin: const EdgeInsets.only(right: 8),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [AppTheme.primary, AppTheme.secondary],
//                 begin: Alignment.centerLeft,
//                 end: Alignment.centerRight,
//               ),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: IconButton(
//               icon: const Icon(Icons.add, color: Colors.white, size: 20),
//               onPressed: () => _showAddMaintenanceDialog(),
//             ),
//           ),
//         ],
//       ),
//       drawer: const CustomDrawer(),
//       body: Consumer<MaintenanceProvider>(
//         builder: (context, provider, child) {
//           if (provider.isLoading) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }

//           if (provider.error != null) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: AppTheme.danger.withValues(alpha: 0.1),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.error_outline,
//                       size: 48,
//                       color: AppTheme.danger,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     'Unable to Load Records',
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       color: AppTheme.primary,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 40),
//                     child: Text(
//                       provider.error!,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         color: AppTheme.neutral,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Container(
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [AppTheme.primary, AppTheme.secondary],
//                         begin: Alignment.centerLeft,
//                         end: Alignment.centerRight,
//                       ),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: ElevatedButton(
//                       onPressed: () => provider.loadMaintenanceRecords(),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.transparent,
//                         shadowColor: Colors.transparent,
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       ),
//                       child: const Text(
//                         'Try Again',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }

//           if (provider.records.isEmpty) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(32),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(24),
//                       decoration: BoxDecoration(
//                         color: AppTheme.primary.withValues(alpha: 0.1),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.build_circle_outlined,
//                         size: 64,
//                         color: AppTheme.primary,
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     Text(
//                       'No Maintenance Records',
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         color: AppTheme.primary,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       'Start by adding your first maintenance record',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: AppTheme.neutral,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     Container(
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [AppTheme.primary, AppTheme.secondary],
//                           begin: Alignment.centerLeft,
//                           end: Alignment.centerRight,
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: ElevatedButton.icon(
//                         onPressed: () => _showAddMaintenanceDialog(),
//                         icon: const Icon(Icons.add, color: Colors.white, size: 18),
//                         label: const Text(
//                           'Add First Record',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.transparent,
//                           shadowColor: Colors.transparent,
//                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }

//           return RefreshIndicator(
//             onRefresh: () => context.read<MaintenanceProvider>().loadMaintenanceRecords(),
//             child: Column(
//               children: [
//                 // Summary Cards
//                 // Container(
//                 //   padding: const EdgeInsets.all(16),
//                 //   child: GridView.count(
//                 //     shrinkWrap: true,
//                 //     physics: const NeverScrollableScrollPhysics(),
//                 //     crossAxisCount: 2,
//                 //     childAspectRatio: 1.4,
//                 //     crossAxisSpacing: 12,
//                 //     mainAxisSpacing: 12,
//                 //     children: [
//                 //       _buildSummaryCard('Total Records', provider.records.length, Icons.list_alt, AppTheme.primary),
//                 //       _buildSummaryCard('This Month', _getThisMonthCount(provider.records), Icons.calendar_month, AppTheme.success),
//                 //       _buildSummaryCard('Pending', _getPendingCount(provider.records), Icons.schedule, AppTheme.warning),
//                 //       _buildSummaryCard('Total Cost', _getTotalCost(provider.records), Icons.currency_rupee, AppTheme.info),
//                 //     ],
//                 //   ),
//                 // ),

//                 // Filter Chips
//                 // Container(
//                 //   padding: const EdgeInsets.symmetric(horizontal: 16),
//                 //   height: 50,
//                 //   child: ListView(
//                 //     scrollDirection: Axis.horizontal,
//                 //     children: [
//                 //       _buildFilterChip('All', true),
//                 //       const SizedBox(width: 8),
//                 //       _buildFilterChip('General Service', false),
//                 //       const SizedBox(width: 8),
//                 //       _buildFilterChip('Tyre Service', false),
//                 //       const SizedBox(width: 8),
//                 //       _buildFilterChip('Battery', false),
//                 //       const SizedBox(width: 8),
//                 //       _buildFilterChip('This Month', false),
//                 //     ],
//                 //   ),
//                 // ),

//                 const SizedBox(height: 8),

//                 // List Header
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         '${provider.records.length} Records',
//                         style: const TextStyle(
//                           color: AppTheme.primary,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                         ),
//                       ),
//                       Text(
//                         'Last 30 days',
//                         style: TextStyle(
//                           color: AppTheme.neutral,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 12),

//                 // Records List
//                 Expanded(
//                   child: ListView.builder(
//                     padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                     itemCount: provider.records.length,
//                     itemBuilder: (context, index) {
//                       final record = provider.records[index];
//                       return _buildMaintenanceCard(context, record);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSummaryCard(String title, dynamic value, IconData icon, Color color) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.06),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(6),
//               decoration: BoxDecoration(
//                 color: color.withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(icon, color: color, size: 18),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value is double ? '₹${value.toStringAsFixed(0)}' : value.toString(),
//               style: TextStyle(
//                 color: AppTheme.primary,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               title,
//               style: TextStyle(
//                 color: AppTheme.neutral,
//                 fontSize: 11,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFilterChip(String label, bool selected) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: selected ? AppTheme.primary : Colors.transparent,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: selected ? AppTheme.primary : AppTheme.neutral.withValues(alpha: 0.3),
//         ),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: selected ? Colors.white : AppTheme.neutral,
//           fontSize: 12,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );
//   }

//   Widget _buildMaintenanceCard(BuildContext context, MaintenanceRecord record) {
//     final typeColor = _getTypeColor(record.type);
    
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Row
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: typeColor.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     _getTypeIcon(record.type),
//                     color: typeColor,
//                     size: 18,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         record.vehicleNumber,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: AppTheme.primary,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         record.reason,
//                         style: const TextStyle(
//                           fontSize: 13,
//                           color: AppTheme.neutral,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: typeColor.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: typeColor),
//                   ),
//                   child: Text(
//                     record.type,
//                     style: TextStyle(
//                       color: typeColor,
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 12),

//             // Details Row
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildDetailItem(Icons.calendar_today, DateFormat('MMM dd, yyyy').format(record.serviceDate)),
//                 _buildDetailItem(Icons.speed, '${record.kilometers} km'),
//                 _buildDetailItem(Icons.currency_rupee, '₹${record.cost.toStringAsFixed(0)}'),
//               ],
//             ),

//             // Next Service Reminder
//             if (record.nextServiceDate != null) ...[
//               const SizedBox(height: 12),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: AppTheme.primary.withValues(alpha: 0.05),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.schedule, size: 16, color: AppTheme.primary),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         'Next service: ${DateFormat('MMM dd, yyyy').format(record.nextServiceDate!)}${record.nextServiceKm != null ? ' or ${record.nextServiceKm} km' : ''}',
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: AppTheme.primary,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],

//             // Remarks
//             if (record.remarks != null && record.remarks!.isNotEmpty) ...[
//               const SizedBox(height: 12),
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: AppTheme.neutral.withValues(alpha: 0.05),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   record.remarks!,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: AppTheme.neutral,
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailItem(IconData icon, String text) {
//     return Row(
//       children: [
//         Icon(icon, size: 14, color: AppTheme.neutral),
//         const SizedBox(width: 4),
//         Text(
//           text,
//           style: const TextStyle(
//             fontSize: 12,
//             color: AppTheme.neutral,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   Color _getTypeColor(String type) {
//     switch (type.toUpperCase()) {
//       case 'GENERAL SERVICE':
//         return AppTheme.primary;
//       case 'TYRE REPLACEMENT':
//         return AppTheme.warning;
//       case 'BATTERY CHANGE':
//         return AppTheme.secondary;
//       case 'WHEEL BALANCING':
//         return AppTheme.success;
//       case 'OIL CHANGE':
//         return AppTheme.info;
//       case 'BRAKE SERVICE':
//         return AppTheme.danger;
//       default:
//         return AppTheme.neutral;
//     }
//   }

//   IconData _getTypeIcon(String type) {
//     switch (type.toUpperCase()) {
//       case 'GENERAL SERVICE':
//         return Icons.build_circle;
//       case 'TYRE REPLACEMENT':
//         return Icons.settings;
//       case 'BATTERY CHANGE':
//         return Icons.electrical_services;
//       case 'WHEEL BALANCING':
//         return Icons.directions_car;
//       case 'OIL CHANGE':
//         return Icons.opacity;
//       case 'BRAKE SERVICE':
//         return Icons.emergency;
//       default:
//         return Icons.build;
//     }
//   }

//   int _getThisMonthCount(List<MaintenanceRecord> records) {
//     final now = DateTime.now();
//     return records.where((record) => 
//       record.serviceDate.month == now.month && record.serviceDate.year == now.year
//     ).length;
//   }

//   int _getPendingCount(List<MaintenanceRecord> records) {
//     final now = DateTime.now();
//     return records.where((record) => 
//       record.nextServiceDate != null && record.nextServiceDate!.isAfter(now)
//     ).length;
//   }

//   double _getTotalCost(List<MaintenanceRecord> records) {
//     return records.fold(0, (sum, record) => sum + record.cost);
//   }

//   void _showAddMaintenanceDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => const AddMaintenanceDialog(),
//     );
//   }
// }

// class AddMaintenanceDialog extends StatefulWidget {
//   const AddMaintenanceDialog({super.key});

//   @override
//   State<AddMaintenanceDialog> createState() => _AddMaintenanceDialogState();
// }

// class _AddMaintenanceDialogState extends State<AddMaintenanceDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final _vehicleNumberController = TextEditingController();
//   final _kilometersController = TextEditingController();
//   final _costController = TextEditingController();
//   final _reasonController = TextEditingController();
//   final _remarksController = TextEditingController();
  
//   String _selectedType = 'General Service';
//   DateTime _serviceDate = DateTime.now();

//   final List<String> _maintenanceTypes = [
//     'General Service',
//     'Tyre Replacement',
//     'Battery Change',
//     'Wheel Balancing',
//     'Oil Change',
//     'Brake Service',
//   ];

//   @override
//   void dispose() {
//     _vehicleNumberController.dispose();
//     _kilometersController.dispose();
//     _costController.dispose();
//     _reasonController.dispose();
//     _remarksController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: AppTheme.primary.withValues(alpha: 0.1),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Icon(Icons.add_circle, color: AppTheme.primary, size: 24),
//                   ),
//                   const SizedBox(width: 12),
//                   const Text(
//                     'Add Maintenance',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: AppTheme.primary,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     TextFormField(
//                       controller: _vehicleNumberController,
//                       decoration: InputDecoration(
//                         labelText: 'Vehicle Number',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         prefixIcon: Icon(Icons.directions_car, color: AppTheme.primary),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter vehicle number';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: _selectedType,
//                       decoration: InputDecoration(
//                         labelText: 'Maintenance Type',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         prefixIcon: Icon(Icons.build_circle, color: AppTheme.primary),
//                       ),
//                       items: _maintenanceTypes.map((type) {
//                         return DropdownMenuItem(
//                           value: type,
//                           child: Text(type),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedType = value!;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     InkWell(
//                       onTap: () => _selectDate(context),
//                       child: Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(Icons.calendar_today, color: AppTheme.primary),
//                             const SizedBox(width: 12),
//                             Text(
//                               DateFormat('MMM dd, yyyy').format(_serviceDate),
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextFormField(
//                             controller: _kilometersController,
//                             keyboardType: TextInputType.number,
//                             decoration: InputDecoration(
//                               labelText: 'Kilometers',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               prefixIcon: Icon(Icons.speed, color: AppTheme.primary),
//                             ),
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Required';
//                               }
//                               return null;
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: TextFormField(
//                             controller: _costController,
//                             keyboardType: TextInputType.number,
//                             decoration: InputDecoration(
//                               labelText: 'Cost (₹)',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.primary),
//                             ),
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Required';
//                               }
//                               return null;
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _reasonController,
//                       decoration: InputDecoration(
//                         labelText: 'Reason',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         prefixIcon: Icon(Icons.description, color: AppTheme.primary),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter the reason';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _remarksController,
//                       decoration: InputDecoration(
//                         labelText: 'Remarks (Optional)',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         prefixIcon: Icon(Icons.note, color: AppTheme.primary),
//                       ),
//                       maxLines: 2,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.of(context).pop(),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Text('Cancel'),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Consumer<MaintenanceProvider>(
//                       builder: (context, provider, child) {
//                         return Container(
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(
//                               colors: [AppTheme.primary, AppTheme.secondary],
//                               begin: Alignment.centerLeft,
//                               end: Alignment.centerRight,
//                             ),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: ElevatedButton(
//                             onPressed: provider.isLoading ? null : _addRecord,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.transparent,
//                               shadowColor: Colors.transparent,
//                               padding: const EdgeInsets.symmetric(vertical: 14),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             child: provider.isLoading
//                                 ? const SizedBox(
//                                     height: 16,
//                                     width: 16,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                       color: Colors.white,
//                                     ),
//                                   )
//                                 : const Text(
//                                     'Add Record',
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final date = await showDatePicker(
//       context: context,
//       initialDate: _serviceDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );

//     if (date != null) {
//       setState(() {
//         _serviceDate = date;
//       });
//     }
//   }

//   Future<void> _addRecord() async {
//     if (_formKey.currentState!.validate()) {
//       final provider = context.read<MaintenanceProvider>();
//       await provider.addMaintenanceRecord(
//         vehicleId: 'vehicle_id',
//         vehicleNumber: _vehicleNumberController.text.trim(),
//         type: _selectedType,
//         serviceDate: _serviceDate,
//         kilometers: double.parse(_kilometersController.text),
//         cost: double.parse(_costController.text),
//         reason: _reasonController.text.trim(),
//         remarks: _remarksController.text.trim().isNotEmpty 
//             ? _remarksController.text.trim() 
//             : null,
//       );

//       if (mounted && provider.error == null) {
//         Navigator.of(context).pop();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text('Maintenance record added successfully'),
//             backgroundColor: AppTheme.success,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         );
//       }
//     }
//   }
// }
