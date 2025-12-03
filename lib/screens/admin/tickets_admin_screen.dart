import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/ticket.dart';
import '../../models/ticket_config.dart';
import 'ticket_detail_dialog.dart';

class TicketsAdminScreen extends StatefulWidget {
  final String? initialTicketId; // Ticket to open automatically
  final int initialTab; // Which tab to open in dialog (0=Details, 1=Chat)

  const TicketsAdminScreen({
    super.key,
    this.initialTicketId,
    this.initialTab = 0,
  });

  @override
  State<TicketsAdminScreen> createState() => _TicketsAdminScreenState();
}

class _TicketsAdminScreenState extends State<TicketsAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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
      final apiService = ApiService();
      final ticket = await apiService.getTicket(ticketId);

      if (mounted) {
        debugPrint('📱 Auto-opening ticket dialog for ${ticket.ticketId}');
        showDialog(
          context: context,
          builder: (context) => TicketDetailDialog(
            ticket: ticket,
            initialTab: widget.initialTab,
            onUpdate: () {
              debugPrint('🔄 Admin ticket updated from notification');
              // Refresh tickets list if needed
              final state =
                  context.findAncestorStateOfType<_TicketsListTabState>();
              state?._loadTickets();
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error opening ticket from notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
          // Reload button will be shown when in Manage Tickets tab
          if (_tabController.index == 0)
            Builder(
              builder: (context) {
                // Get the TicketsListTab state to call refresh
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // Find the TicketsListTab and refresh it
                    final state =
                        context.findAncestorStateOfType<_TicketsListTabState>();
                    state?._loadTickets();
                  },
                  tooltip: 'Refresh',
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Manage Tickets'),
            Tab(icon: Icon(Icons.settings), text: 'Configuration'),
          ],
          onTap: (index) {
            setState(() {}); // Rebuild to show/hide refresh button
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TicketsListTab(),
          TicketsConfigTab(),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 1: MANAGE TICKETS
// ============================================================================

class TicketsListTab extends StatefulWidget {
  const TicketsListTab({super.key});

  @override
  State<TicketsListTab> createState() => _TicketsListTabState();
}

class _TicketsListTabState extends State<TicketsListTab> {
  List<Ticket> _tickets = [];
  List<Ticket> _filteredTickets = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tickets = await ApiService().getTickets();
      setState(() {
        _tickets = tickets;
        _filterTickets();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterTickets() {
    List<Ticket> filtered = _tickets;

    // Filter by status
    if (_statusFilter != 'All') {
      filtered =
          filtered.where((ticket) => ticket.status == _statusFilter).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ticket) {
        final query = _searchQuery.toLowerCase();
        return ticket.username.toLowerCase().contains(query) ||
            ticket.displayName.toLowerCase().contains(query) ||
            ticket.ticketNum.toString().contains(query) ||
            ticket.type.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredTickets = filtered;
    });
  }

  Future<void> _deleteTicket(Ticket ticket) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ticket'),
        content: Text(
            'Are you sure you want to delete Ticket #${ticket.ticketNum}?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService().deleteTicket(ticket.ticketId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket #${ticket.ticketNum} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTickets(); // Reload list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete ticket: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadTickets,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: Column(
        children: [
          // Filters and Search - Kompakter
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                // Status Filter - Responsive layout (kompakt ohne Status-Label)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 700;

                    if (isCompact) {
                      // Mobile/Tablet: Wrap layout ohne Label
                      return Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _statusFilter == 'All',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _statusFilter = 'All';
                                  _filterTickets();
                                });
                              }
                            },
                          ),
                          FilterChip(
                            label: const Text('Open'),
                            selected: _statusFilter == 'Open',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _statusFilter = 'Open';
                                  _filterTickets();
                                });
                              }
                            },
                          ),
                          FilterChip(
                            label: const Text('Claimed'),
                            selected: _statusFilter == 'Claimed',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _statusFilter = 'Claimed';
                                  _filterTickets();
                                });
                              }
                            },
                          ),
                          FilterChip(
                            label: const Text('Closed'),
                            selected: _statusFilter == 'Closed',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _statusFilter = 'Closed';
                                  _filterTickets();
                                });
                              }
                            },
                          ),
                        ],
                      );
                    } else {
                      // Desktop: Horizontal layout ohne Label
                      return SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'All', label: Text('All')),
                          ButtonSegment(value: 'Open', label: Text('Open')),
                          ButtonSegment(
                              value: 'Claimed', label: Text('Claimed')),
                          ButtonSegment(value: 'Closed', label: Text('Closed')),
                        ],
                        selected: {_statusFilter},
                        onSelectionChanged: (Set<String> selected) {
                          setState(() {
                            _statusFilter = selected.first;
                            _filterTickets();
                          });
                        },
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                // Search Bar - kompakter
                SizedBox(
                  height: 44, // Kleinere Höhe
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search tickets...',
                      hintStyle: const TextStyle(fontSize: 14),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _filterTickets();
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _filterTickets();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Results count - kompakter
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              children: [
                Text(
                  'Showing ${_filteredTickets.length} of ${_tickets.length} tickets',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),

          // Tickets List
          Expanded(
            child: _filteredTickets.isEmpty
                ? ListView(
                    // Wrap in ListView for pull-to-refresh to work
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.confirmation_number_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No tickets found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: _filteredTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _filteredTickets[index];
                      return TicketCard(
                        ticket: ticket,
                        onDelete: () => _deleteTicket(ticket),
                        onRefresh: _loadTickets,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TICKET CARD WIDGET
// ============================================================================

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onDelete,
    required this.onRefresh,
  });

  Color _getStatusColor(BuildContext context) {
    switch (ticket.status) {
      case 'Open':
        return Colors.green;
      case 'Claimed':
        return Colors.orange;
      case 'Closed':
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getStatusIcon() {
    switch (ticket.status) {
      case 'Open':
        return Icons.radio_button_unchecked;
      case 'Claimed':
        return Icons.radio_button_checked;
      case 'Closed':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use harmonized accent color for cards (like in dashboard)
    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;

    return Card(
      color: cardColor,
      elevation: 0, // Flat card
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => TicketDetailDialog(
              ticket: ticket,
              onUpdate: onRefresh,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Ticket number, status, actions
              Row(
                children: [
                  // Ticket Number
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${ticket.ticketNum}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(context),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 16,
                          color: _getStatusColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ticket.status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _getStatusColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Delete Button
                  IconButton(
                    icon: Icon(Icons.delete,
                        color: Theme.of(context).colorScheme.error),
                    onPressed: onDelete,
                    tooltip: 'Delete Ticket',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // User Info
              Row(
                children: [
                  // Avatar
                  if (ticket.avatarUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        ticket.avatarUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  const SizedBox(width: 12),
                  // User Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '@${ticket.username}',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Type Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.type,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),

              // Assigned/Claimed Info (Assigned takes priority)
              if (ticket.assignedTo != null || ticket.claimedBy != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Show Assigned To if exists (takes priority over Claimed By)
                    if (ticket.assignedTo != null) ...[
                      Icon(Icons.assignment_ind,
                          size: 16,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Assigned: ${ticket.assignedToName ?? "Unknown"}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else if (ticket.claimedBy != null) ...[
                      // Only show Claimed By if NOT assigned
                      Icon(Icons.person_pin,
                          size: 16,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Claimed by: ${ticket.claimedByName ?? "Unknown"}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Created At
              if (ticket.createdAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Created: ${_formatDateTime(ticket.createdAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}

// ============================================================================
// TAB 2: CONFIGURATION
// ============================================================================

class TicketsConfigTab extends StatefulWidget {
  const TicketsConfigTab({super.key});

  @override
  State<TicketsConfigTab> createState() => _TicketsConfigTabState();
}

class _TicketsConfigTabState extends State<TicketsConfigTab> {
  TicketConfig? _config;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _hasChanges = false;

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _autoCloseController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _autoCloseController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final config = await ApiService().getTicketConfig();
      setState(() {
        _config = config;
        _emailController.text = config.transcriptEmailAddress;
        _autoCloseController.text =
            config.autoDeleteAfterCloseDays?.toString() ?? '';
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;

    setState(() => _isSaving = true);

    try {
      await ApiService().updateTicketConfig(_config!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _hasChanges = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save configuration: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _resetConfig() async {
    // Confirm reset
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Configuration'),
        content: const Text(
            'Are you sure you want to reset the ticket configuration to defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService().resetTicketConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration reset to defaults'),
            backgroundColor: Colors.green,
          ),
        );
        _loadConfig(); // Reload config
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset configuration: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _addCategory() {
    final category = _newCategoryController.text.trim();
    if (category.isEmpty) return;

    if (_config!.categories.contains(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category already exists')),
      );
      return;
    }

    setState(() {
      _config = _config!.copyWith(
        categories: [..._config!.categories, category],
      );
      _hasChanges = true;
    });
    _newCategoryController.clear();
  }

  void _removeCategory(String category) {
    setState(() {
      _config = _config!.copyWith(
        categories: _config!.categories.where((c) => c != category).toList(),
      );
      _hasChanges = true;
    });
  }

  Color _getCardColor(BuildContext context) {
    // Same color logic as ticket cards
    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    return isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadConfig,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_config == null) {
      return const Center(child: Text('No configuration available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Save/Reset Buttons
          if (_hasChanges)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              elevation: 0, // Flat card
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have unsaved changes',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadConfig,
                      child: const Text('Discard'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saveConfig,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Ticket Categories
          Card(
            color: _getCardColor(context),
            elevation: 0, // Flat card
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.category,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Ticket Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Categories available when users create tickets',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _config!.categories.map((category) {
                      return Chip(
                        label: Text(category),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeCategory(category),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newCategoryController,
                          decoration: InputDecoration(
                            labelText: 'New Category',
                            hintText: 'Enter category name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onSubmitted: (_) => _addCategory(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _addCategory,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Ticket Management Settings
          Card(
            color: _getCardColor(context),
            elevation: 0, // Flat card
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Ticket Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Require Claim'),
                    subtitle: const Text(
                        'Moderators must claim tickets before responding'),
                    value: _config!.requireClaim,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(requireClaim: value);
                        _hasChanges = true;
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Auto-Delete Closed Tickets'),
                    subtitle: Text(
                      _config!.autoDeleteAfterCloseDays == null
                          ? 'Never delete'
                          : 'Delete after ${_config!.autoDeleteAfterCloseDays} days',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _autoCloseController,
                            decoration: InputDecoration(
                              labelText: 'Days',
                              hintText: 'Leave empty to disable',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _config = _config!.copyWith(
                                  autoDeleteAfterCloseDays: value.isEmpty
                                      ? null
                                      : int.tryParse(value),
                                );
                                _hasChanges = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _autoCloseController.clear();
                              _config = _config!.copyWith(
                                autoDeleteAfterCloseDays: null,
                              );
                              _hasChanges = true;
                            });
                          },
                          child: const Text('Never Delete'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Email Notifications
          Card(
            color: _getCardColor(context),
            elevation: 0, // Flat card
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.email,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Email Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Send Transcript Email'),
                    subtitle:
                        const Text('Email transcript when ticket is closed'),
                    value: _config!.sendTranscriptEmail,
                    onChanged: (value) {
                      setState(() {
                        _config = _config!.copyWith(sendTranscriptEmail: value);
                        _hasChanges = true;
                      });
                    },
                  ),
                  if (_config!.sendTranscriptEmail) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'admin@example.com',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          setState(() {
                            _config = _config!
                                .copyWith(transcriptEmailAddress: value);
                            _hasChanges = true;
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Save/Reset Buttons
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Mobile: Stack buttons vertically
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            (_isLoading || _isSaving) ? null : _resetConfig,
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
                        onPressed:
                            (_isLoading || _isSaving) ? null : _saveConfig,
                        icon: _isSaving
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
                );
              } else {
                // Desktop: Buttons side by side
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          (_isLoading || _isSaving) ? null : _resetConfig,
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset to Defaults'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        foregroundColor: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: (_isLoading || _isSaving) ? null : _saveConfig,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save Configuration'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
