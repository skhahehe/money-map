import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static Future<bool> exportBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final Map<String, dynamic> backupData = {};

      for (final key in allKeys) {
        backupData[key] = prefs.get(key);
      }

      final jsonString = jsonEncode(backupData);
      
      String? outputPath;
      if (kIsWeb) {
        // Handle web if necessary, but file_picker handles it differently
        return false;
      } else {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup',
          fileName: 'money_tracker_backup_${DateTime.now().millisecondsSinceEpoch}.txt',
          type: FileType.custom,
          allowedExtensions: ['txt', 'json'],
        );
      }

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(jsonString);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error exporting backup: $e');
      return false;
    }
  }

  static Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> backupData = jsonDecode(jsonString);

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        for (final entry in backupData.entries) {
          final value = entry.value;
          if (value is String) {
            await prefs.setString(entry.key, value);
          } else if (value is int) {
            await prefs.setInt(entry.key, value);
          } else if (value is bool) {
            await prefs.setBool(entry.key, value);
          } else if (value is double) {
            await prefs.setDouble(entry.key, value);
          } else if (value is List) {
            await prefs.setStringList(entry.key, value.map((e) => e.toString()).toList());
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error importing backup: $e');
      return false;
    }
  }
}
