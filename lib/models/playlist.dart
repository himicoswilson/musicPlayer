import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final String? comment;
  final String owner;
  final bool public;
  final int songCount;
  final DateTime created;
  final DateTime changed;
  final List<Song> songs;

  Playlist({
    required this.id,
    required this.name,
    this.comment,
    required this.owner,
    required this.public,
    required this.songCount,
    required this.created,
    required this.changed,
    required this.songs,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      comment: json['comment'],
      owner: json['owner'],
      public: json['public'] ?? false,
      songCount: json['songCount'] ?? 0,
      created: DateTime.parse(json['created']),
      changed: DateTime.parse(json['changed']),
      songs: (json['entry'] as List<dynamic>?)
          ?.map((e) => Song.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'comment': comment,
      'owner': owner,
      'public': public,
      'songCount': songCount,
      'created': created.toIso8601String(),
      'changed': changed.toIso8601String(),
      'entry': songs.map((e) => e.toJson()).toList(),
    };
  }
} 