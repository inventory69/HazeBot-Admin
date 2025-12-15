import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_service.dart';
import '../services/permission_service.dart';
import '../utils/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = 'Loading...';
  String _buildNumber = '';
  bool _showAdminPanelOnStartup = false;
  bool _autoSendErrors = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _loadShowAdminPanelSetting();
    _loadErrorReportingSetting();
  }

  Future<void> _loadErrorReportingSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSendErrors = prefs.getBool('auto_send_error_reports') ?? false;
    });
  }

  Future<void> _loadShowAdminPanelSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showAdminPanelOnStartup =
          prefs.getBool('show_admin_panel_on_startup') ?? false;
    });
  }

  Future<void> _setShowAdminPanelOnStartup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_admin_panel_on_startup', value);
    setState(() {
      _showAdminPanelOnStartup = value;
    });
  }

  Future<void> _loadPackageInfo() async {
    setState(() {
      if (kDebugMode) {
        // In Debug mode: Use current date as version to avoid showing outdated CI build info
        final now = DateTime.now();
        final dateStr =
            '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _version = '$dateStr-dev';
        _buildNumber = timeStr;
      } else {
        // In Release mode: Load actual build info from CI/CD
        PackageInfo.fromPlatform().then((packageInfo) {
          setState(() {
            _version = packageInfo.version;
            _buildNumber = packageInfo.buildNumber;
          });
        });
      }
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
                              ? 'Dynamic colors enabled - applied automatically'
                              : 'Dynamic colors disabled - applied automatically',
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
          Consumer<PermissionService>(
            builder: (context, permissionService, _) {
              // Only show for admins and moderators
              if (!permissionService.hasPermission('all')) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Show Admin Panel on Startup'),
                    subtitle: const Text(
                      'Automatically open the admin panel when the app starts',
                    ),
                    secondary: const Icon(Icons.admin_panel_settings),
                    value: _showAdminPanelOnStartup,
                    onChanged: (value) async {
                      await _setShowAdminPanelOnStartup(value);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Admin panel will open on startup'
                                  : 'Admin panel will be hidden on startup',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(),
                ],
              );
            },
          ),
          const Divider(),
          // Error Reporting Section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Privacy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Automatic Error Reporting'),
            subtitle: const Text(
              'Help us improve the app by automatically sending anonymous error reports',
            ),
            secondary: const Icon(Icons.bug_report),
            value: _autoSendErrors,
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('auto_send_error_reports', value);

              setState(() {
                _autoSendErrors = value;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Automatic error reporting enabled'
                          : 'Automatic error reporting disabled',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          // Privacy Info (Expandable)
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('What gets sent?'),
            trailing: const Icon(Icons.info_outline, size: 20),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Error Report Contents'),
                  content: const SingleChildScrollView(
                    child: Text(
                      '✓ Error message and type\n'
                      '✓ Stack trace (crash location)\n'
                      '✓ App version and device info\n'
                      '✓ Recent actions (last 100 logs)\n'
                      '✓ Your username (for follow-up)\n'
                      '\n'
                      '✗ NO passwords or sensitive data\n'
                      '✗ NO message content\n'
                      '✗ NO personal information',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
          if (kDebugMode) ...[
            // Test Error Report Button (nur in Debug Mode)
            ListTile(
              leading: const Icon(Icons.science),
              title: const Text('Test Error Report'),
              subtitle: const Text('Send a test error to verify reporting works'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pushNamed(context, '/test');
              },
            ),
          ],
          const Divider(),
          const SizedBox(height: 16),
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
