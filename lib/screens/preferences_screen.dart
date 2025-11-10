import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _isLoading = true;
  bool _changelogOptIn = false;
  bool _memeOptIn = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.apiService.getUserProfile();

      if (mounted) {
        final profile = response['profile'] as Map<String, dynamic>?;
        final notifications =
            profile?['notifications'] as Map<String, dynamic>?;
        setState(() {
          _changelogOptIn = notifications?['changelog_opt_in'] ?? false;
          _memeOptIn = notifications?['meme_opt_in'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load preferences: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleChangelog(bool value) async {
    setState(() => _changelogOptIn = value);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.updateUserPreferences({
        'changelog_opt_in': value,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  value ? Icons.notifications_active : Icons.notifications_off,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  value
                      ? '🔔 Changelog notifications enabled!'
                      : '🔕 Changelog notifications disabled',
                ),
              ],
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Revert on error
        setState(() => _changelogOptIn = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update preference: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleMeme(bool value) async {
    setState(() => _memeOptIn = value);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.updateUserPreferences({
        'meme_opt_in': value,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  value ? Icons.notifications_active : Icons.notifications_off,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  value
                      ? '🎭 Daily Meme notifications enabled!'
                      : '🔕 Daily Meme notifications disabled',
                ),
              ],
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Revert on error
        setState(() => _memeOptIn = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update preference: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPreferences,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 12.0 : 16.0;
        final cardPadding = isMobile ? 12.0 : 16.0;

        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferences',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: isMobile ? 24 : null,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Customize your notification preferences',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 13 : null,
                      ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Changelog Notifications
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.update,
                              color: Colors.blue,
                              size: isMobile ? 20 : 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Changelog Notifications',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ),
                            Switch(
                              value: _changelogOptIn,
                              onChanged: _toggleChangelog,
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: isMobile ? 18 : 20,
                                  color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _changelogOptIn
                                      ? '✅ You will be notified about bot updates and new features.'
                                      : '❌ You will not receive changelog notifications.',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // Daily Meme Notifications
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.image,
                              color: Colors.purple,
                              size: isMobile ? 20 : 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Daily Meme Notifications',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ),
                            Switch(
                              value: _memeOptIn,
                              onChanged: _toggleMeme,
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.purple.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: isMobile ? 18 : 20,
                                  color: Colors.purple[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _memeOptIn
                                      ? '✅ You will be pinged when the daily meme is posted at 12:00 PM.'
                                      : '❌ You will not receive daily meme notifications.',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.purple[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
