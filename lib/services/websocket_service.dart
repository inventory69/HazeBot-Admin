import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart' show kIsWeb;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  final Map<String, List<Function(Map<String, dynamic>)>> _ticketListeners = {};
  bool _isConnected = false;

  // ✅ Track joined tickets with user IDs for cleanup on disconnect
  final Map<String, String?> _joinedTickets = {}; // ticketId -> userId

  bool get isConnected => _isConnected;

  /// Initialize WebSocket connection
  void connect(String baseUrl) {
    if (_socket != null && _socket!.connected) {
      return;
    }

    try {
      // Determine WebSocket URL based on platform
      String wsUrl;
      
      if (kIsWeb) {
        // WEB: Use current origin (admin.haze.pro)
        wsUrl = Uri.base.origin;
      } else {
        // MOBILE: Direct URL - remove trailing /api if present
        wsUrl = baseUrl.endsWith('/api')
            ? baseUrl.substring(0, baseUrl.length - 4)
            : baseUrl;
      }

      _socket = IO.io(
        wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'foo': 'bar'})
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
      });

      _socket!.onConnectError((error) {
        print('❌ WebSocket connection error: $error');
        _isConnected = false;
      });

      _socket!.on('connected', (data) {
        // Server confirmed connection
      });

      _socket!.on('ticket_update', (data) {
        _handleTicketUpdate(data);
      });

      _socket!.on('message_history', (data) {
        _handleMessageHistory(data);
      });

      _socket!.on('error', (error) {
        print('❌ WebSocket error: $error');
      });

      _socket!.connect();
    } catch (e) {
      print('❌ Failed to initialize WebSocket: $e');
    }
  }

  /// Wait for WebSocket to connect
  /// Returns true if connected, false if timeout
  Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 5)}) async {
    if (isConnected) {
      print('✅ Already connected');
      return true;
    }

    print('⏳ Waiting for WebSocket connection...');
    final start = DateTime.now();
    
    while (!isConnected) {
      if (DateTime.now().difference(start) > timeout) {
        print('❌ WebSocket connection timeout after ${timeout.inSeconds}s');
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('✅ WebSocket connection established');
    return true;
  }

  /// Disconnect WebSocket
  void disconnect() {
    if (_socket != null) {
      // Leave all joined tickets BEFORE disconnecting
      if (_joinedTickets.isNotEmpty) {
        for (var entry in _joinedTickets.entries) {
          final ticketId = entry.key;
          final userId = entry.value;

          final data = {'ticket_id': ticketId};
          if (userId != null) {
            data['user_id'] = userId;
          }

          _socket!.emit('leave_ticket', data);
        }
        _joinedTickets.clear();
      }

      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      // ✅ FIX: Do NOT clear listeners on disconnect!
      // Listeners are callbacks registered by widgets and should persist across reconnects
      // They will automatically work again when socket reconnects
      // _ticketListeners.clear(); // ❌ REMOVED - this caused messages to not arrive after reconnect
    }
  }

  /// Join a ticket room to receive updates
  /// [userId] - Discord user ID to suppress push notifications for this user
  void joinTicket(String ticketId, {String? userId}) {
    if (_socket == null || !_isConnected) {
      return;
    }

    final data = {'ticket_id': ticketId};
    if (userId != null) {
      data['user_id'] = userId;
    }

    _joinedTickets[ticketId] = userId;
    _socket!.emit('join_ticket', data);
  }

  /// Leave a ticket room
  /// [userId] - Discord user ID to re-enable push notifications for this user
  void leaveTicket(String ticketId, {String? userId}) {
    if (_socket == null || !_isConnected) {
      return;
    }

    final data = {'ticket_id': ticketId};
    if (userId != null) {
      data['user_id'] = userId;
    }

    _socket!.emit('leave_ticket', data);
    _joinedTickets.remove(ticketId);
    _ticketListeners.remove(ticketId);
  }

  /// Listen for ticket updates
  void onTicketUpdate(
      String ticketId, Function(Map<String, dynamic>) callback) {
    if (!_ticketListeners.containsKey(ticketId)) {
      _ticketListeners[ticketId] = [];
    }
    _ticketListeners[ticketId]!.add(callback);
  }

  /// Remove ticket update listener
  void removeTicketListener(
      String ticketId, Function(Map<String, dynamic>) callback) {
    if (_ticketListeners.containsKey(ticketId)) {
      _ticketListeners[ticketId]!.remove(callback);
      if (_ticketListeners[ticketId]!.isEmpty) {
        _ticketListeners.remove(ticketId);
      }
    }
  }

  /// Handle incoming ticket updates
  void _handleTicketUpdate(dynamic data) {
    try {
      final updateData = data as Map<String, dynamic>;
      final ticketId = updateData['ticket_id'] as String?;
      final eventType = updateData['event_type'] as String?;

      if (ticketId == null || eventType == null) {
        return;
      }

      // Notify all listeners for this ticket
      if (_ticketListeners.containsKey(ticketId)) {
        for (final listener in _ticketListeners[ticketId]!) {
          try {
            listener(updateData);
          } catch (e) {
            print('❌ Error in ticket listener: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error handling ticket update: $e');
    }
  }

  /// Handle message history from server
  void _handleMessageHistory(dynamic data) {
    try {
      final historyData = data as Map<String, dynamic>;
      final ticketId = historyData['ticket_id'] as String?;
      final messages = historyData['messages'] as List<dynamic>?;

      if (ticketId == null || messages == null) {
        return;
      }

      // Convert to proper format and notify listeners
      final updateData = {
        'ticket_id': ticketId,
        'event_type': 'message_history',
        'data': messages,
      };

      // Notify all listeners for this ticket
      if (_ticketListeners.containsKey(ticketId)) {
        for (final listener in _ticketListeners[ticketId]!) {
          try {
            listener(updateData);
          } catch (e) {
            print('❌ Error in message history listener: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error handling message history: $e');
    }
  }
}
