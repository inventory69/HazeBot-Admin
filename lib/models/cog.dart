import 'package:flutter/material.dart';

enum CogStatus {
  loaded,
  unloaded,
  disabled,
  error,
}

enum CogAction {
  load,
  unload,
  reload,
}

class Cog {
  final String name;
  final String? description;
  final String? icon;
  final String? category;
  final List<String> features;
  final CogStatus status;
  final bool canLoad;
  final bool canUnload;
  final bool canReload;
  final String? errorMessage;

  const Cog({
    required this.name,
    this.description,
    this.icon,
    this.category,
    this.features = const [],
    required this.status,
    this.canLoad = false,
    this.canUnload = false,
    this.canReload = false,
    this.errorMessage,
  });

  factory Cog.fromJson(Map<String, dynamic> json) {
    return Cog(
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      category: json['category'] as String?,
      features: (json['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: _parseStatus(json['status'] as String),
      canLoad: json['can_load'] as bool? ?? false,
      canUnload: json['can_unload'] as bool? ?? false,
      canReload: json['can_reload'] as bool? ?? false,
      errorMessage: json['error_message'] as String?,
    );
  }

  static CogStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'loaded':
        return CogStatus.loaded;
      case 'unloaded':
        return CogStatus.unloaded;
      case 'disabled':
        return CogStatus.disabled;
      case 'error':
        return CogStatus.error;
      default:
        return CogStatus.unloaded;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'features': features,
      'status': status.name,
      'can_load': canLoad,
      'can_unload': canUnload,
      'can_reload': canReload,
      'error_message': errorMessage,
    };
  }

  // Helper to get Material Icon from icon name
  IconData get materialIcon {
    switch (icon) {
      case 'api':
        return Icons.api;
      case 'settings':
        return Icons.settings;
      case 'update':
        return Icons.update;
      case 'image':
        return Icons.image;
      case 'analytics':
        return Icons.analytics;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'leaderboard':
        return Icons.leaderboard;
      case 'create':
        return Icons.create;
      case 'shield':
        return Icons.shield;
      case 'tune':
        return Icons.tune;
      case 'visibility':
        return Icons.visibility;
      case 'person':
        return Icons.person;
      case 'rocket_launch':
        return Icons.rocket_launch;
      case 'badge':
        return Icons.badge;
      case 'menu_book':
        return Icons.menu_book;
      case 'support_agent':
        return Icons.support_agent;
      case 'confirmation_number':
        return Icons.confirmation_number;
      case 'checklist':
        return Icons.checklist;
      case 'build':
        return Icons.build;
      case 'videogame_asset':
        return Icons.videogame_asset;
      case 'waving_hand':
        return Icons.waving_hand;
      default:
        return Icons.extension;
    }
  }

  // Helper to get category color
  Color getCategoryColor() {
    switch (category) {
      case 'core':
        return Colors.purple;
      case 'community':
        return Colors.blue;
      case 'content':
        return Colors.orange;
      case 'gaming':
        return Colors.red;
      case 'moderation':
        return Colors.amber;
      case 'support':
        return Colors.green;
      case 'user':
        return Colors.teal;
      case 'info':
        return Colors.cyan;
      case 'productivity':
        return Colors.indigo;
      case 'utility':
        return Colors.blueGrey;
      case 'notifications':
        return Colors.pink;
      case 'monitoring':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  // Helper to get category display name
  String get categoryDisplay {
    return category
            ?.replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
            .join(' ') ??
        'Other';
  }
}

class CogLog {
  final String timestamp;
  final String level;
  final String message;

  const CogLog({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  factory CogLog.fromJson(Map<String, dynamic> json) {
    return CogLog(
      timestamp: json['timestamp'] as String,
      level: json['level'] as String,
      message: json['message'] as String,
    );
  }
}
