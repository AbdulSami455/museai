// This page builds the UI for profile settings.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:museai/core/configs/app_config.dart';
import 'package:museai/presentation/auth/pages/auth_page.dart';
import 'package:museai/presentation/auth/pages/password_reset_page.dart';
import 'package:museai/presentation/legal/pages/privacy_policy_page.dart';
import 'package:museai/presentation/legal/pages/terms_of_service_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF0F766E),
                  child: Text(
                    (user?.email ?? 'M').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.userMetadata?['full_name']?.toString() ??
                            'MuseAI User',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'Signed in',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SettingsTile(
            icon: Icons.lock_reset_rounded,
            title: 'Reset Password',
            subtitle: 'Send a password reset email',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PasswordResetPage()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read how MuseAI handles your data',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.gavel_outlined,
            title: 'Terms of Service',
            subtitle: 'Review the app usage terms',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.login_rounded,
            title: 'Google Sign-In',
            subtitle: 'UI placeholder for provider auth',
            trailing: const Text('Soon'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Google Sign-In UI is ready; provider setup is pending.')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.apple_rounded,
            title: 'Apple Sign-In',
            subtitle: 'UI placeholder for provider auth',
            trailing: const Text('Soon'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Apple Sign-In UI is ready; provider setup is pending.')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            subtitle: 'End the current session',
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage()),
                (route) => false,
              );
            },
          ),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            title: 'Delete Account',
            subtitle: 'Remove your account and stored data',
            danger: true,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text(
                        'This permanently removes your MuseAI account, tracks, and playlists.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (!confirmed || !context.mounted) return;
              await _deleteAccount(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.backendBaseUrl}/api/v1/auth/account'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_extractErrorMessage(response.body));
      }
      await Supabase.instance.client.auth.signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {}
    return 'Unable to delete account.';
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool danger;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFB7185) : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title,
          style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
