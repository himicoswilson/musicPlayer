import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';

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

  // 获取保存的服务器地址
  Future<String?> getServerUrl() async {
    return _secureStorage.read(key: 'serverUrl');
  }

  // 获取保存的用户名
  Future<String?> getUsername() async {
    return _secureStorage.read(key: 'username');
  }

  // 获取保存的 token
  Future<String?> getToken() async {
    return _secureStorage.read(key: 'token');
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
      
      // 直接使用密码的 MD5 作为 token
      _token = md5.convert(utf8.encode(password)).toString();
      _salt = '';
      
      print('准备发送请求: $_serverUrl/rest/ping.view');
      
      // 测试连接
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

      print('收到响应: ${response.data}');

      if (response.data['subsonic-response']['status'] == 'ok') {
        // 保存认证信息
        try {
          await _secureStorage.write(key: 'serverUrl', value: _serverUrl);
          await _secureStorage.write(key: 'username', value: _username);
          await _secureStorage.write(key: 'salt', value: _salt);
          await _secureStorage.write(key: 'token', value: _token);
          print('登录成功，已保存认证信息');
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

  // 获取所有艺术家
  Future<List<Artist>> getArtists() async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/getArtists.view',
      );

      if (response.data['subsonic-response']['status'] == 'ok') {
        final artists = response.data['subsonic-response']['artists']['index']
            .expand((index) => index['artist'] as List)
            .map((artist) => Artist.fromJson(artist))
            .toList();
        return List<Artist>.from(artists);
      }
      return [];
    } catch (e) {
      print('获取艺术家列表失败: $e');
      return [];
    }
  }

  // 获取艺术家的所有专辑
  Future<List<Album>> getArtistAlbums(String artistId) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/getArtist.view',
        queryParameters: {'id': artistId},
      );

      if (response.data['subsonic-response']['status'] == 'ok') {
        final albums = response.data['subsonic-response']['artist']['album'] ?? [];
        return List<Album>.from(albums.map((album) => Album.fromJson(album)));
      }
      return [];
    } catch (e) {
      print('获取艺术家专辑失败: $e');
      return [];
    }
  }

  // 获取专辑的所有歌曲
  Future<List<Song>> getAlbumSongs(String albumId) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/getAlbum.view',
        queryParameters: {'id': albumId},
      );

      if (response.data['subsonic-response']['status'] == 'ok') {
        final songs = response.data['subsonic-response']['album']['song'] ?? [];
        return List<Song>.from(songs.map((song) => Song.fromJson(song)));
      }
      return [];
    } catch (e) {
      print('获取专辑歌曲失败: $e');
      return [];
    }
  }

  // 获取歌曲流媒体URL
  String getStreamUrl(String songId) {
    return '$_serverUrl/rest/stream.view?id=$songId&u=$_username&t=$_token&s=$_salt&v=1.16.1&c=musicPlayer&f=json';
  }

  // 获取封面图片URL
  String getCoverArtUrl(String? coverArtId) {
    if (coverArtId == null) return '';
    return '$_serverUrl/rest/getCoverArt.view?id=$coverArtId&u=$_username&t=$_token&s=$_salt&v=1.16.1&c=musicPlayer&f=json';
  }

  // 获取所有专辑
  Future<List<Album>> getAlbums({int? size, int? offset}) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/getAlbumList2.view',
        queryParameters: {
          'type': 'newest',
          'size': size ?? 500,
          'offset': offset ?? 0,
        },
      );

      if (response.data['subsonic-response']['status'] == 'ok') {
        final albums = response.data['subsonic-response']['albumList2']['album'] ?? [];
        return List<Album>.from(albums.map((album) => Album.fromJson(album)));
      }
      return [];
    } catch (e) {
      print('获取专辑列表失败: $e');
      return [];
    }
  }

  // 获取最近添加的歌曲
  Future<List<Song>> getNewestSongs({int? size}) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/getRandomSongs.view',
        queryParameters: {
          'size': size ?? 500,
        },
      );

      if (response.data['subsonic-response']['status'] == 'ok') {
        final songs = response.data['subsonic-response']['randomSongs']['song'] ?? [];
        return List<Song>.from(songs.map((song) => Song.fromJson(song)));
      }
      return [];
    } catch (e) {
      print('获取歌曲列表失败: $e');
      return [];
    }
  }

  // 搜索
  Future<Map<String, dynamic>> search(String query) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/search3.view',
        queryParameters: {
          'query': query,
        },
      );

      if (response.data['subsonic-response']['status'] == 'ok') {
        return response.data['subsonic-response']['searchResult3'] ?? {};
      }
      return {};
    } catch (e) {
      print('搜索失败: $e');
      return {};
    }
  }
} 