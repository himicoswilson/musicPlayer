import 'package:flutter/foundation.dart';
import '../services/navidrome_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final NavidromeService _navidromeService = NavidromeService();
  bool _isNavidromeLoggedIn = false;
  bool _isLoading = false;
  String? _error;
  bool _isLocalMode = false;
  bool _hasNavidromeConfig = false;

  bool get isLoggedIn => _isNavidromeLoggedIn || _isLocalMode;
  bool get isNavidromeLoggedIn => _isNavidromeLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLocalMode => _isLocalMode;
  bool get hasNavidromeConfig => _hasNavidromeConfig;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isLocalMode = prefs.getBool('isLocalMode') ?? false;
      
      await _navidromeService.init();
      final serverUrl = await _navidromeService.getServerUrl();
      final username = await _navidromeService.getUsername();
      final token = await _navidromeService.getToken();
      
      _hasNavidromeConfig = serverUrl != null && username != null && token != null;
      
      if (_hasNavidromeConfig) {
        final isConnected = await _navidromeService.ping();
        _isNavidromeLoggedIn = isConnected;
      } else {
        _isNavidromeLoggedIn = false;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isNavidromeLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> toggleLocalMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLocalMode = !_isLocalMode;
      await prefs.setBool('isLocalMode', _isLocalMode);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> configureNavidrome(String serverUrl, String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _navidromeService.login(serverUrl, username, password);
      if (success) {
        _hasNavidromeConfig = true;
        _isNavidromeLoggedIn = true;
        _error = null;
      } else {
        _error = '连接失败，请检查服务器地址和登录信息';
        _hasNavidromeConfig = false;
        _isNavidromeLoggedIn = false;
      }
      return success;
    } catch (e) {
      _error = e.toString();
      _hasNavidromeConfig = false;
      _isNavidromeLoggedIn = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> testNavidromeConnection() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isConnected = await _navidromeService.ping();
      _isNavidromeLoggedIn = isConnected;
      if (!isConnected) {
        _error = '连接失败，请检查网络或重新配置';
      }
      return isConnected;
    } catch (e) {
      _error = e.toString();
      _isNavidromeLoggedIn = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String serverUrl, String username, String password) async {
    return configureNavidrome(serverUrl, username, password);
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _navidromeService.logout();
      _isNavidromeLoggedIn = false;
      _hasNavidromeConfig = false;
      _error = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 获取已保存的 Navidrome 配置
  Future<Map<String, String?>> getNavidromeConfig() async {
    return {
      'serverUrl': await _navidromeService.getServerUrl(),
      'username': await _navidromeService.getUsername(),
    };
  }
} 