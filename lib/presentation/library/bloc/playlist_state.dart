import 'package:equatable/equatable.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/entities/playlist/playlist_entity.dart';

abstract class PlaylistState extends Equatable {
  const PlaylistState();

  @override
  List<Object?> get props => [];
}

class PlaylistIdle extends PlaylistState {
  const PlaylistIdle();
}

class PlaylistLoaded extends PlaylistState {
  final PlaylistEntity playlist;
  final List<GenerationEntity> tracks;

  const PlaylistLoaded({required this.playlist, required this.tracks});

  @override
  List<Object?> get props => [playlist, tracks];
}
