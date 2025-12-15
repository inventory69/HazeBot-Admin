import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class XpConfigScreen extends StatefulWidget {
  const XpConfigScreen({super.key});

  @override
  State<XpConfigScreen> createState() => _XpConfigScreenState();
}

class _XpConfigScreenState extends State<XpConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  // Activity XP Controllers
  final _messageSentController = TextEditingController();
  final _imageSentController = TextEditingController();
  final _memeFetchedController = TextEditingController();
  final _memeGeneratedController = TextEditingController();
  final _ticketCreatedController = TextEditingController();
  final _ticketResolvedController = TextEditingController();
  final _gameRequestController = TextEditingController();

  // Level Calculation Controllers
  final _baseXpController = TextEditingController();
  final _multiplierController = TextEditingController();

  // Cooldown Controllers
  final _messageController = TextEditingController();
  final _imageController = TextEditingController();

  // Level Tier Data
  Map<String, dynamic> _levelTiers = {};
  Map<String, String> _levelIcons = {};

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _messageSentController.dispose();
    _imageSentController.dispose();
    _memeFetchedController.dispose();
    _memeGeneratedController.dispose();
    _ticketCreatedController.dispose();
    _ticketResolvedController.dispose();
    _gameRequestController.dispose();
    _baseXpController.dispose();
    _multiplierController.dispose();
    _messageController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.apiService.getXpConfig();
      
      if (response['success'] == true) {
        final config = response['config'];
        
        if (mounted) {
          setState(() {
            // Activity XP
            final activityXp = config['activity_xp'];
            _messageSentController.text = activityXp['message_sent'].toString();
            _imageSentController.text = activityXp['image_sent'].toString();
            _memeFetchedController.text = activityXp['meme_fetch'].toString();
            _memeGeneratedController.text = activityXp['meme_generate'].toString();
            _ticketCreatedController.text = activityXp['ticket_created'].toString();
            _ticketResolvedController.text = activityXp['ticket_resolved'].toString();
            _gameRequestController.text = activityXp['game_request'].toString();

            // Level Calculation
            final levelCalc = config['level_calculation'];
            _baseXpController.text = levelCalc['base_xp_per_level'].toString();
            _multiplierController.text = levelCalc['xp_multiplier'].toString();

            // Cooldowns
            final cooldowns = config['cooldowns'];
            _messageController.text = cooldowns['message_cooldown'].toString();
            _imageController.text = cooldowns['meme_fetch_cooldown'].toString();

            // Tiers and Icons
            _levelTiers = Map<String, dynamic>.from(config['level_tiers']);
            _levelIcons = Map<String, String>.from(config['level_icons']);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading XP configuration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (mounted) {
      setState(() => _isSaving = true);
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final configData = {
        'activity_xp': {
          'message_sent': int.parse(_messageSentController.text),
          'image_sent': int.parse(_imageSentController.text),
          'meme_fetch': int.parse(_memeFetchedController.text),
          'meme_generate': int.parse(_memeGeneratedController.text),
          'ticket_created': int.parse(_ticketCreatedController.text),
          'ticket_resolved': int.parse(_ticketResolvedController.text),
          'game_request': int.parse(_gameRequestController.text),
        },
        'level_calculation': {
          'base_xp_per_level': int.parse(_baseXpController.text),
          'xp_multiplier': double.parse(_multiplierController.text),
        },
        'cooldowns': {
          'message_cooldown': int.parse(_messageController.text),
          'meme_fetch_cooldown': int.parse(_imageController.text),
        },
      };

      final response = await authService.apiService.updateXpConfig(configData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'XP configuration saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving XP configuration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _resetToDefaults() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will reset all XP system settings to their default values. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Call API to reset to defaults
      final response = await authService.apiService.resetXpConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configuration reset to defaults successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload config
        await _loadConfig();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('XP System Configuration'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadConfig,
              tooltip: 'Reload Configuration',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActivityXpSection(),
                    const SizedBox(height: 24),
                    _buildLevelCalculationSection(),
                    const SizedBox(height: 24),
                    _buildCooldownsSection(),
                    const SizedBox(height: 24),
                    _buildTiersSection(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActivityXpSection() {
    // Monet-aware card color
    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;
    
    return Card(
      elevation: 0,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Activity XP Rewards',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure how much XP users earn for different activities',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildXpTextField(
              controller: _messageSentController,
              label: '💬 Message Sent',
              tooltip: 'XP earned for sending a message',
            ),
            const SizedBox(height: 12),
            _buildXpTextField(
              controller: _imageSentController,
              label: '🖼️ Image Sent',
              tooltip: 'XP earned for sending an image',
            ),
            const SizedBox(height: 12),
            _buildXpTextField(
              controller: _memeFetchedController,
              label: '😂 Meme Fetched',
              tooltip: 'XP earned for fetching a meme',
            ),
            const SizedBox(height: 12),
            _buildXpTextField(
              controller: _memeGeneratedController,
              label: '🎨 Meme Generated',
              tooltip: 'XP earned for generating a meme',
            ),
            const SizedBox(height: 12),
            _buildXpTextField(
              controller: _ticketCreatedController,
              label: '🎫 Ticket Created',
              tooltip: 'XP earned for creating a support ticket',
            ),
            const SizedBox(height: 12),
            _buildXpTextField(
              controller: _ticketResolvedController,
              label: '✅ Ticket Resolved',
              tooltip: 'XP earned for resolving a support ticket',
            ),
            const SizedBox(height: 12),
            _buildXpTextField(
              controller: _gameRequestController,
              label: '🎮 Game Request',
              tooltip: 'XP earned for creating a gaming request',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCalculationSection() {
    // Monet-aware card color
    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;
    
    return Card(
      elevation: 0,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.functions, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Level Calculation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure the formula for calculating XP required for each level',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildXpTextField(
              controller: _baseXpController,
              label: '📊 Base XP',
              tooltip: 'Base XP required for level 2 (default: 100)',
            ),
            const SizedBox(height: 12),
            _buildDecimalTextField(
              controller: _multiplierController,
              label: '📈 Multiplier',
              tooltip: 'Multiplier applied to each level (default: 1.5)',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formula:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'XP for level N = base_xp × multiplier^(N-2)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Example: With base_xp=100 and multiplier=1.5:\n'
                    '• Level 2: 100 XP\n'
                    '• Level 3: 150 XP\n'
                    '• Level 4: 225 XP',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCooldownsSection() {
    // Monet-aware card color
    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;
    
    return Card(
      elevation: 0,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'XP Gain Cooldowns',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Prevent XP farming by setting cooldown periods (in seconds)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildXpTextField(
              controller: _messageController,
              label: '💬 Message Cooldown',
              tooltip: 'Cooldown between message XP gains (seconds)',
            ),
            const SizedBox(height: 12),
            _buildXpTextField(
              controller: _imageController,
              label: '😂 Meme Fetch Cooldown',
              tooltip: 'Cooldown between meme fetch XP gains (seconds)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiersSection() {
    // Monet-aware card color
    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;
    
    return Card(
      elevation: 0,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.military_tech, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Level Tiers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'View configured level tiers and their icons (read-only)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            // Sort tiers by min_level descending (50 -> 1, Legendary -> Common)
            ...(_levelTiers.entries.toList()
              ..sort((a, b) {
                final aLevel = (a.value as Map<String, dynamic>)['min_level'] as int? ?? 0;
                final bLevel = (b.value as Map<String, dynamic>)['min_level'] as int? ?? 0;
                return bLevel.compareTo(aLevel); // Descending order
              })
            ).map((entry) {
              final tierName = entry.key;
              final tierData = entry.value as Map<String, dynamic>;
              final emoji = tierData['emoji'] as String? ?? '⭐';
              final minLevel = tierData['min_level'] as int? ?? 1;
              final color = tierData['color'] as String? ?? '#808080';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: Text(
                    emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    tierName.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorFromHex(color),
                    ),
                  ),
                  subtitle: Text('Level $minLevel+'),
                  tileColor: Theme.of(context).colorScheme.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildXpTextField({
    required TextEditingController controller,
    required String label,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixText: 'XP',
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          final intValue = int.tryParse(value);
          if (intValue == null || intValue < 0) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDecimalTextField({
    required TextEditingController controller,
    required String label,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          final doubleValue = double.tryParse(value);
          if (doubleValue == null || doubleValue <= 0) {
            return 'Please enter a valid positive number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _saveConfig,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save Configuration'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading || _isSaving ? null : _resetToDefaults,
            icon: const Icon(Icons.restore),
            label: const Text('Reset to Defaults'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              foregroundColor: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
