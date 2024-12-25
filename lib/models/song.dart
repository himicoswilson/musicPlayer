class Song {
  final String id;
  final String title;
  final String albumId;
  final String albumName;
  final String artistId;
  final String artistName;
  final String? coverArtId;
  final int duration;
  final int track;
  final int? year;
  final String? genre;
  final int size;
  final String suffix;
  final int bitRate;

  Song({
    required this.id,
    required this.title,
    required this.albumId,
    required this.albumName,
    required this.artistId,
    required this.artistName,
    this.coverArtId,
    required this.duration,
    required this.track,
    this.year,
    this.genre,
    required this.size,
    required this.suffix,
    required this.bitRate,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      albumId: json['albumId'],
      albumName: json['album'],
      artistId: json['artistId'],
      artistName: json['artist'],
      coverArtId: json['coverArt'],
      duration: json['duration'] ?? 0,
      track: json['track'] ?? 0,
      year: json['year'],
      genre: json['genre'],
      size: json['size'] ?? 0,
      suffix: json['suffix'] ?? '',
      bitRate: json['bitRate'] ?? 0,
    );
  }
} 