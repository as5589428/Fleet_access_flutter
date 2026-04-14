// import 'package:flutter/material.dart';
// import '../models/vehicle_model.dart';

// class VehicleProvider extends ChangeNotifier {
//   List<VehicleModel> _vehicles = [];
//   bool _isLoading = false;
//   String? _error;

//   List<VehicleModel> get vehicles => _vehicles;
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   Future<void> loadVehicles() async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       // Demo data - replace with actual API call
//       await Future.delayed(const Duration(seconds: 1));
      
//       _vehicles = [
//         VehicleModel(
//           id: '1',
//           vehicleNumber: 'KA01AB1234',
//           vehicleType: 'Sedan',
//           brand: 'Honda',
//           model: 'City',
//           ownership: 'Company',
//           seatingCapacity: 5,
//           status: 'ACTIVE',
//           purchaseCost: 800000.0,
//           supplier: 'Honda Dealer',
//           purchaseDate: DateTime(2023, 1, 15),
//           rcNumber: 'RC123456',
//           rcExpiry: DateTime(2028, 1, 15),
//           insuranceNumber: 'INS789012',
//           insuranceExpiry: DateTime(2024, 12, 31),
//           pollutionNumber: 'PUC345678',
//           pollutionExpiry: DateTime(2024, 6, 30),
//           createdAt: DateTime(2023, 1, 15),
//         ),
//         VehicleModel(
//           id: '2',
//           vehicleNumber: 'KA01CD5678',
//           vehicleType: 'SUV',
//           brand: 'Toyota',
//           model: 'Fortuner',
//           ownership: 'Leased',
//           seatingCapacity: 7,
//           status: 'MAINTENANCE',
//           purchaseCost: 1200000.0,
//           supplier: 'Toyota Dealer',
//           purchaseDate: DateTime(2022, 8, 10),
//           rcNumber: 'RC234567',
//           rcExpiry: DateTime(2027, 8, 10),
//           insuranceNumber: 'INS890123',
//           insuranceExpiry: DateTime(2024, 3, 15),
//           pollutionNumber: 'PUC456789',
//           pollutionExpiry: DateTime(2024, 2, 28),
//           createdAt: DateTime(2022, 8, 10),
//         ),
//       ];
//     } catch (e) {
//       _error = e.toString();
//     }

//     _isLoading = false;
//     notifyListeners();
//   }

//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }
// }
