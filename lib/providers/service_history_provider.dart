// lib/providers/service_history_provider.dart
import 'package:flutter/foundation.dart';
import '../services/service_history_service.dart';

class ServiceHistoryProvider extends ChangeNotifier {
  final ServiceHistoryService _service = ServiceHistoryService();

  // State variables
  Map<String, dynamic>? _serviceHistory;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, dynamic>? get serviceHistory => _serviceHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load service history (no filters needed)
  Future<void> loadServiceHistory() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('🔄 Loading all service history...');
      final response = await _service.getServiceHistory();

      if (response.success) {
        _serviceHistory = response.data;
        debugPrint('✅ Service history loaded successfully');

        if (response.data != null) {
          debugPrint('📊 Service history data keys: ${response.data!.keys}');
          debugPrint('💰 Total cost: ${response.data!['total_cost']}');
          debugPrint('🛣️ Driven KM: ${response.data!['driven_km']}');
          debugPrint('🔋 Battery services: ${response.data!['battery_count']}');
          debugPrint('🚗 Tyre services: ${response.data!['tyre_count']}');
          debugPrint('⚙️ Wheel services: ${response.data!['wheel_balance_count']}');
          debugPrint('🔧 General services: ${response.data!['general_count']}');
        }
      } else {
        _errorMessage = response.message;
        _serviceHistory = null;
        debugPrint('❌ Service history load failed: ${response.message}');
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to load service history: $e';
      _serviceHistory = null;
      debugPrint('🔥 Exception in loadServiceHistory: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh service history
  Future<void> refresh() async {
    await loadServiceHistory();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
