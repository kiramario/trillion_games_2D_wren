-- ============================================================================
-- 测试场景 A
-- 功能：测试用的第一个场景，暖色调
-- ============================================================================

local Logger = require("core.logger")
local SceneManager = require("core.scene_manager")
local InputManager = require("core.input_manager")

local TestSceneA = {}
TestSceneA.__index = TestSceneA

function TestSceneA.new(params)
  local self = setmetatable({}, TestSceneA)

  self.logger = Logger.get_default()
  self.time = 0

  return self
end

-- 进入场景
function TestSceneA:enter(params)
  self.logger:info("[TestSceneA] Enter")
end

-- 每帧更新
function TestSceneA:update(dt)
  self.time = self.time + dt

  -- 按空格键切换到场景 B
  if InputManager.is_key_pressed("space") then
    SceneManager.switch("test_b")
  end
end

-- 绘制
function TestSceneA:draw()
  -- 暖色调背景
  love.graphics.setBackgroundColor(1, 0.8, 0.6, 1)

  -- 文字
  love.graphics.setColor(0.5, 0.3, 0.1, 1)
  love.graphics.printf("测试场景 A - 暖色调", 0, 200, 960, "center")
  love.graphics.printf("按空格键切换到场景 B", 0, 280, 960, "center")
  love.graphics.printf("运行时间: " .. string.format("%.1f", self.time) .. " 秒", 0, 360, 960, "center")
end

-- 退出场景
function TestSceneA:exit()
  self.logger:info("[TestSceneA] Exit")
end

return TestSceneA
