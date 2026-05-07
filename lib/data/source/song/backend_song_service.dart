// This service handles external or data operations for song browsing and playback.

import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:museai/core/configs/app_config.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/models/songs/song_model.dart';
import 'package:museai/data/source/song/song_service.dart';
import 'package:museai/domain/entities/song/song_entity.dart';

class BackendSongService implements SongService {
  final http.Client _client;

  BackendSongService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<Either<Failure, List<SongEntity>>> getNewsSongs() async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConfig.backendBaseUrl}/api/v1/songs'),
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Left(
          NetworkFailure(message: _extractErrorMessage(response.body)),
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return const Left(
          NetworkFailure(message: 'Invalid songs response from backend.'),
        );
      }

      final songs = decoded
          .map((row) => SongModel.fromMap(row as Map<String, dynamic>))
          .toList();
      return Right(songs);
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {}
    return 'Unable to load songs.';
  }
}
