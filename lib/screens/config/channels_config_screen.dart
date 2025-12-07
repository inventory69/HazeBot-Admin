import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ChannelsConfigScreen extends StatefulWidget {
  const ChannelsConfigScreen({super.key});

  @override
  State<ChannelsConfigScreen> createState() => _ChannelsConfigScreenState();
}

class _ChannelsConfigScreenState extends State<ChannelsConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Channel selections
  String? _logChannelId;
  String? _changelogChannelId;
  String? _todoChannelId;
  String? _rlChannelId;
  String? _gamingChannelId;
  String? _memeChannelId;
  String? _serverGuideChannelId;
  String? _welcomeRulesChannelId;
  String? _welcomePublicChannelId;
  String? _transcriptChannelId;
  String? _ticketsCategoryId;
  String? _statusChannelId;

  // Available channels and categories
  List<Map<String, dynamic>> _channels = [];
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadGuildData();
    await _loadConfig();
  }

  Future<void> _loadGuildData() async {
    try {
      debugPrint('DEBUG: Loading guild channels data...');
      final apiService = ApiService();
      final channels = await apiService.getGuildChannels();
      debugPrint('DEBUG: Received ${channels.length} channels');

      if (mounted) {
        setState(() {
          // Separate text channels and categories
          _channels = channels.where((ch) => ch['type'] == 'text').toList();
          _categories =
              channels.where((ch) => ch['type'] == 'category').toList();
          debugPrint(
              'DEBUG: Text channels: ${_channels.length}, Categories: ${_categories.length}');
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Error loading guild data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading guild data: $e')),
        );
      }
    }
  }

  Future<void> _loadConfig() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      debugPrint('DEBUG: Loading channels config...');
      final apiService = ApiService();
      final config = await apiService.getChannelsConfig();
      debugPrint('DEBUG: Channels config loaded: $config');

      if (mounted) {
        setState(() {
          _logChannelId = config['log_channel_id']?.toString();
          _changelogChannelId = config['changelog_channel_id']?.toString();
          _todoChannelId = config['todo_channel_id']?.toString();
          _rlChannelId = config['rl_channel_id']?.toString();
          _gamingChannelId = config['gaming_channel_id']?.toString();
          _memeChannelId = config['meme_channel_id']?.toString();
          _serverGuideChannelId = config['server_guide_channel_id']?.toString();
          _welcomeRulesChannelId =
              config['welcome_rules_channel_id']?.toString();
          _welcomePublicChannelId =
              config['welcome_public_channel_id']?.toString();
          _transcriptChannelId = config['transcript_channel_id']?.toString();
          _ticketsCategoryId = config['tickets_category_id']?.toString();
          _statusChannelId = config['status_channel_id']?.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading configuration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final apiService = ApiService();

      final config = {
        'log_channel_id':
            _logChannelId != null ? int.parse(_logChannelId!) : null,
        'changelog_channel_id': _changelogChannelId != null
            ? int.parse(_changelogChannelId!)
            : null,
        'todo_channel_id':
            _todoChannelId != null ? int.parse(_todoChannelId!) : null,
        'rl_channel_id': _rlChannelId != null ? int.parse(_rlChannelId!) : null,
        'gaming_channel_id':
            _gamingChannelId != null ? int.parse(_gamingChannelId!) : null,
        'meme_channel_id':
            _memeChannelId != null ? int.parse(_memeChannelId!) : null,
        'server_guide_channel_id': _serverGuideChannelId != null
            ? int.parse(_serverGuideChannelId!)
            : null,
        'welcome_rules_channel_id': _welcomeRulesChannelId != null
            ? int.parse(_welcomeRulesChannelId!)
            : null,
        'welcome_public_channel_id': _welcomePublicChannelId != null
            ? int.parse(_welcomePublicChannelId!)
            : null,
        'transcript_channel_id': _transcriptChannelId != null
            ? int.parse(_transcriptChannelId!)
            : null,
        'tickets_category_id':
            _ticketsCategoryId != null ? int.parse(_ticketsCategoryId!) : null,
        'status_channel_id':
            _statusChannelId != null ? int.parse(_statusChannelId!) : null,
      };

      await apiService.updateChannelsConfig(config);

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will reset all channel settings to their default values. '
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
      final apiService = ApiService();
      await apiService.resetChannelsConfig();
      await _loadConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration reset to defaults'),
            backgroundColor: Colors.orange,
          ),
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

  Widget _buildChannelDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    required String hint,
    IconData? icon,
    bool required = false,
    bool isMobile = false,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: isMobile ? 14 : null),
        hintText: hint,
        hintStyle: TextStyle(fontSize: isMobile ? 12 : null),
        border: const OutlineInputBorder(),
        prefixIcon:
            icon != null ? Icon(icon, size: isMobile ? 20 : null) : null,
        isDense: isMobile,
      ),
      items: [
        if (!required)
          const DropdownMenuItem<String>(
            value: null,
            child: SizedBox(
                width: 200,
                child:
                    Text('None', maxLines: 1, overflow: TextOverflow.ellipsis)),
          ),
        ..._channels.map((channel) {
          final category =
              channel['category'] != null ? '${channel['category']} / ' : '';
          return DropdownMenuItem<String>(
            value: channel['id'],
            child: SizedBox(
              width: 200,
              child: Text('$category#${channel['name']}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          );
        }),
      ],
      onChanged: onChanged,
      validator: required
          ? (value) => value == null ? 'This field is required' : null
          : null,
    );
  }

  Widget _buildCategoryDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    required String hint,
    IconData? icon,
    bool required = false,
    bool isMobile = false,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: isMobile ? 14 : null),
        hintText: hint,
        hintStyle: TextStyle(fontSize: isMobile ? 12 : null),
        border: const OutlineInputBorder(),
        prefixIcon:
            icon != null ? Icon(icon, size: isMobile ? 20 : null) : null,
        isDense: isMobile,
      ),
      items: [
        if (!required)
          const DropdownMenuItem<String>(
            value: null,
            child: SizedBox(
                width: 200,
                child:
                    Text('None', maxLines: 1, overflow: TextOverflow.ellipsis)),
          ),
        ..._categories.map((category) {
          return DropdownMenuItem<String>(
            value: category['id'],
            child: SizedBox(
              width: 200,
              child: Text(category['name'],
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          );
        }),
      ],
      onChanged: onChanged,
      validator: required
          ? (value) => value == null ? 'This field is required' : null
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;
    if (_isLoading && _channels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 12.0 : 24.0;
        final cardPadding = isMobile ? 12.0 : 16.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Channels Configuration',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: isMobile ? 24 : null,
                      ),
                ),
                SizedBox(height: isMobile ? 4 : 8),
                Text(
                  'Configure Discord channels for bot features',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 13 : null,
                      ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

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
                          size: isMobile ? 18 : 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Channels marked as required must be configured for the bot to function properly.',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: Colors.blue[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // General Channels
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.settings_input_composite,
                                color: Colors.blue, size: isMobile ? 20 : 24),
                            SizedBox(width: isMobile ? 6 : 8),
                            Expanded(
                              child: Text(
                                'General Channels',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        SizedBox(
                          width: double.infinity,
                          child: _buildChannelDropdown(
                            label: 'Log Channel',
                            value: _logChannelId,
                            onChanged: (value) =>
                                setState(() => _logChannelId = value),
                            hint: 'Bot logs and events',
                            icon: Icons.article,
                            required: true,
                            isMobile: isMobile,
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        SizedBox(
                          width: double.infinity,
                          child: _buildChannelDropdown(
                            label: 'Changelog Channel',
                            value: _changelogChannelId,
                            onChanged: (value) =>
                                setState(() => _changelogChannelId = value),
                            hint: 'Bot updates and changes',
                            icon: Icons.update,
                            required: true,
                            isMobile: isMobile,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // Feature Channels
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.extension,
                                color: Colors.green, size: isMobile ? 20 : 24),
                            SizedBox(width: isMobile ? 6 : 8),
                            Expanded(
                              child: Text(
                                'Feature Channels',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        SizedBox(
                          width: double.infinity,
                          child: _buildChannelDropdown(
                            label: 'Todo Channel',
                            value: _todoChannelId,
                            onChanged: (value) =>
                                setState(() => _todoChannelId = value),
                            hint: 'Todo list management',
                            icon: Icons.checklist,
                            isMobile: isMobile,
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        SizedBox(
                          width: double.infinity,
                          child: _buildChannelDropdown(
                            label: 'Rocket League Channel',
                            value: _rlChannelId,
                            onChanged: (value) =>
                                setState(() => _rlChannelId = value),
                            hint: 'Rocket League rank updates',
                            icon: Icons.sports_esports,
                            isMobile: isMobile,
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        SizedBox(
                          width: double.infinity,
                          child: _buildChannelDropdown(
                            label: 'Gaming Channel',
                            value: _gamingChannelId,
                            onChanged: (value) =>
                                setState(() => _gamingChannelId = value),
                            hint: 'Gaming requests and community gaming',
                            icon: Icons.videogame_asset,
                            isMobile: isMobile,
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        SizedBox(
                          width: double.infinity,
                          child: _buildChannelDropdown(
                            label: 'Meme Channel',
                            value: _memeChannelId,
                            onChanged: (value) =>
                                setState(() => _memeChannelId = value),
                            hint: 'Daily memes and meme commands',
                            icon: Icons.image,
                            isMobile: isMobile,
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        SizedBox(
                          width: double.infinity,
                          child: _buildChannelDropdown(
                            label: 'Server Guide Channel',
                            value: _serverGuideChannelId,
                            onChanged: (value) =>
                                setState(() => _serverGuideChannelId = value),
                            hint: 'Server guide and info',
                            icon: Icons.info,
                            isMobile: isMobile,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // Welcome System
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.waving_hand,
                                color: Colors.orange, size: isMobile ? 20 : 24),
                            SizedBox(width: isMobile ? 6 : 8),
                            Expanded(
                              child: Text(
                                'Welcome System',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildChannelDropdown(
                          label: 'Welcome Rules Channel',
                          value: _welcomeRulesChannelId,
                          onChanged: (value) =>
                              setState(() => _welcomeRulesChannelId = value),
                          hint: 'Server rules and acceptance',
                          icon: Icons.rule,
                          required: true,
                          isMobile: isMobile,
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildChannelDropdown(
                          label: 'Welcome Public Channel',
                          value: _welcomePublicChannelId,
                          onChanged: (value) =>
                              setState(() => _welcomePublicChannelId = value),
                          hint: 'Public welcome messages',
                          icon: Icons.doorbell,
                          required: true,
                          isMobile: isMobile,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // Ticket System
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.confirmation_number,
                                color: Colors.purple, size: isMobile ? 20 : 24),
                            SizedBox(width: isMobile ? 6 : 8),
                            Expanded(
                              child: Text(
                                'Ticket System',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildChannelDropdown(
                          label: 'Transcript Channel',
                          value: _transcriptChannelId,
                          onChanged: (value) =>
                              setState(() => _transcriptChannelId = value),
                          hint: 'Ticket transcripts archive',
                          icon: Icons.description,
                          required: true,
                          isMobile: isMobile,
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        SizedBox(
                          width: double.infinity,
                          child: _buildCategoryDropdown(
                            label: 'Tickets Category',
                            value: _ticketsCategoryId,
                            onChanged: (value) =>
                                setState(() => _ticketsCategoryId = value),
                            hint: 'Category for ticket channels',
                            icon: Icons.category,
                            required: true,
                            isMobile: isMobile,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // Monitoring
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.monitor_heart,
                                color: Colors.blue, size: isMobile ? 20 : 24),
                            SizedBox(width: isMobile ? 6 : 8),
                            Expanded(
                              child: Text(
                                'Monitoring',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildChannelDropdown(
                          label: 'Status Channel',
                          value: _statusChannelId,
                          onChanged: (value) =>
                              setState(() => _statusChannelId = value),
                          hint: 'Live status dashboard embed',
                          icon: Icons.dashboard,
                          required: false,
                          isMobile: isMobile,
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
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
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
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveConfig,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Save Configuration'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
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
