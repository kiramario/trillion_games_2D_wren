--[[
    模块名: main.lua
    所属层: 入口层
    功能: LÖVE2D 程序入口，初始化所有核心模块
    类比: 类似 JS 的 index.js，Python 的 if __name__ == "__main__"
    版本: v0.2.0 - 渲染增强
--]]

-- 把 src 目录加入模块搜索路径，这样 require 的时候会去 src 里找
package.path = 'src/?.lua;src/?/init.lua;' .. package.path

-- 导入核心模块
local Logger = require("core.logger")
local Config = require("core.config")
local InputManager = require("core.input_manager")
local SceneManager = require("core.scene_manager")
local ResourceManager = require("core.resource_manager")
local RenderManager = require("core.render_manager")
local Camera = require("core.camera")
local Entity = require("core.entity")
local Animation = require("core.animation")
local Utils = require("core.utils")

-- 导入测试场景
local TestSceneA = require("game.scenes.test_scene_a")
local TestSceneB = require("game.scenes.test_scene_b")
local RenderTestScene = require("game.scenes.render_test")

-- 全局游戏对象（尽量少用全局，这里是为了方便各个模块访问）
-- 类比：类似 JS 的 window.game，或者单例模式
Game = {
    version = "v0.2.0",
    logger = Logger,
    config = Config,
    input = InputManager,
    scenes = SceneManager,
    resources = ResourceManager,
    render = RenderManager,
    camera = Camera,
    entity = Entity,
    animation = Animation,
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

    -- 5. 初始化渲染管理器
    local _ = RenderManager.get_default()
    Logger.debug("渲染管理器初始化完成")

    -- 6. 初始化动画系统
    local _ = Animation.get_default()
    Logger.debug("动画系统初始化完成")

    -- 7. 初始化场景管理器，注册所有场景
    SceneManager.init()
    SceneManager.register("test_a", TestSceneA)
    SceneManager.register("test_b", TestSceneB)
    SceneManager.register("render_test", RenderTestScene)
    Logger.debug("场景管理器初始化完成，已注册 3 个测试场景")

    -- 8. 切换到初始场景（渲染测试场景）
    SceneManager.switch("render_test")
    Logger.info("初始场景加载完成: 渲染测试场景")

    -- 9. 启动完成
    Logger.info("游戏启动成功！")
    Logger.info("操作说明：")
    Logger.info("  - WASD / 方向键：移动相机")
    Logger.info("  - 鼠标滚轮：缩放")
    Logger.info("  - 空格：相机震动")
    Logger.info("  - F1：切换调试模式")
    Logger.info("  - ESC：返回上一个场景 / 退出")
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
        -- 渲染管理器的调试模式也跟着切
        RenderManager.get_default().debug_mode = Game.debug_mode
    end

    -- 4. ESC 退出（如果场景栈只有一层，就退出游戏）
    if InputManager.is_key_pressed("escape") then
        if SceneManager.get_stack_depth() <= 1 then
            love.event.quit()
        else
            SceneManager.pop()
        end
    end
end

-- ============================================================================
-- 每帧绘制
-- ============================================================================
function love.draw()
    -- 1. 绘制当前场景
    SceneManager.draw()

    -- 2. 全局调试信息
    if Game.debug_mode then
        _draw_global_debug_info()
    end
end

-- ============================================================================
-- 绘制全局调试信息（左上角）
-- ============================================================================
function _draw_global_debug_info()
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 10, 10, 240, 120)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("版本: " .. Game.version, 20, 20)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 20, 40)
    
    local _, scene_name = SceneManager.get_current()
    love.graphics.print("场景: " .. (scene_name or "unknown"), 20, 60)
    love.graphics.print("场景栈: " .. SceneManager.get_stack_depth() .. " 层", 20, 80)
    love.graphics.print("动画数: " .. Animation.get_default():get_active_count(), 20, 100)
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
