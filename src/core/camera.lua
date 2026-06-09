-- ============================================================================
-- 相机系统
-- 功能：控制视图的位移、缩放、震动，实现镜头效果
-- 类比：Unity 的 Camera，电影里的摄像机
-- 说明：世界里的对象坐标是固定的，相机移动，看到的部分就不一样
-- ============================================================================

local Utils = require("core.utils")
local Logger = require("core.logger")

local Camera = {}
Camera.__index = Camera

-- ============================================================================
-- 创建相机
-- @param table params x, y, zoom 等
-- @return Camera
-- ============================================================================
function Camera.new(params)
  params = params or {}

  local self = setmetatable({}, Camera)

  -- 相机位置（世界坐标，相机中心点）
  self.x = params.x or 0
  self.y = params.y or 0

  -- 目标位置（平滑移动用）
  self.target_x = self.x
  self.target_y = self.y

  -- 缩放倍数（1=正常，>1=放大，<1=缩小）
  self.zoom = params.zoom or 1
  self.target_zoom = self.zoom

  -- 旋转（弧度，一般 2D 游戏不用）
  self.rotation = 0

  -- 震动参数
  self.shake_intensity = 0  -- 震动强度
  self.shake_duration = 0   -- 震动持续时间（秒）
  self.shake_time = 0       -- 当前震动时间
  self.shake_x = 0          -- 当前震动偏移 X
  self.shake_y = 0          -- 当前震动偏移 Y

  -- 平滑移动速度（0~1，越大移动越快）
  self.smooth_speed = params.smooth_speed or 0.1

  -- 边界限制（可选）
  self.bounds = nil  -- {min_x, min_y, max_x, max_y}

  self.logger = Logger.get_default()

  return self
end

-- ============================================================================
-- 每帧更新
-- ============================================================================
function Camera:update(dt)
  -- 1. 平滑移动到目标位置
  self.x = Utils.lerp(self.x, self.target_x, self.smooth_speed)
  self.y = Utils.lerp(self.y, self.target_y, self.smooth_speed)

  -- 2. 平滑缩放
  self.zoom = Utils.lerp(self.zoom, self.target_zoom, self.smooth_speed)

  -- 3. 相机震动
  if self.shake_time > 0 then
    self.shake_time = self.shake_time - dt
    if self.shake_time <= 0 then
      -- 震动结束
      self.shake_intensity = 0
      self.shake_x = 0
      self.shake_y = 0
    else
      -- 随机偏移，模拟震动
      local progress = self.shake_time / self.shake_duration
      local current_intensity = self.shake_intensity * progress
      self.shake_x = Utils.random_float(-current_intensity, current_intensity)
      self.shake_y = Utils.random_float(-current_intensity, current_intensity)
    end
  end

  -- 4. 边界限制
  if self.bounds then
    self.x = Utils.clamp(self.x, self.bounds.min_x, self.bounds.max_x)
    self.y = Utils.clamp(self.y, self.bounds.min_y, self.bounds.max_y)
  end
end

-- ============================================================================
-- 开始相机震动
-- @param number intensity 震动强度（像素）
-- @param number duration 震动持续时间（秒）
-- ============================================================================
function Camera:shake(intensity, duration)
  self.shake_intensity = intensity
  self.shake_duration = duration
  self.shake_time = duration
end

-- ============================================================================
-- 设置相机位置（立即到位）
-- ============================================================================
function Camera:set_position(x, y)
  self.x = x
  self.y = y
  self.target_x = x
  self.target_y = y
end

-- ============================================================================
-- 移动相机到目标位置（平滑移动）
-- ============================================================================
function Camera:move_to(x, y)
  self.target_x = x
  self.target_y = y
end

-- ============================================================================
-- 移动相机（相对位移）
-- ============================================================================
function Camera:translate(dx, dy)
  self.target_x = self.target_x + dx
  self.target_y = self.target_y + dy
end

-- ============================================================================
-- 设置缩放（立即）
-- ============================================================================
function Camera:set_zoom(zoom)
  self.zoom = zoom
  self.target_zoom = zoom
end

-- ============================================================================
-- 平滑缩放到目标倍数
-- ============================================================================
function Camera:zoom_to(zoom)
  self.target_zoom = Utils.clamp(zoom, 0.1, 10)
end

-- ============================================================================
-- 相对缩放
-- ============================================================================
function Camera:zoom_by(factor)
  self:zoom_to(self.target_zoom * factor)
end

-- ============================================================================
-- 设置相机边界限制
-- ============================================================================
function Camera:set_bounds(min_x, min_y, max_x, max_y)
  self.bounds = {
    min_x = min_x,
    min_y = min_y,
    max_x = max_x,
    max_y = max_y
  }
end

-- ============================================================================
-- 清除边界限制
-- ============================================================================
function Camera:clear_bounds()
  self.bounds = nil
end

-- ============================================================================
-- 应用相机变换（开始用相机视角绘制）
-- 调用这个之后，所有绘制都是世界坐标，会被相机变换
-- 类比：就像把摄像机架好，然后开始拍
-- ============================================================================
function Camera:apply()
  love.graphics.push()

  -- 1. 先平移到屏幕中心
  local screen_w = love.graphics.getWidth()
  local screen_h = love.graphics.getHeight()
  love.graphics.translate(screen_w / 2, screen_h / 2)

  -- 2. 旋转
  love.graphics.rotate(self.rotation)

  -- 3. 缩放
  love.graphics.scale(self.zoom, self.zoom)

  -- 4. 平移相机位置（注意是负的，相机往右移，画面往左移）
  -- 加上震动偏移
  love.graphics.translate(-self.x + self.shake_x, -self.y + self.shake_y)
end

-- ============================================================================
-- 取消相机变换（恢复正常绘制，比如画 UI 的时候）
-- ============================================================================
function Camera:reset()
  love.graphics.pop()
end

-- ============================================================================
-- 屏幕坐标转世界坐标
-- 比如鼠标点击的屏幕位置，转换成世界里的位置
-- ============================================================================
function Camera:screen_to_world(screen_x, screen_y)
  local screen_w = love.graphics.getWidth()
  local screen_h = love.graphics.getHeight()

  -- 先减去屏幕中心偏移
  local x = (screen_x - screen_w / 2) / self.zoom + self.x
  local y = (screen_y - screen_h / 2) / self.zoom + self.y

  return x, y
end

-- ============================================================================
-- 世界坐标转屏幕坐标
-- ============================================================================
function Camera:world_to_screen(world_x, world_y)
  local screen_w = love.graphics.getWidth()
  local screen_h = love.graphics.getHeight()

  local x = (world_x - self.x) * self.zoom + screen_w / 2
  local y = (world_y - self.y) * self.zoom + screen_h / 2

  return x, y
end

-- ============================================================================
-- 获取视口大小（世界坐标下的可见范围）
-- ============================================================================
function Camera:get_viewport()
  local screen_w = love.graphics.getWidth()
  local screen_h = love.graphics.getHeight()

  local view_w = screen_w / self.zoom
  local view_h = screen_h / self.zoom

  return {
    left = self.x - view_w / 2,
    right = self.x + view_w / 2,
    top = self.y - view_h / 2,
    bottom = self.y + view_h / 2,
    width = view_w,
    height = view_h
  }
end

-- ============================================================================
-- 全局默认相机
-- ============================================================================
local _default_camera = nil

function Camera.get_default()
  if not _default_camera then
    _default_camera = Camera.new()
  end
  return _default_camera
end

return Camera
