import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/source/song/song_firebase_service.dart';
import 'package:museai/domain/entities/song/song_entity.dart';
import 'package:museai/domain/repository/song/song_repository.dart';
import 'package:museai/service_locator.dart';

class SongRepositoryImpl extends SongRepository {
  @override
  Future<Either<Failure, List<SongEntity>>> getNewsSongs() async {
    return await sl<SongFirebaseService>().getNewsSongs();
  }
}
