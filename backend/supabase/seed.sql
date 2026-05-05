insert into public.songs (id, title, artist, duration, release_date, cover_url, audio_url)
values
  ('11111111-1111-1111-1111-111111111111', 'Midnight Aurora', 'MuseAI Demo', 182, '2026-01-01T00:00:00+00:00', 'https://picsum.photos/seed/museai-demo-1/600/600', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
  ('22222222-2222-2222-2222-222222222222', 'Neon Skyline', 'MuseAI Demo', 205, '2026-01-02T00:00:00+00:00', 'https://picsum.photos/seed/museai-demo-2/600/600', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'),
  ('33333333-3333-3333-3333-333333333333', 'Lofi Rain Circuit', 'MuseAI Demo', 194, '2026-01-03T00:00:00+00:00', 'https://picsum.photos/seed/museai-demo-3/600/600', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'),
  ('44444444-4444-4444-4444-444444444444', 'Solar Pulse', 'MuseAI Demo', 176, '2026-01-04T00:00:00+00:00', 'https://picsum.photos/seed/museai-demo-4/600/600', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3'),
  ('55555555-5555-5555-5555-555555555555', 'Velvet Drive', 'MuseAI Demo', 212, '2026-01-05T00:00:00+00:00', 'https://picsum.photos/seed/museai-demo-5/600/600', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3')
on conflict (id) do update set
  title = excluded.title,
  artist = excluded.artist,
  duration = excluded.duration,
  release_date = excluded.release_date,
  cover_url = excluded.cover_url,
  audio_url = excluded.audio_url;
