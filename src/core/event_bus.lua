--[[
    文件名：event_bus.lua
    功能：事件总线，发布订阅模式，模块之间解耦通信
    类比：相当于 JS 的 EventEmitter，或 Java 的观察者模式
    作者：wren
    创建日期：2026-06-09
    依赖：core.logger
]]

local Logger = require("core.logger")

local EventBus = {}

-- 事件注册表：key是事件名，value是回调函数列表
-- 类比：JS的 EventEmitter 里的 _events 表
EventBus._events = {}

--[[
    订阅事件
    参数：
        event_name (string) - 事件名称
        callback (function) - 回调函数，事件触发时调用
        callback 的参数：事件数据（table）
    返回：无
    示例：
        EventBus:subscribe("scene_changed", function(data)
            print("从场景", data.from, "切换到", data.to)
        end)
]]
function EventBus:subscribe(event_name, callback)
    -- 类型检查
    if type(event_name) ~= "string" then
        Logger.error("订阅事件失败：事件名必须是字符串")
        return
    end
    if type(callback) ~= "function" then
        Logger.error("订阅事件失败：回调必须是函数")
        return
    end
    
    -- 如果这个事件还没有订阅者，创建一个列表
    if self._events[event_name] == nil then
        self._events[event_name] = {}
    end
    
    -- 把回调加进去
    table.insert(self._events[event_name], callback)
    Logger.debug("订阅事件：" .. event_name)
end

--[[
    取消订阅
    参数：
        event_name (string) - 事件名称
        callback (function) - 要取消的回调函数
    返回：无
    注意：必须传跟订阅时完全一样的函数引用才能取消成功
]]
function EventBus:unsubscribe(event_name, callback)
    if self._events[event_name] == nil then
        return
    end
    
    -- 遍历找到对应的回调，移除
    for i, cb in ipairs(self._events[event_name]) do
        if cb == callback then
            table.remove(self._events[event_name], i)
            Logger.debug("取消订阅事件：" .. event_name)
            return
        end
    end
    
    Logger.warn("取消订阅失败：未找到对应的回调函数，事件：" .. event_name)
end

--[[
    发布事件
    参数：
        event_name (string) - 事件名称
        data (table) - 事件数据，可选，传给所有订阅者的回调
    返回：无
    示例：
        EventBus:publish("scene_changed", {from = "menu", to = "game"})
]]
function EventBus:publish(event_name, data)
    if type(event_name) ~= "string" then
        Logger.error("发布事件失败：事件名必须是字符串")
        return
    end
    
    -- 没有订阅者就直接返回
    local callbacks = self._events[event_name]
    if callbacks == nil or #callbacks == 0 then
        -- 没有订阅者是正常的，不用打日志，不然太吵
        return
    end
    
    Logger.debug("发布事件：" .. event_name)
    
    -- 遍历所有回调，依次调用
    -- 注意：这里用 ipairs 遍历，按订阅顺序调用
    -- 类比：JS里事件触发的顺序就是监听顺序
    for i, callback in ipairs(callbacks) do
        -- 用pcall保护，防止某个回调报错影响其他的
        -- 类比：JS里一个listener报错不影响其他listener
        local ok, err = pcall(callback, data)
        if not ok then
            Logger.error("事件回调执行出错，事件：" .. event_name .. "，错误：" .. tostring(err))
        end
    end
end

--[[
    清除某个事件的所有订阅者
    参数：
        event_name (string) - 事件名称，可选；不传就清除所有事件
]]
function EventBus:clear(event_name)
    if event_name then
        self._events[event_name] = nil
        Logger.debug("清除事件订阅：" .. event_name)
    else
        self._events = {}
        Logger.debug("清除所有事件订阅")
    end
end

--[[
    获取某个事件的订阅者数量（调试用）
    参数：
        event_name (string) - 事件名称
    返回：订阅者数量
]]
function EventBus:get_subscriber_count(event_name)
    if self._events[event_name] == nil then
        return 0
    end
    return #self._events[event_name]
end

Logger.info("事件总线初始化完成")

return EventBus
