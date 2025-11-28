import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../services/auth_service.dart';
import '../../services/config_service.dart';

class GeneralConfigScreen extends StatefulWidget {
  const GeneralConfigScreen({super.key});

  @override
  State<GeneralConfigScreen> createState() => _GeneralConfigScreenState();
}

class _GeneralConfigScreenState extends State<GeneralConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;

  // Additional fields
  Color _pinkColor = const Color(0xFFAD1457);
  Map<String, String> _roleNames = {};

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final config = await authService.apiService.getGeneralConfig();

      _controllers['bot_name'] = TextEditingController(
        text: config['bot_name']?.toString() ?? '',
      );
      _controllers['command_prefix'] = TextEditingController(
        text: config['command_prefix']?.toString() ?? '',
      );
      _controllers['presence_update_interval'] = TextEditingController(
        text: config['presence_update_interval']?.toString() ?? '',
      );
      _controllers['message_cooldown'] = TextEditingController(
        text: config['message_cooldown']?.toString() ?? '',
      );
      _controllers['fuzzy_matching_threshold'] = TextEditingController(
        text: config['fuzzy_matching_threshold']?.toString() ?? '',
      );

      // Load color (RGB from backend -> add alpha channel for Flutter)
      if (config['pink_color'] != null) {
        final rgbValue = config['pink_color'] as int;
        // Add full opacity alpha channel (0xFF) to RGB value
        _pinkColor = Color(0xFF000000 | rgbValue);
      }

      // Load footer text
      _controllers['embed_footer_text'] = TextEditingController(
        text: config['embed_footer_text']?.toString() ?? '',
      );

      // Load role names
      if (config['role_names'] != null) {
        _roleNames = Map<String, String>.from(config['role_names']);
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading config: $e')),
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

    final authService = Provider.of<AuthService>(context, listen: false);
    final configService = Provider.of<ConfigService>(context, listen: false);

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final config = {
        'bot_name': _controllers['bot_name']!.text,
        'command_prefix': _controllers['command_prefix']!.text,
        'presence_update_interval': int.parse(_controllers['presence_update_interval']!.text),
        'message_cooldown': int.parse(_controllers['message_cooldown']!.text),
        'fuzzy_matching_threshold': double.parse(_controllers['fuzzy_matching_threshold']!.text),
        'pink_color': _pinkColor.value & 0xFFFFFF, // Remove alpha channel (RGB only)
        'embed_footer_text': _controllers['embed_footer_text']!.text,
        'role_names': _roleNames,
      };

      await configService.updateGeneralConfig(authService.apiService, config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving config: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          'This will reset all general settings to their default values. '
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
              backgroundColor: Colors.orange,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Call API to reset to defaults
      await authService.apiService.resetGeneralConfig();

      // Reload config to show defaults
      await _loadConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration reset to defaults successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting config: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addRoleName() async {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Role Display Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Role Key',
                hintText: 'e.g., user, mod, admin',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'e.g., 🎒 Lootling',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (keyController.text.isNotEmpty && valueController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'key': keyController.text.trim(),
                  'value': valueController.text.trim(),
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _roleNames[result['key']!] = result['value']!;
      });
    }
  }

  Future<void> _editRoleName(String key, String currentValue) async {
    final controller = TextEditingController(text: currentValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Role Display Name: $key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _roleNames[key] = result;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _controllers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final isMonet =
        Theme.of(context).colorScheme.surfaceContainerHigh != ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;
    final infoBoxBlue =
        isMonet ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.10) : Colors.blue.withOpacity(0.1);
    final infoBoxBlueBorder =
        isMonet ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.30) : Colors.blue.withOpacity(0.3);
    final infoBoxGreen =
        isMonet ? Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.10) : Colors.green.withOpacity(0.1);
    final infoBoxGreenBorder =
        isMonet ? Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.30) : Colors.green.withOpacity(0.3);
    final infoBoxPurple =
        isMonet ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.10) : Colors.purple.withOpacity(0.1);
    final infoBoxPurpleBorder =
        isMonet ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.30) : Colors.purple.withOpacity(0.3);
    final infoBoxTeal =
        isMonet ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.10) : Colors.teal.withOpacity(0.1);
    final infoBoxTealBorder =
        isMonet ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.30) : Colors.teal.withOpacity(0.3);
    final infoBoxGrey =
        isMonet ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.10) : Colors.grey.withOpacity(0.1);

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
                  'General Configuration',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: isMobile ? 24 : null,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure bot name, commands, and performance settings',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 13 : null,
                      ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Bot Settings Card
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.smart_toy, color: Colors.blue, size: isMobile ? 20 : 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bot Settings',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        TextFormField(
                          controller: _controllers['bot_name'],
                          decoration: InputDecoration(
                            labelText: 'Bot Name',
                            helperText: 'The display name of the bot',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.label),
                            isDense: isMobile,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a bot name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        TextFormField(
                          controller: _controllers['command_prefix'],
                          decoration: InputDecoration(
                            labelText: 'Command Prefix',
                            helperText: 'Prefix for text commands (e.g., !)',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.terminal),
                            isDense: isMobile,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a command prefix';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: infoBoxBlue,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: infoBoxBlueBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: isMobile ? 18 : 20, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'The bot name and prefix are used throughout Discord. '
                                  'Changes take effect after bot restart.',
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

                // Performance Settings Card
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.speed, color: Colors.green, size: isMobile ? 20 : 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Performance Settings',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        TextFormField(
                          controller: _controllers['presence_update_interval'],
                          decoration: InputDecoration(
                            labelText: 'Presence Update Interval (seconds)',
                            helperText: 'How often to update the bot\'s presence status',
                            helperMaxLines: isMobile ? 2 : 1,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.timer),
                            suffixText: 's',
                            isDense: isMobile,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an interval';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        TextFormField(
                          controller: _controllers['message_cooldown'],
                          decoration: InputDecoration(
                            labelText: 'Message Cooldown (seconds)',
                            helperText: 'Cooldown between user messages',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.pause_circle),
                            suffixText: 's',
                            isDense: isMobile,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a cooldown';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        TextFormField(
                          controller: _controllers['fuzzy_matching_threshold'],
                          decoration: InputDecoration(
                            labelText: 'Fuzzy Matching Threshold',
                            helperText: 'Similarity threshold for command matching (0.0-1.0)',
                            helperMaxLines: isMobile ? 2 : 1,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.find_in_page),
                            isDense: isMobile,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a threshold';
                            }
                            final num = double.tryParse(value);
                            if (num == null || num < 0 || num > 1) {
                              return 'Please enter a number between 0.0 and 1.0';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: infoBoxGreen,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: infoBoxGreenBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: isMobile ? 18 : 20, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Lower cooldown = faster responses. '
                                  'Higher threshold = stricter command matching. '
                                  'Recommended: 5s cooldown, 0.6 threshold.',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.green[700],
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

                // Color Scheme Card
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.palette, color: Colors.purple, size: isMobile ? 20 : 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Color Scheme',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: isMobile ? 36 : 40,
                            height: isMobile ? 36 : 40,
                            decoration: BoxDecoration(
                              color: _pinkColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                          ),
                          title: Text('Primary Pink Color', style: TextStyle(fontSize: isMobile ? 14 : null)),
                          subtitle: Text(
                            '#${_pinkColor.value.toRadixString(16).substring(2).toUpperCase()}',
                            style: TextStyle(fontSize: isMobile ? 12 : null),
                          ),
                          trailing: ElevatedButton.icon(
                            onPressed: () async {
                              final Color? newColor = await showColorPickerDialog(
                                context,
                                _pinkColor,
                                title: Text('Select Pink Color', style: Theme.of(context).textTheme.titleLarge),
                                width: 40,
                                height: 40,
                                spacing: 0,
                                runSpacing: 0,
                                borderRadius: 4,
                                wheelDiameter: 165,
                                enableOpacity: false,
                                showColorCode: true,
                                colorCodeHasColor: true,
                                pickersEnabled: <ColorPickerType, bool>{
                                  ColorPickerType.both: false,
                                  ColorPickerType.primary: true,
                                  ColorPickerType.accent: true,
                                  ColorPickerType.wheel: true,
                                  ColorPickerType.custom: false,
                                },
                              );
                              if (newColor != null) {
                                setState(() => _pinkColor = newColor);
                              }
                            },
                            icon: Icon(Icons.colorize, size: isMobile ? 18 : null),
                            label: Text('Pick Color', style: TextStyle(fontSize: isMobile ? 13 : null)),
                          ),
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: infoBoxPurple,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: infoBoxPurpleBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: isMobile ? 18 : 20, color: Colors.purple[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This color is used for embeds and important messages throughout the bot.',
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
                SizedBox(height: isMobile ? 12 : 16),

                // Embed Footer Text Card
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.text_fields, color: Colors.teal, size: isMobile ? 20 : 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Embed Footer Text',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        TextFormField(
                          controller: _controllers['embed_footer_text'],
                          decoration: InputDecoration(
                            labelText: 'Footer Text',
                            hintText: 'Powered by Haze World 💖',
                            prefixIcon: const Icon(Icons.notes),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Footer text cannot be empty';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: infoBoxTeal,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: infoBoxTealBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: isMobile ? 18 : 20, color: Colors.teal[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This text appears in the footer of all bot embeds.',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.teal[700],
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

                // Role Names Card
                Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.label, color: Colors.orange, size: isMobile ? 20 : 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Role Display Names',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontSize: isMobile ? 18 : null,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, size: isMobile ? 20 : 24),
                              onPressed: () => _addRoleName(),
                              tooltip: 'Add Role Name',
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        if (_roleNames.isEmpty)
                          Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            decoration: BoxDecoration(
                              color: infoBoxGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.grey, size: isMobile ? 20 : 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No custom role names defined.\nClick + to add one.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: isMobile ? 12 : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._roleNames.entries
                              .map((entry) => ListTile(
                                    contentPadding: isMobile ? const EdgeInsets.symmetric(horizontal: 4) : null,
                                    leading: Icon(Icons.label, size: isMobile ? 20 : 24),
                                    title: Text(entry.value, style: TextStyle(fontSize: isMobile ? 14 : null)),
                                    subtitle:
                                        Text('Key: ${entry.key}', style: TextStyle(fontSize: isMobile ? 12 : null)),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete, size: isMobile ? 20 : 24),
                                      onPressed: () {
                                        setState(() {
                                          _roleNames.remove(entry.key);
                                        });
                                      },
                                    ),
                                    onTap: () => _editRoleName(entry.key, entry.value),
                                  ))
                              .toList(),
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
                          label: const Text('Reset to Defaults', style: TextStyle(fontSize: 14)),
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save, size: 20),
                          label: const Text('Save Configuration', style: TextStyle(fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _resetToDefaults,
                        icon: const Icon(Icons.restore),
                        label: const Text('Reset to Defaults'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          foregroundColor: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveConfig,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Save Configuration'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
