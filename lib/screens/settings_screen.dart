import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/finance_provider.dart';
import '../services/backup_service.dart';
import '../widgets/bounce_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _newUserBuilder = TextEditingController();

  Future<void> _pickProfileImage(FinanceProvider finance) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      finance.setUserImage(finance.currentUser, result.files.single.path);
    }
  }

  Future<void> _handleExport(BuildContext context) async {
    final success = await BackupService.exportBackup();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Backup exported successfully!' : 'Failed to export backup.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleImport(BuildContext context, FinanceProvider finance) async {
    final success = await BackupService.importBackup();
    if (mounted) {
      if (success) {
        await finance.refreshAllData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup imported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to import backup.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: TextField(
          controller: _newUserBuilder,
          decoration: const InputDecoration(hintText: 'User Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          BounceButton(
            onTap: () {
              if (_newUserBuilder.text.isNotEmpty) {
                context.read<FinanceProvider>().addUser(_newUserBuilder.text);
                _newUserBuilder.clear();
                Navigator.pop(context);
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Add', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, finance, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('User Profiles'),
              Card(
                child: Column(
                  children: [
                    ...finance.users.map((user) => ListTile(
                          leading: BounceButton(
                            onTap: finance.currentUser == user ? () => _pickProfileImage(finance) : null,
                            child: CircleAvatar(
                              backgroundColor: finance.currentUser == user ? Colors.blue : Colors.grey.shade200,
                              backgroundImage: finance.userImages[user] != null
                                  ? FileImage(File(finance.userImages[user]!))
                                  : null,
                              child: finance.userImages[user] == null
                                  ? Icon(
                                      finance.currentUser == user ? Icons.add_a_photo : Icons.person,
                                      size: 18,
                                      color: finance.currentUser == user ? Colors.white : Colors.grey,
                                    )
                                  : null,
                            ),
                          ),
                          title: Text(user, style: TextStyle(fontWeight: finance.currentUser == user ? FontWeight.bold : FontWeight.normal)),
                          subtitle: finance.currentUser == user ? const Text('Tap icon to change image', style: TextStyle(fontSize: 10)) : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (finance.currentUser != user)
                                BounceButton(
                                  onTap: () => finance.removeUser(user),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Icons.delete, color: Colors.grey, size: 20),
                                  ),
                                ),
                              if (finance.currentUser != user)
                                BounceButton(
                                  onTap: () => finance.switchUser(user),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Icons.swap_horiz, color: Colors.blue),
                                  ),
                                )
                              else
                                const Icon(Icons.check_circle, color: Colors.green),
                            ],
                          ),
                        )),
                    const Divider(),
                    BounceButton(
                      onTap: _showAddUserDialog,
                      child: const ListTile(
                        leading: Icon(Icons.add, color: Colors.blue),
                        title: Text('Add New User', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Appearance'),
              Card(
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('System Default'),
                      value: ThemeMode.system,
                      groupValue: finance.themeMode,
                      onChanged: (val) => finance.setThemeMode(val!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light Mode'),
                      value: ThemeMode.light,
                      groupValue: finance.themeMode,
                      onChanged: (val) => finance.setThemeMode(val!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark Mode'),
                      value: ThemeMode.dark,
                      groupValue: finance.themeMode,
                      onChanged: (val) => finance.setThemeMode(val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Financial Preferences'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Start Day of Month', style: TextStyle(fontSize: 16)),
                          Text(
                            finance.startDayOfMonth.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This day will be considered the first day of the month for calculating savings.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: finance.startDayOfMonth.toDouble(),
                        min: 1,
                        max: 31,
                        divisions: 30,
                        onChanged: (val) => finance.setStartDayOfMonth(val.toInt()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Data Management'),
              Card(
                child: Column(
                  children: [
                    BounceButton(
                      onTap: () => _handleExport(context),
                      child: const ListTile(
                        leading: Icon(Icons.upload_file, color: Colors.blue),
                        title: Text('Export Backup'),
                        subtitle: Text('Save all data to a text file'),
                      ),
                    ),
                    const Divider(height: 1),
                    BounceButton(
                      onTap: () => _handleImport(context, finance),
                      child: const ListTile(
                        leading: Icon(Icons.download, color: Colors.orange),
                        title: Text('Import Backup'),
                        subtitle: Text('Restore data from a backup file'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700, letterSpacing: 1.2),
      ),
    );
  }
}
