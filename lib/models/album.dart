class Album {
  final String id;
  final String name;
  final String artistId;
  final String artistName;
  final String? coverArtId;
  final int songCount;
  final int duration;
  final String? year;

  Album({
    required this.id,
    required this.name,
    required this.artistId,
    required this.artistName,
    this.coverArtId,
    required this.songCount,
    required this.duration,
    this.year,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      name: json['name'],
      artistId: json['artistId'],
      artistName: json['artist'],
      coverArtId: json['coverArt'],
      songCount: json['songCount'] ?? 0,
      duration: json['duration'] ?? 0,
      year: json['year']?.toString(),
    );
  }
} 