import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    setLoading(true);
    final user = await _authService.login(email, password);
    _user = user;
    setLoading(false);
    return user != null;
  }

  Future<bool> register(String name, String email, String password) async {
    setLoading(true);
    final user = await _authService.register(name, email, password);
    _user = user;
    setLoading(false);
    return user != null;
  }

  Future<void> getProfile() async {
    setLoading(true);
    final user = await _authService.getProfile();
    _user = user;
    setLoading(false);
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
