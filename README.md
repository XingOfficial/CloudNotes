# 云笔记 CloudNotes

一款简洁高效的 Android 原生笔记应用，支持邮箱验证码登录、笔记增删改查、搜索、排序、自动保存等功能。

## 功能特性

- **邮箱验证码登录/注册** — 无需密码，邮箱验证码一键登录
- **笔记管理** — 创建、编辑、删除、查看笔记
- **笔记搜索** — 实时搜索笔记标题和内容
- **多种排序** — 按更新时间、创建时间、标题排序
- **自动保存** — 编辑时输入停止 2 秒后自动保存，离开页面也会自动保存
- **字数统计** — 编辑页实时显示字数
- **导出笔记** — 支持导出为 Markdown 格式，可分享到任意应用
- **笔记分享** — 一键分享笔记内容
- **下拉刷新** — 列表页下拉刷新笔记
- **深色状态栏** — 沉浸式顶部栏设计

## 技术栈

- **语言**：Kotlin（全项目 Kotlin + Gradle Kotlin DSL）
- **最低 SDK**：API 24（Android 7.0）
- **目标 SDK**：API 34（Android 14）
- **网络请求**：OkHttp 4.12
- **UI 框架**：AndroidX + Material Design + ViewBinding
- **JSON 解析**：org.json（Android 内置）
- **代码混淆**：R8（release 构建自动开启）
- **DNS 兜底**：Cloudflare DNS-over-HTTPS（解决部分运营商域名解析失败）

## 项目结构

```
app/src/main/
├── java/com/notesapp/
│   ├── MyApplication.kt          # Application 入口
│   ├── api/
│   │   ├── ApiClient.kt          # 网络请求客户端
│   │   ├── AuthResult.kt         # 认证结果模型
│   │   └── CustomDns.kt          # 自定义 DNS（DoH 兜底）
│   ├── model/
│   │   ├── Note.kt               # 笔记数据模型
│   │   └── User.kt               # 用户数据模型
│   ├── ui/
│   │   ├── LoginActivity.kt      # 登录/注册页
│   │   ├── NotesListActivity.kt  # 笔记列表页
│   │   ├── NoteEditActivity.kt   # 笔记编辑页
│   │   └── NotesAdapter.kt       # 笔记列表适配器
│   └── util/
│       └── PreferencesManager.kt # 本地存储管理
└── res/                           # 资源文件（布局、图片、字符串、颜色等）
```

## API 接口

后端基于 PHP + JSON 文件存储，接口地址：`https://xingclouddisk.share.zrok.io/notes-api/`

| 接口 | 方法 | 说明 |
|------|------|------|
| `send_code.php` | POST | 发送邮箱验证码 |
| `verify_code.php` | POST | 验证验证码（登录/注册） |
| `notes_list.php` | GET | 获取笔记列表 |
| `notes_create.php` | POST | 创建笔记 |
| `notes_update.php` | POST | 更新笔记 |
| `notes_delete.php` | POST | 删除笔记 |

所有需要登录的接口需在请求头携带 `Authorization: Bearer <token>`。

## 构建方式

### 环境要求
- JDK 17+
- Android SDK（compileSdk 34）
- Gradle 8.2+

### 构建命令
```bash
# Debug 构建
./gradlew assembleDebug

# Release 构建（需配置签名密钥）
./gradlew assembleRelease
```

### 签名配置
在 `app/build.gradle.kts` 中配置签名密钥：
```kotlin
signingConfigs {
    create("release") {
        storeFile = file("your-keystore.jks")
        storePassword = "your-password"
        keyAlias = "your-alias"
        keyPassword = "your-password"
    }
}
```

## 版本历史

- **v3.1** — 新增笔记搜索、排序、自动保存、字数统计、导出功能
- **v3.0** — 全项目迁移到 Kotlin + Gradle Kotlin DSL
- **v1.6** — Java 版，功能完整（登录/注册/笔记增删改查/分享/长按菜单）
- **v1.4** — 开启 R8 代码混淆，体积优化到 3.6MB
- **v1.0** — 初始版本，基础笔记功能

## License

MIT License
