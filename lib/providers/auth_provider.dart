import 'package:flutter/foundation.dart';
import '../services/navidrome_service.dart';

class AuthProvider with ChangeNotifier {
  final NavidromeService _navidromeService = NavidromeService();
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _navidromeService.init();
      final serverUrl = await _navidromeService.getServerUrl();
      final username = await _navidromeService.getUsername();
      final token = await _navidromeService.getToken();
      
      if (serverUrl != null && username != null && token != null) {
        final isConnected = await _navidromeService.ping();
        _isLoggedIn = isConnected;
      } else {
        _isLoggedIn = false;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String serverUrl, String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _navidromeService.login(serverUrl, username, password);
      _isLoggedIn = success;
      if (!success) {
        _error = '登录失败，请检查服务器地址和登录信息';
      }
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoggedIn = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _navidromeService.logout();
    _isLoggedIn = false;
    _error = null;

    _isLoading = false;
    notifyListeners();
  }
} 