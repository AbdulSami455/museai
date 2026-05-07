// This service handles external or data operations for playlist features.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:museai/core/configs/app_config.dart';
import 'package:museai/data/models/playlist/playlist_model.dart';
import 'package:museai/data/source/playlist/playlist_service.dart';
import 'package:museai/domain/entities/playlist/playlist_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BackendPlaylistService implements PlaylistService {
  final SupabaseClient _client;
  final http.Client _httpClient;

  BackendPlaylistService({SupabaseClient? client, http.Client? httpClient})
      : _client = client ?? Supabase.instance.client,
        _httpClient = httpClient ?? http.Client();

  @override
  Future<List<PlaylistEntity>> getUserPlaylists() async {
    final response = await _authorizedGet('/api/v1/playlists');
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((row) => PlaylistModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PlaylistEntity> createPlaylist({
    required String name,
    String? description,
    PlaylistVisibility visibility = PlaylistVisibility.private,
  }) async {
    final response = await _authorizedRequest(
      'POST',
      '/api/v1/playlists',
      body: {
        'name': name,
        'description': description,
        'visibility': visibility.name,
      },
    );
    return PlaylistModel.fromMap(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<PlaylistEntity> updatePlaylist(
    String playlistId, {
    String? name,
    String? description,
    PlaylistVisibility? visibility,
  }) async {
    final response = await _authorizedRequest(
      'PATCH',
      '/api/v1/playlists/$playlistId',
      body: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (visibility != null) 'visibility': visibility.name,
      },
    );
    return PlaylistModel.fromMap(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await _authorizedRequest('DELETE', '/api/v1/playlists/$playlistId');
  }

  @override
  Future<PlaylistEntity> addTrackToPlaylist(
      String playlistId, String trackId) async {
    final response = await _authorizedRequest(
      'POST',
      '/api/v1/playlists/$playlistId/tracks',
      body: {'track_id': trackId},
    );
    return PlaylistModel.fromMap(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<PlaylistEntity> removeTrackFromPlaylist(
      String playlistId, String trackId) async {
    final response = await _authorizedRequest(
      'DELETE',
      '/api/v1/playlists/$playlistId/tracks/$trackId',
    );
    return PlaylistModel.fromMap(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<http.Response> _authorizedGet(String path) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw StateError('You must sign in before loading playlists.');
    }

    final response = await _httpClient.get(
      Uri.parse('${AppConfig.backendBaseUrl}$path'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );
    _ensureSuccess(response);
    return response;
  }

  Future<http.Response> _authorizedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw StateError('You must sign in before updating playlists.');
    }

    final uri = Uri.parse('${AppConfig.backendBaseUrl}$path');
    late final http.Response response;
    switch (method) {
      case 'POST':
        response = await _httpClient.post(
          uri,
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        );
        break;
      case 'PATCH':
        response = await _httpClient.patch(
          uri,
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        );
        break;
      case 'DELETE':
        response = await _httpClient.delete(
          uri,
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        );
        break;
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }

    _ensureSuccess(response);
    return response;
  }

  void _ensureSuccess(http.Response response) {
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
    return 'Playlist request failed.';
  }
}
