import 'package:flutter/material.dart';
import '../main.dart';
import '../services/local_data_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = LocalDataService.isDarkMode();
  }

  Future<void> _toggleDarkMode(bool value) async {
    await LocalDataService.setDarkMode(value);
    setState(() => _isDarkMode = value);
    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('开启后应用使用深色主题'),
            secondary: const Icon(Icons.dark_mode),
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('云笔记 v1.0.2'),
            onTap: () {
              Navigator.pushNamed(context, '/about');
            },
          ),
        ],
      ),
    );
  }
}
