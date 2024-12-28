import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/local_library_provider.dart';
import '../services/local_music_service.dart';
import '../widgets/mini_player.dart';
import '../pages/home_page.dart';
import '../providers/cache_provider.dart';
import '../pages/cache_management_page.dart';
import '../pages/audio_quality_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Consumer2<SettingsProvider, AuthProvider>(
        builder: (context, settings, auth, child) {
          return ListView(
            children: [
              _buildSettingsSection(
                context,
                title: '音乐源',
                children: [
                  ListTile(
                    title: const Text('音乐源设置'),
                    leading: const Icon(Icons.music_note),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MusicSourceSettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              _buildSettingsSection(
                context,
                title: '外观',
                children: [
                  ListTile(
                    title: const Text('主题设置'),
                    leading: const Icon(Icons.palette),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ThemeSettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              _buildSettingsSection(
                context,
                title: '存储',
                children: [
                  ListTile(
                    leading: const Icon(Icons.storage),
                    title: const Text('缓存管理'),
                    subtitle: Consumer<CacheProvider>(
                      builder: (context, provider, child) {
                        return FutureBuilder<int>(
                          future: provider.getMaxCacheSize(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final maxSpace = snapshot.data!;
                              final usedSpace = provider.getCacheSize();
                              return Text(
                                '已使用 ${_formatSize(usedSpace)} / ${_formatSize(maxSpace)}',
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            return const Text('计算中...');
                          },
                        );
                      },
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CacheManagementPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              _buildSettingsSection(
                context,
                title: '音质',
                children: [
                  ListTile(
                    leading: const Icon(Icons.high_quality),
                    title: const Text('音质设置'),
                    subtitle: Consumer<SettingsProvider>(
                      builder: (context, settings, child) {
                        return Text(
                          settings.autoQuality
                              ? '自动调整音质'
                              : '固定音质：${SettingsProvider.getBitRateDescription(settings.maxBitRate)}',
                        );
                      },
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AudioQualitySettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('主题设置'),
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(58),
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.palette),
                        SizedBox(width: 8),
                        Text('基础'), 
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle),
                        SizedBox(width: 8),
                        Text('播放器'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list),
                        SizedBox(width: 8),
                        Text('列表'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.library_music),
                        SizedBox(width: 8),
                        Text('音乐库'),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _BasicThemeTab(),
            _PlayerSettingsTab(),
            _ListStyleSettingsTab(),
            _LibrarySettingsTab(),
          ],
        ),
      ),
    );
  }
}

class _BasicThemeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '颜色主题',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('主题色'),
                      subtitle: const Text('点击选择应用的主要颜色'),
                      trailing: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: settings.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: settings.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      onTap: () async {
                        final color = await showColorPicker(
                          context: context,
                          initialColor: settings.primaryColor,
                        );
                        if (color != null) {
                          settings.updatePrimaryColor(color);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text('深色模式'),
                      trailing: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (Set<ThemeMode> newSelection) {
                          settings.updateThemeMode(newSelection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '导航栏设置',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('显示导航栏标签'),
                      subtitle: const Text('在底部导航栏显示图标文字'),
                      value: settings.showNavigationLabels,
                      onChanged: settings.toggleNavigationLabels,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlayerSettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '播放器设置',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('封面大小'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: settings.coverArtSizeRatio,
                          min: 0.5,
                          max: 1.0,
                          divisions: 10,
                          label: '${(settings.coverArtSizeRatio * 100).toInt()}%',
                          onChanged: settings.updateCoverArtSizeRatio,
                        ),
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('封面阴影'),
                      value: settings.showCoverArtShadow,
                      onChanged: settings.toggleCoverArtShadow,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '迷你播放器设置',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('播放器高度'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: settings.miniPlayerHeight,
                          min: 48,
                          max: 96,
                          divisions: 8,
                          label: '${settings.miniPlayerHeight.toInt()}',
                          onChanged: settings.updateMiniPlayerHeight,
                        ),
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('显示进度条'),
                      value: settings.showMiniPlayerProgress,
                      onChanged: settings.toggleMiniPlayerProgress,
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('封面圆角'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: settings.miniPlayerCoverRadius,
                          min: 0,
                          max: 24,
                          divisions: 12,
                          label: '${settings.miniPlayerCoverRadius.toInt()}',
                          onChanged: settings.updateMiniPlayerCoverRadius,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ListStyleSettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '列表样式',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('显示分割线'),
                      value: settings.showListDividers,
                      onChanged: settings.toggleListDividers,
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('列表项高度'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: settings.listItemHeight,
                          min: 48,
                          max: 96,
                          divisions: 8,
                          label: '${settings.listItemHeight.toInt()}',
                          onChanged: settings.updateListItemHeight,
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('列表项圆角'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: settings.listItemBorderRadius,
                          min: 0,
                          max: 16,
                          divisions: 8,
                          label: '${settings.listItemBorderRadius.toInt()}',
                          onChanged: settings.updateListItemBorderRadius,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hover效果',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Hover圆角'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: settings.hoverBorderRadius,
                          min: 0,
                          max: 16,
                          divisions: 8,
                          label: '${settings.hoverBorderRadius.toInt()}',
                          onChanged: settings.updateHoverBorderRadius,
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Hover不透明度'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: settings.hoverOpacity,
                          min: 0.05,
                          max: 0.3,
                          divisions: 5,
                          label: '${(settings.hoverOpacity * 100).toInt()}%',
                          onChanged: settings.updateHoverOpacity,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LibrarySettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '专辑视图设置',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('使用网格视图'),
                      value: settings.useGridViewForAlbums,
                      onChanged: settings.toggleGridViewForAlbums,
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('封面大小'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: settings.albumGridCoverSize,
                          min: 120,
                          max: 200,
                          divisions: 4,
                          label: '${settings.albumGridCoverSize.toInt()}',
                          onChanged: settings.updateAlbumGridCoverSize,
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('网格间距'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: settings.albumGridSpacing,
                          min: 8,
                          max: 24,
                          divisions: 4,
                          label: '${settings.albumGridSpacing.toInt()}',
                          onChanged: settings.updateAlbumGridSpacing,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '标签页设置',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('标签栏高度'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: settings.tabBarHeight,
                          min: 40,
                          max: 56,
                          divisions: 4,
                          label: '${settings.tabBarHeight.toInt()}',
                          onChanged: settings.updateTabBarHeight,
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('指示器高度'),
                      trailing: SizedBox(
                        width: 200,
                        child: Slider(
                          value: settings.tabBarIndicatorHeight,
                          min: 24,
                          max: 40,
                          divisions: 4,
                          label: '${settings.tabBarIndicatorHeight.toInt()}',
                          onChanged: settings.updateTabBarIndicatorHeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        );
      },
    );
  }
}

class MusicSourceSettingsPage extends StatefulWidget {
  const MusicSourceSettingsPage({Key? key}) : super(key: key);

  @override
  State<MusicSourceSettingsPage> createState() => _MusicSourceSettingsPageState();
}

class _MusicSourceSettingsPageState extends State<MusicSourceSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  
  void _showNavidromeConfigDialog(BuildContext context) {
    final serverController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    // 预填上次保存的配置
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.getNavidromeConfig().then((config) {
      if (config['serverUrl'] != null) {
        serverController.text = config['serverUrl']!;
      }
      if (config['username'] != null) {
        usernameController.text = config['username']!;
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('配置 Navidrome'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: serverController,
                decoration: const InputDecoration(
                  labelText: '服务器地址',
                  hintText: 'http://localhost:4533',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入服务器地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  hintText: 'admin',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '���输入用户名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  hintText: 'password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              return TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await auth.configureNavidrome(
                            serverController.text,
                            usernameController.text,
                            passwordController.text,
                          );
                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('配置成功')),
                            );
                          }
                        }
                      },
                child: auth.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('确定'),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localMusicService = LocalMusicService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐源设置'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('使��本地音乐'),
                subtitle: Text(auth.isLocalMode ? '已启用本地音乐库' : '未启用本地音乐库'),
                value: auth.isLocalMode,
                onChanged: (value) async {
                  await auth.toggleLocalMode();
                },
              ),
              if (auth.isLocalMode) ...[
                const Divider(),
                ListTile(
                  title: const Text('选择本地音乐文件夹'),
                  subtitle: FutureBuilder<String?>(
                    future: localMusicService.getLocalMusicPath(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('加载中...');
                      }
                      return Text(snapshot.data ?? '未设置');
                    },
                  ),
                  trailing: const Icon(Icons.folder_open),
                  onTap: () async {
                    try {
                      final selectedPath = await localMusicService.pickMusicDirectory();
                      if (selectedPath != null && context.mounted) {
                        await Provider.of<LocalLibraryProvider>(context, listen: false).loadSongs();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已选择文件夹: $selectedPath')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  title: const Text('扫描音乐文件'),
                  subtitle: const Text('重新扫描本地音乐文件'),
                  trailing: const Icon(Icons.refresh),
                  onTap: () async {
                    final musicPath = await localMusicService.getLocalMusicPath() 
                        ?? await localMusicService.getDefaultMusicDirectory();
                    try {
                      await localMusicService.scanMusicFiles(musicPath);
                      if (context.mounted) {
                        await Provider.of<LocalLibraryProvider>(context, listen: false).loadSongs();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('扫描完成')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('扫描失败: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
              const Divider(),
              ListTile(
                title: const Text('Navidrome 设置'),
                subtitle: Text(auth.hasNavidromeConfig ? '已配置 Navidrome 服务' : '未配置 Navidrome 服务'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (auth.hasNavidromeConfig)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () async {
                          final success = await auth.testNavidromeConnection();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? '连接正常' : '连接失败，请检查网络或重新配置'),
                                backgroundColor: success ? null : Colors.red,
                              ),
                            );
                          }
                        },
                        tooltip: '测试连接',
                      ),
                    IconButton(
                      icon: Icon(auth.hasNavidromeConfig ? Icons.edit : Icons.add),
                      onPressed: () => _showNavidromeConfigDialog(context),
                      tooltip: auth.hasNavidromeConfig ? '修改配置' : '添加配置',
                    ),
                    if (auth.hasNavidromeConfig)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('删除配置'),
                              content: const Text('确定要删除 Navidrome 配置吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await auth.logout();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已删除 Navidrome 配置')),
                            );
                          }
                        },
                        tooltip: '删除配置',
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<Color?> showColorPicker({
  required BuildContext context,
  required Color initialColor,
}) async {
  return showDialog<Color>(
    context: context,
    builder: (BuildContext context) {
      Color selectedColor = initialColor;
      return AlertDialog(
        title: const Text('选择颜色'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: (Color color) {
              selectedColor = color;
            },
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: <Widget>[
                    TextButton(
                      child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop();
            },
                    ),
                    TextButton(
            child: const Text('确定'),
                      onPressed: () {
              Navigator.of(context).pop(selectedColor);
            },
          ),
        ],
      );
    },
  );
} 