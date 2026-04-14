import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() async {
  final url = Uri.parse('https://fleet-vehicle-mgmt-backend-2.onrender.com/api/vehicles/getUpcomingMaintenanceList');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'page': 1, 'limit': 10}),
  );
  
  File('out.txt').writeAsStringSync(response.body);
}
