import 'dart:math';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/lyric.dart';
import '../services/player_service.dart';
import '../services/navidrome_service.dart';
import '../services/local_music_service.dart';
import '../services/lyric_service.dart';
import '../models/local_song.dart';
import '../services/music_service.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

enum PlayMode {
  sequence, // 顺序播放
  random,   // 随机播放
  single,   // 单曲循环
  loop      // 列表循环
}

class PlayerProvider extends ChangeNotifier {
  final PlayerService _playerService = PlayerService();
  final LocalMusicService _localMusicService = LocalMusicService();
  final NavidromeService _navidromeService = NavidromeService();
  final LyricService _lyricService = LyricService();
  final SettingsProvider _settingsProvider;
  MusicService? _currentMusicService;
  
  // 播放模式
  PlayMode _playMode = PlayMode.loop;
  PlayMode get playMode => _playMode;
  
  // 播放列表
  final List<Song> _playlist = [];
  List<Song> get playlist => List.unmodifiable(_playlist);
  
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isDraggingProgress = false;

  // 歌词相关
  Lyric? _currentLyric;
  Lyric? get currentLyric => _currentLyric;
  bool _isLoadingLyric = false;
  bool get isLoadingLyric => _isLoadingLyric;
  final Map<String, Lyric> _lyricCache = {};
  
  PlayerProvider(this._settingsProvider) {
    // 设置播放状态监听回调
    _playerService.onPositionChanged = (position) {
      updatePosition(position);
    };
    
    _playerService.onDurationChanged = (duration) {
      updateDuration(duration);
    };
    
    _playerService.onPlayingChanged = (playing) {
      _isPlaying = playing;
      notifyListeners();
    };
  }
  
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  
  void _setMusicService(Song song) {
    if (song is LocalSong) {
      _currentMusicService = _localMusicService;
      _playerService.setMusicService(_localMusicService);
    } else {
      _currentMusicService = _navidromeService;
      _playerService.setMusicService(_navidromeService);
    }
  }
  
  Future<void> playSong(Song song) async {
    _currentSong = song;
    _currentLyric = null;
    notifyListeners();

    // 开始加载歌词
    _preloadLyric(song);

    try {
      _setMusicService(song);
      
      // 获取所有歌曲并添加到播放列表
      if (_playlist.isEmpty) {
        if (song is LocalSong) {
          final songs = await _localMusicService.getNewestSongs();
          _playlist.addAll(songs);
        } else {
          _playlist.add(song);
        }
      }
      
      // 如果歌曲不在播放列表中，添加它
      if (!_playlist.contains(song)) {
        _playlist.add(song);
      }
      
      // 立即通知界面更新
      notifyListeners();
      
      // 获取音质设置
      final maxBitRate = _settingsProvider.autoQuality ? 0 : _settingsProvider.maxBitRate;
      
      // 然后开始播放，传入音质参数
      await _playerService.play(song, maxBitRate: maxBitRate);
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      print('播放失败: $e');
    }
  }
  
  Future<void> togglePlay() async {
    if (_currentSong == null) return;
    
    if (_isPlaying) {
      await _playerService.pause();
      _isPlaying = false;
    } else {
      await _playerService.resume();
      _isPlaying = true;
    }
    notifyListeners();
  }
  
  Future<void> seek(Duration position) async {
    await _playerService.seek(position);
    _position = position;
    notifyListeners();
  }
  
  void updatePosition(Duration position) {
    if (!_isDraggingProgress) {
      _position = position;
      notifyListeners();
    }
  }
  
  void updateDuration(Duration duration) {
    _duration = duration;
    notifyListeners();
  }

  // 播放列表相关功能
  void addSongsToPlaylist(List<Song> songs) {
    for (final song in songs) {
      if (!_playlist.contains(song)) {
        _playlist.add(song);
      }
    }
    notifyListeners();
  }

  void removeFromPlaylist(Song song) {
    _playlist.remove(song);
    notifyListeners();
  }

  void clearPlaylist() {
    _playlist.clear();
    _currentSong = null;
    notifyListeners();
  }

  // 播放模式相关功能
  void togglePlayMode() {
    final modes = PlayMode.values;
    final currentIndex = modes.indexOf(_playMode);
    _playMode = modes[(currentIndex + 1) % modes.length];
    notifyListeners();
  }

  // 播放控制
  Future<void> playNext() async {
    if (_playlist.isEmpty || _currentSong == null) return;
    
    final currentIndex = _playlist.indexOf(_currentSong!);
    int nextIndex;
    
    switch (_playMode) {
      case PlayMode.sequence:
        nextIndex = currentIndex < _playlist.length - 1 ? currentIndex + 1 : -1;
        break;
      case PlayMode.random:
        nextIndex = Random().nextInt(_playlist.length);
        break;
      case PlayMode.single:
        nextIndex = currentIndex;
        break;
      case PlayMode.loop:
        nextIndex = (currentIndex + 1) % _playlist.length;
        break;
    }
    
    if (nextIndex != -1) {
      await playSong(_playlist[nextIndex]);
    }
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty || _currentSong == null) return;
    
    final currentIndex = _playlist.indexOf(_currentSong!);
    int previousIndex;
    
    switch (_playMode) {
      case PlayMode.sequence:
        previousIndex = currentIndex > 0 ? currentIndex - 1 : -1;
        break;
      case PlayMode.random:
        previousIndex = Random().nextInt(_playlist.length);
        break;
      case PlayMode.single:
        previousIndex = currentIndex;
        break;
      case PlayMode.loop:
        previousIndex = currentIndex > 0 ? currentIndex - 1 : _playlist.length - 1;
        break;
    }
    
    if (previousIndex != -1) {
      await playSong(_playlist[previousIndex]);
    }
  }

  // 播放全部
  Future<void> playAll(List<Song> songs, {bool shuffle = false, int? startIndex}) async {
    if (songs.isEmpty) return;
    
    _playlist.clear();
    _playlist.addAll(songs);
    
    if (shuffle) {
      _playlist.shuffle();
      _playMode = PlayMode.random;
    } else {
      _playMode = PlayMode.sequence;
    }
    
    await playSong(_playlist[startIndex ?? 0]);
  }

  // 进度条拖动相关
  void startSeek() {
    _isDraggingProgress = true;
  }

  void updateSeekPosition(Duration position) {
    _position = position;
    notifyListeners();
  }

  Future<void> endSeek(Duration position) async {
    _isDraggingProgress = false;
    await seek(position);
  }
  
  @override
  void dispose() {
    _playerService.dispose();
    super.dispose();
  }

  // 获取封面图片URL
  String getCoverArtUrl(String coverArtId) {
    if (_currentMusicService == null) {
      throw StateError('未设置音乐服务');
    }
    return _currentMusicService!.getCoverArtUrl(coverArtId);
  }

  // 预加载歌词
  Future<void> _preloadLyric(Song song) async {
    if (_lyricCache.containsKey(song.id)) {
      _currentLyric = _lyricCache[song.id];
      notifyListeners();
      return;
    }

    if (_isLoadingLyric) return;

    _isLoadingLyric = true;
    notifyListeners();

    try {
      final lrcContent = await _navidromeService.getLyrics(song.id);
      if (lrcContent != null) {
        final lyric = await _lyricService.parseLyric(lrcContent);
        if (lyric != null) {
          _lyricCache[song.id] = lyric;
          if (song.id == _currentSong?.id) {
            _currentLyric = lyric;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('加载歌词失败: $e');
    } finally {
      _isLoadingLyric = false;
      notifyListeners();
    }
  }

  // 清除歌词缓存
  void clearLyricCache() {
    _lyricCache.clear();
    _currentLyric = null;
    notifyListeners();
  }

  // 获取当前歌词
  LyricLine? getCurrentLyricLine() {
    if (_currentLyric == null) return null;
    return _currentLyric!.findLyricLine(_position);
  }
} 