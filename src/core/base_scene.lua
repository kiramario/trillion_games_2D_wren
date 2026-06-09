--[[
    文件名：base_scene.lua
    功能：场景基类，所有场景都继承自这个类
    定义场景的统一生命周期接口
    类比：相当于 Java 的抽象类，或 React 的 Component 基类
    作者：wren
    创建日期：2026-06-09
    依赖：core.logger
]]

local Logger = require("core.logger")

-- 类定义
local BaseScene = {}
-- __index 是metatable的元方法，当访问不存在的key时，会去__index指向的表里找
-- 这是Lua实现面向对象的基础
-- 类比：JS的prototype，Java的父类
BaseScene.__index = BaseScene

--[[
    构造函数
    返回：新的场景对象
]]
function BaseScene.new()
    -- self 就是新的对象
    -- setmetatable 设置元表，这样self就能访问BaseScene里的方法了
    local self = setmetatable({}, BaseScene)
    
    -- 场景名称
    self.name = "base"
    
    -- 场景是否已经进入
    self._entered = false
    
    -- 场景参数（切换场景时传进来的）
    self._params = nil
    
    return self
end

--[[
    进入场景时调用
    参数：
        params (table) - 场景参数，可选，从切换场景时传过来
    说明：子类可以重写这个方法，做初始化工作
    类比：React的componentDidMount，或Android的onCreate
]]
function BaseScene:enter(params)
    self._entered = true
    self._params = params or {}
    Logger.debug("进入场景：" .. self.name)
    
    -- 子类重写的话，可以在这里加自己的逻辑
    -- 注意：要调用父类的方法的话，用 BaseScene.enter(self, params)
end

--[[
    离开场景时调用
    说明：子类可以重写，做清理工作
    类比：React的componentWillUnmount，或Android的onDestroy
]]
function BaseScene:exit()
    self._entered = false
    Logger.debug("离开场景：" .. self.name)
    
    -- 子类重写的话，在这里加清理逻辑
end

--[[
    每帧更新
    参数：
        dt (number) - 距离上一帧的时间，单位秒
    说明：子类重写，做游戏逻辑更新
    类比：游戏循环的update阶段
]]
function BaseScene:update(dt)
    -- 默认空实现，子类按需重写
end

--[[
    每帧绘制
    说明：子类重写，绘制场景内容
    注意：这里直接画，还是通过RenderSystem分层画，看子类实现
]]
function BaseScene:draw()
    -- 默认空实现，子类按需重写
end

--[[
    暂停场景（比如被弹窗盖住，或者切到后台）
    说明：子类可选实现
]]
function BaseScene:pause()
    Logger.debug("暂停场景：" .. self.name)
end

--[[
    恢复场景
    说明：子类可选实现
]]
function BaseScene:resume()
    Logger.debug("恢复场景：" .. self.name)
end

--[[
    窗口大小改变时调用
    参数：
        w (number) - 新的宽度
        h (number) - 新的高度
    说明：子类可选实现，做自适应
]]
function BaseScene:resize(w, h)
    Logger.debug("场景窗口大小改变：" .. self.name .. " -> " .. w .. "x" .. h)
end

return BaseScene
