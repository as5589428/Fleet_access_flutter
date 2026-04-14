import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/action_alert_model.dart';
import '../services/action_alert_service.dart';
import '../services/notification_service.dart';
import '../core/constants/app_constants.dart';

class ActionAlertProvider extends ChangeNotifier {
  final ActionAlertService _service = ActionAlertService();
  List<ActionAlert> _alerts = [];
  final Set<String> _notifiedIds = {};
  bool _isLoading = false;
  String? _error;
  Timer? _timer;

  List<ActionAlert> get alerts => _alerts;
  List<ActionAlert> get openAlerts => _alerts.where((a) => a.isOpen).toList();
  List<ActionAlert> get closedAlerts => _alerts.where((a) => a.isClosed).toList();
  int get openCount => _alerts.where((a) => a.isOpen).length;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  ActionAlertProvider() {
    fetchAlerts(initial: true);
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchAlerts());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchAlerts({bool initial = false}) async {
    if (initial) {
      _isLoading = true;
      notifyListeners();
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      
      if (token == null) {
        // Not logged in, skip fetch
        if (initial) {
           _isLoading = false;
           notifyListeners();
        }
        return;
      }

      final fetchedAlerts = await _service.getAlerts();
      
      // Check for new open alerts to notify
      for (var alert in fetchedAlerts) {
        if (alert.isOpen && !_notifiedIds.contains(alert.id)) {
          if (!initial) { // Only notify for truly "new" ones after initial load
            NotificationService.showNotification(
              id: alert.id.hashCode.abs(),
              title: 'New Action Alert: ${alert.alertType}',
              body: alert.displayMessage,
            );
          }
          _notifiedIds.add(alert.id);
        }
      }

      _alerts = fetchedAlerts;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching alerts: $e');
    } finally {
      if (initial) _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> closeAlert({
    required String id,
    required String actionTaken,
    required String performedBy,
    required String actionTakenDate,
  }) async {
    try {
      final payload = {
        "status": "Closed",
        "action_taken": actionTaken,
        "performed_by": performedBy,
        "action_taken_date": actionTakenDate,
      };
      
      await _service.updateAlert(id, payload);
      
      // Update local state
      final index = _alerts.indexWhere((a) => a.id == id);
      if (index != -1) {
        final a = _alerts[index];
        _alerts[index] = ActionAlert(
          id: a.id,
          vehicleNumber: a.vehicleNumber,
          description: a.description,
          alertType: a.alertType,
          status: 'Closed',
          date: a.date,
          person: a.person,
          remarks: a.remarks,
          actionTaken: actionTaken,
          performedBy: performedBy,
          actionTakenDate: actionTakenDate,
          createdAt: a.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error closing alert: $e');
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
