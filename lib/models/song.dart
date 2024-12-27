class Song {
  final String id;
  String title;
  String? albumId;
  String? albumName;
  String? artistId;
  String? artistName;
  String? coverArtId;
  int duration;
  int track;
  int? year;

  Song({
    required this.id,
    required this.title,
    this.albumId,
    this.albumName,
    this.artistId,
    this.artistName,
    this.coverArtId,
    this.duration = 0,
    this.track = 0,
    this.year,
  });

  String get artist => artistName ?? '未知艺术家';

  String? get coverArtUrl => coverArtId != null ? '/rest/getCoverArt.view?id=$coverArtId' : null;

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'albumId': albumId,
      'album': albumName,
      'artistId': artistId,
      'artist': artistName,
      'coverArt': coverArtId,
      'duration': duration,
      'track': track,
      'year': year,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
} 