--[[
    文件名：camera_system.lua
    功能：相机系统，支持平移、缩放、震动等效果
    类比：相当于 Unity 的 Camera，或者 2D 游戏的视口变换
    作者：wren
    创建日期：2026-06-09
    依赖：core.logger, core.config
]]

local Logger = require("core.logger")

local CameraSystem = {}
CameraSystem.__index = CameraSystem

--[[
    构造函数
    返回：新的相机对象
]]
function CameraSystem.new()
    local self = setmetatable({}, CameraSystem)
    
    -- 相机位置（中心点）
    self.x = 0
    self.y = 0
    
    -- 缩放比例（1=正常，>1=放大，<1=缩小）
    self.scale = 1
    
    -- 旋转角度（弧度，2D游戏一般不用，先留着接口）
    self.rotation = 0
    
    -- 震动参数
    self._shake_intensity = 0    -- 震动强度
    self._shake_duration = 0     -- 震动持续时间（秒）
    self._shake_time = 0         -- 已经震动的时间
    self._shake_offset_x = 0     -- 当前震动偏移X
    self._shake_offset_y = 0     -- 当前震动偏移Y
    
    -- 视口大小（窗口大小）
    self._viewport_width = 0
    self._viewport_height = 0
    
    return self
end

--[[
    设置视口大小（一般是窗口大小）
    参数：
        width, height (number) - 视口宽高
]]
function CameraSystem:set_viewport(width, height)
    self._viewport_width = width
    self._viewport_height = height
end

--[[
    设置相机位置（中心点）
    参数：
        x, y (number) - 相机中心坐标
]]
function CameraSystem:set_position(x, y)
    self.x = x
    self.y = y
end

--[[
    移动相机
    参数：
        dx, dy (number) - 偏移量
]]
function CameraSystem:translate(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end

--[[
    设置缩放比例
    参数：
        scale (number) - 缩放比例，1=原始大小
]]
function CameraSystem:set_scale(scale)
    -- 限制缩放范围，防止缩太小或太大
    self.scale = Utils and Utils.clamp and Utils.clamp(scale, 0.1, 10) or scale
end

--[[
    缩放相机（相对值）
    参数：
        factor (number) - 缩放因子，比如 1.1 是放大10%，0.9是缩小10%
]]
function CameraSystem:zoom(factor)
    self:set_scale(self.scale * factor)
end

--[[
    开始震动效果
    参数：
        intensity (number) - 震动强度（像素）
        duration (number) - 持续时间（秒）
]]
function CameraSystem:shake(intensity, duration)
    self._shake_intensity = intensity
    self._shake_duration = duration
    self._shake_time = 0
end

--[[
    更新相机
    参数：
        dt (number) - 时间增量
]]
function CameraSystem:update(dt)
    -- 更新震动
    if self._shake_time < self._shake_duration then
        self._shake_time = self._shake_time + dt
        
        -- 计算震动偏移（随机方向）
        if self._shake_time < self._shake_duration then
            local progress = 1 - self._shake_time / self._shake_duration
            local current_intensity = self._shake_intensity * progress
            self._shake_offset_x = (math.random() * 2 - 1) * current_intensity
            self._shake_offset_y = (math.random() * 2 - 1) * current_intensity
        else
            -- 震动结束，归零
            self._shake_offset_x = 0
            self._shake_offset_y = 0
        end
    end
end

--[[
    开始应用相机变换
    调用这个之后，所有的绘制都会经过相机变换
    类比：push 一个变换矩阵
]]
function CameraSystem:begin()
    love.graphics.push()
    
    -- 先平移到视口中心
    love.graphics.translate(self._viewport_width / 2, self._viewport_height / 2)
    
    -- 缩放
    love.graphics.scale(self.scale, self.scale)
    
    -- 旋转
    love.graphics.rotate(self.rotation)
    
    -- 平移相机位置（加上震动偏移）
    love.graphics.translate(
        -self.x + self._shake_offset_x,
        -self.y + self._shake_offset_y
    )
end

--[[
    结束相机变换，恢复正常
    类比：pop 变换矩阵
]]
function CameraSystem:finish()
    love.graphics.pop()
end

--[[
    屏幕坐标转世界坐标
    参数：
        screen_x, screen_y (number) - 屏幕上的坐标（比如鼠标位置）
    返回：世界坐标 world_x, world_y
]]
function CameraSystem:screen_to_world(screen_x, screen_y)
    -- 减去视口中心
    local x = screen_x - self._viewport_width / 2
    local y = screen_y - self._viewport_height / 2
    
    -- 反向缩放
    x = x / self.scale
    y = y / self.scale
    
    -- 反向旋转（如果有旋转的话，V0阶段暂时不用）
    -- x = x * math.cos(-self.rotation) - y * math.sin(-self.rotation)
    -- y = x * math.sin(-self.rotation) + y * math.cos(-self.rotation)
    
    -- 加上相机位置
    x = x + self.x
    y = y + self.y
    
    return x, y
end

--[[
    世界坐标转屏幕坐标
    参数：
        world_x, world_y (number) - 世界坐标
    返回：屏幕坐标 screen_x, screen_y
]]
function CameraSystem:world_to_screen(world_x, world_y)
    -- 减去相机位置
    local x = world_x - self.x
    local y = world_y - self.y
    
    -- 缩放
    x = x * self.scale
    y = y * self.scale
    
    -- 加上视口中心
    x = x + self._viewport_width / 2
    y = y + self._viewport_height / 2
    
    return x, y
end

--[[
    让相机聚焦到某个点，平滑移动（后续版本加，先留接口）
    参数：
        target_x, target_y (number) - 目标点
        speed (number) - 移动速度
        dt (number) - 时间增量
]]
function CameraSystem:focus(target_x, target_y, speed, dt)
    -- 简单的线性插值，平滑跟随
    self.x = Utils and Utils.lerp and Utils.lerp(self.x, target_x, speed * dt) or target_x
    self.y = Utils and Utils.lerp and Utils.lerp(self.y, target_y, speed * dt) or target_y
end

Logger.info("相机系统模块加载完成")

return CameraSystem
