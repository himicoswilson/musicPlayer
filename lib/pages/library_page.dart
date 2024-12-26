import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../widgets/mini_player.dart';
import '../services/navidrome_service.dart';
import 'player_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时获取数据
    Future.microtask(() {
      final provider = context.read<LibraryProvider>();
      provider.loadArtists();
      provider.loadAlbums();
      provider.loadSongs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('音乐库'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '歌曲'),
              Tab(text: '专辑'),
              Tab(text: '艺术家'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildSongsTab(context),
                  _buildAlbumsTab(),
                  _buildArtistsTab(),
                ],
              ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistsTab() {
    return Consumer<LibraryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text(provider.error!));
        }

        final artists = provider.artists;
        if (artists.isEmpty) {
          return const Center(child: Text('没有找到艺术家'));
        }

        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return ListTile(
              leading: artist.imageUrl != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(
                        provider.getCoverArtUrl(artist.imageUrl),
                      ),
                    )
                  : const CircleAvatar(child: Icon(Icons.person)),
              title: Text(artist.name),
              subtitle: Text('${artist.albumCount} 张专辑'),
              onTap: () {
                provider.loadArtistAlbums(artist.id);
                _showArtistAlbums(artist);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    return Consumer<LibraryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text(provider.error!));
        }

        final albums = provider.albums;
        if (albums.isEmpty) {
          return const Center(child: Text('没有找到专辑'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.75,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return _buildAlbumCard(album);
          },
        );
      },
    );
  }

  Widget _buildSongsTab(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '没有找到歌曲',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final settings = Provider.of<SettingsProvider>(context);

        return Column(
          children: [
            // 操作栏
            if (provider.songs.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '${provider.songs.length} 首歌曲',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.play_circle_filled),
                      label: const Text('播放全部'),
                      onPressed: () {
                        Provider.of<PlayerProvider>(context, listen: false)
                            .playAll(provider.songs);
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.shuffle),
                      label: const Text('随机播放'),
                      onPressed: () {
                        Provider.of<PlayerProvider>(context, listen: false)
                            .playAll(provider.songs, shuffle: true);
                      },
                    ),
                  ],
                ),
              ),
            // 歌曲列表
            Expanded(
              child: ListView.separated(
                itemCount: provider.songs.length,
                separatorBuilder: (context, index) => settings.showListDividers
                    ? const Divider(height: 1)
                    : const SizedBox.shrink(),
                itemBuilder: (context, index) {
                  final song = provider.songs[index];
                  final isPlaying = Provider.of<PlayerProvider>(context).currentSong?.id == song.id;
                  
                  return Container(
                    height: settings.listItemHeight,
                    child: ListTile(
                      leading: song.coverArtId != null
                          ? Image.network(
                              Provider.of<NavidromeService>(context, listen: false)
                                  .getCoverArtUrl(song.coverArtId!),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.album, size: 24),
                                );
                              },
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[200],
                              child: const Icon(Icons.album, size: 24),
                            ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPlaying ? Theme.of(context).primaryColor : null,
                          fontWeight: isPlaying ? FontWeight.bold : null,
                        ),
                      ),
                      subtitle: Text(
                        song.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isPlaying
                          ? Icon(
                              Icons.volume_up,
                              color: Theme.of(context).primaryColor,
                            )
                          : IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.playlist_add),
                                        title: const Text('添加到播放列表'),
                                        onTap: () {
                                          Provider.of<PlayerProvider>(context, listen: false)
                                              .addSongsToPlaylist([song]);
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('已添加到播放列表'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      onTap: () {
                        final provider = Provider.of<PlayerProvider>(context, listen: false);
                        provider.playSong(song, provider.getStreamUrl(song));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showArtistAlbums(Artist artist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer<LibraryProvider>(
                      builder: (context, provider, child) {
                        final albums = provider.getArtistAlbums(artist.id);
                        
                        if (provider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (albums == null || albums.isEmpty) {
                          return const Center(child: Text('没有找到专辑'));
                        }

                        return GridView.builder(
                          controller: scrollController,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: albums.length,
                          itemBuilder: (context, index) {
                            final album = albums[index];
                            return _buildAlbumCard(album);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlbumCard(Album album) {
    return Consumer<LibraryProvider>(
      builder: (context, provider, child) {
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              provider.loadAlbumSongs(album.id);
              _showAlbumSongs(album);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: album.coverArtId != null
                      ? Image.network(
                          provider.getCoverArtUrl(album.coverArtId),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(child: Icon(Icons.album)),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.album)),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        album.artistName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAlbumSongs(Album album) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    album.artistName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer<LibraryProvider>(
                      builder: (context, provider, child) {
                        final songs = provider.getAlbumSongs(album.id);
                        
                        if (provider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (songs == null || songs.isEmpty) {
                          return const Center(child: Text('没有找到歌曲'));
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: songs.length,
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            return ListTile(
                              leading: Text('${song.track}'),
                              title: Text(song.title),
                              subtitle: Text(song.artistName),
                              trailing: Text(_formatDuration(song.duration)),
                              onTap: () {
                                final url = provider.getStreamUrl(song.id);
                                _playSong(context, song, url);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds - minutes * 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _playSong(BuildContext context, Song song, String url) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.playSong(song, url);
    
    Navigator.push(
      context,
      BottomToTopPageRoute(
        child: PlayerPage(
          song: song,
          streamUrl: url,
        ),
      ),
    );
  }
} 