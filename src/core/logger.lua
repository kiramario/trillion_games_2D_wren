-- ============================================================================
-- 日志系统
-- 功能：分级日志输出，支持 DEBUG/INFO/WARN/ERROR 四个级别
-- 类比：JS 的 console.log/warn/error，Java 的 log4j/slf4j
-- ============================================================================

-- 日志级别
local LOG_LEVELS = {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3
}

-- 日志颜色（ANSI 转义码，控制台彩色显示）
local LOG_COLORS = {
  DEBUG = "\27[36m",   -- 青色
  INFO = "\27[32m",    -- 绿色
  WARN = "\27[33m",    -- 黄色
  ERROR = "\27[31m",   -- 红色
  RESET = "\27[0m"     -- 重置
}

local Logger = {}
Logger.__index = Logger

-- ============================================================================
-- 创建新的日志实例
-- @param string name 日志器名称（可选）
-- @param string level 初始日志级别
-- @return Logger
-- ============================================================================
function Logger.new(name, level)
  local self = setmetatable({}, Logger)

  self.name = name or "default"
  self.level = LOG_LEVELS[level] or LOG_LEVELS.DEBUG
  self.show_time = true
  self.show_color = true

  return self
end

-- ============================================================================
-- 设置日志级别
-- @param string level DEBUG/INFO/WARN/ERROR
-- ============================================================================
function Logger:set_level(level)
  self.level = LOG_LEVELS[level] or LOG_LEVELS.DEBUG
end

-- ============================================================================
-- 获取当前时间字符串
-- @return string 格式 HH:MM:SS
-- ============================================================================
local function _get_time_str()
  -- os.date 是 Lua 标准库函数，类似 JS 的 new Date().toLocaleTimeString()
  return os.date("%H:%M:%S")
end

-- ============================================================================
-- 格式化日志消息
-- ============================================================================
function Logger:_format_message(level_name, msg)
  local parts = {}

  -- 时间
  if self.show_time then
    table.insert(parts, "[" .. _get_time_str() .. "]")
  end

  -- 日志级别
  if self.show_color then
    table.insert(parts, LOG_COLORS[level_name] .. "[" .. level_name .. "]" .. LOG_COLORS.RESET)
  else
    table.insert(parts, "[" .. level_name .. "]")
  end

  -- 日志器名称（如果有的话）
  if self.name ~= "default" then
    table.insert(parts, "[" .. self.name .. "]")
  end

  -- 消息内容
  table.insert(parts, tostring(msg))

  return table.concat(parts, " ")
end

-- ============================================================================
-- 输出日志
-- ============================================================================
function Logger:_log(level_name, msg)
  local level = LOG_LEVELS[level_name]
  if level < self.level then
    return  -- 级别不够，不输出
  end
  print(self:_format_message(level_name, msg))
end

-- ============================================================================
-- 各等级的快捷方法
-- ============================================================================
function Logger:debug(msg)
  self:_log("DEBUG", msg)
end

function Logger:info(msg)
  self:_log("INFO", msg)
end

function Logger:warn(msg)
  self:_log("WARN", msg)
end

function Logger:error(msg)
  self:_log("ERROR", msg)
end

-- ============================================================================
-- 全局默认日志实例
-- 大部分时候直接用这个就行，不用每次都 new
-- ============================================================================
local _default_logger = Logger.new("default", "DEBUG")

function Logger.get_default()
  return _default_logger
end

function Logger.set_default_level(level)
  _default_logger:set_level(level)
end

-- 也可以直接调用 Logger.debug() 等，就是用默认实例
function Logger.debug(msg)
  _default_logger:debug(msg)
end
function Logger.info(msg)
  _default_logger:info(msg)
end
function Logger.warn(msg)
  _default_logger:warn(msg)
end
function Logger.error(msg)
  _default_logger:error(msg)
end

return Logger
