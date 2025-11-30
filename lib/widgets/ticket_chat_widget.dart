import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../models/ticket.dart';
import '../models/ticket_message.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/message_cache_service.dart';

/// Shared chat widget for ticket conversations
/// Used in both Admin Dialog (embedded) and User Screen (full-screen)
class TicketChatWidget extends StatefulWidget {
  final Ticket ticket;
  final bool isFullScreen;
  final VoidCallback? onClose;

  const TicketChatWidget({
    super.key,
    required this.ticket,
    this.isFullScreen = false,
    this.onClose,
  });

  @override
  State<TicketChatWidget> createState() => _TicketChatWidgetState();
}

class _TicketChatWidgetState extends State<TicketChatWidget>
    with WidgetsBindingObserver {
  List<TicketMessage> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _messageError;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode(); // For keyboard detection
  int _previousMessageCount = 0;
  final Set<String> _seenMessageIds = {}; // Prevent duplicates
  int _firstNewMessageIndex = -1;
  final GlobalKey _newMessagesDividerKey =
      GlobalKey(); // For precise scroll position
  String? _currentUserDiscordId; // ✅ Cache current user's Discord ID
  bool _isUserAtBottom =
      true; // ✅ Track if user is at bottom (for auto-scroll logic)
  bool _isKeyboardVisible = false; // ✅ Track keyboard visibility

  // ✅ Telegram-Style Scroll
  static const double _estimatedMessageHeight =
      85.0; // Average message height for pre-scroll
  bool _hasScrolledToInitialPosition =
      false; // Prevent duplicate initial scrolls

  // ✅ Message Cache Service
  final MessageCacheService _cacheService = MessageCacheService();

  // ✅ Store AuthService reference to avoid context access in dispose
  AuthService? _authService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ✅ Observe keyboard changes

    // ✅ 1. Initialize cache service
    _cacheService.ensureInitialized();

    // ✅ 2. Load current user ID first
    _loadCurrentUser();

    // ✅ 3. Try cache FIRST (synchronous, instant render)
    _loadCachedMessagesSync();

    // ✅ 4. Setup WebSocket (before API call)
    _setupWebSocketListener();

    // ✅ 5. Dismiss notifications
    _dismissNotifications();

    // ✅ 6. Setup listeners
    _setupKeyboardListener();
    _setupScrollListener();

    // ✅ 7. INSTANT PRE-SCROLL (Telegram-style estimated position)
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _performInitialScroll();
    });

    // ✅ 8. Load from API (in background, updates cache)
    _loadMessages();
  }

  @override
  void didChangeMetrics() {
    // ✅ CRITICAL: Check if widget is still in tree before accessing context
    if (!mounted) {
      return;
    }

    // ✅ Web doesn't support View.of() reliably - skip keyboard detection
    if (kIsWeb) {
      return;
    }

    // ✅ Try-catch to prevent crashes when widget is being disposed
    try {
      // Use PlatformDispatcher for direct keyboard detection (fastest)
      final window = WidgetsBinding.instance.platformDispatcher.views.first;
      final bottomInset = window.viewInsets.bottom / window.devicePixelRatio;
      final isKeyboardVisible = bottomInset > 0;

      if (isKeyboardVisible != _isKeyboardVisible) {
        _isKeyboardVisible = isKeyboardVisible;
        debugPrint('⌨️ Keyboard visibility changed: $_isKeyboardVisible');

        // ✅ Auto-scroll to bottom when keyboard opens (only if user was at bottom)
        // Longer delay for Android keyboard animation
        if (_isKeyboardVisible && _isUserAtBottom) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted && _scrollController.hasClients) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      }
    } catch (e) {
      // Widget was disposed during execution - safe to ignore
      return;
    }
  }

  /// Setup keyboard listener for focus changes
  void _setupKeyboardListener() {
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus && _isUserAtBottom) {
        // When input field gains focus, scroll to bottom
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _scrollToBottom(animate: true);
          }
        });
      }
    });
  }

  /// Setup scroll listener to track if user is at bottom
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      const threshold = 100.0; // Consider "at bottom" if within 100px

      final wasAtBottom = _isUserAtBottom;
      _isUserAtBottom = (maxScroll - currentScroll) < threshold;

      // Debug only on state change
      if (wasAtBottom != _isUserAtBottom) {
        debugPrint(
            '📍 User scroll position: ${_isUserAtBottom ? "AT BOTTOM" : "SCROLLED UP"}');
      }
    });
  }

  /// Load current user's Discord ID for duplicate message detection
  Future<void> _loadCurrentUser() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.apiService.getCurrentUser();
      _currentUserDiscordId = userData['discord_id']?.toString();
      debugPrint('👤 Current user Discord ID: $_currentUserDiscordId');
    } catch (e) {
      debugPrint('⚠️ Could not load current user ID: $e');
    }
  }

  /// Load cached messages synchronously (Telegram-style instant render)
  void _loadCachedMessagesSync() {
    final cachedMessages =
        _cacheService.getCachedMessages(widget.ticket.ticketId);

    if (cachedMessages != null && cachedMessages.isNotEmpty) {
      setState(() {
        _messages = cachedMessages;
        _previousMessageCount = cachedMessages.length;

        // Mark all as seen
        for (final msg in cachedMessages) {
          _seenMessageIds.add(msg.id);
        }
      });
    } else {
      debugPrint(
          '📭 No cached messages for ticket ${widget.ticket.ticketId.substring(0, 8)}...');
    }
  }

  /// Perform initial scroll to bottom (Telegram-style with triple strategy)
  void _performInitialScroll() {
    if (!mounted || _hasScrolledToInitialPosition) return;

    if (!_scrollController.hasClients) {
      // Retry if ListView not ready yet
      Future.delayed(const Duration(milliseconds: 50), _performInitialScroll);
      return;
    }

    _hasScrolledToInitialPosition = true;

    // ✅ STRATEGY 1: Estimated scroll (instant, no flicker)
    if (_messages.isNotEmpty) {
      final estimatedMax = _messages.length * _estimatedMessageHeight;
      _scrollController.jumpTo(estimatedMax);
      debugPrint(
          '📍 Pre-scrolled to ESTIMATED position: ${estimatedMax.toInt()}px (${_messages.length} msgs)');
    }

    // ✅ STRATEGY 2: Correction scroll after render
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        final actualMax = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(actualMax);
        debugPrint('📍 Corrected to ACTUAL max: ${actualMax.toInt()}px');

        // ✅ STRATEGY 3: Final safety net (after images/avatars load)
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _scrollController.hasClients) {
            final finalMax = _scrollController.position.maxScrollExtent;
            final currentPos = _scrollController.position.pixels;

            if ((finalMax - currentPos).abs() > 5) {
              _scrollController.jumpTo(finalMax);
              debugPrint(
                  '🎯 Final correction: ${finalMax.toInt()}px (was ${currentPos.toInt()}px)');
            } else {
              debugPrint('✅ Already at bottom: ${currentPos.toInt()}px');
            }
          }
        });
      }
    });
  }

  /// Dismiss ticket notifications when user enters the chat
  void _dismissNotifications() {
    // Get singleton instance of NotificationService
    final notificationService = NotificationService();

    // Dismiss all notifications for this ticket
    notificationService.dismissTicketNotifications(widget.ticket.ticketId);
    debugPrint(
        '🔕 Dismissed notifications for ticket ${widget.ticket.ticketId}');
  }

  void _setupWebSocketListener() {
    // Store AuthService reference for use in dispose()
    _authService = Provider.of<AuthService>(context, listen: false);
    final wsService = _authService!.wsService;

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

    // ✅ FIX: Check if message already exists (prevent duplicates)
    if (_seenMessageIds.contains(newMessage.id)) {
      debugPrint('⚠️ Duplicate message ignored: ${newMessage.id}');
      return;
    }

    // ✅ FIX: Skip own messages from WebSocket (already added optimistically)
    // This prevents duplicate messages when user sends a message
    if (_currentUserDiscordId != null &&
        newMessage.authorId == _currentUserDiscordId) {
      debugPrint(
          '⏭️ Skipping own message from WebSocket: ${newMessage.id} (already added optimistically)');
      return;
    }

    final oldCount = _messages.length;

    setState(() {
      _messages.add(newMessage);
      _seenMessageIds.add(newMessage.id);
      _previousMessageCount = _messages.length;

      // Mark where new messages start (if not already set)
      if (_firstNewMessageIndex < 0) {
        _firstNewMessageIndex = oldCount;
      }
    });

    // ✅ Update cache (fire-and-forget)
    _cacheService.appendMessage(widget.ticket.ticketId, newMessage);

    // ✅ IMPROVED: Smart scroll behavior based on user position
    // - If user is at bottom: auto-scroll to new message
    // - If user scrolled up: don't interrupt their reading
    if (_isUserAtBottom) {
      debugPrint('📩 New message arrived, user at bottom → auto-scrolling');
      _scrollToBottom(animate: true);
    } else {
      debugPrint(
          '📩 New message arrived, user scrolled up → not auto-scrolling');
      // Optional: Could show a "New messages" badge here
    }
  }

  @override
  void dispose() {
    // Leave WebSocket ticket room (use stored reference to avoid context access)
    _authService?.wsService.leaveTicket(widget.ticket.ticketId);

    WidgetsBinding.instance.removeObserver(this); // ✅ Remove observer
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose(); // ✅ Clean up focus node
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    // ✅ IMPROVED: Instant scroll to bottom with multiple retries for reliability
    if (!mounted || !_scrollController.hasClients) return;

    // Immediately update user position tracking
    _isUserAtBottom = true;

    void performScroll() {
      if (!mounted || !_scrollController.hasClients) return;

      final targetPosition = _scrollController.position.maxScrollExtent;

      if (animate) {
        _scrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(targetPosition);
      }
    }

    // Immediate first scroll (no delay)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      performScroll();

      // Retry 1: after 100ms (for fast-loading images)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          performScroll();

          // Retry 2: after 300ms (for slow-loading avatars)
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && _scrollController.hasClients) {
              final maxExtent = _scrollController.position.maxScrollExtent;
              final currentPos = _scrollController.position.pixels;

              if ((maxExtent - currentPos).abs() > 10) {
                debugPrint(
                    '🔄 Final scroll correction (delta: ${maxExtent - currentPos}px)');
                _scrollController.jumpTo(maxExtent);

                // Retry 3: Extra aggressive retry after 600ms (for initial load on web)
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted && _scrollController.hasClients) {
                    final finalMax = _scrollController.position.maxScrollExtent;
                    final finalPos = _scrollController.position.pixels;

                    if ((finalMax - finalPos).abs() > 10) {
                      debugPrint(
                          '🔄 Extra aggressive scroll correction (delta: ${finalMax - finalPos}px)');
                      _scrollController.jumpTo(finalMax);
                    }
                  }
                });
              }
            }
          });
        }
      });
    });
  }

  void _scrollToNewMessages() {
    // ✅ FIX: Discord-style scroll to "New Messages" divider with precise positioning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _scrollController.hasClients &&
          _firstNewMessageIndex >= 0) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            // Try to use GlobalKey for exact position
            final dividerContext = _newMessagesDividerKey.currentContext;
            if (dividerContext != null) {
              // Use Scrollable.ensureVisible for precise, automatic scrolling
              Scrollable.ensureVisible(
                dividerContext,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                alignment: 0.2, // Scroll to 20% from top (like Discord)
              );
              debugPrint(
                  '✅ Scrolled to New Messages divider (precise position)');
            } else {
              // Fallback: Estimate position (better than before)
              final maxScroll = _scrollController.position.maxScrollExtent;
              final viewportHeight =
                  _scrollController.position.viewportDimension;
              final estimatedMessageHeight = maxScroll / _messages.length;
              final dividerOffset =
                  _firstNewMessageIndex * estimatedMessageHeight;

              // Scroll to show divider near top (20% from top like Discord)
              final targetPosition = (dividerOffset - (viewportHeight * 0.2))
                  .clamp(0.0, maxScroll);

              _scrollController.animateTo(
                targetPosition,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
              debugPrint(
                  '⚠️ Scrolled to New Messages divider (estimated position)');
            }
          }
        });
      }
    });
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;

    // ✅ Only show loading if we have NO cached messages
    final showLoading = _messages.isEmpty;

    if (showLoading) {
      setState(() {
        _isLoadingMessages = true;
        _messageError = null;
      });
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final messagesData = await authService.apiService
          .getTicketMessages(widget.ticket.ticketId);

      if (mounted) {
        // Convert List<dynamic> to List<TicketMessage>
        final messages = messagesData
            .map((json) => TicketMessage.fromJson(json as Map<String, dynamic>))
            .toList();

        // ✅ Detect if we have NEW messages (vs. cached)
        final hasNewMessages = messages.length > _previousMessageCount;
        final isUpdate = _previousMessageCount > 0; // We had cache

        setState(() {
          _messages = messages;
          _previousMessageCount = messages.length;
          _isLoadingMessages = false;

          // Mark all messages as seen
          for (final msg in messages) {
            _seenMessageIds.add(msg.id);
          }
        });

        // ✅ Update cache (fire-and-forget)
        _cacheService.cacheMessages(widget.ticket.ticketId, messages);

        // ✅ Scroll behavior:
        // - First load WITH cache: Already scrolled by _performInitialScroll()
        // - First load NO cache: _performInitialScroll() handles it
        // - Update with new messages: Scroll to bottom (if user was there)
        if (isUpdate && hasNewMessages && _isUserAtBottom) {
          debugPrint('📩 New messages loaded from API, scrolling to bottom');
          _scrollToBottom(animate: true);
        } else if (!_hasScrolledToInitialPosition) {
          // Fallback: Initial scroll if _performInitialScroll() hasn't run yet
          _performInitialScroll();
        }

        // ✅ Auto-focus textbox on desktop/web (only on first load)
        if (!isUpdate) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted && !_messageFocusNode.hasFocus) {
              final mediaQuery = MediaQuery.of(context);
              final isDesktopOrWeb = kIsWeb || mediaQuery.size.width > 600;

              if (isDesktopOrWeb) {
                _messageFocusNode.requestFocus();
                debugPrint('🎯 Auto-focused message input (desktop/web)');
              } else {
                debugPrint('📱 Skipping auto-focus on mobile');
              }
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messageError = 'Failed to load messages: $e';
          _isLoadingMessages = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();

    setState(() => _isSending = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final newMessageData = await authService.apiService.sendTicketMessage(
        widget.ticket.ticketId,
        content,
      );

      if (mounted) {
        // Convert Map to TicketMessage
        final newMessage = TicketMessage.fromJson(newMessageData);

        // ✅ FIX: Add to seen IDs immediately (before WebSocket arrives)
        _seenMessageIds.add(newMessage.id);

        // Optimistic update (won't be duplicated by WebSocket)
        setState(() {
          _messages.add(newMessage);
          _previousMessageCount = _messages.length;
          _isSending = false;
        });

        // Clear input (will close keyboard on Android - we reopen it below)
        _messageController.clear();

        // ✅ AGGRESSIVE: Force keyboard to stay open
        // Android closes keyboard on clear() - we must force it open again
        if (!kIsWeb && mounted) {
          // Multiple attempts with increasing delays to ensure keyboard reopens
          _messageFocusNode.requestFocus();
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) _messageFocusNode.requestFocus();
          });
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) _messageFocusNode.requestFocus();
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _messageFocusNode.requestFocus();
          });
        }

        // ✅ Update cache (fire-and-forget)
        _cacheService.appendMessage(widget.ticket.ticketId, newMessage);

        // ✅ IMPROVED: Always scroll to bottom after sending (instant)
        // User expects to see their own message immediately
        _isUserAtBottom = true; // Mark user as at bottom

        // Wait for frame to render new message, then scroll
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
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
    final colorScheme = Theme.of(context).colorScheme;
    final isClosed = widget.ticket.isClosed;

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
                          if (index == _firstNewMessageIndex &&
                              _firstNewMessageIndex > 0)
                            Padding(
                              key:
                                  _newMessagesDividerKey, // ✅ GlobalKey for precise scroll
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: colorScheme.primary,
                                      thickness: 2,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      'New Messages',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: colorScheme.primary,
                                      thickness: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _buildMessageBubble(message, isNew),
                        ],
                      );
                    },
                  ),
                ),
        ),

        // Message Input (hidden if ticket closed)
        if (!isClosed)
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  // ✅ Send button as suffix - using GestureDetector to prevent focus loss
                  suffixIcon: _isSending
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(4),
                          child: GestureDetector(
                            onTap: _sendMessage,
                            // ✅ Prevents TextField from losing focus
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.send,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
                enabled: !_isSending,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageBubble(TicketMessage message, bool isNew) {
    final colorScheme = Theme.of(context).colorScheme;

    // Check message types
    final isAdminMessage = message.isAdmin ||
        message.content.contains('[Admin Panel') ||
        message.role != null;
    final isInitialMessage = message.content.contains('**Initial details');
    final isClosingMessage =
        message.content.contains('Ticket successfully closed') ||
            message.content.contains('**Closing Message:**');
    final isSystem = message.isBot && !isAdminMessage;

    // Clean content
    String cleanContent = message.content;
    cleanContent = cleanContent.replaceAll('**', '');

    if (isAdminMessage) {
      final match = RegExp(r'\[Admin Panel - [^\]]+\]:\s*(.+)', dotAll: true)
          .firstMatch(cleanContent);
      if (match != null) {
        cleanContent = match.group(1) ?? cleanContent;
      }
    }

    if (isInitialMessage) {
      final match = RegExp(r'Initial details from [^:]+:\s*(.+)', dotAll: true)
          .firstMatch(cleanContent);
      if (match != null) {
        cleanContent = match.group(1) ?? cleanContent;
      }
    }

    // Get display name
    String displayName = message.authorName;
    if (isAdminMessage) {
      final match =
          RegExp(r'\[Admin Panel - ([^\]]+)\]').firstMatch(message.content);
      if (match != null) {
        displayName = match.group(1) ?? message.authorName;
      }
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _buildAvatar(message, isAdminMessage, isClosingMessage, isSystem),
              const SizedBox(width: 12),
              // Message content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildMessageHeader(
                      displayName,
                      message,
                      isAdminMessage,
                      isClosingMessage,
                    ),
                    const SizedBox(height: 6),
                    // Message bubble
                    _buildMessageContent(
                      cleanContent,
                      isAdminMessage,
                      isClosingMessage,
                      isSystem,
                      message.isBot,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // New message indicator (blue line on left)
        if (isNew)
          Positioned(
            left: 0,
            top: 0,
            bottom: 8,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(
    TicketMessage message,
    bool isAdminMessage,
    bool isClosingMessage,
    bool isSystem,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarUrl = message.authorAvatar;

    // Avatar with Discord image or fallback icon
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Container(
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
              return Center(
                child: Icon(
                  message.isBot
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
      );
    }

    // Fallback icon avatar
    return CircleAvatar(
      radius: 16,
      backgroundColor: isClosingMessage
          ? Colors.green.withOpacity(0.2)
          : isAdminMessage
              ? colorScheme.primaryContainer
              : isSystem
                  ? colorScheme.tertiaryContainer
                  : colorScheme.secondaryContainer,
      child: Icon(
        message.isBot
            ? Icons.smart_toy
            : isAdminMessage
                ? Icons.admin_panel_settings
                : Icons.person,
        size: 20,
        color: isClosingMessage
            ? Colors.green
            : isAdminMessage
                ? colorScheme.primary
                : isSystem
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onSecondaryContainer,
      ),
    );
  }

  Widget _buildMessageHeader(
    String displayName,
    TicketMessage message,
    bool isAdminMessage,
    bool isClosingMessage,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Flexible(
          child: Text(
            displayName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isAdminMessage ? colorScheme.primary : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isAdminMessage) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: message.role == 'moderator'
                  ? Colors.blue.withOpacity(0.2)
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              message.role == 'moderator' ? 'MOD' : 'ADMIN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: message.role == 'moderator'
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
        Text(
          _formatMessageTime(message.timestamp),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent(
    String cleanContent,
    bool isAdminMessage,
    bool isClosingMessage,
    bool isSystem,
    bool isBot,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                : !isBot
                    ? Border.all(
                        color: colorScheme.outline.withOpacity(0.3),
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
}
