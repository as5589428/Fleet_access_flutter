// lib/providers/closing_provider.dart
import 'package:flutter/foundation.dart';
import '../models/closing_model.dart';
import '../services/closing_service.dart';

class ClosingProvider with ChangeNotifier {
  List<ClosingRecord> _records = [];
  bool _isLoading = false;
  String _error = '';

  List<ClosingRecord> get records => _records;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchRecords() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _records = await ClosingService.fetchRecords();
      _error = '';
    } catch (e) {
      _error = 'Failed to load records: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRecord(String id) async {
    try {
      final response = await ClosingService.deleteRecord(id);
      if (response.status == 'success') {
        await fetchRecords();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to delete record: $e';
      notifyListeners();
      return false;
    }
  }
}
