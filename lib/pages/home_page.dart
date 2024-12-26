import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/mini_player.dart';
import 'library_page.dart';
import 'playlist_page.dart';
import 'settings_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const LibraryPage(),
    const PlaylistPage(),
    const SearchPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 主内容区域
          _pages[_currentIndex],
          // 底部播放器
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiniPlayer(),
                // 底部导航栏
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    return NavigationBar(
                      height: settings.navigationBarHeight,
                      labelBehavior: settings.showNavigationLabels
                          ? NavigationDestinationLabelBehavior.alwaysShow
                          : NavigationDestinationLabelBehavior.onlyShowSelected,
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.library_music_outlined),
                          selectedIcon: Icon(Icons.library_music),
                          label: '音乐库',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.playlist_play_outlined),
                          selectedIcon: Icon(Icons.playlist_play),
                          label: '歌单',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.search_outlined),
                          selectedIcon: Icon(Icons.search),
                          label: '搜索',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: '设置',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 