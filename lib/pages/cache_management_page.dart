import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cache_provider.dart';
import '../models/song.dart';

class CacheManagementPage extends StatelessWidget {
  const CacheManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('缓存管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showCacheSettings(context),
          ),
        ],
      ),
      body: Consumer<CacheProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final cachedSongs = provider.getCachedSongs();
          if (cachedSongs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.storage,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '没有缓存的歌曲',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildCacheStatus(context, provider),
              Expanded(
                child: ListView.builder(
                  itemCount: cachedSongs.length,
                  itemBuilder: (context, index) {
                    final song = cachedSongs[index];
                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(song.title),
                      subtitle: Text(song.artist),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => provider.removeCachedSong(song.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCacheStatus(BuildContext context, CacheProvider provider) {
    final usedSpace = provider.getCacheSize();

    return FutureBuilder<int>(
      future: provider.getMaxCacheSize(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final maxSpace = snapshot.data!;
        final percentage = usedSpace / maxSpace;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '已使用 ${_formatSize(usedSpace)} / ${_formatSize(maxSpace)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => provider.clearCache(),
                    child: const Text('清除全部'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 0.9 ? Colors.red : Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCacheSettings(BuildContext context) {
    final provider = context.read<CacheProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('缓存设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('最大缓存大小'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return FutureBuilder<int>(
                  future: provider.getMaxCacheSize(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    return Slider(
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${snapshot.data! ~/ (1024 * 1024 * 1024)} GB',
                      value: snapshot.data! / (1024 * 1024 * 1024),
                      onChanged: (value) {
                        setState(() {
                          provider.setMaxCacheSize((value * 1024 * 1024 * 1024).toInt());
                        });
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
} 