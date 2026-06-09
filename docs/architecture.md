# 详细架构设计

## 核心设计思想

### 1. 分层架构 + 依赖倒置
上层依赖下层，下层不感知上层。通用层（core/systems）绝对不能引用业务层（entities/game）的代码。

类比：
- Java的三层架构（DAO/Service/Controller）
- JS的MVC里的Model和View不能互相直接调用

### 2. 组合优于继承
尽量用组合的方式组装功能，而不是深继承链。Lua的metatable继承虽然能用，但深了不好理解。

类比：
- Unity的组件系统
- ECS（实体组件系统）的思想，简化版

### 3. 事件驱动解耦
模块之间通过事件总线通信，不直接持有对方的引用。

类比：
- JS的EventEmitter
- Java的观察者模式
- 前端的自定义事件

---

## 核心模块详解

### 1. Logger 日志系统

**职责**：统一的日志输出，分级管理，方便调试。

**接口**：
- Logger.info(message) - 普通信息
- Logger.warn(message) - 警告
- Logger.error(message) - 错误
- Logger.debug(message) - 调试信息（默认关闭）

**设计要点**：
- 不同级别不同颜色（控制台输出）
- 可以配置输出级别
- 每条日志带时间戳和调用位置
- 后续可以扩展写文件

---

### 2. Config 配置系统

**职责**：集中管理所有配置项，统一读取，支持热重载。

**设计要点**：
- 所有可调参数都在这里，不要硬编码
- 分模块配置（graphics/audio/input/game等）
- 有默认值，配置文件不存在也能跑
- 后续可以做成读json/lua配置文件

类比：
- JS里的config.js
- Java里的application.properties
- Python里的settings.py

---

### 3. EventBus 事件总线

**职责**：模块之间的通信中枢，发布订阅模式。

**接口**：
- EventBus:subscribe(event_name, callback) - 订阅事件
- EventBus:unsubscribe(event_name, callback) - 取消订阅
- EventBus:publish(event_name, data) - 发布事件

**常用事件示例**：
- scene_changed - 场景切换
- input_mouse_pressed - 鼠标按下
- input_key_pressed - 键盘按下
- game_piece_moved - 棋子移动
- game_check - 将军

**为什么要用事件总线**：
- 解耦：A模块发事件，不用知道谁在听
- 灵活：随时加新的监听者，不用改发事件的代码
- 易调试：所有事件都可以打日志

类比：
- JS的addEventListener
- Node.js的EventEmitter
- 消息队列（简化版单进程版）

---

### 4. ResourceManager 资源管理器

**职责**：统一加载和缓存图片、音效、字体等资源，避免重复加载。

**接口**：
- ResourceManager:load_image(path) - 加载图片，返回缓存的
- ResourceManager:load_sound(path) - 加载音效
- ResourceManager:load_font(path, size) - 加载字体
- ResourceManager:unload_all() - 卸载所有资源

**设计要点**：
- 缓存已经加载的资源，重复调用直接返回
- 异步加载（后续版本加，V0先同步）
- 引用计数，不用的资源可以卸载
- 资源路径统一管理

类比：
- 浏览器的缓存
- Java的资源池
- Unity的Resources.Load + 缓存

---

### 5. SceneManager 场景管理器

**职责**：管理场景的生命周期，负责场景切换。

**场景生命周期**：
```
enter()  →  update(dt) 每帧调用  →  exit()
                    ↓
               draw() 每帧调用
```

**接口**：
- SceneManager:switch_scene(scene_name, params) - 切换场景
- SceneManager:update(dt) - 更新当前场景
- SceneManager:draw() - 绘制当前场景

**设计要点**：
- 场景之间切换有过渡效果（后续加）
- 切换时清理上一个场景的资源
- 参数传递：切换场景可以带参数

类比：
- 前端的路由（React Router/Vue Router）
- Android的Activity栈
- iOS的ViewController

---

### 6. BaseScene 场景基类

**职责**：所有场景的父类，定义统一的生命周期接口。

**子类需要重写的方法**：
- enter(params) - 进入场景时调用
- exit() - 离开场景时调用
- update(dt) - 每帧更新
- draw() - 每帧绘制

**设计要点**：
- 空的默认实现，子类按需重写
- 统一的事件绑定/解绑时机
- 每个场景有自己的名字

类比：
- 抽象基类（Java abstract class）
- React的Component基类
- 接口（Interface），带默认实现

---

### 7. RenderSystem 渲染系统

**职责**：分层渲染，统一管理绘制顺序。

**渲染层级（从下到上）**：
1. BACKGROUND - 背景层
2. GAME - 游戏内容层（棋盘、棋子等）
3. EFFECT - 特效层（粒子、光影等）
4. UI - 用户界面层（按钮、文字等）
5. DEBUG - 调试信息层（最上层）

**接口**：
- RenderSystem:add_to_layer(layer, draw_func) - 添加绘制函数到某一层
- RenderSystem:draw() - 按层级顺序绘制全部
- RenderSystem:clear() - 清空所有绘制函数

**为什么要分层渲染**：
- 不用自己记绘制顺序，按层来就不会错
- 同一层的可以做排序（比如按Y坐标排序伪深度）
- 方便开关某一层（比如关调试层）

类比：
- Photoshop的图层
- CSS的z-index
- Canvas的绘制顺序

---

### 8. InputSystem 输入系统

**职责**：统一封装输入事件，分发到各个模块。

**处理的输入**：
- 鼠标：按下、释放、移动、滚轮
- 键盘：按下、释放
- 触屏（后续加）

**设计要点**：
- 原始输入事件 → 封装成游戏事件 → 通过EventBus发布
- 支持按键映射（后续加）
- 支持输入状态查询（某键是否按住）

为什么不直接用love.mouse/love.keyboard：
- 封装一层，后续换平台或者改输入方式不用改业务代码
- 统一打日志，方便调试
- 可以加输入录制回放功能

类比：
- 前端的事件委托
- Unity的Input System
- 游戏手柄的输入映射

---

## 数据流向

### 正常一帧的流程
```
love.update(dt)
  ↓
InputSystem:update()  - 处理输入
  ↓
EventBus 发布输入事件
  ↓
SceneManager:update(dt) - 更新当前场景
  ↓
场景逻辑处理，可能发布各种游戏事件
  ↓
love.draw()
  ↓
RenderSystem:draw() - 按层绘制
```

### 场景切换的流程
```
调用 SceneManager:switch_scene("game")
  ↓
EventBus:publish("scene_before_change", {from="menu", to="game"})
  ↓
current_scene:exit()
  ↓
current_scene = GameScene.new()
  ↓
current_scene:enter(params)
  ↓
EventBus:publish("scene_changed", {from="menu", to="game"})
```

---

## 模块依赖关系图

```
                    main.lua
                       │
                       ▼
          ┌──────────────────────┐
          │     SceneManager     │
          └──────────────────────┘
              │    │    │    │
              ▼    ▼    ▼    ▼
        MenuScene GameScene ...  (场景层，业务相关)
              │    │    │
              └────┼────┘
                   │
         ┌─────────┴─────────┐
         │   EventBus        │  (核心层，通用)
         └─────────┬─────────┘
                   │
    ┌──────────────┼──────────────┐
    ▼              ▼              ▼
RenderSystem  InputSystem  AudioSystem ... (系统层，通用)
    │              │              │
    └──────────────┼──────────────┘
                   │
         ┌─────────┴─────────┐
         │  ResourceManager  │  (核心层，通用)
         │     Logger        │
         │     Config        │
         └─────────┬─────────┘
                   │
                   ▼
              LÖVE2D API
```

---

## 扩展新游戏的步骤（比如弹珠台）

1. 在src/entities/里加弹珠、挡板、砖块等实体
2. 在src/game/里加弹珠的物理、碰撞、得分等逻辑
3. 在src/scenes/里加弹珠的游戏场景
4. 修改菜单场景，加一个弹珠游戏的入口
5. 完成！core和systems层完全不用改

这就是分层架构的好处——通用能力一次写好，无限复用。

---

*文档版本：v0.0.1*
