# MuseAI

MuseAI is a cross-platform mobile application that uses AI agents to generate original music in real time.  
Users can select mood, genre, tempo, and instrumentation, then get a tailored track they can play, save, share, and remix.

## Target Users
- General listeners who want personalized, mood-based music
- Content creators (YouTubers, TikTokers, podcasters) needing royalty-free music
- Students learning music theory and AI
- Independent artists looking for AI-assisted composition ideas
- Casual users who enjoy experimenting with AI creativity

## Problem Statement (Why)
The current music ecosystem is split:
- Streaming apps support consumption but not creativity
- Production tools are powerful but hard to learn
- Many AI music tools are web-first and not mobile-native

### Current Issues
- Creating original music typically requires advanced skills and expensive tooling
- Content creators struggle to find suitable royalty-free tracks
- Existing AI generation tools are often not optimized for mobile UX
- Listeners have limited creative control in traditional streaming apps
- No single mobile app combines generation, remixing, social sharing, and personal music library

### Why MuseAI
MuseAI removes technical barriers by using AI agents for composition and production, making music creation accessible to users regardless of musical background.

## Project Objectives
1. Build a functional cross-platform app for fast AI track generation from mood/genre input.
2. Integrate AI agents for multi-genre composition (pop, hip-hop, classical, lo-fi, electronic).
3. Provide an intuitive UI usable by non-musicians.
4. Enable royalty-free export for content creators.
5. Add social features for sharing and discovery of generated music.

## Proposed Solution (How)
### Platform
- Flutter for Android and iOS with a shared codebase

### Backend
- Supabase for authentication, Postgres data, and storage

### AI Integration
- External AI music generation APIs (e.g., Suno-like services)
- Python-based AI agent orchestration for prompt optimization, mood mapping, and track parameter control

### Development Process
- Agile sprints
- Phases: UI/UX prototyping -> core Flutter features -> AI integration and testing
- Version control with Git/GitHub

## Functional Requirements
1. User registration/login (email-password and Google Sign-In)
2. AI music generation from mood, genre, tempo, and instruments
3. In-app playback (play/pause/seek/skip)
4. Library management and playlist organization
5. Remix controls (tempo, key, instrumentation) with regeneration
6. Track sharing to external platforms and in-app feed
7. Royalty-free MP3 export/download
8. Mood and genre selection via presets or text input

## Non-Functional Requirements
1. Performance: generation within 10-15 seconds; UI response within 2 seconds in normal conditions
2. Usability: first-time users can generate a track without tutorials
3. Security: secure storage and Supabase access controls
4. Scalability: backend supports growth without major degradation
5. Reliability: graceful handling of API failures with clear retry/error states

## Current Implementation Status
The current codebase includes core app structure, authentication flow scaffolding, playback screens, and placeholder media data for local/demo usage.  
Advanced AI generation, royalty-free export pipeline, and full social feed workflows are planned for incremental implementation.
