-- ============================================================================
-- 场景管理器
-- 功能：管理游戏场景，场景切换、场景栈、生命周期管理
-- 类比：JS 的 React Router，Android 的 Activity 栈，iOS 的 ViewController 栈
-- 说明：每个场景是独立的"页面"，比如主菜单是一个场景，游戏中是另一个场景
-- ============================================================================

local Logger = require("src.core.logger")
local Utils = require("src.core.utils")

local SceneManager = {}
SceneManager.__index = SceneManager

-- ============================================================================
-- 创建场景管理器
-- @return SceneManager
-- ============================================================================
function SceneManager.new()
  local self = setmetatable({}, SceneManager)

  self.scenes = {}          -- 注册的场景：key=场景名，value=场景类/构造函数
  self.current_scene = nil  -- 当前场景对象
  self.current_scene_name = nil  -- 当前场景名
  self.scene_stack = {}     -- 场景栈（用于 push/pop，比如打开设置页）

  self.logger = Logger.get_default()

  return self
end

-- ============================================================================
-- 初始化
-- ============================================================================
function SceneManager:init()
  self.logger:info("[SceneManager] Initialized")
end

-- ============================================================================
-- 注册场景
-- @param string name 场景名
-- @param table scene_class 场景类，必须有 new() 方法，返回场景对象
-- ============================================================================
function SceneManager:register(name, scene_class)
  if not name or not scene_class then
    self.logger:error("[SceneManager] Register failed: name or scene_class is nil")
    return
  end

  self.scenes[name] = scene_class
  self.logger:debug("[SceneManager] Registered scene: " .. name)
end

-- ============================================================================
-- 切换到指定场景（替换当前场景）
-- @param string name 场景名
-- @param table params 传给场景的参数（可选）
-- ============================================================================
function SceneManager:switch(name, params)
  if not self.scenes[name] then
    self.logger:error("[SceneManager] Switch failed: scene not found - " .. tostring(name))
    return
  end

  -- 退出当前场景
  if self.current_scene then
    if self.current_scene.exit then
      self.current_scene:exit()
    end
    self.logger:debug("[SceneManager] Exit scene: " .. self.current_scene_name)
  end

  -- 创建新场景
  local scene_class = self.scenes[name]
  local new_scene = scene_class.new(params)

  -- 进入新场景
  self.current_scene = new_scene
  self.current_scene_name = name

  if new_scene.enter then
    new_scene:enter(params)
  end

  self.logger:info("[SceneManager] Switched to scene: " .. name)
end

-- ============================================================================
-- 把当前场景压入栈，切换到新场景（比如打开弹窗/设置页）
-- ============================================================================
function SceneManager:push(name, params)
  if self.current_scene then
    table.insert(self.scene_stack, {
      name = self.current_scene_name,
      scene = self.current_scene
    })
    -- 暂停当前场景
    if self.current_scene.pause then
      self.current_scene:pause()
    end
  end

  self:switch(name, params)
end

-- ============================================================================
-- 弹出栈顶场景，回到上一个场景
-- ============================================================================
function SceneManager:pop()
  if #self.scene_stack == 0 then
    self.logger:warn("[SceneManager] Pop failed: stack is empty")
    return
  end

  -- 退出当前场景
  if self.current_scene then
    if self.current_scene.exit then
      self.current_scene:exit()
    end
  end

  -- 取出栈顶的场景
  local top = table.remove(self.scene_stack)
  self.current_scene = top.scene
  self.current_scene_name = top.name

  -- 恢复场景
  if self.current_scene.resume then
    self.current_scene:resume()
  end

  self.logger:info("[SceneManager] Pop back to scene: " .. top.name)
end

-- ============================================================================
-- 每帧更新当前场景
-- ============================================================================
function SceneManager:update(dt)
  if self.current_scene and self.current_scene.update then
    self.current_scene:update(dt)
  end
end

-- ============================================================================
-- 绘制当前场景
-- ============================================================================
function SceneManager:draw()
  if self.current_scene and self.current_scene.draw then
    self.current_scene:draw()
  end
end

-- ============================================================================
-- 窗口大小改变
-- ============================================================================
function SceneManager:resize(w, h)
  if self.current_scene and self.current_scene.resize then
    self.current_scene:resize(w, h)
  end
end

-- ============================================================================
-- 退出所有场景（游戏退出时调用）
-- ============================================================================
function SceneManager:exit()
  if self.current_scene and self.current_scene.exit then
    self.current_scene:exit()
  end
  self.current_scene = nil
  self.current_scene_name = nil

  -- 清空栈
  for _, item in ipairs(self.scene_stack) do
    if item.scene.exit then
      item.scene:exit()
    end
  end
  self.scene_stack = {}
end

-- ============================================================================
-- 获取当前场景
-- ============================================================================
function SceneManager:get_current()
  return self.current_scene, self.current_scene_name
end

-- ============================================================================
-- 获取栈深度
-- ============================================================================
function SceneManager:get_stack_depth()
  return #self.scene_stack + (self.current_scene and 1 or 0)
end

-- ============================================================================
-- 全局默认场景管理器实例
-- ============================================================================
local _default_manager = nil

function SceneManager.get_default()
  if not _default_manager then
    _default_manager = SceneManager.new()
  end
  return _default_manager
end

-- 快捷方法
function SceneManager.init()
  SceneManager.get_default():init()
end
function SceneManager.register(name, scene_class)
  SceneManager.get_default():register(name, scene_class)
end
function SceneManager.switch(name, params)
  SceneManager.get_default():switch(name, params)
end
function SceneManager.push(name, params)
  SceneManager.get_default():push(name, params)
end
function SceneManager.pop()
  SceneManager.get_default():pop()
end
function SceneManager.update(dt)
  SceneManager.get_default():update(dt)
end
function SceneManager.draw()
  SceneManager.get_default():draw()
end
function SceneManager.resize(w, h)
  SceneManager.get_default():resize(w, h)
end
function SceneManager.exit()
  SceneManager.get_default():exit()
end

return SceneManager
