import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:museai/domain/entities/song/song_entity.dart';
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
      songDuration = duration!;
    });
  }

  void updateSongPlayer() {
    emit(SongPlayerLoaded());
  }

  Future<void> loadSong(SongEntity song) async {
    try {
      await audioPlayer.setUrl(song.songUrl!);
      audioPlayer.play();
      AudioSource.uri(
        Uri.parse(song.songUrl!),
        tag: MediaItem(
          id: '1',
          album: song.artist,
          title: song.title!,
          artUri: Uri.parse(song.coverUrl!),
        ),
      );
      emit(SongPlayerLoaded());
    } catch (e) {
      emit(SongPlayerFailure());
    }
  }

  void playOrPauseSong() {
    if (audioPlayer.playing) {
      audioPlayer.stop();
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
