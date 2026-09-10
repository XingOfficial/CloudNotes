import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/local_data_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;
  late double _fontSize;
  late int _maxChars;
  late bool _hasPin;

  @override
  void initState() {
    super.initState();
    _isDarkMode = LocalDataService.isDarkMode();
    _fontSize = LocalDataService.getEditorFontSize();
    _maxChars = LocalDataService.getMaxChars();
    _hasPin = LocalDataService.hasPin();
  }

  Future<void> _toggleDarkMode(bool value) async {
    await LocalDataService.setDarkMode(value);
    setState(() => _isDarkMode = value);
    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _changeFontSize(double value) async {
    setState(() => _fontSize = value);
    await LocalDataService.setEditorFontSize(value);
  }

  Future<void> _changeMaxChars(int value) async {
    setState(() => _maxChars = value);
    await LocalDataService.setMaxChars(value);
  }

  void _showMaxCharsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('字数上限'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('设置单篇笔记的最大字数，超出后将无法保存', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<int>(
                  value: _maxChars,
                  items: [2000, 5000, 10000, 20000, 50000].map((v) {
                    return DropdownMenuItem(value: v, child: Text('$v 字'));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) _changeMaxChars(v);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定')),
        ],
      ),
    );
  }

  Future<void> _setupPin() async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PinSetupDialog(hasPin: _hasPin),
    );
    if (pin != null) {
      if (pin.isEmpty) {
        // 关闭应用锁
        await LocalDataService.clearPin();
        setState(() => _hasPin = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('应用锁已关闭')));
        }
      } else {
        await LocalDataService.setPin(pin);
        setState(() => _hasPin = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('应用锁已开启，下次启动应用时生效')));
        }
      }
    }
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
            leading: const Icon(Icons.format_size),
            title: const Text('编辑字体大小'),
            subtitle: Text('当前 ${_fontSize.round()} 号'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Semantics(
              label: '编辑字体大小调节滑块',
              child: Slider(
                value: _fontSize,
                min: 12,
                max: 28,
                divisions: 16,
                label: '${_fontSize.round()}',
                onChanged: _changeFontSize,
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('单篇字数上限'),
            subtitle: Text('当前上限 $_maxChars 字，超出后无法保存'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showMaxCharsDialog,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('应用锁'),
            subtitle: Text(_hasPin ? '已开启，启动应用时需要输入密码' : '开启后启动应用需输入密码，保护笔记隐私'),
            secondary: const Icon(Icons.lock_outline),
            value: _hasPin,
            onChanged: (_) => _setupPin(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('云笔记 v1.0.3'),
            onTap: () {
              Navigator.pushNamed(context, '/about');
            },
          ),
        ],
      ),
    );
  }
}

class _PinSetupDialog extends StatefulWidget {
  final bool hasPin;
  const _PinSetupDialog({required this.hasPin});

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();
    if (pin.length < 4) {
      setState(() => _error = '密码至少 4 位数字');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = '两次输入的密码不一致');
      return;
    }
    Navigator.pop(context, pin);
  }

  void _disable() {
    Navigator.pop(context, '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.hasPin ? '修改应用锁密码' : '设置应用锁密码'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '输入 4~6 位数字密码',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '再次输入密码',
              counterText: '',
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
        ],
      ),
      actions: [
        if (widget.hasPin)
          TextButton(
            onPressed: _disable,
            child: const Text('关闭应用锁', style: TextStyle(color: Colors.red)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(onPressed: _submit, child: const Text('确定')),
      ],
    );
  }
}
