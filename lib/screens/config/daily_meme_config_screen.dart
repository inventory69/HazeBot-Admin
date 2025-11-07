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
  String? _selectedChannelId;
  String? _selectedRoleId;
  bool _allowNsfw = true;

  // Dropdowns data
  List<Map<String, dynamic>> _channels = [];
  List<Map<String, dynamic>> _roles = [];

  // Meme sources
  List<String> _subreddits = [];
  List<String> _lemmyCommunities = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Load all data in parallel
      final results = await Future.wait([
        authService.apiService.getGuildChannels(),
        authService.apiService.getGuildRoles(),
        authService.apiService.getDailyMemeConfig(),
      ]);

      final channels = results[0] as List<Map<String, dynamic>>;
      final roles = results[1] as List<Map<String, dynamic>>;
      final config = results[2] as Map<String, dynamic>;

      final configChannelId = config['channel_id']?.toString();
      final configRoleId = config['role_id']?.toString();

      if (mounted) {
        setState(() {
          _channels = channels;
          _roles = roles;
          _enabled = config['enabled'] ?? true;
          _hourController.text = (config['hour'] ?? 12).toString();
          _minuteController.text = (config['minute'] ?? 0).toString();
          _allowNsfw = config['allow_nsfw'] ?? true;

          // Load meme sources
          _subreddits = List<String>.from(config['available_subreddits'] ?? []);
          _lemmyCommunities =
              List<String>.from(config['available_lemmy'] ?? []);

          // Only set selected IDs if they exist in the loaded lists
          if (configChannelId != null &&
              _channels.any((ch) => ch['id'] == configChannelId)) {
            _selectedChannelId = configChannelId;
          }
          if (configRoleId != null &&
              _roles.any((r) => r['id'] == configRoleId)) {
            _selectedRoleId = configRoleId;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading configuration: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
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
        'channel_id':
            _selectedChannelId != null ? int.parse(_selectedChannelId!) : null,
        'role_id': // Changed from ping_role_id to match backend
            _selectedRoleId != null ? int.parse(_selectedRoleId!) : null,
        'allow_nsfw': _allowNsfw,
        'subreddits': _subreddits,
        'lemmy_communities': _lemmyCommunities,
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
      await _initializeData();

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

  Future<void> _addSubreddit() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subreddit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Subreddit name',
            hintText: 'e.g., memes, dankmemes',
            prefixText: 'r/',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (!_subreddits.contains(result)) {
          _subreddits.add(result);
        }
      });
    }
  }

  Future<void> _addLemmyCommunity() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Lemmy Community'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Community',
            hintText: 'e.g., memes@lemmy.ml',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (!_lemmyCommunities.contains(result)) {
          _lemmyCommunities.add(result);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final padding = isMobile ? 12.0 : 24.0;

              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.schedule_send,
                              size: isMobile ? 28 : 32,
                              color: Theme.of(context).colorScheme.primary),
                          SizedBox(width: isMobile ? 8 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Meme Configuration',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontSize: isMobile ? 24 : null,
                                      ),
                                ),
                                Text(
                                  'Configure when and how daily memes are automatically posted',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: isMobile ? 13 : null,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 20 : 32),

                      // Info Box
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
                                'Set up automatic meme posting schedule and source configuration.',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),

                      // Enabled Switch
                      Card(
                        child: SwitchListTile(
                          title: Row(
                            children: [
                              Icon(Icons.power_settings_new,
                                  color: _enabled ? Colors.green : Colors.grey,
                                  size: isMobile ? 20 : 24),
                              const SizedBox(width: 8),
                              Text('Enable Daily Memes',
                                  style: TextStyle(
                                      fontSize: isMobile ? 14 : null)),
                            ],
                          ),
                          subtitle: Text('Automatically post memes daily',
                              style: TextStyle(fontSize: isMobile ? 12 : null)),
                          value: _enabled,
                          onChanged: (value) =>
                              setState(() => _enabled = value),
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),

                      // Time Configuration
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.schedule,
                                      color: Colors.orange,
                                      size: isMobile ? 20 : 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Posting Time',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontSize: isMobile ? 16 : null,
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 8 : 12),
                              // Info box about scheduling
                              Container(
                                padding: EdgeInsets.all(isMobile ? 10 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: isMobile ? 18 : 20,
                                        color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'The daily meme will run once per day at the specified time. If you change the time to earlier than the current time, it will run tomorrow at that time.',
                                        style: TextStyle(
                                          fontSize: isMobile ? 12 : 13,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isMobile ? 12 : 16),
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
                      SizedBox(height: isMobile ? 12 : 16),

                      // Channel & Role Configuration
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.tag,
                                      color: Colors.purple,
                                      size: isMobile ? 20 : 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Channel & Role Settings',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontSize: isMobile ? 16 : null,
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 12 : 16),
                              DropdownButtonFormField<String>(
                                value: _selectedChannelId,
                                decoration: const InputDecoration(
                                  labelText: 'Meme Channel',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.tag),
                                ),
                                items: _channels.map((channel) {
                                  final category = channel['category'] != null
                                      ? '${channel['category']} / '
                                      : '';
                                  return DropdownMenuItem<String>(
                                    value: channel['id'],
                                    child: Text('$category#${channel['name']}'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedChannelId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Channel is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedRoleId,
                                decoration: const InputDecoration(
                                  labelText: 'Ping Role (Optional)',
                                  hintText: 'Select role to mention',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.alternate_email),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('None'),
                                  ),
                                  ..._roles.map((role) {
                                    return DropdownMenuItem<String>(
                                      value: role['id'],
                                      child: Text('@${role['name']}'),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRoleId = value;
                                  });
                                },
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
                          subtitle:
                              const Text('Include NSFW memes in selection'),
                          value: _allowNsfw,
                          onChanged: (value) =>
                              setState(() => _allowNsfw = value),
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),

                      // Meme Sources Card
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.source,
                                      color: Colors.red,
                                      size: isMobile ? 20 : 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Meme Sources',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontSize: isMobile ? 16 : null,
                                          ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_subreddits.length + _lemmyCommunities.length} total',
                                      style: TextStyle(
                                        fontSize: isMobile ? 11 : 12,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 12 : 16),

                              // Subreddits Section
                              Row(
                                children: [
                                  const Icon(Icons.reddit, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Subreddits (${_subreddits.length})',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _addSubreddit(),
                                    tooltip: 'Add Subreddit',
                                  ),
                                ],
                              ),
                              if (_subreddits.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text('No subreddits configured'),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _subreddits.map((sub) {
                                    return Chip(
                                      label: Text('r/$sub'),
                                      onDeleted: () {
                                        setState(() => _subreddits.remove(sub));
                                      },
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 16),

                              // Lemmy Communities Section
                              Row(
                                children: [
                                  const Icon(Icons.forum, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lemmy Communities (${_lemmyCommunities.length})',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _addLemmyCommunity(),
                                    tooltip: 'Add Lemmy Community',
                                  ),
                                ],
                              ),
                              if (_lemmyCommunities.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child:
                                      Text('No Lemmy communities configured'),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _lemmyCommunities.map((community) {
                                    return Chip(
                                      label: Text(community),
                                      onDeleted: () {
                                        setState(() => _lemmyCommunities
                                            .remove(community));
                                      },
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : 24),

                      // Action Buttons
                      if (isMobile)
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _resetToDefaults,
                                icon: const Icon(Icons.restore, size: 20),
                                label: const Text('Reset to Defaults',
                                    style: TextStyle(fontSize: 14)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  padding: const EdgeInsets.all(14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _saveConfig,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.save, size: 20),
                                label: const Text('Save Configuration',
                                    style: TextStyle(fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(14),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
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
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.save),
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
              );
            },
          );
  }
}
