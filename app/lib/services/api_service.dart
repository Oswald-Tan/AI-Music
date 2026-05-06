import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: headers);
  }

  Future<http.Response> post(String endpoint, dynamic body) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.StreamedResponse> multipartPost(String endpoint, String filePath, Map<String, String> fields) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}$endpoint'));
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath('audio', filePath));
    
    return request.send();
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return http.delete(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: headers);
  }
}
