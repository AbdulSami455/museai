// This service handles external or data operations for song browsing and playback.

import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/song/song_entity.dart';

abstract class SongService {
  Future<Either<Failure, List<SongEntity>>> getNewsSongs();
}
