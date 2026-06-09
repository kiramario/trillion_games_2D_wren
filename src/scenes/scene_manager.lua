--[[
    文件名：scene_manager.lua
    功能：场景管理器，管理场景的切换、生命周期
    类比：相当于前端的路由管理器（React Router），或 Android 的 Activity 栈
    作者：wren
    创建日期：2026-06-09
    依赖：core.logger, core.event_bus, scenes.base_scene
]]

local Logger = require("core.logger")
local EventBus = require("core.event_bus")
local BaseScene = require("scenes.base_scene")

local SceneManager = {}

-- 当前场景
SceneManager._current_scene = nil
SceneManager._current_scene_name = nil

-- 场景注册表：key是场景名，value是场景类（构造函数）
SceneManager._scene_classes = {}

--[[
    注册场景类
    参数：
        scene_name (string) - 场景名称
        scene_class (table) - 场景类（要有new方法）
    示例：
        SceneManager:register_scene("menu", MenuScene)
]]
function SceneManager:register_scene(scene_name, scene_class)
    if type(scene_name) ~= "string" then
        Logger.error("注册场景失败：场景名必须是字符串")
        return
    end
    if type(scene_class) ~= "table" or type(scene_class.new) ~= "function" then
        Logger.error("注册场景失败：场景类必须有new方法")
        return
    end
    
    self._scene_classes[scene_name] = scene_class
    Logger.debug("注册场景：" .. scene_name)
end

--[[
    切换到指定场景
    参数：
        scene_name (string) - 场景名称
        params (table) - 传给新场景的参数，可选
    示例：
        SceneManager:switch_scene("game", {level = 1})
]]
function SceneManager:switch_scene(scene_name, params)
    -- 检查场景是否存在
    if not self._scene_classes[scene_name] then
        Logger.error("切换场景失败：场景不存在 - " .. tostring(scene_name))
        return
    end
    
    local old_scene_name = self._current_scene_name
    
    -- 发布场景切换前事件
    EventBus:publish("scene_before_change", {
        from = old_scene_name,
        to = scene_name,
    })
    
    -- 退出当前场景
    if self._current_scene then
        self._current_scene:exit()
        self._current_scene = nil
    end
    
    -- 创建新场景
    Logger.info("切换场景：" .. tostring(old_scene_name) .. " -> " .. scene_name)
    local new_scene = self._scene_classes[scene_name].new()
    self._current_scene = new_scene
    self._current_scene_name = scene_name
    
    -- 进入新场景
    new_scene:enter(params or {})
    
    -- 发布场景切换完成事件
    EventBus:publish("scene_changed", {
        from = old_scene_name,
        to = scene_name,
        params = params,
    })
end

--[[
    获取当前场景
    返回：当前场景对象，场景名
]]
function SceneManager:get_current_scene()
    return self._current_scene, self._current_scene_name
end

--[[
    获取当前场景名称
    返回：场景名字符串
]]
function SceneManager:get_current_scene_name()
    return self._current_scene_name
end

--[[
    更新当前场景
    参数：
        dt (number) - 时间增量，秒
]]
function SceneManager:update(dt)
    if self._current_scene and self._current_scene.update then
        self._current_scene:update(dt)
    end
end

--[[
    绘制当前场景
]]
function SceneManager:draw()
    if self._current_scene and self._current_scene.draw then
        self._current_scene:draw()
    end
end

--[[
    暂停当前场景
]]
function SceneManager:pause()
    if self._current_scene and self._current_scene.pause then
        self._current_scene:pause()
    end
end

--[[
    恢复当前场景
]]
function SceneManager:resume()
    if self._current_scene and self._current_scene.resume then
        self._current_scene:resume()
    end
end

--[[
    窗口大小改变时调用
    参数：
        w (number) - 新宽度
        h (number) - 新高度
]]
function SceneManager:resize(w, h)
    if self._current_scene and self._current_scene.resize then
        self._current_scene:resize(w, h)
    end
end

--[[
    检查场景是否已注册
    参数：
        scene_name (string) - 场景名
    返回：true/false
]]
function SceneManager:has_scene(scene_name)
    return self._scene_classes[scene_name] ~= nil
end

--[[
    获取所有已注册的场景名列表
    返回：数组
]]
function SceneManager:get_all_scene_names()
    local names = {}
    for name, _ in pairs(self._scene_classes) do
        table.insert(names, name)
    end
    return names
end

Logger.info("场景管理器模块加载完成")

return SceneManager
