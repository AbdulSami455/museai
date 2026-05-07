// This file contains supporting logic for domain logic.

abstract class Playable {
  String get audioUrl;
  String get title;
  String? get coverUrl;
  String? get artist;
}
