import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../models/ticket_message.dart';
import '../../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _messages.isEmpty) {
        _loadMessages();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoadingMessages = true;
      _messageError = null;
    });

    try {
      final messagesData = await ApiService().getTicketMessages(widget.ticket.ticketId);
      setState(() {
        _messages = messagesData
            .map((json) => TicketMessage.fromJson(json as Map<String, dynamic>))
            .toList();
        _isLoadingMessages = false;
      });
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
    final userIdController = TextEditingController();
    
    final userId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the Discord User ID to assign this ticket to:'),
            const SizedBox(height: 16),
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                hintText: 'e.g., 123456789012345678',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, userIdController.text.trim()),
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (userId == null || userId.isEmpty) return;

    try {
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
                      Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        widget.ticket.username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${widget.ticket.userId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created: ${widget.ticket.createdAt != null ? _formatDateTime(widget.ticket.createdAt!) : 'Unknown'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Assignment Card
          if (widget.ticket.claimedBy != null || widget.ticket.assignedTo != null)
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.ticket.claimedBy != null) ...[
                      Text(
                        'Claimed by',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'User ID: ${widget.ticket.claimedBy}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (widget.ticket.assignedTo != null) const SizedBox(height: 12),
                    ],
                    if (widget.ticket.assignedTo != null) ...[
                      Text(
                        'Assigned to',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'User ID: ${widget.ticket.assignedTo}',
                        style: const TextStyle(fontSize: 14),
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
            if (!widget.ticket.isClaimed)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _claimTicket,
                  icon: const Icon(Icons.pan_tool),
                  label: const Text('Claim Ticket'),
                ),
              ),
            if (!widget.ticket.isClaimed) const SizedBox(height: 8),
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
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _MessageCard(message: message);
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

  const _MessageCard({required this.message});

  bool get _isAdminMessage => message.content.contains('[Admin Panel');
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
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: _isClosingMessage
                ? Colors.green.withOpacity(0.2)
                : _isAdminMessage 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : isSystem
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.secondaryContainer,
            backgroundImage: message.authorAvatar != null && !_isAdminMessage && !_isClosingMessage
                ? NetworkImage(message.authorAvatar!)
                : null,
            child: message.authorAvatar == null || _isAdminMessage || _isClosingMessage
                ? Icon(
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
                            ? Theme.of(context).colorScheme.primary
                            : isSystem
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onSecondaryContainer,
                  )
                : null,
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
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isClosingMessage
                        ? Colors.green.withOpacity(0.1)
                        : _isAdminMessage
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                            : isSystem
                                ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
                                : Theme.of(context).colorScheme.surfaceContainerHigh,
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
