# ⚖️ DEBIT_SYNC // 智能账单对账工具

**DEBIT_SYNC** 是一款采用“复古未来极简主义 (Retro-Future Minimalism)”设计风格的自动化对账工具。它专为解决中国工商银行 (ICBC) 流水与微信支付明细之间的对账痛点而设计，通过精密算法实现当日流水的全自动配对。

![Aesthetics](https://img.shields.io/badge/Aesthetics-Retro--Future-orange)
![Python](https://img.shields.io/badge/Python-3.14-blue)
![Framework](https://img.shields.io/badge/Framework-Streamlit-red)

## 🚀 核心功能

### 1. 智能账单对账 (DEBIT_SYNC)
- **双 Excel 自动对账**：支持工行 XLSX 流水与微信导出明细的直接对位，无需 PDF 繁琐步骤。
- **Multiset 匹配算法**：按日期对每一笔交易进行排序对比，精准识别漏项。
- **多维度明细追踪**：在对账异常时，自动展示当日双端的“对方户名”、“交易内容”与“商品详情”。
- **人机协同审核**：支持一键审核已确认的异常流水，状态实时同步，主表动态变绿。
- **复古未来主义视觉**：黑曜石底色配合琥珀色荧光点缀，带给您极简且硬核的对账体验。

### 2. 极速视频下载 (VID_LOADER)
- **VidBee 内核优化**：集成 JS Runtime (Deno/Node) 自动探测，提取能力更强。
- **全速引擎**：aria2c 16线程并发，榨干带宽潜力。
- **登录穿透**：支持从 Chrome/Edge 自动提取 Cookie，轻松下载会员/限制视频。

## 🛠️ 安装与运行

1. **环境准备**：
   项目采用 `uv` 进行依赖管理。
   ```bash
   pip install uv
   ```

2. **安装依赖**：
   ```bash
   uv sync
   ```

3. **启动对账工具**：
   ```bash
   uv run streamlit run app.py
   ```

4. **启动视频下载工具**：
   ```bash
   uv run python auto_download.py
   ```
   *或直接运行 `启动视频下载工具.bat`*

## 📂 项目结构 (File Structure)

本仓库现包含以下核心工具及其配套文件：

### ⚖️ 对账工具相关
- **`app.py`**：对账工具主程序 (Streamlit)。
- **`reconcile_bills.py`**：辅助对账逻辑库。

### 🎬 视频下载相关
- **`auto_download.py`**：视频下载工具主程序 (Flask + VidBee 内核)。
- **`templates/`**：下载工具的前端界面模板。
- **`static/`**：下载工具的静态资源文件。
- **`启动视频下载工具.bat`**：Windows 一键启动脚本。

### ⚙️ 系统通用
- **`pyproject.toml`**：全量项目依赖配置。
- **`.gitignore`**：隐私防护，严格过滤所有流水账单与个人数据。
- **`README.md`**：项目说明文档。

## 🔒 隐私安全

- **本地解析**：所有账单数据仅在内存中处理，绝不上传至任何云端服务器。
- **.gitignore 保护**：默认配置严格过滤所有 `.xlsx` 和 `.pdf` 文件，确保您的隐私数据不会进入 Git 版本库。

## 🎨 视觉风格说明

本项目遵循 **现代极简 + 复古未来** 的基调：
- **字体**：数据部分采用 `JetBrains Mono`，确保对账时的机械精准感。
- **布局**：一像素边框、直角逻辑、零圆角阴影。
- **色彩**：黑曜石 (#050505) 为底，琥珀色 (#FFAA00) 激活。

---
*Created with Passion for Precise Finance.*
