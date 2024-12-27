import 'package:flutter/foundation.dart';
import '../services/navidrome_service.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';

class LibraryProvider with ChangeNotifier {
  final NavidromeService _navidromeService;
  
  List<Artist> _artists = [];
  List<Album> _albums = [];
  List<Song> _songs = [];
  Map<String, List<Album>> _artistAlbums = {};
  Map<String, List<Song>> _albumSongs = {};
  
  bool _isLoading = false;
  String? _error;

  LibraryProvider(this._navidromeService);

  List<Artist> get artists => _artists;
  List<Album> get albums => _albums;
  List<Song> get songs => _songs;
  List<Album>? getArtistAlbums(String artistId) => _artistAlbums[artistId];
  List<Song>? getAlbumSongs(String albumId) => _albumSongs[albumId];
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadArtists() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _artists = await _navidromeService.getArtists();
    } catch (e) {
      _error = '加载艺术家列表失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAlbums() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _albums = await _navidromeService.getAlbums();
    } catch (e) {
      _error = '加载专辑列表失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSongs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _songs = await _navidromeService.getNewestSongs();
    } catch (e) {
      _error = '加载歌曲列表失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadArtistAlbums(String artistId) async {
    if (_artistAlbums.containsKey(artistId)) return;

    _isLoading = true;
    notifyListeners();

    try {
      final albums = await _navidromeService.getArtistAlbums(artistId);
      _artistAlbums[artistId] = albums;
    } catch (e) {
      _error = '加载专辑列表失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAlbumSongs(String albumId) async {
    if (_albumSongs.containsKey(albumId)) return;

    _isLoading = true;
    notifyListeners();

    try {
      final songs = await _navidromeService.getAlbumSongs(albumId);
      _albumSongs[albumId] = songs;
    } catch (e) {
      _error = '加载歌���列表失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> search(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _navidromeService.search(query);
      _isLoading = false;
      notifyListeners();
      return results;
    } catch (e) {
      _error = '搜索失败: $e';
      _isLoading = false;
      notifyListeners();
      return {};
    }
  }

  Future<String> getStreamUrl(String songId) {
    return _navidromeService.getStreamUrl(songId);
  }

  String getCoverArtUrl(String? coverArtId) {
    return _navidromeService.getCoverArtUrl(coverArtId);
  }
} 