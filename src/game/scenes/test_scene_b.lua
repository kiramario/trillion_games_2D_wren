-- ============================================================================
-- 测试场景 B
-- 功能：测试用的第二个场景，冷色调
-- ============================================================================

local Logger = require("core.logger")
local SceneManager = require("core.scene_manager")
local InputManager = require("core.input_manager")

local TestSceneB = {}
TestSceneB.__index = TestSceneB

function TestSceneB.new(params)
  local self = setmetatable({}, TestSceneB)

  self.logger = Logger.get_default()
  self.time = 0

  return self
end

function TestSceneB:enter(params)
  self.logger:info("[TestSceneB] Enter")
end

function TestSceneB:update(dt)
  self.time = self.time + dt

  -- 按空格键切换回场景 A
  if InputManager.is_key_pressed("space") then
    SceneManager.switch("test_a")
  end
end

function TestSceneB:draw()
  -- 冷色调背景
  love.graphics.setBackgroundColor(0.6, 0.8, 1, 1)

  -- 文字
  love.graphics.setColor(0.1, 0.3, 0.5, 1)
  love.graphics.printf("测试场景 B - 冷色调", 0, 200, 960, "center")
  love.graphics.printf("按空格键切换回场景 A", 0, 280, 960, "center")
  love.graphics.printf("运行时间: " .. string.format("%.1f", self.time) .. " 秒", 0, 360, 960, "center")
end

function TestSceneB:exit()
  self.logger:info("[TestSceneB] Exit")
end

return TestSceneB
