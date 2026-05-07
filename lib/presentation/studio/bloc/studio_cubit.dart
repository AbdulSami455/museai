// This cubit manages state updates for the studio flow.

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/usecases/generation/create_generation_usecase.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';
import 'package:museai/domain/usecases/generation/watch_generation_usecase.dart';
import 'package:museai/presentation/studio/bloc/studio_state.dart';

class StudioCubit extends Cubit<StudioState> {
  final CreateGenerationUsecase _createGenerationUsecase;
  final WatchGenerationUsecase _watchGenerationUsecase;

  StreamSubscription? _generationSubscription;
  Timer? _timeoutTimer;

  StudioCubit({
    required CreateGenerationUsecase createGenerationUsecase,
    required WatchGenerationUsecase watchGenerationUsecase,
  })  : _createGenerationUsecase = createGenerationUsecase,
        _watchGenerationUsecase = watchGenerationUsecase,
        super(const StudioIdle());

  Future<void> submit(GenerationParams params) async {
    // Guard: no-op if already submitting or processing
    if (state is StudioSubmitting || state is StudioProcessing) return;

    emit(const StudioSubmitting());

    final result = await _createGenerationUsecase(params);

    result.fold(
      (failure) => emit(StudioFailed(message: failure.message)),
      (generationId) {
        emit(StudioProcessing(generationId: generationId));
        _startWatching(params.uid, generationId);
      },
    );
  }

  void _startWatching(String uid, String generationId) {
    _cancelActiveSubscription();

    _timeoutTimer = Timer(const Duration(minutes: 3), () {
      _cancelActiveSubscription();
      emit(const StudioFailed(
        message: 'Generation is taking longer than expected. Please try again.',
      ));
    });

    _generationSubscription = _watchGenerationUsecase(
      WatchGenerationParams(uid: uid, generationId: generationId),
    ).listen(
      (either) {
        either.fold(
          (failure) {
            _cancelActiveSubscription();
            emit(StudioFailed(message: failure.message));
          },
          (entity) {
            if (entity.status == GenerationStatus.completed) {
              if (entity.audioUrlNullable != null) {
                _cancelActiveSubscription();
                emit(StudioCompleted(generation: entity));
              } else {
                _cancelActiveSubscription();
                emit(const StudioFailed(
                  message: 'Generation completed but audio is unavailable.',
                ));
              }
            } else if (entity.status == GenerationStatus.failed) {
              _cancelActiveSubscription();
              emit(StudioFailed(
                message: entity.errorMessage ?? 'Generation failed.',
              ));
            }
            // processing: do nothing, keep waiting
          },
        );
      },
    );
  }

  void retry() {
    _cancelActiveSubscription();
    emit(const StudioIdle());
  }

  void _cancelActiveSubscription() {
    _generationSubscription?.cancel();
    _generationSubscription = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  @override
  Future<void> close() {
    _cancelActiveSubscription();
    return super.close();
  }
}
