import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/usecases/generation/create_generation_usecase.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';
import 'package:museai/domain/usecases/generation/watch_generation_usecase.dart';
import 'package:museai/presentation/studio/bloc/studio_cubit.dart';
import 'package:museai/presentation/studio/bloc/studio_state.dart';

class MockCreateGenerationUsecase extends Mock implements CreateGenerationUsecase {}
class MockWatchGenerationUsecase extends Mock implements WatchGenerationUsecase {}

final _completedEntity = GenerationEntity(
  id: 'id1',
  uid: 'uid1',
  prompt: 'test',
  mood: 'Happy',
  genre: 'Pop',
  bpm: 120,
  status: GenerationStatus.completed,
  createdAt: DateTime(2026, 1, 1),
  audioUrl: 'https://example.com/audio.mp3',
);

const _params = GenerationParams(
  uid: 'uid1',
  prompt: 'test',
  mood: 'Happy',
  genre: 'Pop',
  bpm: 120,
);

void main() {
  late MockCreateGenerationUsecase mockCreate;
  late MockWatchGenerationUsecase mockWatch;

  setUp(() {
    mockCreate = MockCreateGenerationUsecase();
    mockWatch = MockWatchGenerationUsecase();
  });

  setUpAll(() {
    registerFallbackValue(_params);
    registerFallbackValue(const WatchGenerationParams(uid: '', generationId: ''));
  });

  StudioCubit buildCubit() => StudioCubit(
    createGenerationUsecase: mockCreate,
    watchGenerationUsecase: mockWatch,
  );

  group('submit', () {
    blocTest<StudioCubit, StudioState>(
      'Idle → Submitting → Processing → Completed on happy path',
      build: buildCubit,
      setUp: () {
        when(() => mockCreate(any()))
            .thenAnswer((_) async => const Right('gen-1'));
        when(() => mockWatch(any()))
            .thenAnswer((_) => Stream.value(Right(_completedEntity)));
      },
      act: (cubit) => cubit.submit(_params),
      expect: () => [
        const StudioSubmitting(),
        const StudioProcessing(generationId: 'gen-1'),
        StudioCompleted(generation: _completedEntity),
      ],
    );

    blocTest<StudioCubit, StudioState>(
      'emits StudioFailed when createGeneration fails',
      build: buildCubit,
      setUp: () {
        when(() => mockCreate(any()))
            .thenAnswer((_) async => const Left(GenerationFailure(message: 'create error')));
      },
      act: (cubit) => cubit.submit(_params),
      expect: () => [
        const StudioSubmitting(),
        const StudioFailed(message: 'create error'),
      ],
    );

    blocTest<StudioCubit, StudioState>(
      'emits StudioFailed when stream emits Left',
      build: buildCubit,
      setUp: () {
        when(() => mockCreate(any()))
            .thenAnswer((_) async => const Right('gen-1'));
        when(() => mockWatch(any()))
            .thenAnswer((_) => Stream.value(const Left(GenerationFailure(message: 'stream error'))));
      },
      act: (cubit) => cubit.submit(_params),
      expect: () => [
        const StudioSubmitting(),
        const StudioProcessing(generationId: 'gen-1'),
        const StudioFailed(message: 'stream error'),
      ],
    );

    blocTest<StudioCubit, StudioState>(
      'emits StudioFailed when completed entity has null audioUrl',
      build: buildCubit,
      setUp: () {
        final noAudioEntity = GenerationEntity(
          id: 'id1',
          uid: 'uid1',
          prompt: 'test',
          mood: 'Happy',
          genre: 'Pop',
          bpm: 120,
          status: GenerationStatus.completed,
          createdAt: DateTime(2026, 1, 1),
          // audioUrl is null
        );
        when(() => mockCreate(any()))
            .thenAnswer((_) async => const Right('gen-1'));
        when(() => mockWatch(any()))
            .thenAnswer((_) => Stream.value(Right(noAudioEntity)));
      },
      act: (cubit) => cubit.submit(_params),
      expect: () => [
        const StudioSubmitting(),
        const StudioProcessing(generationId: 'gen-1'),
        const StudioFailed(message: 'Generation completed but audio is unavailable.'),
      ],
    );

    blocTest<StudioCubit, StudioState>(
      'emits StudioFailed when entity status is failed',
      build: buildCubit,
      setUp: () {
        final failedEntity = GenerationEntity(
          id: 'id1',
          uid: 'uid1',
          prompt: 'test',
          mood: 'Happy',
          genre: 'Pop',
          bpm: 120,
          status: GenerationStatus.failed,
          createdAt: DateTime(2026, 1, 1),
          errorMessage: 'AI error',
        );
        when(() => mockCreate(any()))
            .thenAnswer((_) async => const Right('gen-1'));
        when(() => mockWatch(any()))
            .thenAnswer((_) => Stream.value(Right(failedEntity)));
      },
      act: (cubit) => cubit.submit(_params),
      expect: () => [
        const StudioSubmitting(),
        const StudioProcessing(generationId: 'gen-1'),
        const StudioFailed(message: 'AI error'),
      ],
    );

    blocTest<StudioCubit, StudioState>(
      'duplicate submit while Processing is a no-op',
      build: buildCubit,
      setUp: () {
        // Never completes — stream hangs
        when(() => mockCreate(any()))
            .thenAnswer((_) async => const Right('gen-1'));
        when(() => mockWatch(any()))
            .thenAnswer((_) => const Stream.empty());
      },
      act: (cubit) async {
        await cubit.submit(_params);
        await cubit.submit(_params); // should be no-op
      },
      expect: () => [
        const StudioSubmitting(),
        const StudioProcessing(generationId: 'gen-1'),
        // No additional Submitting state — second submit was ignored
      ],
      verify: (_) {
        // createGeneration called exactly once
        verify(() => mockCreate(any())).called(1);
      },
    );
  });

  group('retry', () {
    blocTest<StudioCubit, StudioState>(
      'retry from Failed emits StudioIdle',
      build: buildCubit,
      seed: () => const StudioFailed(message: 'some error'),
      act: (cubit) => cubit.retry(),
      expect: () => [const StudioIdle()],
    );
  });

  group('close', () {
    test('cancels subscription on close', () async {
      final streamController = StreamController<Either<Failure, GenerationEntity>>();
      when(() => mockCreate(any()))
          .thenAnswer((_) async => const Right('gen-1'));
      when(() => mockWatch(any()))
          .thenAnswer((_) => streamController.stream);

      final cubit = buildCubit();
      await cubit.submit(_params);
      await cubit.close();

      // Should not throw after close
      streamController.add(Right(_completedEntity));
      await streamController.close();
    });
  });
}
