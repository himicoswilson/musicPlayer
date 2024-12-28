import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // 主题色
  Color _primaryColor = Colors.deepPurple;
  Color get primaryColor => _primaryColor;

  // 导航栏样式
  double _navigationBarHeight = 80;
  double get navigationBarHeight => _navigationBarHeight;

  bool _showNavigationLabels = true;
  bool get showNavigationLabels => _showNavigationLabels;

  // 迷你播放器样式
  double _miniPlayerHeight = 64;
  double get miniPlayerHeight => _miniPlayerHeight;

  bool _showMiniPlayerProgress = true;
  bool get showMiniPlayerProgress => _showMiniPlayerProgress;

  double _miniPlayerCoverRadius = 6;
  double get miniPlayerCoverRadius => _miniPlayerCoverRadius;

  // 播放页面样式
  double _coverArtSizeRatio = 0.75;
  double get coverArtSizeRatio => _coverArtSizeRatio;

  bool _showCoverArtShadow = true;
  bool get showCoverArtShadow => _showCoverArtShadow;

  // 列表样式
  bool _showListDividers = false;
  bool get showListDividers => _showListDividers;

  double _listItemHeight = 64;
  double get listItemHeight => _listItemHeight;

  // 列表项圆角
  double _listItemBorderRadius = 8.0;
  double get listItemBorderRadius => _listItemBorderRadius;

  // Hover效果
  double _hoverBorderRadius = 8.0;
  double get hoverBorderRadius => _hoverBorderRadius;

  double _hoverOpacity = 0.1;
  double get hoverOpacity => _hoverOpacity;

  // 歌词设置
  static const String _kLyricNormalColorKey = 'lyric_normal_color';
  static const String _kLyricActiveColorKey = 'lyric_active_color';
  static const String _kLyricNormalSizeKey = 'lyric_normal_size';
  static const String _kLyricActiveSizeKey = 'lyric_active_size';
  static const String _kDefaultShowLyricsKey = 'default_show_lyrics';

  // 默认值
  static const Color _defaultLyricNormalColor = Colors.grey;
  static const Color _defaultLyricActiveColor = Colors.deepPurple;
  static const double _defaultLyricNormalSize = 16.0;
  static const double _defaultLyricActiveSize = 18.0;
  static const bool _defaultShowLyrics = true;

  Color _lyricNormalColor = _defaultLyricNormalColor;
  Color _lyricActiveColor = _defaultLyricActiveColor;
  double _lyricNormalSize = _defaultLyricNormalSize;
  double _lyricActiveSize = _defaultLyricActiveSize;
  bool _showLyrics = _defaultShowLyrics;

  Color get lyricNormalColor => _lyricNormalColor;
  Color get lyricActiveColor => _lyricActiveColor;
  double get lyricNormalSize => _lyricNormalSize;
  double get lyricActiveSize => _lyricActiveSize;
  bool get defaultShowLyrics => _showLyrics;

  int _maxBitRate = 0; // 0 表示不限制
  bool _autoQuality = true; // 是否自动根据网络调整音质
  
  int get maxBitRate => _maxBitRate;
  bool get autoQuality => _autoQuality;
  
  // 预设的音质选项（kbps）
  static const List<int> bitRateOptions = [0, 96, 128, 192, 320];
  
  // 音质描述
  static String getBitRateDescription(int bitRate) {
    switch (bitRate) {
      case 0:
        return '原始音质';
      case 96:
        return '低音质 (96kbps)';
      case 128:
        return '标准音质 (128kbps)';
      case 192:
        return '高音质 (192kbps)';
      case 320:
        return '超高音质 (320kbps)';
      default:
        return '${bitRate}kbps';
    }
  }

  // 主题设置
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // 音乐库设置
  bool _useGridViewForAlbums = true;
  bool get useGridViewForAlbums => _useGridViewForAlbums;

  double _albumGridCoverSize = 160;
  double get albumGridCoverSize => _albumGridCoverSize;

  double _albumGridSpacing = 16;
  double get albumGridSpacing => _albumGridSpacing;

  bool _enableListAnimation = true;
  bool get enableListAnimation => _enableListAnimation;

  double _tabBarHeight = 48;
  double get tabBarHeight => _tabBarHeight;

  double _tabBarIndicatorHeight = 32;
  double get tabBarIndicatorHeight => _tabBarIndicatorHeight;

  // 加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 主题色
    final colorValue = prefs.getInt('primaryColor') ?? Colors.deepPurple.value;
    _primaryColor = Color(colorValue);

    // 导航栏样式
    _navigationBarHeight = prefs.getDouble('navigationBarHeight') ?? 80;
    _showNavigationLabels = prefs.getBool('showNavigationLabels') ?? true;

    // 迷你播放器样式
    _miniPlayerHeight = prefs.getDouble('miniPlayerHeight') ?? 64;
    _showMiniPlayerProgress = prefs.getBool('showMiniPlayerProgress') ?? true;
    _miniPlayerCoverRadius = prefs.getDouble('miniPlayerCoverRadius') ?? 6;

    // 播放页面样式
    _coverArtSizeRatio = prefs.getDouble('coverArtSizeRatio') ?? 0.75;
    _showCoverArtShadow = prefs.getBool('showCoverArtShadow') ?? true;

    // 列表样式
    _showListDividers = prefs.getBool('showListDividers') ?? false;
    _listItemHeight = prefs.getDouble('listItemHeight') ?? 64;

    // 加载歌词设置
    _lyricNormalColor = Color(prefs.getInt(_kLyricNormalColorKey) ?? _defaultLyricNormalColor.value);
    _lyricActiveColor = Color(prefs.getInt(_kLyricActiveColorKey) ?? _defaultLyricActiveColor.value);
    _lyricNormalSize = prefs.getDouble(_kLyricNormalSizeKey) ?? _defaultLyricNormalSize;
    _lyricActiveSize = prefs.getDouble(_kLyricActiveSizeKey) ?? _defaultLyricActiveSize;
    _showLyrics = prefs.getBool(_kDefaultShowLyricsKey) ?? _defaultShowLyrics;

    _maxBitRate = prefs.getInt('maxBitRate') ?? 0;
    _autoQuality = prefs.getBool('autoQuality') ?? true;

    // 主题设置
    _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];

    // 加载音乐库设置
    _useGridViewForAlbums = prefs.getBool('useGridViewForAlbums') ?? true;
    _albumGridCoverSize = prefs.getDouble('albumGridCoverSize') ?? 160;
    _albumGridSpacing = prefs.getDouble('albumGridSpacing') ?? 16;
    _enableListAnimation = prefs.getBool('enableListAnimation') ?? true;
    _tabBarHeight = prefs.getDouble('tabBarHeight') ?? 48;
    _tabBarIndicatorHeight = prefs.getDouble('tabBarIndicatorHeight') ?? 32;

    // 加载列表项圆角和Hover效果设置
    _listItemBorderRadius = prefs.getDouble('listItemBorderRadius') ?? 8.0;
    _hoverBorderRadius = prefs.getDouble('hoverBorderRadius') ?? 8.0;
    _hoverOpacity = prefs.getDouble('hoverOpacity') ?? 0.1;

    notifyListeners();
  }

  // 保存设置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 主题色
    await prefs.setInt('primaryColor', _primaryColor.value);

    // 导航栏样式
    await prefs.setDouble('navigationBarHeight', _navigationBarHeight);
    await prefs.setBool('showNavigationLabels', _showNavigationLabels);

    // 迷你播放器样式
    await prefs.setDouble('miniPlayerHeight', _miniPlayerHeight);
    await prefs.setBool('showMiniPlayerProgress', _showMiniPlayerProgress);
    await prefs.setDouble('miniPlayerCoverRadius', _miniPlayerCoverRadius);

    // 播放页面样式
    await prefs.setDouble('coverArtSizeRatio', _coverArtSizeRatio);
    await prefs.setBool('showCoverArtShadow', _showCoverArtShadow);

    // 列表样式
    await prefs.setBool('showListDividers', _showListDividers);
    await prefs.setDouble('listItemHeight', _listItemHeight);

    // 主题设置
    await prefs.setInt('themeMode', _themeMode.index);

    // 保存音乐库设置
    await prefs.setBool('useGridViewForAlbums', _useGridViewForAlbums);
    await prefs.setDouble('albumGridCoverSize', _albumGridCoverSize);
    await prefs.setDouble('albumGridSpacing', _albumGridSpacing);
    await prefs.setBool('enableListAnimation', _enableListAnimation);
    await prefs.setDouble('tabBarHeight', _tabBarHeight);
    await prefs.setDouble('tabBarIndicatorHeight', _tabBarIndicatorHeight);

    // 保存列表项圆角和Hover效果设置
    await prefs.setDouble('listItemBorderRadius', _listItemBorderRadius);
    await prefs.setDouble('hoverBorderRadius', _hoverBorderRadius);
    await prefs.setDouble('hoverOpacity', _hoverOpacity);
  }

  // 更新设置
  void updatePrimaryColor(Color color) {
    _primaryColor = color;
    _saveSettings();
    notifyListeners();
  }

  void updateNavigationBarHeight(double height) {
    _navigationBarHeight = height;
    _saveSettings();
    notifyListeners();
  }

  void toggleNavigationLabels(bool show) {
    _showNavigationLabels = show;
    _saveSettings();
    notifyListeners();
  }

  void updateMiniPlayerHeight(double height) {
    _miniPlayerHeight = height;
    _saveSettings();
    notifyListeners();
  }

  void toggleMiniPlayerProgress(bool show) {
    _showMiniPlayerProgress = show;
    _saveSettings();
    notifyListeners();
  }

  void updateMiniPlayerCoverRadius(double radius) {
    _miniPlayerCoverRadius = radius;
    _saveSettings();
    notifyListeners();
  }

  void updateCoverArtSizeRatio(double ratio) {
    _coverArtSizeRatio = ratio;
    _saveSettings();
    notifyListeners();
  }

  void toggleCoverArtShadow(bool show) {
    _showCoverArtShadow = show;
    _saveSettings();
    notifyListeners();
  }

  void toggleListDividers(bool show) {
    _showListDividers = show;
    _saveSettings();
    notifyListeners();
  }

  void updateListItemHeight(double height) {
    _listItemHeight = height;
    _saveSettings();
    notifyListeners();
  }

  void updateListItemBorderRadius(double radius) {
    _listItemBorderRadius = radius;
    _saveSettings();
    notifyListeners();
  }

  void updateHoverBorderRadius(double radius) {
    _hoverBorderRadius = radius;
    _saveSettings();
    notifyListeners();
  }

  void updateHoverOpacity(double opacity) {
    _hoverOpacity = opacity;
    _saveSettings();
    notifyListeners();
  }

  // 恢复所有设置为默认值
  Future<void> resetAllSettings() async {
    // 主题色
    _primaryColor = Colors.deepPurple;

    // 导航栏样式
    _navigationBarHeight = 80;
    _showNavigationLabels = true;

    // 迷你播放器样式
    _miniPlayerHeight = 64;
    _showMiniPlayerProgress = true;
    _miniPlayerCoverRadius = 6;

    // 播放页面样式
    _coverArtSizeRatio = 0.75;
    _showCoverArtShadow = true;

    // 列表样式
    _showListDividers = false;
    _listItemHeight = 64;

    // 主题设置
    _themeMode = ThemeMode.system;

    await _saveSettings();
    notifyListeners();
  }

  // 更新歌词设置
  Future<void> updateLyricSettings({
    Color? normalColor,
    Color? activeColor,
    double? normalSize,
    double? activeSize,
    bool? showLyrics,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (normalColor != null) {
      _lyricNormalColor = normalColor;
      await prefs.setInt(_kLyricNormalColorKey, normalColor.value);
    }
    
    if (activeColor != null) {
      _lyricActiveColor = activeColor;
      await prefs.setInt(_kLyricActiveColorKey, activeColor.value);
    }
    
    if (normalSize != null) {
      _lyricNormalSize = normalSize;
      await prefs.setDouble(_kLyricNormalSizeKey, normalSize);
    }
    
    if (activeSize != null) {
      _lyricActiveSize = activeSize;
      await prefs.setDouble(_kLyricActiveSizeKey, activeSize);
    }
    
    if (showLyrics != null) {
      _showLyrics = showLyrics;
      await prefs.setBool(_kDefaultShowLyricsKey, showLyrics);
    }

    notifyListeners();
  }

  Future<void> setMaxBitRate(int bitRate) async {
    if (_maxBitRate != bitRate) {
      _maxBitRate = bitRate;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('maxBitRate', bitRate);
      notifyListeners();
    }
  }

  Future<void> setAutoQuality(bool enabled) async {
    if (_autoQuality != enabled) {
      _autoQuality = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoQuality', enabled);
      notifyListeners();
    }
  }

  // 更新主题模式
  void updateThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveSettings();
    notifyListeners();
  }

  // 更新音乐库设置
  void toggleGridViewForAlbums(bool value) {
    _useGridViewForAlbums = value;
    _saveSettings();
    notifyListeners();
  }

  void updateAlbumGridCoverSize(double size) {
    _albumGridCoverSize = size;
    _saveSettings();
    notifyListeners();
  }

  void updateAlbumGridSpacing(double spacing) {
    _albumGridSpacing = spacing;
    _saveSettings();
    notifyListeners();
  }

  void updateTabBarHeight(double height) {
    _tabBarHeight = height;
    _saveSettings();
    notifyListeners();
  }

  void updateTabBarIndicatorHeight(double height) {
    _tabBarIndicatorHeight = height;
    _saveSettings();
    notifyListeners();
  }
} 