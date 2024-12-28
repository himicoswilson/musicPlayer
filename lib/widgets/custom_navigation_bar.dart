import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const CustomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (settings.navigationBarHeight <= 0) {
          return const SizedBox.shrink();
        }

        final items = [
          (Icons.library_music_outlined, Icons.library_music, '音乐库'),
          (Icons.playlist_play_outlined, Icons.playlist_play, '歌单'),
          (Icons.search_outlined, Icons.search, '搜索'),
          (Icons.settings_outlined, Icons.settings, '设置'),
        ];

        return Container(
          height: settings.navigationBarHeight,
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final (unselectedIcon, selectedIcon, label) = items[index];
              final isSelected = currentIndex == index;
              
              return Material(
                color: Colors.transparent,
                child: InkResponse(
                  onTap: () => onDestinationSelected(index),
                  highlightShape: BoxShape.circle,
                  containedInkWell: true,
                  radius: 24,
                  child: SizedBox(
                    height: settings.navigationBarHeight,
                    width: 64,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? selectedIcon : unselectedIcon,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        if (settings.showNavigationLabels) ...[
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            child: Text(label),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
} 