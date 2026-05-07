// This file implements repository behavior for music generation.

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/source/generation/generation_service.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/repository/generation/generation_repository.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';

class GenerationRepositoryImpl implements GenerationRepository {
  final GenerationService _service;

  GenerationRepositoryImpl(this._service);

  @override
  Future<Either<Failure, String>> createGeneration(
      GenerationParams params) async {
    try {
      final id = await _service.createGeneration(params.uid, params);
      return Right(id);
    } catch (e) {
      return Left(GenerationFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, GenerationEntity>> watchGeneration(
    String uid,
    String generationId,
  ) {
    return _service.watchGeneration(uid, generationId).transform(
          StreamTransformer<GenerationEntity,
              Either<Failure, GenerationEntity>>.fromHandlers(
            handleData: (entity, sink) => sink.add(Right(entity)),
            handleError: (e, _, sink) =>
                sink.add(Left(GenerationFailure(message: e.toString()))),
          ),
        );
  }

  @override
  Future<Either<Failure, List<GenerationEntity>>> getUserGenerations(
      String uid) async {
    try {
      final list = await _service.getUserGenerations(uid);
      return Right(list);
    } catch (e) {
      return Left(GenerationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, GenerationEntity>> updateGeneration(
    String generationId, {
    String? title,
    String? prompt,
    bool? isPublic,
  }) async {
    try {
      final generation = await _service.updateGeneration(
        generationId,
        title: title,
        prompt: prompt,
        isPublic: isPublic,
      );
      return Right(generation);
    } catch (e) {
      return Left(GenerationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGeneration(String generationId) async {
    try {
      await _service.deleteGeneration(generationId);
      return const Right(null);
    } catch (e) {
      return Left(GenerationFailure(message: e.toString()));
    }
  }
}
