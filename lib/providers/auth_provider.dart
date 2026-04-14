import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> checkAuthStatus() async {
    _isLoading = true;

    // Don't notify here (causes error)
    await Future.delayed(Duration.zero); // waits until build completes

    notifyListeners(); // ✔ safe

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);

      if (token != null) {
        final userJson = prefs.getString(AppConstants.userKey);
        if (userJson != null) {
          try {
            _user = UserModel.fromJson(jsonDecode(userJson));
          } catch (e) {
            // failed to parse user json
            _error = e.toString();
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String employeeCode, String password) async {
    _isLoading = true;
    _error = null;

    await Future.delayed(Duration.zero); // ✔ waits until build finishes
    notifyListeners(); // ✔ now safe

    try {
      if (employeeCode.isNotEmpty && password.isNotEmpty) {
        final result = await _authService.login(employeeCode, password);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, result['token']);
        
        _user = result['user'] as UserModel;

        await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
        await prefs.setString(AppConstants.roleKey, _user!.role);
        
        if (result['permissions'] != null) {
          await prefs.setString(AppConstants.permissionsKey, jsonEncode(result['permissions']));
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Please enter valid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Strip "Exception: " prefix added by Dart's Exception.toString()
      final raw = e.toString();
      _error = raw.startsWith('Exception: ') ? raw.substring(11) : raw;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _user = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
