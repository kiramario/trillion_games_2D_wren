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
local CameraSystem = require("systems.camera_system")
local Board = require("entities.board")
local Config = require("core.config")
local Utils = require("core.utils")

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
    
    -- 鼠标对应的棋盘坐标
    self._hover_col = 0
    self._hover_row = 0
    
    -- 相机
    self._camera = nil
    
    -- 棋盘
    self._board = nil
    
    return self
end

--[[
    进入场景
]]
function GameScene:enter(params)
    BaseScene.enter(self, params)
    
    Logger.info("游戏场景初始化")
    
    -- 初始化相机
    self._camera = CameraSystem.new()
    self._camera:set_viewport(love.graphics.getWidth(), love.graphics.getHeight())
    
    -- 初始化棋盘
    self._board = Board.new()
    -- 自适应窗口
    self._board:fit_to_window(love.graphics.getWidth(), love.graphics.getHeight())
    
    -- 订阅鼠标事件
    self._mouse_press_callback = function(data)
        self:_on_mouse_press(data)
    end
    EventBus:subscribe("input_mouse_left_pressed", self._mouse_press_callback)
    
    self._mouse_move_callback = function(data)
        self._mouse_x = data.x
        self._mouse_y = data.y
        -- 更新鼠标对应的棋盘坐标
        if self._board then
            local col, row = self._board:screen_to_board(data.x, data.y)
            self._hover_col = col
            self._hover_row = row
        end
    end
    EventBus:subscribe("input_mouse_move", self._mouse_move_callback)
    
    -- 订阅键盘事件
    self._key_press_callback = function(data)
        self:_on_key_press(data)
    end
    EventBus:subscribe("input_key_pressed", self._key_press_callback)
    
    -- 订阅滚轮回调
    self._wheel_callback = function(data)
        self:_on_wheel(data)
    end
    EventBus:subscribe("input_wheel_moved", self._wheel_callback)
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
    EventBus:unsubscribe("input_wheel_moved", self._wheel_callback)
    
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
    
    -- 按r重置棋盘大小
    if key == "r" then
        self._board:fit_to_window(love.graphics.getWidth(), love.graphics.getHeight())
        Logger.info("重置棋盘大小")
    end
    
    -- 按s相机震动测试
    if key == "s" then
        self._camera:shake(10, 0.5)
        Logger.info("相机震动测试")
    end
end

--[[
    鼠标滚轮处理
]]
function GameScene:_on_wheel(data)
    -- 滚轮缩放棋盘（测试用）
    if self._board then
        local delta = data.y * 5
        local new_size = self._board.cell_size + delta
        new_size = Utils.clamp(new_size, 20, 150)
        self._board:set_cell_size(new_size)
        self._board.x = love.graphics.getWidth() / 2
        self._board.y = love.graphics.getHeight() / 2
        Logger.debug("格子大小调整为：" .. new_size .. "px")
    end
end

--[[
    窗口大小改变
]]
function GameScene:resize(w, h)
    if self._board then
        self._board:fit_to_window(w, h)
    end
    if self._camera then
        self._camera:set_viewport(w, h)
    end
end

--[[
    更新
]]
function GameScene:update(dt)
    -- 更新相机
    if self._camera then
        self._camera:update(dt)
    end
    
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
    end)
    
    -- ===== 游戏层 =====
    RenderSystem:add_to_layer("GAME", function()
        -- 相机变换内绘制游戏内容
        if self._camera then
            self._camera:begin()
        end
        
        -- 绘制棋盘
        if self._board then
            self._board:draw()
        end
        
        -- 画点击的点（测试用，后面换成棋子）
        for _, point in ipairs(self._click_points) do
            -- 透明度随时间减少，淡出效果
            local alpha = math.max(0, 1 - point.time / 3)
            love.graphics.setColor(0, 1, 0, alpha)
            love.graphics.circle("fill", point.x, point.y, 8)
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.circle("line", point.x, point.y, 8)
        end
        
        -- 鼠标悬停的棋盘位置标记
        if self._board then
            local col = math.floor(self._hover_col + 0.5)
            local row = math.floor(self._hover_row + 0.5)
            if self._board:is_valid_position(col, row) then
                local x, y = self._board:board_to_screen(col, row)
                love.graphics.setColor(1, 1, 0, 0.5)
                love.graphics.circle("fill", x, y, 10)
            end
        end
        
        if self._camera then
            self._camera:finish()
        end
    end)
    
    -- ===== UI层 =====
    RenderSystem:add_to_layer("UI", function()
        -- 左上角信息
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("游戏场景 (GameScene) - V0.1 棋盘版", 10, 10)
        love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 30)
        love.graphics.print("鼠标位置: " .. math.floor(self._mouse_x) .. ", " .. math.floor(self._mouse_y), 10, 50)
        love.graphics.print("点击次数: " .. #self._click_points, 10, 70)
        
        -- 棋盘坐标
        if self._board then
            local col = math.floor(self._hover_col + 0.5)
            local row = math.floor(self._hover_row + 0.5)
            local valid = self._board:is_valid_position(col, row) and "有效" or "棋盘外"
            love.graphics.print(string.format("棋盘坐标: (%.1f, %.1f) → 格子(%d, %d) %s", 
                self._hover_col, self._hover_row, col, row, valid), 10, 90)
            love.graphics.print("格子大小: " .. self._board.cell_size .. "px", 10, 110)
        end
        
        -- 底部提示
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        local hint = "鼠标滚轮缩放棋盘 | 按 R 重置大小 | 按 S 相机震动测试 | 按 2 返回菜单"
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
