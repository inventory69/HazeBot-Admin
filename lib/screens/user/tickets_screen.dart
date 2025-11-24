import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/ticket.dart';
import '../../models/ticket_config.dart';
import 'package:timeago/timeago.dart' as timeago;

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

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
        children: const [
          _MyTicketsTab(),
          _CreateTicketTab(),
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

  Widget _buildTicketCard(Ticket ticket, ColorScheme colorScheme, ThemeData theme) {
    final statusColor = ticket.status.toLowerCase() == 'open'
        ? Colors.green
        : Colors.grey;

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
                                  value: loadingProgress.expectedTotalBytes != null
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
                        ? timeago.format(DateTime.parse(ticket.createdAt!))
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
    final subjectMatch = RegExp(r'\*\*Subject:\*\*\s*(.+?)(?:\n|$)')
        .firstMatch(initialMessage);
    return subjectMatch?.group(1)?.trim() ?? 'No subject';
  }

  String _extractDescription(String initialMessage) {
    final descMatch = RegExp(r'\*\*Description:\*\*\s*\n(.+)',
            dotAll: true, multiLine: true)
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
  const _CreateTicketTab();

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
        DefaultTabController.of(context).animateTo(0);
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

// Ticket Detail Screen (for users)
class _TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;

  const _TicketDetailScreen({required this.ticket});

  @override
  State<_TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<_TicketDetailScreen> {
  bool _isLoadingMessages = true;
  bool _isSending = false;
  List<dynamic> _messages = [];
  String? _errorMessage;
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupWebSocketListener();
  }
  
  void _setupWebSocketListener() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final wsService = authService.wsService;
    
    // Join ticket room
    wsService.joinTicket(widget.ticket.ticketId);
    
    // Listen for new messages
    wsService.onTicketUpdate(widget.ticket.ticketId, (data) {
      final eventType = data['event_type'] as String?;
      
      if (eventType == 'new_message') {
        final messageData = data['data'] as Map<String, dynamic>?;
        if (messageData != null) {
          _handleNewMessage(messageData);
        }
      }
    });
  }
  
  void _handleNewMessage(Map<String, dynamic> messageData) {
    if (!mounted) return;
    
    // Check if message already exists
    final messageId = messageData['id'] as String;
    if (_messages.any((m) => m['id'] == messageId)) {
      return;
    }
    
    setState(() {
      _messages.add(messageData);
      _previousMessageCount = _messages.length;
    });
    
    // Scroll to bottom
    _scrollToBottom();
  }

  @override
  void dispose() {
    // Leave WebSocket ticket room
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.wsService.leaveTicket(widget.ticket.ticketId);
    
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMessages = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final messages =
          await authService.apiService.getTicketMessages(widget.ticket.ticketId);

      if (mounted) {
        setState(() {
          final newMessageCount = messages.length;
          final hasNewMessages = newMessageCount > _previousMessageCount;
          final isFirstLoad = _previousMessageCount == 0;
          
          _messages = messages;
          _previousMessageCount = newMessageCount;
          _isLoadingMessages = false;
          
          // Auto-scroll to bottom if there are new messages OR first load
          if (hasNewMessages || isFirstLoad) {
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load messages: $e';
          _isLoadingMessages = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final newMessage = await authService.apiService.sendTicketMessage(
        widget.ticket.ticketId,
        _messageController.text.trim(),
      );

      if (mounted) {
        _messageController.clear();
        // Add the new message to the list immediately (optimistic update)
        setState(() {
          _messages.add(newMessage);
          _previousMessageCount = _messages.length;
          _isSending = false;
        });
        // Scroll to bottom after sending
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
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
    final statusColor = widget.ticket.status.toLowerCase() == 'open'
        ? Colors.green
        : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${widget.ticket.ticketNum}'),
        backgroundColor: colorScheme.surface,
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
                        widget.ticket.type,
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
                            widget.ticket.status.toLowerCase() == 'open'
                                ? Icons.circle
                                : Icons.check_circle,
                            color: statusColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.ticket.status,
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
                if (widget.ticket.initialMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _extractSubject(widget.ticket.initialMessage!),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _extractDescription(widget.ticket.initialMessage!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (widget.ticket.assignedToName != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Assigned to: ${widget.ticket.assignedToName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Messages
          Expanded(
            child: _isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colorScheme.error),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadMessages,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: _messages.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  Center(
                                    child: Text(
                                      'No messages yet',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  return _buildMessageBubble(
                                      message, colorScheme, theme);
                                },
                              ),
                      ),
          ),

          // Message input (only if ticket is not closed)
          if (widget.ticket.status.toLowerCase() != 'closed')
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSending ? null : _sendMessage,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      dynamic message, ColorScheme colorScheme, ThemeData theme) {
    // Get author info from backend response (author_name, author_avatar)
    final author = message['author_name'] as String? ?? message['author'] as String? ?? 'Unknown';
    final avatarUrl = message['author_avatar'] as String?;
    final content = message['content'] as String? ?? '';
    final timestamp = message['timestamp'] as String?;
    final isBot = message['is_bot'] as bool? ?? false;
    final isAdmin = message['is_admin'] as bool? ?? false;
    final role = message['role'] as String?; // 'admin', 'moderator', or null
    
    // Check message types
    final isAdminMessage = isAdmin || content.contains('[Admin Panel');
    final isInitialMessage = content.contains('**Initial details');
    final isClosingMessage = content.contains('Ticket successfully closed') || 
                              content.contains('**Closing Message:**');
    final isSystem = isBot && !isAdminMessage;

    // Clean content
    String cleanContent = content;
    cleanContent = cleanContent.replaceAll('**', '');
    
    if (isAdminMessage) {
      final match = RegExp(r'\[Admin Panel - [^\]]+\]:\s*(.+)', dotAll: true).firstMatch(cleanContent);
      if (match != null) {
        cleanContent = match.group(1) ?? cleanContent;
      }
    }
    
    if (isInitialMessage) {
      final match = RegExp(r'Initial details from [^:]+:\s*(.+)', dotAll: true).firstMatch(cleanContent);
      if (match != null) {
        cleanContent = match.group(1) ?? cleanContent;
      }
    }

    // Get display name
    String displayName = author;
    if (isAdminMessage) {
      final match = RegExp(r'\[Admin Panel - ([^\]]+)\]').firstMatch(content);
      if (match != null) {
        displayName = match.group(1) ?? author;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with Discord image or fallback icon
          avatarUrl != null && avatarUrl.isNotEmpty
              ? Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: ClipOval(
                    child: Image.network(
                      avatarUrl,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to icon on error
                        return Center(
                          child: Icon(
                            isBot
                                ? Icons.smart_toy
                                : isAdminMessage
                                    ? Icons.admin_panel_settings
                                    : Icons.person,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: 16,
                  backgroundColor: isClosingMessage
                      ? Colors.green.withOpacity(0.2)
                      : isAdminMessage
                          ? colorScheme.primaryContainer
                          : isSystem
                              ? colorScheme.tertiaryContainer
                              : colorScheme.secondaryContainer,
                  child: isBot
                      ? Icon(
                          Icons.smart_toy,
                          size: 20,
                          color: isClosingMessage
                              ? Colors.green
                              : isAdminMessage
                                  ? colorScheme.primary
                                  : colorScheme.onTertiaryContainer,
                        )
                      : Icon(
                          isAdminMessage
                              ? Icons.admin_panel_settings
                              : Icons.person,
                          size: 20,
                          color: isClosingMessage
                              ? Colors.green
                              : isAdminMessage
                                  ? colorScheme.primary
                                  : isSystem
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSecondaryContainer,
                        ),
                ),
          const SizedBox(width: 12),
          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isAdminMessage
                              ? colorScheme.primary
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAdminMessage) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: role == 'moderator'
                              ? Colors.blue.withOpacity(0.2)
                              : colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role == 'moderator' ? 'MOD' : 'ADMIN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: role == 'moderator'
                                ? Colors.blue
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                    if (isClosingMessage) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CLOSED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    if (timestamp != null)
                      Text(
                        _formatMessageTime(DateTime.parse(timestamp)),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Message bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isClosingMessage
                        ? Colors.green.withOpacity(0.1)
                        : isAdminMessage
                            ? colorScheme.primaryContainer.withOpacity(0.3)
                            : isSystem
                                ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
                                : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: isClosingMessage
                        ? Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 1,
                          )
                        : isAdminMessage
                            ? Border.all(
                                color: colorScheme.primary.withOpacity(0.3),
                                width: 1,
                              )
                            : null,
                  ),
                  child: Text(
                    cleanContent,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _extractSubject(String initialMessage) {
    final subjectMatch = RegExp(r'\*\*Subject:\*\*\s*(.+?)(?:\n|$)')
        .firstMatch(initialMessage);
    return subjectMatch?.group(1)?.trim() ?? 'No subject';
  }

  String _extractDescription(String initialMessage) {
    final descMatch = RegExp(r'\*\*Description:\*\*\s*\n(.+)',
            dotAll: true, multiLine: true)
        .firstMatch(initialMessage);
    return descMatch?.group(1)?.trim() ?? '';
  }
}
