import 'dart:convert';

class Note {
  final String id;
  final String userId;
  final String title;
  final String content;
  final bool isFavorite;
  final bool isPinned;
  final List<String> tags;
  final String? reminderTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.isFavorite = false,
    this.isPinned = false,
    this.tags = const [],
    this.reminderTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    List<String> tags = [];
    if (json['tags'] != null) {
      if (json['tags'] is String) {
        try {
          final decoded = jsonDecode(json['tags']);
          if (decoded is List) {
            tags = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      } else if (json['tags'] is List) {
        tags = (json['tags'] as List).map((e) => e.toString()).toList();
      }
    }

    return Note(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      isFavorite: json['is_favorite'] == 1 || json['is_favorite'] == true,
      isPinned: json['is_pinned'] == 1 || json['is_pinned'] == true,
      tags: tags,
      reminderTime: json['reminder_time'] != null && json['reminder_time'].toString().isNotEmpty
          ? json['reminder_time'].toString()
          : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'is_favorite': isFavorite ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'tags': jsonEncode(tags),
      'reminder_time': reminderTime ?? '',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Note copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    bool? isFavorite,
    bool? isPinned,
    List<String>? tags,
    String? reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayTitle {
    if (title.isNotEmpty) return title;
    if (content.isNotEmpty) {
      return content.length > 20 ? content.substring(0, 20) : content;
    }
    return '无标题';
  }

  String get preview {
    if (content.isEmpty) return '无内容';
    return content.length > 50 ? content.substring(0, 50) : content;
  }
}
