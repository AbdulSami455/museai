// This file implements repository behavior for song browsing and playback.

import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/source/song/song_service.dart';
import 'package:museai/domain/entities/song/song_entity.dart';
import 'package:museai/domain/repository/song/song_repository.dart';

class SongRepositoryImpl extends SongRepository {
  final SongService _service;
  SongRepositoryImpl(this._service);

  @override
  Future<Either<Failure, List<SongEntity>>> getNewsSongs() async {
    return await _service.getNewsSongs();
  }
}
