--[[
    文件名：game_scene.lua
    功能：游戏场景（V0测试用，后面会加棋盘棋子等）
    作者：wren
    创建日期：2026-06-09
    依赖：scenes.base_scene, core.logger, core.event_bus, systems.render_system
]]

local BaseScene = require("scenes.base_scene")
local Logger = require("core.logger")
local EventBus = require("core.event_bus")
local RenderSystem = require("systems.render_system")
local InputSystem = require("systems.input_system")
local Config = require("core.config")

-- 游戏场景类，继承自BaseScene
local GameScene = {}
GameScene.__index = GameScene
setmetatable(GameScene, {__index = BaseScene})

--[[
    构造函数
]]
function GameScene.new()
    local self = BaseScene.new()
    setmetatable(self, GameScene)
    
    self.name = "game"
    
    -- 测试用：鼠标点击的点列表，用来测试输入
    self._click_points = {}
    
    -- 测试用：当前鼠标位置
    self._mouse_x = 0
    self._mouse_y = 0
    
    return self
end

--[[
    进入场景
]]
function GameScene:enter(params)
    BaseScene.enter(self, params)
    
    Logger.info("游戏场景初始化")
    
    -- 订阅鼠标事件
    self._mouse_press_callback = function(data)
        self:_on_mouse_press(data)
    end
    EventBus:subscribe("input_mouse_left_pressed", self._mouse_press_callback)
    
    self._mouse_move_callback = function(data)
        self._mouse_x = data.x
        self._mouse_y = data.y
    end
    EventBus:subscribe("input_mouse_move", self._mouse_move_callback)
    
    -- 订阅键盘事件
    self._key_press_callback = function(data)
        self:_on_key_press(data)
    end
    EventBus:subscribe("input_key_pressed", self._key_press_callback)
end

--[[
    离开场景
]]
function GameScene:exit()
    BaseScene.exit(self)
    
    -- 取消订阅
    EventBus:unsubscribe("input_mouse_left_pressed", self._mouse_press_callback)
    EventBus:unsubscribe("input_mouse_move", self._mouse_move_callback)
    EventBus:unsubscribe("input_key_pressed", self._key_press_callback)
    
    Logger.info("游戏场景清理完成")
end

--[[
    鼠标按下处理
]]
function GameScene:_on_mouse_press(data)
    Logger.debug("游戏场景收到鼠标点击：" .. data.x .. ", " .. data.y)
    
    -- 把点击的点存起来，画出来
    table.insert(self._click_points, {
        x = data.x,
        y = data.y,
        time = 0  -- 用来做消失动画
    })
    
    -- 最多存50个点
    if #self._click_points > 50 then
        table.remove(self._click_points, 1)
    end
end

--[[
    键盘按下处理
]]
function GameScene:_on_key_press(data)
    local key = data.key
    
    -- 按2键切回菜单
    if key == "2" then
        Logger.info("返回菜单场景")
        local SceneManager = require("scenes.scene_manager")
        SceneManager:switch_scene("menu")
    end
    
    -- 按c清除点击点
    if key == "c" then
        self._click_points = {}
        Logger.info("清除所有点击点")
    end
end

--[[
    更新
]]
function GameScene:update(dt)
    -- 更新点击点的时间，做淡出效果
    for i = #self._click_points, 1, -1 do
        local point = self._click_points[i]
        point.time = point.time + dt
        -- 超过3秒就移除
        if point.time > 3 then
            table.remove(self._click_points, i)
        end
    end
end

--[[
    绘制
]]
function GameScene:draw()
    RenderSystem:clear()
    
    -- ===== 背景层 =====
    RenderSystem:add_to_layer("BACKGROUND", function()
        -- 背景色（游戏场景的背景跟菜单不一样，区分一下）
        love.graphics.setColor(0.08, 0.1, 0.12, 1)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        -- 画个棋盘占位，V0先用简单的格子
        -- 后面V0.1会换成真正的象棋棋盘
        love.graphics.setColor(0.2, 0.25, 0.2, 1)
        local board_size = math.min(love.graphics.getWidth(), love.graphics.getHeight()) * 0.8
        local board_x = (love.graphics.getWidth() - board_size) / 2
        local board_y = (love.graphics.getHeight() - board_size) / 2
        
        -- 画棋盘边框
        love.graphics.setColor(0.4, 0.5, 0.4, 1)
        love.graphics.rectangle("line", board_x, board_y, board_size, board_size)
        
        -- 画网格线（9x10，象棋是9列10行）
        local cols = 9
        local rows = 10
        local cell_w = board_size / cols
        local cell_h = board_size / rows
        
        love.graphics.setColor(0.3, 0.35, 0.3, 1)
        -- 竖线
        for i = 0, cols do
            local x = board_x + i * cell_w
            love.graphics.line(x, board_y, x, board_y + board_size)
        end
        -- 横线
        for j = 0, rows do
            local y = board_y + j * cell_h
            love.graphics.line(board_x, y, board_x + board_size, y)
        end
        
        -- 楚河汉界文字（占位）
        love.graphics.setColor(0.5, 0.6, 0.5, 1)
        local river_font = love.graphics.newFont(32)
        love.graphics.setFont(river_font)
        local river_text = "楚河        汉界"
        local river_width = river_font:getWidth(river_text)
        local river_y = board_y + board_size / 2 - river_font:getHeight() / 2
        love.graphics.print(river_text, (love.graphics.getWidth() - river_width) / 2, river_y)
        
        -- 恢复默认字体
        love.graphics.setFont(love.graphics.newFont(16))
    end)
    
    -- ===== 游戏层 =====
    RenderSystem:add_to_layer("GAME", function()
        -- 画点击的点（测试用，后面换成棋子）
        for _, point in ipairs(self._click_points) do
            -- 透明度随时间减少，淡出效果
            local alpha = math.max(0, 1 - point.time / 3)
            love.graphics.setColor(0, 1, 0, alpha)
            love.graphics.circle("fill", point.x, point.y, 8)
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.circle("line", point.x, point.y, 8)
        end
    end)
    
    -- ===== UI层 =====
    RenderSystem:add_to_layer("UI", function()
        -- 左上角信息
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("游戏场景 (GameScene) - V0 测试版", 10, 10)
        love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 30)
        love.graphics.print("鼠标位置: " .. math.floor(self._mouse_x) .. ", " .. math.floor(self._mouse_y), 10, 50)
        love.graphics.print("点击次数: " .. #self._click_points, 10, 70)
        
        -- 底部提示
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        local hint = "点击鼠标画点 | 按 C 清除 | 按 2 返回菜单"
        local hint_width = love.graphics.getFont():getWidth(hint)
        love.graphics.print(hint, (love.graphics.getWidth() - hint_width) / 2, love.graphics.getHeight() - 30)
    end)
    
    -- ===== 调试层 =====
    RenderSystem:add_to_layer("DEBUG", function()
        -- 鼠标十字线，帮助定位
        love.graphics.setColor(1, 0, 0, 0.3)
        love.graphics.line(self._mouse_x, 0, self._mouse_x, love.graphics.getHeight())
        love.graphics.line(0, self._mouse_y, love.graphics.getWidth(), self._mouse_y)
    end)
    
    -- 执行绘制
    RenderSystem:draw()
end

return GameScene
