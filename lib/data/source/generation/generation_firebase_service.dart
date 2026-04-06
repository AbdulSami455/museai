import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';

abstract class GenerationFirebaseService {
  Future<String> createGeneration(String uid, GenerationParams params);
  Stream<GenerationEntity> watchGeneration(String uid, String generationId);
  Future<List<GenerationEntity>> getUserGenerations(String uid);
}
