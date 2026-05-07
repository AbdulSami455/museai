// This service handles external or data operations for music generation.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:museai/core/configs/app_config.dart';
import 'package:museai/data/models/generation/generation_model.dart';
import 'package:museai/data/source/generation/generation_service.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseGenerationService implements GenerationService {
  final SupabaseClient _client;
  final http.Client _httpClient;

  SupabaseGenerationService({SupabaseClient? client, http.Client? httpClient})
      : _client = client ?? Supabase.instance.client,
        _httpClient = httpClient ?? http.Client();

  @override
  Future<String> createGeneration(String uid, GenerationParams params) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw StateError('You must sign in before generating a track.');
    }

    final response = await _httpClient.post(
      Uri.parse('${AppConfig.backendBaseUrl}/api/v1/generations'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'prompt': params.prompt,
        'mood': params.mood,
        'genre': params.genre,
        'bpm': params.bpm,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return payload['id'] as String;
  }

  @override
  Stream<GenerationEntity> watchGeneration(String uid, String generationId) {
    final controller = StreamController<GenerationEntity>();
    Timer? poller;

    Future<void> fetchGeneration() async {
      try {
        final session = _client.auth.currentSession;
        if (session == null) {
          throw StateError('You must sign in before loading generations.');
        }

        final response = await _httpClient.get(
          Uri.parse(
              '${AppConfig.backendBaseUrl}/api/v1/generations/$generationId'),
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(_extractErrorMessage(response.body));
        }

        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        if (!controller.isClosed) {
          controller.add(GenerationModel.fromMap(payload));
        }
      } catch (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      }
    }

    fetchGeneration();
    poller =
        Timer.periodic(const Duration(seconds: 2), (_) => fetchGeneration());

    controller.onCancel = () async {
      poller?.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  @override
  Future<List<GenerationEntity>> getUserGenerations(String uid) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw StateError('You must sign in before loading generations.');
    }

    final response = await _httpClient.get(
      Uri.parse('${AppConfig.backendBaseUrl}/api/v1/generations'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((row) => GenerationModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GenerationEntity> updateGeneration(
    String generationId, {
    String? title,
    String? prompt,
    bool? isPublic,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw StateError('You must sign in before updating generations.');
    }

    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (prompt != null) body['prompt'] = prompt;
    if (isPublic != null) body['is_public'] = isPublic;

    final response = await _httpClient.patch(
      Uri.parse('${AppConfig.backendBaseUrl}/api/v1/generations/$generationId'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return GenerationModel.fromMap(payload);
  }

  @override
  Future<void> deleteGeneration(String generationId) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw StateError('You must sign in before deleting generations.');
    }

    final response = await _httpClient.delete(
      Uri.parse('${AppConfig.backendBaseUrl}/api/v1/generations/$generationId'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body));
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
    return 'Generation request failed.';
  }
}
