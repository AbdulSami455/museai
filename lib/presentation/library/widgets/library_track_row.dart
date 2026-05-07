// This file contains supporting logic for the library section.

import 'package:flutter/material.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';

class LibraryTrackRow extends StatelessWidget {
  final GenerationEntity track;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onAddToPlaylist;
  final VoidCallback onDelete;

  const LibraryTrackRow({
    super.key,
    required this.track,
    required this.subtitle,
    required this.onTap,
    required this.onRename,
    required this.onAddToPlaylist,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (track.status) {
      GenerationStatus.completed => const Color(0xFF4ADE80),
      GenerationStatus.processing => const Color(0xFFF59E0B),
      GenerationStatus.failed => const Color(0xFFFB7185),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: track.coverUrl == null
                    ? null
                    : DecorationImage(
                        image: NetworkImage(track.coverUrl!),
                        fit: BoxFit.cover,
                      ),
                gradient: track.coverUrl == null
                    ? const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: Icon(
                track.status == GenerationStatus.processing
                    ? Icons.auto_awesome
                    : Icons.play_arrow_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.prompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.66),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            PopupMenuButton<String>(
              color: const Color(0xFF111827),
              onSelected: (value) {
                switch (value) {
                  case 'rename':
                    onRename();
                    break;
                  case 'playlist':
                    onAddToPlaylist();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(
                    value: 'playlist', child: Text('Add to playlist')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
