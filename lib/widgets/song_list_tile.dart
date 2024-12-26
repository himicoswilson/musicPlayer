import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../services/navidrome_service.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final bool showAddToPlaylist;

  const SongListTile({
    super.key,
    required this.song,
    this.onTap,
    this.showAddToPlaylist = true,
  });

  @override
  Widget build(BuildContext context) {
    final navidromeService = NavidromeService();
    
    return ListTile(
      title: Text(song.title),
      subtitle: Text(song.artist),
      leading: song.coverArtId != null
          ? Image.network(
              navidromeService.getCoverArtUrl(song.coverArtId),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.music_note),
                );
              },
            )
          : const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.music_note),
            ),
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
          if (showAddToPlaylist)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showMoreOptions(context),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('添加到歌单'),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylistDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现分享功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.album),
              title: const Text('查看专辑'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 跳转到专辑详情页
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('查看艺术家'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 跳转到艺术家详情页
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context) {
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
                      _showCreatePlaylistDialog(context);
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
                    _showCreatePlaylistDialog(context);
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

  void _showCreatePlaylistDialog(BuildContext context) {
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