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
      final bytes = utf8.encode(jsonString);
      
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
          bytes: bytes,
        );
      }

      if (outputPath != null) {
        debugPrint('Backup save location: $outputPath');
        
        // On Android, outputPath might be a Content URI (content://...)
        // In that case, the 'bytes' parameter in saveFile should have already handled the write.
        // We only attempt manual write if it's a regular file path and doesn't exist.
        if (!outputPath.startsWith('content://')) {
          final file = File(outputPath);
          if (!await file.exists()) {
            await file.writeAsBytes(bytes);
            debugPrint('Manual backup write successful.');
          }
        } else {
          debugPrint('Content URI detected, assuming bytes were saved by plugin.');
        }
        return true;
      }
      debugPrint('Backup export cancelled or failed (no path returned).');
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
