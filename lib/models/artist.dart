class Artist {
  final String id;
  final String name;
  final String? imageUrl;
  final int albumCount;

  Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.albumCount,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'],
      name: json['name'],
      imageUrl: json['coverArt'],
      albumCount: json['albumCount'] ?? 0,
    );
  }
} 