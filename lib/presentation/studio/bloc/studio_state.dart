// This file defines state objects used in the studio flow.

import 'package:equatable/equatable.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';

abstract class StudioState extends Equatable {
  const StudioState();
}

class StudioIdle extends StudioState {
  const StudioIdle();
  @override
  List<Object?> get props => [];
}

class StudioSubmitting extends StudioState {
  const StudioSubmitting();
  @override
  List<Object?> get props => [];
}

class StudioProcessing extends StudioState {
  final String generationId;
  const StudioProcessing({required this.generationId});
  @override
  List<Object?> get props => [generationId];
}

class StudioCompleted extends StudioState {
  final GenerationEntity generation;
  const StudioCompleted({required this.generation});
  @override
  List<Object?> get props => [generation];
}

class StudioFailed extends StudioState {
  final String message;
  const StudioFailed({required this.message});
  @override
  List<Object?> get props => [message];
}
