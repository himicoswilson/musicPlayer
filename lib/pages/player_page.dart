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
  late bool _showLyrics;  // 修改为late

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    // 从设置中获取默认显示模式
    _showLyrics = Provider.of<SettingsProvider>(context, listen: false).defaultShowLyrics;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, SettingsProvider>(
      builder: (context, playerProvider, settingsProvider, child) {
        // 更新当前歌曲
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
              // 添加歌词显示切换按钮
              IconButton(
                icon: Icon(_showLyrics ? Icons.subject : Icons.image),
                onPressed: () {
                  setState(() {
                    _showLyrics = !_showLyrics;
                  });
                },
              ),
            ],
            centerTitle: true,
          ),
          body: Column(
            children: [
              // 专辑封面或歌词显示区域
              Expanded(
                child: _showLyrics
                    ? _buildLyricView(playerProvider, settingsProvider)
                    : _buildCoverView(playerProvider),
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

    return LyricView(
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
    );
  }

  Widget _buildCoverView(PlayerProvider provider) {
    return Center(
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
                          const Icon(Icons.music_note, size: 100),
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
              ],
            ),
          ),
          const SizedBox(height: 8),
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