import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:museai/domain/usecases/song/get_news_song.dart';
import 'package:museai/service_locator.dart';
import 'news_song_state.dart';

class NewsSongCubit extends Cubit<NewsSongState> {
  NewsSongCubit():super(NewsSongLoading());

  Future<void> getNewsSongs() async {
    var returnedSongs = await sl<GetNewsSongUsecase>().call();

    returnedSongs.fold((l) {
      emit(NewsSongError());
    }, (r) {
      emit(NewsSongLoaded(songs: r));
    });
  }
}
