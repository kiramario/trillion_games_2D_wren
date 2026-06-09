-- ============================================================================
-- 通用工具函数
-- 功能：各种通用的工具函数，数学、表格、字符串等
-- 类比：JS 的 Lodash，Python 的工具模块，Java 的 Guava
-- ============================================================================

local Utils = {}

-- ============================================================================
-- 数学工具
-- ============================================================================

-- 限制数值在 min 和 max 之间
-- 类比：JS 的 Math.clamp，很多语言都有这个函数
function Utils.clamp(value, min, max)
  if value < min then return min end
  if value > max then return max end
  return value
end

-- 线性插值
-- 类比：lerp 函数，游戏里常用
function Utils.lerp(a, b, t)
  return a + (b - a) * t
end

-- 计算两点之间的距离
function Utils.distance(x1, y1, x2, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end

-- 角度转弧度
function Utils.deg_to_rad(deg)
  return deg * math.pi / 180
end

-- 弧度转角度
function Utils.rad_to_deg(rad)
  return rad * 180 / math.pi
end

-- 随机浮点数
function Utils.random_float(min, max)
  return min + math.random() * (max - min)
end

-- 随机整数（包含 min 和 max）
function Utils.random_int(min, max)
  return math.floor(math.random() * (max - min + 1)) + min
end

-- ============================================================================
-- 表格（table）工具
-- Lua 的 table 类似 JS 的对象 + 数组的结合体
-- ============================================================================

-- 复制一个表（浅拷贝）
-- 类比：JS 的 Object.assign 或者 {...obj}
function Utils.shallow_copy(t)
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = v
  end
  return copy
end

-- 复制一个表（深拷贝，递归）
-- 类比：JS 的 JSON.parse(JSON.stringify(obj))，但更强大
function Utils.deep_copy(t)
  if type(t) ~= "table" then
    return t
  end
  local copy = {}
  for k, v in pairs(t) do
    copy[Utils.deep_copy(k)] = Utils.deep_copy(v)
  end
  return copy
end

-- 获取表的长度（对非数组的表也有效）
-- 类比：JS 的 Object.keys(obj).length
function Utils.table_length(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

-- 检查表里是否包含某个值
function Utils.table_contains(t, value)
  for _, v in pairs(t) do
    if v == value then
      return true
    end
  end
  return false
end

-- 查找值的 key（第一个匹配的）
function Utils.table_find(t, value)
  for k, v in pairs(t) do
    if v == value then
      return k
    end
  end
  return nil
end

-- 合并两个表（后面的覆盖前面的）
-- 类比：JS 的 Object.assign
function Utils.table_merge(t1, t2)
  local result = Utils.shallow_copy(t1)
  for k, v in pairs(t2) do
    result[k] = v
  end
  return result
end

-- 反转数组
function Utils.array_reverse(arr)
  local result = {}
  for i = #arr, 1, -1 do
    table.insert(result, arr[i])
  end
  return result
end

--  ============================================================================
-- 字符串工具
-- ============================================================================

-- 字符串是否以某个前缀开头
-- 类比：JS 的 startsWith
function Utils.starts_with(str, prefix)
  return string.sub(str, 1, string.len(prefix)) == prefix
end

-- 字符串是否以某个后缀结尾
-- 类比：JS 的 endsWith
function Utils.ends_with(str, suffix)
  return suffix == "" or string.sub(str, -string.len(suffix)) == suffix
end

-- 分割字符串
-- 类比：JS 的 split
function Utils.split(str, sep)
  sep = sep or "%s"  -- 默认按空格分割
  local parts = {}
  for part in string.gmatch(str, "([^" .. sep .. "]+)") do
    table.insert(parts, part)
  end
  return parts
end

-- 去掉字符串首尾空白
-- 类比：JS 的 trim
function Utils.trim(str)
  return string.match(str, "^%s*(.-)%s*$")
end

-- ============================================================================
-- 颜色工具
-- ============================================================================

-- 把 0-255 的颜色值转换成 0-1 的（LÖVE2D 用 0-1）
function Utils.rgb(r, g, b, a)
  a = a or 255
  return r / 255, g / 255, b / 255, a / 255
end

-- 十六进制颜色转 RGB
-- 类比：JS 的十六进制颜色解析
function Utils.hex_color(hex, alpha)
  alpha = alpha or 1
  -- 去掉 # 号
  hex = hex:gsub("#", "")
  local r = tonumber("0x" .. hex:sub(1, 2)) / 255
  local g = tonumber("0x" .. hex:sub(3, 4)) / 255
  local b = tonumber("0x" .. hex:sub(5, 6)) / 255
  return r, g, b, alpha
end

-- ============================================================================
-- 其他工具
-- ============================================================================

-- 检查值是否在范围内
function Utils.in_range(value, min, max)
  return value >= min and value <= max
end

-- 符号函数（正返回 1，负返回 -1，零返回 0）
function Utils.sign(value)
  if value > 0 then return 1 end
  if value < 0 then return -1 end
  return 0
end

-- 打印表的内容（调试用）
function Utils.print_table(t, indent)
  indent = indent or 0
  local prefix = string.rep("  ", indent)
  if type(t) ~= "table" then
    print(prefix .. tostring(t))
    return
  end
  for k, v in pairs(t) do
    if type(v) == "table" then
      print(prefix .. tostring(k) .. ":")
      Utils.print_table(v, indent + 1)
    else
      print(prefix .. tostring(k) .. ": " .. tostring(v))
    end
  end
end

return Utils
