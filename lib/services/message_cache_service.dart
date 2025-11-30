import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_message.dart';

/// Message cache service for offline-first ticket chat experience
/// Stores messages per ticket in SharedPreferences for instant loading
class MessageCacheService {
  static final MessageCacheService _instance = MessageCacheService._internal();
  factory MessageCacheService() => _instance;
  MessageCacheService._internal() {
    _init();
  }

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Cache settings
  static const int _maxCachedTickets = 50;
  static const int _cacheValidityHours = 24;

  Future<void> _init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      await _cleanupOldCaches(); // LRU cleanup on init
      debugPrint('💾 MessageCacheService initialized');
    }
  }

  /// Ensure initialization (call in initState if needed)
  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await _init();
    }
  }

  /// Get cached messages synchronously (returns null if not cached or expired)
  List<TicketMessage>? getCachedMessages(String ticketId) {
    if (_prefs == null) {
      debugPrint('⚠️ Cache not initialized yet for ticket $ticketId');
      return null;
    }

    final cacheKey = 'message_cache_ticket_$ticketId';
    final cacheJson = _prefs!.getString(cacheKey);

    if (cacheJson == null) {
      return null;
    }

    try {
      final cacheData = jsonDecode(cacheJson) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Check if cache is still valid (24h)
      if (now - timestamp > _cacheValidityHours * 3600) {
        debugPrint(
            '🗑️ Cache expired for ticket $ticketId (${(now - timestamp) ~/ 3600}h old)');
        return null;
      }

      final messagesJson = cacheData['messages'] as List<dynamic>;
      final messages = messagesJson
          .map((json) => TicketMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint(
          '💾 Loaded ${messages.length} messages from cache (ticket: ${ticketId.substring(0, 8)}...)');
      return messages;
    } catch (e) {
      debugPrint('⚠️ Failed to parse cached messages: $e');
      return null;
    }
  }

  /// Cache messages for a ticket (async, fire-and-forget)
  Future<void> cacheMessages(
      String ticketId, List<TicketMessage> messages) async {
    if (_prefs == null) await _init();

    final cacheKey = 'message_cache_ticket_$ticketId';
    final cacheData = {
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'messages': messages.map((m) => m.toJson()).toList(),
    };

    try {
      await _prefs!.setString(cacheKey, jsonEncode(cacheData));
      debugPrint(
          '💾 Cached ${messages.length} messages for ticket ${ticketId.substring(0, 8)}...');

      // Update metadata (for LRU tracking)
      await _updateCacheMetadata(ticketId);
    } catch (e) {
      debugPrint('⚠️ Failed to cache messages: $e');
    }
  }

  /// Append a single message to existing cache (instant, fire-and-forget)
  void appendMessage(String ticketId, TicketMessage message) {
    final cached = getCachedMessages(ticketId);
    if (cached != null) {
      cached.add(message);
      cacheMessages(ticketId, cached); // Fire-and-forget
      debugPrint(
          '➕ Appended message to cache (ticket: ${ticketId.substring(0, 8)}...)');
    }
  }

  /// Update cache metadata (LRU tracking)
  Future<void> _updateCacheMetadata(String ticketId) async {
    final metadataKey = 'message_cache_metadata';
    final metadataJson = _prefs!.getString(metadataKey);

    Map<String, int> metadata = {};
    if (metadataJson != null) {
      try {
        metadata = Map<String, int>.from(jsonDecode(metadataJson) as Map);
      } catch (e) {
        debugPrint('⚠️ Failed to parse cache metadata: $e');
      }
    }

    metadata[ticketId] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _prefs!.setString(metadataKey, jsonEncode(metadata));
  }

  /// Cleanup old caches (LRU strategy - keeps newest N tickets)
  Future<void> _cleanupOldCaches() async {
    final metadataKey = 'message_cache_metadata';
    final metadataJson = _prefs!.getString(metadataKey);

    if (metadataJson == null) return;

    try {
      final metadata = Map<String, int>.from(jsonDecode(metadataJson) as Map);

      // If we have more than max, remove oldest
      if (metadata.length > _maxCachedTickets) {
        final sorted = metadata.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

        final toRemove = sorted.take(metadata.length - _maxCachedTickets);

        for (final entry in toRemove) {
          final cacheKey = 'message_cache_ticket_${entry.key}';
          await _prefs!.remove(cacheKey);
          metadata.remove(entry.key);
          debugPrint(
              '🗑️ Removed old cache for ticket ${entry.key.substring(0, 8)}... (LRU cleanup)');
        }

        await _prefs!.setString(metadataKey, jsonEncode(metadata));
        debugPrint(
            '✅ LRU cleanup complete: ${metadata.length}/$_maxCachedTickets tickets cached');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to cleanup old caches: $e');
    }
  }

  /// Clear cache for a specific ticket (useful for testing or user-triggered refresh)
  Future<void> clearTicketCache(String ticketId) async {
    if (_prefs == null) await _init();

    final cacheKey = 'message_cache_ticket_$ticketId';
    await _prefs!.remove(cacheKey);
    debugPrint('🗑️ Cleared cache for ticket ${ticketId.substring(0, 8)}...');
  }

  /// Clear all message caches (useful for logout or debugging)
  Future<void> clearAllCaches() async {
    if (_prefs == null) await _init();

    final metadataKey = 'message_cache_metadata';
    final metadataJson = _prefs!.getString(metadataKey);

    if (metadataJson != null) {
      try {
        final metadata = Map<String, int>.from(jsonDecode(metadataJson) as Map);

        for (final ticketId in metadata.keys) {
          final cacheKey = 'message_cache_ticket_$ticketId';
          await _prefs!.remove(cacheKey);
        }

        await _prefs!.remove(metadataKey);
        debugPrint(
            '🗑️ Cleared all message caches (${metadata.length} tickets)');
      } catch (e) {
        debugPrint('⚠️ Failed to clear all caches: $e');
      }
    }
  }
}
