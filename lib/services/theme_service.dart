import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _dynamicColorKey = 'use_dynamic_color';
  bool _useDynamicColor = false;

  bool get useDynamicColor => _useDynamicColor;

  ThemeService() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _useDynamicColor = prefs.getBool(_dynamicColorKey) ?? false;
    notifyListeners();
  }

  Future<void> setDynamicColor(bool value) async {
    _useDynamicColor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dynamicColorKey, value);
    notifyListeners();
  }
}
