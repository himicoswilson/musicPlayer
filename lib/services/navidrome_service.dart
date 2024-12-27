import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'music_service.dart';
import 'cache_service.dart';

class NavidromeService implements MusicService {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final CacheService _cacheService;
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
        ),
        _cacheService = CacheService() {
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

  @override
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
        print('获取状态失败: 缺少必要的���证信息');
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

  Future<Map<String, String>> _getBaseParams() async {
    if (_username == null || _token == null) {
      throw Exception('未登录');
    }
    return {
      'u': _username!,
      't': _token!,
      's': _salt ?? '',
      'v': '1.16.1',
      'c': 'musicPlayer',
      'f': 'json',
    };
  }

  @override
  Future<String> getStreamUrl(String id, {int? maxBitRate}) async {
    if (_serverUrl == null) throw Exception('未设置服务器地址');
    
    final params = await _getBaseParams();
    params['id'] = id;
    params['format'] = 'mp3';
    
    if (maxBitRate != null && maxBitRate > 0) {
      params['maxBitRate'] = maxBitRate.toString();
      print('设置音频比特率: $maxBitRate kbps');
    } else {
      print('使用原始音质');
    }

    final uri = Uri.parse('$_serverUrl/rest/stream')
      .replace(queryParameters: params);
    print('音频流URL: $uri');
    return uri.toString();
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

  // 获取所有歌单
  Future<List<Playlist>> getPlaylists() async {
    try {
      final response = await _dio.get('$_serverUrl/rest/getPlaylists.view');
      
      if (response.data['subsonic-response']['status'] == 'ok') {
        final playlists = response.data['subsonic-response']['playlists']['playlist'] as List;
        return playlists.map((p) => Playlist.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      print('获取歌单错误: $e');
      return [];
    }
  }

  // 获取歌单详情
  Future<Playlist?> getPlaylist(String playlistId) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/getPlaylist.view',
        queryParameters: {'id': playlistId},
      );
      
      if (response.data['subsonic-response']['status'] == 'ok') {
        return Playlist.fromJson(response.data['subsonic-response']['playlist']);
      }
      return null;
    } catch (e) {
      print('获取歌单详情错误: $e');
      return null;
    }
  }

  // 创建歌单
  Future<bool> createPlaylist(String name, {String? comment}) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/createPlaylist.view',
        queryParameters: {
          'name': name,
          if (comment != null) 'comment': comment,
        },
      );
      
      return response.data['subsonic-response']['status'] == 'ok';
    } catch (e) {
      print('创建歌单错误: $e');
      return false;
    }
  }

  // 添加歌曲到歌单
  Future<bool> addToPlaylist(String playlistId, String songId) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/updatePlaylist.view',
        queryParameters: {
          'playlistId': playlistId,
          'songIdToAdd': songId,
        },
      );
      
      return response.data['subsonic-response']['status'] == 'ok';
    } catch (e) {
      print('添加歌曲到歌单失败: $e');
      return false;
    }
  }

  // 从歌单中移除歌曲
  Future<bool> removeFromPlaylist(String playlistId, int songIndex) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/updatePlaylist.view',
        queryParameters: {
          'playlistId': playlistId,
          'songIndexToRemove': songIndex,
        },
      );
      
      return response.data['subsonic-response']['status'] == 'ok';
    } catch (e) {
      print('从歌单中移除歌曲失败: $e');
      return false;
    }
  }

  // 更新歌单信息
  Future<bool> updatePlaylist(String playlistId, {
    String? name,
    String? comment,
  }) async {
    try {
      final params = {
        'playlistId': playlistId,
        if (name != null) 'name': name,
        if (comment != null) 'comment': comment,
      };

      final response = await _dio.get(
        '$_serverUrl/rest/updatePlaylist.view',
        queryParameters: params,
      );
      
      return response.data['subsonic-response']['status'] == 'ok';
    } catch (e) {
      print('更新歌单信息失败: $e');
      return false;
    }
  }

  // 删除歌单
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/deletePlaylist.view',
        queryParameters: {'id': playlistId},
      );
      
      return response.data['subsonic-response']['status'] == 'ok';
    } catch (e) {
      print('删除歌单错误: $e');
      return false;
    }
  }

  // 获取收藏的歌曲
  Future<List<Song>> getStarred() async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/getStarred.view',
      );

      if (response.data['subsonic-response']['status'] == 'ok') {
        final starred = response.data['subsonic-response']['starred'];
        if (starred == null || !starred.containsKey('song')) {
          return [];
        }
        
        final songs = starred['song'];
        if (songs is! List) {
          return [];
        }

        return songs.map<Song>((song) => Song.fromJson(song)).toList();
      }
      
      print('获取收藏歌曲失败: 服务器返回非 OK 状态');
      return [];
    } catch (e) {
      print('获取收藏歌曲错误: $e');
      return [];
    }
  }

  // 收藏歌曲
  Future<bool> star({String? songId, String? albumId, String? artistId}) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/star.view',
        queryParameters: {
          if (songId != null) 'id': songId,
          if (albumId != null) 'albumId': albumId,
          if (artistId != null) 'artistId': artistId,
        },
      );

      return response.data['subsonic-response']['status'] == 'ok';
    } catch (e) {
      print('收藏失败: $e');
      return false;
    }
  }

  // 取消收藏
  Future<bool> unstar({String? songId, String? albumId, String? artistId}) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/unstar.view',
        queryParameters: {
          if (songId != null) 'id': songId,
          if (albumId != null) 'albumId': albumId,
          if (artistId != null) 'artistId': artistId,
        },
      );

      return response.data['subsonic-response']['status'] == 'ok';
    } catch (e) {
      print('取消收藏失败: $e');
      return false;
    }
  }

  // 获取歌词URL
  String getLyricUrl(String songId) {
    if (_serverUrl == null || _username == null || _token == null) {
      throw Exception('Not logged in');
    }
    
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final token = md5.convert(utf8.encode('$_token$salt')).toString();
    
    return '$_serverUrl/rest/getLyrics?id=$songId&u=$_username&t=$token&s=$salt&v=1.16.1&c=music_player';
  }

  // 获取歌词内容
  Future<String?> getLyrics(String songId) async {
    try {
      if (_serverUrl == null || _username == null || _token == null) {
        print('获取歌词失败: 缺少必要的认证信息');
        return null;
      }

      // 尝试使用 getLyrics.view
      final response = await _dio.get(
        '$_serverUrl/rest/getLyrics.view',
        queryParameters: {
          'id': songId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final subsonicResponse = response.data['subsonic-response'];
        if (subsonicResponse['status'] == 'ok' && 
            subsonicResponse['lyrics'] != null) {
          final value = subsonicResponse['lyrics']['value'];
          if (value != null && value.toString().isNotEmpty) {
            return value.toString();
          }
        }
      }

      // 如果没有找到歌词，尝试从本地文件获取
      final songResponse = await _dio.get(
        '$_serverUrl/rest/getSong.view',
        queryParameters: {
          'id': songId,
        },
      );

      if (songResponse.statusCode == 200 && songResponse.data != null) {
        final song = songResponse.data['subsonic-response']['song'];
        if (song != null) {
          final path = song['path'] as String?;
          if (path != null) {
            // 构造 .lrc 文件路径
            final basePath = path.substring(0, path.lastIndexOf('.'));
            final lrcPath = '$basePath.lrc';
            
            try {
              // 尝试直接从文件系统获取 .lrc 文件
              final lrcResponse = await _dio.get(
                '$_serverUrl/rest/download',
                queryParameters: {
                  'id': songId,
                  'path': lrcPath,
                },
              );
              
              if (lrcResponse.statusCode == 200 && 
                  lrcResponse.data != null && 
                  lrcResponse.data.toString().isNotEmpty) {
                return lrcResponse.data.toString();
              }
            } catch (e) {
              print('获取 .lrc 文件失败: $e');
            }
          }
        }
      }

      print('未找到歌词');
      return null;
    } catch (e) {
      print('获取歌词错误: $e');
      return null;
    }
  }

  // 添加缓存相关的方法
  Future<bool> cacheMusic(String songId) async {
    try {
      final url = await getStreamUrl(songId);
      if (url.isEmpty) return false;
      final cachedPath = await _cacheService.cacheFile(url, songId);
      return cachedPath != null;
    } catch (e) {
      print('缓存音乐失败: $e');
      return false;
    }
  }

  Future<bool> isMusicCached(String songId) async {
    return _cacheService.isCached(songId);
  }

  Future<bool> removeMusicCache(String songId) async {
    return _cacheService.removeCachedFile(songId);
  }

  Future<List<CacheInfo>> getCacheInfo() async {
    return _cacheService.getCacheInfo();
  }

  Future<double> getCacheSize() async {
    return _cacheService.getCacheSize();
  }

  Future<void> setMaxCacheSize(int sizeMB) async {
    await _cacheService.setMaxCacheSize(sizeMB);
  }

  Future<int> getMaxCacheSize() async {
    return _cacheService.getMaxCacheSize();
  }

  @override
  Future<bool> isAvailable() async {
    return await ping();
  }

  // 获取歌曲信息
  Future<Song?> getSongInfo(String songId) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/getSong.view',
        queryParameters: {
          'id': songId,
        },
      );

      if (response.data['subsonic-response']['status'] == 'ok') {
        final songData = response.data['subsonic-response']['song'];
        if (songData != null) {
          return Song.fromJson(songData);
        }
      }
      return null;
    } catch (e) {
      print('获取歌曲信息失败: $e');
      return null;
    }
  }
} 