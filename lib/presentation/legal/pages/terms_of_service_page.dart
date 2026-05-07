// This page builds the UI for legal pages.

import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: 'Terms of Service',
      sections: [
        (
          'Acceptable Use',
          'Do not use MuseAI to generate unlawful, abusive, or infringing content. You are responsible for the prompts you submit.'
        ),
        (
          'Generated Content',
          'MuseAI-generated tracks are provided as-is. Review outputs before publishing or commercial use.'
        ),
        (
          'Service Availability',
          'Generation features depend on external AI providers and Supabase-backed services, so uptime and latency may vary.'
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
