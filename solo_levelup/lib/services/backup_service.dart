import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/backup_model.dart';
import '../data/repositories/player_repository.dart';
import '../data/repositories/quest_repository.dart';
import '../data/repositories/quest_template_repository.dart';

/// Service for backing up and restoring app data
class BackupService {
  final PlayerRepository _playerRepo;
  final QuestRepository _questRepo;
  final QuestTemplateRepository _templateRepo;

  BackupService(this._playerRepo, this._questRepo, this._templateRepo);

  /// Export all data to JSON
  Future<AppBackup> createBackup() async {
    final player = await _playerRepo.getPlayer();
    final quests = await _questRepo.getAllQuests();
    final templates = await _templateRepo.getAllTemplates();

    return AppBackup(
      player: player,
      quests: quests,
      templates: templates,
      exportedAt: DateTime.now(),
    );
  }

  /// Convert backup to JSON string
  String backupToJson(AppBackup backup) {
    return jsonEncode(backup.toJson());
  }

  /// Parse JSON string to backup
  AppBackup jsonToBackup(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return AppBackup.fromJson(json);
  }

  /// Save backup to file and share
  Future<void> exportToFile() async {
    final backup = await createBackup();
    final jsonString = backupToJson(backup);

    // Get temporary directory
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/solo_levelup_backup_$timestamp.json');

    // Write to file
    await file.writeAsString(jsonString);

    // Share file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Solo Level Up Backup',
      text: 'Backup created on ${DateTime.now()}',
    );
  }

  /// Import backup from JSON string
  Future<void> importFromJson(String jsonString) async {
    final backup = jsonToBackup(jsonString);

    // Clear existing data (optional - could merge instead)
    // For now, we'll just import without clearing

    // Import player
    await _playerRepo.updatePlayer(backup.player);

    // Import quests
    for (final quest in backup.quests) {
      await _questRepo.createQuest(quest);
    }

    // Import templates
    for (final template in backup.templates) {
      await _templateRepo.createTemplate(template);
    }
  }

  /// Import from file
  Future<void> importFromFile(File file) async {
    final jsonString = await file.readAsString();
    await importFromJson(jsonString);
  }

  /// Get backup file size estimate
  Future<int> getBackupSize() async {
    final backup = await createBackup();
    final jsonString = backupToJson(backup);
    return jsonString.length;
  }
}
