# 06. 代码规范

## 为什么要有代码规范

独立开发也需要代码规范，原因：
1. **过几个月回来还能看懂**：自己写的代码，时间长了也会忘，规范的代码好维护
2. **减少 Bug**：统一的写法不容易出低级错误
3. **方便扩展**：结构清晰的代码加新功能不容易乱
4. **如果以后开源或者找人协作**：规范的代码别人看得懂

---

## 命名规范

### 文件和目录
- 全小写，用下划线分隔（snake_case）
- 不用拼音，不用缩写（除非是大家都认识的缩写，比如 ui、api、utils）
- 文件名和里面的模块名对应

✅ 正确：
```
scene_manager.lua
game_play.lua
utils.lua
```

❌ 错误：
```
SceneManager.lua    # 驼峰
sceneManager.lua    # 小驼峰
场景管理.lua        # 中文
scn_mgr.lua         # 看不懂的缩写
```

### 变量
- 局部变量：snake_case，全小写，下划线分隔
- 全局变量：尽量少用全局变量，如果用的话全大写，下划线分隔
- 常量：全大写，下划线分隔

✅ 正确：
```lua
local player_health = 100
local move_speed = 200

MAX_LEVEL = 10
GAME_VERSION = "1.0.0"
```

❌ 错误：
```lua
local playerHealth = 100   # 驼峰，不统一
local PlayerHealth = 100   # 大驼峰
local pl_hp = 100          # 缩写看不懂
```

### 函数
- snake_case，动词开头
- 名字要能看出做什么的
- 私有函数（模块内部用的）可以加下划线前缀（约定俗成）

✅ 正确：
```lua
function move_player(x, y)
function get_player_health()
function _update_internal_state()  -- 私有函数，加下划线
```

❌ 错误：
```lua
function playerMove()       -- 驼峰
function move()             -- 太模糊，不知道移动什么
function do_stuff()         -- 太笼统
```

### 类/模块
- 虽然 Lua 没有类的概念，但我们模拟类的时候，文件名和模块名用 snake_case
- 构造函数一般叫 new()

✅ 正确：
```lua
local SceneManager = {}
function SceneManager.new()
```

### 布尔变量
- 用 is/has/can/should 等前缀，一看就知道是布尔值

✅ 正确：
```lua
local is_running = true
local has_skill = false
local can_move = true
local should_update = false
```

---

## 代码格式

### 缩进
- 用 2 个空格缩进（Lua 社区常用，也可以用 4 个，统一就行，我们选 2 个）
- 不要用 Tab，不同编辑器显示不一样

✅ 正确：
```lua
function hello()
  if true then
    print("hello")
  end
end
```

### 空行
- 不同逻辑块之间加空行分隔，不要堆在一起
- 函数之间加空行
- 文件末尾留一个空行

✅ 正确：
```lua
-- 初始化
local x = 0
local y = 0

-- 更新
function update(dt)
  x = x + 1
  y = y + 1
end

-- 绘制
function draw()
  love.graphics.rectangle("fill", x, y, 10, 10)
end
```

### 空格
- 运算符两边加空格
- 逗号后面加空格
- 括号内侧不加空格

✅ 正确：
```lua
local a = 1 + 2
function foo(a, b, c)
if x > 10 then
```

❌ 错误：
```lua
local a=1+2
function foo( a , b , c )
if x>10 then
```

### 行长度
- 每行尽量不超过 120 个字符
- 太长的话换行，缩进对齐

---

## Lua 语言特定规范

### 局部变量优先
- 尽量用 local，少用全局变量
- 全局变量会污染命名空间，而且访问比局部变量慢
- 只有真正需要全局访问的才放到全局

✅ 正确：
```lua
-- 模块内部用的，加 local
local utils = require("utils")

local function helper()
  -- ...
end
```

### require 放在文件开头
- 所有 require 都放在文件最上面，一目了然依赖了哪些模块
- 按顺序：先标准库，再核心模块，再业务模块

✅ 正确：
```lua
-- 标准库（如果有的话）
local math = require("math")

-- 核心模块
local Logger = require("src.core.logger")
local Utils = require("src.core.utils")

-- 业务模块
local Board = require("src.game.entities.board")
```

### 表（table）的写法
- 短的可以写一行
- 长的换行，每个键值对一行，最后一个后面也可以加逗号（Lua 允许，方便以后加）

✅ 正确：
```lua
-- 短的一行
local person = {name = "张三", age = 18}

-- 长的换行
local config = {
  width = 960,
  height = 640,
  title = "游戏",
  fullscreen = false,
}
```

### 注释
- 代码看不懂的地方一定要加注释
- 注释要说明"为什么这么做"，而不是"做了什么"（代码本身已经说明做了什么）
- 涉及 Lua 特有语法或者 LÖVE2D API 的地方，加类比说明（JS/Java/Python 视角）

✅ 正确：
```lua
-- 这里用闭包保存计数器，避免全局变量（类比 JS 的闭包）
local function create_counter()
  local count = 0
  return function()
    count = count + 1
    return count
  end
end
```

### 错误处理
- 可能出错的地方用 pcall 或者 xpcall
- 不要静默失败，至少打个错误日志

✅ 正确：
```lua
local ok, result = pcall(load_file, path)
if not ok then
  logger:error("加载文件失败: " .. tostring(result))
  return nil
end
```

---

## 模块规范

### 模块结构
每个模块（文件）的结构尽量统一：
1. 模块说明注释（这个模块是做什么的）
2. require 其他模块
3. 模块变量和常量
4. 内部辅助函数（私有，加下划线前缀）
5. 模块公开函数/方法
6. 构造函数 new()（如果是类的话）
7. 返回模块

示例：
```lua
-- ============================================================================
-- 模块名：场景管理器
-- 功能：管理所有游戏场景，负责场景切换、生命周期管理
-- 类比：JS 的 React Router / Java 的 Activity 栈
-- ============================================================================

local Logger = require("src.core.logger")
local Utils = require("src.core.utils")

local SceneManager = {}
SceneManager.__index = SceneManager

-- 内部变量
local _instance = nil

-- 内部辅助函数
local function _validate_scene(scene)
  -- ...
end

-- 公开方法
function SceneManager.new()
  local self = setmetatable({}, SceneManager)
  -- ...
  return self
end

function SceneManager:switch(scene_name, params)
  -- ...
end

-- 单例模式
function SceneManager.get_default()
  if not _instance then
    _instance = SceneManager.new()
  end
  return _instance
end

return SceneManager
```

### 类的写法
- 用 setmetatable + __index 的方式模拟类
- 构造函数叫 new()
- 方法用冒号语法（self 是第一个参数）
- 继承的话，子类的 metatable 指向父类

### 依赖关系
- 核心层（core/）绝对不能依赖业务层（game/）
- 同层模块之间尽量减少循环依赖
- 依赖方向只能是：业务层 → 核心层，不能反过来

---

## 注释规范（代码里的注释）

### 文件头注释
每个文件开头都要有模块说明注释，说明这个文件是做什么的，类比其他语言的什么东西。

### 函数注释
复杂的函数要加注释，说明：
- 函数功能
- 参数是什么，类型是什么
- 返回值是什么，类型是什么
- 有什么副作用

示例：
```lua
-- ============================================================================
-- 移动棋子到指定位置
-- @param Piece piece 要移动的棋子
-- @param number target_col 目标列
-- @param number target_row 目标行
-- @return boolean 是否移动成功
-- ============================================================================
function move_piece(piece, target_col, target_row)
  -- ...
end
```

### 行内注释
- 复杂的逻辑旁边加行内注释
- 不要每行都加注释，只加在需要解释的地方
- 注释不要重复代码说的内容

✅ 正确：
```lua
-- 乘以 0.98 是为了模拟摩擦力，速度逐渐衰减
velocity = velocity * 0.98
```

❌ 错误：
```lua
-- 速度乘以 0.98
velocity = velocity * 0.98
```

---

## 最佳实践

### 1. 函数不要太长
- 一个函数尽量只做一件事
- 超过 50 行的函数考虑拆成几个小函数
- 函数名就是最好的注释，好的命名胜过一堆注释

### 2. 魔法数字要命名
- 代码里不要直接出现奇怪的数字，用常量代替
- 看到数字不知道是什么意思的，都要命名

✅ 正确：
```lua
local MAX_HEALTH = 100
local MOVE_SPEED = 200
local GRAVITY = 9.8
```

❌ 错误：
```lua
if health > 100 then  -- 100 是什么？
speed = 200           -- 200 是什么单位？
```

### 3. 提前返回，减少嵌套
- 条件判断尽量早返回，减少嵌套层级

✅ 正确：
```lua
function can_move(piece, x, y)
  if not piece then
    return false
  end
  
  if piece.dead then
    return false
  end
  
  if not is_inside_board(x, y) then
    return false
  end
  
  -- 真正的逻辑
  return true
end
```

❌ 错误：
```lua
function can_move(piece, x, y)
  if piece then
    if not piece.dead then
      if is_inside_board(x, y) then
        -- 真正的逻辑
        return true
      else
        return false
      end
    else
      return false
    end
  else
    return false
  end
end
```

### 4. 不要过早优化
- 先写对，再写快
- 先让功能跑起来，再考虑优化
- 只有确定是性能瓶颈的地方才优化
- 可读性永远比微小的性能提升重要

### 5. 复用代码，但不要过度抽象
- 重复的代码可以抽成函数或模块
- 但是不要为了复用而过度设计
- 重复 3 次以上再考虑抽出来
- YAGNI 原则：你不会需要它的，就不要提前做

---

## 提交规范

### Commit 信息
- 格式：`类型: 简短描述`
- 类型：feat（新功能）、fix（修复）、docs（文档）、style（格式）、refactor（重构）、test（测试）、chore（构建/工具）

示例：
```
feat: 实现棋子移动动画
fix: 修复马走日规则判断错误
docs: 更新版本路线图
refactor: 重构规则引擎，提取公共函数
chore: 添加构建脚本
```

### 提交粒度
- 一个 commit 做一件事
- 不要把不相关的改动放到一个 commit 里
- 每个 commit 都应该是可运行的

### Tag
- 每个版本打一个 tag
- 格式：vX.Y.Z，比如 v0.1.0、v1.0.0
- 打 tag 之前确保代码可运行

---

## 总结

规范是为了让代码更好维护，不是为了束缚。

**核心原则：**
1. 清晰易读最重要
2. 保持统一，不要一会儿这样一会儿那样
3. 写代码的时候想想，过三个月的自己能不能看懂
4. 不要教条，特殊情况特殊处理，但尽量少特殊情况
