import 'dart:convert';
import 'api_service.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<UserModel?> login(String email, String password) async {
    final response = await _api.post(ApiConfig.login, {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _api.saveToken(data['token']);
      return UserModel.fromJson(data['user']);
    }
    return null;
  }

  Future<UserModel?> register(String name, String email, String password) async {
    final response = await _api.post(ApiConfig.register, {
      'name': name,
      'email': email,
      'password': password,
    });

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _api.saveToken(data['token']);
      return UserModel.fromJson(data['user']);
    }
    return null;
  }

  Future<UserModel?> getProfile() async {
    final response = await _api.get(ApiConfig.profile);
    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<void> logout() async {
    await _api.removeToken();
  }
}
