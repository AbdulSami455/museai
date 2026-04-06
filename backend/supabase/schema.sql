create extension if not exists "pgcrypto";

create table if not exists public.users (
  id text primary key,
  email text unique,
  full_name text,
  photo_url text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.songs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  artist text,
  duration double precision,
  release_date timestamptz,
  cover_url text,
  audio_url text
);

create table if not exists public.generations (
  id text primary key,
  uid text not null,
  title text,
  prompt text not null,
  mood text not null,
  genre text not null,
  bpm integer not null,
  instruments jsonb not null default '[]'::jsonb,
  duration_seconds integer not null default 30,
  status text not null,
  audio_url text,
  cover_url text,
  audio_storage_path text,
  cover_storage_path text,
  error_message text,
  parent_id text,
  is_public boolean not null default false,
  share_slug text unique,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists generations_uid_created_at_idx
  on public.generations (uid, created_at desc);

create index if not exists generations_share_slug_idx
  on public.generations (share_slug);

create table if not exists public.playlists (
  id text primary key,
  uid text not null,
  name text not null,
  description text,
  visibility text not null default 'private',
  track_ids jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists playlists_uid_created_at_idx
  on public.playlists (uid, created_at desc);
