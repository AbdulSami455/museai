// This cubit manages state updates for song browsing and playback.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:museai/domain/entities/playable.dart';
import 'package:museai/presentation/song_player/bloc/song_player_state.dart';

class SongPlayerCubit extends Cubit<SongPlayerState> {
  AudioPlayer audioPlayer = AudioPlayer();

  Duration songDuration = Duration.zero;
  Duration songPosition = Duration.zero;

  SongPlayerCubit() : super(SongPlayerLoading()) {
    audioPlayer.positionStream.listen((position) {
      songPosition = position;
      updateSongPlayer();
    });

    audioPlayer.durationStream.listen((duration) {
      songDuration = duration ?? Duration.zero;
      updateSongPlayer();
    });
  }

  void updateSongPlayer() {
    emit(SongPlayerLoaded());
  }

  Future<void> loadSong(Playable song) async {
    try {
      await audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(song.audioUrl),
          tag: MediaItem(
            id: song.audioUrl,
            album: song.artist,
            title: song.title,
            artUri: song.coverUrl != null ? Uri.parse(song.coverUrl!) : null,
          ),
        ),
      );
      audioPlayer.play();
      emit(SongPlayerLoaded());
    } catch (e) {
      emit(SongPlayerFailure());
    }
  }

  void playOrPauseSong() {
    if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }
    emit(SongPlayerLoaded());
  }

  void jumpTo(Duration position) {
    audioPlayer.seek(position);
    emit(SongPlayerLoaded());
  }

  @override
  Future<void> close() {
    audioPlayer.dispose();
    return super.close();
  }
}
