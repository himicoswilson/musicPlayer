import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class CacheService {
  static const String _cacheVersionKey = 'cache_version';
  static const String _cacheSizeKey = 'max_cache_size_mb';
  static const int _defaultMaxCacheSizeMB = 1024; // 默认最大缓存大小为 1GB
  static const int _currentVersion = 1;

  final Dio _dio;
  late final Directory _cacheDir;
  bool _initialized = false;

  // 单例模式
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;

  CacheService._internal() : _dio = Dio() {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;

    try {
      // 获取缓存目录
      final appDir = await getApplicationSupportDirectory();
      _cacheDir = Directory(path.join(appDir.path, 'music_cache'));
      if (!await _cacheDir.exists()) {
        await _cacheDir.create(recursive: true);
      }

      // 检查缓存版本
      final prefs = await SharedPreferences.getInstance();
      final cacheVersion = prefs.getInt(_cacheVersionKey) ?? 0;
      if (cacheVersion < _currentVersion) {
        await _clearCache();
        await prefs.setInt(_cacheVersionKey, _currentVersion);
      }

      _initialized = true;
    } catch (e) {
      print('初始化缓存服务失败: $e');
    }
  }

  // 获取缓存文件路径
  String _getCacheFilePath(String songId) {
    return path.join(_cacheDir.path, '$songId.cache');
  }

  // 检查歌曲是否已缓存
  Future<bool> isCached(String songId) async {
    if (!_initialized) await _init();
    final file = File(_getCacheFilePath(songId));
    return await file.exists();
  }

  // 获取缓存文件的大小（MB）
  Future<double> getCacheSize() async {
    if (!_initialized) await _init();
    int totalSize = 0;
    await for (var entity in _cacheDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize / (1024 * 1024); // 转换为 MB
  }

  // 获取最大缓存大小（MB）
  Future<int> getMaxCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cacheSizeKey) ?? _defaultMaxCacheSizeMB;
  }

  // 设置最大缓存大小（MB）
  Future<void> setMaxCacheSize(int sizeMB) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheSizeKey, sizeMB);
    await _enforceMaxCacheSize();
  }

  // 缓存歌曲
  Future<String?> cacheFile(String url, String songId) async {
    if (!_initialized) await _init();

    try {
      final cacheFile = File(_getCacheFilePath(songId));
      if (await cacheFile.exists()) {
        return cacheFile.path;
      }

      // 检查缓存大小是否超过限制
      final currentSize = await getCacheSize();
      final maxSize = await getMaxCacheSize();
      if (currentSize >= maxSize) {
        await _enforceMaxCacheSize();
      }

      // 下载文件
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      // 保存文件
      await cacheFile.writeAsBytes(response.data);
      return cacheFile.path;
    } catch (e) {
      print('缓存文件失败: $e');
      return null;
    }
  }

  // 获取缓存的文件路径
  Future<String?> getCachedFilePath(String songId) async {
    if (!_initialized) await _init();
    final file = File(_getCacheFilePath(songId));
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  // 删除指定歌曲的缓存
  Future<bool> removeCachedFile(String songId) async {
    if (!_initialized) await _init();
    try {
      final file = File(_getCacheFilePath(songId));
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('删除缓存文件失败: $e');
      return false;
    }
  }

  // 清除所有缓存
  Future<void> _clearCache() async {
    if (!_initialized) await _init();
    try {
      if (await _cacheDir.exists()) {
        await _cacheDir.delete(recursive: true);
        await _cacheDir.create(recursive: true);
      }
    } catch (e) {
      print('清除缓存失败: $e');
    }
  }

  // 强制执行最大缓存大小限制
  Future<void> _enforceMaxCacheSize() async {
    if (!_initialized) await _init();

    try {
      final maxSize = await getMaxCacheSize();
      var currentSize = await getCacheSize();

      if (currentSize <= maxSize) return;

      // 获取所有缓存文件及其最后访问时间
      final files = await _cacheDir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      // 获取所有文件的访问时间
      final fileStats = <File, DateTime>{};
      for (var file in files) {
        final stats = await file.stat();
        fileStats[file] = stats.accessed;
      }

      // 按最后访问时间排序
      files.sort((a, b) => 
        fileStats[a]!.compareTo(fileStats[b]!));

      // 删除最旧的文件，直到缓存大小低于限制
      for (var file in files) {
        if (currentSize <= maxSize) break;
        final fileSize = await file.length();
        await file.delete();
        currentSize -= fileSize / (1024 * 1024);
      }
    } catch (e) {
      print('强制执行缓存大小限制失败: $e');
    }
  }

  // 获取所有缓存的文件信息
  Future<List<CacheInfo>> getCacheInfo() async {
    if (!_initialized) await _init();

    try {
      final List<CacheInfo> cacheInfoList = [];
      await for (var entity in _cacheDir.list()) {
        if (entity is File) {
          final stats = await entity.stat();
          cacheInfoList.add(CacheInfo(
            songId: path.basenameWithoutExtension(entity.path),
            size: await entity.length(),
            lastAccessed: stats.accessed,
          ));
        }
      }
      return cacheInfoList;
    } catch (e) {
      print('获取缓存信息失败: $e');
      return [];
    }
  }
}

class CacheInfo {
  final String songId;
  final int size;
  final DateTime lastAccessed;

  CacheInfo({
    required this.songId,
    required this.size,
    required this.lastAccessed,
  });
} 