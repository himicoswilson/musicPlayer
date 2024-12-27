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

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
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
              // 缓存管理
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('缓存管理'),
                subtitle: Consumer<CacheProvider>(
                  builder: (context, provider, child) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FutureBuilder<int>(
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
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '缓存位置: ${provider.cachePath}',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                trailing: SizedBox(
                  width: 24,
                  child: Icon(Icons.chevron_right),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CacheManagementPage(),
                    ),
                  );
                },
              ),
              const Divider(),
            ],
          );
        },
      ),
    );
  }
}

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('主题设置'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '基础'),
              Tab(text: '播放'),
              Tab(text: '列表'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BasicThemeTab(),
            _PlayerSettingsTab(),
            _ListStyleSettingsTab(),
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
          children: [
            ListTile(
              title: const Text('主题色'),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: settings.primaryColor,
                  shape: BoxShape.circle,
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
            const Divider(),
            SwitchListTile(
              title: const Text('显示导航栏标签'),
              value: settings.showNavigationLabels,
              onChanged: settings.toggleNavigationLabels,
            ),
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

class _PlayerSettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
    return ListView(
      children: [
            // 封面设置
            ListTile(
              title: const Text('封面大小比例'),
              subtitle: Slider(
                value: settings.coverArtSizeRatio,
                min: 0.5,
                max: 0.9,
                divisions: 40,
                label: settings.coverArtSizeRatio.toStringAsFixed(2),
                onChanged: settings.updateCoverArtSizeRatio,
              ),
            ),
            SwitchListTile(
              title: const Text('显示封面阴影'),
                value: settings.showCoverArtShadow,
                onChanged: settings.toggleCoverArtShadow,
              ),
            const Divider(),
            
            // 歌词设置
            SwitchListTile(
              title: const Text('默认显示歌词'),
              subtitle: const Text('打开播放页面时是否默认显示歌词'),
              value: settings.defaultShowLyrics,
              onChanged: (value) {
                settings.updateLyricSettings(showLyrics: value);
              },
            ),
            ListTile(
              title: const Text('普通歌词颜色'),
              trailing: Container(
                width: 24,
                height: 24,
                        decoration: BoxDecoration(
                  color: settings.lyricNormalColor,
                                shape: BoxShape.circle,
                ),
              ),
              onTap: () async {
                final color = await showColorPicker(
                  context: context,
                  initialColor: settings.lyricNormalColor,
                );
                if (color != null) {
                  settings.updateLyricSettings(normalColor: color);
                }
              },
            ),
            ListTile(
              title: const Text('高亮歌词颜色'),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: settings.lyricActiveColor,
                  shape: BoxShape.circle,
                ),
              ),
              onTap: () async {
                final color = await showColorPicker(
                  context: context,
                  initialColor: settings.lyricActiveColor,
                );
                if (color != null) {
                  settings.updateLyricSettings(activeColor: color);
                }
              },
            ),
            ListTile(
              title: const Text('普通歌词字号'),
              subtitle: Slider(
                value: settings.lyricNormalSize,
                min: 12,
                max: 24,
                divisions: 12,
                label: settings.lyricNormalSize.toStringAsFixed(1),
                onChanged: (value) {
                  settings.updateLyricSettings(normalSize: value);
                },
              ),
            ),
            ListTile(
              title: const Text('高亮歌词字号'),
              subtitle: Slider(
                value: settings.lyricActiveSize,
                min: 14,
                max: 28,
                divisions: 14,
                label: settings.lyricActiveSize.toStringAsFixed(1),
                onChanged: (value) {
                  settings.updateLyricSettings(activeSize: value);
                },
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
        children: [
            SwitchListTile(
              title: const Text('显示分割线'),
              value: settings.showListDividers,
              onChanged: settings.toggleListDividers,
            ),
            ListTile(
              title: const Text('列表项高度'),
      subtitle: Slider(
                value: settings.listItemHeight,
                min: 48,
                max: 80,
                divisions: 16,
                label: settings.listItemHeight.toStringAsFixed(1),
                onChanged: settings.updateListItemHeight,
              ),
            ),
          ],
        );
      },
    );
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
} 