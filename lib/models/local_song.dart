import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'song.dart';

class LocalSong extends Song {
  final String filePath;
  final Uint8List? coverData;
  final DateTime? lastModified;

  LocalSong({
    required String id,
    required String title,
    required this.filePath,
    String? albumName,
    String? artistName,
    String? coverArtId,
    int duration = 0,
    int track = 0,
    int? year,
    this.coverData,
    this.lastModified,
  }) : super(
          id: id,
          title: title,
          albumName: albumName,
          artistName: artistName,
          coverArtId: coverArtId,
          duration: duration,
          track: track,
          year: year,
        );

  static Future<LocalSong> fromFile(File file) async {
    final stats = await file.stat();
    
    try {
      final metadata = await MetadataRetriever.fromFile(file);
      
      return LocalSong(
        id: file.path,
        title: metadata.trackName ?? path.basenameWithoutExtension(file.path),
        filePath: file.path,
        albumName: metadata.albumName,
        artistName: metadata.trackArtistNames?.firstOrNull,
        coverArtId: null, // 暂时不处理封面
        duration: metadata.trackDuration ?? 0,
        track: metadata.trackNumber ?? 0,
        year: metadata.year,
        lastModified: stats.modified,
      );
    } catch (e) {
      print('读取音乐文件元数据失败: $e');
      // 如果读取元数据失败，使用基本文件信息
      return LocalSong(
        id: file.path,
        title: path.basenameWithoutExtension(file.path),
        filePath: file.path,
        lastModified: stats.modified,
      );
    }
  }
} 