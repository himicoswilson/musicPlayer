import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/navidrome_service.dart';
import '../services/local_music_service.dart';
import '../providers/player_provider.dart';
import '../widgets/song_list_tile.dart';

class AlbumDetailPage extends StatefulWidget {
  final String albumId;
  final String albumName;
  final String artistName;

  const AlbumDetailPage({
    super.key,
    required this.albumId,
    required this.albumName,
    required this.artistName,
  });

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  late Future<List<Song>> _songsFuture;
  final NavidromeService _navidromeService = NavidromeService();
  final LocalMusicService _localMusicService = LocalMusicService();

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  void _loadSongs() {
    _songsFuture = _loadAlbumSongs();
  }

  Future<List<Song>> _loadAlbumSongs() async {
    try {
      // 首先尝试从本地加载
      final localSongs = await _localMusicService.getAlbumSongs(widget.albumId);
      if (localSongs.isNotEmpty) {
        return localSongs;
      }

      // 如果本地没有，尝试从云端加载
      if (await _navidromeService.isAvailable()) {
        return await _navidromeService.getAlbumSongs(widget.albumId);
      }

      return [];
    } catch (e) {
      print('加载专辑歌曲失败: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.albumName),
            Text(
              widget.artistName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Song>>(
        future: _songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('加载失败: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadSongs();
                      });
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final songs = snapshot.data ?? [];
          if (songs.isEmpty) {
            return const Center(child: Text('暂无歌曲'));
          }

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return SongListTile(
                song: song,
                onTap: () {
                  context.read<PlayerProvider>().playAll(
                    songs,
                    startIndex: index,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 