import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:museai/presentation/song_player/bloc/song_player_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sl = GetIt.instance;

  setUp(() {
    sl.registerLazySingleton<SongPlayerCubit>(() => SongPlayerCubit());
  });

  tearDown(() async {
    await sl.reset();
  });

  test('SongPlayerCubit lazySingleton returns same instance', () {
    final instance1 = sl<SongPlayerCubit>();
    final instance2 = sl<SongPlayerCubit>();
    expect(identical(instance1, instance2), true);
  });
}
