import 'package:dartz/dartz.dart';
import 'package:museai/core/usecase/usecase.dart';
import 'package:museai/domain/repository/song/song_repository.dart';
import 'package:museai/service_locator.dart';

class GetNewsSongUsecase implements Usecase<Either, dynamic> {
  @override
  Future<Either> call({params}) async{
    return await sl<SongRepository>().getNewsSongs();
  }
}
