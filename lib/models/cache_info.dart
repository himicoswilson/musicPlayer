class CacheInfo {
  final String songId;
  final int size;
  final DateTime lastAccessed;

  CacheInfo({
    required this.songId,
    required this.size,
    required this.lastAccessed,
  });
} 