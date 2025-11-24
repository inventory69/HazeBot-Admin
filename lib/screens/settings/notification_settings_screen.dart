import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../services/discord_auth_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  // Settings state
  bool _ticketNewMessages = true;
  bool _ticketMentions = true;
  bool _ticketCreated = true;
  bool _ticketAssigned = true;
  
  bool _isAdmin = false;
  bool _isModerator = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 [NotificationSettings] initState() called');
    
    // Delay to ensure context is fully available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🎬 [NotificationSettings] PostFrameCallback - calling _loadSettings()');
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    debugPrint('🔧 [NotificationSettings] _loadSettings() started');
    
    if (!mounted) {
      debugPrint('⚠️ [NotificationSettings] Widget not mounted, aborting');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    debugPrint('🔧 [NotificationSettings] Loading state set');

    try {
      debugPrint('🔧 [NotificationSettings] Getting DiscordAuthService from context...');
      final authService = context.read<DiscordAuthService>();
      debugPrint('✅ [NotificationSettings] Got DiscordAuthService');
      
      debugPrint('🔧 [NotificationSettings] Creating NotificationService...');
      final notificationService = NotificationService();
      debugPrint('✅ [NotificationSettings] NotificationService created');

      debugPrint('🔧 [NotificationSettings] Checking user role...');
      final userInfo = authService.userInfo;
      _isAdmin = userInfo?['roles']?.contains('admin') ?? false;
      _isModerator = userInfo?['roles']?.contains('moderator') ?? false;
      debugPrint('✅ [NotificationSettings] User role: admin=$_isAdmin, moderator=$_isModerator');

      // Check if permission already granted
      if (!notificationService.hasPermission) {
        debugPrint('📱 [NotificationSettings] Notification permission not granted yet');
      }

      debugPrint('🔧 [NotificationSettings] Loading settings from backend...');
      final settings = await notificationService.getNotificationSettings(authService.apiService);
      debugPrint('✅ [NotificationSettings] Got settings from backend: $settings');

      if (settings != null) {
        if (!mounted) {
          debugPrint('⚠️ [NotificationSettings] Widget unmounted after loading, aborting setState');
          return;
        }
        
        setState(() {
          _ticketNewMessages = settings['ticket_new_messages'] ?? true;
          _ticketMentions = settings['ticket_mentions'] ?? true;
          _ticketCreated = settings['ticket_created'] ?? true;
          _ticketAssigned = settings['ticket_assigned'] ?? true;
          _isLoading = false;
        });
        debugPrint('✅ [NotificationSettings] Settings loaded successfully');
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to load notification settings';
          _isLoading = false;
        });
        debugPrint('⚠️ [NotificationSettings] No settings returned from backend');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [NotificationSettings] Error loading settings: $e');
      debugPrint('📚 [NotificationSettings] Stack trace: $stackTrace');
      
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!mounted) return;
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<DiscordAuthService>();
      final notificationService = NotificationService();

      // Check if any notification is being enabled
      final anyEnabled = _ticketNewMessages || _ticketMentions || _ticketCreated || _ticketAssigned;

      // Request permission if not granted and user wants notifications
      if (anyEnabled && !notificationService.hasPermission) {
        debugPrint('📱 User enabling notifications, requesting permission...');
        
        final permissionGranted = await notificationService.requestPermissionAndRegister();
        
        if (!permissionGranted) {
          setState(() {
            _isSaving = false;
            _errorMessage = 'Notification permission denied. Please enable notifications in system settings.';
          });
          return;
        }

        // Register token with backend
        await notificationService.registerWithBackend(authService.apiService);
      }

      final settings = {
        'ticket_new_messages': _ticketNewMessages,
        'ticket_mentions': _ticketMentions,
        'ticket_created': _ticketCreated,
        'ticket_assigned': _ticketAssigned,
      };

      final success = await notificationService.updateNotificationSettings(
        authService.apiService,
        settings,
      );

      setState(() {
        _isSaving = false;
      });

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Notification settings saved'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to save notification settings';
        });
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Error saving settings: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [NotificationSettings] build() called - isLoading=$_isLoading, error=$_errorMessage');
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Use harmonized accent color for cards (same as tickets screen)
    final isMonet = colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? colorScheme.primaryContainer.withOpacity(0.18)
        : colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message
                  if (_errorMessage != null)
                    Card(
                      elevation: 0,
                      color: colorScheme.errorContainer,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  if (_errorMessage != null) const SizedBox(height: 8),

                  // Web warning card
                  if (kIsWeb)
                    Card(
                      elevation: 0,
                      color: colorScheme.secondaryContainer,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.web,
                              color: colorScheme.onSecondaryContainer,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Push notifications are only available on mobile devices (Android/iOS). '
                                'You can configure your preferences here, but you\'ll need the mobile app to receive notifications.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  if (kIsWeb) const SizedBox(height: 8),

                  // Info card
                  Card(
                    elevation: 0,
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Configure which ticket events send push notifications to your device.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Settings section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Ticket Notifications',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // New Messages
                  Card(
                    elevation: 0,
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: SwitchListTile(
                      value: _ticketNewMessages,
                      onChanged: (value) {
                        setState(() {
                          _ticketNewMessages = value;
                        });
                      },
                      title: const Text('New Messages'),
                      subtitle: Text(
                        _isAdmin || _isModerator
                            ? 'Get notified about new messages in your assigned/claimed tickets'
                            : 'Get notified about new messages in your tickets',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      secondary: Icon(
                        Icons.message_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),

                  // Mentions
                  Card(
                    elevation: 0,
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: SwitchListTile(
                      value: _ticketMentions,
                      onChanged: (value) {
                        setState(() {
                          _ticketMentions = value;
                        });
                      },
                      title: const Text('Mentions'),
                      subtitle: Text(
                        'Get notified when someone mentions you (@username) in a ticket',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      secondary: Icon(
                        Icons.alternate_email,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),

                  // New Tickets (Admin/Mod only)
                  if (_isAdmin || _isModerator)
                    Card(
                      elevation: 0,
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: SwitchListTile(
                        value: _ticketCreated,
                        onChanged: (value) {
                          setState(() {
                            _ticketCreated = value;
                          });
                        },
                        title: const Text('New Tickets'),
                        subtitle: Text(
                          'Get notified when a new ticket is created (Admin/Moderator only)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        secondary: Icon(
                          Icons.add_circle_outline,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),

                  // Assignments
                  Card(
                    elevation: 0,
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: SwitchListTile(
                      value: _ticketAssigned,
                      onChanged: (value) {
                        setState(() {
                          _ticketAssigned = value;
                        });
                      },
                      title: const Text('Ticket Assignments'),
                      subtitle: Text(
                        _isAdmin || _isModerator
                            ? 'Get notified when a ticket is assigned to you'
                            : 'Get notified about updates to your tickets',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      secondary: Icon(
                        Icons.assignment_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // FCM Token Info (Debug)
                  if (NotificationService().fcmToken != null)
                    Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerHighest,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.developer_mode,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Debug Info',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'FCM Token: ${NotificationService().fcmToken!.substring(0, 20)}...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
