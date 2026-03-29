import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/core/usecase/usecase.dart';
import 'package:museai/domain/entities/song/song_entity.dart';
import 'package:museai/domain/repository/song/song_repository.dart';
import 'package:museai/service_locator.dart';

class GetNewsSongUsecase implements Usecase<Either<Failure, List<SongEntity>>, dynamic> {
  @override
  Future<Either<Failure, List<SongEntity>>> call({params}) async {
    return await sl<SongRepository>().getNewsSongs();
  }
}
