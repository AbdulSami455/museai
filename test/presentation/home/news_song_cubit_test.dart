import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/song/song_entity.dart';
import 'package:museai/domain/usecases/song/get_news_song.dart';
import 'package:museai/domain/repository/song/song_repository.dart';
import 'package:museai/presentation/home/bloc/news_song_cubit.dart';
import 'package:museai/presentation/home/bloc/news_song_state.dart';

class MockSongRepository extends Mock implements SongRepository {}

void main() {
  late MockSongRepository mockRepo;
  late GetNewsSongUsecase usecase;
  final sl = GetIt.instance;

  setUp(() {
    mockRepo = MockSongRepository();
    usecase = GetNewsSongUsecase(mockRepo);
    sl.registerSingleton<GetNewsSongUsecase>(usecase);
  });

  tearDown(() async {
    await sl.reset();
  });

  final fakeSongs = [
    const SongEntity(
      title: 'Test Song',
      artist: 'Test Artist',
      duration: 3.0,
      songUrl: 'https://example.com/song.mp3',
      coverUrl: 'https://example.com/cover.jpg',
    ),
  ];

  blocTest<NewsSongCubit, NewsSongState>(
    'emits [Loading, Loaded] when songs load successfully',
    build: () {
      when(() => mockRepo.getNewsSongs())
          .thenAnswer((_) async => Right(fakeSongs));
      return NewsSongCubit();
    },
    act: (cubit) => cubit.getNewsSongs(),
    expect: () => [
      isA<NewsSongLoading>(),
      isA<NewsSongLoaded>(),
    ],
  );

  blocTest<NewsSongCubit, NewsSongState>(
    'emits [Loading, Error] with message when SongFailure occurs',
    build: () {
      when(() => mockRepo.getNewsSongs()).thenAnswer(
          (_) async => const Left(SongFailure(message: 'No songs available')));
      return NewsSongCubit();
    },
    act: (cubit) => cubit.getNewsSongs(),
    expect: () => [
      isA<NewsSongLoading>(),
      isA<NewsSongError>()
          .having((e) => e.message, 'message', 'No songs available'),
    ],
  );

  blocTest<NewsSongCubit, NewsSongState>(
    'emits [Loading, Error] with message when NetworkFailure occurs',
    build: () {
      when(() => mockRepo.getNewsSongs()).thenAnswer((_) async =>
          const Left(NetworkFailure(message: 'No internet connection')));
      return NewsSongCubit();
    },
    act: (cubit) => cubit.getNewsSongs(),
    expect: () => [
      isA<NewsSongLoading>(),
      isA<NewsSongError>()
          .having((e) => e.message, 'message', 'No internet connection'),
    ],
  );
}
