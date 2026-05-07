import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/source/playlist/playlist_service.dart';
import 'package:museai/domain/entities/playlist/playlist_entity.dart';
import 'package:museai/domain/repository/playlist/playlist_repository.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final PlaylistService _service;

  PlaylistRepositoryImpl(this._service);

  @override
  Future<Either<Failure, List<PlaylistEntity>>> getUserPlaylists() async {
    try {
      return Right(await _service.getUserPlaylists());
    } catch (e) {
      return Left(GenerationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlaylistEntity>> createPlaylist({
    required String name,
    String? description,
    PlaylistVisibility visibility = PlaylistVisibility.private,
  }) async {
    try {
      return Right(
        await _service.createPlaylist(
          name: name,
          description: description,
          visibility: visibility,
        ),
      );
    } catch (e) {
      return Left(GenerationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlaylistEntity>> updatePlaylist(
    String playlistId, {
    String? name,
    String? description,
    PlaylistVisibility? visibility,
  }) async {
    try {
      return Right(
        await _service.updatePlaylist(
          playlistId,
          name: name,
          description: description,
          visibility: visibility,
        ),
      );
    } catch (e) {
      return Left(GenerationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlaylist(String playlistId) async {
    try {
      await _service.deletePlaylist(playlistId);
      return const Right(null);
    } catch (e) {
      return Left(GenerationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlaylistEntity>> addTrackToPlaylist(
    String playlistId,
    String trackId,
  ) async {
    try {
      return Right(await _service.addTrackToPlaylist(playlistId, trackId));
    } catch (e) {
      return Left(GenerationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlaylistEntity>> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    try {
      return Right(await _service.removeTrackFromPlaylist(playlistId, trackId));
    } catch (e) {
      return Left(GenerationFailure(message: e.toString()));
    }
  }
}
