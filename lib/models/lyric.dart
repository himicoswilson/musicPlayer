class LyricLine {
  final Duration timestamp;
  final String text;

  LyricLine({
    required this.timestamp,
    required this.text,
  });
}

class Lyric {
  final List<LyricLine> lines;
  final String? title;
  final String? artist;
  final String? album;
  final String? by;
  final Duration? offset;

  Lyric({
    required this.lines,
    this.title,
    this.artist,
    this.album,
    this.by,
    this.offset,
  });

  LyricLine? findLyricLine(Duration position) {
    if (lines.isEmpty) return null;
    
    // 考虑偏移量
    final adjustedPosition = position - (offset ?? Duration.zero);
    
    // 找到第一个时间戳大于当前位置的歌词的索引
    int index = lines.indexWhere((line) => line.timestamp > adjustedPosition);
    
    // 如果没找到，说明当前位置已经超过最后一句歌词
    if (index == -1) return lines.last;
    
    // 如果是第一句歌词，并且还没到时间，返回null
    if (index == 0) return null;
    
    // 返回前一句歌词
    return lines[index - 1];
  }
} 