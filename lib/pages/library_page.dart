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
import '../providers/cache_provider.dart';

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

  void _showSongOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('添加到播放列表'),
              onTap: () {
                context.read<PlayerProvider>().addSongsToPlaylist([song]);
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
                    isStarred ? Icons.favorite : Icons.favorite_border,
                    color: isStarred ? Theme.of(context).colorScheme.primary : null,
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
            Consumer<CacheProvider>(
              builder: (context, provider, child) {
                final isCached = provider.isCached(song.id);
                final isDownloading = provider.isDownloading(song.id);
                
                if (isDownloading) {
                  return ListTile(
                    leading: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: provider.getDownloadProgress(song.id),
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: const Text('正在下载'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => provider.cancelDownload(song.id),
                    ),
                  );
                }
                
                return ListTile(
                  leading: Icon(isCached ? Icons.delete : Icons.download),
                  title: Text(isCached ? '删除缓存' : '下载'),
                  onTap: () {
                    if (isCached) {
                      provider.removeCachedSong(song.id);
                    } else {
                      provider.cacheSong(song);
                    }
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final showNavidromeContent = auth.isNavidromeLoggedIn;
    final showLocalContent = auth.isLocalMode;
    final settings = context.watch<SettingsProvider>();

    // 计算需要显示的标签页数量
    int tabCount = 0;
    if (showLocalContent) tabCount++;
    if (showNavidromeContent) tabCount += 3;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('音乐库'),
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(settings.tabBarHeight),
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
            tabs: [
              if (showLocalContent)
                    SizedBox(
                      height: settings.tabBarIndicatorHeight,
                      child: const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open),
                      SizedBox(width: 8),
                      Text('本地音乐'),
                    ],
                        ),
                  ),
                ),
              if (showNavidromeContent) ...[
                    SizedBox(
                      height: settings.tabBarIndicatorHeight,
                      child: const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud),
                      SizedBox(width: 8),
                      Text('在线歌曲'),
                    ],
                  ),
                ),
                    ),
                    SizedBox(
                      height: settings.tabBarIndicatorHeight,
                      child: const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.album),
                      SizedBox(width: 8),
                      Text('在线专辑'),
                    ],
                  ),
                ),
                    ),
                    SizedBox(
                      height: settings.tabBarIndicatorHeight,
                      child: const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text('在线艺术家'),
                    ],
                        ),
                  ),
                ),
              ],
            ],
              ),
            ),
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
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                  onPressed: () => provider.loadSongs(),
                ),
              ],
            ),
          );
        }

        if (provider.songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '没有找到本地音乐',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('去设置音乐文件夹'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
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
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                    '${provider.songs.length} 首歌曲',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isNarrow = screenWidth < 320;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 40,
                            child: isNarrow
                                ? IconButton.filled(
                                    icon: const Icon(Icons.play_circle),
                                    onPressed: () {
                                      Provider.of<LocalLibraryProvider>(context, listen: false).playAll();
                                    },
                                  )
                                : FilledButton.icon(
                                    icon: const Icon(Icons.play_circle),
                    label: const Text('播放全部'),
                    onPressed: () {
                      Provider.of<LocalLibraryProvider>(context, listen: false).playAll();
                    },
                                  ),
                  ),
                  const SizedBox(width: 8),
                          SizedBox(
                            height: 40,
                            child: isNarrow
                                ? IconButton.filledTonal(
                                    icon: const Icon(Icons.shuffle),
                                    onPressed: () {
                                      Provider.of<LocalLibraryProvider>(context, listen: false).playAll(true);
                                    },
                                  )
                                : FilledButton.tonalIcon(
                    icon: const Icon(Icons.shuffle),
                    label: const Text('随机播放'),
                    onPressed: () {
                      Provider.of<LocalLibraryProvider>(context, listen: false).playAll(true);
                    },
                                  ),
                  ),
                ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: provider.songs.length,
                itemBuilder: (context, index) {
                  final song = provider.songs[index];
                  final isPlaying = provider.currentSong?.id == song.id;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: settings.listItemHeight,
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Theme.of(context).colorScheme.primary.withOpacity(1),
                      border: settings.showListDividers
                          ? Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor.withOpacity(0.1),
                                width: 1,
                              ),
                            )
                          : null,
                    ),
                    child: ListTile(
                      leading: Hero(
                        tag: 'cover-${song.id}',
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: song.coverData != null
                          ? Image.memory(
                              song.coverData!,
                                    width: 48,
                                    height: 48,
                              fit: BoxFit.cover,
                            )
                          : Container(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.music_note,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                          ),
                        ),
                            ),
                      title: Text(
                        song.title,
                        style: TextStyle(
                          color: isPlaying
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isPlaying ? FontWeight.bold : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artist ?? '未知歌手',
                        style: TextStyle(
                          color: isPlaying
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                          if (isPlaying)
                            Icon(
                              Icons.equalizer,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showSongOptions(context, song),
                          ),
                        ],
                      ),
                                  onTap: () {
                        _playSong(context, song);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerPage(song: song),
                          ),
                        );
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
    return Consumer2<LibraryProvider, SettingsProvider>(
      builder: (context, provider, settings, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                  onPressed: () => provider.loadAlbums(),
                ),
              ],
            ),
          );
        }

        if (provider.albums.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.album,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '没有找到专辑',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
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
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '${provider.albums.length} 张专辑',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 40,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                      ),
                      icon: Icon(
                        settings.useGridViewForAlbums ? Icons.view_list : Icons.grid_view,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => settings.toggleGridViewForAlbums(!settings.useGridViewForAlbums),
                      tooltip: settings.useGridViewForAlbums ? '切换到列表视图' : '切换到网格视图',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: settings.useGridViewForAlbums
                  ? GridView.builder(
                      padding: EdgeInsets.all(settings.albumGridSpacing),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: settings.albumGridSpacing,
                        mainAxisSpacing: settings.albumGridSpacing,
                      ),
                      itemCount: provider.albums.length,
          itemBuilder: (context, index) {
                        final album = provider.albums[index];
                        return AnimatedContainer(
                          duration: Duration(
                            milliseconds: settings.enableListAnimation ? 300 : 0,
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/album', arguments: album);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Hero(
                                      tag: 'album-${album.id}',
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(12),
                                          ),
                                          image: album.coverArtId != null
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                    Provider.of<NavidromeService>(context, listen: false)
                                                        .getCoverArtUrl(album.coverArtId!),
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          color: album.coverArtId == null
                                              ? Theme.of(context).colorScheme.surfaceVariant
                                              : null,
                                        ),
                                        child: album.coverArtId == null
                                            ? Center(
                                                child: Icon(
                                                  Icons.album,
                                                  size: 48,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          album.name,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          album.artistName,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: provider.albums.length,
                      itemBuilder: (context, index) {
                        final album = provider.albums[index];
                        return AnimatedContainer(
                          duration: Duration(
                            milliseconds: settings.enableListAnimation ? 300 : 0,
                          ),
                          height: settings.listItemHeight,
                          child: ListTile(
                            leading: Hero(
                              tag: 'album-${album.id}',
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: album.coverArtId != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            Provider.of<NavidromeService>(context, listen: false)
                                                .getCoverArtUrl(album.coverArtId!),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: album.coverArtId == null
                                      ? Theme.of(context).colorScheme.surfaceVariant
                                      : null,
                                ),
                                child: album.coverArtId == null
                                    ? Icon(
                                        Icons.album,
                                        color: Theme.of(context).colorScheme.primary,
                                      )
                                    : null,
                              ),
                            ),
                            title: Text(
                              album.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              album.artistName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            onTap: () {
                              Navigator.pushNamed(context, '/album', arguments: album);
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

  Widget _buildSongsTab(BuildContext context) {
    return Consumer2<LibraryProvider, SettingsProvider>(
      builder: (context, provider, settings, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                  onPressed: () => provider.loadSongs(),
                ),
              ],
            ),
          );
        }

        if (provider.songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '没有找到在线歌曲',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
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
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                    '${provider.songs.length} 首歌曲',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isNarrow = screenWidth < 768;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 40,
                            child: isNarrow
                                ? IconButton.filledTonal(
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    onPressed: () {
                                      context.read<PlayerProvider>().playAll(provider.songs);
                                    },
                                  )
                                : FilledButton.tonalIcon(
                                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('播放全部'),
                    onPressed: () {
                                      context.read<PlayerProvider>().playAll(provider.songs);
                    },
                                  ),
                  ),
                  const SizedBox(width: 8),
                          SizedBox(
                            height: 40,
                            child: isNarrow
                                ? IconButton.filledTonal(
                                    icon: const Icon(Icons.shuffle),
                                    onPressed: () {
                                      context.read<PlayerProvider>().playAll(provider.songs, shuffle: true);
                                    },
                                  )
                                : FilledButton.tonalIcon(
                    icon: const Icon(Icons.shuffle),
                    label: const Text('随机播放'),
                    onPressed: () {
                                      context.read<PlayerProvider>().playAll(provider.songs, shuffle: true);
                    },
                                  ),
                  ),
                ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: provider.songs.length,
                itemBuilder: (context, index) {
                  final song = provider.songs[index];
                  final isPlaying = context.watch<PlayerProvider>().currentSong?.id == song.id;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: settings.listItemHeight,
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Theme.of(context).colorScheme.surface,
                      border: settings.showListDividers
                          ? Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor.withOpacity(0.1),
                                width: 1,
                              ),
                            )
                          : null,
                    ),
                    child: ListTile(
                      leading: Hero(
                        tag: 'cover-${song.id}',
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: song.coverArtId != null
                          ? Image.network(
                              Provider.of<NavidromeService>(context, listen: false)
                                  .getCoverArtUrl(song.coverArtId!),
                                    width: 48,
                                    height: 48,
                              fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      child: Icon(
                                        Icons.music_note,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                            )
                          : Container(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.music_note,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                          ),
                        ),
                            ),
                      title: Text(
                        song.title,
                        style: TextStyle(
                          color: isPlaying
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isPlaying ? FontWeight.bold : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artist ?? '未知歌手',
                        style: TextStyle(
                          color: isPlaying
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPlaying)
                            Icon(
                              Icons.equalizer,
                              color: Theme.of(context).colorScheme.primary,
                                    ),
                                    IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showSongOptions(context, song),
                          ),
                        ],
                      ),
                                      onTap: () {
                        _playSong(context, song);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerPage(song: song),
                                          ),
                                        );
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
                              subtitle: Text(song.artist),
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
                          const SnackBar(
                            content: Text('已添加到歌单'),
                            duration: Duration(seconds: 1),
                          ),
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

  Widget _buildSongListTile(BuildContext context, Song song) {
    return ListTile(
      leading: Image.network(
        song.coverArtUrl ?? '',
        width: 40,
        height: 40,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.music_note),
      ),
      title: Text(song.title),
      subtitle: Text(song.artist),
      onTap: () {
        context.read<PlayerProvider>().playSong(song);
      },
    );
  }
} 