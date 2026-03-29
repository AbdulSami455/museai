import 'package:get_it/get_it.dart';
import 'package:museai/data/repository/auth/auth_repository_impl.dart';
import 'package:museai/data/repository/song/song_repository_impl.dart';
import 'package:museai/data/source/auth/auth_firebase_service.dart';
import 'package:museai/data/source/auth/auth_firebase_service_impl.dart';
import 'package:museai/data/source/song/song_firebase_service.dart';
import 'package:museai/data/source/song/song_firebase_service_impl.dart';
import 'package:museai/domain/repository/auth/auth_repository.dart';
import 'package:museai/domain/repository/song/song_repository.dart';
import 'package:museai/domain/usecases/auth/signin_usecase.dart';
import 'package:museai/domain/usecases/auth/signup_usecase.dart';
import 'package:museai/domain/usecases/song/get_news_song.dart';
import 'package:museai/presentation/song_player/bloc/song_player_cubit.dart';

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
}
