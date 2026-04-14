// lib/services/http_client.dart
import 'package:http/http.dart' as http;

class HttpClient {
  static Future<String> get(String url, {Map<String, String>? headers}) async {
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return response.body;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  }

  static Future<String> post(String url, {Map<String, String>? headers, Object? data}) async {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: data,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  }

  static Future<String> put(String url, {Map<String, String>? headers, Object? data}) async {
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: data,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  }

  static Future<String> delete(String url, {Map<String, String>? headers}) async {
    final response = await http.delete(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return response.body;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  }
}
