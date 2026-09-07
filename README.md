# 云笔记

简洁高效的云端笔记应用，使用 Flutter 开发，支持 Android 平台。

## 功能特性

- 📝 **快速记录** - 新建笔记只需一步，标题和内容自由填写
- 🔐 **邮箱验证码登录** - 无需设置密码，邮箱+6位验证码即可登录/注册
- ☁️ **云端同步** - 所有笔记实时保存在云端服务器，换设备不丢失
- ⭐ **笔记收藏** - 收藏重要笔记，支持仅显示收藏
- 📌 **笔记置顶** - 置顶笔记永远排在最前面
- 🏷️ **标签系统** - 给笔记打标签，按标签筛选
- ⏰ **笔记提醒** - 设置提醒时间，到点本地通知提醒
- 📋 **复制笔记** - 一键复制生成笔记副本
- 🗂️ **批量操作** - 多选批量删除、批量分享
- 🌙 **深色模式** - 支持亮色/暗色主题切换
- 🔍 **搜索排序** - 支持搜索笔记，多种排序方式
- 💾 **自动保存** - 编辑时输入停止2秒自动保存
- 📊 **字数统计** - 实时显示笔记字数
- 📤 **导出 Markdown** - 一键导出笔记为 Markdown 文件
- 🔗 **一键分享** - 调用系统分享面板，发送到任意应用
- ♿ **无障碍优化** - 完整支持 TalkBack 屏幕阅读器

## 技术栈

- **前端**: Flutter 3.47 / Dart 3.13
- **后端**: PHP + JSON 文件存储
- **网络**: HTTP REST API
- **通知**: flutter_local_notifications
- **存储**: SharedPreferences

## 后端 API

### 用户认证
- `send_code.php` - 发送验证码
- `verify_code.php` - 验证验证码（登录/注册）

### 笔记操作
- `notes_list.php` - 获取笔记列表（支持收藏/标签筛选，置顶优先排序）
- `notes_create.php` - 创建笔记
- `notes_update.php` - 更新笔记
- `notes_delete.php` - 删除笔记
- `notes_toggle_favorite.php` - 切换收藏
- `notes_toggle_pinned.php` - 切换置顶
- `notes_duplicate.php` - 复制笔记
- `notes_tags.php` - 获取用户所有标签

### 笔记数据结构
```json
{
  "id": "n_xxx",
  "user_id": "u_xxx",
  "title": "笔记标题",
  "content": "笔记内容",
  "is_favorite": 0,
  "is_pinned": 0,
  "tags": "[\"工作\",\"重要\"]",
  "reminder_time": "2026-09-07 10:00:00",
  "created_at": "2026-09-07 10:00:00",
  "updated_at": "2026-09-07 10:00:00"
}
```

## 构建说明

### 环境要求
- Flutter SDK 3.47+
- Android SDK (compileSdk 36)
- JDK 17

### 构建命令
```bash
flutter pub get
flutter build apk --release
```

### 后端部署
1. 把 `backend/` 目录下的 PHP 文件上传到服务器
2. 确保 `data/` 目录有写入权限
3. 修改 `config.php` 中的 SMTP 配置

## 版本历史

### v1.0.2
- 修复无法打开浏览器的问题
- 新建笔记页面简化，收藏/置顶/标签/提醒仅在编辑页显示

### v1.0.1
- 笔记收藏/星标
- 笔记固定置顶
- 笔记标签系统
- 笔记提醒（本地通知）
- 复制笔记
- 批量操作（批量删除/分享）
- 深色模式
- 无障碍优化（TalkBack）

### v1.0.0
- 基础笔记功能（增删改查）
- 邮箱验证码登录/注册
- 搜索和排序
- 自动保存
- 导出 Markdown
- 一键分享

## 许可证

MIT License
