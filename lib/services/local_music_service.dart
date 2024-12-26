import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/local_song.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import 'music_service.dart';

class LocalMusicService implements MusicService {
  static const String _localMusicPathKey = 'localMusicPath';
  String? _musicPath;
  List<LocalSong> _cachedSongs = [];
  bool _initialized = false;

  static final LocalMusicService _instance = LocalMusicService._internal();
  factory LocalMusicService() => _instance;
  LocalMusicService._internal();

  @override
  Future<void> init() async {
    if (_initialized) return;
    _musicPath = await getLocalMusicPath();
    if (_musicPath != null) {
      _cachedSongs = await scanMusicFiles(_musicPath!);
    }
    _initialized = true;
  }

  @override
  Future<bool> isAvailable() async {
    final path = await getLocalMusicPath();
    if (path == null) return false;
    final dir = Directory(path);
    return await dir.exists();
  }

  @override
  Future<List<Artist>> getArtists() async {
    if (!_initialized) await init();
    final artists = <String, List<LocalSong>>{};
    
    for (var song in _cachedSongs) {
      final artistName = song.artistName;
      artists.putIfAbsent(artistName, () => []).add(song);
    }

    return artists.entries.map((entry) => Artist(
      id: entry.key,
      name: entry.key,
      albumCount: entry.value.map((s) => s.albumName).toSet().length,
    )).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<Album>> getArtistAlbums(String artistId) async {
    if (!_initialized) await init();
    final albums = <String, List<LocalSong>>{};
    
    for (var song in _cachedSongs.where((s) => s.artistName == artistId)) {
      final albumName = song.albumName;
      albums.putIfAbsent(albumName, () => []).add(song);
    }

    return albums.entries.map((entry) => Album(
      id: '${artistId}_${entry.key}',
      name: entry.key,
      artistId: artistId,
      artistName: artistId,
      songCount: entry.value.length,
      duration: entry.value.fold<int>(0, (sum, song) => 
          sum + song.duration),
      year: entry.value.first.year?.toString(),
    )).toList();
  }

  @override
  Future<List<Album>> getAlbums({int? size, int? offset}) async {
    if (!_initialized) await init();
    final albums = <String, List<LocalSong>>{};
    
    for (var song in _cachedSongs) {
      final albumKey = '${song.artistName}_${song.albumName}';
      albums.putIfAbsent(albumKey, () => []).add(song);
    }

    var allAlbums = albums.entries.map((entry) {
      final artist = entry.value.first.artistName;
      final albumName = entry.value.first.albumName;
      return Album(
        id: '${artist}_$albumName',
        name: albumName,
        artistId: artist,
        artistName: artist,
        songCount: entry.value.length,
        duration: entry.value.fold<int>(0, (sum, song) => 
            sum + song.duration),
        year: entry.value.first.year?.toString(),
      );
    }).toList();

    allAlbums.sort((a, b) {
      final yearA = int.tryParse(a.year ?? '') ?? 0;
      final yearB = int.tryParse(b.year ?? '') ?? 0;
      return yearB.compareTo(yearA);
    });

    if (offset != null) {
      allAlbums = allAlbums.skip(offset).toList();
    }
    if (size != null) {
      allAlbums = allAlbums.take(size).toList();
    }

    return allAlbums;
  }

  @override
  Future<List<Song>> getAlbumSongs(String albumId) async {
    if (!_initialized) await init();
    final parts = albumId.split('_');
    if (parts.length < 2) return [];
    
    final artist = parts.first;
    final albumName = parts.sublist(1).join('_');
    
    return _cachedSongs
        .where((s) => s.artistName == artist && s.albumName == albumName)
        .map((s) => s as Song)
        .toList()
      ..sort((a, b) => (a.track).compareTo(b.track));
  }

  @override
  Future<List<Song>> getNewestSongs({int? size}) async {
    if (!_initialized) await init();
    var songs = List<Song>.from(_cachedSongs)
      ..sort((a, b) {
        final dateA = (a as LocalSong).lastModified ?? DateTime.now();
        final dateB = (b as LocalSong).lastModified ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
    
    if (size != null) {
      songs = songs.take(size).toList();
    }
    return songs;
  }

  @override
  Future<Map<String, dynamic>> search(String query) async {
    if (!_initialized) await init();
    query = query.toLowerCase();
    
    final matchingSongs = _cachedSongs.where((song) =>
        song.title.toLowerCase().contains(query) ||
        song.artistName.toLowerCase().contains(query) ||
        song.albumName.toLowerCase().contains(query)
    ).toList();

    final artists = matchingSongs
        .map((s) => s.artistName)
        .toSet()
        .map((name) => Artist(
              id: name,
              name: name,
              albumCount: matchingSongs
                  .where((s) => s.artistName == name)
                  .map((s) => s.albumName)
                  .toSet()
                  .length,
            ))
        .toList();

    final albums = matchingSongs
        .map((s) => '${s.artistName}_${s.albumName}')
        .toSet()
        .map((key) {
          final songs = matchingSongs
              .where((s) => '${s.artistName}_${s.albumName}' == key)
              .toList();
          final firstSong = songs.first;
          return Album(
            id: key,
            name: firstSong.albumName,
            artistId: firstSong.artistName,
            artistName: firstSong.artistName,
            songCount: songs.length,
            duration: songs.fold<int>(0, (sum, song) => 
                sum + song.duration),
            year: firstSong.year?.toString(),
          );
        })
        .toList();

    return {
      'artist': artists,
      'album': albums,
      'song': matchingSongs,
    };
  }

  @override
  String getStreamUrl(String songId) {
    return 'file://$songId';
  }

  @override
  String getCoverArtUrl(String? coverArtId) {
    if (coverArtId == null) return '';
    return 'file://$coverArtId';
  }

  Future<String?> getLocalMusicPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localMusicPathKey);
  }

  Future<void> setLocalMusicPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localMusicPathKey, path);
    _musicPath = path;
    _cachedSongs = await scanMusicFiles(path);
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      return true;
    }
    return true;
  }

  Future<String?> pickMusicDirectory() async {
    if (Platform.isAndroid) {
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('需要存储权限来选择音乐文件夹');
      }
    }

    try {
      if (Platform.isIOS) {
        // 在iOS上，我们使用应用的Documents目录
        final directory = await getApplicationDocumentsDirectory();
        final musicDir = Directory('${directory.path}/Music');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
        await setLocalMusicPath(musicDir.path);
        return musicDir.path;
      } else {
        String? initialDirectory = await getLocalMusicPath() ?? await getDefaultMusicDirectory();
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: '选择音乐文件夹',
          initialDirectory: initialDirectory,
        );

        if (selectedDirectory != null) {
          final dir = Directory(selectedDirectory);
          if (!await dir.exists()) {
            throw Exception('选择的目录不存在');
          }
          await setLocalMusicPath(selectedDirectory);
          return selectedDirectory;
        }
      }
      return null;
    } catch (e) {
      throw Exception('选择文件夹失败: $e');
    }
  }

  Future<List<LocalSong>> scanMusicFiles(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      throw Exception('目录不存在');
    }

    List<LocalSong> musicFiles = [];
    try {
      await for (var entity in dir.list(recursive: true)) {
        if (entity is File) {
          String path = entity.path.toLowerCase();
          if (path.endsWith('.mp3') || 
              path.endsWith('.m4a') || 
              path.endsWith('.wav') || 
              path.endsWith('.flac')) {
            try {
              final song = await LocalSong.fromFile(entity);
              musicFiles.add(song);
            } catch (e) {
              print('Error processing file ${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error scanning directory: $e');
      // 如果扫描失败，返回空列表而不是抛出异常
      return [];
    }

    musicFiles.sort((a, b) {
      final artistCompare = a.artistName.compareTo(b.artistName);
      if (artistCompare != 0) return artistCompare;
      return a.title.compareTo(b.title);
    });

    return musicFiles;
  }

  Future<String> getDefaultMusicDirectory() async {
    if (Platform.isAndroid) {
      final directory = Directory('/storage/emulated/0/Music');
      if (await directory.exists()) {
        return directory.path;
      }
      return (await getExternalStorageDirectory())?.path ?? '/storage/emulated/0/Music';
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${directory.path}/Music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      return musicDir.path;
    }
    return (await getApplicationDocumentsDirectory()).path;
  }
} 