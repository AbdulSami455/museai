import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: 'Privacy Policy',
      sections: [
        (
          'What We Collect',
          'MuseAI stores account details, generated track metadata, playlists, and generation prompts so your library syncs across devices.'
        ),
        (
          'How We Use It',
          'We use your prompts and settings to generate tracks, personalize your library, and operate authenticated features backed by Supabase.'
        ),
        (
          'Your Controls',
          'You can delete tracks, playlists, and your account from the app. Deleting your account removes associated app data from the backend.'
        ),
      ],
    );
  }
}

class _LegalScaffold extends StatelessWidget {
  final String title;
  final List<(String, String)> sections;

  const _LegalScaffold({
    required this.title,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.$1,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                section.$2,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76), height: 1.5),
              ),
            ],
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 22),
        itemCount: sections.length,
      ),
    );
  }
}
