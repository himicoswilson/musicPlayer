import 'package:flutter/material.dart';
import '../services/local_music_service.dart';
import '../models/local_song.dart';
import 'player_provider.dart';

class LocalLibraryProvider extends ChangeNotifier {
  final LocalMusicService _localMusicService = LocalMusicService();
  final PlayerProvider _playerProvider;
  
  bool _isLoading = false;
  String? _error;
  List<LocalSong> _songs = [];
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<LocalSong> get songs => List.unmodifiable(_songs);
  
  LocalSong? get currentSong {
    final current = _playerProvider.currentSong;
    if (current is LocalSong) {
      return current;
    }
    return null;
  }

  LocalLibraryProvider(this._playerProvider);

  Future<void> loadSongs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final path = await _localMusicService.getLocalMusicPath();
      if (path == null) {
        _error = '未设置音乐文件夹';
        _songs = [];
      } else {
        _songs = await _localMusicService.scanMusicFiles(path);
      }
    } catch (e) {
      _error = e.toString();
      _songs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void playSong(LocalSong song) {
    _playerProvider.playSong(song);
  }

  void playAll([bool shuffle = false]) {
    if (_songs.isEmpty) return;
    
    if (shuffle) {
      _playerProvider.playAll(_songs, shuffle: true);
    } else {
      _playerProvider.playAll(_songs);
    }
  }
} 