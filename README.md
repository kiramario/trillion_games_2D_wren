# Trillion Games 2D (代号: wren)

基于 LÖVE2D 的 2D 通用游戏引擎脚手架 + 中国象棋首发作品。

## 项目定位

**引擎层（src/core/）** 与 **游戏层（src/game/）** 完全分离。换一个游戏只需替换 game/ 目录，通用能力全部复用。

首发作品：中国象棋（目标优先 Steam，后续支持 APK 和桌面版）

## 快速开始

### 环境要求

- LÖVE2D 11.x 或更高
- Git

### 运行

```bash
# 直接运行（需要系统安装了 love2d）
love .

# 或者在项目根目录执行
cd /path/to/love2DGame_wren
love .
```

### 验证 V0 版本

1. 启动后看到 960×640 窗口
2. 控制台有 INFO 级别日志输出
3. 按 ESC 退出游戏

## 项目结构

```
love2DGame_wren/
├── main.lua              # 游戏入口
├── conf.lua              # LÖVE2D 配置
├── README.md             # 项目说明
├── LICENSE               # 许可协议
├── .gitignore            # Git 忽略文件
├── docs/                 # 文档目录
│   ├── 01_vision.md       # 项目愿景
│   ├── 02_methodology.md  # 开发方式与理由
│   ├── 03_architecture.md # 整体架构
│   ├── 04_directory.md    # 目录设计
│   ├── 05_roadmap.md      # 版本路线图
│   ├── 06_code_style.md   # 代码规范
│   ├── 07_doc_style.md    # 文档规范
│   ├── 08_release.md      # 发布路径建议
│   ├── 09_risks.md        # 主要风险与替代方案
│   └── changelog.md       # 变更日志
├── src/
│   ├── core/             # 通用 2D 游戏脚手架层（与具体游戏无关）
│   │   ├── logger.lua       # 日志系统
│   │   ├── config.lua       # 配置管理
│   │   ├── input_manager.lua# 输入管理
│   │   ├── scene_manager.lua# 场景管理
│   │   ├── resource_manager.lua # 资源管理
│   │   ├── render_manager.lua   # 渲染分层管理
│   │   ├── camera.lua       # 相机系统
│   │   ├── entity.lua       # 实体基类
│   │   ├── animation.lua    # 动画与缓动系统
│   │   ├── audio_manager.lua# 音效与音乐管理
│   │   ├── particle_system.lua # 粒子系统
│   │   ├── save_manager.lua # 存档管理
│   │   ├── utils.lua        # 工具函数
│   │   └── ui/              # 通用 UI 组件库
│   │       ├── widget.lua    # UI 组件基类
│   │       ├── button.lua    # 按钮
│   │       ├── panel.lua     # 面板
│   │       ├── checkbox.lua  # 复选框
│   │       └── ui_manager.lua# UI 管理器
│   └── game/             # 中国象棋业务层
│       ├── entities/       # 游戏实体
│       │   ├── board.lua    # 棋盘
│       │   └── piece.lua    # 棋子
│       ├── scenes/         # 游戏场景
│       │   ├── main_menu.lua    # 主菜单
│       │   └── game_play.lua    # 游戏对战
│       ├── rules.lua       # 规则引擎
│       └── ai.lua          # AI 对手
├── assets/               # 资源目录
│   ├── images/             # 图片
│   ├── sounds/             # 音效
│   ├── music/              # 背景音乐
│   └── fonts/              # 字体
└── scripts/              # 构建/发布脚本
```

## 版本列表

| 版本 | 内容 | Tag |
|------|------|-----|
| V0.0.0 | 项目初始化与文档 | v0.0.0 |
| V0.1.0 | 基础脚手架（核心模块） | v0.1.0 |
| V0.2.0 | 渲染增强（分层/相机/实体/动画） | v0.2.0 |
| V1.0.0 | 棋盘与棋子渲染 | v1.0.0 |
| V2.0.0 | 规则引擎（走法/吃子/将军/胜负） | v2.0.0 |
| V3.0.0 | UI系统 + 存档 + 设置 | v3.0.0 |
| V4.0.0 | 音效 + 粒子 + 动效 | v4.0.0 |
| V5.0.0 | AI对手 + 发布准备 | v5.0.0 |

## 切换版本测试

```bash
# 查看所有版本 tag
git tag

# 切换到指定版本
git checkout v0.0.0
git checkout v1.0.0
git checkout v5.0.0

# 切回最新版
git checkout master
```

## 文档索引

- [项目愿景](docs/01_vision.md)
- [开发方式与理由](docs/02_methodology.md)
- [整体架构](docs/03_architecture.md)
- [目录设计](docs/04_directory.md)
- [版本路线图](docs/05_roadmap.md)
- [代码规范](docs/06_code_style.md)
- [文档规范](docs/07_doc_style.md)
- [发布路径建议](docs/08_release.md)
- [主要风险与替代方案](docs/09_risks.md)
- [变更日志](docs/changelog.md)

## 设计原则

1. **分层清晰**：通用层与业务层严格分离，通用层不依赖任何游戏特定逻辑
2. **注释友好**：所有 Lua 特性和 LÖVE2D API 都有 JS/Java/Python 视角的类比说明
3. **渐进式开发**：每个版本都是最小可运行版本，随时可以切换 tag 看到明确成果
4. **可复用**：核心模块设计为通用，后续做弹珠等其他 2D 游戏可直接复用
5. **可维护**：代码简洁，不炫技，结构清晰，方便后续扩展

## 许可

MIT
