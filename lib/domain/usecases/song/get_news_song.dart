// This file contains supporting logic for song browsing and playback.

import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/core/usecase/usecase.dart';
import 'package:museai/domain/entities/song/song_entity.dart';
import 'package:museai/domain/repository/song/song_repository.dart';

class GetNewsSongUsecase
    implements Usecase<Either<Failure, List<SongEntity>>, dynamic> {
  final SongRepository _repository;
  GetNewsSongUsecase(this._repository);

  @override
  Future<Either<Failure, List<SongEntity>>> call({params}) async {
    return await _repository.getNewsSongs();
  }
}
