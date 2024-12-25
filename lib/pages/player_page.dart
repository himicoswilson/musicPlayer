import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../services/navidrome_service.dart';

class PlayerPage extends StatelessWidget {
  final Song song;
  final String streamUrl;

  const PlayerPage({
    super.key,
    required this.song,
    required this.streamUrl,
  });

  @override
  Widget build(BuildContext context) {
    final navidromeService = Provider.of<NavidromeService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('正在播放'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () => _showPlaylist(context),
          ),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // 封面区域
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: song.coverArtId != null
                      ? Image.network(
                          navidromeService.getCoverArtUrl(song.coverArtId!),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.album, size: 120),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.album, size: 120),
                        ),
                ),
              ),
              // 歌曲信息
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.artistName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // 进度条
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    Slider(
                      value: provider.position.inSeconds.toDouble(),
                      max: provider.duration.inSeconds.toDouble(),
                      onChangeStart: (_) {
                        provider.startSeek();
                      },
                      onChanged: (value) {
                        provider.updateSeekPosition(Duration(seconds: value.toInt()));
                      },
                      onChangeEnd: (value) {
                        provider.endSeek(Duration(seconds: value.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(provider.position),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            _formatDuration(provider.duration),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 播放控制
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: _getPlayModeIcon(provider.playMode),
                      onPressed: () => provider.togglePlayMode(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, size: 32),
                      onPressed: () => provider.playPrevious(),
                    ),
                    IconButton(
                      icon: Icon(
                        provider.isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        size: 64,
                      ),
                      onPressed: () => provider.togglePlay(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 32),
                      onPressed: () => provider.playNext(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.playlist_play),
                      onPressed: () => _showPlaylist(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Icon _getPlayModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return const Icon(Icons.repeat);
      case PlayMode.random:
        return const Icon(Icons.shuffle);
      case PlayMode.single:
        return const Icon(Icons.repeat_one);
      case PlayMode.loop:
        return const Icon(Icons.repeat_on);
    }
  }

  void _showPlaylist(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer<PlayerProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '播放列表',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Row(
                        children: [
                          Text(
                            '${provider.playlist.length} 首歌曲',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 8),
                          if (provider.playlist.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_all),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('清空播放列表'),
                                    content: const Text('确定要清空播放列表吗？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          provider.clearPlaylist();
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        },
                                        child: const Text('确定'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (provider.playlist.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.queue_music,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '播放列表为空',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: provider.playlist.length,
                      onReorder: (oldIndex, newIndex) {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final song = provider.playlist[oldIndex];
                        provider.removeFromPlaylist(song);
                        provider.addSongsToPlaylist([song]);
                      },
                      itemBuilder: (context, index) {
                        final song = provider.playlist[index];
                        final isPlaying = provider.currentSong?.id == song.id;
                        
                        return Dismissible(
                          key: Key(song.id),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            provider.removeFromPlaylist(song);
                          },
                          child: ListTile(
                            leading: song.coverArtId != null
                                ? Image.network(
                                    Provider.of<NavidromeService>(context, listen: false)
                                        .getCoverArtUrl(song.coverArtId!),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 40,
                                        height: 40,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.album, size: 24),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.album, size: 24),
                                  ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isPlaying ? Theme.of(context).primaryColor : null,
                                fontWeight: isPlaying ? FontWeight.bold : null,
                              ),
                            ),
                            subtitle: Text(
                              song.artistName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isPlaying
                                ? Icon(
                                    Icons.volume_up,
                                    color: Theme.of(context).primaryColor,
                                  )
                                : const Icon(Icons.drag_handle),
                            onTap: () {
                              provider.playSong(song, provider.getStreamUrl(song));
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
} 