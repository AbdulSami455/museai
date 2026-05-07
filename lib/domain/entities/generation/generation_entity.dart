// This entity represents core business data for music generation.

import 'package:equatable/equatable.dart';
import 'package:museai/domain/entities/playable.dart';

enum GenerationStatus { processing, completed, failed }

class GenerationEntity extends Equatable implements Playable {
  final String id;
  final String uid;
  final String prompt;
  final String mood;
  final String genre;
  final int bpm;
  final GenerationStatus status;
  final int? durationSeconds;
  final String? audioUrlNullable;
  @override
  final String? coverUrl;
  final DateTime createdAt;
  final String? errorMessage;
  final String? parentId;
  final bool isPublic;
  final String? shareSlug;

  const GenerationEntity({
    required this.id,
    required this.uid,
    required this.prompt,
    required this.mood,
    required this.genre,
    required this.bpm,
    required this.status,
    required this.createdAt,
    this.durationSeconds,
    String? audioUrl,
    this.coverUrl,
    this.errorMessage,
    this.parentId,
    this.isPublic = false,
    this.shareSlug,
  }) : audioUrlNullable = audioUrl;

  @override
  String get audioUrl => audioUrlNullable!;

  @override
  String get title => prompt;

  @override
  String? get artist => null;

  @override
  List<Object?> get props => [
        id,
        uid,
        prompt,
        mood,
        genre,
        bpm,
        status,
        durationSeconds,
        audioUrlNullable,
        coverUrl,
        createdAt,
        errorMessage,
        parentId,
        isPublic,
        shareSlug,
      ];
}
