# 代码规范

## 一、Lua 语言风格

### 1.1 缩进
- 用4个空格缩进，**绝对不要用tab**
- 同一层级的代码对齐

```lua
-- ✅ 正确
if condition then
    do_something()
end

-- ❌ 错误（2个空格）
if condition then
  do_something()
end
```

### 1.2 命名规范
| 类型 | 规则 | 示例 |
|------|------|------|
| 变量 | snake_case（小写下划线） | `local player_health` |
| 函数 | snake_case | `function calculate_damage()` |
| 类/模块 | PascalCase（大驼峰） | `local Logger = {}` |
| 常量 | UPPER_SNAKE_CASE | `local MAX_SPEED = 100` |
| 私有成员 | _下划线开头 | `local _internal_state = {}` |
| 文件名 | 全小写+下划线 | `scene_manager.lua` |

```lua
-- ✅ 正确的命名
local MAX_HEALTH = 100
local player_name = "张三"

local Player = {}
function Player:take_damage(amount)
    self.health = self.health - amount
end

-- ❌ 错误的命名
local maxHealth = 100   -- 驼峰，不符合Lua习惯
local PlayerName = "李四" -- 变量用了大驼峰
function player:TakeDamage() end -- 混合风格
```

**为什么用snake_case不用camelCase？**
Lua标准库和大部分Lua项目都是snake_case风格，入乡随俗，跟社区保持一致。类比Python的命名风格。

### 1.3 空格
- 运算符前后加空格
- 逗号后面加空格
- 函数参数括号前后不加空格
- 表的大括号内侧不加空格

```lua
-- ✅ 正确
local sum = a + b
local result = calculate(1, 2, 3)
local t = {x = 1, y = 2}

-- ❌ 错误
local sum=a+b
local result = calculate( 1 , 2 , 3 )
local t = { x = 1, y = 2 }
```

### 1.4 注释
- 单行注释用 `--`，后面跟一个空格
- 多行注释用 `--[[ ... ]]`
- 注释要有意义，不要解释"代码在做什么"，要解释"为什么这么做"
- Lua特有语法或LÖVE2D API的地方，加JS/Java/Python类比说明

```lua
-- ✅ 好的注释
-- 限制最大速度，防止穿墙
if speed > MAX_SPEED then
    speed = MAX_SPEED
end

-- ❌ 坏的注释（废话）
-- 如果速度大于最大速度，就设为最大速度
if speed > MAX_SPEED then
    speed = MAX_SPEED
end

-- ✅ 带类比的注释（对Lua初学者友好）
-- metatable 类似于 JS 的 prototype 或 Java 的父类
-- 用来实现继承和运算符重载
setmetatable(Player, {__index = Entity})
```

### 1.5 局部变量优先
- **尽量用local，少用全局变量**
- 全局变量越少越好，污染全局作用域是万恶之源
- 全局变量统一放在config或者专门的模块里

```lua
-- ✅ 正确（局部变量）
local score = 0

-- ❌ 错误（全局变量）
score = 0
```

类比：
- Lua的local ≈ JS的let/const，或Java的局部变量
- Lua的全局变量 ≈ JS的window.xxx，或Java的静态变量，能不用就不用

---

## 二、文件结构规范

### 2.1 文件头部
每个文件开头都要有文件说明注释：

```lua
--[[
    文件名：logger.lua
    功能：日志系统，提供分级日志输出
    作者：wren
    创建日期：2026-06-09
]]
```

### 2.2 模块结构
每个模块按这个顺序组织：
1. 文件头注释
2. require 其他模块
3. 常量定义
4. 模块表定义
5. 私有函数（下划线开头）
6. 公有方法
7. return 模块表

```lua
-- 文件头注释...

-- 1. 依赖导入
local Utils = require("core.utils")

-- 2. 常量
local LOG_LEVEL_DEBUG = 0
local LOG_LEVEL_INFO = 1

-- 3. 模块表
local Logger = {}
Logger._level = LOG_LEVEL_INFO

-- 4. 私有函数
local function _format_message(level, msg)
    -- ...
end

-- 5. 公有方法
function Logger.info(msg)
    print(_format_message("INFO", msg))
end

-- 6. 返回模块
return Logger
```

类比：
- 一个Lua模块 ≈ 一个JS模块 / 一个Java类
- return 出来的东西就是对外暴露的API

### 2.3 类的写法（面向对象）
Lua没有内置的class，用metatable模拟。统一写法：

```lua
local BaseScene = {}
BaseScene.__index = BaseScene  -- 关键：index指向自己

-- 构造函数
function BaseScene.new()
    local self = setmetatable({}, BaseScene)
    self.name = "base"
    self._entered = false
    return self
end

-- 方法
function BaseScene:enter(params)
    -- 注意这里用冒号:，第一个参数是self
    self._entered = true
end

return BaseScene
```

**冒号语法说明：**
- `obj:method(args)` 等价于 `obj.method(obj, args)`
- 冒号会自动把self作为第一个参数传进去
- 类比：JS的this，Python的self，Java的this

**继承的写法：**

```lua
local MenuScene = {}
MenuScene.__index = MenuScene

-- 继承 BaseScene
setmetatable(MenuScene, {__index = BaseScene})  -- 父类的方法能被子类调用

function MenuScene.new()
    local self = BaseScene.new()  -- 先调用父类构造
    setmetatable(self, MenuScene)  -- 再改成子类的metatable
    self.name = "menu"
    return self
end

-- 重写父类方法
function MenuScene:enter(params)
    BaseScene.enter(self, params)  -- 调用父类方法，注意用点.，手动传self
    -- 子类自己的逻辑...
end
```

类比：
- 这就相当于 `class MenuScene extends BaseScene`
- `BaseScene.enter(self, params)` 相当于 `super.enter(params)`

---

## 三、架构规范

### 3.1 分层依赖规则
**上层可以调用下层，下层绝对不能调用上层**

```
业务层 → 场景层 → 系统层 → 核心层 → LÖVE2D
 ✅ 可以往下调用
 ❌ 绝对不能往上调用
 ❌ 不能跨层乱调用
```

**具体来说：**
- core层不能引用systems、scenes、entities里的任何东西
- systems层不能引用scenes、entities里的业务代码
- scenes层可以引用systems和core，但不能直接引用entities的具体实现（通过事件通信）
- entities/game是最上层，可以引用下面所有层

**检查方法：**
看一个文件的require列表，只能require下层的模块，不能require上层的。

### 3.2 事件驱动，减少直接依赖
模块之间尽量通过EventBus通信，不要直接持有对方的引用。

```lua
-- ✅ 好的方式（松耦合）
-- A模块发事件
EventBus:publish("piece_moved", {from = from, to = to})

-- B模块听事件
EventBus:subscribe("piece_moved", function(data)
    -- 处理
end)

-- ❌ 坏的方式（紧耦合）
-- A直接调用B
b:on_piece_moved(from, to)
```

什么时候用直接调用？
- 同层内部，紧密相关的
- 性能要求极高的（事件有一点点开销，但一般可以忽略）
- 明确是从属关系的（比如场景里的渲染器，就是场景的一部分）

### 3.3 配置外置，不要硬编码
所有可调参数都放到Config模块里，不要在代码里写死数字。

```lua
-- ✅ 正确
function move_piece(piece, target_x, target_y)
    local move_time = Config.animation.piece_move_time
    -- ...
end

-- ❌ 错误（硬编码魔法数字）
function move_piece(piece, target_x, target_y)
    local move_time = 0.3  -- 这是啥？为什么是0.3？
    -- ...
end
```

类比：
- 就像前端把样式抽成CSS变量
- 或者Java里的配置文件
- 改参数不用翻代码，直接去config里改

### 3.4 错误处理
- 重要操作要用pcall保护，不要让游戏崩掉
- 出错了打ERROR日志，方便排查
- 不要吞错误，至少要打日志

```lua
-- ✅ 正确
local ok, err = pcall(function()
    do_something_risky()
end)
if not ok then
    Logger.error("操作失败：" .. tostring(err))
end

-- ❌ 错误（吞掉了错误）
pcall(function()
    do_something_risky()
end)
-- 出错了完全不知道
```

类比：
- pcall ≈ try-catch
- 第一个返回值是是否成功，第二个是错误信息

---

## 四、性能规范（V0阶段不用太在意，先写对再说）

### 4.1 少在update里创建对象
- love.update每帧都跑，不要在里面创建新的table
- 尽量复用对象，或者放在外面创建

```lua
-- ✅ 好的做法
local temp_vec = {x = 0, y = 0}  -- 外面创建，复用

function update(dt)
    temp_vec.x = player.x
    temp_vec.y = player.y
    -- 使用temp_vec
end

-- ❌ 不好的做法
function update(dt)
    local temp_vec = {x = player.x, y = player.y}  -- 每帧都创建新table
    -- 使用
end
```

### 4.2 图片资源要缓存
- 不要每帧都加载图片
- 用ResourceManager统一管理

### 4.3 减少全局变量访问
- 全局变量访问比局部变量慢
- 常用的全局函数可以存成局部变量

```lua
-- 常用的可以本地化
local math_sin = math.sin
local love_draw = love.graphics.draw
```

---

## 五、Git 规范

### 5.1 commit message 格式
```
<类型>: <简短描述>

<详细描述（可选）>
```

类型：
- feat: 新功能
- fix: 修复bug
- docs: 文档
- style: 代码格式调整
- refactor: 重构
- test: 测试
- chore: 构建/工具/依赖相关

示例：
```
feat: 实现日志系统分级输出

- 支持DEBUG/INFO/WARN/ERROR四个级别
- 不同级别不同颜色
- 可配置最低输出级别
```

### 5.2 分支
- master: 主分支，每个tag都在master上
- 开发的时候直接在master上也行，单人项目无所谓
- 大版本开发可以开feature分支，合并后删除

### 5.3 Tag
- 每个版本完成后打tag
- 格式：v0.0.1, v0.1.0, v1.0.0
- tag要打注释，说明这个版本做了什么

---

*文档版本：v0.0.1*
