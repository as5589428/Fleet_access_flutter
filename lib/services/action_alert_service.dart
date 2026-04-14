import '../models/action_alert_model.dart';
import 'api_service.dart';

class ActionAlertService {
  final ApiService _api = ApiService.instance;
  final String _baseUrl = 'https://fleet-vehicle-mgmt-backend-2.onrender.com/api';

  Future<List<ActionAlert>> getAlerts() async {
    try {
      // We use a fresh Dio instance or just pass the full URL to the existing one 
      // if it handles absolute URLs. Dio's get() handles absolute URLs.
      final response = await _api.get('$_baseUrl/action-alerts');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        return data.map((item) => ActionAlert.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load alerts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading alerts: $e');
    }
  }

  Future<void> updateAlert(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('$_baseUrl/action-alerts/$id', data: data);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update alert: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating alert: $e');
    }
  }
}
