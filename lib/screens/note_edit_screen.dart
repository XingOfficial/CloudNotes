import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/local_data_service.dart';
import '../services/notification_service.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note;
  const NoteEditScreen({super.key, this.note});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _apiService = ApiService();
  final _undoController = UndoHistoryController();

  bool _isSaving = false;
  bool _isNewNote = true;
  DateTime? _createdAt;
  DateTime? _updatedAt;
  DateTime? _lastAutoSaveTime;

  bool _isFavorite = false;
  bool _isPinned = false;
  List<String> _tags = [];
  DateTime? _reminderTime;

  late double _fontSize;
  late int _maxChars;

  @override
  void initState() {
    super.initState();
    _apiService.setToken(StorageService.getToken());
    _fontSize = LocalDataService.getEditorFontSize();
    _maxChars = LocalDataService.getMaxChars();
    if (widget.note != null) {
      _isNewNote = false;
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _createdAt = widget.note!.createdAt;
      _updatedAt = widget.note!.updatedAt;
      _isFavorite = widget.note!.isFavorite;
      _isPinned = widget.note!.isPinned;
      _tags = List.from(widget.note!.tags);
      if (widget.note!.reminderTime != null) {
        _reminderTime = DateTime.tryParse(widget.note!.reminderTime!);
      }
    }
    _contentController.addListener(_onContentChanged);
    _titleController.addListener(_onContentChanged);
    _undoController.addListener(_onUndoStateChanged);
  }

  @override
  void dispose() {
    _undoController.removeListener(_onUndoStateChanged);
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _undoController.dispose();
    super.dispose();
  }

  void _onUndoStateChanged() {
    if (mounted) setState(() {});
  }

  int get _charCount => _titleController.text.length + _contentController.text.length;

  void _onContentChanged() {
    setState(() {}); // 刷新字数统计
    if (_isNewNote) return;
    final now = DateTime.now();
    if (_lastAutoSaveTime != null && now.difference(_lastAutoSaveTime!).inSeconds < 2) {
      return;
    }
    _lastAutoSaveTime = now;
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isNewNote && _lastAutoSaveTime == now) {
        _autoSave();
      }
    });
  }

  Future<void> _autoSave() async {
    if (_isNewNote || _isSaving) return;
    try {
      final updated = await _apiService.updateNote(
        widget.note!.id,
        title: _titleController.text,
        content: _contentController.text,
        isFavorite: _isFavorite,
        isPinned: _isPinned,
        tags: _tags,
        reminderTime: _reminderTime?.toIso8601String(),
      );
      setState(() {
        _updatedAt = updated.updatedAt;
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text;
    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('标题和内容不能同时为空')));
      return;
    }
    if (_charCount > _maxChars) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('内容超出字数上限（$_maxChars 字），请精简后再保存')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (_isNewNote) {
        final note = await _apiService.createNote(
          title,
          content,
          isFavorite: _isFavorite,
          isPinned: _isPinned,
          tags: _tags,
          reminderTime: _reminderTime?.toIso8601String(),
        );
        _createdAt = note.createdAt;
        _updatedAt = note.updatedAt;
        _isNewNote = false;
        _scheduleReminder(note.id, title, content);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('创建成功')));
      } else {
        final updated = await _apiService.updateNote(
          widget.note!.id,
          title: title,
          content: content,
          isFavorite: _isFavorite,
          isPinned: _isPinned,
          tags: _tags,
          reminderTime: _reminderTime?.toIso8601String(),
        );
        _updatedAt = updated.updatedAt;
        _scheduleReminder(widget.note!.id, title, content);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _scheduleReminder(String noteId, String title, String content) {
    final id = NotificationService.generateId(noteId);
    NotificationService.cancelReminder(id);
    if (_reminderTime != null && _reminderTime!.isAfter(DateTime.now())) {
      NotificationService.scheduleReminder(
        id: id,
        title: title.isEmpty ? '笔记提醒' : title,
        body: content.length > 50 ? content.substring(0, 50) : content,
        scheduledTime: _reminderTime!,
      );
    }
  }

  Future<void> _exportMarkdown() async {
    final title = _titleController.text.trim().isEmpty ? '无标题' : _titleController.text.trim();
    final content = _contentController.text;
    final markdown = '# $title\n\n$content\n';
    try {
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/${title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.md');
      await file.writeAsString(markdown);
      await Share.shareXFiles([XFile(file.path)], text: '导出笔记：$title');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导出失败')));
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) return;
    if (!_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
    _tagController.clear();
  }

  Future<void> _pickReminderTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderTime ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderTime ?? now),
    );
    if (time == null) return;
    setState(() {
      _reminderTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final overLimit = _charCount > _maxChars;
    final nearLimit = !overLimit && _charCount >= _maxChars * 0.9;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewNote ? '新建笔记' : '编辑笔记'),
        actions: [
          if (!_isNewNote) ...[
            IconButton(
              icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
              onPressed: () => setState(() => _isFavorite = !_isFavorite),
              tooltip: _isFavorite ? '取消收藏' : '收藏',
            ),
            IconButton(
              icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: () => setState(() => _isPinned = !_isPinned),
              tooltip: _isPinned ? '取消置顶' : '置顶',
            ),
            IconButton(
              onPressed: _exportMarkdown,
              icon: const Icon(Icons.ios_share),
              tooltip: '导出 Markdown',
            ),
          ],
          IconButton(
            onPressed: _undoController.value.canUndo ? _undoController.undo : null,
            icon: const Icon(Icons.undo),
            tooltip: '撤销',
            color: _undoController.value.canUndo ? null : Colors.grey,
          ),
          IconButton(
            onPressed: _undoController.value.canRedo ? _undoController.redo : null,
            icon: const Icon(Icons.redo),
            tooltip: '重做',
            color: _undoController.value.canRedo ? null : Colors.grey,
          ),
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('保存', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: '笔记标题',
                    child: TextField(
                      controller: _titleController,
                      undoController: _undoController,
                      style: TextStyle(fontSize: _fontSize + 6, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: '标题',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const Divider(),
                  Semantics(
                    label: '笔记内容',
                    child: TextField(
                      controller: _contentController,
                      undoController: _undoController,
                      maxLines: null,
                      style: TextStyle(fontSize: _fontSize, height: 1.6),
                      decoration: const InputDecoration(
                        hintText: '开始记录...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  if (nearLimit || overLimit) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          overLimit ? Icons.error_outline : Icons.info_outline,
                          size: 16,
                          color: overLimit ? Colors.red : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            overLimit ? '已超出字数上限，无法保存' : '即将达到字数上限',
                            style: TextStyle(
                              fontSize: 12,
                              color: overLimit ? Colors.red : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!_isNewNote) ...[
                    const SizedBox(height: 16),
                    const Text('标签', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._tags.map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                        )),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: const Text('添加标签'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => AlertDialog(
                                title: const Text('添加标签'),
                                content: TextField(
                                  controller: _tagController,
                                  autofocus: true,
                                  decoration: const InputDecoration(hintText: '输入标签名称'),
                                  onSubmitted: (_) {
                                    _addTag();
                                    Navigator.pop(ctx);
                                  },
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                                  TextButton(
                                    onPressed: () {
                                      _addTag();
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('添加'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('提醒', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.alarm),
                      title: Text(_reminderTime == null
                          ? '未设置提醒'
                          : DateFormat('yyyy-MM-dd HH:mm').format(_reminderTime!)),
                      trailing: _reminderTime != null
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _reminderTime = null),
                            )
                          : null,
                      onTap: _pickReminderTime,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _updatedAt != null
                      ? '更新于 ${DateFormat('yyyy-MM-dd HH:mm').format(_updatedAt!)}'
                      : _createdAt != null
                          ? '创建于 ${DateFormat('yyyy-MM-dd HH:mm').format(_createdAt!)}'
                          : '未保存',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  '$_charCount / $_maxChars 字',
                  style: TextStyle(
                    color: overLimit ? Colors.red : (nearLimit ? Colors.orange : Colors.grey),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
