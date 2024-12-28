import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/custom_navigation_bar.dart';
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
          // 底部播放器和导航栏
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiniPlayer(),
                // 自定义分割线
                Container(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                // 使用自定义导航栏
                CustomNavigationBar(
                  currentIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
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