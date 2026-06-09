--[[
    模块名: main.lua
    所属层: 入口层
    功能: LÖVE2D 程序入口，初始化所有核心模块
    类比: 类似 JS 的 index.js，Python 的 if __name__ == "__main__"
    版本: v0.1.0 - 基础脚手架
--]]

-- 导入核心模块
local Logger = require("src.core.logger")
local Config = require("src.core.config")
local InputManager = require("src.core.input_manager")
local SceneManager = require("src.core.scene_manager")
local ResourceManager = require("src.core.resource_manager")
local Utils = require("src.core.utils")

-- 导入测试场景
local TestSceneA = require("src.game.scenes.test_scene_a")
local TestSceneB = require("src.game.scenes.test_scene_b")

-- 全局游戏对象（尽量少用全局，这里是为了方便各个模块访问）
-- 类比：类似 JS 的 window.game，或者单例模式
Game = {
    version = "v0.1.0",
    logger = Logger,
    config = Config,
    input = InputManager,
    scenes = SceneManager,
    resources = ResourceManager,
    utils = Utils,

    -- 游戏状态
    is_running = true,
    debug_mode = true,
}

-- ============================================================================
-- 游戏加载
-- 类比：JS 的 DOMContentLoaded，或者 Java 的 main 方法
-- ============================================================================
function love.load(arg)
    Logger.info("========================================")
    Logger.info("游戏启动中...")
    Logger.info("版本: " .. Game.version)
    Logger.info("========================================")

    -- 1. 初始化日志
    Logger.set_default_level("DEBUG")
    Logger.debug("日志系统初始化完成")

    -- 2. 初始化配置
    Logger.debug("配置系统初始化完成")

    -- 3. 初始化输入系统
    InputManager.init()
    Logger.debug("输入系统初始化完成")

    -- 4. 初始化资源管理器
    ResourceManager.init()
    Logger.debug("资源管理器初始化完成")

    -- 5. 初始化场景管理器，注册所有场景
    SceneManager.init()
    SceneManager.register("test_a", TestSceneA)
    SceneManager.register("test_b", TestSceneB)
    Logger.debug("场景管理器初始化完成，已注册 2 个测试场景")

    -- 6. 切换到初始场景（测试场景 A）
    SceneManager.switch("test_a")
    Logger.info("初始场景加载完成: 测试场景 A")

    -- 7. 启动完成
    Logger.info("游戏启动成功！")
    Logger.info("操作说明：")
    Logger.info("  - 空格键：切换场景")
    Logger.info("  - F1：切换调试模式")
    Logger.info("  - ESC：退出游戏")
    Logger.info("========================================")
end

-- ============================================================================
-- 每帧更新
-- 类比：JS 的 requestAnimationFrame 回调
-- @param dt number 距离上一帧的秒数（delta time）
-- ============================================================================
function love.update(dt)
    if not Game.is_running then
        return
    end

    -- 1. 更新输入系统（必须放在最前面，清空上一帧的按键状态）
    InputManager.update(dt)

    -- 2. 更新当前场景
    SceneManager.update(dt)

    -- 3. F1 切换调试模式
    if InputManager.is_key_pressed("f1") then
        Game.debug_mode = not Game.debug_mode
        Logger.info("调试模式: " .. (Game.debug_mode and "开启" or "关闭"))
    end

    -- 4. ESC 退出
    if InputManager.is_key_pressed("cancel") then
        love.event.quit()
    end
end

-- ============================================================================
-- 每帧绘制
-- ============================================================================
function love.draw()
    -- 1. 绘制当前场景
    SceneManager.draw()

    -- 2. 调试信息
    if Game.debug_mode then
        _draw_debug_info()
    end
end

-- ============================================================================
-- 绘制调试信息
-- ============================================================================
function _draw_debug_info()
    -- 半透明背景
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 10, 10, 260, 130)

    -- 文字
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("版本: " .. Game.version, 20, 20)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 20, 40)
    love.graphics.print("场景: " .. (SceneManager.current_scene_name or "unknown"), 20, 60)
    love.graphics.print("栈深度: " .. SceneManager.get_stack_depth(), 20, 80)
    love.graphics.print("调试模式: 开启 (F1 关闭)", 20, 100)
end

-- ============================================================================
-- 键盘按下事件
-- ============================================================================
function love.keypressed(key, scancode, isrepeat)
    InputManager.keypressed(key, scancode, isrepeat)
end

-- ============================================================================
-- 键盘松开事件
-- ============================================================================
function love.keyreleased(key, scancode)
    InputManager.keyreleased(key, scancode)
end

-- ============================================================================
-- 鼠标按下事件
-- ============================================================================
function love.mousepressed(x, y, button, istouch, presses)
    InputManager.mousepressed(x, y, button, istouch, presses)
end

-- ============================================================================
-- 鼠标松开事件
-- ============================================================================
function love.mousereleased(x, y, button, istouch, presses)
    InputManager.mousereleased(x, y, button, istouch, presses)
end

-- ============================================================================
-- 鼠标移动事件
-- ============================================================================
function love.mousemoved(x, y, dx, dy, istouch)
    InputManager.mousemoved(x, y, dx, dy, istouch)
end

-- ============================================================================
-- 鼠标滚轮事件
-- ============================================================================
function love.wheelmoved(x, y)
    InputManager.wheelmoved(x, y)
end

-- ============================================================================
-- 窗口大小改变
-- ============================================================================
function love.resize(w, h)
    SceneManager.resize(w, h)
end

-- ============================================================================
-- 游戏退出
-- ============================================================================
function love.quit()
    Logger.info("游戏退出中...")
    SceneManager.exit()
    ResourceManager:unload_all()
    Logger.info("游戏已退出")
    Logger.info("========================================")
end
