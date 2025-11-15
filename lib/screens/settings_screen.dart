import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/theme_service.dart';
import '../utils/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = 'Loading...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

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
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(AppConfig.appName),
            subtitle: Text('Version $_version+$_buildNumber'),
          ),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('Environment'),
            subtitle: Text(AppConfig.environmentName),
            trailing: Icon(
              AppConfig.isProduction ? Icons.verified : Icons.science,
              color: AppConfig.isProduction ? Colors.green : Colors.orange,
            ),
          ),
          const ListTile(
            leading: Icon(Icons.badge),
            title: Text('Package ID'),
            subtitle: Text('xyz.hzwd.hazebot.admin'),
          ),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Developer'),
            subtitle: Text('inventory69'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('GitHub Repository'),
            subtitle: const Text('github.com/inventory69/HazeBot-Admin'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              final githubUrl = dotenv.env['GITHUB_REPO_URL'] ??
                  'https://github.com/inventory69/HazeBot-Admin';
              final url = Uri.parse(githubUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}
