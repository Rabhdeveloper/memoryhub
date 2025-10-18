import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/collapsible_settings_group.dart';
import '../../widgets/modern_list_tile.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  bool _darkMode = false;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setString('language', _language);
    
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
        title: const Text('Personalization'),
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
          CollapsibleSettingsGroup(
            title: 'Appearance',
            icon: Icons.palette,
            children: [
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                value: _darkMode,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          CollapsibleSettingsGroup(
            title: 'Content Preferences',
            icon: Icons.tune,
            children: [
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.label,
                title: 'Tags Management',
                subtitle: 'Organize and manage your tags',
                onTap: () => Navigator.pushNamed(context, '/tags/management'),
              ),
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.category,
                title: 'Categories',
                subtitle: 'Manage content categories',
                onTap: () => Navigator.pushNamed(context, '/categories'),
              ),
              const SizedBox(height: 8),
              ModernListTile(
                icon: Icons.description,
                title: 'Memory Templates',
                subtitle: 'Use and create templates',
                onTap: () => Navigator.pushNamed(context, '/templates'),
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 16),
          CollapsibleSettingsGroup(
            title: 'Language & Region',
            icon: Icons.language,
            children: [
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Language'),
                subtitle: Text(_language),
                trailing: DropdownButton<String>(
                  value: _language,
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
                    DropdownMenuItem(value: 'French', child: Text('French')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _language = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
