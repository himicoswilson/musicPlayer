import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/lyric.dart';

class LyricService {
  static final LyricService _instance = LyricService._internal();
  factory LyricService() => _instance;
  LyricService._internal();

  Future<Lyric?> parseLyric(String lrcContent) async {
    try {
      final lines = <LyricLine>[];
      final lrcLines = lrcContent.split('\n');
      
      for (final line in lrcLines) {
        if (line.trim().isEmpty) continue;
        
        // 解析时间标签 [mm:ss.xx] 或 [mm:ss:xx]
        final regex = RegExp(r'\[(\d{2}):(\d{2})[\.:]\d{2,3}\]');
        final matches = regex.allMatches(line);
        
        if (matches.isEmpty) continue;
        
        // 获取歌词文本（去除所有时间标签）
        String text = line.replaceAll(RegExp(r'\[\d{2}:\d{2}[\.:]\d{2,3}\]'), '').trim();
        if (text.isEmpty) continue;
        
        // 为每个时间标签创建一个歌词行
        for (final match in matches) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          
          final timestamp = Duration(
            minutes: minutes,
            seconds: seconds,
          );
          
          lines.add(LyricLine(
            timestamp: timestamp,
            text: text,
          ));
        }
      }
      
      // 按时间戳排序
      lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // 如果没有解析出任何歌词行，返回null
      if (lines.isEmpty) return null;
      
      return Lyric(lines);
    } catch (e) {
      debugPrint('解析歌词失败: $e');
      return null;
    }
  }

  String? _parseMetadata(String line, String tag) {
    final RegExp regex = RegExp(r'\[' + tag + r':([^\]]*)\]');
    final match = regex.firstMatch(line);
    return match?.group(1)?.trim();
  }

  LyricLine? _parseLyricLine(String line) {
    // 匹配时间戳格式 [mm:ss.xx] 或 [mm:ss:xx]
    final RegExp timeRegex = RegExp(r'\[(\d{2}):(\d{2})[\.:]\d{2,3}\]');
    final matches = timeRegex.allMatches(line);
    
    if (matches.isEmpty) return null;

    // 获取最后一个时间戳后的文本作为歌词
    final lastMatch = matches.last;
    final text = line.substring(lastMatch.end).trim();
    
    // 如果没有歌词文本，返回null
    if (text.isEmpty) return null;

    // 解析时间戳
    final minutes = int.parse(lastMatch.group(1)!);
    final seconds = int.parse(lastMatch.group(2)!);
    final timestamp = Duration(minutes: minutes, seconds: seconds);

    return LyricLine(
      timestamp: timestamp,
      text: text,
    );
  }

  Future<String?> fetchLyricContent(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('获取歌词失败: $e');
    }
    return null;
  }
} 