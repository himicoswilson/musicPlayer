class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricLine &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          text == other.text;

  @override
  int get hashCode => timestamp.hashCode ^ text.hashCode;
}

class Lyric {
  final List<LyricLine> _lines;

  Lyric(this._lines);

  List<LyricLine> get lyrics => _lines;

  LyricLine? findLyricLine(Duration position) {
    if (_lines.isEmpty) return null;
    
    // 如果当前时间小于第一行歌词时间，返回第一行
    if (position < _lines.first.timestamp) {
      return _lines.first;
    }
    
    // 如果当前时间大于最后一行歌词时间，返回最后一行
    if (position > _lines.last.timestamp) {
      return _lines.last;
    }
    
    // 二分查找当前时间对应的歌词
    int left = 0;
    int right = _lines.length - 1;
    
    while (left <= right) {
      final mid = (left + right) ~/ 2;
      final line = _lines[mid];
      
      if (line.timestamp == position) {
        return line;
      }
      
      if (line.timestamp < position) {
        // 如果是最后一行，或者下一行的时间戳大于当前时间，说明当前行就是要找的歌词
        if (mid == _lines.length - 1 || _lines[mid + 1].timestamp > position) {
          return line;
        }
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }
    
    // 如果没找到，返回最近的一行
    return _lines[left];
  }
} 