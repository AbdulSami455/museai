// This file registers dependencies and wires services for injection.

import 'package:get_it/get_it.dart';
import 'package:museai/data/repository/auth/auth_repository_impl.dart';
import 'package:museai/data/repository/generation/generation_repository_impl.dart';
import 'package:museai/data/repository/playlist_repository_impl.dart';
import 'package:museai/data/repository/song/song_repository_impl.dart';
import 'package:museai/data/source/auth/auth_service.dart';
import 'package:museai/data/source/auth/supabase_auth_service.dart';
import 'package:museai/data/source/generation/generation_service.dart';
import 'package:museai/data/source/generation/supabase_generation_service.dart';
import 'package:museai/data/source/playlist/backend_playlist_service.dart';
import 'package:museai/data/source/playlist/playlist_service.dart';
import 'package:museai/data/source/song/backend_song_service.dart';
import 'package:museai/data/source/song/song_service.dart';
import 'package:museai/domain/repository/auth/auth_repository.dart';
import 'package:museai/domain/repository/generation/generation_repository.dart';
import 'package:museai/domain/repository/playlist/playlist_repository.dart';
import 'package:museai/domain/repository/song/song_repository.dart';
import 'package:museai/domain/usecases/auth/signin_usecase.dart';
import 'package:museai/domain/usecases/auth/signup_usecase.dart';
import 'package:museai/domain/usecases/generation/create_generation_usecase.dart';
import 'package:museai/domain/usecases/generation/delete_generation_usecase.dart';
import 'package:museai/domain/usecases/generation/get_user_generations_usecase.dart';
import 'package:museai/domain/usecases/generation/update_generation_usecase.dart';
import 'package:museai/domain/usecases/generation/watch_generation_usecase.dart';
import 'package:museai/domain/usecases/playlist/add_track_to_playlist_usecase.dart';
import 'package:museai/domain/usecases/playlist/create_playlist_usecase.dart';
import 'package:museai/domain/usecases/playlist/delete_playlist_usecase.dart';
import 'package:museai/domain/usecases/playlist/get_user_playlists_usecase.dart';
import 'package:museai/domain/usecases/playlist/remove_track_from_playlist_usecase.dart';
import 'package:museai/domain/usecases/playlist/update_playlist_usecase.dart';
import 'package:museai/domain/usecases/song/get_news_song.dart';
import 'package:museai/presentation/library/bloc/library_cubit.dart';
import 'package:museai/presentation/library/bloc/playlist_cubit.dart';
import 'package:museai/presentation/song_player/bloc/song_player_cubit.dart';
import 'package:museai/presentation/studio/bloc/studio_cubit.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  sl.registerSingleton<AuthService>(SupabaseAuthService());

  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(sl<AuthService>()),
  );

  sl.registerSingleton<SongService>(BackendSongService());

  sl.registerSingleton<SongRepository>(
    SongRepositoryImpl(sl<SongService>()),
  );

  sl.registerSingleton<SignUpUsecase>(SignUpUsecase(sl<AuthRepository>()));
  sl.registerSingleton<SignInUsecase>(SignInUsecase(sl<AuthRepository>()));
  sl.registerSingleton<GetNewsSongUsecase>(
      GetNewsSongUsecase(sl<SongRepository>()));

  sl.registerLazySingleton<SongPlayerCubit>(() => SongPlayerCubit());

  // Generation — service, repository, use cases, cubit
  sl.registerSingleton<GenerationService>(SupabaseGenerationService());

  sl.registerSingleton<GenerationRepository>(
    GenerationRepositoryImpl(sl<GenerationService>()),
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
  sl.registerSingleton<UpdateGenerationUsecase>(
    UpdateGenerationUsecase(sl<GenerationRepository>()),
  );
  sl.registerSingleton<DeleteGenerationUsecase>(
    DeleteGenerationUsecase(sl<GenerationRepository>()),
  );

  sl.registerSingleton<PlaylistService>(BackendPlaylistService());
  sl.registerSingleton<PlaylistRepository>(
    PlaylistRepositoryImpl(sl<PlaylistService>()),
  );
  sl.registerSingleton<GetUserPlaylistsUsecase>(
    GetUserPlaylistsUsecase(sl<PlaylistRepository>()),
  );
  sl.registerSingleton<CreatePlaylistUsecase>(
    CreatePlaylistUsecase(sl<PlaylistRepository>()),
  );
  sl.registerSingleton<UpdatePlaylistUsecase>(
    UpdatePlaylistUsecase(sl<PlaylistRepository>()),
  );
  sl.registerSingleton<DeletePlaylistUsecase>(
    DeletePlaylistUsecase(sl<PlaylistRepository>()),
  );
  sl.registerSingleton<AddTrackToPlaylistUsecase>(
    AddTrackToPlaylistUsecase(sl<PlaylistRepository>()),
  );
  sl.registerSingleton<RemoveTrackFromPlaylistUsecase>(
    RemoveTrackFromPlaylistUsecase(sl<PlaylistRepository>()),
  );

  sl.registerLazySingleton<StudioCubit>(
    () => StudioCubit(
      createGenerationUsecase: sl<CreateGenerationUsecase>(),
      watchGenerationUsecase: sl<WatchGenerationUsecase>(),
    ),
  );
  sl.registerLazySingleton<LibraryCubit>(
    () => LibraryCubit(
      getUserGenerationsUsecase: sl<GetUserGenerationsUsecase>(),
      updateGenerationUsecase: sl<UpdateGenerationUsecase>(),
      deleteGenerationUsecase: sl<DeleteGenerationUsecase>(),
      getUserPlaylistsUsecase: sl<GetUserPlaylistsUsecase>(),
      createPlaylistUsecase: sl<CreatePlaylistUsecase>(),
      updatePlaylistUsecase: sl<UpdatePlaylistUsecase>(),
      deletePlaylistUsecase: sl<DeletePlaylistUsecase>(),
      addTrackToPlaylistUsecase: sl<AddTrackToPlaylistUsecase>(),
      removeTrackFromPlaylistUsecase: sl<RemoveTrackFromPlaylistUsecase>(),
    ),
  );
  sl.registerFactory<PlaylistCubit>(() => PlaylistCubit());
}
