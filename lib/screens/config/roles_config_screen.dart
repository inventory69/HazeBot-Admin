import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RolesConfigScreen extends StatefulWidget {
  const RolesConfigScreen({super.key});

  @override
  State<RolesConfigScreen> createState() => _RolesConfigScreenState();
}

class _RolesConfigScreenState extends State<RolesConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Role selections
  String? _adminRoleId;
  String? _moderatorRoleId;
  String? _normalRoleId;
  String? _memberRoleId;
  String? _changelogRoleId;
  String? _memeRoleId;

  // Available roles
  List<Map<String, dynamic>> _roles = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadGuildData();
    await _loadConfig();
  }

  Future<void> _loadGuildData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final roles = await authService.apiService.getGuildRoles();

      if (mounted) {
        setState(() {
          _roles = roles;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading guild data: $e')),
        );
      }
    }
  }

  Future<void> _loadConfig() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final config = await authService.apiService.getRolesConfig();

      if (mounted) {
        setState(() {
          _adminRoleId = config['admin_role_id']?.toString();
          _moderatorRoleId = config['moderator_role_id']?.toString();
          _normalRoleId = config['normal_role_id']?.toString();
          _memberRoleId = config['member_role_id']?.toString();
          _changelogRoleId = config['changelog_role_id']?.toString();
          _memeRoleId = config['meme_role_id']?.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading configuration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final config = {
        'admin_role_id': _adminRoleId != null ? int.parse(_adminRoleId!) : null,
        'moderator_role_id':
            _moderatorRoleId != null ? int.parse(_moderatorRoleId!) : null,
        'normal_role_id':
            _normalRoleId != null ? int.parse(_normalRoleId!) : null,
        'member_role_id':
            _memberRoleId != null ? int.parse(_memberRoleId!) : null,
        'changelog_role_id':
            _changelogRoleId != null ? int.parse(_changelogRoleId!) : null,
        'meme_role_id': _memeRoleId != null ? int.parse(_memeRoleId!) : null,
      };

      await authService.apiService.updateRolesConfig(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving configuration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will reset all role settings to their default values. '
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.resetRolesConfig();
      await _loadConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration reset to defaults'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting configuration: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildRoleDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    required String hint,
    IconData? icon,
    bool required = false,
    bool isMobile = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: isMobile ? 14 : null),
        hintText: hint,
        hintStyle: TextStyle(fontSize: isMobile ? 12 : null),
        border: const OutlineInputBorder(),
        prefixIcon:
            icon != null ? Icon(icon, size: isMobile ? 20 : null) : null,
        isDense: isMobile,
      ),
      items: [
        if (!required)
          const DropdownMenuItem<String>(
            value: null,
            child: Text('None'),
          ),
        ..._roles.map((role) {
          return DropdownMenuItem<String>(
            value: role['id'],
            child: Text('@${role['name']}'),
          );
        }),
      ],
      onChanged: onChanged,
      validator: required
          ? (value) => value == null ? 'This field is required' : null
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _roles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 12.0 : 24.0;
        final cardPadding = isMobile ? 12.0 : 16.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Roles Configuration',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: isMobile ? 24 : null,
                      ),
                ),
                SizedBox(height: isMobile ? 4 : 8),
                Text(
                  'Configure Discord roles for bot permissions and features',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 13 : null,
                      ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Info Box
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: isMobile ? 18 : 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Permission roles control access to bot commands. All permission roles are required.',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // Permission Roles
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security,
                                color: Colors.red, size: isMobile ? 20 : 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Permission Roles',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildRoleDropdown(
                          label: 'Admin Role',
                          value: _adminRoleId,
                          onChanged: (value) =>
                              setState(() => _adminRoleId = value),
                          hint: 'Full bot administration access',
                          icon: Icons.admin_panel_settings,
                          required: true,
                          isMobile: isMobile,
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildRoleDropdown(
                          label: 'Moderator Role',
                          value: _moderatorRoleId,
                          onChanged: (value) =>
                              setState(() => _moderatorRoleId = value),
                          hint: 'Moderation commands access',
                          icon: Icons.shield,
                          required: true,
                          isMobile: isMobile,
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildRoleDropdown(
                          label: 'Normal Role',
                          value: _normalRoleId,
                          onChanged: (value) =>
                              setState(() => _normalRoleId = value),
                          hint: 'Default user role',
                          icon: Icons.person,
                          required: true,
                          isMobile: isMobile,
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildRoleDropdown(
                          label: 'Member Role',
                          value: _memberRoleId,
                          onChanged: (value) =>
                              setState(() => _memberRoleId = value),
                          hint: 'Verified member role',
                          icon: Icons.verified_user,
                          required: true,
                          isMobile: isMobile,
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: isMobile ? 18 : 20,
                                  color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Admin > Moderator > Member > Normal hierarchy. Higher roles inherit lower permissions.',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),

                // Feature Roles
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notifications_active,
                                color: Colors.purple, size: isMobile ? 20 : 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Feature Roles',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: isMobile ? 18 : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildRoleDropdown(
                          label: 'Changelog Role',
                          value: _changelogRoleId,
                          onChanged: (value) =>
                              setState(() => _changelogRoleId = value),
                          hint: 'Pinged for bot updates',
                          icon: Icons.update,
                          isMobile: isMobile,
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildRoleDropdown(
                          label: 'Meme Role',
                          value: _memeRoleId,
                          onChanged: (value) =>
                              setState(() => _memeRoleId = value),
                          hint: 'Pinged for daily memes',
                          icon: Icons.image,
                          isMobile: isMobile,
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: isMobile ? 18 : 20,
                                  color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Feature roles are optional and used for notifications and mentions.',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Action Buttons
                if (isMobile)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _resetToDefaults,
                          icon: const Icon(Icons.restore, size: 20),
                          label: const Text('Reset to Defaults',
                              style: TextStyle(fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveConfig,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save, size: 20),
                          label: const Text('Save Configuration',
                              style: TextStyle(fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _resetToDefaults,
                          icon: const Icon(Icons.restore),
                          label: const Text('Reset to Defaults'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveConfig,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Save Configuration'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
