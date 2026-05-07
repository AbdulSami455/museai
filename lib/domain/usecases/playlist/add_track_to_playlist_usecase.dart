// This use case handles one focused action in playlist features.

import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/playlist/playlist_entity.dart';
import 'package:museai/domain/repository/playlist/playlist_repository.dart';

class AddTrackToPlaylistUsecase {
  final PlaylistRepository _repository;

  AddTrackToPlaylistUsecase(this._repository);

  Future<Either<Failure, PlaylistEntity>> call(
    String playlistId,
    String trackId,
  ) {
    return _repository.addTrackToPlaylist(playlistId, trackId);
  }
}
