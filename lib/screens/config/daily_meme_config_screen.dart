import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class DailyMemeConfigScreen extends StatefulWidget {
  const DailyMemeConfigScreen({super.key});

  @override
  State<DailyMemeConfigScreen> createState() => _DailyMemeConfigScreenState();
}

class _DailyMemeConfigScreenState extends State<DailyMemeConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form fields
  bool _enabled = true;
  final _hourController = TextEditingController();
  final _minuteController = TextEditingController();
  final _channelIdController = TextEditingController();
  final _pingRoleIdController = TextEditingController();
  bool _allowNsfw = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _channelIdController.dispose();
    _pingRoleIdController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final config = await authService.apiService.getDailyMemeConfig();

      setState(() {
        _enabled = config['enabled'] ?? true;
        _hourController.text = (config['hour'] ?? 12).toString();
        _minuteController.text = (config['minute'] ?? 0).toString();
        _channelIdController.text = (config['channel_id'] ?? '').toString();
        _pingRoleIdController.text = (config['ping_role_id'] ?? '').toString();
        _allowNsfw = config['allow_nsfw'] ?? true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading configuration: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final config = {
        'enabled': _enabled,
        'hour': int.parse(_hourController.text),
        'minute': int.parse(_minuteController.text),
        'channel_id': int.tryParse(_channelIdController.text),
        'ping_role_id': int.tryParse(_pingRoleIdController.text),
        'allow_nsfw': _allowNsfw,
      };

      await authService.apiService.updateDailyMemeConfig(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving configuration: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetToDefaults() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will reset all daily meme settings to their default values:\n\n'
          '• Enabled: Yes\n'
          '• Time: 12:00\n'
          '• NSFW: Allowed\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.resetDailyMemeConfig();
      await _loadConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration reset to defaults')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting configuration: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Meme Configuration'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enabled Switch
                    Card(
                      child: SwitchListTile(
                        title: const Text('Enable Daily Memes'),
                        subtitle: const Text('Automatically post memes daily'),
                        value: _enabled,
                        onChanged: (value) => setState(() => _enabled = value),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Configuration
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Posting Time',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _hourController,
                                    decoration: const InputDecoration(
                                      labelText: 'Hour (0-23)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.access_time),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      final hour = int.tryParse(value);
                                      if (hour == null ||
                                          hour < 0 ||
                                          hour > 23) {
                                        return 'Must be 0-23';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _minuteController,
                                    decoration: const InputDecoration(
                                      labelText: 'Minute (0-59)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.schedule),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      final minute = int.tryParse(value);
                                      if (minute == null ||
                                          minute < 0 ||
                                          minute > 59) {
                                        return 'Must be 0-59';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Channel & Role Configuration
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Channel & Role Settings',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _channelIdController,
                              decoration: const InputDecoration(
                                labelText: 'Channel ID',
                                hintText: 'Discord Channel ID',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.tag),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Channel ID is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _pingRoleIdController,
                              decoration: const InputDecoration(
                                labelText: 'Ping Role ID (Optional)',
                                hintText: 'Role to ping with memes',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // NSFW Switch
                    Card(
                      child: SwitchListTile(
                        title: const Text('Allow NSFW Content'),
                        subtitle: const Text('Include NSFW memes in selection'),
                        value: _allowNsfw,
                        onChanged: (value) =>
                            setState(() => _allowNsfw = value),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _resetToDefaults,
                            icon: const Icon(Icons.restore),
                            label: const Text('Reset to Defaults'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveConfig,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Configuration'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
