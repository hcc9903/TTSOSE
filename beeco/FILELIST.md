# BeeCo 项目文件清单

## 项目结构

```
beeco/
├── android/
│   └── app/
│       ├── build.gradle
│       └── src/
│           └── main/
│               ├── AndroidManifest.xml
│               ├── kotlin/
│               │   └── com/
│               │       └── beeco/
│               │           └── app/
│               │               └── MainActivity.kt
│               └── res/
│                   ├── drawable/
│                   │   └── launch_background.xml
│                   └── values/
│                       ├── strings.xml
│                       └── styles.xml
│   ├── build.gradle
│   ├── proguard-rules.pro
│   └── settings.gradle
├── assets/
│   └── (logo.png - 需要添加)
├── lib/
│   ├── data/
│   │   ├── dao.dart          # 数据访问对象
│   │   └── database_helper.dart  # 数据库帮助类
│   ├── models/
│   │   └── models.dart       # 数据模型 (Ledger, Account, Category, Transaction, Budget)
│   ├── pages/
│   │   ├── home_page.dart    # 首页
│   │   ├── main_page.dart    # 主页面框架
│   │   ├── settings_page.dart # 设置页面
│   │   └── stats_page.dart   # 统计页面
│   ├── providers/
│   │   └── app_providers.dart # 状态管理
│   ├── theme/
│   │   └── app_theme.dart    # 主题配置
│   ├── widgets/
│   │   └── logo_widget.dart  # Logo组件
│   └── main.dart             # 应用入口
├── test/
│   └── widget_test.dart      # 测试文件
├── analysis_options.yaml     # 代码分析配置
├── BUILD.md                  # 构建说明
├── pubspec.yaml              # 依赖配置
└── README.md                 # 项目说明

```

## 文件统计

- Dart 文件: 12 个
- Gradle 文件: 3 个
- XML 文件: 4 个
- Kotlin 文件: 1 个
- Markdown 文件: 2 个
- YAML 文件: 2 个
- ProGuard 文件: 1 个

总计: 约 25 个文件

## 与原版的区别

### 保留的核心功能
- 多账本管理
- 收支记录（收入、支出、转账）
- 账户管理
- 分类管理（二级分类）
- 预算设置
- 数据统计和图表
- 数据导入导出（CSV）
- 暗黑模式
- 多语言支持

### 移除的复杂功能
- AI 相关功能（OCR、语音、AI助手）
- 云同步（iCloud/Supabase/WebDAV/S3）
- 截图自动监听
- 桌面小组件
- 内购功能
- 复杂的权限处理
- 第三方登录
- 社区功能

### 技术栈变更
- 数据库: Drift → sqflite
- 状态管理: Riverpod（保留，简化）
- 移除本地包依赖
- 移除复杂的平台通道代码

## 构建 APK

```bash
cd beeco
flutter pub get
flutter build apk --release
```

APK 路径: `build/app/outputs/flutter-apk/app-release.apk`
