import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';
import 'note_edit_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';

enum SortMode { updatedDesc, updatedAsc, createdDesc, titleAsc }

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();

  List<Note> _allNotes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  SortMode _sortMode = SortMode.updatedDesc;
  AppUser? _user;

  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

  String? _filterTag;
  bool _showFavoritesOnly = false;
  List<String> _allTags = [];

  @override
  void initState() {
    super.initState();
    _user = StorageService.getUser();
    _apiService.setToken(StorageService.getToken());
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await _apiService.getNotes(
        onlyFavorite: _showFavoritesOnly,
        tag: _filterTag,
      );
      _allNotes = notes;
      _allTags = await _apiService.getTags();
      _applyFilterAndSort();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilterAndSort() {
    final query = _searchController.text.toLowerCase();
    var notes = _allNotes.where((note) {
      if (query.isNotEmpty) {
        final matchQuery = note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query);
        if (!matchQuery) return false;
      }
      return true;
    }).toList();

    switch (_sortMode) {
      case SortMode.updatedDesc:
        notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortMode.updatedAsc:
        notes.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case SortMode.createdDesc:
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortMode.titleAsc:
        notes.sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
        break;
    }

    // 置顶优先（仅在默认排序时）
    if (_sortMode == SortMode.updatedDesc) {
      final pinned = notes.where((n) => n.isPinned).toList();
      final unpinned = notes.where((n) => !n.isPinned).toList();
      notes = [...pinned, ...unpinned];
    }

    _filteredNotes = notes;
    setState(() {});
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除笔记「${note.displayTitle}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _apiService.deleteNote(note.id);
      _allNotes.removeWhere((n) => n.id == note.id);
      _applyFilterAndSort();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除成功')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _shareNote(Note note) {
    final text = '${note.title}\n\n${note.content}';
    Share.share(text, subject: note.title);
  }

  Future<void> _duplicateNote(Note note) async {
    try {
      final newNote = await _apiService.duplicateNote(note.id);
      _allNotes.add(newNote);
      _applyFilterAndSort();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制笔记')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Note note) async {
    try {
      final updated = await _apiService.toggleFavorite(note.id);
      final index = _allNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _allNotes[index] = updated;
        _applyFilterAndSort();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _togglePinned(Note note) async {
    try {
      final updated = await _apiService.togglePinned(note.id);
      final index = _allNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _allNotes[index] = updated;
        _applyFilterAndSort();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('排序方式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SortMode.values.map((mode) {
            final labels = {
              SortMode.updatedDesc: '按更新时间（新→旧）',
              SortMode.updatedAsc: '按更新时间（旧→新）',
              SortMode.createdDesc: '按创建时间（新→旧）',
              SortMode.titleAsc: '按标题（A→Z）',
            };
            return RadioListTile<SortMode>(
              title: Text(labels[mode]!),
              value: mode,
              groupValue: _sortMode,
              onChanged: (v) {
                if (v != null) {
                  _sortMode = v;
                  _applyFilterAndSort();
                }
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('筛选'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  title: const Text('仅显示收藏'),
                  value: _showFavoritesOnly,
                  onChanged: (v) {
                    setDialogState(() => _showFavoritesOnly = v ?? false);
                  },
                ),
                const Divider(),
                const Text('按标签筛选：', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_allTags.isEmpty)
                  const Text('暂无标签', style: TextStyle(color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('全部'),
                        selected: _filterTag == null,
                        onSelected: (_) => setDialogState(() => _filterTag = null),
                      ),
                      ..._allTags.map((tag) => ChoiceChip(
                            label: Text(tag),
                            selected: _filterTag == tag,
                            onSelected: (_) => setDialogState(() => _filterTag = tag),
                          )),
                    ],
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _loadNotes();
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 ${_selectedIds.length} 篇笔记吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      for (final id in _selectedIds) {
        await _apiService.deleteNote(id);
      }
      _allNotes.removeWhere((n) => _selectedIds.contains(n.id));
      _selectedIds.clear();
      _isSelectMode = false;
      _applyFilterAndSort();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('批量删除成功')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _batchShare() {
    if (_selectedIds.isEmpty) return;
    final selectedNotes = _allNotes.where((n) => _selectedIds.contains(n.id)).toList();
    final text = selectedNotes.map((n) => '【${n.title}】\n${n.content}').join('\n\n---\n\n');
    Share.share(text, subject: '批量分享笔记');
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('退出')),
        ],
      ),
    );
    if (confirmed != true) return;
    await StorageService.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectMode ? '已选 ${_selectedIds.length} 篇' : '云笔记'),
        leading: _isSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectMode,
                tooltip: '取消选择',
              )
            : null,
        actions: [
          if (_isSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _selectedIds.isNotEmpty ? _batchShare : null,
              tooltip: '批量分享',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _selectedIds.isNotEmpty ? _batchDelete : null,
              tooltip: '批量删除',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: '筛选',
            ),
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectMode,
              tooltip: '批量操作',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              tooltip: '设置',
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
              child: const Text('关于', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: _logout,
              child: const Text('退出', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: '搜索笔记',
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: '搜索笔记...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (_) => _applyFilterAndSort(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showSortDialog,
                  icon: const Icon(Icons.sort),
                  tooltip: '排序',
                ),
              ],
            ),
          ),
          if ((_filterTag != null || _showFavoritesOnly) && !_isSelectMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_filterTag != null)
                    Chip(
                      label: Text('标签：$_filterTag'),
                      onDeleted: () {
                        _filterTag = null;
                        _loadNotes();
                      },
                    ),
                  if (_showFavoritesOnly)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Chip(
                        label: const Text('仅收藏'),
                        avatar: const Icon(Icons.star, size: 16),
                        onDeleted: () {
                          _showFavoritesOnly = false;
                          _loadNotes();
                        },
                      ),
                    ),
                ],
              ),
            ),
          if (_user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('你好，${_user!.displayName}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? Center(child: Semantics(label: '加载中', child: const CircularProgressIndicator()))
                : _filteredNotes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredNotes.length,
                          itemBuilder: (ctx, i) => _buildNoteCard(_filteredNotes[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _isSelectMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NoteEditScreen()),
                );
                if (result == true) _loadNotes();
              },
              icon: const Icon(Icons.add),
              label: const Text('新建笔记'),
            ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;
    return Semantics(
      label: isSearching ? '没有找到匹配的笔记' : '还没有笔记，点击右下角新建笔记按钮',
      excludeSemantics: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSearching ? Icons.search_off : Icons.note_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              isSearching ? '没有找到匹配的笔记' : '还没有笔记，点击右下角新建',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final isSelected = _selectedIds.contains(note.id);

    return Semantics(
      label: '${note.isPinned ? "置顶，" : ""}${note.isFavorite ? "收藏，" : ""}笔记：${note.displayTitle}，${note.preview}，更新于${DateFormat('yyyy-MM-dd HH:mm').format(note.updatedAt)}，${note.tags.isNotEmpty ? "标签：${note.tags.join("、")}，" : ""}双击编辑，长按打开菜单',
      excludeSemantics: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
        child: InkWell(
          onTap: _isSelectMode ? () => _toggleSelect(note.id) : () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteEditScreen(note: note)),
            );
            if (result == true) _loadNotes();
          },
          onLongPress: _isSelectMode ? null : () {
            showModalBottomSheet(
              context: context,
              isDismissible: false,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(note.isFavorite ? Icons.star : Icons.star_border),
                      title: Text(note.isFavorite ? '取消收藏' : '收藏'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _toggleFavorite(note);
                      },
                    ),
                    ListTile(
                      leading: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                      title: Text(note.isPinned ? '取消置顶' : '置顶'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _togglePinned(note);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.content_copy),
                      title: const Text('复制笔记'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _duplicateNote(note);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.share),
                      title: const Text('分享'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _shareNote(note);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('删除', style: TextStyle(color: Colors.red)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _deleteNote(note);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.close),
                      title: const Text('取消'),
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (note.isPinned) const Icon(Icons.push_pin, size: 16, color: Colors.orange),
                    if (note.isPinned) const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        note.displayTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isFavorite) const Icon(Icons.star, size: 16, color: Colors.amber),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note.preview,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: note.tags.map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(note.updatedAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
