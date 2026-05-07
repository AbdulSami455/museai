import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/playlist/playlist_entity.dart';

abstract class PlaylistRepository {
  Future<Either<Failure, List<PlaylistEntity>>> getUserPlaylists();
  Future<Either<Failure, PlaylistEntity>> createPlaylist({
    required String name,
    String? description,
    PlaylistVisibility visibility = PlaylistVisibility.private,
  });
  Future<Either<Failure, PlaylistEntity>> updatePlaylist(
    String playlistId, {
    String? name,
    String? description,
    PlaylistVisibility? visibility,
  });
  Future<Either<Failure, void>> deletePlaylist(String playlistId);
  Future<Either<Failure, PlaylistEntity>> addTrackToPlaylist(
    String playlistId,
    String trackId,
  );
  Future<Either<Failure, PlaylistEntity>> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  );
}
