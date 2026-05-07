import 'package:museai/domain/entities/generation/generation_entity.dart';

class GenerationModel extends GenerationEntity {
  const GenerationModel({
    required super.id,
    required super.uid,
    required super.prompt,
    required super.mood,
    required super.genre,
    required super.bpm,
    required super.status,
    required super.createdAt,
    super.durationSeconds,
    super.audioUrl,
    super.coverUrl,
    super.errorMessage,
    super.parentId,
    super.isPublic,
    super.shareSlug,
  });

  factory GenerationModel.fromMap(Map<String, dynamic> map) {
    return GenerationModel(
      id: map['id'] as String,
      uid: map['uid'] as String,
      prompt: map['prompt'] as String,
      mood: map['mood'] as String,
      genre: map['genre'] as String,
      bpm: map['bpm'] as int,
      status: _parseStatus(map['status'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      durationSeconds: map['duration_seconds'] as int?,
      audioUrl: map['audio_url'] as String?,
      coverUrl: map['cover_url'] as String?,
      errorMessage: map['error_message'] as String?,
      parentId: map['parent_id'] as String?,
      isPublic: map['is_public'] as bool? ?? false,
      shareSlug: map['share_slug'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'prompt': prompt,
      'mood': mood,
      'genre': genre,
      'bpm': bpm,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'duration_seconds': durationSeconds,
      'audio_url': audioUrlNullable,
      'cover_url': coverUrl,
      'error_message': errorMessage,
      'parent_id': parentId,
      'is_public': isPublic,
      'share_slug': shareSlug,
    };
  }

  static GenerationStatus _parseStatus(String? value) {
    switch (value) {
      case 'completed':
        return GenerationStatus.completed;
      case 'failed':
        return GenerationStatus.failed;
      default:
        return GenerationStatus.processing;
    }
  }
}
