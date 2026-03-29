import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/source/song/song_firebase_service.dart';
import 'package:museai/domain/entities/song/song_entity.dart';
import 'package:museai/domain/repository/song/song_repository.dart';

class SongRepositoryImpl extends SongRepository {
  final SongFirebaseService _service;
  SongRepositoryImpl(this._service);

  @override
  Future<Either<Failure, List<SongEntity>>> getNewsSongs() async {
    return await _service.getNewsSongs();
  }
}
