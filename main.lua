--[[
    模块名: main.lua
    所属层: 入口层
    功能: LÖVE2D 程序入口
    类比: 类似 JS 的 index.js，Python 的 if __name__ == "__main__"
    说明: V0.0.0 版本只有最简单的入口，能运行就行，后面版本逐步加功能
--]]

-- V0.0.0 版本：最简单的可运行版本
function love.load()
    -- 游戏启动时调用一次
    print("[INFO] 游戏启动成功！")
    print("[INFO] 版本: v0.0.0 - 项目初始化")
    print("[INFO] 按 ESC 退出游戏")
end

function love.update(dt)
    -- 每帧更新，dt 是距离上一帧的秒数
    -- V0.0.0 暂时空着
end

function love.draw()
    -- 每帧绘制
    -- 画个简单的欢迎文字
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Trillion Games 2D (wren)", 0, 250, 960, "center")
    love.graphics.printf("V0.0.0 - 项目初始化", 0, 300, 960, "center")
    love.graphics.printf("按 ESC 退出", 0, 380, 960, "center")
end

function love.keypressed(key)
    -- 键盘按下时调用
    if key == "escape" then
        love.event.quit()
    end
end

function love.quit()
    -- 退出时调用
    print("[INFO] 游戏退出")
end
