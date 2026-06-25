import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Handles user authentication — login, register, token storage.
class AuthService extends ChangeNotifier {
  String? _token;
  String? _userId;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  String? get token => _token;
  String? get userId => _userId;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;

  final String baseUrl = ApiConfig.baseUrl;

  /// Load saved token from device storage.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userId = prefs.getString('user_id');
    if (_token != null) {
      // Verify token is still valid
      try {
        await _getMe();
      } catch (_) {
        _token = null;
        _userId = null;
        await prefs.remove('auth_token');
        await prefs.remove('user_id');
      }
    }
    notifyListeners();
  }

  /// Register a new user.
  Future<void> register({
    required String nickname,
    String? phone,
    String? email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'nickname': nickname,
        'password': password,
      };
      if (phone != null) body['phone'] = phone;
      if (email != null) body['email'] = email;

      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['access_token'];
        _userData = data['user'];
        _userId = data['user']['id'];
        await _saveToken();
      } else {
        final err = jsonDecode(res.body);
        throw Exception(err['detail'] ?? '注册失败');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with phone/email + password.
  Future<void> login({
    String? phone,
    String? email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{'password': password};
      if (phone != null) body['phone'] = phone;
      if (email != null) body['email'] = email;

      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['access_token'];
        _userData = data['user'];
        _userId = data['user']['id'];
        await _saveToken();
      } else {
        final err = jsonDecode(res.body);
        throw Exception(err['detail'] ?? '登录失败');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout.
  Future<void> logout() async {
    _token = null;
    _userId = null;
    _userData = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    notifyListeners();
  }

  Future<void> _getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _userData = data['user'];
    } else {
      throw Exception('Token invalid');
    }
  }

  Future<void> _saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString('auth_token', _token!);
    if (_userId != null) await prefs.setString('user_id', _userId!);
  }
}
