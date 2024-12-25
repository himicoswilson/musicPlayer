import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NavidromeService {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  String? _serverUrl;
  String? _username;
  String? _salt;
  String? _token;

  static final NavidromeService _instance = NavidromeService._internal();

  factory NavidromeService() {
    return _instance;
  }

  NavidromeService._internal() 
      : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
          mOptions: MacOsOptions(
            accessibility: KeychainAccessibility.first_unlock,
            synchronizable: true,
          ),
        ) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('请求URL: ${options.uri}');
        print('请求参数: ${options.queryParameters}');
        if (_serverUrl != null && _username != null && _token != null) {
          options.queryParameters.addAll({
            'u': _username,
            't': _token,
            's': _salt,
            'v': '1.16.1',
            'c': 'musicPlayer',
            'f': 'json',
          });
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('响应数据: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('请求错误: ${error.message}');
        if (error.response != null) {
          print('错误响应: ${error.response?.data}');
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> init() async {
    try {
      _serverUrl = await _secureStorage.read(key: 'serverUrl');
      _username = await _secureStorage.read(key: 'username');
      _salt = await _secureStorage.read(key: 'salt');
      _token = await _secureStorage.read(key: 'token');
      print('初始化完成: serverUrl=$_serverUrl, username=$_username');
    } catch (e) {
      print('初始化错误: $e');
    }
  }

  Future<bool> login(String serverUrl, String username, String password) async {
    try {
      print('开始登录: serverUrl=$serverUrl, username=$username');
      
      _serverUrl = serverUrl.trim();
      if (!_serverUrl!.startsWith('http')) {
        _serverUrl = 'http://$_serverUrl';
      }
      if (_serverUrl!.endsWith('/')) {
        _serverUrl = _serverUrl!.substring(0, _serverUrl!.length - 1);
      }

      _username = username;
      _salt = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 生成 token (密码 + salt 的 MD5)
      final token = md5.convert(utf8.encode(password + _salt!)).toString();
      
      print('准备发送请求: $_serverUrl/rest/ping.view');
      
      // 测试连接
      final response = await _dio.get(
        '$_serverUrl/rest/ping.view',
        queryParameters: {
          'u': _username,
          't': token,
          's': _salt,
          'v': '1.16.1',
          'c': 'musicPlayer',
          'f': 'json',
        },
      );

      print('收到响应: ${response.data}');

      if (response.data['subsonic-response']['status'] == 'ok') {
        _token = token;
        // 保存认证信息
        try {
          await _secureStorage.write(key: 'serverUrl', value: _serverUrl);
          await _secureStorage.write(key: 'username', value: _username);
          await _secureStorage.write(key: 'salt', value: _salt);
          await _secureStorage.write(key: 'token', value: _token);
          print('登录成功');
          return true;
        } catch (e) {
          print('保存认证信息失败: $e');
          return false;
        }
      }
      print('登录失败: 服务器返回非 OK 状态');
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          print('登录失败: 连接超时');
        } else if (e.type == DioExceptionType.connectionError) {
          print('登录失败: 连接错误 - ${e.message}');
        } else {
          print('登录失败: ${e.type} - ${e.message}');
        }
        if (e.response != null) {
          print('错误响应: ${e.response?.data}');
        }
      } else {
        print('登录失败: $e');
      }
      return false;
    }
  }

  Future<void> logout() async {
    try {
      print('开始注销');
      await _secureStorage.deleteAll();
      _serverUrl = null;
      _username = null;
      _salt = null;
      _token = null;
      print('注销成功');
    } catch (e) {
      print('注销错误: $e');
    }
  }

  Future<bool> ping() async {
    try {
      if (_serverUrl == null || _username == null || _token == null) {
        print('Ping 失败: 缺少必要的认证信息');
        return false;
      }
      
      final response = await _dio.get(
        '$_serverUrl/rest/ping.view',
        queryParameters: {
          'u': _username,
          't': _token,
          's': _salt,
          'v': '1.16.1',
          'c': 'musicPlayer',
          'f': 'json',
        },
      );
      
      return response.data['subsonic-response']['status'] == 'ok';
    } catch (e) {
      print('Ping 错误: $e');
      return false;
    }
  }

  // 获取服务器状态
  Future<Map<String, dynamic>?> getStatus() async {
    try {
      if (_serverUrl == null || _username == null || _token == null) {
        print('获取状态失败: 缺少必要的认证信息');
        return null;
      }

      final response = await _dio.get(
        '$_serverUrl/rest/getStatus.view',
        queryParameters: {
          'u': _username,
          't': _token,
          's': _salt,
          'v': '1.16.1',
          'c': 'musicPlayer',
          'f': 'json',
        },
      );
      
      if (response.data['subsonic-response']['status'] == 'ok') {
        return response.data['subsonic-response'];
      }
      print('获取状态失败: 服务器返回非 OK 状态');
      return null;
    } catch (e) {
      print('获取状态错误: $e');
      return null;
    }
  }
} 