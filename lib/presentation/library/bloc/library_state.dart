// This file defines state objects used in the library section.

import 'package:equatable/equatable.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/entities/playlist/playlist_entity.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

class LibraryLoading extends LibraryState {
  const LibraryLoading();
}

class LibraryLoaded extends LibraryState {
  final List<GenerationEntity> tracks;
  final List<PlaylistEntity> playlists;
  final bool usingMockData;

  const LibraryLoaded({
    required this.tracks,
    required this.playlists,
    required this.usingMockData,
  });

  @override
  List<Object?> get props => [tracks, playlists, usingMockData];
}

class LibraryError extends LibraryState {
  final String message;

  const LibraryError(this.message);

  @override
  List<Object?> get props => [message];
}
