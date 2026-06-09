# 变更日志

所有重要的版本变更都会记录在这个文件里。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/) 规范。

---

## [Unreleased] - 开发中
### 新增
- 待添加

---

## [v0.1.0] - 2024-06-09
### 新增
- 📝 日志系统（`src/core/logger.lua`）
  - 四级日志：DEBUG / INFO / WARN / ERROR
  - 控制台彩色输出
  - 支持多个日志实例，默认全局单例
  - 类比 JS console / Java log4j
- ⚙️ 配置管理（`src/core/config.lua`）
  - 默认配置 + 用户配置合并
  - 支持点号路径访问（`config:get("window.width")`）
  - 深拷贝和深合并
- 🎹 输入管理器（`src/core/input_manager.lua`）
  - 键盘输入：按下/按住/松开三种状态查询
  - 鼠标输入：位置、按钮、滚轮
  - 按键映射，支持逻辑按键名
  - 每帧自动清理 pressed/released 状态
- 🎬 场景管理器（`src/core/scene_manager.lua`）
  - 场景注册和切换
  - 场景栈（push/pop，适合弹窗/设置页）
  - 完整的生命周期：enter / update / draw / exit / pause / resume
  - 类比 React Router / Android Activity 栈
- 📦 资源管理器（`src/core/resource_manager.lua`）
  - 图片/音效/音乐/字体的加载和缓存
  - 自动检测扩展名（png/jpg/ogg/mp3 等）
  - 预加载、卸载、统计
  - 避免重复加载，提升性能
- 🛠️ 工具函数库（`src/core/utils.lua`）
  - 数学工具：clamp、lerp、distance、随机数等
  - 表格工具：浅拷贝、深拷贝、合并、查找等
  - 字符串工具：分割、trim、前后缀判断
  - 颜色工具：RGB 转换、十六进制颜色
  - 其他通用工具
- 🧪 两个测试场景（`test_scene_a.lua` / `test_scene_b.lua`）
  - 场景 A：暖色调，按空格切换到 B
  - 场景 B：冷色调，按空格切换回 A
  - 验证场景切换功能正常

### 说明
V0.1.0 完成了通用 2D 游戏框架的核心基础模块。
所有模块都是通用的，和具体游戏无关，可以复用到任何 2D 游戏。
这一版没有任何游戏内容，只是把框架的地基搭好了。

### 验收标准
- ✅ 游戏正常启动，不报错
- ✅ 控制台有完整的启动日志
- ✅ 按空格键可以在两个场景之间切换
- ✅ 按 F1 可以开关调试信息
- ✅ 按 ESC 可以退出游戏
- ✅ 所有核心模块都能正常工作
- ✅ 所有模块都是通用的，不依赖具体游戏逻辑

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
