import 'package:flutter/material.dart';

class AlertModel {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String? vehicleId;
  final String? vehicleNumber;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? actionTaken;
  final String? performedBy;

  AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.vehicleId,
    this.vehicleNumber,
    required this.createdAt,
    this.resolvedAt,
    this.actionTaken,
    this.performedBy,
  });
}

class AlertProvider extends ChangeNotifier {
  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _error;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAlerts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Demo data - replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      
      _alerts = [
        AlertModel(
          id: '1',
          title: 'Insurance Expiry Warning',
          description: 'Vehicle KA01CD5678 insurance expires in 15 days',
          priority: 'PRIORITY',
          status: 'OPEN',
          vehicleId: 'vehicle2',
          vehicleNumber: 'KA01CD5678',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        AlertModel(
          id: '2',
          title: 'Maintenance Overdue',
          description: 'Vehicle KA01AB1234 maintenance is overdue by 500 km',
          priority: 'RISK',
          status: 'OPEN',
          vehicleId: 'vehicle1',
          vehicleNumber: 'KA01AB1234',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        AlertModel(
          id: '3',
          title: 'Fuel Efficiency Drop',
          description: 'Vehicle KA01CD5678 showing decreased fuel efficiency',
          priority: 'NORMAL',
          status: 'CLOSED',
          vehicleId: 'vehicle2',
          vehicleNumber: 'KA01CD5678',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
          actionTaken: 'Vehicle serviced and filters replaced',
          performedBy: 'Maintenance Team',
        ),
      ];
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> resolveAlert({
    required String alertId,
    required String actionTaken,
    required String performedBy,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final alertIndex = _alerts.indexWhere((a) => a.id == alertId);
      if (alertIndex != -1) {
        _alerts[alertIndex] = AlertModel(
          id: _alerts[alertIndex].id,
          title: _alerts[alertIndex].title,
          description: _alerts[alertIndex].description,
          priority: _alerts[alertIndex].priority,
          status: 'CLOSED',
          vehicleId: _alerts[alertIndex].vehicleId,
          vehicleNumber: _alerts[alertIndex].vehicleNumber,
          createdAt: _alerts[alertIndex].createdAt,
          resolvedAt: DateTime.now(),
          actionTaken: actionTaken,
          performedBy: performedBy,
        );
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
