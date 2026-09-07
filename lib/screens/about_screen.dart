import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _apiService = ApiService();
  bool _isChecking = false;
  String _updateStatus = '点击按钮检查是否有新版本';

  static const String repoUrl = 'https://github.com/XingOfficial/CloudNotes';
  static const String currentVersion = '1.0.2';

  Future<void> _openRepo() async {
    final uri = Uri.parse(repoUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法打开浏览器，请手动访问 GitHub')));
    }
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _isChecking = true;
      _updateStatus = '正在检查更新...';
    });
    try {
      final release = await _apiService.checkUpdate();
      if (release == null) {
        setState(() => _updateStatus = '检查失败，请稍后重试');
        return;
      }
      final tagName = release['tag_name'] ?? '';
      final latestVersion = tagName.replaceFirst('v', '');
      final releaseName = release['name'] ?? tagName;
      final releaseNotes = release['body'] ?? '';
      final htmlUrl = release['html_url'] ?? repoUrl;

      if (_isNewerVersion(latestVersion, currentVersion)) {
        setState(() => _updateStatus = '发现新版本：$latestVersion');
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('发现新版本'),
            content: Text('最新版本：$releaseName\n\n${releaseNotes.isNotEmpty ? '更新说明：\n$releaseNotes' : ''}'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('稍后再说')),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse(htmlUrl);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
                child: const Text('去下载'),
              ),
            ],
          ),
        );
      } else {
        setState(() => _updateStatus = '已是最新版本');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('当前已是最新版本')));
      }
    } catch (e) {
      setState(() => _updateStatus = '检查失败：${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();
      final maxLen = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;
      for (var i = 0; i < maxLen; i++) {
        final l = i < latestParts.length ? latestParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (_) {
      return latest != current;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.note, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                const Text('云笔记', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('版本 $currentVersion', style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('开源项目', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('本应用完全开源，欢迎 Star 支持', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openRepo,
                      icon: const Icon(Icons.star),
                      label: const Text('给仓库点 Star'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('检查更新', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_updateStatus, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isChecking ? null : _checkUpdate,
                      child: _isChecking
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('检查更新'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('反馈与交流', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('QQ 群：677010442', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
