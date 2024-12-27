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
  Lyric? _lyric;
  bool _isLoadingLyric = false;
  final _lyricService = LyricService();
  bool _showLyrics = true;  // 控制是否显示歌词

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _loadLyric();
  }

  @override
  void didUpdateWidget(PlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.song != _currentSong) {
      _currentSong = widget.song;
      _loadLyric();
    }
  }

  Future<void> _loadLyric() async {
    if (_isLoadingLyric) return;
    setState(() {
      _isLoadingLyric = true;
      _lyric = null;
    });

    try {
      // TODO: 从 Navidrome 获取歌词文件 URL
      // 这里需要根据实际的 API 实现
      final lrcUrl = 'YOUR_LRC_URL/${_currentSong.id}.lrc';
      final lrcContent = await _lyricService.fetchLyricContent(lrcUrl);
      if (lrcContent != null) {
        final lyric = await _lyricService.parseLyric(lrcContent);
        if (mounted) {
          setState(() {
            _lyric = lyric;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading lyric: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLyric = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        // 更新当前歌曲
        if (provider.currentSong != null && provider.currentSong != _currentSong) {
          _currentSong = provider.currentSong!;
          _loadLyric();
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
                    ? _buildLyricView(provider)
                    : _buildCoverView(provider),
              ),
              // 播放控制区域
              _buildControlPanel(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLyricView(PlayerProvider provider) {
    if (_isLoadingLyric) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return LyricView(
      lyric: _lyric,
      position: provider.position ?? Duration.zero,
      lineHeight: 32.0,
      normalStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 16,
        height: 1.5,
      ),
      activeStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        height: 1.5,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCoverView(PlayerProvider provider) {
    // 保留原有的封面显示逻辑
    // ... existing code ...
  }

  Widget _buildControlPanel(PlayerProvider provider) {
    // 保留原有的控制面板逻辑
    // ... existing code ...
  }
} 