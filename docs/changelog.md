# 变更日志

所有重要的版本变更都会记录在这个文件里。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/) 规范。

---

## [Unreleased] - 开发中
### 新增
- 待添加

---

## [v0.0.0] - 2024-06-09
### 新增
- 📄 项目初始化，创建目录结构
- 📝 完整的规划文档（9 篇）
  - 01_vision.md：项目愿景
  - 02_methodology.md：推荐开发方式（增量开发）与理由
  - 03_architecture.md：整体架构设计
  - 04_directory.md：仓库目录设计
  - 05_roadmap.md：V0-V5 详细版本路线图
  - 06_code_style.md：代码规范
  - 07_doc_style.md：文档规范
  - 08_release.md：Steam/APK/桌面发布路径建议
  - 09_risks.md：主要风险与替代方案
- 📋 README.md：项目说明文档
- 🔧 conf.lua：LÖVE2D 基础配置
- 🎮 main.lua：最简单的可运行入口

### 说明
V0.0.0 是项目的第一个版本，主要是规划和文档，代码只有最简单的可运行入口。
所有方向、架构、规范都已经定好，后面的版本就按这个路线图推进。

### 验收
- ✅ `love .` 能正常启动，显示窗口，不报错
- ✅ 所有规划文档都写完了
- ✅ Git 仓库初始化完成
- ✅ 打了 v0.0.0 tag
