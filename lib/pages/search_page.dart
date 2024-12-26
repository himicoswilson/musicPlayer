import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../services/local_music_service.dart';
import '../services/navidrome_service.dart';
import '../providers/player_provider.dart';
import '../widgets/song_list_tile.dart';
import 'album_detail_page.dart';
import 'artist_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  List<Song> _songs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // 本地搜索
      final localService = LocalMusicService();
      final localResults = await localService.search(query);

      // 云端搜索
      final navidromeService = NavidromeService();
      final isNavidromeAvailable = await navidromeService.isAvailable();
      Map<String, dynamic> navidromeResults = {};
      
      if (isNavidromeAvailable) {
        navidromeResults = await navidromeService.search(query);
      }

      // 合并结果
      final List<Song> songs = [
        ...localResults['song'] as List<Song>? ?? [],
        ...navidromeResults['song']?.map<Song>((s) => Song.fromJson(s)) ?? [],
      ];

      final List<Album> albums = [
        ...localResults['album'] as List<Album>? ?? [],
        ...navidromeResults['album']?.map<Album>((a) => Album.fromJson(a)) ?? [],
      ];

      final List<Artist> artists = [
        ...localResults['artist'] as List<Artist>? ?? [],
        ...navidromeResults['artist']?.map<Artist>((a) => Artist.fromJson(a)) ?? [],
      ];

      setState(() {
        _songs = songs;
        _albums = albums;
        _artists = artists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '搜索失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索音乐、专辑、艺术家',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _songs = [];
                  _albums = [];
                  _artists = [];
                });
              },
            ),
          ),
          onSubmitted: _performSearch,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '歌曲'),
            Tab(text: '专辑'),
            Tab(text: '艺术家'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // 歌曲列表
                    ListView.builder(
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        return SongListTile(
                          song: song,
                          onTap: () {
                            context.read<PlayerProvider>().playAll(
                              _songs,
                              startIndex: index,
                            );
                          },
                        );
                      },
                    ),
                    // 专辑列表
                    ListView.builder(
                      itemCount: _albums.length,
                      itemBuilder: (context, index) {
                        final album = _albums[index];
                        return ListTile(
                          leading: album.coverArtId != null
                              ? Image.network(
                                  NavidromeService().getCoverArtUrl(album.coverArtId),
                                  width: 50,
                                  height: 50,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.album),
                                )
                              : const Icon(Icons.album),
                          title: Text(album.name),
                          subtitle: Text(album.artistName ?? '未知艺术家'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AlbumDetailPage(
                                  albumId: album.id,
                                  albumName: album.name,
                                  artistName: album.artistName ?? '未知艺术家',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    // 艺术家列表
                    ListView.builder(
                      itemCount: _artists.length,
                      itemBuilder: (context, index) {
                        final artist = _artists[index];
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(artist.name),
                          subtitle: Text('${artist.albumCount} 张专辑'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArtistDetailPage(
                                  artistId: artist.id,
                                  artistName: artist.name,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
    );
  }
} 