import 'package:flutter/foundation.dart';

class PermissionService extends ChangeNotifier {
  String _role = 'lootling';
  List<String> _permissions = [];

  String get role => _role;
  List<String> get permissions => _permissions;

  void updatePermissions(String? role, List<String>? permissions) {
    _role = role ?? 'lootling';
    _permissions = permissions ?? [];
    notifyListeners();
  }

  bool hasPermission(String permission) {
    if (_permissions.contains('all')) {
      return true;
    }
    return _permissions.contains(permission);
  }

  bool get isAdmin => _role == 'admin';
  bool get isMod => _role == 'mod';
  bool get isLootling => _role == 'lootling';

  bool get canAccessAll => hasPermission('all');
  bool get canAccessMemeGenerator => hasPermission('meme_generator');

  void clear() {
    _role = 'lootling';
    _permissions = [];
    notifyListeners();
  }
}
