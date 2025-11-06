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

        // Load selected sources (empty = all selected)
        final useSubreddits = List<String>.from(config['use_subreddits'] ?? []);
        final useLemmy = List<String>.from(config['use_lemmy'] ?? []);

        _selectedSubreddits = useSubreddits.isEmpty
            ? List.from(_availableSubreddits)
            : useSubreddits;
        _selectedLemmy =
            useLemmy.isEmpty ? List.from(_availableLemmy) : useLemmy;
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

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final config = {
        'min_score': _minScore.toInt(),
        'max_sources': int.parse(_maxSourcesController.text),
        'pool_size': int.parse(_poolSizeController.text),
        // If all selected, send empty array (= use all)
        'use_subreddits':
            _selectedSubreddits.length == _availableSubreddits.length
                ? []
                : _selectedSubreddits,
        'use_lemmy': _selectedLemmy.length == _availableLemmy.length
            ? []
            : _selectedLemmy,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Meme Preferences'),
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
                    // Selection Settings
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selection Criteria',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),

                            // Min Score Slider
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Minimum Score: ${_minScore.toInt()}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Text(
                                  'Minimum upvotes required for a meme',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
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
                            const SizedBox(height: 16),

                            // Max Sources
                            TextFormField(
                              controller: _maxSourcesController,
                              decoration: const InputDecoration(
                                labelText: 'Max Sources',
                                hintText: 'Number of sources to fetch from',
                                helperText:
                                    'How many subreddits/communities to use',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.source),
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
                            const SizedBox(height: 16),

                            // Pool Size
                            TextFormField(
                              controller: _poolSizeController,
                              decoration: const InputDecoration(
                                labelText: 'Pool Size',
                                hintText: 'Number of memes in selection pool',
                                helperText: 'Pick from top X memes',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.pool),
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
                    const SizedBox(height: 16),

                    // Subreddit Selection
                    if (_availableSubreddits.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Reddit Sources',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
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
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              ..._availableSubreddits.map((subreddit) =>
                                  CheckboxListTile(
                                    title: Text('r/$subreddit'),
                                    value:
                                        _selectedSubreddits.contains(subreddit),
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _selectedSubreddits.add(subreddit);
                                        } else {
                                          _selectedSubreddits.remove(subreddit);
                                        }
                                      });
                                    },
                                    dense: true,
                                  )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Lemmy Selection
                    if (_availableLemmy.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Lemmy Sources',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
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
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              ..._availableLemmy
                                  .map((community) => CheckboxListTile(
                                        title: Text(community),
                                        value:
                                            _selectedLemmy.contains(community),
                                        onChanged: (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              _selectedLemmy.add(community);
                                            } else {
                                              _selectedLemmy.remove(community);
                                            }
                                          });
                                        },
                                        dense: true,
                                      )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                            onPressed: _isLoading ? null : _savePreferences,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Preferences'),
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
