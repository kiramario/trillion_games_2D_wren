--[[
    文件名：menu_scene.lua
    功能：菜单场景（V0测试用，后面会改成真正的菜单）
    作者：wren
    创建日期：2026-06-09
    依赖：scenes.base_scene, core.logger, core.event_bus, systems.render_system
]]

local BaseScene = require("scenes.base_scene")
local Logger = require("core.logger")
local EventBus = require("core.event_bus")
local RenderSystem = require("systems.render_system")
local Config = require("core.config")

-- 菜单场景类，继承自BaseScene
local MenuScene = {}
MenuScene.__index = MenuScene

-- 设置继承：MenuScene的元表的__index指向BaseScene
-- 这样MenuScene就能访问BaseScene的方法了
-- 类比：class MenuScene extends BaseScene
setmetatable(MenuScene, {__index = BaseScene})

--[[
    构造函数
]]
function MenuScene.new()
    -- 先调用父类构造函数，得到父类的实例
    local self = BaseScene.new()
    -- 然后把它的元表改成MenuScene，这样就能访问MenuScene的方法了
    -- 同时保留父类的方法（因为MenuScene的__index是BaseScene）
    setmetatable(self, MenuScene)
    
    self.name = "menu"
    
    -- 菜单场景自己的成员变量
    self._menu_items = {
        "1. 开始游戏（切换到游戏场景）",
        "2. 设置",
        "3. 退出",
    }
    self._selected_index = 1
    
    return self
end

--[[
    进入场景
]]
function MenuScene:enter(params)
    -- 调用父类的enter方法
    -- 注意：这里用点号调用，手动传self，因为不是用冒号的方式
    -- 类比：super.enter(params)
    BaseScene.enter(self, params)
    
    Logger.info("菜单场景初始化")
    
    -- 订阅键盘事件，用来切换场景
    self._key_press_callback = function(data)
        self:_on_key_press(data)
    end
    EventBus:subscribe("input_key_pressed", self._key_press_callback)
end

--[[
    离开场景
]]
function MenuScene:exit()
    BaseScene.exit(self)
    
    -- 取消订阅事件，防止内存泄漏
    EventBus:unsubscribe("input_key_pressed", self._key_press_callback)
    
    Logger.info("菜单场景清理完成")
end

--[[
    键盘按下处理
]]
function MenuScene:_on_key_press(data)
    local key = data.key
    
    -- 按1键切换到游戏场景
    if key == "1" then
        Logger.info("菜单：选择开始游戏")
        local SceneManager = require("scenes.scene_manager")
        SceneManager:switch_scene("game")
    end
    
    -- 按2键... 后面加设置
    if key == "2" then
        Logger.info("菜单：选择设置（暂未实现）")
    end
    
    -- 上下键选择菜单项
    if key == "up" then
        self._selected_index = self._selected_index - 1
        if self._selected_index < 1 then
            self._selected_index = #self._menu_items
        end
    end
    if key == "down" then
        self._selected_index = self._selected_index + 1
        if self._selected_index > #self._menu_items then
            self._selected_index = 1
        end
    end
    
    -- 回车键确认
    if key == "return" or key == "kpenter" then
        if self._selected_index == 1 then
            local SceneManager = require("scenes.scene_manager")
            SceneManager:switch_scene("game")
        elseif self._selected_index == 3 then
            -- 退出游戏
            love.event.quit()
        end
    end
end

--[[
    更新
]]
function MenuScene:update(dt)
    -- 菜单逻辑，V0阶段暂时没什么要更新的
end

--[[
    绘制
]]
function MenuScene:draw()
    -- 清空渲染系统，准备画这一帧
    RenderSystem:clear()
    
    -- ===== 背景层 =====
    RenderSystem:add_to_layer("BACKGROUND", function()
        -- 画背景色
        love.graphics.setColor(Config.get("graphics.background_color"))
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        -- 画点装饰，比如渐变或者图案，V0先画个简单的
        love.graphics.setColor(0.15, 0.18, 0.22, 1)
        for i = 0, love.graphics.getWidth(), 50 do
            love.graphics.line(i, 0, i, love.graphics.getHeight())
        end
        for j = 0, love.graphics.getHeight(), 50 do
            love.graphics.line(0, j, love.graphics.getWidth(), j)
        end
    end)
    
    -- ===== UI层 =====
    RenderSystem:add_to_layer("UI", function()
        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
        
        -- 标题
        love.graphics.setColor(1, 1, 1, 1)
        local title_font = love.graphics.newFont(48)  -- V0临时用，后面用ResourceManager
        love.graphics.setFont(title_font)
        local title = "Trillion Games 2D"
        local title_width = title_font:getWidth(title)
        love.graphics.print(title, (w - title_width) / 2, h * 0.25)
        
        -- 副标题
        local subtitle_font = love.graphics.newFont(24)
        love.graphics.setFont(subtitle_font)
        local subtitle = "中国象棋 - V0.0.1 脚手架版"
        local subtitle_width = subtitle_font:getWidth(subtitle)
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print(subtitle, (w - subtitle_width) / 2, h * 0.25 + 60)
        
        -- 菜单项
        local menu_font = love.graphics.newFont(20)
        love.graphics.setFont(menu_font)
        local start_y = h * 0.5
        local line_height = 40
        
        for i, item in ipairs(self._menu_items) do
            local item_width = menu_font:getWidth(item)
            local x = (w - item_width) / 2
            local y = start_y + (i - 1) * line_height
            
            if i == self._selected_index then
                -- 选中的项，高亮显示
                love.graphics.setColor(1, 0.8, 0.2, 1)
                -- 画个高亮背景
                love.graphics.rectangle("fill", x - 20, y - 5, item_width + 40, line_height - 10)
                love.graphics.setColor(0, 0, 0, 1)
            else
                -- 未选中
                love.graphics.setColor(0.9, 0.9, 0.9, 1)
            end
            
            love.graphics.print(item, x, y)
        end
        
        -- 提示文字
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        local hint_font = love.graphics.newFont(14)
        love.graphics.setFont(hint_font)
        local hint = "按 1/2/3 快速选择，上下键选择，回车确认，按 1 开始游戏"
        local hint_width = hint_font:getWidth(hint)
        love.graphics.print(hint, (w - hint_width) / 2, h - 60)
        
        -- 恢复默认字体
        love.graphics.setFont(love.graphics.newFont(16))
    end)
    
    -- ===== 调试层 =====
    RenderSystem:add_to_layer("DEBUG", function()
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.print("当前场景：菜单场景 (MenuScene)", 10, 10)
        love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 30)
        love.graphics.print("按 1 键切换到游戏场景", 10, 50)
    end)
    
    -- 执行绘制
    RenderSystem:draw()
end

return MenuScene
