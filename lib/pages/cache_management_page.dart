import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import '../services/cache_service.dart';
import '../widgets/custom_app_bar.dart';

class CacheManagementPage extends StatefulWidget {
  const CacheManagementPage({super.key});

  @override
  State<CacheManagementPage> createState() => _CacheManagementPageState();
}

class _CacheManagementPageState extends State<CacheManagementPage> {
  final CacheService _cacheService = CacheService();
  List<CacheInfo> _cacheInfoList = [];
  double _currentCacheSize = 0;
  int _maxCacheSize = 1024;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    setState(() => _isLoading = true);
    try {
      _cacheInfoList = await _cacheService.getCacheInfo();
      _currentCacheSize = await _cacheService.getCacheSize();
      _maxCacheSize = await _cacheService.getMaxCacheSize();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openCacheDirectory() async {
    final directory = await getApplicationSupportDirectory();
    final cachePath = path.join(directory.path, 'music_cache');
    if (Platform.isWindows) {
      Process.run('explorer', [cachePath]);
    } else if (Platform.isMacOS) {
      Process.run('open', [cachePath]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [cachePath]);
    }
  }

  Future<void> _exportCache() async {
    final directory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择导出目录',
    );
    if (directory == null) return;

    setState(() => _isLoading = true);
    try {
      for (var cacheInfo in _cacheInfoList) {
        final sourcePath = await _cacheService.getCachedFilePath(cacheInfo.songId);
        if (sourcePath != null) {
          final sourceFile = File(sourcePath);
          final targetPath = path.join(directory, path.basename(sourcePath));
          await sourceFile.copy(targetPath);
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('缓存导出成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importCache() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      dialogTitle: '选择要导入的缓存文件',
    );

    if (result == null) return;

    setState(() => _isLoading = true);
    try {
      for (var file in result.files) {
        if (file.path != null) {
          final sourceFile = File(file.path!);
          final targetPath = path.join(
            (await getApplicationSupportDirectory()).path,
            'music_cache',
            path.basename(file.path!),
          );
          await sourceFile.copy(targetPath);
        }
      }
      await _loadCacheInfo();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('缓存导入成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有缓存吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _cacheService.clearCache();
      await _loadCacheInfo();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('缓存已清除')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '缓存管理'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '当前缓存: ${_currentCacheSize.toStringAsFixed(2)}MB / ${_maxCacheSize}MB',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadCacheInfo,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openCacheDirectory,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('打开缓存目录'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _exportCache,
                        icon: const Icon(Icons.file_upload),
                        label: const Text('导出缓存'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _importCache,
                        icon: const Icon(Icons.file_download),
                        label: const Text('导入缓存'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _clearAllCache,
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('清除所有'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 32),
                Expanded(
                  child: ListView.builder(
                    itemCount: _cacheInfoList.length,
                    itemBuilder: (context, index) {
                      final cacheInfo = _cacheInfoList[index];
                      return ListTile(
                        title: Text('文件ID: ${cacheInfo.songId}'),
                        subtitle: Text(
                          '大小: ${(cacheInfo.size / 1024 / 1024).toStringAsFixed(2)}MB\n'
                          '最后访问: ${cacheInfo.lastAccessed.toString()}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await _cacheService.removeCachedFile(cacheInfo.songId);
                            await _loadCacheInfo();
                          },
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
} 