import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/player_service.dart';

enum PlayMode {
  sequence, // 顺序播放
  random,   // 随机播放
  single,   // 单曲循环
  loop      // 列表循环
}

class PlayerProvider extends ChangeNotifier {
  final PlayerService _playerService = PlayerService();
  bool _isInitialized = false;
  bool _isDraggingProgress = false;  // 添加拖动状态标志
  
  // 播放模式
  PlayMode _playMode = PlayMode.sequence;
  PlayMode get playMode => _playMode;
  
  // 当前播放的歌曲
  Song? _currentSong;
  Song? get currentSong => _currentSong;
  
  // 播放列表
  final List<Song> _playlist = [];
  List<Song> get playlist => List.unmodifiable(_playlist);
  
  // 播放状态
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  
  // 播放进度
  Duration _position = Duration.zero;
  Duration get position => _position;
  
  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  PlayerProvider() {
    _init();
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    
    try {
      // 监听播放状态
      _playerService.player.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        notifyListeners();
      });

      // 监听播放进度
      _playerService.player.positionStream.listen((position) {
        if (!_isDraggingProgress) {  // 只在非拖动状态下更新位置
          _position = position;
          notifyListeners();
        }
      });

      // 监听音频时长
      _playerService.player.durationStream.listen((duration) {
        _duration = duration ?? Duration.zero;
        notifyListeners();
      });

      // 监听播放完成
      _playerService.player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          _onSongComplete();
        }
      });

      _isInitialized = true;
    } catch (e) {
      print('PlayerProvider 初始化失败: $e');
    }
  }

  // 播放歌曲
  Future<void> playSong(Song song, String url) async {
    if (!_isInitialized) await _init();
    
    try {
      _currentSong = song;
      if (!_playlist.contains(song)) {
        _playlist.add(song);
      }
      _playerService.updateCurrentSong(song);
      await _playerService.play(url);
      notifyListeners();
    } catch (e) {
      print('播放失败: $e');
    }
  }

  // 暂停/继续
  Future<void> togglePlay() async {
    if (!_isInitialized) await _init();
    
    try {
      if (_isPlaying) {
        await _playerService.pause();
      } else {
        await _playerService.resume();
      }
    } catch (e) {
      print('切换播放状态失败: $e');
    }
  }

  // 跳转到指定位置
  Future<void> seek(Duration position) async {
    if (!_isInitialized) await _init();
    
    try {
      await _playerService.seek(position);
    } catch (e) {
      print('跳转失败: $e');
    }
  }

  // 切换播放模式
  void togglePlayMode() {
    final modes = PlayMode.values;
    final currentIndex = modes.indexOf(_playMode);
    _playMode = modes[(currentIndex + 1) % modes.length];
    notifyListeners();
  }

  // 播放下一首
  Future<void> playNext() async {
    if (_playlist.isEmpty || _currentSong == null) return;
    
    final nextIndex = _getNextIndex();
    if (nextIndex != -1) {
      final nextSong = _playlist[nextIndex];
      await playSong(nextSong, getStreamUrl(nextSong));
    }
  }

  // 播放上一首
  Future<void> playPrevious() async {
    if (_playlist.isEmpty || _currentSong == null) return;
    
    final previousIndex = _getPreviousIndex();
    if (previousIndex != -1) {
      final previousSong = _playlist[previousIndex];
      await playSong(previousSong, getStreamUrl(previousSong));
    }
  }

  // 获取下一首歌曲的索引
  int _getNextIndex() {
    if (_playlist.isEmpty || _currentSong == null) return -1;
    
    final currentIndex = _playlist.indexOf(_currentSong!);
    switch (_playMode) {
      case PlayMode.sequence:
        return currentIndex < _playlist.length - 1 ? currentIndex + 1 : -1;
      case PlayMode.random:
        return Random().nextInt(_playlist.length);
      case PlayMode.single:
        return currentIndex;
      case PlayMode.loop:
        return (currentIndex + 1) % _playlist.length;
    }
  }

  // 获取上一首歌曲的索引
  int _getPreviousIndex() {
    if (_playlist.isEmpty || _currentSong == null) return -1;
    
    final currentIndex = _playlist.indexOf(_currentSong!);
    switch (_playMode) {
      case PlayMode.sequence:
        return currentIndex > 0 ? currentIndex - 1 : -1;
      case PlayMode.random:
        return Random().nextInt(_playlist.length);
      case PlayMode.single:
        return currentIndex;
      case PlayMode.loop:
        return currentIndex > 0 ? currentIndex - 1 : _playlist.length - 1;
    }
  }

  // 歌曲播放完成的处理
  void _onSongComplete() {
    switch (_playMode) {
      case PlayMode.single:
        if (_currentSong != null) {
          playSong(_currentSong!, getStreamUrl(_currentSong!));
        }
        break;
      default:
        playNext();
        break;
    }
  }

  // 获取歌曲的流媒体URL
  String getStreamUrl(Song song) {
    return 'http://localhost:4533/rest/stream.view?id=${song.id}&u=admin&t=5f4dcc3b5aa765d61d8327deb882cf99&s=&v=1.16.1&c=musicPlayer';
  }

  // 添加多首歌曲到播放列表
  void addSongsToPlaylist(List<Song> songs) {
    for (final song in songs) {
      if (!_playlist.contains(song)) {
        _playlist.add(song);
      }
    }
    notifyListeners();
  }

  // 从播放列表中移除歌曲
  void removeFromPlaylist(Song song) {
    _playlist.remove(song);
    notifyListeners();
  }

  // 清空播放列表
  void clearPlaylist() {
    _playlist.clear();
    _currentSong = null;
    notifyListeners();
  }

  // 播放全部歌曲
  Future<void> playAll(List<Song> songs, {bool shuffle = false}) async {
    if (songs.isEmpty) return;
    
    // 清空当前播放列表
    _playlist.clear();
    
    // 添加所有歌曲
    _playlist.addAll(songs);
    
    // 如果需要随机播放，则打乱列表
    if (shuffle) {
      _playlist.shuffle();
      _playMode = PlayMode.random;
    } else {
      _playMode = PlayMode.sequence;
    }
    
    // 播放第一首歌
    await playSong(_playlist.first, getStreamUrl(_playlist.first));
  }

  // 开始拖动进度条
  void startSeek() {
    _isDraggingProgress = true;
  }

  // 更新拖动位置
  void updateSeekPosition(Duration position) {
    _position = position;
    notifyListeners();
  }

  // 结束拖动并跳转
  Future<void> endSeek(Duration position) async {
    _isDraggingProgress = false;
    await seek(position);
  }

  @override
  void dispose() {
    _playerService.dispose();
    super.dispose();
  }
} 