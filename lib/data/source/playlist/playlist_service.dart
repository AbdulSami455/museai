import 'package:museai/domain/entities/playlist/playlist_entity.dart';

abstract class PlaylistService {
  Future<List<PlaylistEntity>> getUserPlaylists();
  Future<PlaylistEntity> createPlaylist({
    required String name,
    String? description,
    PlaylistVisibility visibility = PlaylistVisibility.private,
  });
  Future<PlaylistEntity> updatePlaylist(
    String playlistId, {
    String? name,
    String? description,
    PlaylistVisibility? visibility,
  });
  Future<void> deletePlaylist(String playlistId);
  Future<PlaylistEntity> addTrackToPlaylist(String playlistId, String trackId);
  Future<PlaylistEntity> removeTrackFromPlaylist(
      String playlistId, String trackId);
}
