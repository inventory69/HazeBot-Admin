import 'package:flutter/material.dart';
import '../screens/admin/ticket_detail_dialog.dart';
import '../screens/admin/tickets_admin_screen.dart';
import '../screens/user/tickets_screen.dart';
import '../services/api_service.dart';
import '../models/ticket.dart';

/// Handle notification tap and navigate to the appropriate screen
Future<void> handleNotificationTap(
    BuildContext? context, Map<String, dynamic> data) async {
  if (context == null || !context.mounted) {
    debugPrint('⚠️ No valid context available for notification navigation');
    return;
  }

  try {
    final ticketId = data['ticket_id'] as String?;
    final notificationType = data['notification_type'] as String?;
    final openTab = data['open_tab'] as String?; // New: which tab to open

    debugPrint(
        '📱 Handling notification tap: type=$notificationType, ticketId=$ticketId, openTab=$openTab');

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

    // Check user role to determine navigation
    final isOwnTicket = await _isUserTicket(context, ticket);
    final isAdmin = await _isUserAdmin(context);

    // Navigate based on role and ticket ownership
    if (context.mounted) {
      if (isOwnTicket) {
        // Own ticket → always go to user ticket chat
        debugPrint('📱 Opening OWN ticket in user view');
        _navigateToTicketChat(context, ticket);
      } else if (isAdmin) {
        // Admin viewing other user's ticket → admin dialog
        debugPrint('📱 Opening OTHER USER ticket in admin dialog');
        _navigateToAdminDialog(context, ticket);
      } else {
        // Fallback to legacy behavior
        if (openTab == 'messages') {
          _navigateToTicketChat(context, ticket);
        } else {
          _navigateToTicket(context, ticket);
        }
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

/// Check if ticket belongs to current user
Future<bool> _isUserTicket(BuildContext context, Ticket ticket) async {
  try {
    final apiService = ApiService();
    final userData = await apiService.getCurrentUser();
    final userDiscordId = userData['discord_id']?.toString();
    return ticket.userId == userDiscordId;
  } catch (e) {
    debugPrint('❌ Error checking ticket ownership: $e');
    return false;
  }
}

/// Check if current user is admin
Future<bool> _isUserAdmin(BuildContext context) async {
  try {
    final apiService = ApiService();
    final userData = await apiService.getCurrentUser();
    final role = userData['role'] as String?;
    return role == 'admin' || role == 'moderator';
  } catch (e) {
    debugPrint('❌ Error checking admin status: $e');
    return false;
  }
}

/// Navigate to admin dialog for other users' tickets
void _navigateToAdminDialog(BuildContext context, Ticket ticket) {
  // ✅ FIX: Use push instead of pushReplacement to preserve navigation stack
  // This allows admins to go back to the previous screen after closing the dialog
  debugPrint('📱 Navigating to admin screen with ticket dialog');

  Navigator.of(context)
      .push(
    MaterialPageRoute(
      builder: (context) => const TicketsAdminScreen(),
      settings: const RouteSettings(name: '/admin/tickets'),
    ),
  )
      .then((_) {
    // After navigation, show the ticket dialog
    if (context.mounted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => TicketDetailDialog(
              ticket: ticket,
              onUpdate: () {
                debugPrint('🔄 Admin ticket updated from notification');
              },
            ),
          );
        }
      });
    }
  });
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
  // Import the ticket detail screen from tickets_screen.dart
  // Since _TicketDetailScreen is private, we need to use the public route
  // Navigate directly to the chat by pushing a new screen
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) {
        // We'll use a simple approach: navigate to TicketsScreen first,
        // then it will auto-open the ticket via initialTicketId
        return TicketsScreen(initialTicketId: ticket.ticketId);
      },
    ),
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
