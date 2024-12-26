import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/local_library_provider.dart';
import '../services/local_music_service.dart';
import '../widgets/mini_player.dart';
import '../pages/home_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置')
      ),
      body: Consumer2<SettingsProvider, AuthProvider>(
        builder: (context, settings, auth, child) {
          return ListView(
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
              const Divider(),
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
              const Divider(),
              // 其他设置项...
            ],
          );
        },
      ),
    );
  }
}

class MusicSourceSettingsPage extends StatefulWidget {
  const MusicSourceSettingsPage({super.key});

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
                    return '请输入用户名';
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
                title: const Text('使用本地音乐'),
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

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                  maintainState: true,
                ),
              );
            },
            tooltip: '预览',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('恢复默认设置'),
                  content: const Text('确定要恢复所有设置为默认值吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Provider.of<SettingsProvider>(context, listen: false)
                            .resetAllSettings();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已恢复所有设置为默认值'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
            tooltip: '恢复所有设置',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.tab,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: const [
            Tab(text: '基础设置'),
            Tab(text: '迷你播放器'),
            Tab(text: '播放页面'),
            Tab(text: '列表样式'),
          ],
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicSettings(context, settings),
                    _buildMiniPlayerSettings(context, settings),
                    _buildPlayerSettings(context, settings),
                    _buildListSettings(context, settings),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBasicSettings(BuildContext context, SettingsProvider settings) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 16),
            children: [
              _ColorPicker(
                label: '主题色',
                value: settings.primaryColor,
                onChanged: settings.updatePrimaryColor,
              ),
              _SliderSetting(
                label: '导航栏高度',
                value: settings.navigationBarHeight,
                min: 60,
                max: 100,
                defaultValue: 80,
                onChanged: settings.updateNavigationBarHeight,
              ),
              _SwitchSetting(
                label: '显示导航栏标签',
                value: settings.showNavigationLabels,
                onChanged: settings.toggleNavigationLabels,
              ),
            ],
          ),
        ),
        Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              NavigationBar(
                height: settings.navigationBarHeight,
                labelBehavior: settings.showNavigationLabels
                    ? NavigationDestinationLabelBehavior.alwaysShow
                    : NavigationDestinationLabelBehavior.onlyShowSelected,
                selectedIndex: 0,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.music_note_outlined),
                    selectedIcon: Icon(Icons.music_note),
                    label: '听听',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search_outlined),
                    selectedIcon: Icon(Icons.search),
                    label: '浏览',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music),
                    label: '音乐库',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPlayerSettings(BuildContext context, SettingsProvider settings) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        Expanded(
          child: Column(
            children: [
              _SliderSetting(
                label: '播放器高度',
                value: settings.miniPlayerHeight,
                min: 48,
                max: 80,
                defaultValue: 64,
                onChanged: settings.updateMiniPlayerHeight,
              ),
              _SliderSetting(
                label: '封面圆角',
                value: settings.miniPlayerCoverRadius,
                min: 0,
                max: 24,
                defaultValue: 6,
                onChanged: settings.updateMiniPlayerCoverRadius,
              ),
              _SwitchSetting(
                label: '显示进度条',
                value: settings.showMiniPlayerProgress,
                onChanged: settings.toggleMiniPlayerProgress,
              ),
              const SizedBox(height: 32),
              // 预览区域
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (settings.showMiniPlayerProgress)
                      LinearProgressIndicator(
                        value: 0.7,
                        minHeight: 1,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    Container(
                      height: settings.miniPlayerHeight,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(settings.miniPlayerCoverRadius),
                              color: Colors.grey[200],
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.album, size: 24),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '预览歌曲',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '预览艺术家',
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
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.play_arrow_rounded,
                                  color: Theme.of(context).primaryColor,
                                ),
                                iconSize: 32,
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.skip_next_rounded,
                                  color: Theme.of(context).primaryColor,
                                ),
                                iconSize: 32,
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerSettings(BuildContext context, SettingsProvider settings) {
    final size = MediaQuery.of(context).size;
    final previewWidth = size.width * 0.8;
    final previewHeight = previewWidth * 1.6;
    final coverSize = previewWidth * settings.coverArtSizeRatio;

    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        Expanded(
          child: Column(
            children: [
              _SliderSetting(
                label: '封面大小比例',
                value: settings.coverArtSizeRatio,
                min: 0.5,
                max: 0.9,
                defaultValue: 0.75,
                onChanged: settings.updateCoverArtSizeRatio,
              ),
              _SwitchSetting(
                label: '显示封面阴影',
                value: settings.showCoverArtShadow,
                onChanged: settings.toggleCoverArtShadow,
              ),
              const SizedBox(height: 32),
              // 预览区域
              Container(
                width: previewWidth,
                height: previewHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 顶部栏
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down),
                              onPressed: null,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.playlist_play),
                              onPressed: null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 封面
                      Container(
                        width: coverSize,
                        height: coverSize,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: settings.showCoverArtShadow
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ]
                              : null,
                        ),
                        child: const Icon(Icons.album, size: 64),
                      ),
                      const SizedBox(height: 32),
                      // 歌曲信息
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            Text(
                              '预览歌曲',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '预览艺术家',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // 进度条
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                                activeTrackColor: Theme.of(context).primaryColor,
                                inactiveTrackColor: Colors.grey[300],
                                thumbColor: Theme.of(context).primaryColor,
                                overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: 0.7,
                                onChanged: null,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '2:10',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '3:00',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 播放控制
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Icon(Icons.repeat, color: Theme.of(context).primaryColor),
                            Icon(Icons.skip_previous_rounded, size: 40),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).primaryColor,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Icon(Icons.skip_next_rounded, size: 40),
                            Icon(Icons.playlist_play, color: Theme.of(context).primaryColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListSettings(BuildContext context, SettingsProvider settings) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 16),
            children: [
              _SliderSetting(
                label: '列表项高度',
                value: settings.listItemHeight,
                min: 48,
                max: 80,
                defaultValue: 64,
                onChanged: settings.updateListItemHeight,
              ),
              _SwitchSetting(
                label: '显示分割线',
                value: settings.showListDividers,
                onChanged: settings.toggleListDividers,
              ),
            ],
          ),
        ),
        Container(
          height: 300,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            itemCount: 5,
            separatorBuilder: (context, index) => settings.showListDividers
                ? const Divider(height: 1)
                : const SizedBox.shrink(),
            itemBuilder: (context, index) {
              return Container(
                height: settings.listItemHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.music_note),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '预览歌曲 ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '预览艺术家',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

enum PreviewType {
  listen,
  browse,
  library,
}

class _PreviewContent extends StatelessWidget {
  final SettingsProvider settings;
  final PreviewType type;

  const _PreviewContent({
    required this.settings,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case PreviewType.listen:
        return _buildListenPreview(context);
      case PreviewType.browse:
        return _buildBrowsePreview(context);
      case PreviewType.library:
        return _buildLibraryPreview(context);
    }
  }

  Widget _buildListenPreview(BuildContext context) {
    return ListView.separated(
      itemCount: 10,
      separatorBuilder: (context, index) => settings.showListDividers
          ? const Divider(height: 1)
          : const SizedBox.shrink(),
      itemBuilder: (context, index) {
        return Container(
          height: settings.listItemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.music_note),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '预览歌曲 ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '预览艺术家',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrowsePreview(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: Text('浏览'),
          floating: true,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.primaries[index % Colors.primaries.length][100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              index.isEven ? Icons.album : Icons.person,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              index.isEven ? '专辑' : '艺术家',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLibraryPreview(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '歌曲'),
              Tab(text: '专辑'),
              Tab(text: '艺术家'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildListenPreview(context),
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.album, size: 48),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '预览专辑 ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '预览艺术家',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person),
                      ),
                      title: Text('预览艺术家 ${index + 1}'),
                      subtitle: const Text('10 张专辑'),
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

class _ColorPicker extends StatelessWidget {
  final String label;
  final Color value;
  final ValueChanged<Color> onChanged;

  const _ColorPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(label),
              content: SingleChildScrollView(
                child: MaterialPicker(
                  pickerColor: value,
                  onColorChanged: (color) {
                    onChanged(color);
                    Navigator.pop(context);
                  },
                  enableLabel: true,
                ),
              ),
            ),
          );
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: value,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: value.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderSetting extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double defaultValue;
  final ValueChanged<double> onChanged;

  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.onChanged,
  });

  @override
  State<_SliderSetting> createState() => _SliderSettingState();
}

class _SliderSettingState extends State<_SliderSetting> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SliderSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(widget.label)),
          IconButton(
            icon: const Icon(Icons.restore, size: 20),
            onPressed: () => widget.onChanged(widget.defaultValue),
            tooltip: '恢复默认',
          ),
        ],
      ),
      subtitle: Slider(
        value: widget.value,
        min: widget.min,
        max: widget.max,
        onChanged: widget.onChanged,
      ),
      trailing: SizedBox(
        width: 60,
        child: TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            hintText: widget.value.toStringAsFixed(1),
            hintStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          onSubmitted: (text) {
            if (text.isEmpty) {
              widget.onChanged(widget.defaultValue);
              return;
            }
            final newValue = double.tryParse(text);
            if (newValue != null && newValue >= widget.min && newValue <= widget.max) {
              widget.onChanged(newValue);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('请输入 ${widget.min.toStringAsFixed(1)} 到 ${widget.max.toStringAsFixed(1)} 之间的数值'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            _controller.clear();
          },
        ),
      ),
    );
  }
}

class _SwitchSetting extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSetting({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
} 