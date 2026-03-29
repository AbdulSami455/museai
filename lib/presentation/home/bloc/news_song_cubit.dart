import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/usecases/song/get_news_song.dart';
import 'package:museai/service_locator.dart';
import 'news_song_state.dart';

class NewsSongCubit extends Cubit<NewsSongState> {
  NewsSongCubit() : super(NewsSongLoading());

  Future<void> getNewsSongs() async {
    emit(NewsSongLoading());
    final result = await sl<GetNewsSongUsecase>().call();
    result.fold(
      (failure) {
        final message = failure is SongFailure
            ? failure.message
            : failure is NetworkFailure
                ? failure.message
                : 'Failed to load songs';
        emit(NewsSongError(message: message));
      },
      (songs) => emit(NewsSongLoaded(songs: songs)),
    );
  }
}
