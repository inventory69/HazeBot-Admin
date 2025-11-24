import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ticket.dart';
import '../../models/ticket_message.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class TicketDetailDialog extends StatefulWidget {
  final Ticket ticket;
  final VoidCallback onUpdate;

  const TicketDetailDialog({
    super.key,
    required this.ticket,
    required this.onUpdate,
  });

  @override
  State<TicketDetailDialog> createState() => _TicketDetailDialogState();
}

class _TicketDetailDialogState extends State<TicketDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TicketMessage> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _messageError;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _previousMessageCount = 0;
  Set<String> _seenMessageIds = {};
  int _firstNewMessageIndex = -1; // Index of first new message for divider

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        if (_messages.isEmpty) {
          _loadMessages();
        } else {
          // Mark all messages as seen when switching to messages tab
          _markAllAsSeen();
          // Scroll to bottom when switching to messages tab
          _scrollToBottom();
        }
      }
    });
    
    // Set up WebSocket listener for real-time updates
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
    
    final newMessage = TicketMessage.fromJson(messageData);
    
    // Check if message already exists
    if (_messages.any((m) => m.id == newMessage.id)) {
      return;
    }
    
    final oldCount = _messages.length;
    
    setState(() {
      _messages.add(newMessage);
      _previousMessageCount = _messages.length;
      // Mark where new messages start (if not already set)
      if (_firstNewMessageIndex < 0) {
        _firstNewMessageIndex = oldCount;
      }
    });
    
    // Scroll behavior on messages tab
    if (_tabController.index == 1) {
      if (_firstNewMessageIndex >= 0) {
        _scrollToNewMessages();
      } else {
        _scrollToBottom();
      }
    }
  }

  void _markAllAsSeen() {
    setState(() {
      _seenMessageIds = _messages.map((m) => m.id).toSet();
    });
  }

  @override
  void dispose() {
    // Leave WebSocket ticket room
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.wsService.leaveTicket(widget.ticket.ticketId);
    
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    // Use addPostFrameCallback to ensure widgets are built and layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        // Add delay to ensure layout is fully complete (200ms for reliable rendering)
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _scrollController.hasClients) {
            final targetPosition = _scrollController.position.maxScrollExtent;
            if (animate) {
              _scrollController.animateTo(
                targetPosition,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            } else {
              // Jump instantly for initial load
              _scrollController.jumpTo(targetPosition);
            }
          }
        });
      }
    });
  }

  void _scrollToNewMessages() {
    // Scroll to show the "New Messages" divider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients && _firstNewMessageIndex > 0) {
        // Add delay to ensure layout is fully complete (200ms for reliable rendering)
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _scrollController.hasClients) {
            // Calculate approximate position (each message ~100px height estimate)
            final approximatePosition = _firstNewMessageIndex * 100.0;
            final maxPosition = _scrollController.position.maxScrollExtent;
            final targetPosition = approximatePosition.clamp(0.0, maxPosition);
            
            _scrollController.animateTo(
              targetPosition,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoadingMessages = true;
      _messageError = null;
    });

    try {
      final messagesData = await ApiService().getTicketMessages(widget.ticket.ticketId);
      
      final newMessageCount = messagesData.length;
      final hasNewMessages = newMessageCount > _previousMessageCount;
      final isFirstLoad = _previousMessageCount == 0;
      
      setState(() {
        _messages = messagesData
            .map((json) => TicketMessage.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Find first new message index
        if (hasNewMessages && !isFirstLoad) {
          _firstNewMessageIndex = _previousMessageCount; // Messages after this index are new
        } else {
          _firstNewMessageIndex = -1; // No new messages
        }
        
        // Mark all current messages as seen if this is the first load
        if (_seenMessageIds.isEmpty) {
          _seenMessageIds = _messages.map((m) => m.id).toSet();
        }
        
        _previousMessageCount = newMessageCount;
        _isLoadingMessages = false;
      });
      
      // Scroll behavior:
      // - First load: Always scroll to bottom (no animation)
      // - Updates with new messages: Scroll to divider
      // - Updates without new messages: Do nothing (stay at current position)
      if (isFirstLoad) {
        _scrollToBottom(animate: false); // Jump instantly to bottom on first load
      } else if (hasNewMessages && _firstNewMessageIndex >= 0) {
        _scrollToNewMessages(); // Scroll to new messages divider
      }
    } catch (e) {
      setState(() {
        _messageError = e.toString();
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await ApiService().sendTicketMessage(widget.ticket.ticketId, content);
      _messageController.clear();
      
      // Wait a moment for the bot to post the message
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Reload messages
      await _loadMessages();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _claimTicket() async {
    try {
      // Get current user's Discord ID
      final userData = await ApiService().getCurrentUser();
      final discordId = userData['discord_id']?.toString();
      
      if (discordId == null || discordId.isEmpty) {
        throw Exception('Could not retrieve user Discord ID');
      }
      
      await ApiService().claimTicket(widget.ticket.ticketId, discordId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket claimed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdate();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim ticket: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _assignTicket() async {
    // Show loading dialog while fetching members
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading members...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Fetch guild members
      final membersData = await ApiService().getGamingMembers();
      final members = membersData['members'] as List<dynamic>;

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show member selection dialog
      final selectedUser = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _UserSelectionDialog(members: members),
      );

      if (selectedUser == null) return;

      final userId = selectedUser['id'] as String;

      await ApiService().assignTicket(widget.ticket.ticketId, userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket assigned successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdate();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign ticket: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _closeTicket() async {
    final closeMessage = await showDialog<String>(
      context: context,
      builder: (context) => _CloseMessageDialog(),
    );

    if (closeMessage == null) return; // User cancelled

    try {
      await ApiService().closeTicket(
        widget.ticket.ticketId,
        closeMessage: closeMessage.isEmpty ? null : closeMessage,
      );
      
      // Wait a moment for the close message to be posted to Discord
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Reload messages to show the closing message
      if (_messages.isNotEmpty) {
        await _loadMessages();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket closed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdate();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close ticket: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _reopenTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reopen Ticket'),
        content: const Text('Are you sure you want to reopen this ticket?'),
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

    try {
      await ApiService().reopenTicket(widget.ticket.ticketId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket reopened successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdate();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reopen ticket: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Color _getStatusColor() {
    switch (widget.ticket.status) {
      case 'Open':
        return Colors.green;
      case 'Claimed':
        return Colors.orange;
      case 'Closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;
          final dialogWidth = isCompact ? constraints.maxWidth : constraints.maxWidth * 0.8;
          final dialogHeight = constraints.maxHeight * 0.9;

          return Container(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.confirmation_number,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Ticket #${widget.ticket.ticketNum}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Details', icon: Icon(Icons.info_outline)),
                    Tab(text: 'Messages', icon: Icon(Icons.chat_bubble_outline)),
                  ],
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDetailsTab(),
                      _buildMessagesTab(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status & Type Card
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.ticket.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Type',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.ticket.type,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Creator Card
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Creator',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: widget.ticket.avatarUrl != null
                            ? NetworkImage(widget.ticket.avatarUrl!)
                            : null,
                        child: widget.ticket.avatarUrl == null
                            ? Icon(Icons.person,
                                size: 20, color: Theme.of(context).colorScheme.primary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ticket.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Created ${widget.ticket.createdAt != null ? _formatDateTime(widget.ticket.createdAt!) : 'Unknown'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Assignment Card - Show assigned OR claimed (assigned takes priority)
          if (widget.ticket.assignedTo != null || widget.ticket.claimedBy != null)
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show Assigned To if exists (takes priority over Claimed By)
                    if (widget.ticket.assignedTo != null) ...[
                      Text(
                        'Assigned to',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: widget.ticket.assignedToAvatar != null
                                ? NetworkImage(widget.ticket.assignedToAvatar!)
                                : null,
                            child: widget.ticket.assignedToAvatar == null
                                ? Icon(Icons.person,
                                    size: 20, color: Theme.of(context).colorScheme.primary)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.ticket.assignedToName ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (widget.ticket.claimedBy != null) ...[
                      // Only show Claimed By if NOT assigned
                      Text(
                        'Claimed by',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: widget.ticket.claimedByAvatar != null
                                ? NetworkImage(widget.ticket.claimedByAvatar!)
                                : null,
                            child: widget.ticket.claimedByAvatar == null
                                ? Icon(Icons.person,
                                    size: 20, color: Theme.of(context).colorScheme.primary)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.ticket.claimedByName ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Actions
          Text(
            'Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons based on status
          if (widget.ticket.isClosed) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _reopenTicket,
                icon: const Icon(Icons.lock_open),
                label: const Text('Reopen Ticket'),
              ),
            ),
          ] else ...[
            // Show Claim OR Assign buttons (mutually exclusive)
            if (widget.ticket.claimedBy == null && widget.ticket.assignedTo == null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _claimTicket,
                  icon: const Icon(Icons.pan_tool),
                  label: const Text('Claim Ticket'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _assignTicket,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assign to User'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ] else if (widget.ticket.claimedBy != null && widget.ticket.assignedTo == null) ...[
              // Already claimed - only show Assign option
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _assignTicket,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assign to User'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _closeTicket,
                icon: const Icon(Icons.check_circle),
                label: const Text('Close Ticket'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    if (_isLoadingMessages && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messageError != null && _messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load messages',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadMessages,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Messages List
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMessages,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isNew = !_seenMessageIds.contains(message.id);
                      
                      return Column(
                        children: [
                          // Show "New Messages" divider before first new message
                          if (index == _firstNewMessageIndex && _firstNewMessageIndex > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Theme.of(context).colorScheme.primary,
                                      thickness: 2,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'New Messages',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Theme.of(context).colorScheme.primary,
                                      thickness: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _MessageCard(
                            message: message,
                            isNew: isNew,
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ),

        // Send Message Card
        if (!widget.ticket.isClosed)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  tooltip: 'Send',
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
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

class _MessageCard extends StatelessWidget {
  final TicketMessage message;
  final bool isNew;

  const _MessageCard({required this.message, this.isNew = false});

  bool get _isAdminMessage => message.isAdmin || message.content.contains('[Admin Panel');
  bool get _isInitialMessage => message.content.contains('**Initial details');
  bool get _isClosingMessage => message.content.contains('Ticket successfully closed') || 
                                 message.content.contains('**Closing Message:**');

  String get _cleanContent {
    String content = message.content;
    
    // Remove markdown bold markers
    content = content.replaceAll('**', '');
    
    // Extract actual message from admin panel format
    if (_isAdminMessage) {
      final match = RegExp(r'\[Admin Panel - [^\]]+\]:\s*(.+)', dotAll: true).firstMatch(content);
      if (match != null) {
        return match.group(1) ?? content;
      }
    }
    
    // Extract actual message from initial details format
    if (_isInitialMessage) {
      final match = RegExp(r'Initial details from [^:]+:\s*(.+)', dotAll: true).firstMatch(content);
      if (match != null) {
        return match.group(1) ?? content;
      }
    }
    
    return content;
  }

  String get _displayName {
    if (_isAdminMessage) {
      final match = RegExp(r'\[Admin Panel - ([^\]]+)\]').firstMatch(message.content);
      if (match != null) {
        return match.group(1) ?? message.authorName;
      }
    }
    return message.authorName;
  }

  @override
  Widget build(BuildContext context) {
    final isSystem = message.isBot && !_isAdminMessage;
    
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Avatar
          (message.authorAvatar != null && 
                  message.authorAvatar!.isNotEmpty && 
                  !_isClosingMessage)
              ? Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: ClipOval(
                    child: Image.network(
                      message.authorAvatar!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            _isAdminMessage
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                  radius: 18,
                  backgroundColor: _isClosingMessage
                      ? Colors.green.withOpacity(0.2)
                      : _isAdminMessage
                          ? Theme.of(context).colorScheme.primaryContainer
                          : isSystem
                              ? Theme.of(context).colorScheme.surfaceContainerHighest
                              : Theme.of(context).colorScheme.secondaryContainer,
                  child: Icon(
                    _isClosingMessage
                        ? Icons.check_circle
                        : _isAdminMessage
                            ? Icons.admin_panel_settings
                            : isSystem
                                ? Icons.smart_toy
                                : Icons.person,
                    size: 20,
                    color: _isClosingMessage
                        ? Colors.green
                        : _isAdminMessage
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : isSystem
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onSecondaryContainer,
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
                        _displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _isAdminMessage
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isAdminMessage) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: message.role == 'moderator'
                              ? Colors.blue.withOpacity(0.2)
                              : Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          message.role == 'moderator' ? 'MOD' : 'ADMIN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: message.role == 'moderator'
                                ? Colors.blue
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                    if (_isClosingMessage) ...[
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
                    Text(
                      _formatDateTime(message.timestamp),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isClosingMessage
                        ? Colors.green.withOpacity(0.1)
                        : _isAdminMessage
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                            : isSystem
                                ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
                                : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: _isClosingMessage
                        ? Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 1,
                          )
                        : _isAdminMessage
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                width: 1,
                              )
                            : !message.isBot
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                    width: 1,
                                  )
                                : null,
                  ),
                  child: Text(
                    _cleanContent,
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
    ),
        // New message indicator
        if (isNew)
          Positioned(
            left: 0,
            top: 0,
            bottom: 16,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
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
}

class _UserSelectionDialog extends StatefulWidget {
  final List<dynamic> members;

  const _UserSelectionDialog({required this.members});

  @override
  State<_UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<_UserSelectionDialog> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> get _filteredMembers {
    if (_searchQuery.isEmpty) {
      return widget.members;
    }
    return widget.members.where((member) {
      final name = (member['name'] as String? ?? '').toLowerCase();
      final displayName = (member['display_name'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || displayName.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = _filteredMembers;

    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.person_add, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text(
                  'Assign to User',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Members List
            Expanded(
              child: filteredMembers.isEmpty
                  ? Center(
                      child: Text(
                        'No members found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredMembers.length,
                      itemBuilder: (context, index) {
                        final member = filteredMembers[index];
                        final id = member['id'] as String;
                        final name = member['name'] as String? ?? 'Unknown';
                        final displayName = member['display_name'] as String? ?? name;
                        final avatar = member['avatar_url'] as String?;
                        final status = member['status'] as String?;

                        Color statusColor = Colors.grey;
                        if (status == 'online') statusColor = Colors.green;
                        if (status == 'idle') statusColor = Colors.orange;
                        if (status == 'dnd') statusColor = Colors.red;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                                  child: avatar == null ? const Icon(Icons.person) : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('@$name'),
                            onTap: () => Navigator.pop(
                              context,
                              {
                                'id': id,
                                'name': name,
                                'display_name': displayName,
                                'avatar_url': avatar,
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              hintText: 'e.g., Issue resolved, let me know if you need more help.',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 500,
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
