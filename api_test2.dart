import 'package:http/http.dart' as http;
import 'dart:io';

void main() async {
  final url = Uri.parse('https://fleet-vehicle-mgmt-backend-2.onrender.com/api/vehicles/getUnderMaintenance');
  final response = await http.get(
    url,
    headers: {'Content-Type': 'application/json'},
  );
  
  File('out2.txt').writeAsStringSync(response.body);
}
