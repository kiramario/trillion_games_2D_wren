-- ============================================================================
-- 渲染测试场景
-- 功能：测试渲染管理器、相机、实体、动画系统
-- ============================================================================

local Logger = require("core.logger")
local Entity = require("core.entity")
local RenderManager = require("core.render_manager")
local Animation = require("core.animation")
local InputManager = require("core.input_manager")
local SceneManager = require("core.scene_manager")
local Utils = require("core.utils")

local RenderTestScene = {}
RenderTestScene.__index = RenderTestScene

function RenderTestScene.new(params)
  local self = setmetatable({}, RenderTestScene)

  self.logger = Logger.get_default()
  self.render = RenderManager.get_default()
  self.camera = self.render:get_camera()
  self.time = 0

  -- 测试实体列表
  self.entities = {}

  return self
end

-- 进入场景
function RenderTestScene:enter(params)
  self.logger:info("[RenderTestScene] Enter")

  -- 背景层的大矩形
  local bg = Entity.new({
    x = -400, y = -300,
    width = 800, height = 600,
    layer = "background",
    color = {0.2, 0.3, 0.4, 1}
  })
  function bg:_draw_content()
    love.graphics.rectangle("fill",
      -self.width * self.anchor_x,
      -self.height * self.anchor_y,
      self.width, self.height)
  end
  table.insert(self.entities, bg)

  -- 世界底层的网格地板
  for i = -4, 4 do
    for j = -3, 3 do
      local tile = Entity.new({
        x = i * 80, y = j * 80,
        width = 78, height = 78,
        layer = "world_back",
        z_index = 0,
        color = {0.3, 0.4, 0.5, 1}
      })
      function tile:_draw_content()
        love.graphics.rectangle("fill",
          -self.width * self.anchor_x,
          -self.height * self.anchor_y,
          self.width, self.height)
      end
      table.insert(self.entities, tile)
    end
  end

  -- 世界中层的几个测试方块
  for i = 1, 5 do
    local box = Entity.new({
      x = -200 + i * 80,
      y = -50 + math.sin(i) * 30,
      width = 60, height = 60,
      layer = "world_mid",
      z_index = i,
      color = {0.2 + i * 0.1, 0.6, 0.4, 1},
      anchor_x = 0.5,
      anchor_y = 0.5
    })
    function box:_draw_content()
      love.graphics.rectangle("fill",
        -self.width * self.anchor_x,
        -self.height * self.anchor_y,
        self.width, self.height)
    end
    table.insert(self.entities, box)

    -- 给方块加个动画，上下浮动
    local original_y = box.y
    Animation.tween(box, 2, {y = original_y + 40}, {
      ease = "ease_in_out_sine",
      yoyo = true,
      loops = -1  -- 无限循环
    })
  end

  -- 世界上层的旋转方块
  local rotating = Entity.new({
    x = 0, y = -100,
    width = 50, height = 50,
    layer = "world_front",
    color = {1, 0.8, 0.2, 1},
    anchor_x = 0.5,
    anchor_y = 0.5
  })
  function rotating:_draw_content()
    love.graphics.rectangle("fill",
      -self.width * self.anchor_x,
      -self.height * self.anchor_y,
      self.width, self.height)
  end
  table.insert(self.entities, rotating)
  -- 无限旋转动画
  self.rotating_box = rotating

  -- UI 层的文字说明
  self.ui_text = {
    "渲染测试场景 (V0.2.0)",
    "WASD / 方向键：移动相机",
    "滚轮：缩放",
    "空格：相机震动",
    "F1：切换调试模式",
    "ESC：返回测试场景 A"
  }
end

-- 每帧更新
function RenderTestScene:update(dt)
  self.time = self.time + dt

  -- 相机移动
  local move_speed = 300
  if InputManager.is_key_down("w") or InputManager.is_key_down("up") then
    self.camera:translate(0, -move_speed * dt)
  end
  if InputManager.is_key_down("s") or InputManager.is_key_down("down") then
    self.camera:translate(0, move_speed * dt)
  end
  if InputManager.is_key_down("a") or InputManager.is_key_down("left") then
    self.camera:translate(-move_speed * dt, 0)
  end
  if InputManager.is_key_down("d") or InputManager.is_key_down("right") then
    self.camera:translate(move_speed * dt, 0)
  end

  -- 滚轮缩放
  local wheel_x, wheel_y = InputManager.get_mouse_wheel()
  if wheel_y ~= 0 then
    self.camera:zoom_by(1 + wheel_y * 0.1)
  end

  -- 空格触发相机震动
  if InputManager.is_key_pressed("space") then
    self.camera:shake(10, 0.5)
  end

  -- ESC 返回场景 A
  if InputManager.is_key_pressed("escape") then
    SceneManager.switch("test_a")
  end

  -- 旋转方块
  self.rotating_box.rotation = self.time * 2

  -- 更新动画系统
  Animation.update(dt)

  -- 更新相机
  self.camera:update(dt)

  -- 清空渲染队列
  self.render:clear()

  -- 把所有实体加到渲染管理器
  for _, entity in ipairs(self.entities) do
    if entity.active then
      self.render:add_entity(entity)
    end
  end

  -- 加个 UI 层的绘制
  self.render:add_draw("ui", function()
    self:_draw_ui()
  end, 100)
end

-- 绘制 UI
function RenderTestScene:_draw_ui()
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.rectangle("fill", 10, 10, 280, 180)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("渲染测试 (V0.2.0)", 20, 20)
  love.graphics.print("WASD / 方向键：移动相机", 20, 45)
  love.graphics.print("鼠标滚轮：缩放", 20, 65)
  love.graphics.print("空格：相机震动", 20, 85)
  love.graphics.print("F1：调试信息", 20, 105)
  love.graphics.print("ESC：返回上一个场景", 20, 125)
  love.graphics.print(string.format("相机位置: (%.1f, %.1f)", self.camera.x, self.camera.y), 20, 150)
  love.graphics.print(string.format("缩放: %.2fx", self.camera.zoom), 20, 170)
end

-- 绘制
function RenderTestScene:draw()
  self.render:draw()
end

-- 退出场景
function RenderTestScene:exit()
  self.logger:info("[RenderTestScene] Exit")
  Animation.stop_all()
end

return RenderTestScene
