class ArtistPlaceholder {
  final String name;
  final String genre;
  final String imageUrl;

  const ArtistPlaceholder({
    required this.name,
    required this.genre,
    required this.imageUrl,
  });
}

class PlaceholderArtists {
  static List<ArtistPlaceholder> get items => const [
        ArtistPlaceholder(
          name: 'Billie Eilish',
          genre: 'Alt Pop',
          imageUrl: 'https://picsum.photos/seed/artist-1/300/300',
        ),
        ArtistPlaceholder(
          name: 'The Weeknd',
          genre: 'R&B',
          imageUrl: 'https://picsum.photos/seed/artist-2/300/300',
        ),
        ArtistPlaceholder(
          name: 'Dua Lipa',
          genre: 'Dance Pop',
          imageUrl: 'https://picsum.photos/seed/artist-3/300/300',
        ),
        ArtistPlaceholder(
          name: 'Arijit Singh',
          genre: 'Bollywood',
          imageUrl: 'https://picsum.photos/seed/artist-4/300/300',
        ),
        ArtistPlaceholder(
          name: 'Talha Anjum',
          genre: 'Hip Hop',
          imageUrl: 'https://picsum.photos/seed/artist-5/300/300',
        ),
      ];
}
