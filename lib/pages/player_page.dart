import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../models/local_song.dart';
import '../models/lyric.dart';
import '../services/navidrome_service.dart';
import '../services/lyric_service.dart';
import '../providers/settings_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/lyric_view.dart';

class PlayerPage extends StatefulWidget {
  final Song song;

  const PlayerPage({
    Key? key,
    required this.song,
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late Song _currentSong;
  late bool _showLyrics;
  
  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _showLyrics = Provider.of<SettingsProvider>(context, listen: false).defaultShowLyrics;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, SettingsProvider>(
      builder: (context, playerProvider, settingsProvider, child) {
        // 更新前歌曲
        if (playerProvider.currentSong != null && playerProvider.currentSong != _currentSong) {
          _currentSong = playerProvider.currentSong!;
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _currentSong.title,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _currentSong.artist ?? '未知歌手',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showMoreOptions(context),
              ),
            ],
            centerTitle: true,
          ),
          body: Column(
            children: [
              // 专辑面或歌词显示区域
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showLyrics = !_showLyrics;
                    });
                  },
                  child: _showLyrics
                      ? _buildLyricView(playerProvider, settingsProvider)
                      : _buildCoverView(playerProvider),
                ),
              ),
              // 播放控制区域
              _buildControlPanel(playerProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLyricView(PlayerProvider provider, SettingsProvider settings) {
    if (provider.isLoadingLyric) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: LyricView(
          lyric: provider.currentLyric,
          position: provider.position ?? Duration.zero,
          lineHeight: 32.0,
          normalStyle: TextStyle(
            color: settings.lyricNormalColor,
            fontSize: settings.lyricNormalSize,
            height: 1.5,
          ),
          activeStyle: TextStyle(
            color: settings.lyricActiveColor,
            fontSize: settings.lyricActiveSize,
            height: 1.5,
            fontWeight: FontWeight.bold,
          ),
          onPositionChanged: (position) {
            provider.seek(position);
          },
        ),
      ),
    );
  }

  Widget _buildCoverView(PlayerProvider provider) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 封面图片
            Container(
              width: 300,
              height: 300,
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _currentSong.coverArtId != null
                    ? Image.network(
                        Provider.of<NavidromeService>(context, listen: false)
                            .getCoverArtUrl(_currentSong.coverArtId!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.music_note, size: 100),
                            ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, size: 100),
                      ),
              ),
            ),
            // 歌曲信息
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    _currentSong.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentSong.artist ?? '未知歌手',
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
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(PlayerProvider provider) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    value: (provider.position?.inSeconds ?? 0).toDouble(),
                    max: (provider.duration?.inSeconds ?? 0).toDouble(),
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
                        _formatDuration(provider.position ?? Duration.zero),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatDuration(provider.duration ?? Duration.zero),
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
          const SizedBox(height: 8),
          // 播放控制按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Consumer<PlaylistProvider>(
                  builder: (context, provider, child) {
                    final isStarred = provider.isSongStarred(_currentSong.id);
                    return IconButton(
                      icon: Icon(
                        isStarred ? Icons.favorite : Icons.favorite_border
                      ),
                      iconSize: 24,
                      onPressed: () => provider.toggleStarSong(_currentSong.id),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: 36,
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
                    iconSize: 42,
                    onPressed: () => provider.togglePlay(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: 36,
                  onPressed: () => provider.playNext(),
                ),
                IconButton(
                  icon: _getPlayModeIcon(provider.playMode),
                  iconSize: 24,
                  onPressed: () => provider.togglePlayMode(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Icon _getPlayModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return const Icon(Icons.format_list_bulleted_sharp);
      case PlayMode.random:
        return const Icon(Icons.shuffle);
      case PlayMode.single:
        return const Icon(Icons.repeat_one);
      case PlayMode.loop:
        return const Icon(Icons.repeat);
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('添加到歌单'),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylistDialog(context);
              },
            ),
            Consumer<PlaylistProvider>(
              builder: (context, provider, child) {
                final isStarred = provider.isSongStarred(_currentSong.id);
                return ListTile(
                  leading: Icon(
                    isStarred ? Icons.favorite : Icons.favorite_border
                  ),
                  title: Text(isStarred ? '取消收藏' : '收藏'),
                  onTap: () async {
                    Navigator.pop(context);
                    await provider.toggleStarSong(_currentSong.id);
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现分享功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.album),
              title: const Text('查看专辑'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 跳转到专辑详情页
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('查看艺术家'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 跳转到艺术家详情页
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<PlaylistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('还没有歌单'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCreatePlaylistDialog(context);
                    },
                    child: const Text('创建歌单'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.playlists.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('创建新歌单'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreatePlaylistDialog(context);
                  },
                );
              }

              final playlist = provider.playlists[index - 1];
              return ListTile(
                leading: const Icon(Icons.playlist_play),
                title: Text(playlist.name),
                subtitle: Text('${playlist.songCount} 首歌曲'),
                onTap: () async {
                  Navigator.pop(context);
                  final currentPlaylist = await NavidromeService().getPlaylist(playlist.id);
                  if (currentPlaylist != null) {
                    if (!currentPlaylist.songs.any((s) => s.id == _currentSong.id)) {
                      final success = await provider.addToPlaylist(playlist.id, _currentSong.id);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已添加到歌单')),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('添加失败')),
                        );
                      }
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('歌曲已在歌单中')),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final nameController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建歌单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '歌单名称',
                hintText: '请输入歌单名称',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: '描述',
                hintText: '请输入歌单描述（可选）',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入歌单名称')),
                );
                return;
              }

              final provider = context.read<PlaylistProvider>();
              final success = await provider.createPlaylist(
                nameController.text,
                comment: commentController.text.isEmpty
                    ? null
                    : commentController.text,
              );

              if (success && context.mounted) {
                final playlists = provider.playlists;
                if (playlists.isNotEmpty) {
                  final newPlaylist = playlists.last;
                  final addSuccess = await provider.addToPlaylist(
                    newPlaylist.id,
                    _currentSong.id,
                  );
                  if (addSuccess && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已创建歌单并添加歌曲')),
                    );
                  } else if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('创建歌单成功，但添加歌曲失败')),
                    );
                  }
                }
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('创建歌单失败')),
                );
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
} 