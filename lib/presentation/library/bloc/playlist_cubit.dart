// This cubit manages state updates for the library section.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/entities/playlist/playlist_entity.dart';
import 'package:museai/presentation/library/bloc/playlist_state.dart';

class PlaylistCubit extends Cubit<PlaylistState> {
  PlaylistCubit() : super(const PlaylistIdle());

  void selectPlaylist(
      PlaylistEntity playlist, List<GenerationEntity> allTracks) {
    final tracks = <GenerationEntity>[];
    for (final trackId in playlist.trackIds) {
      for (final track in allTracks) {
        if (track.id == trackId) {
          tracks.add(track);
          break;
        }
      }
    }
    emit(PlaylistLoaded(playlist: playlist, tracks: tracks));
  }
}
