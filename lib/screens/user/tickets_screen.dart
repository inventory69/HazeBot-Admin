import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../models/ticket.dart';
import '../../widgets/ticket_chat_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class TicketsScreen extends StatefulWidget {
  final String? initialTicketId; // Ticket to open automatically

  const TicketsScreen({super.key, this.initialTicketId});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAndRequestNotificationPermission();

    // If initialTicketId provided, open that ticket after build
    if (widget.initialTicketId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openTicketById(widget.initialTicketId!);
      });
    }
  }

  /// Open a specific ticket by ID
  Future<void> _openTicketById(String ticketId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final ticket = await authService.apiService.getTicket(ticketId);

      if (mounted) {
        // Navigate to ticket detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _TicketDetailScreen(ticket: ticket),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error opening ticket from notification: $e');
    }
  }

  /// Ask for notification permission on first visit
  Future<void> _checkAndRequestNotificationPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAskedBefore =
          prefs.getBool('notification_permission_asked') ?? false;

      if (!hasAskedBefore) {
        final notificationService = NotificationService();

        if (!notificationService.hasPermission) {
          debugPrint(
              '📱 First time opening tickets, requesting notification permission...');

          // Show dialog explaining why we need permission
          if (!mounted) return;
          final shouldAsk = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('📬 Enable Notifications?'),
              content: const Text(
                'Get instant notifications when:\n'
                '• You receive new ticket messages\n'
                '• Someone mentions you\n'
                '• Your ticket is assigned to staff\n\n'
                'You can customize this later in settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Not now'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Enable'),
                ),
              ],
            ),
          );

          if (shouldAsk == true && mounted) {
            final granted =
                await notificationService.requestPermissionAndRegister();

            if (granted) {
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              await notificationService
                  .registerWithBackend(authService.apiService);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Notifications enabled'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }

          // Mark as asked
          await prefs.setBool('notification_permission_asked', true);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error checking notification permission: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        backgroundColor: colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.list),
              text: 'My Tickets',
            ),
            Tab(
              icon: Icon(Icons.add_circle_outline),
              text: 'Create New',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _MyTicketsTab(),
          _CreateTicketTab(tabController: _tabController),
        ],
      ),
    );
  }
}

// My Tickets Tab
class _MyTicketsTab extends StatefulWidget {
  const _MyTicketsTab();

  @override
  State<_MyTicketsTab> createState() => _MyTicketsTabState();
}

class _MyTicketsTabState extends State<_MyTicketsTab> {
  bool _isLoading = true;
  List<Ticket> _tickets = [];
  String? _errorMessage;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final tickets = await authService.apiService.getMyTickets(
        status: _statusFilter == 'all' ? null : _statusFilter,
      );

      if (mounted) {
        setState(() {
          _tickets = tickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load tickets: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTickets,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all', colorScheme),
                        const SizedBox(width: 6),
                        _buildFilterChip('Open', 'open', colorScheme),
                        const SizedBox(width: 6),
                        _buildFilterChip('Closed', 'closed', colorScheme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tickets list
          Expanded(
            child: _tickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tickets found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a new ticket to get started',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      return _buildTicketCard(ticket, colorScheme, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ColorScheme colorScheme) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
        _loadTickets();
      },
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTicketCard(
      Ticket ticket, ColorScheme colorScheme, ThemeData theme) {
    final statusColor =
        ticket.status.toLowerCase() == 'open' ? Colors.green : Colors.grey;

    // Use harmonized accent color for cards (same as admin screen)
    final isMonet = colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? colorScheme.primaryContainer.withOpacity(0.18)
        : colorScheme.surface;

    return Card(
      color: cardColor,
      elevation: 0, // Flat card
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showTicketDetail(ticket),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // User Avatar
                  if (ticket.avatarUrl != null && ticket.avatarUrl!.isNotEmpty)
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      child: ClipOval(
                        child: Image.network(
                          ticket.avatarUrl!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 18,
                              color: colorScheme.onPrimaryContainer,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 32,
                              height: 32,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.confirmation_number,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '#${ticket.ticketNum}',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ticket.type,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    ticket.status.toLowerCase() == 'open'
                        ? Icons.circle
                        : Icons.check_circle,
                    color: statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (ticket.initialMessage != null) ...[
                Text(
                  _extractSubject(ticket.initialMessage!),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _extractDescription(ticket.initialMessage!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.createdAt != null
                        ? timeago
                            .format(DateTime.parse(ticket.createdAt!).toLocal())
                        : 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (ticket.assignedToName != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.person,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ticket.assignedToName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractSubject(String initialMessage) {
    final subjectMatch =
        RegExp(r'\*\*Subject:\*\*\s*(.+?)(?:\n|$)').firstMatch(initialMessage);
    return subjectMatch?.group(1)?.trim() ?? 'No subject';
  }

  String _extractDescription(String initialMessage) {
    final descMatch =
        RegExp(r'\*\*Description:\*\*\s*\n(.+)', dotAll: true, multiLine: true)
            .firstMatch(initialMessage);
    return descMatch?.group(1)?.trim() ?? '';
  }

  void _showTicketDetail(Ticket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _TicketDetailScreen(ticket: ticket),
      ),
    ).then((_) => _loadTickets()); // Reload tickets when returning
  }
}

// Create Ticket Tab
class _CreateTicketTab extends StatefulWidget {
  final TabController tabController;

  const _CreateTicketTab({required this.tabController});

  @override
  State<_CreateTicketTab> createState() => _CreateTicketTabState();
}

class _CreateTicketTabState extends State<_CreateTicketTab> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingCategories = true;
  List<String> _categories = [];
  String? _selectedCategory;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCategories = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final config = await authService.apiService.getTicketConfig();

      if (mounted) {
        setState(() {
          _categories = config.categories;
          _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load ticket categories: $e';
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a ticket category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.createTicket(
        type: _selectedCategory!,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        // Clear form
        _subjectController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
          _isLoading = false;
        });

        // Show success message with null-safe ticket number
        final ticketNum = result['ticket_num'] ?? 'Unknown';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Ticket #$ticketNum created successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Switch to My Tickets tab
        widget.tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        String errorMsg = e.toString();
        if (errorMsg.contains('Exception:')) {
          errorMsg = errorMsg.replaceAll('Exception:', '').trim();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadCategories,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Submit a support request, bug report, or application',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              items: _categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                hintText: 'Brief summary of your request',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                counterText: '${_subjectController.text.length}/100',
              ),
              maxLength: 100,
              onChanged: (value) {
                setState(() {});
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subject';
                }
                if (value.trim().length < 3) {
                  return 'Subject must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Provide detailed information about your request',
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                counterText: '${_descriptionController.text.length}/2000',
              ),
              maxLines: 8,
              maxLength: 2000,
              onChanged: (value) {
                setState(() {});
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submitTicket,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isLoading ? 'Creating...' : 'Create Ticket',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ticket Detail Screen (for users) - using shared TicketChatWidget
class _TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;

  const _TicketDetailScreen({required this.ticket});

  @override
  State<_TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<_TicketDetailScreen> {
  late Ticket _ticket;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
  }

  Future<void> _closeTicket() async {
    // Show close message dialog
    final closeMessage = await showDialog<String>(
      context: context,
      builder: (context) => _CloseMessageDialog(),
    );

    if (closeMessage == null) return; // User cancelled

    setState(() => _isProcessing = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.closeTicket(
        _ticket.ticketId,
        closeMessage: closeMessage.isEmpty ? null : closeMessage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ticket closed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to ticket list
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reopenTicket() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reopen Ticket'),
        content: Text(
          'Do you want to reopen this ticket?\n\n'
          'Reopens remaining: ${3 - _ticket.reopenCount}/3',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reopen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.reopenTicket(_ticket.ticketId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ticket reopened successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to ticket list
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reopen ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor =
        _ticket.status.toLowerCase() == 'open' ? Colors.green : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${_ticket.ticketNum}'),
        backgroundColor: colorScheme.surface,
        actions: [
          // Show Close button for open tickets
          if (_ticket.isOpen && !_isProcessing)
            IconButton(
              onPressed: _closeTicket,
              icon: const Icon(Icons.lock),
              tooltip: 'Close Ticket',
              color: Colors.red[700],
            ),
          // Show Reopen button for closed tickets (if limit not reached)
          if (_ticket.isClosed && _ticket.reopenCount < 3 && !_isProcessing)
            IconButton(
              onPressed: _reopenTicket,
              icon: const Icon(Icons.lock_open),
              tooltip: 'Reopen Ticket',
              color: Colors.blue[700],
            ),
          // Show loading indicator when processing
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Ticket info header
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _ticket.type,
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _ticket.status.toLowerCase() == 'open'
                                ? Icons.circle
                                : Icons.check_circle,
                            color: statusColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _ticket.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Show reopen count badge if ticket has been reopened
                if (_ticket.isClosed && _ticket.reopenCount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reopened ${_ticket.reopenCount}/3 times',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Show limit reached warning
                if (_ticket.isClosed && _ticket.reopenCount >= 3) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 14,
                          color: Colors.red[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reopen limit reached (3/3)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_ticket.initialMessage != null) ...[
                  const SizedBox(height: 12),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    initiallyExpanded: false,
                    title: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _extractSubject(_ticket.initialMessage!),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          _extractDescription(_ticket.initialMessage!),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Chat widget (full screen mode)
          Expanded(
            child: TicketChatWidget(
              ticket: _ticket,
              isFullScreen: true,
            ),
          ),
        ],
      ),
    );
  }

  String _extractSubject(String initialMessage) {
    final subjectMatch =
        RegExp(r'\*\*Subject:\*\*\s*(.+?)(?:\n|$)').firstMatch(initialMessage);
    return subjectMatch?.group(1)?.trim() ?? 'No subject';
  }

  String _extractDescription(String initialMessage) {
    final descMatch =
        RegExp(r'\*\*Description:\*\*\s*\n(.+)', dotAll: true, multiLine: true)
            .firstMatch(initialMessage);
    return descMatch?.group(1)?.trim() ?? '';
  }
}

// Old duplicate removed below (was causing the error)

// Close Message Dialog
class _CloseMessageDialog extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  _CloseMessageDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Close Ticket'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add an optional closing message:'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText:
                  'e.g., Issue resolved, let me know if you need more help.',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 500,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Close Ticket'),
        ),
      ],
    );
  }
}
