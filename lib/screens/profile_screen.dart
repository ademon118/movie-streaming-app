import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              'Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.surfaceElevated,
                  child: Text(
                    'A',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.accent,
                        ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aung Ko Ko Naing',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'aung@example.com',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit Profile coming soon'),
                      backgroundColor: AppTheme.surfaceElevated,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Profile'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Favorite genres',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profileFavoriteGenres
                  .map(
                    (genre) => Chip(
                      label: Text(genre),
                      backgroundColor: AppTheme.surfaceElevated,
                      side: BorderSide.none,
                      labelStyle: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            _ProfileTile(
              icon: Icons.history_rounded,
              title: 'Watch History',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WatchHistoryScreen(),
                  ),
                );
              },
            ),
            _ProfileTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            _ProfileTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              destructive: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out (UI only)'),
                    backgroundColor: AppTheme.surfaceElevated,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFFF6B6B) : AppTheme.textPrimary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      trailing: destructive
          ? null
          : const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}

class WatchHistoryScreen extends StatelessWidget {
  const WatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watch History')),
      body: Center(
        child: Text(
          'No watch history yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  bool _notifications = true;
  String _language = 'English';
  String _region = 'US';
  String _quality = 'Auto';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Cinema look (on by default)'),
            value: _darkMode,
            activeThumbColor: AppTheme.accent,
            onChanged: (value) => setState(() => _darkMode = value),
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: _notifications,
            activeThumbColor: AppTheme.accent,
            onChanged: (value) => setState(() => _notifications = value),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(_language),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final next = await _pickOption(
                context,
                title: 'Language',
                options: const ['English', 'Myanmar', '中文'],
                current: _language,
              );
              if (next != null) setState(() => _language = next);
            },
          ),
          ListTile(
            title: const Text('Region'),
            subtitle: Text(_region),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final next = await _pickOption(
                context,
                title: 'Region',
                options: const ['US', 'MM', 'SG', 'JP'],
                current: _region,
              );
              if (next != null) setState(() => _region = next);
            },
          ),
          ListTile(
            title: const Text('Video Quality'),
            subtitle: Text(_quality),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final next = await _pickOption(
                context,
                title: 'Video Quality',
                options: const ['Auto', '1080p', '720p', '480p'],
                current: _quality,
              );
              if (next != null) setState(() => _quality = next);
            },
          ),
          ListTile(
            title: const Text('Clear Cache'),
            trailing: const Icon(Icons.delete_outline_rounded),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared (UI only)'),
                  backgroundColor: AppTheme.surfaceElevated,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const ListTile(
            title: Text('About'),
            subtitle: Text('KyiKyaMal · v1.0.0'),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickOption(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String current,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              ...options.map(
                (option) => ListTile(
                  title: Text(option),
                  trailing: option == current
                      ? const Icon(Icons.check_rounded, color: AppTheme.accent)
                      : null,
                  onTap: () => Navigator.pop(context, option),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
