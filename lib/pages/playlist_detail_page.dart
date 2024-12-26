import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../services/navidrome_service.dart';
import '../widgets/song_list_tile.dart';

class PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;
  final bool isStarredPlaylist;

  const PlaylistDetailPage({
    super.key,
    required this.playlist,
    this.isStarredPlaylist = false,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  late Future<Playlist?> _playlistFuture;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  void _loadPlaylist() {
    if (widget.isStarredPlaylist) {
      _playlistFuture = Future.value(widget.playlist);
    } else {
      _playlistFuture = NavidromeService().getPlaylist(widget.playlist.id);
    }
  }

  void _showPlaylistOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑歌单'),
              onTap: () {
                Navigator.pop(context);
                _showEditPlaylistDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除歌单', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlaylistDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.playlist.name);
    final commentController = TextEditingController(text: widget.playlist.comment ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑歌单'),
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

              final success = await context.read<PlaylistProvider>().updatePlaylist(
                widget.playlist.id,
                name: nameController.text,
                comment: commentController.text.isEmpty ? null : commentController.text,
              );

              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('更新成功')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('更新失败')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除歌单'),
        content: Text('确定要删除歌单"${widget.playlist.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context
                  .read<PlaylistProvider>()
                  .deletePlaylist(widget.playlist.id);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  Navigator.pop(context); // 返回歌单列表页
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除成功')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除失败')),
                  );
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        actions: [
          if (!widget.isStarredPlaylist) // 只有非收藏歌单才显示更多选项
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showPlaylistOptions(context),
            ),
        ],
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, provider, child) {
          return FutureBuilder<Playlist?>(
            future: _playlistFuture,
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
                            _loadPlaylist();
                          });
                        },
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
              }

              final playlist = snapshot.data;
              if (playlist == null) {
                return const Center(child: Text('歌单不存在'));
              }

              final songs = widget.isStarredPlaylist 
                  ? provider.starredSongs 
                  : playlist.songs;

              if (songs.isEmpty) {
                return const Center(
                  child: Text('暂无歌曲'),
                );
              }

              return ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return SongListTile(
                    song: song,
                    onTap: () {
                      final playerProvider = context.read<PlayerProvider>();
                      playerProvider.playAll(songs, shuffle: false);
                    },
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