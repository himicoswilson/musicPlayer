import 'package:flutter/foundation.dart';
import '../services/navidrome_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_provider.dart';

class AuthProvider with ChangeNotifier {
  final NavidromeService _navidromeService = NavidromeService();
  bool _isNavidromeLoggedIn = false;
  bool _isLoading = false;
  String? _error;
  bool _isLocalMode = false;
  bool _hasNavidromeConfig = false;
  bool _isOfflineMode = false;
  String? _serverUrl;
  String? _username;
  String? _password;
  CacheProvider? _cacheProvider;

  bool get isLoggedIn => _isNavidromeLoggedIn || _isLocalMode || _isOfflineMode;
  bool get isNavidromeLoggedIn => _isNavidromeLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLocalMode => _isLocalMode;
  bool get hasNavidromeConfig => _hasNavidromeConfig;
  bool get isOfflineMode => _isOfflineMode;
  String? get serverUrl => _serverUrl;
  String? get username => _username;

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
        try {
          final isConnected = await _navidromeService.ping();
          _isNavidromeLoggedIn = isConnected;
        } catch (e) {
          debugPrint('连接服务器失败: $e');
          // 检查是否有缓存的歌曲
          _cacheProvider = CacheProvider(_navidromeService);
          await _cacheProvider!.ensureInitialized();
          final hasCachedSongs = _cacheProvider!.getCachedSongs().isNotEmpty;
          
          if (hasCachedSongs) {
            _isOfflineMode = true;
            _error = null;
          } else {
            _error = e.toString();
          }
        }
      } else {
        _isNavidromeLoggedIn = false;
      }
    } catch (e) {
      _error = e.toString();
      _isNavidromeLoggedIn = false;
      
      // 检查是否有缓存的歌曲
      _cacheProvider = CacheProvider(_navidromeService);
      await _cacheProvider!.ensureInitialized();
      final hasCachedSongs = _cacheProvider!.getCachedSongs().isNotEmpty;
      
      if (hasCachedSongs) {
        _isOfflineMode = true;
        _error = null;
      }
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

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('serverUrl');
    _username = prefs.getString('username');
    final password = prefs.getString('password');
    
    if (_serverUrl != null && _username != null && password != null) {
      try {
        final success = await login(_serverUrl!, _username!, password);
        if (success) {
          return true;
        }
      } catch (e) {
        debugPrint('自动登录失败: $e');
        // 如果登录失败，检查是否有缓存的歌曲
        _cacheProvider = CacheProvider(_navidromeService);
        await _cacheProvider!.ensureInitialized();
        final hasCachedSongs = _cacheProvider!.getCachedSongs().isNotEmpty;
        
        if (hasCachedSongs) {
          _isOfflineMode = true;
          notifyListeners();
          return true;
        }
      }
    }
    return false;
  }

  Future<bool> login(String serverUrl, String username, String password) async {
    try {
      final success = await _navidromeService.login(serverUrl, username, password);
      
      if (success) {
        _isNavidromeLoggedIn = true;
        _serverUrl = serverUrl;
        _username = username;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('serverUrl', serverUrl);
        await prefs.setString('username', username);
        await prefs.setString('password', password);
        
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('登录失败: $e');
      // 检查是否有缓存的歌曲
      _cacheProvider = CacheProvider(_navidromeService);
      await _cacheProvider!.ensureInitialized();
      final hasCachedSongs = _cacheProvider!.getCachedSongs().isNotEmpty;
      
      if (hasCachedSongs) {
        _isOfflineMode = true;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void setLocalMode(bool enabled) {
    _isLocalMode = enabled;
    notifyListeners();
  }

  Future<void> logout() async {
    _isNavidromeLoggedIn = false;
    _isOfflineMode = false;
    _serverUrl = null;
    _username = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('serverUrl');
    await prefs.remove('username');
    await prefs.remove('password');
    
    notifyListeners();
  }

  // 获取已保存的 Navidrome 配置
  Future<Map<String, String?>> getNavidromeConfig() async {
    return {
      'serverUrl': await _navidromeService.getServerUrl(),
      'username': await _navidromeService.getUsername(),
    };
  }
} 