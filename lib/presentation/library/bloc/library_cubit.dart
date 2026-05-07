import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/data/source/library/mock_library_data.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/entities/playlist/playlist_entity.dart';
import 'package:museai/domain/usecases/generation/delete_generation_usecase.dart';
import 'package:museai/domain/usecases/generation/get_user_generations_usecase.dart';
import 'package:museai/domain/usecases/generation/update_generation_usecase.dart';
import 'package:museai/domain/usecases/playlist/add_track_to_playlist_usecase.dart';
import 'package:museai/domain/usecases/playlist/create_playlist_usecase.dart';
import 'package:museai/domain/usecases/playlist/delete_playlist_usecase.dart';
import 'package:museai/domain/usecases/playlist/get_user_playlists_usecase.dart';
import 'package:museai/domain/usecases/playlist/remove_track_from_playlist_usecase.dart';
import 'package:museai/domain/usecases/playlist/update_playlist_usecase.dart';
import 'package:museai/presentation/library/bloc/library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final GetUserGenerationsUsecase _getUserGenerationsUsecase;
  final UpdateGenerationUsecase _updateGenerationUsecase;
  final DeleteGenerationUsecase _deleteGenerationUsecase;
  final GetUserPlaylistsUsecase _getUserPlaylistsUsecase;
  final CreatePlaylistUsecase _createPlaylistUsecase;
  final UpdatePlaylistUsecase _updatePlaylistUsecase;
  final DeletePlaylistUsecase _deletePlaylistUsecase;
  final AddTrackToPlaylistUsecase _addTrackToPlaylistUsecase;
  final RemoveTrackFromPlaylistUsecase _removeTrackFromPlaylistUsecase;

  LibraryCubit({
    required GetUserGenerationsUsecase getUserGenerationsUsecase,
    required UpdateGenerationUsecase updateGenerationUsecase,
    required DeleteGenerationUsecase deleteGenerationUsecase,
    required GetUserPlaylistsUsecase getUserPlaylistsUsecase,
    required CreatePlaylistUsecase createPlaylistUsecase,
    required UpdatePlaylistUsecase updatePlaylistUsecase,
    required DeletePlaylistUsecase deletePlaylistUsecase,
    required AddTrackToPlaylistUsecase addTrackToPlaylistUsecase,
    required RemoveTrackFromPlaylistUsecase removeTrackFromPlaylistUsecase,
  })  : _getUserGenerationsUsecase = getUserGenerationsUsecase,
        _updateGenerationUsecase = updateGenerationUsecase,
        _deleteGenerationUsecase = deleteGenerationUsecase,
        _getUserPlaylistsUsecase = getUserPlaylistsUsecase,
        _createPlaylistUsecase = createPlaylistUsecase,
        _updatePlaylistUsecase = updatePlaylistUsecase,
        _deletePlaylistUsecase = deletePlaylistUsecase,
        _addTrackToPlaylistUsecase = addTrackToPlaylistUsecase,
        _removeTrackFromPlaylistUsecase = removeTrackFromPlaylistUsecase,
        super(const LibraryLoading());

  Future<void> load(String uid) async {
    emit(const LibraryLoading());
    final tracksResult = await _getUserGenerationsUsecase(uid);
    final playlistsResult = await _getUserPlaylistsUsecase();

    List<GenerationEntity> tracks = [];
    List<PlaylistEntity> playlists = [];
    bool fallbackToMock = false;

    tracksResult.fold((_) => fallbackToMock = true, (value) => tracks = value);
    playlistsResult.fold(
        (_) => fallbackToMock = true, (value) => playlists = value);

    if (tracks.isEmpty && playlists.isEmpty) {
      fallbackToMock = true;
    }

    if (fallbackToMock) {
      emit(
        LibraryLoaded(
          tracks: tracks.isEmpty ? MockLibraryData.generations(uid) : tracks,
          playlists:
              playlists.isEmpty ? MockLibraryData.playlists(uid) : playlists,
          usingMockData: true,
        ),
      );
      return;
    }

    emit(LibraryLoaded(
        tracks: tracks, playlists: playlists, usingMockData: false));
  }

  Future<Failure?> renameTrack(String trackId, String nextPrompt) async {
    final current = _loadedState();
    if (current == null) return null;

    if (_isMockTrack(trackId)) {
      final updated = current.tracks
          .map((track) => track.id == trackId
              ? GenerationEntity(
                  id: track.id,
                  uid: track.uid,
                  prompt: nextPrompt,
                  mood: track.mood,
                  genre: track.genre,
                  bpm: track.bpm,
                  status: track.status,
                  createdAt: track.createdAt,
                  durationSeconds: track.durationSeconds,
                  audioUrl: track.audioUrlNullable,
                  coverUrl: track.coverUrl,
                  errorMessage: track.errorMessage,
                  parentId: track.parentId,
                  isPublic: track.isPublic,
                  shareSlug: track.shareSlug,
                )
              : track)
          .toList();
      emit(LibraryLoaded(
        tracks: updated,
        playlists: current.playlists,
        usingMockData: current.usingMockData,
      ));
      return null;
    }

    final result = await _updateGenerationUsecase(trackId, prompt: nextPrompt);
    return result.fold((failure) => failure, (updatedTrack) {
      final nextTracks = current.tracks
          .map((track) => track.id == trackId ? updatedTrack : track)
          .toList();
      emit(LibraryLoaded(
        tracks: nextTracks,
        playlists: current.playlists,
        usingMockData: current.usingMockData,
      ));
      return null;
    });
  }

  Future<Failure?> deleteTrack(String trackId) async {
    final current = _loadedState();
    if (current == null) return null;

    if (_isMockTrack(trackId)) {
      emit(
        LibraryLoaded(
          tracks: current.tracks.where((track) => track.id != trackId).toList(),
          playlists: current.playlists
              .map(
                (playlist) => PlaylistEntity(
                  id: playlist.id,
                  uid: playlist.uid,
                  name: playlist.name,
                  description: playlist.description,
                  visibility: playlist.visibility,
                  trackIds:
                      playlist.trackIds.where((id) => id != trackId).toList(),
                  createdAt: playlist.createdAt,
                  updatedAt: playlist.updatedAt,
                ),
              )
              .toList(),
          usingMockData: current.usingMockData,
        ),
      );
      return null;
    }

    final result = await _deleteGenerationUsecase(trackId);
    return result.fold((failure) => failure, (_) {
      emit(
        LibraryLoaded(
          tracks: current.tracks.where((track) => track.id != trackId).toList(),
          playlists: current.playlists
              .map(
                (playlist) => PlaylistEntity(
                  id: playlist.id,
                  uid: playlist.uid,
                  name: playlist.name,
                  description: playlist.description,
                  visibility: playlist.visibility,
                  trackIds:
                      playlist.trackIds.where((id) => id != trackId).toList(),
                  createdAt: playlist.createdAt,
                  updatedAt: playlist.updatedAt,
                ),
              )
              .toList(),
          usingMockData: current.usingMockData,
        ),
      );
      return null;
    });
  }

  Future<Failure?> createPlaylist({
    required String uid,
    required String name,
    String? description,
  }) async {
    final current = _loadedState();
    if (current == null) return null;

    if (current.usingMockData) {
      final playlist = PlaylistEntity(
        id: 'mock-playlist-${DateTime.now().millisecondsSinceEpoch}',
        uid: uid,
        name: name,
        description: description,
        visibility: PlaylistVisibility.private,
        trackIds: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      emit(
        LibraryLoaded(
          tracks: current.tracks,
          playlists: [playlist, ...current.playlists],
          usingMockData: true,
        ),
      );
      return null;
    }

    final result =
        await _createPlaylistUsecase(name: name, description: description);
    return result.fold((failure) => failure, (playlist) {
      emit(
        LibraryLoaded(
          tracks: current.tracks,
          playlists: [playlist, ...current.playlists],
          usingMockData: false,
        ),
      );
      return null;
    });
  }

  Future<Failure?> renamePlaylist(
      String playlistId, String name, String? description) async {
    final current = _loadedState();
    if (current == null) return null;

    if (_isMockPlaylist(playlistId)) {
      emit(
        LibraryLoaded(
          tracks: current.tracks,
          playlists: current.playlists
              .map(
                (playlist) => playlist.id == playlistId
                    ? PlaylistEntity(
                        id: playlist.id,
                        uid: playlist.uid,
                        name: name,
                        description: description,
                        visibility: playlist.visibility,
                        trackIds: playlist.trackIds,
                        createdAt: playlist.createdAt,
                        updatedAt: DateTime.now(),
                      )
                    : playlist,
              )
              .toList(),
          usingMockData: current.usingMockData,
        ),
      );
      return null;
    }

    final result = await _updatePlaylistUsecase(
      playlistId,
      name: name,
      description: description,
    );
    return result.fold((failure) => failure, (updated) {
      emit(
        LibraryLoaded(
          tracks: current.tracks,
          playlists: current.playlists
              .map((playlist) => playlist.id == playlistId ? updated : playlist)
              .toList(),
          usingMockData: current.usingMockData,
        ),
      );
      return null;
    });
  }

  Future<Failure?> deletePlaylist(String playlistId) async {
    final current = _loadedState();
    if (current == null) return null;

    if (_isMockPlaylist(playlistId)) {
      emit(
        LibraryLoaded(
          tracks: current.tracks,
          playlists: current.playlists
              .where((playlist) => playlist.id != playlistId)
              .toList(),
          usingMockData: current.usingMockData,
        ),
      );
      return null;
    }

    final result = await _deletePlaylistUsecase(playlistId);
    return result.fold((failure) => failure, (_) {
      emit(
        LibraryLoaded(
          tracks: current.tracks,
          playlists: current.playlists
              .where((playlist) => playlist.id != playlistId)
              .toList(),
          usingMockData: current.usingMockData,
        ),
      );
      return null;
    });
  }

  Future<Failure?> addTrackToPlaylist(String playlistId, String trackId) async {
    final current = _loadedState();
    if (current == null) return null;

    if (_isMockPlaylist(playlistId) || current.usingMockData) {
      final updatedPlaylists = current.playlists
          .map((playlist) => playlist.id == playlistId
              ? PlaylistEntity(
                  id: playlist.id,
                  uid: playlist.uid,
                  name: playlist.name,
                  description: playlist.description,
                  visibility: playlist.visibility,
                  trackIds: playlist.trackIds.contains(trackId)
                      ? playlist.trackIds
                      : [...playlist.trackIds, trackId],
                  createdAt: playlist.createdAt,
                  updatedAt: DateTime.now(),
                )
              : playlist)
          .toList();
      emit(LibraryLoaded(
        tracks: current.tracks,
        playlists: updatedPlaylists,
        usingMockData: current.usingMockData,
      ));
      return null;
    }

    final result = await _addTrackToPlaylistUsecase(playlistId, trackId);
    return result.fold((failure) => failure, (updated) {
      emit(LibraryLoaded(
        tracks: current.tracks,
        playlists: current.playlists
            .map((playlist) => playlist.id == playlistId ? updated : playlist)
            .toList(),
        usingMockData: current.usingMockData,
      ));
      return null;
    });
  }

  Future<Failure?> removeTrackFromPlaylist(
      String playlistId, String trackId) async {
    final current = _loadedState();
    if (current == null) return null;

    if (_isMockPlaylist(playlistId) || current.usingMockData) {
      final updatedPlaylists = current.playlists
          .map((playlist) => playlist.id == playlistId
              ? PlaylistEntity(
                  id: playlist.id,
                  uid: playlist.uid,
                  name: playlist.name,
                  description: playlist.description,
                  visibility: playlist.visibility,
                  trackIds:
                      playlist.trackIds.where((id) => id != trackId).toList(),
                  createdAt: playlist.createdAt,
                  updatedAt: DateTime.now(),
                )
              : playlist)
          .toList();
      emit(LibraryLoaded(
        tracks: current.tracks,
        playlists: updatedPlaylists,
        usingMockData: current.usingMockData,
      ));
      return null;
    }

    final result = await _removeTrackFromPlaylistUsecase(playlistId, trackId);
    return result.fold((failure) => failure, (updated) {
      emit(LibraryLoaded(
        tracks: current.tracks,
        playlists: current.playlists
            .map((playlist) => playlist.id == playlistId ? updated : playlist)
            .toList(),
        usingMockData: current.usingMockData,
      ));
      return null;
    });
  }

  LibraryLoaded? _loadedState() {
    final current = state;
    return current is LibraryLoaded ? current : null;
  }

  bool _isMockTrack(String id) => id.startsWith('mock-');
  bool _isMockPlaylist(String id) => id.startsWith('mock-');
}
