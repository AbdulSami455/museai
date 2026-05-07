// This file defines state objects used in song browsing and playback.

abstract class SongPlayerState {}

class SongPlayerLoading extends SongPlayerState {}

class SongPlayerLoaded extends SongPlayerState {}

class SongPlayerFailure extends SongPlayerState {}
