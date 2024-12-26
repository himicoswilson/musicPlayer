import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'song.dart';

class LocalSong extends Song {
  final String filePath;
  final Uint8List? coverData;
  final DateTime? lastModified;

  LocalSong({
    required String id,
    required String title,
    String? artist,
    String? album,
    String? albumArtist,
    String? genre,
    int? year,
    int? track,
    required this.filePath,
    Duration? duration,
    String? coverPath,
    this.coverData,
    this.lastModified,
  }) : super(
          id: id,
          title: title,
          albumId: album ?? 'unknown',
          albumName: album ?? '未知专辑',
          artistId: artist ?? albumArtist ?? 'unknown',
          artistName: artist ?? albumArtist ?? '未知艺术家',
          coverArtId: coverPath,
          duration: duration?.inSeconds ?? 0,
          track: track ?? 0,
          year: year,
          genre: genre,
          size: 0,  // 暂时不计算文件大小
          suffix: path.extension(filePath).replaceAll('.', ''),
          bitRate: 0,  // 暂时不计算比特率
        );

  static Future<LocalSong> fromFile(File file) async {
    final filePath = file.path;
    String title = path.basenameWithoutExtension(filePath);
    final lastModified = await file.lastModified();
    
    // 暂时只使用文件名作为标题
    return LocalSong(
      id: filePath,
      title: title,
      filePath: filePath,
      lastModified: lastModified,
    );
  }
} 