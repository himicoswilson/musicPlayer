import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../services/navidrome_service.dart';
import '../pages/player_page.dart';
import '../providers/settings_provider.dart';

// 添加自定义路由
class BottomToTopPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  
  BottomToTopPageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final navidromeService = Provider.of<NavidromeService>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context);
    
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final currentSong = provider.currentSong;
        if (currentSong == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              BottomToTopPageRoute(
                child: PlayerPage(
                  song: currentSong,
                  streamUrl: provider.getStreamUrl(currentSong),
                ),
              ),
            );
          },
          child: Container(
            height: settings.miniPlayerHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              children: [
                // 进度条
                if (settings.showMiniPlayerProgress)
                  LinearProgressIndicator(
                    value: provider.duration.inSeconds > 0
                        ? provider.position.inSeconds / provider.duration.inSeconds
                        : 0,
                    minHeight: 1,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                // 播放器内容
                Expanded(
                  child: Row(
                    children: [
                      // 封面
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(settings.miniPlayerCoverRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: currentSong.coverArtId != null
                            ? Image.network(
                                navidromeService.getCoverArtUrl(currentSong.coverArtId!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.album, size: 24),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.album, size: 24),
                              ),
                      ),
                      // 歌曲信息
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentSong.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentSong.artistName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 播���控制
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              provider.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Theme.of(context).primaryColor,
                            ),
                            iconSize: 32,
                            onPressed: () => provider.togglePlay(),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.skip_next_rounded,
                              color: Theme.of(context).primaryColor,
                            ),
                            iconSize: 32,
                            onPressed: () => provider.playNext(),
                          ),
                        ],
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
} 