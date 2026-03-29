import 'package:dartz/dartz.dart';
import 'package:museai/data/source/song/song_firebase_service.dart';
import 'package:museai/domain/repository/song/song_repository.dart';
import 'package:museai/service_locator.dart';

class SongRepositoryImpl extends SongRepository{
  @override
  Future<Either> getNewsSongs() {
    return sl<SongFirebaseService>().getNewsSongs();
  }
  
}