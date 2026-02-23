# BeeCount Community Edition (BeeCo)

一个简洁、高效的 Flutter 个人记账应用，从原 BeeCount 项目精简而来，移除了复杂的云同步和 AI 功能，专注于核心记账体验。

## 功能特性

### 核心功能
- ✅ 多账本管理 - 支持创建多个独立账本
- ✅ 收支记录 - 支持收入、支出、转账三种类型
- ✅ 分类管理 - 二级分类系统，支持自定义分类图标
- ✅ 账户管理 - 多账户管理，支持现金、银行卡、信用卡等
- ✅ 预算设置 - 月度预算追踪
- ✅ 数据统计 - 图表分析、分类排行、趋势分析
- ✅ 日历视图 - 日历形式查看收支情况
- ✅ 数据导入导出 - 支持 CSV 格式
- ✅ 暗黑模式 - 完整的深色主题支持
- ✅ 多语言 - 支持中文、英文

### 技术栈
- Flutter 3.x
- Riverpod 状态管理
- SQLite 本地数据库
- Material Design 3

## 快速开始

### 环境要求
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android SDK >= 21

### 安装步骤

1. 克隆仓库
```bash
git clone https://github.com/yourusername/beeco.git
cd beeco
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

4. 构建 APK
```bash
flutter build apk --release
```

构建后的 APK 位于：`build/app/outputs/flutter-apk/app-release.apk`

## 项目结构

```
beeco/
├── lib/
│   ├── data/           # 数据库相关
│   ├── models/         # 数据模型
│   ├── pages/          # 页面
│   ├── providers/      # 状态管理
│   ├── theme/          # 主题配置
│   ├── utils/          # 工具函数
│   └── main.dart       # 应用入口
├── android/            # Android 配置
├── assets/             # 资源文件
└── pubspec.yaml        # 依赖配置
```

## 与原版的区别

| 功能 | BeeCount | BeeCo |
|------|----------|-------|
| 云同步 | ✅ iCloud/Supabase/WebDAV/S3 | ❌ 本地存储 |
| AI功能 | ✅ OCR/语音/AI助手 | ❌ 移除 |
| 截图监听 | ✅ Android/iOS | ❌ 移除 |
| 桌面小组件 | ✅ iOS/Android | ❌ 移除 |
| 内购 | ✅ 专业版 | ❌ 移除 |
| 数据导入导出 | ✅ CSV/Excel/YAML | ✅ CSV |
| 多账本 | ✅ 完整支持 | ✅ 支持 |
| 分类管理 | ✅ 二级分类 | ✅ 二级分类 |
| 预算管理 | ✅ 完整支持 | ✅ 基础支持 |
| 暗黑模式 | ✅ 完整支持 | ✅ 支持 |
| 多语言 | ✅ 中英繁 | ✅ 中英 |

## 许可证

MIT License

## 致谢

本项目基于 [BeeCount](https://github.com/TNT-Likely/BeeCount) 精简重构，感谢原作者的开源贡献。
