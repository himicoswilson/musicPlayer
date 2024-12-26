import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song.dart';
import '../services/navidrome_service.dart';

class PlayerService {
  AudioPlayer? _player;
  AudioHandler? _audioHandler;
  final NavidromeService _navidromeService = NavidromeService();
  bool _initialized = false;
  
  // 单例模式
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  
  PlayerService._internal() {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    
    try {
      _audioHandler = await AudioService.init(
        builder: () => MyAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.myapp.audio',
          androidNotificationChannelName: 'Audio Service',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
      _player = (_audioHandler as MyAudioHandler).player;
      _initialized = true;
    } catch (e) {
      print('初始化播放器失败: $e');
    }
  }

  AudioPlayer get player {
    if (_player == null) {
      throw StateError('播放器尚未初始化');
    }
    return _player!;
  }

  // 播放歌曲
  Future<void> play(String url) async {
    if (!_initialized) await _init();
    try {
      await _audioHandler?.playMediaItem(
        MediaItem(
          id: url,
          album: _currentSong?.albumName ?? '',
          title: _currentSong?.title ?? '',
          artist: _currentSong?.artistName ?? '',
          duration: Duration(seconds: _currentSong?.duration ?? 0),
          artUri: _currentSong?.coverArtId != null 
              ? Uri.parse(_getCoverArtUrl(_currentSong!.coverArtId!))
              : null,
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

  Song? _currentSong;
  void updateCurrentSong(Song song) {
    _currentSong = song;
  }

  String _getCoverArtUrl(String coverArtId) {
    return _navidromeService.getCoverArtUrl(coverArtId);
  }
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final List<MediaItem> _mediaItems = [];

  MyAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });
  }

  AudioPlayer get player => _player;

  Future<void> playMediaItem(MediaItem mediaItem) async {
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(mediaItem.id)));
      mediaItem = mediaItem.copyWith(duration: _player.duration);
      _mediaItems.add(mediaItem);
      await _player.play();
    } catch (e) {
      print('Error playing media item: $e');
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
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
    ));
  }
} 