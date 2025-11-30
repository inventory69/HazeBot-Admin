import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/discord_auth_service.dart';
import '../services/permission_service.dart';
import '../utils/web_utils.dart';
import '../utils/app_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isDiscordLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Check for token in URL (after OAuth redirect)
    if (kIsWeb) {
      // Use WidgetsBinding to ensure we're checking after the frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForTokenInUrl();
      });
    }
  }

  Future<void> _checkForTokenInUrl() async {
    try {
      // Get current URL using platform-specific implementation
      final currentUrl = WebUtils.getCurrentUrl();
      if (currentUrl.isEmpty) return; // Non-web platform

      final uri = Uri.parse(currentUrl);

      print('DEBUG: Full URL: $currentUrl');
      print('DEBUG: Uri.base: ${Uri.base}');
      print('DEBUG: Parsed URI: ${uri.toString()}');
      print('DEBUG: Query params: ${uri.queryParameters}');

      // Check for token (from backend redirect after OAuth)
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        print('DEBUG: Found token in URL: ${token.substring(0, 20)}...');

        final discordAuthService =
            Provider.of<DiscordAuthService>(context, listen: false);
        final permissionService =
            Provider.of<PermissionService>(context, listen: false);

        try {
          print('DEBUG: Calling handleTokenFromUrl with token...');
          final success = await discordAuthService.handleTokenFromUrl(token);
          print('DEBUG: handleTokenFromUrl returned: $success');

          if (success && discordAuthService.userInfo != null) {
            print(
                'DEBUG: Token handled successfully, userInfo: ${discordAuthService.userInfo}');

            // Update permission service
            permissionService.updatePermissions(
              discordAuthService.role,
              discordAuthService.permissions,
            );
            print('DEBUG: Permissions updated');

            // Clean URL (remove token from URL bar)
            WebUtils.replaceUrl(uri.replace(queryParameters: {}).toString());
            print('DEBUG: URL cleaned');

            if (mounted) {
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Discord login successful! Welcome ${discordAuthService.userInfo?['username']}'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );

              // Force navigation check (main.dart should redirect to home)
              print('DEBUG: Login complete, should navigate to home now');
            }
          } else {
            if (mounted) {
              setState(() {
                _errorMessage = 'Discord login failed. Please try again.';
              });
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Discord login error: $e';
            });
          }
        }
        return;
      }

      // Check for OAuth code (from Discord redirect - fallback)
      final code = uri.queryParameters['code'];
      print('DEBUG: Code from URL: $code');
      if (code != null && code.isNotEmpty) {
        print('DEBUG: Found OAuth code in URL: $code');
        // This shouldn't happen anymore since backend redirects with token
        if (mounted) {
          setState(() {
            _errorMessage = 'Unexpected OAuth flow. Please try again.';
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Error checking for token in URL: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error processing login: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final permissionService =
        Provider.of<PermissionService>(context, listen: false);

    final success = await authService.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Legacy login has full permissions
      permissionService.updatePermissions('admin', ['all']);
    } else {
      setState(() {
        _errorMessage = 'Invalid username or password';
      });
    }
  }

  Future<void> _loginWithDiscord() async {
    setState(() {
      _isDiscordLoading = true;
      _errorMessage = null;
    });

    try {
      final discordAuthService =
          Provider.of<DiscordAuthService>(context, listen: false);

      // Get the auth URL
      final authUrl = await discordAuthService.getDiscordAuthUrl();

      if (authUrl == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to get Discord auth URL';
            _isDiscordLoading = false;
          });
        }
        return;
      }

      // Open in same tab/window on web, or launch browser on mobile
      if (kIsWeb) {
        WebUtils.navigateToUrl(authUrl);
      } else {
        // On mobile, use the standard OAuth flow with external browser
        await discordAuthService.initiateDiscordLogin();
        setState(() {
          _isDiscordLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isDiscordLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Monet/normal mode card color logic (match other screens)
    final isMonet = Theme.of(context).colorScheme.surfaceContainerHigh !=
        ThemeData.light().colorScheme.surfaceContainerHigh;
    final cardColor = isMonet
        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              color: cardColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppConfig.appName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Configuration Interface',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person),
                          ),
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                          enabled: !_isLoading,
                          onFieldSubmitted: (_) => _login(),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style:
                                        TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Login'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed:
                              _isDiscordLoading ? null : _loginWithDiscord,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: const Color(0xFF5865F2),
                              width: 2,
                            ),
                          ),
                          icon: _isDiscordLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  Icons.chat_bubble,
                                  color: const Color(0xFF5865F2),
                                ),
                          label: Text(
                            'Login with Discord',
                            style: TextStyle(
                              color: const Color(0xFF5865F2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Discord login grants role-based access',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
