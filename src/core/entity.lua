-- ============================================================================
-- 实体基类
-- 功能：所有游戏对象的基类，有位置、大小、缩放、旋转、颜色等属性
-- 类比：Unity 的 GameObject，Godot 的 Node2D，JS 游戏里的 Entity 类
-- 说明：所有可见的游戏对象（棋子、棋盘、UI、特效等）都继承这个类
-- ============================================================================

local Utils = require("core.utils")

local Entity = {}
Entity.__index = Entity

-- ============================================================================
-- 创建新实体
-- @param table params 参数：x, y, width, height, layer 等
-- @return Entity
-- ============================================================================
function Entity.new(params)
  params = params or {}

  local self = setmetatable({}, Entity)

  -- 位置（左上角坐标）
  self.x = params.x or 0
  self.y = params.y or 0

  -- 大小
  self.width = params.width or 0
  self.height = params.height or 0

  -- 缩放
  self.scale_x = params.scale_x or 1
  self.scale_y = params.scale_y or 1

  -- 旋转（弧度）
  self.rotation = params.rotation or 0

  -- 锚点（0~1，默认左上角）
  self.anchor_x = params.anchor_x or 0
  self.anchor_y = params.anchor_y or 0

  -- 透明度（0~1）
  self.alpha = params.alpha or 1

  -- 颜色（RGBA，0~1）
  self.color = params.color or {1, 1, 1, 1}

  -- 渲染层（决定绘制顺序，数值大的在上面）
  self.layer = params.layer or "world_mid"
  self.z_index = params.z_index or 0  -- 同层内的排序

  -- 是否可见
  self.visible = true

  -- 是否激活（参与更新和渲染）
  self.active = true

  -- 父实体（可选）
  self.parent = nil
  self.children = {}  -- 子实体列表

  -- 实体 ID（自动生成）
  self._id = Entity._next_id()
  self._name = params.name or "entity_" .. self._id

  return self
end

-- 自增 ID 计数器
local _entity_id_counter = 0
function Entity._next_id()
  _entity_id_counter = _entity_id_counter + 1
  return _entity_id_counter
end

-- ============================================================================
-- 每帧更新
-- 子类可以重写这个方法
-- ============================================================================
function Entity:update(dt)
  -- 基类里什么都不做，子类重写
  -- 更新子实体
  for _, child in ipairs(self.children) do
    if child.update and child.active then
      child:update(dt)
    end
  end
end

-- ============================================================================
-- 绘制
-- 子类可以重写这个方法
-- ============================================================================
function Entity:draw()
  if not self.visible or self.alpha <= 0 then
    return
  end

  -- 保存当前绘制状态
  love.graphics.push()

  -- 变换：先平移，再旋转，再缩放（顺序很重要）
  local draw_x = self.x + self.width * self.anchor_x
  local draw_y = self.y + self.height * self.anchor_y

  love.graphics.translate(draw_x, draw_y)
  love.graphics.rotate(self.rotation)
  love.graphics.scale(self.scale_x, self.scale_y)

  -- 设置颜色和透明度
  local r, g, b, a = unpack(self.color)
  love.graphics.setColor(r, g, b, a * self.alpha)

  -- 实际绘制内容，子类重写
  self:_draw_content()

  -- 绘制子实体
  for _, child in ipairs(self.children) do
    if child.draw and child.visible then
      child:draw()
    end
  end

  -- 恢复绘制状态
  love.graphics.pop()
end

-- ============================================================================
-- 绘制实体内容（子类重写这个方法）
-- 注意：这个方法里的坐标是相对于实体锚点的
-- ============================================================================
function Entity:_draw_content()
  -- 基类里画个默认的矩形，方便调试
  love.graphics.rectangle(
    "line",
    -self.width * self.anchor_x,
    -self.height * self.anchor_y,
    self.width,
    self.height
  )
end

-- ============================================================================
-- 移动实体
-- ============================================================================
function Entity:move(dx, dy)
  self.x = self.x + dx
  self.y = self.y + dy
end

-- ============================================================================
-- 设置位置
-- ============================================================================
function Entity:set_position(x, y)
  self.x = x
  self.y = y
end

-- ============================================================================
-- 获取中心位置
-- ============================================================================
function Entity:get_center()
  return self.x + self.width / 2, self.y + self.height / 2
end

-- ============================================================================
-- 设置大小
-- ============================================================================
function Entity:set_size(width, height)
  self.width = width
  self.height = height
end

-- ============================================================================
-- 设置缩放
-- ============================================================================
function Entity:set_scale(scale_x, scale_y)
  scale_y = scale_y or scale_x
  self.scale_x = scale_x
  self.scale_y = scale_y
end

-- ============================================================================
-- 设置旋转（角度制，方便用）
-- ============================================================================
function Entity:set_rotation_deg(deg)
  self.rotation = Utils.deg_to_rad(deg)
end

-- ============================================================================
-- 设置透明度
-- ============================================================================
function Entity:set_alpha(alpha)
  self.alpha = Utils.clamp(alpha, 0, 1)
end

-- ============================================================================
-- 设置颜色
-- ============================================================================
function Entity:set_color(r, g, b, a)
  self.color = {r, g, b, a or self.color[4]}
end

-- ============================================================================
-- 点是否在实体范围内（碰撞检测用）
-- ============================================================================
function Entity:contains_point(px, py)
  return px >= self.x and px <= self.x + self.width and
         py >= self.y and py <= self.y + self.height
end

-- ============================================================================
-- 添加子实体
-- ============================================================================
function Entity:add_child(child)
  if not child then return end
  table.insert(self.children, child)
  child.parent = self
end

-- ============================================================================
-- 移除子实体
-- ============================================================================
function Entity:remove_child(child)
  for i, c in ipairs(self.children) do
    if c == child then
      table.remove(self.children, i)
      child.parent = nil
      return
    end
  end
end

-- ============================================================================
-- 销毁实体
-- ============================================================================
function Entity:destroy()
  self.active = false
  self.visible = false
  -- 销毁所有子实体
  for _, child in ipairs(self.children) do
    if child.destroy then
      child:destroy()
    end
  end
  self.children = {}
  if self.parent then
    self.parent:remove_child(self)
  end
end

-- ============================================================================
-- 静态方法：获取下一个实体 ID
-- ============================================================================
function Entity.get_total_count()
  return _entity_id_counter
end

return Entity
