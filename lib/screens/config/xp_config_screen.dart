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
  
  // NEW: Meme Activities Extended
  final _memePostController = TextEditingController();
  final _memeGeneratePostController = TextEditingController();
  final _memeLikeController = TextEditingController();
  
  // NEW: Rocket League XP
  final _rlAccountLinkedController = TextEditingController();
  final _rlStatsCheckedController = TextEditingController();
  
  // NEW: Mod Activities Extended
  final _ticketClaimedController = TextEditingController();
  
  // NEW: Community Posts & Engagement
  final _communityPostCreateController = TextEditingController();
  final _communityPostLikeController = TextEditingController();

  // Level Calculation Controllers
  final _baseXpController = TextEditingController();
  final _multiplierController = TextEditingController();

  // Cooldown Controllers
  final _messageController = TextEditingController();
  final _imageController = TextEditingController();

  // Level Tier Data
  Map<String, dynamic> _levelTiers = {};
  Map<String, String> _levelIcons = {};
  Map<String, int> _levelTierRoles = {};

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
    _memePostController.dispose();
    _memeGeneratePostController.dispose();
    _memeLikeController.dispose();
    _rlAccountLinkedController.dispose();
    _rlStatsCheckedController.dispose();
    _ticketClaimedController.dispose();
    _communityPostCreateController.dispose();
    _communityPostLikeController.dispose();
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
            _memeGeneratedController.text =
                activityXp['meme_generate'].toString();
            _ticketCreatedController.text =
                activityXp['ticket_created'].toString();
            _ticketResolvedController.text =
                activityXp['ticket_resolved'].toString();
            _gameRequestController.text = activityXp['game_request'].toString();
            
            // NEW: Extended XP Rewards with fallback values
            _memePostController.text = activityXp['meme_post']?.toString() ?? '5';
            _memeGeneratePostController.text = activityXp['meme_generate_post']?.toString() ?? '8';
            _memeLikeController.text = activityXp['meme_like']?.toString() ?? '2';
            _rlAccountLinkedController.text = activityXp['rl_account_linked']?.toString() ?? '20';
            _rlStatsCheckedController.text = activityXp['rl_stats_checked']?.toString() ?? '5';
            _ticketClaimedController.text = activityXp['ticket_claimed']?.toString() ?? '15';
            _communityPostCreateController.text = activityXp['community_post_create']?.toString() ?? '15';
            _communityPostLikeController.text = activityXp['community_post_like']?.toString() ?? '2';

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
            _levelIcons = Map<String, String>.from(config['level_icons'] ?? {});
            
            // NEW: Level Tier Roles
            _levelTierRoles = Map<String, int>.from(config['level_tier_roles'] ?? {});
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
          'meme_post': int.parse(_memePostController.text),
          'meme_generate_post': int.parse(_memeGeneratePostController.text),
          'meme_like': int.parse(_memeLikeController.text),
          'rl_account_linked': int.parse(_rlAccountLinkedController.text),
          'rl_stats_checked': int.parse(_rlStatsCheckedController.text),
          'ticket_claimed': int.parse(_ticketClaimedController.text),
          'community_post_create': int.parse(_communityPostCreateController.text),
          'community_post_like': int.parse(_communityPostLikeController.text),
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
            content: Text(
                response['message'] ?? 'XP configuration saved successfully'),
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
                Text('Activity XP Rewards', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure XP rewards for different activities. Expand categories to edit values.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            
            _buildXpCategoryTile(
              title: '💬 Basic Activities',
              subtitle: '2 rewards • Messages and images',
              icon: Icons.chat_bubble_outline,
              fields: [
                _buildCompactXpField(_messageSentController, '💬 Message Sent', 'XP for sending a message'),
                _buildCompactXpField(_imageSentController, '🖼️ Image Sent', 'XP for sending an image'),
              ],
            ),
            
            const SizedBox(height: 8),
            
            _buildXpCategoryTile(
              title: '😂 Meme Activities',
              subtitle: '5 rewards • Fetch, generate, post, and like memes',
              icon: Icons.emoji_emotions,
              fields: [
                _buildCompactXpField(_memeFetchedController, '😂 Meme Fetched', 'XP for fetching a meme'),
                _buildCompactXpField(_memeGeneratedController, '🎨 Meme Generated', 'XP for generating a custom meme'),
                _buildCompactXpField(_memePostController, '📤 Meme Posted (Fetched)', 'XP for posting a fetched meme to Discord'),
                _buildCompactXpField(_memeGeneratePostController, '🚀 Meme Posted (Generated)', 'XP for posting a generated meme'),
                _buildCompactXpField(_memeLikeController, '👍 Meme Liked', 'XP for liking a meme'),
              ],
            ),
            
            const SizedBox(height: 8),
            
            _buildXpCategoryTile(
              title: '✨ Community Posts',
              subtitle: '2 rewards • Create and like posts',
              icon: Icons.dynamic_feed,
              fields: [
                _buildCompactXpField(_communityPostCreateController, '✨ Post Created', 'XP for creating a community post'),
                _buildCompactXpField(_communityPostLikeController, '❤️ Post Liked', 'XP for liking a post'),
              ],
            ),
            
            const SizedBox(height: 8),
            
            _buildXpCategoryTile(
              title: '🎫 Support & Tickets',
              subtitle: '3 rewards • Create, claim, resolve tickets',
              icon: Icons.support_agent,
              fields: [
                _buildCompactXpField(_ticketCreatedController, '🎫 Ticket Created', 'XP for creating a support ticket'),
                _buildCompactXpField(_ticketClaimedController, '🛡️ Ticket Claimed', 'XP for claiming a ticket (Mod only)'),
                _buildCompactXpField(_ticketResolvedController, '✅ Ticket Resolved', 'XP for resolving a ticket (Mod only)'),
              ],
            ),
            
            const SizedBox(height: 8),
            
            _buildXpCategoryTile(
              title: '🎮 Gaming',
              subtitle: '3 rewards • Game requests and Rocket League',
              icon: Icons.sports_esports,
              fields: [
                _buildCompactXpField(_gameRequestController, '🎮 Game Request', 'XP for creating a gaming request'),
                _buildCompactXpField(_rlAccountLinkedController, '🚀 RL Account Linked', 'One-time XP for linking Rocket League'),
                _buildCompactXpField(_rlStatsCheckedController, '📊 RL Stats Checked', 'XP for checking RL stats'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildXpCategoryTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> fields,
    bool initiallyExpanded = false,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        collapsedBackgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        children: fields,
      ),
    );
  }
  
  Widget _buildCompactXpField(
    TextEditingController controller,
    String label,
    String tooltip,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: tooltip,
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixText: 'XP',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue < 0) return 'Invalid';
                  return null;
                },
              ),
            ),
          ),
        ],
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
                Icon(Icons.functions,
                    color: Theme.of(context).colorScheme.primary),
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
                Icon(Icons.military_tech,
                    color: Theme.of(context).colorScheme.primary),
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
                    final aLevel = (a.value
                            as Map<String, dynamic>)['min_level'] as int? ??
                        0;
                    final bLevel = (b.value
                            as Map<String, dynamic>)['min_level'] as int? ??
                        0;
                    return bLevel.compareTo(aLevel); // Descending order
                  }))
                .map((entry) {
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
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tierName.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getColorFromHex(color),
                          fontSize: 16,
                        ),
                      ),
                      if (tierData['name'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          tierData['name'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Level $minLevel+'),
                      if (tierData['description'] != null)
                        Text(
                          tierData['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      if (_levelTierRoles.containsKey(tierName)) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Discord Role ID: ${_levelTierRoles[tierName]}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
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
