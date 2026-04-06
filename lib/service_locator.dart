import 'package:get_it/get_it.dart';
import 'package:museai/data/repository/auth/auth_repository_impl.dart';
import 'package:museai/data/repository/generation/generation_repository_impl.dart';
import 'package:museai/data/repository/song/song_repository_impl.dart';
import 'package:museai/data/source/auth/auth_firebase_service.dart';
import 'package:museai/data/source/auth/auth_firebase_service_impl.dart';
import 'package:museai/data/source/generation/generation_firebase_service.dart';
import 'package:museai/data/source/generation/generation_stub_service.dart';
import 'package:museai/data/source/song/song_firebase_service.dart';
import 'package:museai/data/source/song/song_firebase_service_impl.dart';
import 'package:museai/domain/repository/auth/auth_repository.dart';
import 'package:museai/domain/repository/generation/generation_repository.dart';
import 'package:museai/domain/repository/song/song_repository.dart';
import 'package:museai/domain/usecases/auth/signin_usecase.dart';
import 'package:museai/domain/usecases/auth/signup_usecase.dart';
import 'package:museai/domain/usecases/generation/create_generation_usecase.dart';
import 'package:museai/domain/usecases/generation/get_user_generations_usecase.dart';
import 'package:museai/domain/usecases/generation/watch_generation_usecase.dart';
import 'package:museai/domain/usecases/song/get_news_song.dart';
import 'package:museai/presentation/song_player/bloc/song_player_cubit.dart';
import 'package:museai/presentation/studio/bloc/studio_cubit.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  sl.registerSingleton<AuthFirebaseService>(AuthFirebaseServiceImpl());

  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(sl<AuthFirebaseService>()),
  );

  sl.registerSingleton<SongFirebaseService>(SongFirebaseServiceImpl());

  sl.registerSingleton<SongRepository>(
    SongRepositoryImpl(sl<SongFirebaseService>()),
  );

  sl.registerSingleton<SignUpUsecase>(SignUpUsecase(sl<AuthRepository>()));
  sl.registerSingleton<SignInUsecase>(SignInUsecase(sl<AuthRepository>()));
  sl.registerSingleton<GetNewsSongUsecase>(GetNewsSongUsecase(sl<SongRepository>()));

  sl.registerLazySingleton<SongPlayerCubit>(() => SongPlayerCubit());

  // Generation — service, repository, use cases, cubit
  sl.registerSingleton<GenerationFirebaseService>(GenerationStubService());

  sl.registerSingleton<GenerationRepository>(
    GenerationRepositoryImpl(sl<GenerationFirebaseService>()),
  );

  sl.registerSingleton<CreateGenerationUsecase>(
    CreateGenerationUsecase(sl<GenerationRepository>()),
  );
  sl.registerSingleton<WatchGenerationUsecase>(
    WatchGenerationUsecase(sl<GenerationRepository>()),
  );
  sl.registerSingleton<GetUserGenerationsUsecase>(
    GetUserGenerationsUsecase(sl<GenerationRepository>()),
  );

  sl.registerLazySingleton<StudioCubit>(
    () => StudioCubit(
      createGenerationUsecase: sl<CreateGenerationUsecase>(),
      watchGenerationUsecase: sl<WatchGenerationUsecase>(),
    ),
  );
}
