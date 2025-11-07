import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class DailyMemePreferencesScreen extends StatefulWidget {
  const DailyMemePreferencesScreen({super.key});

  @override
  State<DailyMemePreferencesScreen> createState() =>
      _DailyMemePreferencesScreenState();
}

class _DailyMemePreferencesScreenState
    extends State<DailyMemePreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Selection Settings
  double _minScore = 100;
  final _maxSourcesController = TextEditingController();
  final _poolSizeController = TextEditingController();

  // Source selection
  List<String> _availableSubreddits = [];
  List<String> _availableLemmy = [];
  List<String> _selectedSubreddits = [];
  List<String> _selectedLemmy = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _maxSourcesController.dispose();
    _poolSizeController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final config = await authService.apiService.getDailyMemeConfig();

      setState(() {
        _minScore = (config['min_score'] ?? 100).toDouble();
        _maxSourcesController.text = (config['max_sources'] ?? 5).toString();
        _poolSizeController.text = (config['pool_size'] ?? 50).toString();

        // Load available sources
        _availableSubreddits =
            List<String>.from(config['available_subreddits'] ?? []);
        _availableLemmy = List<String>.from(config['available_lemmy'] ?? []);

        // Load selected sources
        // Note: Empty list means none selected, not all selected
        final useSubreddits = config['use_subreddits'];
        final useLemmy = config['use_lemmy'];

        // If use_subreddits is null or not present, default to all
        // If it's an empty list [], keep it empty
        // If it has items, use those items
        if (useSubreddits == null) {
          _selectedSubreddits = List.from(_availableSubreddits);
        } else {
          _selectedSubreddits = List<String>.from(useSubreddits);
        }

        if (useLemmy == null) {
          _selectedLemmy = List.from(_availableLemmy);
        } else {
          _selectedLemmy = List<String>.from(useLemmy);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation: At least one source must be selected
    if (_selectedSubreddits.isEmpty && _selectedLemmy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one source (Reddit or Lemmy) must be selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final config = {
        'min_score': _minScore.toInt(),
        'max_sources': int.parse(_maxSourcesController.text),
        'pool_size': int.parse(_poolSizeController.text),
        // Send the selected lists (empty list = none, full list = all, partial = those selected)
        'use_subreddits': _selectedSubreddits,
        'use_lemmy': _selectedLemmy,
      };

      await authService.apiService.updateDailyMemeConfig(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will reset all selection preferences to their default values:\n\n'
          '• Min Score: 100\n'
          '• Max Sources: 5\n'
          '• Pool Size: 50\n'
          '• All subreddits enabled\n'
          '• All Lemmy communities enabled\n\n'
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
          const SnackBar(content: Text('Preferences reset to defaults')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting preferences: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
                          Icon(Icons.tune,
                              size: isMobile ? 28 : 32,
                              color: Theme.of(context).colorScheme.primary),
                          SizedBox(width: isMobile ? 8 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Meme Preferences',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontSize: isMobile ? 24 : null,
                                      ),
                                ),
                                Text(
                                  'Fine-tune meme selection criteria and choose which sources to use',
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

                      // Info Box (keeping the existing one)
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
                                'Configure how memes are selected and which sources are used.',
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

                      // Selection Settings
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.tune,
                                      color: Colors.green,
                                      size: isMobile ? 20 : 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Selection Criteria',
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

                              // Min Score Slider
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Minimum Score: ${_minScore.toInt()}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: isMobile ? 13 : null,
                                        ),
                                  ),
                                  Text(
                                    'Minimum upvotes required for a meme',
                                    style: TextStyle(
                                        fontSize: isMobile ? 11 : 12,
                                        color: Colors.grey),
                                  ),
                                  Slider(
                                    value: _minScore,
                                    min: 0,
                                    max: 10000,
                                    divisions: 100,
                                    label: _minScore.toInt().toString(),
                                    onChanged: (value) =>
                                        setState(() => _minScore = value),
                                  ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 12 : 16),

                              // Max Sources
                              TextFormField(
                                controller: _maxSourcesController,
                                decoration: InputDecoration(
                                  labelText: 'Max Sources',
                                  hintText: 'Number of sources to fetch from',
                                  helperText:
                                      'How many subreddits/communities to use',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.source),
                                  isDense: isMobile,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final num = int.tryParse(value);
                                  if (num == null || num < 1 || num > 20) {
                                    return 'Must be 1-20';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isMobile ? 12 : 16),

                              // Pool Size
                              TextFormField(
                                controller: _poolSizeController,
                                decoration: InputDecoration(
                                  labelText: 'Pool Size',
                                  hintText: 'Number of memes in selection pool',
                                  helperText: 'Pick from top X memes',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.pool),
                                  isDense: isMobile,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final num = int.tryParse(value);
                                  if (num == null || num < 10 || num > 200) {
                                    return 'Must be 10-200';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),

                      // Subreddit Selection
                      if (_availableSubreddits.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.reddit,
                                              color: Colors.deepOrange,
                                              size: isMobile ? 20 : 24),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Reddit Sources',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontSize:
                                                        isMobile ? 16 : null,
                                                  ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.deepOrange
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${_selectedSubreddits.length}/${_availableSubreddits.length}',
                                              style: TextStyle(
                                                fontSize: isMobile ? 11 : 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.deepOrange[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          if (_selectedSubreddits.length ==
                                              _availableSubreddits.length) {
                                            _selectedSubreddits.clear();
                                          } else {
                                            _selectedSubreddits =
                                                List.from(_availableSubreddits);
                                          }
                                        });
                                      },
                                      child: Text(
                                        _selectedSubreddits.length ==
                                                _availableSubreddits.length
                                            ? 'Deselect All'
                                            : 'Select All',
                                        style: TextStyle(
                                            fontSize: isMobile ? 12 : null),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                ..._availableSubreddits
                                    .map((subreddit) => CheckboxListTile(
                                          title: Text(
                                            'r/$subreddit',
                                            style: TextStyle(
                                                fontSize: isMobile ? 13 : null),
                                          ),
                                          value: _selectedSubreddits
                                              .contains(subreddit),
                                          onChanged: (checked) {
                                            setState(() {
                                              if (checked == true) {
                                                _selectedSubreddits
                                                    .add(subreddit);
                                              } else {
                                                // Don't allow deselecting if it's the last source
                                                if (_selectedSubreddits.length > 1 ||
                                                    _selectedLemmy.isNotEmpty) {
                                                  _selectedSubreddits
                                                      .remove(subreddit);
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'At least one source must be selected'),
                                                      duration:
                                                          Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              }
                                            });
                                          },
                                          dense: true,
                                        )),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                      ],

                      // Lemmy Selection
                      if (_availableLemmy.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.group,
                                              color: Colors.teal,
                                              size: isMobile ? 20 : 24),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Lemmy Sources',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontSize:
                                                        isMobile ? 16 : null,
                                                  ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.teal
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${_selectedLemmy.length}/${_availableLemmy.length}',
                                              style: TextStyle(
                                                fontSize: isMobile ? 11 : 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.teal[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          if (_selectedLemmy.length ==
                                              _availableLemmy.length) {
                                            _selectedLemmy.clear();
                                          } else {
                                            _selectedLemmy =
                                                List.from(_availableLemmy);
                                          }
                                        });
                                      },
                                      child: Text(
                                        _selectedLemmy.length ==
                                                _availableLemmy.length
                                            ? 'Deselect All'
                                            : 'Select All',
                                        style: TextStyle(
                                            fontSize: isMobile ? 12 : null),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                ..._availableLemmy.map((community) =>
                                    CheckboxListTile(
                                      title: Text(
                                        community,
                                        style: TextStyle(
                                            fontSize: isMobile ? 13 : null),
                                      ),
                                      value: _selectedLemmy.contains(community),
                                      onChanged: (checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedLemmy.add(community);
                                          } else {
                                            // Don't allow deselecting if it's the last source
                                            if (_selectedLemmy.length > 1 ||
                                                _selectedSubreddits.isNotEmpty) {
                                              _selectedLemmy.remove(community);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'At least one source must be selected'),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          }
                                        });
                                      },
                                      dense: true,
                                    )),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                      ],

                      // Action Buttons
                      if (isMobile)
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _resetToDefaults,
                                icon: const Icon(Icons.restore),
                                label: const Text('Reset to Defaults'),
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
                                onPressed: _isLoading ? null : _savePreferences,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(_isLoading
                                    ? 'Saving...'
                                    : 'Save Preferences'),
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
                                onPressed: _isLoading ? null : _savePreferences,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(_isLoading
                                    ? 'Saving...'
                                    : 'Save Preferences'),
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
