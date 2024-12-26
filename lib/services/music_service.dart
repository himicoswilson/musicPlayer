import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';

abstract class MusicService {
  // 获取所有艺术家
  Future<List<Artist>> getArtists();

  // 获取艺术家的所有专辑
  Future<List<Album>> getArtistAlbums(String artistId);

  // 获取专辑的所有歌曲
  Future<List<Song>> getAlbumSongs(String albumId);

  // 获取所有专辑
  Future<List<Album>> getAlbums({int? size, int? offset});

  // 获取最新歌曲
  Future<List<Song>> getNewestSongs({int? size});

  // 搜索
  Future<Map<String, dynamic>> search(String query);

  // 获取歌曲流媒体URL
  String getStreamUrl(String songId);

  // 获取封面图片URL
  String getCoverArtUrl(String? coverArtId);

  // 初始化服务
  Future<void> init();

  // 检查服务是否可用
  Future<bool> isAvailable();
} 