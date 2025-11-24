import 'package:flutter/material.dart';
import '../screens/admin/ticket_detail_dialog.dart';
import '../screens/user/tickets_screen.dart';
import '../services/api_service.dart';
import '../models/ticket.dart';

/// Handle notification tap and navigate to the appropriate screen
Future<void> handleNotificationTap(BuildContext? context, Map<String, dynamic> data) async {
  if (context == null || !context.mounted) {
    debugPrint('⚠️ No valid context available for notification navigation');
    return;
  }

  try {
    final ticketId = data['ticket_id'] as String?;
    final notificationType = data['notification_type'] as String?;
    final openTab = data['open_tab'] as String?;  // New: which tab to open

    debugPrint('📱 Handling notification tap: type=$notificationType, ticketId=$ticketId, openTab=$openTab');

    if (ticketId == null) {
      debugPrint('⚠️ No ticket_id in notification data');
      return;
    }

    // Fetch ticket details from API
    final ticket = await _fetchTicket(context, ticketId);
    
    if (ticket == null) {
      debugPrint('⚠️ Could not fetch ticket $ticketId');
      _showError(context, 'Ticket not found');
      return;
    }

    // Navigate to ticket based on open_tab parameter
    if (context.mounted) {
      if (openTab == 'messages') {
        // User notification: open ticket chat screen
        _navigateToTicketChat(context, ticket);
      } else {
        // Admin notification: show ticket detail dialog
        _navigateToTicket(context, ticket);
      }
    }

  } catch (e) {
    debugPrint('❌ Error handling notification tap: $e');
    if (context.mounted) {
      _showError(context, 'Could not open ticket');
    }
  }
}

/// Fetch ticket from API
Future<Ticket?> _fetchTicket(BuildContext context, String ticketId) async {
  try {
    final apiService = ApiService();
    final ticket = await apiService.getTicket(ticketId);
    return ticket;
  } catch (e) {
    debugPrint('❌ Error fetching ticket: $e');
    return null;
  }
}

/// Navigate to ticket detail dialog (for admins)
void _navigateToTicket(BuildContext context, Ticket ticket) {
  // Show ticket dialog (works for both admin and user)
  showDialog(
    context: context,
    builder: (context) => TicketDetailDialog(
      ticket: ticket,
      onUpdate: () {
        // Refresh tickets list if needed
        debugPrint('🔄 Ticket updated from notification');
      },
    ),
  );
}

/// Navigate to ticket chat screen (for regular users)
void _navigateToTicketChat(BuildContext context, Ticket ticket) {
  // Navigate to user tickets screen with this ticket opened
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (context) => TicketsScreen(
        initialTicketId: ticket.ticketId,  // Open this specific ticket
      ),
    ),
    (route) => route.isFirst,  // Keep only the first route (home screen)
  );
}

/// Show error message
void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}
