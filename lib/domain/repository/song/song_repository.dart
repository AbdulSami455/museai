import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/song/song_entity.dart';

abstract class SongRepository {
  Future<Either<Failure, List<SongEntity>>> getNewsSongs();
}
