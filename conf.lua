--[[
    模块名: conf.lua
    所属层: 配置层
    功能: LÖVE2D 引擎配置，在 love.load 之前加载
    类比: 类似 Web 项目的 vite.config.js 或者 package.json 里的配置
    说明: 这里设置的是引擎级别的配置，比如窗口大小、标题、帧率等
--]]

function love.conf(t)
    -- 游戏基本信息
    t.title = "Trillion Games 2D (wren)"  -- 窗口标题
    t.version = "11.0"                     -- 目标 LÖVE2D 版本
    t.identity = "trillion_games_2d_wren" -- 存档/配置目录名（在用户目录下）

    -- 窗口配置
    t.window.width = 960                   -- 窗口宽度
    t.window.height = 640                  -- 窗口高度
    t.window.resizable = true              -- 允许窗口缩放
    t.window.minwidth = 480                -- 最小宽度
    t.window.minheight = 320               -- 最小高度
    t.window.fullscreen = false            -- 默认不全屏
    t.window.fullscreentype = "desktop"    -- 全屏类型
    t.window.vsync = 1                     -- 垂直同步（1=开启，0=关闭）
    t.window.msaa = 0                      -- 抗锯齿（0=关闭）
    t.window.display = 1                   -- 默认显示器
    t.window.highdpi = true                -- 高 DPI 支持

    -- 模块配置（不需要的模块可以关掉，省资源）
    t.modules.audio = true                 -- 音频模块
    t.modules.data = true                  -- 数据模块
    t.modules.event = true                 -- 事件模块
    t.modules.font = true                  -- 字体模块
    t.modules.graphics = true              -- 图形模块
    t.modules.image = true                 -- 图片模块
    t.modules.joystick = false             -- 手柄模块（暂时不需要）
    t.modules.keyboard = true              -- 键盘模块
    t.modules.math = true                  -- 数学模块
    t.modules.mouse = true                 -- 鼠标模块
    t.modules.physics = false              -- 物理模块（暂时不需要）
    t.modules.sound = true                 -- 声音模块
    t.modules.system = true                -- 系统模块
    t.modules.thread = true                -- 线程模块
    t.modules.timer = true                 -- 定时器模块
    t.modules.touch = false                -- 触控模块（桌面版暂时不需要）
    t.modules.video = false                -- 视频模块（暂时不需要）
    t.modules.window = true                -- 窗口模块
end
