import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/models/songs/song_model.dart';
import 'package:museai/data/source/song/song_firebase_service.dart';
import 'package:museai/domain/entities/song/song_entity.dart';

class SongFirebaseServiceImpl extends SongFirebaseService {
  final SupabaseClient _client;

  SongFirebaseServiceImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<Either<Failure, List<SongEntity>>> getNewsSongs() async {
    try {
      final response = await _client
          .from('songs')
          .select()
          .order('release_date', ascending: false);

      if (response.isEmpty) {
        return const Left(SongFailure(message: 'No songs available'));
      }

      final songs = (response as List)
          .map((row) => SongModel.fromMap(row as Map<String, dynamic>))
          .toList();
      return Right(songs);
    } on SocketException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(SongFailure(message: e.toString()));
    }
  }
}
