--[[
    文件名：utils.lua
    功能：通用工具函数集合
    类比：相当于 JS 的 lodash 工具库，或 Java 的工具类
    作者：wren
    创建日期：2026-06-09
]]

local Utils = {}

--[[
    深度拷贝一个table
    注意：不处理循环引用，遇到循环引用会无限递归
    参数：
        orig (table) - 要拷贝的表
    返回：新的表
    类比：JS的 JSON.parse(JSON.stringify(obj)) 深拷贝，或 Java 的 clone()
]]
function Utils.deep_copy(orig)
    if type(orig) ~= "table" then
        return orig
    end
    
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == "table" then
            copy[k] = Utils.deep_copy(v)
        else
            copy[k] = v
        end
    end
    
    -- 拷贝metatable
    local mt = getmetatable(orig)
    if mt then
        setmetatable(copy, mt)
    end
    
    return copy
end

--[[
    浅拷贝一个table
    只拷贝第一层，嵌套的table还是引用
    参数：
        orig (table) - 要拷贝的表
    返回：新的表
]]
function Utils.shallow_copy(orig)
    if type(orig) ~= "table" then
        return orig
    end
    
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = v
    end
    
    return copy
end

--[[
    检查一个值是否在数组里
    参数：
        arr (table) - 数组（ipairs遍历的）
        val (any) - 要查找的值
    返回：true/false
    类比：JS的 Array.includes()，或 Python 的 in 操作符
]]
function Utils.array_contains(arr, val)
    for _, v in ipairs(arr) do
        if v == val then
            return true
        end
    end
    return false
end

--[[
    获取table的长度（包括非数字key的）
    注意：#table 只能算连续数字key的长度，这个函数算所有key的数量
    类比：JS的 Object.keys(obj).length
]]
function Utils.table_length(t)
    if type(t) ~= "table" then
        return 0
    end
    
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

--[[
    限制数值在最小值和最大值之间
    参数：
        value (number) - 要限制的值
        min_val (number) - 最小值
        max_val (number) - 最大值
    返回：限制后的值
    类比：JS的 Math.clamp()（较新的API），或自己写的三元表达式
]]
function Utils.clamp(value, min_val, max_val)
    if value < min_val then
        return min_val
    elseif value > max_val then
        return max_val
    else
        return value
    end
end

--[[
    线性插值
    参数：
        a (number) - 起始值
        b (number) - 结束值
        t (number) - 插值因子，0-1之间
    返回：插值结果
    说明：t=0返回a，t=1返回b，t=0.5返回中间值
    类比：游戏开发里常用的lerp函数
]]
function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

--[[
    四舍五入
    参数：
        n (number) - 数字
        decimals (number) - 小数位数，可选，默认0
    返回：四舍五入后的数字
]]
function Utils.round(n, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(n * mult + 0.5) / mult
end

--[[
    字符串分割
    参数：
        str (string) - 要分割的字符串
        sep (string) - 分隔符
    返回：分割后的数组
    类比：JS的 String.split()，Python的 str.split()
]]
function Utils.string_split(str, sep)
    if sep == nil then
        sep = "%s"  -- 默认按空白分割
    end
    
    local t = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(t, part)
    end
    
    return t
end

--[[
    字符串以某个前缀开头
    参数：
        str (string) - 字符串
        prefix (string) - 前缀
    返回：true/false
    类比：JS的 String.startsWith()
]]
function Utils.string_starts_with(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

--[[
    字符串以某个后缀结尾
    参数：
        str (string) - 字符串
        suffix (string) - 后缀
    返回：true/false
    类比：JS的 String.endsWith()
]]
function Utils.string_ends_with(str, suffix)
    return suffix == "" or string.sub(str, -string.len(suffix)) == suffix
end

--[[
    生成UUID（简单版，不是标准UUID，但足够游戏用）
    返回：随机字符串ID
    说明：用时间戳+随机数，重复概率极低
]]
function Utils.generate_id()
    local time_part = os.time()
    local random_part = math.random(100000, 999999)
    return string.format("%d_%d", time_part, random_part)
end

--[[
    打印一个table的内容（调试用）
    参数：
        t (table) - 要打印的表
        indent (number) - 缩进层数，内部递归用
]]
function Utils.print_table(t, indent)
    indent = indent or 0
    local indent_str = string.rep("  ", indent)
    
    if type(t) ~= "table" then
        print(indent_str .. tostring(t))
        return
    end
    
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(indent_str .. tostring(k) .. ":")
            Utils.print_table(v, indent + 1)
        else
            print(indent_str .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

--[[
    检查点是否在矩形内
    参数：
        px, py (number) - 点的坐标
        rx, ry (number) - 矩形左上角坐标
        rw, rh (number) - 矩形宽高
    返回：true/false
    说明：矩形坐标系是左上角为原点，y向下（跟LÖVE2D一致）
]]
function Utils.point_in_rect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

--[[
    两点之间的距离
    参数：
        x1, y1 (number) - 点1坐标
        x2, y2 (number) - 点2坐标
    返回：距离（number）
]]
function Utils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- 初始化随机数种子
-- 注意：Lua的math.random如果不设种子，每次启动序列都一样
math.randomseed(os.time())
-- 第一次调用random往往不够随机，先调一下
math.random()
math.random()
math.random()

return Utils
