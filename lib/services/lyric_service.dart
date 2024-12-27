import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lyric.dart';

class LyricService {
  static final LyricService _instance = LyricService._internal();
  factory LyricService() => _instance;
  LyricService._internal();

  Future<Lyric?> parseLyric(String lrcContent) async {
    if (lrcContent.isEmpty) return null;

    final List<LyricLine> lines = [];
    String? title, artist, album, by;
    Duration? offset;

    // 按行分割歌词
    final List<String> rawLines = LineSplitter.split(lrcContent).toList();

    for (String line in rawLines) {
      // 解析元数据
      if (line.startsWith('[ti:')) {
        title = _parseMetadata(line, 'ti');
      } else if (line.startsWith('[ar:')) {
        artist = _parseMetadata(line, 'ar');
      } else if (line.startsWith('[al:')) {
        album = _parseMetadata(line, 'al');
      } else if (line.startsWith('[by:')) {
        by = _parseMetadata(line, 'by');
      } else if (line.startsWith('[offset:')) {
        final offsetStr = _parseMetadata(line, 'offset');
        if (offsetStr != null) {
          offset = Duration(milliseconds: int.tryParse(offsetStr) ?? 0);
        }
      } else if (line.startsWith('[')) {
        // 解析带时间戳的歌词行
        final lyricLine = _parseLyricLine(line);
        if (lyricLine != null) {
          lines.add(lyricLine);
        }
      }
    }

    // 按时间戳排序
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Lyric(
      lines: lines,
      title: title,
      artist: artist,
      album: album,
      by: by,
      offset: offset,
    );
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
      print('Error fetching lyric: $e');
    }
    return null;
  }
} 