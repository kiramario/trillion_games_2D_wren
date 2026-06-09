--[[
    文件名：config.lua
    功能：全局配置管理，所有可调参数集中在这里
    类比：相当于 JS 的 config.js，或 Python 的 settings.py
    作者：wren
    创建日期：2026-06-09
    依赖：core.logger
]]

local Logger = require("core.logger")

local Config = {}

--[[
    配置分模块组织，每个模块一个子表
    好处：分类清晰，不会乱
    类比：Java里按类分配置，或者yaml配置文件的层级结构
]]

-- 图形相关配置
Config.graphics = {
    -- 背景色（RGBA，取值0-1）
    -- 类比：CSS的rgba，只是取值范围是0-1不是0-255
    background_color = {0.1, 0.12, 0.15, 1},
    
    -- 默认字体大小
    default_font_size = 16,
    
    -- 是否开启垂直同步
    vsync = true,
    
    -- 目标帧率
    target_fps = 60,
}

-- 渲染层配置（分层渲染，层级顺序在这里定义）
-- 数字越小越先绘制（在下面），数字越大越晚绘制（在上面）
-- 类比：CSS的z-index，或Photoshop的图层顺序
Config.render_layers = {
    BACKGROUND = 1,   -- 背景层（最底层）
    GAME = 2,         -- 游戏内容层
    EFFECT = 3,       -- 特效层（粒子、光影等）
    UI = 4,           -- UI层（按钮、文字等）
    DEBUG = 5,        -- 调试信息层（最上层）
}

-- 日志配置
Config.log = {
    -- 日志级别：DEBUG / INFO / WARN / ERROR
    level = "DEBUG",
}

-- 输入配置
Config.input = {
    -- 是否启用鼠标
    mouse_enabled = true,
    -- 是否启用键盘
    keyboard_enabled = true,
}

-- 游戏相关配置
Config.game = {
    -- 游戏名称
    name = "中国象棋",
    -- 版本号
    version = "0.5.0",
}

-- 棋盘相关配置
Config.board = {
    -- 棋盘格子默认大小
    default_cell_size = 60,
    -- 窗口边距比例
    padding_ratio = 0.1,
}

--[[
    获取配置项
    支持用点分隔的路径，比如 "graphics.background_color"
    参数：
        path (string) - 配置路径，用点分隔
        default (any) - 找不到时的默认值，可选
    返回：配置值
    示例：Config.get("graphics.background_color")
]]
function Config.get(path, default)
    -- 按点分割路径
    -- 类比：JS里的 lodash.get() 函数
    local keys = {}
    for key in string.gmatch(path, "([^%.]+)") do
        table.insert(keys, key)
    end
    
    local current = Config
    for _, key in ipairs(keys) do
        if current[key] ~= nil then
            current = current[key]
        else
            -- 找不到，返回默认值
            if default ~= nil then
                return default
            else
                Logger.warn("配置项不存在：" .. path)
                return nil
            end
        end
    end
    
    return current
end

--[[
    设置配置项
    支持点分隔路径
    参数：
        path (string) - 配置路径
        value (any) - 要设置的值
    示例：Config.set("log.level", "INFO")
]]
function Config.set(path, value)
    local keys = {}
    for key in string.gmatch(path, "([^%.]+)") do
        table.insert(keys, key)
    end
    
    if #keys == 0 then
        Logger.warn("无效的配置路径：" .. tostring(path))
        return
    end
    
    local current = Config
    -- 遍历到倒数第二个key
    for i = 1, #keys - 1 do
        local key = keys[i]
        if current[key] == nil then
            -- 不存在就创建新的表
            current[key] = {}
        end
        if type(current[key]) ~= "table" then
            Logger.warn("配置路径错误，中间项不是table：" .. path)
            return
        end
        current = current[key]
    end
    
    -- 设置最后一个key的值
    local last_key = keys[#keys]
    current[last_key] = value
    Logger.debug("配置项已更新：" .. path .. " = " .. tostring(value))
end

--[[
    打印所有配置（调试用）
]]
function Config.dump()
    Logger.debug("=== 当前配置 ===")
    -- 简单递归打印
    local function dump_table(t, indent)
        indent = indent or ""
        for k, v in pairs(t) do
            if type(v) == "table" then
                Logger.debug(indent .. k .. ":")
                dump_table(v, indent .. "  ")
            else
                Logger.debug(indent .. k .. " = " .. tostring(v))
            end
        end
    end
    dump_table(Config)
    Logger.debug("================")
end

Logger.info("配置系统初始化完成")

return Config
