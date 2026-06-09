# 04. 仓库目录设计

## 目录总览

```
love2DGame_wren/
├── main.lua              # 游戏入口文件（最顶层，LÖVE2D 默认加载 main.lua）
├── conf.lua              # LÖVE2D 配置文件（窗口大小、标题等）
├── config.lua            # 游戏配置（游戏逻辑相关的配置）
│
├── README.md             # 项目说明
├── LICENSE               # 许可协议
├── .gitignore            # Git 忽略文件
│
├── docs/                 # 文档目录
│   ├── 01_vision.md       # 项目愿景
│   ├── 02_methodology.md  # 开发方式与理由
│   ├── 03_architecture.md # 整体架构
│   ├── 04_directory.md    # 目录设计（就是这个文件）
│   ├── 05_roadmap.md      # 版本路线图
│   ├── 06_code_style.md   # 代码规范
│   ├── 07_doc_style.md    # 文档规范
│   ├── 08_release.md      # 发布路径建议
│   ├── 09_risks.md        # 主要风险与替代方案
│   └── changelog.md       # 变更日志（每个版本更新）
│
├── src/                  # 源代码目录
│   ├── core/             # 通用 2D 游戏框架层（与具体游戏无关）
│   │   ├── logger.lua       # 日志系统
│   │   ├── config.lua       # 配置管理
│   │   ├── utils.lua        # 通用工具函数
│   │   │
│   │   ├── input_manager.lua  # 输入管理（键盘/鼠标/手柄）
│   │   ├── scene_manager.lua  # 场景管理
│   │   ├── resource_manager.lua # 资源管理（图片/音效/字体）
│   │   │
│   │   ├── render_manager.lua  # 渲染分层管理
│   │   ├── camera.lua         # 相机系统
│   │   ├── entity.lua         # 实体基类
│   │   ├── animation.lua      # 动画与缓动系统
│   │   ├── particle_system.lua # 粒子系统
│   │   │
│   │   ├── audio_manager.lua  # 音频管理（音效/背景音乐）
│   │   ├── save_manager.lua   # 存档管理
│   │   │
│   │   └── ui/              # 通用 UI 组件库
│   │       ├── widget.lua      # UI 组件基类
│   │       ├── button.lua      # 按钮组件
│   │       ├── panel.lua       # 面板组件
│   │       ├── checkbox.lua    # 复选框组件
│   │       ├── text.lua        # 文本组件（后面加）
│   │       └── ui_manager.lua  # UI 管理器
│   │
│   └── game/             # 游戏业务层（中国象棋特有，换游戏就换这个目录）
│       ├── entities/       # 游戏实体
│       │   ├── board.lua    # 棋盘
│       │   └── piece.lua    # 棋子
│       │
│       ├── scenes/         # 游戏场景
│       │   ├── main_menu.lua    # 主菜单场景
│       │   ├── game_play.lua    # 游戏对战场景
│       │   ├── settings.lua     # 设置场景（后面可以拆出来）
│       │   └── game_over.lua    # 游戏结束场景（后面可以拆出来）
│       │
│       ├── rules.lua       # 规则引擎
│       └── ai.lua          # AI 对手
│
├── assets/               # 资源目录（美术/音频/字体等）
│   ├── images/             # 图片资源
│   │   ├── ui/              # UI 相关图片
│   │   ├── pieces/          # 棋子图片
│   │   └── board/           # 棋盘图片
│   │
│   ├── sounds/             # 音效（短音频，加载到内存）
│   │   ├── select.wav       # 选中音效
│   │   ├── move.wav         # 移动音效
│   │   ├── capture.wav      # 吃子音效
│   │   ├── check.wav        # 将军音效
│   │   └── game_over.wav    # 游戏结束音效
│   │
│   ├── music/              # 背景音乐（长音频，流式播放）
│   │   └── bgm.ogg          # 背景音乐
│   │
│   └── fonts/              # 字体
│       └── default.ttf      # 默认字体
│
├── scripts/              # 脚本目录（构建/打包/发布脚本）
│   ├── run.sh              # 运行游戏脚本
│   ├── build_windows.sh    # 打包 Windows 版本
│   ├── build_macos.sh      # 打包 macOS 版本
│   ├── build_linux.sh      # 打包 Linux 版本
│   ├── build_android.sh    # 打包 Android APK
│   └── build_steam.sh      # 打包 Steam 版本
│
├── build/                # 构建输出目录（Git 忽略）
│   ├── windows/            # Windows 构建产物
│   ├── macos/              # macOS 构建产物
│   ├── linux/              # Linux 构建产物
│   └── android/            # Android 构建产物
│
└── saves/                # 存档目录（运行时生成，Git 忽略）
```

## 目录设计原则

### 1. 按职责分层，不按文件类型分
- core/ 和 game/ 是最大的两个分层，职责完全不同
- 每个分层下面再按功能模块分子目录
- 类比：后端的 controller/service/dao 分层，或者前端的 components/pages/utils 分层

### 2. 通用的放左边，业务的放右边
- 越靠左越通用，越靠右越和具体游戏相关
- 看目录结构就能看出来哪些是可以复用的，哪些是业务代码
- 核心层（core/）完全独立，业务层（game/）依赖核心层

### 3. 资源和代码分离
- 所有静态资源都放 assets/ 目录
- 代码放 src/ 目录
- 脚本放 scripts/ 目录
- 文档放 docs/ 目录
- 各归各位，不混乱

### 4. 构建产物不入库
- build/、saves/ 等运行时或构建生成的目录，加入 .gitignore
- 仓库里只放源码和必要的资源
- 保持仓库干净

### 5. 命名清晰，一看就懂
- 目录名全小写，用下划线分隔（snake_case）
- 文件名也全小写，下划线分隔
- 不用拼音，不用缩写（除非是大家都认识的缩写，比如 ui、api）
- 看到名字就知道里面装的是什么，不用打开看

## 各目录详细说明

### 根目录文件
| 文件 | 说明 |
|------|------|
| main.lua | LÖVE2D 入口文件，游戏启动时第一个加载的文件 |
| conf.lua | LÖVE2D 配置文件，设置窗口大小、标题、帧率等，在 love.load 之前加载 |
| config.lua | 游戏自己的配置，比如难度默认值、音量默认值等 |
| README.md | 项目说明文档，新人上手第一个看的文件 |
| LICENSE | 开源许可协议 |
| .gitignore | Git 忽略文件列表 |

### docs/ 目录
所有文档都在这里，按编号排序，方便按顺序阅读：
- 01~03：项目概览（愿景、方式、架构）
- 04~05：项目规划（目录、路线图）
- 06~07：规范（代码、文档）
- 08~09：落地（发布、风险）
- changelog.md：每个版本的变更记录

### src/core/ 目录（通用框架层）
这是整个项目最有价值的部分，所有 2D 游戏都能复用。

**基础模块**（最底层，被所有人依赖）：
- logger.lua：日志系统，所有模块都用它打日志
- config.lua：配置管理，集中管理所有配置
- utils.lua：工具函数，大家都能用的通用工具

**系统模块**（核心功能）：
- input_manager.lua：输入管理，统一处理所有输入
- scene_manager.lua：场景管理，游戏的"页面切换"
- resource_manager.lua：资源管理，加载和缓存所有资源

**渲染模块**（和画面相关的）：
- render_manager.lua：渲染管理器，分层渲染
- camera.lua：相机系统，镜头控制
- entity.lua：实体基类，所有游戏对象都继承它
- animation.lua：动画系统，补间动画、缓动
- particle_system.lua：粒子系统，特效用

**其他模块**：
- audio_manager.lua：音频管理，音效和音乐
- save_manager.lua：存档管理，存盘读档
- ui/：UI 组件库，所有游戏都能用的 UI 组件

### src/game/ 目录（业务层）
中国象棋特有的代码，换游戏就换掉这个目录。

- entities/：游戏实体，棋盘、棋子这些可见的游戏对象
- scenes/：游戏场景，不同的"页面"
- rules.lua：规则引擎，象棋的所有规则都在这里
- ai.lua：AI 对手，人机对战的 AI

### assets/ 目录
所有静态资源，按类型分子目录：
- images/：图片，再按用途细分（ui/pieces/board 等）
- sounds/：短音效，加载到内存里，播放延迟低
- music/：长音乐，流式播放，不占太多内存
- fonts/：字体文件

### scripts/ 目录
所有脚本，按用途命名：
- run.sh：运行游戏的快捷脚本
- build_*.sh：各种平台的打包脚本
- 其他工具脚本

### build/ 目录
构建产物，不入库：
- 每个平台一个子目录
- 打完包的可执行文件都在这里
- Git 忽略，不提交到仓库

### saves/ 目录
运行时生成的存档和设置文件：
- 游戏存档
- 设置文件
- 日志文件
- Git 忽略

## 后续扩展建议

如果项目变大了，可以考虑再加这些目录：
- `tests/`：单元测试
- `tools/`：开发工具（地图编辑器、粒子编辑器等）
- `plugins/`：插件系统（如果需要插件化）
- `docs/api/`：API 文档

目前项目还小，先不用加，等需要了再加。**不要过度设计，够用就行。**
