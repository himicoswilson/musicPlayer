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
} 