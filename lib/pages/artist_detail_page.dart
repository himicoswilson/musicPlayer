import 'package:flutter/material.dart';
import '../models/album.dart';
import '../services/navidrome_service.dart';
import '../services/local_music_service.dart';
import 'album_detail_page.dart';

class ArtistDetailPage extends StatefulWidget {
  final String artistId;
  final String artistName;

  const ArtistDetailPage({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  late Future<List<Album>> _albumsFuture;
  final NavidromeService _navidromeService = NavidromeService();
  final LocalMusicService _localMusicService = LocalMusicService();

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  void _loadAlbums() {
    _albumsFuture = _loadArtistAlbums();
  }

  Future<List<Album>> _loadArtistAlbums() async {
    try {
      // 首先尝试从本地加载
      final localAlbums = await _localMusicService.getArtistAlbums(widget.artistId);
      if (localAlbums.isNotEmpty) {
        return localAlbums;
      }

      // 如果本地没有，尝试从云端加载
      if (await _navidromeService.isAvailable()) {
        return await _navidromeService.getArtistAlbums(widget.artistId);
      }

      return [];
    } catch (e) {
      print('加载艺术家专辑失败: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artistName),
      ),
      body: FutureBuilder<List<Album>>(
        future: _albumsFuture,
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
                        _loadAlbums();
                      });
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final albums = snapshot.data ?? [];
          if (albums.isEmpty) {
            return const Center(child: Text('暂无专辑'));
          }

          return ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return ListTile(
                leading: album.coverArtId != null
                    ? Image.network(
                        _navidromeService.getCoverArtUrl(album.coverArtId),
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.album),
                      )
                    : const Icon(Icons.album),
                title: Text(album.name),
                subtitle: Text('${album.songCount} 首歌曲'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumDetailPage(
                        albumId: album.id,
                        albumName: album.name,
                        artistName: widget.artistName,
                      ),
                    ),
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