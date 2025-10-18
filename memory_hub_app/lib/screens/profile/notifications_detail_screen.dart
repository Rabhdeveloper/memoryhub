import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/collapsible_settings_group.dart';

class NotificationsDetailScreen extends StatefulWidget {
  const NotificationsDetailScreen({super.key});

  @override
  State<NotificationsDetailScreen> createState() => _NotificationsDetailScreenState();
}

class _NotificationsDetailScreenState extends State<NotificationsDetailScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _memoriesNotif = true;
  bool _commentsNotif = true;
  bool _reactionsNotif = true;
  bool _followersNotif = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _memoriesNotif = prefs.getBool('memories_notif') ?? true;
      _commentsNotif = prefs.getBool('comments_notif') ?? true;
      _reactionsNotif = prefs.getBool('reactions_notif') ?? true;
      _followersNotif = prefs.getBool('followers_notif') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('memories_notif', _memoriesNotif);
    await prefs.setBool('comments_notif', _commentsNotif);
    await prefs.setBool('reactions_notif', _reactionsNotif);
    await prefs.setBool('followers_notif', _followersNotif);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Master Control',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Enable or disable all notifications',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CollapsibleSettingsGroup(
            title: 'Notification Channels',
            icon: Icons.send,
            children: [
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive notifications via email'),
                value: _emailNotifications,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() => _emailNotifications = value);
                      }
                    : null,
              ),
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive push notifications'),
                value: _pushNotifications,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() => _pushNotifications = value);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          CollapsibleSettingsGroup(
            title: 'Content Notifications',
            icon: Icons.auto_awesome,
            children: [
              SwitchListTile(
                title: const Text('New Memories'),
                subtitle: const Text('When people you follow share memories'),
                value: _memoriesNotif,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() => _memoriesNotif = value);
                      }
                    : null,
              ),
              SwitchListTile(
                title: const Text('Comments'),
                subtitle: const Text('When someone comments on your content'),
                value: _commentsNotif,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() => _commentsNotif = value);
                      }
                    : null,
              ),
              SwitchListTile(
                title: const Text('Reactions'),
                subtitle: const Text('When someone reacts to your content'),
                value: _reactionsNotif,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() => _reactionsNotif = value);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          CollapsibleSettingsGroup(
            title: 'Social Notifications',
            icon: Icons.people,
            children: [
              SwitchListTile(
                title: const Text('New Followers'),
                subtitle: const Text('When someone follows you'),
                value: _followersNotif,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() => _followersNotif = value);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
