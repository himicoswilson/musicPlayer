import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/navidrome_service.dart';
import '../models/song.dart';

class CacheProvider with ChangeNotifier {
  final NavidromeService _navidromeService;
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};
  final Map<String, CancelToken> _cancelTokens = {};
  bool _isLoading = false;
  Directory? _cacheDir;
  static const String _maxCacheSizeKey = 'maxCacheSize';
  static const int _defaultMaxCacheSize = 1024 * 1024 * 1024; // 1GB
  final _dio = Dio();

  CacheProvider(this._navidromeService) {
    _init();
  }

  bool get isLoading => _isLoading;
  bool get isInitialized => _cacheDir != null;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final appDir = await getApplicationSupportDirectory();
      final dir = Directory('${appDir.path}/music_cache');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _cacheDir = dir;
      debugPrint('缓存目录: ${_cacheDir?.path}');
    } catch (e) {
      debugPrint('初始化缓存目录失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String get cachePath => _cacheDir?.path ?? '正在初始化...';

  bool isCached(String songId) {
    if (_cacheDir == null) return false;
    final file = File('${_cacheDir!.path}/$songId');
    return file.existsSync();
  }

  Future<void> ensureInitialized() async {
    if (_cacheDir == null) {
      await _init();
    }
  }

  bool isDownloading(String songId) {
    return _isDownloading[songId] ?? false;
  }

  double getDownloadProgress(String songId) {
    return _downloadProgress[songId] ?? 0.0;
  }

  Future<void> cacheSong(Song song) async {
    await ensureInitialized();
    if (_cacheDir == null) return;
    
    if (isCached(song.id) || isDownloading(song.id)) return;

    _isDownloading[song.id] = true;
    _downloadProgress[song.id] = 0.0;
    final cancelToken = CancelToken();
    _cancelTokens[song.id] = cancelToken;
    notifyListeners();

    try {
      final url = await _navidromeService.getStreamUrl(song.id);
      if (url == null) {
        throw Exception('获取歌曲下载地址失败');
      }

      final file = File('${_cacheDir!.path}/${song.id}');
      await _dio.download(
        url,
        file.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _downloadProgress[song.id] = received / total;
            notifyListeners();
          }
        },
      );

      await _saveSongInfo(song);
    } catch (e) {
      debugPrint('缓存歌曲失败: $e');
      if (!cancelToken.isCancelled) {
        final file = File('${_cacheDir!.path}/${song.id}');
        if (await file.exists()) {
          await file.delete();
        }
      }
    } finally {
      _isDownloading[song.id] = false;
      _downloadProgress.remove(song.id);
      _cancelTokens.remove(song.id);
      notifyListeners();
    }
  }

  void cancelDownload(String songId) {
    final cancelToken = _cancelTokens[songId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('用户取消下载');
      _cancelTokens.remove(songId);
    }
  }

  Future<void> _saveSongInfo(Song song) async {
    if (_cacheDir == null) return;
    try {
      final file = File('${_cacheDir!.path}/${song.id}.info');
      final songInfo = {
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'albumId': song.albumId,
        'albumName': song.albumName,
        'coverArtId': song.coverArtId,
        'duration': song.duration,
        'track': song.track,
        'year': song.year,
      };
      await file.writeAsString(songInfo.toString());
    } catch (e) {
      debugPrint('保存歌曲信息失败: $e');
    }
  }

  Future<void> removeCachedSong(String songId) async {
    if (_cacheDir == null) return;
    final file = File('${_cacheDir!.path}/$songId');
    if (await file.exists()) {
      await file.delete();
      notifyListeners();
    }
  }

  Future<void> clearCache() async {
    if (_cacheDir == null) return;
    if (await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create();
      notifyListeners();
    }
  }

  int getCacheSize() {
    if (_cacheDir == null) return 0;
    try {
      int totalSize = 0;
      if (_cacheDir!.existsSync()) {
        _cacheDir!.listSync().forEach((entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
      return totalSize;
    } catch (e) {
      debugPrint('获取缓存大小失败: $e');
      return 0;
    }
  }

  Future<int> getMaxCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxCacheSizeKey) ?? _defaultMaxCacheSize;
  }

  Future<void> setMaxCacheSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxCacheSizeKey, size);
    notifyListeners();
  }

  List<Song> getCachedSongs() {
    if (_cacheDir == null) return [];
    try {
      final List<Song> songs = [];
      if (_cacheDir!.existsSync()) {
        final files = _cacheDir!.listSync();
        for (var entity in files) {
          if (entity is File && !entity.path.endsWith('.info')) {
            final songId = entity.path.split('/').last;
            final infoFile = File('${_cacheDir!.path}/$songId.info');
            if (infoFile.existsSync()) {
              try {
                final infoStr = infoFile.readAsStringSync();
                final info = infoStr.substring(1, infoStr.length - 1)
                    .split(', ')
                    .map((item) {
                      final parts = item.split(': ');
                      return MapEntry(
                        parts[0].replaceAll("'", ''),
                        parts[1].replaceAll("'", ''),
                      );
                    })
                    .fold<Map<String, String>>({}, (map, entry) {
                      map[entry.key] = entry.value;
                      return map;
                    });
                
                songs.add(Song(
                  id: info['id'] ?? songId,
                  title: info['title'] ?? 'Unknown Title',
                  artistName: info['artist'] ?? 'Unknown Artist',
                  albumId: info['albumId'] ?? '',
                  albumName: info['albumName'] ?? 'Unknown Album',
                  coverArtId: info['coverArtId'],
                  duration: int.tryParse(info['duration'] ?? '0') ?? 0,
                  track: int.tryParse(info['track'] ?? '0') ?? 0,
                  year: int.tryParse(info['year'] ?? '0') ?? 0,
                ));
              } catch (e) {
                debugPrint('解析歌曲信息失败: $e');
              }
            }
          }
        }
      }
      return songs;
    } catch (e) {
      debugPrint('获取缓存歌曲列表失败: $e');
      return [];
    }
  }

  @override
  void dispose() {
    // 取消所有正在进行的下载
    for (var cancelToken in _cancelTokens.values) {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('Provider disposed');
      }
    }
    _cancelTokens.clear();
    super.dispose();
  }
} 