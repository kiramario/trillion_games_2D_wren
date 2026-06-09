-- ============================================================================
-- 渲染管理器
-- 功能：分层渲染管理，按层排序，自动应用相机变换
-- 类比：Photoshop 的图层，Unity 的 Sorting Layer
-- 说明：所有要绘制的东西都加到渲染管理器，它会自动按层和 z-index 排序绘制
-- ============================================================================

local Logger = require("core.logger")
local Utils = require("core.utils")
local Camera = require("core.camera")

local RenderManager = {}
RenderManager.__index = RenderManager

-- 默认的渲染层（顺序很重要，先画的在下面）
local DEFAULT_LAYERS = {
  "background",     -- 最底层：背景
  "world_back",     -- 世界底层：地板、棋盘等
  "world_mid",      -- 世界中层：棋子、角色等
  "world_front",    -- 世界上层：特效、粒子等
  "ui"              -- 最上层：UI，不受相机影响
}

-- ============================================================================
-- 创建渲染管理器
-- @param table params
-- @return RenderManager
-- ============================================================================
function RenderManager.new(params)
  params = params or {}

  local self = setmetatable({}, RenderManager)

  -- 相机（世界层用）
  self.camera = params.camera or Camera.new()

  -- 渲染项：按层分组
  self.layers = {}
  self.layer_order = params.layers or DEFAULT_LAYERS

  -- 初始化每一层的渲染项列表
  for _, layer_name in ipairs(self.layer_order) do
    self.layers[layer_name] = {}
  end

  -- 调试模式
  self.debug_mode = false

  self.logger = Logger.get_default()

  return self
end

-- ============================================================================
-- 清空所有渲染项
-- 每帧开始的时候调用
-- ============================================================================
function RenderManager:clear()
  for _, layer_name in ipairs(self.layer_order) do
    self.layers[layer_name] = {}
  end
end

-- ============================================================================
-- 添加一个实体到渲染队列
-- 实体会按 layer 和 z_index 排序
-- ============================================================================
function RenderManager:add_entity(entity)
  if not entity then return end

  local layer = entity.layer or "world_mid"
  local z_index = entity.z_index or 0

  if not self.layers[layer] then
    self.logger:warn("[RenderManager] Unknown layer: " .. layer)
    return
  end

  table.insert(self.layers[layer], {
    type = "entity",
    obj = entity,
    z_index = z_index
  })
end

-- ============================================================================
-- 添加一个自定义绘制函数
-- 有时候不想做实体，直接画个东西，就用这个
-- ============================================================================
function RenderManager:add_draw(layer, draw_func, z_index)
  if not self.layers[layer] then
    self.logger:warn("[RenderManager] Unknown layer: " .. layer)
    return
  end

  table.insert(self.layers[layer], {
    type = "draw",
    func = draw_func,
    z_index = z_index or 0
  })
end

-- ============================================================================
-- 添加一个图层（在指定位置插入）
-- ============================================================================
function RenderManager:add_layer(name, position)
  if self.layers[name] then
    return  -- 已经存在了
  end

  position = position or #self.layer_order + 1
  table.insert(self.layer_order, position, name)
  self.layers[name] = {}
end

-- ============================================================================
-- 按 z_index 排序一层里的所有项
-- ============================================================================
local function _sort_layer_items(items)
  table.sort(items, function(a, b)
    return a.z_index < b.z_index
  end)
end

-- ============================================================================
-- 执行渲染
-- 每帧调用一次
-- ============================================================================
function RenderManager:draw()
  -- 按层顺序绘制
  for _, layer_name in ipairs(self.layer_order) do
    local items = self.layers[layer_name]
    if #items > 0 then
      -- 按 z_index 排序
      _sort_layer_items(items)

      -- 判断是不是 UI 层（UI 层不用相机变换）
      local is_ui_layer = (layer_name == "ui")

      if not is_ui_layer then
        -- 世界层：应用相机变换
        self.camera:apply()
      end

      -- 绘制这一层的所有项
      for _, item in ipairs(items) do
        if item.type == "entity" then
          if item.obj.draw and item.obj.visible then
            item.obj:draw()
          end
        elseif item.type == "draw" then
          if item.func then
            item.func()
          end
        end
      end

      if not is_ui_layer then
        -- 恢复相机变换
        self.camera:reset()
      end
    end
  end

  -- 调试信息
  if self.debug_mode then
    self:_draw_debug_info()
  end
end

-- ============================================================================
-- 绘制调试信息
-- ============================================================================
function RenderManager:_draw_debug_info()
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", love.graphics.getWidth() - 220, 10, 210, 120)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("渲染管理器（调试）", love.graphics.getWidth() - 210, 20)
  love.graphics.print(string.format("相机位置: (%.1f, %.1f)", self.camera.x, self.camera.y), love.graphics.getWidth() - 210, 40)
  love.graphics.print(string.format("缩放: %.2fx", self.camera.zoom), love.graphics.getWidth() - 210, 60)

  -- 统计每层的渲染项数量
  local y = 80
  for i, layer_name in ipairs(self.layer_order) do
    local count = #self.layers[layer_name]
    love.graphics.print(string.format("%s: %d 项", layer_name, count), love.graphics.getWidth() - 210, y)
    y = y + 15
  end
end

-- ============================================================================
-- 获取相机
-- ============================================================================
function RenderManager:get_camera()
  return self.camera
end

-- ============================================================================
-- 设置相机
-- ============================================================================
function RenderManager:set_camera(camera)
  self.camera = camera
end

-- ============================================================================
-- 全局默认渲染管理器
-- ============================================================================
local _default_manager = nil

function RenderManager.get_default()
  if not _default_manager then
    _default_manager = RenderManager.new()
  end
  return _default_manager
end

-- 快捷方法
function RenderManager.clear()
  RenderManager.get_default():clear()
end
function RenderManager.add_entity(entity)
  RenderManager.get_default():add_entity(entity)
end
function RenderManager.add_draw(layer, func, z)
  RenderManager.get_default():add_draw(layer, func, z)
end
function RenderManager.draw()
  RenderManager.get_default():draw()
end
function RenderManager.get_camera()
  return RenderManager.get_default():get_camera()
end

return RenderManager
