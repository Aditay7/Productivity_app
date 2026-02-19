import '../models/player.dart';
import '../models/quest.dart';
import '../models/quest_template.dart';

/// Model for complete app backup
class AppBackup {
  final Player player;
  final List<Quest> quests;
  final List<QuestTemplate> templates;
  final DateTime exportedAt;
  final int version;

  AppBackup({
    required this.player,
    required this.quests,
    required this.templates,
    required this.exportedAt,
    this.version = 1,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'exported_at': exportedAt.toIso8601String(),
      'player': player.toMap(),
      'quests': quests.map((q) => q.toMap()).toList(),
      'templates': templates.map((t) => t.toMap()).toList(),
    };
  }

  /// Create from JSON
  factory AppBackup.fromJson(Map<String, dynamic> json) {
    return AppBackup(
      version: json['version'] as int,
      exportedAt: DateTime.parse(json['exported_at'] as String),
      player: Player.fromMap(json['player'] as Map<String, dynamic>),
      quests: (json['quests'] as List)
          .map((q) => Quest.fromMap(q as Map<String, dynamic>))
          .toList(),
      templates: (json['templates'] as List)
          .map((t) => QuestTemplate.fromMap(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
