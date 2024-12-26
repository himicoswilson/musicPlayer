import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/navidrome_service.dart';

class PlaylistProvider extends ChangeNotifier {
  final NavidromeService _service = NavidromeService();
  List<Playlist> _playlists = [];
  List<Song> _starredSongs = [];
  bool _isLoading = false;
  String? _error;

  PlaylistProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadPlaylists();
    await loadStarredSongs();
  }

  List<Playlist> get playlists => _playlists;
  List<Song> get starredSongs => _starredSongs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPlaylists() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _playlists = await _service.getPlaylists();
      _error = null;
    } catch (e) {
      _error = '加载歌单失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStarredSongs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _starredSongs = await _service.getStarred();
      _error = null;
    } catch (e) {
      _error = '加载收藏歌曲失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPlaylist(String name, {String? comment}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.createPlaylist(name, comment: comment);
      if (success) {
        await loadPlaylists();
        return true;
      }
      _error = '创建歌单失败';
      return false;
    } catch (e) {
      _error = '创建歌单失败: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePlaylist(String playlistId, {
    String? name,
    String? comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.updatePlaylist(
        playlistId,
        name: name,
        comment: comment,
      );
      if (success) {
        await loadPlaylists();
        return true;
      }
      _error = '更新歌单失败';
      return false;
    } catch (e) {
      _error = '更新歌单失败: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePlaylist(String playlistId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.deletePlaylist(playlistId);
      if (success) {
        await loadPlaylists();
        return true;
      }
      _error = '删除歌单失败';
      return false;
    } catch (e) {
      _error = '删除歌单失败: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleStarSong(String songId) async {
    try {
      final isStarred = isSongStarred(songId);
      final success = isStarred
          ? await _service.unstar(songId: songId)
          : await _service.star(songId: songId);
      if (success) {
        await loadStarredSongs();
      }
      return success;
    } catch (e) {
      _error = '收藏/取消收藏失败: $e';
      return false;
    }
  }

  bool isSongStarred(String songId) {
    return _starredSongs.any((song) => song.id == songId);
  }

  Future<bool> addToPlaylist(String playlistId, String songId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.addToPlaylist(playlistId, songId);
      if (success) {
        await loadPlaylists();
        return true;
      }
      _error = '添加歌曲到歌单失败';
      return false;
    } catch (e) {
      _error = '添加歌曲到歌单失败: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeFromPlaylist(String playlistId, int songIndex) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.removeFromPlaylist(playlistId, songIndex);
      if (success) {
        await loadPlaylists();
        return true;
      }
      _error = '从歌单中移除歌曲失败';
      return false;
    } catch (e) {
      _error = '从歌单中移除歌曲失败: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 