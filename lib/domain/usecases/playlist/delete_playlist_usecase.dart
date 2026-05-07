// This use case handles one focused action in playlist features.

import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/repository/playlist/playlist_repository.dart';

class DeletePlaylistUsecase {
  final PlaylistRepository _repository;

  DeletePlaylistUsecase(this._repository);

  Future<Either<Failure, void>> call(String playlistId) {
    return _repository.deletePlaylist(playlistId);
  }
}
