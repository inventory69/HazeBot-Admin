import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<ThemeService>(
            builder: (context, themeService, _) {
              return SwitchListTile(
                title: const Text('Dynamic Colors'),
                subtitle: const Text(
                  'Use colors from your wallpaper (Material You)',
                ),
                secondary: const Icon(Icons.palette),
                value: themeService.useDynamicColor,
                onChanged: (value) async {
                  await themeService.setDynamicColor(value);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Dynamic colors enabled - restart app to apply'
                              : 'Dynamic colors disabled - restart app to apply',
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text('2025.11.06'),
          ),
          const ListTile(
            leading: Icon(Icons.badge),
            title: Text('Package ID'),
            subtitle: Text('xyz.hzwd.hazebot.admin'),
          ),
        ],
      ),
    );
  }
}
