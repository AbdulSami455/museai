import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:museai/data/models/generation/generation_model.dart';
import 'package:museai/data/source/generation/generation_service.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';

class GenerationStubService implements GenerationService {
  final SupabaseClient _client;

  GenerationStubService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<String> createGeneration(String uid, GenerationParams params) async {
    final response = await _client.from('generations').insert({
      'uid': uid,
      'prompt': params.prompt,
      'mood': params.mood,
      'genre': params.genre,
      'bpm': params.bpm,
      'status': 'processing',
      'created_at': DateTime.now().toIso8601String(),
    }).select('id').single();

    final id = response['id'] as String;

    // Simulate backend completing after 3 seconds
    Future.delayed(const Duration(seconds: 3), () async {
      await _client.from('generations').update({
        'status': 'completed',
        'audio_url':
            'https://fatxsbalyeebltrzzape.supabase.co/storage/v1/object/public/museai-assets/stub-audio.mp3',
        'cover_url':
            'https://fatxsbalyeebltrzzape.supabase.co/storage/v1/object/public/museai-assets/stub-cover.jpg',
      }).eq('id', id);
    });

    return id;
  }

  @override
  Stream<GenerationEntity> watchGeneration(String uid, String generationId) {
    final controller = StreamController<GenerationEntity>();

    // Initial fetch
    _client
        .from('generations')
        .select()
        .eq('id', generationId)
        .single()
        .then((data) {
      if (!controller.isClosed) {
        controller.add(GenerationModel.fromMap(data));
      }
    });

    // Realtime subscription
    final channel = _client
        .channel('generation-$generationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'generations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: generationId,
          ),
          callback: (payload) {
            if (!controller.isClosed) {
              controller.add(
                GenerationModel.fromMap(payload.newRecord),
              );
            }
          },
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<List<GenerationEntity>> getUserGenerations(String uid) async {
    final response = await _client
        .from('generations')
        .select()
        .eq('uid', uid)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => GenerationModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
