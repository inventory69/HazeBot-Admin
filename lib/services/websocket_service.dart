import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  final Map<String, List<Function(Map<String, dynamic>)>> _ticketListeners = {};
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Initialize WebSocket connection
  void connect(String baseUrl) {
    if (_socket != null && _socket!.connected) {
      print('🔌 WebSocket already connected');
      return;
    }

    try {
      // Remove trailing /api from baseUrl if present
      // baseUrl is like: https://api.haze.pro/api
      // We need: https://api.haze.pro
      final wsUrl = baseUrl.endsWith('/api')
          ? baseUrl.substring(0, baseUrl.length - 4)
          : baseUrl;
      print('🔌 Connecting to WebSocket: $wsUrl');

      _socket = IO.io(
        wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'foo': 'bar'})
            .build(),
      );

      _socket!.onConnect((_) {
        print('✅ WebSocket connected');
        _isConnected = true;
      });

      _socket!.onDisconnect((_) {
        print('❌ WebSocket disconnected');
        _isConnected = false;
      });

      _socket!.onConnectError((error) {
        print('❌ WebSocket connection error: $error');
        _isConnected = false;
      });

      _socket!.on('connected', (data) {
        print('📡 Server confirmed connection: $data');
      });

      _socket!.on('ticket_update', (data) {
        print('📨 Received ticket update: $data');
        _handleTicketUpdate(data);
      });

      _socket!.on('message_history', (data) {
        print('📜 Received message history: ${data}');
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

  /// Disconnect WebSocket
  void disconnect() {
    if (_socket != null) {
      print('🔌 Disconnecting WebSocket');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _ticketListeners.clear();
    }
  }

  /// Join a ticket room to receive updates
  void joinTicket(String ticketId) {
    if (_socket == null || !_socket!.connected) {
      print('⚠️ Cannot join ticket: WebSocket not connected');
      return;
    }

    print('🎫 Joining ticket room: $ticketId');
    _socket!.emit('join_ticket', {'ticket_id': ticketId});

    _socket!.once('joined_ticket', (data) {
      print('✅ Joined ticket room: $data');
    });
  }

  /// Leave a ticket room
  void leaveTicket(String ticketId) {
    if (_socket == null || !_socket!.connected) {
      return;
    }

    print('🎫 Leaving ticket room: $ticketId');
    _socket!.emit('leave_ticket', {'ticket_id': ticketId});

    _ticketListeners.remove(ticketId);
  }

  /// Listen for ticket updates
  void onTicketUpdate(
      String ticketId, Function(Map<String, dynamic>) callback) {
    if (!_ticketListeners.containsKey(ticketId)) {
      _ticketListeners[ticketId] = [];
    }
    _ticketListeners[ticketId]!.add(callback);
    print('👂 Added listener for ticket: $ticketId');
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
        print('⚠️ Invalid ticket update data: $updateData');
        return;
      }

      print('📡 Processing $eventType for ticket $ticketId');

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
        print('⚠️ Invalid message history data: $historyData');
        return;
      }

      print(
          '📜 Processing message history for ticket $ticketId: ${messages.length} messages');

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
