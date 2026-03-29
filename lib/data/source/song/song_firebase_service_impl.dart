import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:museai/core/configs/const/firebase_const.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/models/songs/song_model.dart';
import 'package:museai/data/source/song/song_firebase_service.dart';
import 'package:museai/domain/entities/song/song_entity.dart';

class SongFirebaseServiceImpl extends SongFirebaseService {
  @override
  Future<Either<Failure, List<SongEntity>>> getNewsSongs() async {
    try {
      final songCollection = await FirebaseFirestore.instance
          .collection(FirebaseConst.songs)
          .orderBy('releaseDate', descending: true)
          .get();

      final songs = songCollection.docs
          .map((snap) => SongModel.fromSnapshot(snap) as SongEntity)
          .toList();

      return Right(songs);
    } on SocketException {
      return const Left(NetworkFailure(message: 'No internet connection'));
    } on HandshakeException {
      return const Left(NetworkFailure(message: 'Network error'));
    } catch (e) {
      return Left(SongFailure(message: e.toString()));
    }
  }
}
