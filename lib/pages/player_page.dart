import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../services/navidrome_service.dart';
import '../providers/settings_provider.dart';

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
    final settings = Provider.of<SettingsProvider>(context);
    final size = MediaQuery.of(context).size;
    final coverSize = size.width * settings.coverArtSizeRatio;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () => _showPlaylist(context),
          ),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // 封面区域
                Container(
                  width: coverSize,
                  height: coverSize,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: settings.showCoverArtShadow
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.coverArtId != null
                        ? Image.network(
                            navidromeService.getCoverArtUrl(song.coverArtId!),
                            fit: BoxFit.cover,
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
                const SizedBox(height: 32),
                // 歌曲信息
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        song.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        song.artistName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // 进度条
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveTrackColor: Colors.grey[300],
                          thumbColor: Theme.of(context).primaryColor,
                          overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        ),
                        child: Slider(
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
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(provider.position),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _formatDuration(provider.duration),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 播放控制
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: _getPlayModeIcon(provider.playMode),
                        iconSize: 24,
                        onPressed: () => provider.togglePlayMode(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 40,
                        onPressed: () => provider.playPrevious(),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                        ),
                        child: IconButton(
                          icon: Icon(
                            provider.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          iconSize: 48,
                          onPressed: () => provider.togglePlay(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 40,
                        onPressed: () => provider.playNext(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.playlist_play),
                        iconSize: 24,
                        onPressed: () => _showPlaylist(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
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