--[[
    文件名：logger.lua
    功能：日志系统，提供分级日志输出
    级别：DEBUG < INFO < WARN < ERROR
    类比：相当于 JS 的 console.log/warn/error，或 Java 的 log4j
    作者：wren
    创建日期：2026-06-09
]]

local Logger = {}

-- 日志级别常量
-- 类比：枚举类型
local LOG_LEVEL = {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3
}

-- 当前日志级别，低于这个级别的日志不输出
Logger._level = LOG_LEVEL.DEBUG

-- 日志颜色（ANSI转义码，控制台显示颜色）
-- 类比：终端里的彩色输出，跟JS的console样式类似
local LOG_COLORS = {
    DEBUG = "\27[36m",   -- 青色
    INFO = "\27[32m",    -- 绿色
    WARN = "\27[33m",    -- 黄色
    ERROR = "\27[31m",   -- 红色
    RESET = "\27[0m"     -- 重置颜色
}

--[[
    获取当前时间字符串，用于日志时间戳
    返回：时间字符串，格式：HH:MM:SS
]]
local function _get_time_str()
    -- os.date 是Lua标准库的日期函数
    -- 类比：JS的new Date().toLocaleTimeString()
    return os.date("%H:%M:%S")
end

--[[
    格式化日志消息
    参数：
        level (string) - 日志级别名称
        msg (string) - 日志消息
    返回：格式化后的完整日志字符串
]]
local function _format_message(level, msg)
    local time_str = _get_time_str()
    local color = LOG_COLORS[level]
    local reset = LOG_COLORS.RESET
    return string.format("[%s] %s[%s]%s %s", time_str, color, level, reset, tostring(msg))
end

--[[
    输出 DEBUG 级别的日志
    参数：
        msg (any) - 日志内容，会自动转成字符串
]]
function Logger.debug(msg)
    if Logger._level <= LOG_LEVEL.DEBUG then
        print(_format_message("DEBUG", msg))
    end
end

--[[
    输出 INFO 级别的日志
    参数：
        msg (any) - 日志内容
]]
function Logger.info(msg)
    if Logger._level <= LOG_LEVEL.INFO then
        print(_format_message("INFO", msg))
    end
end

--[[
    输出 WARN 级别的日志（警告）
    参数：
        msg (any) - 日志内容
]]
function Logger.warn(msg)
    if Logger._level <= LOG_LEVEL.WARN then
        print(_format_message("WARN", msg))
    end
end

--[[
    输出 ERROR 级别的日志（错误）
    参数：
        msg (any) - 日志内容
]]
function Logger.error(msg)
    if Logger._level <= LOG_LEVEL.ERROR then
        print(_format_message("ERROR", msg))
        -- 错误日志可以额外加堆栈信息，方便调试
        -- debug.traceback() 是Lua的调试函数，获取调用栈
        -- 类比：JS的console.trace()，或Java的e.printStackTrace()
        local trace = debug.traceback("", 2)
        if trace and trace ~= "" then
            print(_format_message("ERROR", "堆栈信息：" .. trace))
        end
    end
end

--[[
    设置日志级别
    参数：
        level (string) - "DEBUG", "INFO", "WARN", "ERROR"
]]
function Logger.set_level(level)
    local level_upper = string.upper(level)
    if LOG_LEVEL[level_upper] ~= nil then
        Logger._level = LOG_LEVEL[level_upper]
        Logger.info("日志级别设置为：" .. level_upper)
    else
        Logger.warn("无效的日志级别：" .. tostring(level))
    end
end

-- 把日志级别常量也暴露出去，外部可以用
Logger.LEVEL = LOG_LEVEL

return Logger
