import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/local_library_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_provider.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/local_song.dart';
import '../widgets/mini_player.dart';
import '../services/navidrome_service.dart';
import 'player_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    // 设置播放状态变化回调
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      
      // 计算标签页数量
      int tabCount = 0;
      if (auth.isLocalMode) tabCount++;
      if (auth.isNavidromeLoggedIn) tabCount += 3;
      
      // 初始化 TabController
      setState(() {
        _tabController = TabController(length: tabCount, vsync: this);
      });

      // 加载数据
      // 如果开启了本地模式，加载本地音乐
      if (auth.isLocalMode) {
        context.read<LocalLibraryProvider>().loadSongs();
      }
      
      // 如果已登录 Navidrome，加载在线音乐
      if (auth.isNavidromeLoggedIn) {
        final provider = context.read<LibraryProvider>();
        provider.loadArtists();
        provider.loadAlbums();
        provider.loadSongs();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _playSong(BuildContext context, Song song) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.playSong(song);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final showNavidromeContent = auth.isNavidromeLoggedIn;
    final showLocalContent = auth.isLocalMode;

    // 计算需要显示的标签页数量
    int tabCount = 0;
    if (showLocalContent) tabCount++;
    if (showNavidromeContent) tabCount += 3;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('音乐库'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: [
              if (showLocalContent)
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open),
                      SizedBox(width: 8),
                      Text('本地音乐'),
                    ],
                  ),
                ),
              if (showNavidromeContent) ...[
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud),
                      SizedBox(width: 8),
                      Text('在线歌曲'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.album),
                      SizedBox(width: 8),
                      Text('在线专辑'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text('在线艺术家'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  if (showLocalContent)
                    _buildLocalSongsTab(context),
                  if (showNavidromeContent) ...[
                    _buildSongsTab(context),
                    _buildAlbumsTab(),
                    _buildArtistsTab(),
                  ],
                ],
              ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalSongsTab(BuildContext context) {
    return Consumer2<LocalLibraryProvider, SettingsProvider>(
      builder: (context, provider, settings, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text(provider.error!));
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
                  '没有找到本地音乐',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                  child: const Text('去设置音乐文件夹'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
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
                      Provider.of<LocalLibraryProvider>(context, listen: false).playAll();
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.shuffle),
                    label: const Text('随机播放'),
                    onPressed: () {
                      Provider.of<LocalLibraryProvider>(context, listen: false).playAll(true);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: provider.songs.length,
                separatorBuilder: (context, index) => settings.showListDividers
                    ? const Divider(height: 1)
                    : const SizedBox.shrink(),
                itemBuilder: (context, index) {
                  final song = provider.songs[index];
                  final isPlaying = provider.currentSong?.id == song.id;
                  
                  return Container(
                    height: settings.listItemHeight,
                    child: ListTile(
                      leading: song.coverData != null
                          ? Image.memory(
                              song.coverData!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[200],
                              child: const Icon(Icons.music_note, size: 24),
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
                      trailing: IconButton(
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
                                Consumer<PlaylistProvider>(
                                  builder: (context, provider, child) {
                                    final isStarred = provider.isSongStarred(song.id);
                                    return ListTile(
                                      leading: Icon(
                                        isStarred ? Icons.favorite : Icons.favorite_border
                                      ),
                                      title: Text(isStarred ? '取消收藏' : '收藏'),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await provider.toggleStarSong(song.id);
                                      },
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.playlist_add),
                                  title: const Text('添加到歌单'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAddToPlaylistDialog(context, song);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        provider.playSong(song);
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
                      trailing: IconButton(
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
                                Consumer<PlaylistProvider>(
                                  builder: (context, provider, child) {
                                    final isStarred = provider.isSongStarred(song.id);
                                    return ListTile(
                                      leading: Icon(
                                        isStarred ? Icons.favorite : Icons.favorite_border
                                      ),
                                      title: Text(isStarred ? '取消收藏' : '收藏'),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await provider.toggleStarSong(song.id);
                                      },
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.playlist_add),
                                  title: const Text('添加到歌单'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAddToPlaylistDialog(context, song);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
                        playerProvider.playSong(song);
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Consumer<PlaylistProvider>(
                                    builder: (context, provider, child) {
                                      final isStarred = provider.isSongStarred(song.id);
                                      return IconButton(
                                        icon: Icon(
                                          isStarred ? Icons.favorite : Icons.favorite_border
                                        ),
                                        onPressed: () => provider.toggleStarSong(song.id),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_formatDuration(song.duration)),
                                ],
                              ),
                              onTap: () {
                                _playSong(context, song);
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

  void _showAddToPlaylistDialog(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<PlaylistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('还没有歌单'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCreatePlaylistDialog(context, song);
                    },
                    child: const Text('创建歌单'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.playlists.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('创建新歌单'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreatePlaylistDialog(context, song);
                  },
                );
              }

              final playlist = provider.playlists[index - 1];
              return ListTile(
                leading: const Icon(Icons.playlist_play),
                title: Text(playlist.name),
                subtitle: Text('${playlist.songCount} 首歌曲'),
                onTap: () async {
                  Navigator.pop(context);
                  final currentPlaylist = await NavidromeService().getPlaylist(playlist.id);
                  if (currentPlaylist != null) {
                    if (!currentPlaylist.songs.any((s) => s.id == song.id)) {
                      final success = await provider.addToPlaylist(playlist.id, song.id);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已添加到歌单')),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('添加失败')),
                        );
                      }
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('歌曲已在歌单中')),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, Song song) {
    final nameController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建歌单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '歌单名称',
                hintText: '请输入歌单名称',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: '描述',
                hintText: '请输入歌单描述（可选）',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入歌单名称')),
                );
                return;
              }

              final provider = context.read<PlaylistProvider>();
              final success = await provider.createPlaylist(
                nameController.text,
                comment: commentController.text.isEmpty
                    ? null
                    : commentController.text,
              );

              if (success && context.mounted) {
                final playlists = provider.playlists;
                if (playlists.isNotEmpty) {
                  final newPlaylist = playlists.last;
                  final addSuccess = await provider.addToPlaylist(
                    newPlaylist.id,
                    song.id,
                  );
                  if (addSuccess && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已创建歌单并添加歌曲')),
                    );
                  } else if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('创建歌单成功，但添加歌曲失败')),
                    );
                  }
                }
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('创建歌单失败')),
                );
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
} 