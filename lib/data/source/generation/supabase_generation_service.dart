import 'package:museai/data/source/generation/generation_service.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';

class SupabaseGenerationService implements GenerationService {
  @override
  Future<String> createGeneration(String uid, GenerationParams params) {
    throw UnimplementedError(
        'Backend not yet implemented — see GitHub issue #31');
  }

  @override
  Stream<GenerationEntity> watchGeneration(String uid, String generationId) {
    throw UnimplementedError(
        'Backend not yet implemented — see GitHub issue #31');
  }

  @override
  Future<List<GenerationEntity>> getUserGenerations(String uid) {
    throw UnimplementedError(
        'Backend not yet implemented — see GitHub issue #31');
  }
}
