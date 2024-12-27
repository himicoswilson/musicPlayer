import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song.dart';
import 'music_service.dart';

class PlayerService {
  AudioPlayer? _player;
  AudioHandler? _audioHandler;
  MusicService? _currentMusicService;
  bool _initialized = false;
  static bool _isInitializing = false;
  
  // 状态监听回调
  Function(Duration)? onPositionChanged;
  Function(Duration)? onDurationChanged;
  Function(bool)? onPlayingChanged;
  
  // 单例模式
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  
  PlayerService._internal() {
    _init();
  }

  Future<void> _init() async {
    if (_initialized || _isInitializing) return;
    
    try {
      _isInitializing = true;
      
      // 确保 AudioService 只初始化一次
      if (_audioHandler == null) {
        _audioHandler = await AudioService.init(
          builder: () => MyAudioHandler(),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.myapp.audio',
            androidNotificationChannelName: '音乐播放器',
            androidNotificationChannelDescription: '音乐播放器通知',
            androidNotificationIcon: 'mipmap/ic_launcher',
            androidShowNotificationBadge: true,
            androidNotificationOngoing: true,
            androidStopForegroundOnPause: true,
            artDownscaleWidth: 300,
            artDownscaleHeight: 300,
            fastForwardInterval: Duration(seconds: 10),
            rewindInterval: Duration(seconds: 10),
            preloadArtwork: true,
          ),
        );
      }
      
      _player = (_audioHandler as MyAudioHandler).player;
      
      // 添加状态监听
      _player?.positionStream.listen((position) {
        onPositionChanged?.call(position);
      });
      
      _player?.durationStream.listen((duration) {
        if (duration != null) {
          onDurationChanged?.call(duration);
        }
      });
      
      _player?.playingStream.listen((playing) {
        onPlayingChanged?.call(playing);
      });
      
      _initialized = true;
    } catch (e) {
      print('初始化播放器失败: $e');
    } finally {
      _isInitializing = false;
    }
  }

  AudioPlayer get player {
    if (_player == null) {
      throw StateError('播放器尚未初始化');
    }
    return _player!;
  }

  void setMusicService(MusicService service) {
    _currentMusicService = service;
  }

  // 播放歌曲
  Future<void> play(Song song) async {
    if (!_initialized) await _init();
    if (_currentMusicService == null) {
      throw StateError('未设置音乐服务');
    }
    try {
      final url = await _currentMusicService!.getStreamUrl(song.id);
      final coverArtUrl = _currentMusicService!.getCoverArtUrl(song.coverArtId);
      
      await _audioHandler?.playMediaItem(
        MediaItem(
          id: url,
          album: song.albumName ?? '',
          title: song.title,
          artist: song.artistName ?? '',
          duration: Duration(seconds: song.duration),
          artUri: coverArtUrl.isNotEmpty ? Uri.parse(coverArtUrl) : null,
          extras: {
            'songId': song.id,
            'coverArtId': song.coverArtId,
          },
        ),
      );
    } catch (e) {
      print('播放失败: $e');
    }
  }

  // 暂停
  Future<void> pause() async {
    if (!_initialized) return;
    try {
      await _audioHandler?.pause();
    } catch (e) {
      print('暂停失败: $e');
    }
  }

  // 继续播放
  Future<void> resume() async {
    if (!_initialized) return;
    try {
      await _audioHandler?.play();
    } catch (e) {
      print('继续播放失败: $e');
    }
  }

  // 停止
  Future<void> stop() async {
    if (!_initialized) return;
    try {
      await _audioHandler?.stop();
    } catch (e) {
      print('停止失败: $e');
    }
  }

  // 跳转到指定位置
  Future<void> seek(Duration position) async {
    if (!_initialized) return;
    try {
      await _audioHandler?.seek(position);
    } catch (e) {
      print('跳转失败: $e');
    }
  }

  // 设置音量
  Future<void> setVolume(double volume) async {
    if (!_initialized) return;
    try {
      await _player?.setVolume(volume);
    } catch (e) {
      print('设置音量失败: $e');
    }
  }

  // 释放资源
  Future<void> dispose() async {
    if (!_initialized) return;
    await _player?.dispose();
    await _audioHandler?.stop();
    _initialized = false;
  }
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final List<MediaItem> _mediaItems = [];
  int? _currentIndex;

  MyAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handlePlaybackCompletion();
      }
    });
  }

  AudioPlayer get player => _player;

  Future<void> playMediaItem(MediaItem mediaItem) async {
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(mediaItem.id)));
      // 等待获取实际时长
      await _player.load();
      final duration = _player.duration;
      if (duration != null) {
        mediaItem = mediaItem.copyWith(duration: duration);
      }
      _mediaItems.clear();  // 清除之前的媒体项
      _mediaItems.add(mediaItem);
      _currentIndex = 0;
      mediaItem = mediaItem.copyWith(duration: _player.duration);
      mediaItem = await _updateMediaItem(mediaItem);
      await _player.play();
    } catch (e) {
      print('Error playing media item: $e');
    }
  }

  Future<MediaItem> _updateMediaItem(MediaItem mediaItem) async {
    mediaItem = mediaItem.copyWith(
      id: mediaItem.id,
      album: mediaItem.album,
      title: mediaItem.title,
      artist: mediaItem.artist,
      duration: mediaItem.duration,
      artUri: mediaItem.artUri,
      playable: true,
      displayTitle: mediaItem.title,
      displaySubtitle: mediaItem.artist,
      displayDescription: mediaItem.album,
    );
    mediaItem = await _addRatingAndLyrics(mediaItem);
    return mediaItem;
  }

  Future<MediaItem> _addRatingAndLyrics(MediaItem mediaItem) async {
    // TODO: 从服务器获取歌曲评分和歌词信息
    return mediaItem.copyWith(
      rating: const Rating.newHeartRating(false),
      extras: {
        'lyrics': '', // 这里可以添加歌词
      },
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToPrevious() async {
    if (_currentIndex == null || _mediaItems.isEmpty) return;
    if (_currentIndex! > 0) {
      _currentIndex = _currentIndex! - 1;
      await playMediaItem(_mediaItems[_currentIndex!]);
    }
  }

  @override
  Future<void> skipToNext() async {
    if (_currentIndex == null || _mediaItems.isEmpty) return;
    if (_currentIndex! < _mediaItems.length - 1) {
      _currentIndex = _currentIndex! + 1;
      await playMediaItem(_mediaItems[_currentIndex!]);
    }
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      await _player.setShuffleModeEnabled(false);
    } else {
      await _player.setShuffleModeEnabled(true);
    }
  }

  Future<void> _handlePlaybackCompletion() async {
    if (_currentIndex != null && _currentIndex! < _mediaItems.length - 1) {
      await skipToNext();
    } else {
      await stop();
    }
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final repeatMode = _player.loopMode;
    final shuffleMode = _player.shuffleModeEnabled;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.setRepeatMode,
        MediaAction.setShuffleMode,
        MediaAction.setSpeed,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
      repeatMode: {
        LoopMode.off: AudioServiceRepeatMode.none,
        LoopMode.one: AudioServiceRepeatMode.one,
        LoopMode.all: AudioServiceRepeatMode.all,
      }[repeatMode]!,
      shuffleMode: shuffleMode
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    ));

    // 更新媒体会话
    if (_currentIndex != null && _currentIndex! < _mediaItems.length) {
      mediaItem.add(_mediaItems[_currentIndex!]);
    }
  }
} 