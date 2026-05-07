// This service handles external or data operations for music generation.

import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';

abstract class GenerationService {
  Future<String> createGeneration(String uid, GenerationParams params);
  Stream<GenerationEntity> watchGeneration(String uid, String generationId);
  Future<List<GenerationEntity>> getUserGenerations(String uid);
  Future<GenerationEntity> updateGeneration(
    String generationId, {
    String? title,
    String? prompt,
    bool? isPublic,
  });
  Future<void> deleteGeneration(String generationId);
}
