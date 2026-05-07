// This file contains supporting logic for music generation.

class GenerationParams {
  final String uid;
  final String prompt;
  final String mood;
  final String genre;
  final int bpm;

  const GenerationParams({
    required this.uid,
    required this.prompt,
    required this.mood,
    required this.genre,
    required this.bpm,
  });
}
