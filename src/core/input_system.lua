--[[
    文件名：input_system.lua
    功能：输入系统，统一封装鼠标和键盘输入，通过事件总线发布
    类比：相当于前端的事件系统，或 Unity 的 Input System
    作者：wren
    创建日期：2026-06-09
    依赖：core.logger, core.event_bus, core.config
]]

local Logger = require("core.logger")
local EventBus = require("core.event_bus")
local Config = require("core.config")

local InputSystem = {}

-- 当前输入状态
InputSystem._state = {
    -- 鼠标状态
    mouse = {
        x = 0,
        y = 0,
        dx = 0,  -- 这一帧的移动量
        dy = 0,
        buttons = {},  -- 按键状态：true=按下，false=松开
    },
    
    -- 键盘状态
    keyboard = {
        keys = {},  -- 按键状态
    },
}

--[[
    初始化输入系统
    注册 LÖVE2D 的输入回调
]]
function InputSystem:init()
    -- 注意：这里把LÖVE2D的回调函数接管了
    -- 但保存原来的，如果有的话，这样不会跟其他模块冲突
    
    -- 鼠标移动回调
    -- 类比：JS的 mousemove 事件
    local original_mousemoved = love.mousemoved
    love.mousemoved = function(x, y, dx, dy, istouch)
        if original_mousemoved then
            original_mousemoved(x, y, dx, dy, istouch)
        end
        self:_on_mouse_move(x, y, dx, dy, istouch)
    end
    
    -- 鼠标按下回调
    -- 类比：JS的 mousedown 事件
    local original_mousepressed = love.mousepressed
    love.mousepressed = function(x, y, button, istouch, presses)
        if original_mousepressed then
            original_mousepressed(x, y, button, istouch, presses)
        end
        self:_on_mouse_pressed(x, y, button, istouch, presses)
    end
    
    -- 鼠标释放回调
    -- 类比：JS的 mouseup 事件
    local original_mousereleased = love.mousereleased
    love.mousereleased = function(x, y, button, istouch, presses)
        if original_mousereleased then
            original_mousereleased(x, y, button, istouch, presses)
        end
        self:_on_mouse_released(x, y, button, istouch, presses)
    end
    
    -- 键盘按下回调
    -- 类比：JS的 keydown 事件
    local original_keypressed = love.keypressed
    love.keypressed = function(key, scancode, isrepeat)
        if original_keypressed then
            original_keypressed(key, scancode, isrepeat)
        end
        self:_on_key_pressed(key, scancode, isrepeat)
    end
    
    -- 键盘释放回调
    -- 类比：JS的 keyup 事件
    local original_keyreleased = love.keyreleased
    love.keyreleased = function(key, scancode)
        if original_keyreleased then
            original_keyreleased(key, scancode)
        end
        self:_on_key_released(key, scancode)
    end
    
    -- 鼠标滚轮回调
    local original_wheelmoved = love.wheelmoved
    love.wheelmoved = function(x, y)
        if original_wheelmoved then
            original_wheelmoved(x, y)
        end
        self:_on_wheel_moved(x, y)
    end
    
    Logger.info("输入系统初始化完成")
end

--[[
    每帧更新（目前暂时不用，状态在回调里已经更新了）
    留着接口，后面可能要加状态类的处理
    参数：
        dt (number) - 距离上一帧的时间，秒
]]
function InputSystem:update(dt)
    -- 重置这一帧的鼠标移动量
    self._state.mouse.dx = 0
    self._state.mouse.dy = 0
end

-- ============== 鼠标相关 ==============

-- 鼠标移动处理
function InputSystem:_on_mouse_move(x, y, dx, dy, istouch)
    self._state.mouse.x = x
    self._state.mouse.y = y
    self._state.mouse.dx = dx
    self._state.mouse.dy = dy
    
    -- 发布事件
    EventBus:publish("input_mouse_move", {
        x = x,
        y = y,
        dx = dx,
        dy = dy,
        istouch = istouch,
    })
    
    Logger.debug("鼠标移动：(" .. x .. ", " .. y .. ")")
end

-- 鼠标按下处理
function InputSystem:_on_mouse_pressed(x, y, button, istouch, presses)
    self._state.mouse.buttons[button] = true
    
    EventBus:publish("input_mouse_pressed", {
        x = x,
        y = y,
        button = button,
        istouch = istouch,
        presses = presses,
    })
    
    -- 同时发布具体按键的事件，方便监听特定按键
    local button_names = {
        [1] = "left",
        [2] = "right",
        [3] = "middle",
    }
    local button_name = button_names[button] or tostring(button)
    EventBus:publish("input_mouse_" .. button_name .. "_pressed", {
        x = x,
        y = y,
        presses = presses,
    })
    
    Logger.debug("鼠标按下：按钮" .. button .. "，位置(" .. x .. ", " .. y .. ")")
end

-- 鼠标释放处理
function InputSystem:_on_mouse_released(x, y, button, istouch, presses)
    self._state.mouse.buttons[button] = false
    
    EventBus:publish("input_mouse_released", {
        x = x,
        y = y,
        button = button,
        istouch = istouch,
        presses = presses,
    })
    
    local button_names = {
        [1] = "left",
        [2] = "right",
        [3] = "middle",
    }
    local button_name = button_names[button] or tostring(button)
    EventBus:publish("input_mouse_" .. button_name .. "_released", {
        x = x,
        y = y,
        presses = presses,
    })
    
    Logger.debug("鼠标释放：按钮" .. button .. "，位置(" .. x .. ", " .. y .. ")")
end

-- 鼠标滚轮处理
function InputSystem:_on_wheel_moved(x, y)
    EventBus:publish("input_wheel_moved", {
        x = x,
        y = y,
    })
    
    Logger.debug("鼠标滚轮：x=" .. x .. ", y=" .. y)
end

--[[
    获取鼠标当前位置
    返回：x, y
]]
function InputSystem:get_mouse_position()
    return self._state.mouse.x, self._state.mouse.y
end

--[[
    获取鼠标按键是否按下
    参数：
        button (number/string) - 按键：1/left=左键，2/right=右键，3/middle=中键
    返回：true/false
]]
function InputSystem:is_mouse_button_down(button)
    -- 如果传的是字符串，转成数字
    if type(button) == "string" then
        local button_map = {
            left = 1,
            right = 2,
            middle = 3,
        }
        button = button_map[button] or tonumber(button)
    end
    
    return self._state.mouse.buttons[button] == true
end

-- ============== 键盘相关 ==============

-- 键盘按下处理
function InputSystem:_on_key_pressed(key, scancode, isrepeat)
    self._state.keyboard.keys[key] = true
    self._state.keyboard.keys[scancode] = true
    
    EventBus:publish("input_key_pressed", {
        key = key,
        scancode = scancode,
        isrepeat = isrepeat,
    })
    
    -- 发布具体按键的事件
    EventBus:publish("input_key_" .. key .. "_pressed", {
        isrepeat = isrepeat,
    })
    
    if not isrepeat then
        Logger.debug("键盘按下：" .. key)
    end
end

-- 键盘释放处理
function InputSystem:_on_key_released(key, scancode)
    self._state.keyboard.keys[key] = false
    self._state.keyboard.keys[scancode] = false
    
    EventBus:publish("input_key_released", {
        key = key,
        scancode = scancode,
    })
    
    -- 发布具体按键的事件
    EventBus:publish("input_key_" .. key .. "_released", {})
    
    Logger.debug("键盘释放：" .. key)
end

--[[
    检查某个键是否按住
    参数：
        key (string) - 键名，比如 "a", "space", "escape"
    返回：true/false
]]
function InputSystem:is_key_down(key)
    return self._state.keyboard.keys[key] == true
end

--[[
    重置所有输入状态
    比如场景切换的时候调用，防止残留状态
]]
function InputSystem:reset()
    -- 清空按键状态
    self._state.mouse.buttons = {}
    self._state.keyboard.keys = {}
    Logger.debug("输入系统状态已重置")
end

Logger.info("输入系统模块加载完成")

return InputSystem
