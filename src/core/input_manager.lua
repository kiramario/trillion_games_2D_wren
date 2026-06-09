-- ============================================================================
-- 输入管理器
-- 功能：统一管理键盘、鼠标输入，支持按键映射、按下/按住/松开状态查询
-- 类比：JS 的事件监听封装，Unity 的 Input 系统
-- 说明：LÖVE2D 自己的键盘事件是 love.keypressed/keyreleased，
--       我们封装一下，方便查询某一帧内的按键状态
-- ============================================================================

local Logger = require("core.logger")
local Utils = require("core.utils")

local InputManager = {}
InputManager.__index = InputManager

-- ============================================================================
-- 创建输入管理器
-- @return InputManager
-- ============================================================================
function InputManager.new()
  local self = setmetatable({}, InputManager)

  -- 键盘状态
  self.keys = {}              -- 当前按住的键
  self.keys_pressed = {}      -- 这一帧刚按下的键
  self.keys_released = {}     -- 这一帧刚松开的键

  -- 鼠标状态
  self.mouse_x = 0
  self.mouse_y = 0
  self.mouse_buttons = {}       -- 鼠标按钮状态
  self.mouse_pressed = {}       -- 这一帧刚按下的按钮
  self.mouse_released = {}      -- 这一帧刚松开的按钮
  self.mouse_wheel_x = 0        -- 滚轮横向滚动
  self.mouse_wheel_y = 0        -- 滚轮纵向滚动

  -- 按键映射（逻辑键名 -> 物理按键）
  self.key_map = {}

  self.logger = Logger.get_default()

  return self
end

-- ============================================================================
-- 初始化
-- ============================================================================
function InputManager:init()
  -- 设置默认按键映射，后面可以从配置里读
  self.key_map = {
    cancel = "escape",
    confirm = "return",
    reset = "r",
    view_1p = "1",
    view_2p = "2"
  }

  self.logger:info("[InputManager] Initialized")
end

-- ============================================================================
-- 每帧更新（清空上一帧的 pressed/released 状态）
-- 这个必须每帧调用，放在 love.update 最前面
-- ============================================================================
function InputManager:update(dt)
  -- 清空"刚按下"和"刚松开"的状态，这些只在一帧内有效
  for k in pairs(self.keys_pressed) do
    self.keys_pressed[k] = false
  end
  for k in pairs(self.keys_released) do
    self.keys_released[k] = false
  end

  for b in pairs(self.mouse_pressed) do
    self.mouse_pressed[b] = false
  end
  for b in pairs(self.mouse_released) do
    self.mouse_released[b] = false
  end

  -- 滚轮也每帧清空
  self.mouse_wheel_x = 0
  self.mouse_wheel_y = 0
end

-- ============================================================================
-- 键盘按下事件（由 love.keypressed 调用）
-- ============================================================================
function InputManager:keypressed(key, scancode, isrepeat)
  if not self.keys[key] then
    self.keys_pressed[key] = true
  end
  self.keys[key] = true
end

-- ============================================================================
-- 键盘松开事件（由 love.keyreleased 调用）
-- ============================================================================
function InputManager:keyreleased(key, scancode)
  self.keys[key] = false
  self.keys_released[key] = true
end

-- ============================================================================
-- 检查某个键是否正在按住
-- @param string key 键名，或者逻辑按键名
-- @return boolean
-- ============================================================================
function InputManager:is_key_down(key)
  -- 先查是不是逻辑按键
  local physical_key = self.key_map[key]
  if physical_key then
    return self.keys[physical_key] == true
  end
  -- 直接是物理键名
  return self.keys[key] == true
end

-- ============================================================================
-- 检查某个键在这一帧是否刚按下（只触发一次）
-- ============================================================================
function InputManager:is_key_pressed(key)
  local physical_key = self.key_map[key]
  if physical_key then
    return self.keys_pressed[physical_key] == true
  end
  return self.keys_pressed[key] == true
end

-- ============================================================================
-- 检查某个键在这一帧是否刚松开
-- ============================================================================
function InputManager:is_key_released(key)
  local physical_key = self.key_map[key]
  if physical_key then
    return self.keys_released[physical_key] == true
  end
  return self.keys_released[key] == true
end

-- ============================================================================
-- 鼠标按下事件
-- ============================================================================
function InputManager:mousepressed(x, y, button, istouch, presses)
  if not self.mouse_buttons[button] then
    self.mouse_pressed[button] = true
  end
  self.mouse_buttons[button] = true
  self.mouse_x = x
  self.mouse_y = y
end

-- ============================================================================
-- 鼠标松开事件
-- ============================================================================
function InputManager:mousereleased(x, y, button, istouch, presses)
  self.mouse_buttons[button] = false
  self.mouse_released[button] = true
  self.mouse_x = x
  self.mouse_y = y
end

-- ============================================================================
-- 鼠标移动事件
-- ============================================================================
function InputManager:mousemoved(x, y, dx, dy, istouch)
  self.mouse_x = x
  self.mouse_y = y
end

-- ============================================================================
-- 鼠标滚轮事件
-- ============================================================================
function InputManager:wheelmoved(x, y)
  self.mouse_wheel_x = x
  self.mouse_wheel_y = y
end

-- ============================================================================
-- 获取鼠标位置
-- ============================================================================
function InputManager:get_mouse_position()
  return self.mouse_x, self.mouse_y
end

-- ============================================================================
-- 检查鼠标按钮是否按住
-- @param number button 1=左键, 2=右键, 3=中键
-- ============================================================================
function InputManager:is_mouse_down(button)
  return self.mouse_buttons[button] == true
end

-- ============================================================================
-- 检查鼠标按钮是否刚按下
-- ============================================================================
function InputManager:is_mouse_pressed(button)
  return self.mouse_pressed[button] == true
end

-- ============================================================================
-- 检查鼠标按钮是否刚松开
-- ============================================================================
function InputManager:is_mouse_released(button)
  return self.mouse_released[button] == true
end

-- ============================================================================
-- 获取鼠标滚轮滚动量
-- ============================================================================
function InputManager:get_mouse_wheel()
  return self.mouse_wheel_x, self.mouse_wheel_y
end

-- ============================================================================
-- 设置按键映射
-- ============================================================================
function InputManager:set_key_map(action, key)
  self.key_map[action] = key
end

-- ============================================================================
-- 获取按键映射
-- ============================================================================
function InputManager:get_key_map(action)
  return self.key_map[action]
end

-- ============================================================================
-- 全局默认输入管理器实例
-- ============================================================================
local _default_input = InputManager.new()

function InputManager.get_default()
  return _default_input
end

-- 快捷方法
function InputManager.init()
  _default_input:init()
end
function InputManager.update(dt)
  _default_input:update(dt)
end
function InputManager.keypressed(...)
  _default_input:keypressed(...)
end
function InputManager.keyreleased(...)
  _default_input:keyreleased(...)
end
function InputManager.mousepressed(...)
  _default_input:mousepressed(...)
end
function InputManager.mousereleased(...)
  _default_input:mousereleased(...)
end
function InputManager.mousemoved(...)
  _default_input:mousemoved(...)
end
function InputManager.wheelmoved(...)
  _default_input:wheelmoved(...)
end
function InputManager.is_key_down(key)
  return _default_input:is_key_down(key)
end
function InputManager.is_key_pressed(key)
  return _default_input:is_key_pressed(key)
end
function InputManager.is_key_released(key)
  return _default_input:is_key_released(key)
end
function InputManager.get_mouse_position()
  return _default_input:get_mouse_position()
end
function InputManager.is_mouse_down(btn)
  return _default_input:is_mouse_down(btn)
end
function InputManager.is_mouse_pressed(btn)
  return _default_input:is_mouse_pressed(btn)
end
function InputManager.get_mouse_wheel()
  return _default_input:get_mouse_wheel()
end

return InputManager
