import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class TextsConfigScreen extends StatefulWidget {
  const TextsConfigScreen({super.key});

  @override
  State<TextsConfigScreen> createState() => _TextsConfigScreenState();
}

class _TextsConfigScreenState extends State<TextsConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Welcome System
  final _rulesTextController = TextEditingController();
  List<String> _welcomeMessages = [];
  List<String> _welcomeButtonReplies = [];

  // Rocket League
  final _rlNotificationPrefixController = TextEditingController();
  final _rlEmbedTitleController = TextEditingController();
  final _rlEmbedDescriptionController = TextEditingController();
  List<String> _rlCongratsReplies = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _rulesTextController.dispose();
    _rlNotificationPrefixController.dispose();
    _rlEmbedTitleController.dispose();
    _rlEmbedDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Load Welcome Config
      final welcomeConfig = await authService.apiService.getWelcomeConfig();

      // Load Rocket League Texts Config
      final rlTextsConfig =
          await authService.apiService.getRocketLeagueTextsConfig();

      if (mounted) {
        setState(() {
          // Welcome
          _rulesTextController.text = welcomeConfig['rules_text'] ?? '';
          _welcomeMessages =
              List<String>.from(welcomeConfig['welcome_messages'] ?? []);
          _welcomeButtonReplies =
              List<String>.from(welcomeConfig['welcome_button_replies'] ?? []);

          // Rocket League
          final promotionConfig = rlTextsConfig['promotion_config'] ?? {};
          _rlNotificationPrefixController.text =
              promotionConfig['notification_prefix'] ?? '';
          _rlEmbedTitleController.text = promotionConfig['embed_title'] ?? '';
          _rlEmbedDescriptionController.text =
              promotionConfig['embed_description'] ?? '';
          _rlCongratsReplies =
              List<String>.from(rlTextsConfig['congrats_replies'] ?? []);
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

  Future<void> _saveWelcomeConfig() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final config = {
        'rules_text': _rulesTextController.text,
        'welcome_messages': _welcomeMessages,
        'welcome_button_replies': _welcomeButtonReplies,
      };

      await authService.apiService.updateWelcomeConfig(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Welcome configuration saved successfully')),
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

  Future<void> _saveRocketLeagueTexts() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final config = {
        'promotion_config': {
          'notification_prefix': _rlNotificationPrefixController.text,
          'embed_title': _rlEmbedTitleController.text,
          'embed_description': _rlEmbedDescriptionController.text,
        },
        'congrats_replies': _rlCongratsReplies,
      };

      await authService.apiService.updateRocketLeagueTextsConfig(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Rocket League texts saved successfully')),
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

  Future<void> _resetWelcomeConfig() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Welcome Configuration?'),
        content: const Text(
          'This will reset all welcome system texts to their default values.\n\n'
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

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.resetWelcomeConfig();
      await _loadConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome configuration reset to defaults'),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetRocketLeagueTexts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Rocket League Texts?'),
        content: const Text(
          'This will reset all Rocket League message texts to their default values.\n\n'
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

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.resetRocketLeagueTextsConfig();
      await _loadConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rocket League texts reset to defaults'),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _welcomeMessages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 12.0 : 16.0;
        final cardPadding = isMobile ? 12.0 : 16.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Text Configuration',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: isMobile ? 24 : null,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure all bot text messages and replies',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 13 : null,
                      ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Welcome System Section
                _buildWelcomeSection(isMobile, cardPadding),
                SizedBox(height: isMobile ? 16 : 24),

                // Rocket League Section
                _buildRocketLeagueSection(isMobile, cardPadding),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(bool isMobile, double cardPadding) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.waving_hand,
                    color: Colors.blue, size: isMobile ? 20 : 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Welcome System',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: isMobile ? 18 : null,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Rules Text
            Text(
              'Server Rules Text',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _rulesTextController,
              decoration: const InputDecoration(
                hintText: 'Enter server rules text...',
                border: OutlineInputBorder(),
                helperText: 'Shown in the rules acceptance message',
              ),
              maxLines: 10,
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Welcome Messages
            _buildStringListEditor(
              title: 'Welcome Messages',
              subtitle:
                  'Random messages shown when users join (use {name} for username)',
              items: _welcomeMessages,
              onAdd: () => setState(() => _welcomeMessages.add('')),
              onRemove: (index) =>
                  setState(() => _welcomeMessages.removeAt(index)),
              onUpdate: (index, value) =>
                  setState(() => _welcomeMessages[index] = value),
              isMobile: isMobile,
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Welcome Button Replies
            _buildStringListEditor(
              title: 'Welcome Button Replies',
              subtitle:
                  'Random replies when someone clicks the welcome button (use {user} and {new_member})',
              items: _welcomeButtonReplies,
              onAdd: () => setState(() => _welcomeButtonReplies.add('')),
              onRemove: (index) =>
                  setState(() => _welcomeButtonReplies.removeAt(index)),
              onUpdate: (index, value) =>
                  setState(() => _welcomeButtonReplies[index] = value),
              isMobile: isMobile,
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Action Buttons
            if (isMobile)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _resetWelcomeConfig,
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
                      onPressed: _isLoading ? null : _saveWelcomeConfig,
                      icon: const Icon(Icons.save, size: 20),
                      label: const Text('Save Welcome Config',
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
                      onPressed: _isLoading ? null : _resetWelcomeConfig,
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
                      onPressed: _isLoading ? null : _saveWelcomeConfig,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Welcome Config'),
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
  }

  Widget _buildRocketLeagueSection(bool isMobile, double cardPadding) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch,
                    color: Colors.orange, size: isMobile ? 20 : 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Rocket League',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: isMobile ? 18 : null,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Rank Promotion Messages
            Text(
              'Rank Promotion Notification',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _rlNotificationPrefixController,
              decoration: const InputDecoration(
                labelText: 'Notification Prefix',
                hintText: 'Use {user} for mention',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rlEmbedTitleController,
              decoration: const InputDecoration(
                labelText: 'Embed Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rlEmbedDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Embed Description',
                hintText: 'Use {user}, {playlist}, {emoji}, {rank}',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Congrats Button Replies
            _buildStringListEditor(
              title: 'Congrats Button Replies',
              subtitle:
                  'Random replies when someone clicks congrats (use {user} and {ranked_user})',
              items: _rlCongratsReplies,
              onAdd: () => setState(() => _rlCongratsReplies.add('')),
              onRemove: (index) =>
                  setState(() => _rlCongratsReplies.removeAt(index)),
              onUpdate: (index, value) =>
                  setState(() => _rlCongratsReplies[index] = value),
              isMobile: isMobile,
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Action Buttons
            if (isMobile)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _resetRocketLeagueTexts,
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
                      onPressed: _isLoading ? null : _saveRocketLeagueTexts,
                      icon: const Icon(Icons.save, size: 20),
                      label: const Text('Save RL Texts',
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
                      onPressed: _isLoading ? null : _resetRocketLeagueTexts,
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
                      onPressed: _isLoading ? null : _saveRocketLeagueTexts,
                      icon: const Icon(Icons.save),
                      label: const Text('Save RL Texts'),
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
  }

  Widget _buildStringListEditor({
    required String title,
    required String subtitle,
    required List<String> items,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
    required void Function(int, String) onUpdate,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, size: isMobile ? 20 : 24),
              onPressed: onAdd,
              tooltip: 'Add new',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: value,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: '${index + 1}',
                      isDense: isMobile,
                    ),
                    onChanged: (newValue) => onUpdate(index, newValue),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete,
                      color: Colors.red, size: isMobile ? 20 : 24),
                  onPressed: () => onRemove(index),
                  tooltip: 'Remove',
                ),
              ],
            ),
          );
        }),
        if (items.isEmpty)
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.grey, size: isMobile ? 20 : 24),
                const SizedBox(width: 8),
                const Text('No items added yet. Click + to add.'),
              ],
            ),
          ),
      ],
    );
  }
}
