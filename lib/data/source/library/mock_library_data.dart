// This file contains supporting logic for the library section.

import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/entities/playlist/playlist_entity.dart';

class MockLibraryData {
  static List<GenerationEntity> generations(String uid) => [
        GenerationEntity(
          id: 'mock-gen-001',
          uid: uid,
          prompt: 'Neon city drive with punchy synth bass',
          mood: 'Energetic',
          genre: 'Electronic',
          bpm: 126,
          status: GenerationStatus.completed,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          durationSeconds: 30,
          audioUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          coverUrl: 'https://picsum.photos/seed/museai-gen-1/600/600',
          isPublic: true,
          shareSlug: 'mockshare001',
        ),
        GenerationEntity(
          id: 'mock-gen-002',
          uid: uid,
          prompt: 'Warm lo-fi piano with rain ambience',
          mood: 'Calm',
          genre: 'Ambient',
          bpm: 88,
          status: GenerationStatus.completed,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          durationSeconds: 45,
          audioUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          coverUrl: 'https://picsum.photos/seed/museai-gen-2/600/600',
        ),
        GenerationEntity(
          id: 'mock-gen-003',
          uid: uid,
          prompt: 'Late-night jazz trio with upright bass',
          mood: 'Romantic',
          genre: 'Jazz',
          bpm: 102,
          status: GenerationStatus.processing,
          createdAt: DateTime.now().subtract(const Duration(minutes: 22)),
          durationSeconds: 30,
          coverUrl: 'https://picsum.photos/seed/museai-gen-3/600/600',
        ),
      ];

  static List<PlaylistEntity> playlists(String uid) => [
        PlaylistEntity(
          id: 'mock-playlist-001',
          uid: uid,
          name: 'Late Night Drafts',
          description:
              'Best tracks for editing, journaling, and long focus blocks.',
          visibility: PlaylistVisibility.private,
          trackIds: const ['mock-gen-001', 'mock-gen-002'],
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        PlaylistEntity(
          id: 'mock-playlist-002',
          uid: uid,
          name: 'Shareable Cuts',
          description: 'Tracks ready to export and post.',
          visibility: PlaylistVisibility.public,
          trackIds: const ['mock-gen-001'],
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
}
