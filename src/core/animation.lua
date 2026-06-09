-- ============================================================================
-- 动画与缓动系统
-- 功能：补间动画、缓动函数，实现各种动画效果
-- 类比：JS 的 GreenSock (GSAP)、CSS transition、Unity 的 DOTween
-- 说明：补间动画就是从一个值平滑过渡到另一个值，比如位置移动、大小变化、透明度变化
-- ============================================================================

local Utils = require("core.utils")
local Logger = require("core.logger")

-- ============================================================================
-- 缓动函数集合
-- 每个函数输入 t (0~1)，输出 eased 值
-- 参考：https://easings.net/
-- ============================================================================
local Easing = {}

-- 线性
function Easing.linear(t)
  return t
end

-- 二次方
function Easing.ease_in_quad(t)
  return t * t
end
function Easing.ease_out_quad(t)
  return 1 - (1 - t) * (1 - t)
end
function Easing.ease_in_out_quad(t)
  if t < 0.5 then
    return 2 * t * t
  else
    return 1 - (-2 * t + 2) ^ 2 / 2
  end
end

-- 三次方
function Easing.ease_in_cubic(t)
  return t * t * t
end
function Easing.ease_out_cubic(t)
  return 1 - (1 - t) ^ 3
end
function Easing.ease_in_out_cubic(t)
  if t < 0.5 then
    return 4 * t * t * t
  else
    return 1 - (-2 * t + 2) ^ 3 / 2
  end
end

-- 四次方
function Easing.ease_in_quart(t)
  return t * t * t * t
end
function Easing.ease_out_quart(t)
  return 1 - (1 - t) ^ 4
end
function Easing.ease_in_out_quart(t)
  if t < 0.5 then
    return 8 * t * t * t * t
  else
    return 1 - (-2 * t + 2) ^ 4 / 2
  end
end

-- 正弦
function Easing.ease_in_sine(t)
  return 1 - math.cos((t * math.pi) / 2)
end
function Easing.ease_out_sine(t)
  return math.sin((t * math.pi) / 2)
end
function Easing.ease_in_out_sine(t)
  return -(math.cos(math.pi * t) - 1) / 2
end

-- 回弹
function Easing.ease_out_back(t)
  local c1 = 1.70158
  local c3 = c1 + 1
  return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end
function Easing.ease_in_back(t)
  local c1 = 1.70158
  local c3 = c1 + 1
  return c3 * t * t * t - c1 * t * t
end
function Easing.ease_in_out_back(t)
  local c1 = 1.70158
  local c2 = c1 * 1.525
  if t < 0.5 then
    return ((2 * t) ^ 2 * ((c2 + 1) * 2 * t - c2)) / 2
  else
    return ((2 * t - 2) ^ 2 * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
  end
end

-- 弹跳
function Easing.ease_out_bounce(t)
  local n1 = 7.5625
  local d1 = 2.75
  if t < 1 / d1 then
    return n1 * t * t
  elseif t < 2 / d1 then
    t = t - 1.5 / d1
    return n1 * t * t + 0.75
  elseif t < 2.5 / d1 then
    t = t - 2.25 / d1
    return n1 * t * t + 0.9375
  else
    t = t - 2.625 / d1
    return n1 * t * t + 0.984375
  end
end

-- 弹性
function Easing.ease_out_elastic(t)
  local c4 = (2 * math.pi) / 3
  if t == 0 then
    return 0
  elseif t == 1 then
    return 1
  else
    return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
  end
end

-- 缓动函数别名（方便使用）
Easing.ease_in = Easing.ease_in_quad
Easing.ease_out = Easing.ease_out_quad
Easing.ease_in_out = Easing.ease_in_out_quad

-- ============================================================================
-- 动画系统
-- 管理所有补间动画
-- ============================================================================

local AnimationSystem = {}
AnimationSystem.__index = AnimationSystem

-- ============================================================================
-- 创建动画系统
-- ============================================================================
function AnimationSystem.new()
  local self = setmetatable({}, AnimationSystem)

  self.tweens = {}  -- 所有活跃的补间动画
  self.animations = {}  -- 其他动画（后面扩展）

  self.logger = Logger.get_default()

  return self
end

-- ============================================================================
-- 创建一个补间动画
-- @param table target 目标对象（要修改属性的对象）
-- @param number duration 持续时间（秒）
-- @param table properties 目标属性值，比如 {x = 100, y = 200, alpha = 1}
-- @param table options 选项：ease, delay, on_complete, on_update 等
-- @return table tween 对象
-- ============================================================================
function AnimationSystem:tween(target, duration, properties, options)
  options = options or {}

  local tween = {
    target = target,
    duration = duration,
    time = 0,
    delay = options.delay or 0,
    ease = options.ease and Easing[options.ease] or Easing.ease_out_cubic,
    from = {},       -- 起始值
    to = properties, -- 目标值
    properties = {}, -- 要动画的属性名列表
    on_complete = options.on_complete,
    on_update = options.on_update,
    active = true,
    yoyo = options.yoyo or false,
    loops = options.loops or 0,  -- 循环次数，0=不循环，-1=无限
    _loop_count = 0,
    _direction = 1,  -- 1=正向，-1=反向（yoyo用）
  }

  -- 记录每个属性的起始值
  for key, _ in pairs(properties) do
    if target[key] ~= nil then
      table.insert(tween.properties, key)
      tween.from[key] = target[key]
    else
      self.logger:warn("[Animation] Target has no property: " .. key)
    end
  end

  table.insert(self.tweens, tween)
  return tween
end

-- ============================================================================
-- 每帧更新所有动画
-- ============================================================================
function AnimationSystem:update(dt)
  -- 倒序遍历，方便删除
  for i = #self.tweens, 1, -1 do
    local tween = self.tweens[i]
    if not tween.active then
      table.remove(self.tweens, i)
    else
      -- 延迟时间
      if tween.delay > 0 then
        tween.delay = tween.delay - dt
      else
        -- 更新时间
        if tween._direction == 1 then
          tween.time = tween.time + dt
        else
          tween.time = tween.time - dt
        end

        -- 计算进度（0~1）
        local progress = tween.time / tween.duration
        progress = Utils.clamp(progress, 0, 1)

        -- 应用缓动
        local eased = tween.ease(progress)

        -- 更新属性
        for _, key in ipairs(tween.properties) do
          local from = tween.from[key]
          local to = tween.to[key]
          local value = Utils.lerp(from, to, eased)
          tween.target[key] = value
        end

        -- 更新回调
        if tween.on_update then
          tween.on_update(progress)
        end

        -- 检查是否完成
        local finished = false
        if tween._direction == 1 and progress >= 1 then
          finished = true
        elseif tween._direction == -1 and progress <= 0 then
          finished = true
        end

        if finished then
          if tween.yoyo then
            -- 往返动画，反向
            tween._direction = -tween._direction
            -- 如果是一次往返完成了，算一次循环
            if tween._direction == 1 then
              tween._loop_count = tween._loop_count + 1
              if tween.loops > 0 and tween._loop_count >= tween.loops then
                self:_complete_tween(tween)
                table.remove(self.tweens, i)
              end
            end
          elseif tween.loops ~= 0 then
            -- 普通循环
            tween._loop_count = tween._loop_count + 1
            if tween.loops > 0 and tween._loop_count >= tween.loops then
              self:_complete_tween(tween)
              table.remove(self.tweens, i)
            else
              -- 重新开始
              tween.time = 0
            end
          else
            -- 普通动画，完成了
            self:_complete_tween(tween)
            table.remove(self.tweens, i)
          end
        end -- if finished
      end -- if delay > 0
    end -- if active
  end -- for
end

-- ============================================================================
-- 内部：动画完成处理
-- ============================================================================
function AnimationSystem:_complete_tween(tween)
  tween.active = false
  if tween.on_complete then
    tween.on_complete()
  end
end

-- ============================================================================
-- 停止所有动画
-- ============================================================================
function AnimationSystem:stop_all()
  for _, tween in ipairs(self.tweens) do
    tween.active = false
  end
  self.tweens = {}
end

-- ============================================================================
-- 停止某个对象的所有动画
-- ============================================================================
function AnimationSystem:stop_target(target)
  for i = #self.tweens, 1, -1 do
    if self.tweens[i].target == target then
      self.tweens[i].active = false
      table.remove(self.tweens, i)
    end
  end
end

-- ============================================================================
-- 获取当前活跃动画数量
-- ============================================================================
function AnimationSystem:get_active_count()
  return #self.tweens
end

-- ============================================================================
-- 全局默认动画系统实例
-- ============================================================================
local _default_system = nil

function AnimationSystem.get_default()
  if not _default_system then
    _default_system = AnimationSystem.new()
  end
  return _default_system
end

-- 快捷方法
function AnimationSystem.tween(target, duration, props, opts)
  return AnimationSystem.get_default():tween(target, duration, props, opts)
end
function AnimationSystem.update(dt)
  AnimationSystem.get_default():update(dt)
end
function AnimationSystem.stop_all()
  AnimationSystem.get_default():stop_all()
end

-- 导出缓动函数
AnimationSystem.Easing = Easing

return AnimationSystem
