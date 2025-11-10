import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

/// Helper function to proxy external images through our backend to bypass CORS
String getProxiedImageUrl(String originalUrl) {
  // Proxy external images (Reddit, Imgur, Imgflip)
  if (originalUrl.contains('i.redd.it') ||
      originalUrl.contains('i.imgur.com') ||
      originalUrl.contains('preview.redd.it') ||
      originalUrl.contains('external-preview.redd.it') ||
      originalUrl.contains('imgflip.com')) {
    // Use our backend proxy
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return 'https://test-hazebot-admin.hzwd.xyz/api/proxy/image?url=$encodedUrl';
  }
  // For other URLs, return as-is
  return originalUrl;
}

class MemeGeneratorScreen extends StatefulWidget {
  const MemeGeneratorScreen({super.key});

  @override
  State<MemeGeneratorScreen> createState() => _MemeGeneratorScreenState();
}

class _MemeGeneratorScreenState extends State<MemeGeneratorScreen> {
  bool _isLoadingTemplates = true;
  bool _isRefreshing = false;
  bool _isGenerating = false;
  bool _isSendingToDiscord = false;
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _filteredTemplates = [];
  Map<String, dynamic>? _selectedTemplate;
  String? _generatedMemeUrl;
  List<String>? _generatedMemeTexts;
  String? _errorMessage;
  int _currentPage = 0;
  final int _templatesPerPage = 12;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoadingTemplates = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.getMemeTemplates();

      setState(() {
        _templates = List<Map<String, dynamic>>.from(result['templates'] ?? []);
        _filteredTemplates = _templates;
        _isLoadingTemplates = false;
        // Auto-select first template
        if (_filteredTemplates.isNotEmpty) {
          _selectedTemplate = _filteredTemplates[0];
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading templates: $e';
        _isLoadingTemplates = false;
      });
    }
  }

  Future<void> _refreshTemplates() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.refreshMemeTemplates();

      // Reload templates after refresh
      await _loadTemplates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Templates refreshed successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

      setState(() {
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error refreshing templates: $e';
        _isRefreshing = false;
      });
    }
  }

  void _filterTemplates(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTemplates = _templates;
      } else {
        _filteredTemplates = _templates
            .where((template) => template['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
      _currentPage = 0; // Reset to first page when searching
      // Auto-select first template of filtered results
      if (_filteredTemplates.isNotEmpty) {
        _selectedTemplate = _filteredTemplates[0];
      }
    });
  }

  void _showCreateMemeDialog() {
    if (_selectedTemplate == null) return;

    final boxCount = _selectedTemplate!['box_count'] ?? 2;
    final templateName = _selectedTemplate!['name'] ?? 'Meme';

    // Create text controllers for each box
    final textControllers = List.generate(
      boxCount > 5 ? 5 : boxCount, // Limit to 5 fields
      (index) => TextEditingController(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎨 Create: $templateName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(textControllers.length, (index) {
                final labels = [
                  'Top Text',
                  'Bottom Text',
                  'Middle Text',
                  'Text Box 4',
                  'Text Box 5'
                ];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextField(
                    controller: textControllers[index],
                    decoration: InputDecoration(
                      labelText: labels[index],
                      hintText: 'Enter text for box ${index + 1}...',
                      border: const OutlineInputBorder(),
                    ),
                    maxLength: 200,
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              for (var controller in textControllers) {
                controller.dispose();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final texts = textControllers.map((c) => c.value.text).toList();

              // Check if at least one field has text
              if (!texts.any((text) => text.isNotEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide at least one text field!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(context).pop(); // Close dialog

              // Generate meme
              await _generateMeme(texts);

              // Dispose controllers
              for (var controller in textControllers) {
                controller.dispose();
              }
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Preview'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateMeme(List<String> texts) async {
    if (_selectedTemplate == null) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedMemeUrl = null;
      _generatedMemeTexts = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.generateMeme(
        _selectedTemplate!['id'].toString(),
        texts,
      );

      setState(() {
        _generatedMemeUrl = result['url'];
        _generatedMemeTexts = texts;
        _isGenerating = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Meme generated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating meme: $e';
        _isGenerating = false;
      });
    }
  }

  Future<void> _sendMemeToDiscord() async {
    if (_generatedMemeUrl == null || _selectedTemplate == null) return;

    setState(() {
      _isSendingToDiscord = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.postGeneratedMemeToDiscord(
        _generatedMemeUrl!,
        _selectedTemplate!['name'],
        _generatedMemeTexts ?? [],
      );

      setState(() {
        _isSendingToDiscord = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(result['message'] ?? 'Meme sent to Discord!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sending meme to Discord: $e';
        _isSendingToDiscord = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        final padding = isMobile ? 12.0 : 24.0;

        final totalPages =
            (_filteredTemplates.length / _templatesPerPage).ceil();
        final startIdx = _currentPage * _templatesPerPage;
        final endIdx =
            (startIdx + _templatesPerPage < _filteredTemplates.length)
                ? startIdx + _templatesPerPage
                : _filteredTemplates.length;
        final pageTemplates = _filteredTemplates.sublist(startIdx, endIdx);

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: isMobile ? 28 : 32,
                      color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meme Generator',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontSize: isMobile ? 24 : null,
                              ),
                        ),
                        Text(
                          'Create custom memes with popular templates',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: isMobile ? 13 : null,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    FilledButton.tonalIcon(
                      onPressed: _isRefreshing ? null : _refreshTemplates,
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Refresh Templates'),
                    ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 20),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Templates',
                  hintText: 'e.g., Drake, Distracted Boyfriend...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterTemplates('');
                          },
                        )
                      : null,
                ),
                onChanged: _filterTemplates,
              ),
              SizedBox(height: isMobile ? 16 : 24),

              if (_isLoadingTemplates)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_filteredTemplates.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Icon(Icons.search_off,
                            size: 64,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          'No templates found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Template Gallery (Left Side)
                    Expanded(
                      flex: isMobile ? 1 : 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '📋 Template Gallery',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Page ${_currentPage + 1}/$totalPages',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Grid of templates
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: pageTemplates.length,
                            itemBuilder: (context, index) {
                              final template = pageTemplates[index];
                              final isSelected = _selectedTemplate != null &&
                                  _selectedTemplate!['id'] == template['id'];

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedTemplate = template;
                                    _generatedMemeUrl = null; // Clear preview
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: 0.2),
                                      width: isSelected ? 3 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(alpha: 0.3)
                                        : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(11)),
                                          child: Image.network(
                                            getProxiedImageUrl(template['url']),
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .errorContainer,
                                                child: const Center(
                                                  child: Icon(
                                                      Icons.broken_image,
                                                      size: 32),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              template['name'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${template['box_count']} text boxes',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // Pagination
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filled(
                                onPressed: _currentPage > 0
                                    ? () {
                                        setState(() {
                                          _currentPage--;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                                style: IconButton.styleFrom(
                                  disabledBackgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '${startIdx + 1}-$endIdx of ${_filteredTemplates.length}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              IconButton.filled(
                                onPressed: _currentPage < totalPages - 1
                                    ? () {
                                        setState(() {
                                          _currentPage++;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                                style: IconButton.styleFrom(
                                  disabledBackgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (!isMobile) ...[
                      const SizedBox(width: 24),

                      // Preview Panel (Right Side)
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎨 Preview',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            if (_selectedTemplate != null)
                              Card(
                                elevation: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Preview Image
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: Image.network(
                                        getProxiedImageUrl(_generatedMemeUrl ??
                                            _selectedTemplate!['url']),
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            height: 300,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    // Template Info
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedTemplate!['name'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${_selectedTemplate!['box_count']} text boxes available',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          const SizedBox(height: 20),

                                          // Create Button
                                          SizedBox(
                                            width: double.infinity,
                                            child: FilledButton.icon(
                                              onPressed: _isGenerating
                                                  ? null
                                                  : _showCreateMemeDialog,
                                              icon: _isGenerating
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : const Icon(Icons.create),
                                              label: Text(_isGenerating
                                                  ? 'Generating...'
                                                  : 'Create Meme'),
                                              style: FilledButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16),
                                              ),
                                            ),
                                          ),

                                          if (_generatedMemeUrl != null) ...[
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: FilledButton.icon(
                                                onPressed: _isSendingToDiscord
                                                    ? null
                                                    : _sendMemeToDiscord,
                                                icon: _isSendingToDiscord
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : const Icon(Icons.send),
                                                label: Text(_isSendingToDiscord
                                                    ? 'Sending...'
                                                    : 'Send to Discord'),
                                                style: FilledButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 16),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.green
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.green
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.check_circle,
                                                      color: Colors.green,
                                                      size: 20),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Meme generated! Right-click to save.',
                                                      style: TextStyle(
                                                        color:
                                                            Colors.green[800],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

              // Mobile Create Button
              if (isMobile && _selectedTemplate != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isGenerating ? null : _showCreateMemeDialog,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.create),
                    label: Text(_isGenerating
                        ? 'Generating...'
                        : 'Create Meme: ${_selectedTemplate!['name']}'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],

              // Mobile Generated Meme Preview
              if (isMobile && _generatedMemeUrl != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.network(
                          getProxiedImageUrl(_generatedMemeUrl!),
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isSendingToDiscord
                                    ? null
                                    : _sendMemeToDiscord,
                                icon: _isSendingToDiscord
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send),
                                label: Text(_isSendingToDiscord
                                    ? 'Sending...'
                                    : 'Send to Discord'),
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Meme generated! Long-press to save.',
                                      style: TextStyle(
                                        color: Colors.green[800],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Error Display
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Info Card
              const SizedBox(height: 32),
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'How to Use',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        icon: Icons.grid_view,
                        text:
                            'Browse templates in the gallery and click to select',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        icon: Icons.search,
                        text:
                            'Use the search bar to find specific templates quickly',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        icon: Icons.create,
                        text:
                            'Click "Create Meme" to add text and generate your meme',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        icon: Icons.download,
                        text:
                            'Right-click (or long-press on mobile) the generated meme to save',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
