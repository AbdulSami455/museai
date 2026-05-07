// This use case handles one focused action in playlist features.

import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/playlist/playlist_entity.dart';
import 'package:museai/domain/repository/playlist/playlist_repository.dart';

class CreatePlaylistUsecase {
  final PlaylistRepository _repository;

  CreatePlaylistUsecase(this._repository);

  Future<Either<Failure, PlaylistEntity>> call({
    required String name,
    String? description,
    PlaylistVisibility visibility = PlaylistVisibility.private,
  }) {
    return _repository.createPlaylist(
      name: name,
      description: description,
      visibility: visibility,
    );
  }
}
