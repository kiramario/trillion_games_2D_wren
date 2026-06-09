--[[
    文件名：piece.lua
    功能：中国象棋棋子实体
    作者：wren
    创建日期：2026-06-09
    依赖：core.logger
]]

local Logger = require("core.logger")

-- 棋子类
local Piece = {}
Piece.__index = Piece

-- 棋子类型常量
-- 象棋棋子类型：帅/将、仕/士、相/象、马、车、炮、兵/卒
Piece.TYPE = {
    KING = "king",       -- 将/帅
    ADVISOR = "advisor", -- 士/仕
    ELEPHANT = "elephant", -- 象/相
    HORSE = "horse",     -- 马
    CHARIOT = "chariot", -- 车
    CANNON = "cannon",   -- 炮
    PAWN = "pawn",       -- 兵/卒
}

-- 棋子颜色（阵营）
Piece.COLOR = {
    RED = "red",     -- 红方（下方）
    BLACK = "black", -- 黑方（上方）
}

-- 棋子对应的汉字
-- 红方和黑方用字不一样（比如帅/将，兵/卒）
local PIECE_CHARS = {
    red = {
        king = "帅",
        advisor = "仕",
        elephant = "相",
        horse = "马",
        chariot = "车",
        cannon = "炮",
        pawn = "兵",
    },
    black = {
        king = "将",
        advisor = "士",
        elephant = "象",
        horse = "马",
        chariot = "车",
        cannon = "炮",
        pawn = "卒",
    }
}

-- 棋子的分值（AI用，或者显示用）
local PIECE_VALUES = {
    king = 10000,   -- 帅，无价
    chariot = 900,  -- 车
    horse = 400,    -- 马
    cannon = 450,   -- 炮
    elephant = 200, -- 象
    advisor = 200,  -- 士
    pawn = 100,     -- 兵
}

--[[
    构造函数
    参数：
        piece_type (string) - 棋子类型，Piece.TYPE里的常量
        color (string) - 棋子颜色，Piece.COLOR里的常量
        col, row (number) - 棋盘坐标
    返回：新的棋子对象
]]
function Piece.new(piece_type, color, col, row)
    local self = setmetatable({}, Piece)
    
    -- 棋子类型
    self.type = piece_type
    
    -- 棋子颜色（阵营）
    self.color = color
    
    -- 棋盘坐标
    self.col = col or 0
    self.row = row or 0
    
    -- 屏幕坐标（渲染用，从棋盘坐标转换而来）
    self.x = 0
    self.y = 0
    
    -- 棋子是否被选中
    self.selected = false
    
    -- 棋子是否存活
    self.alive = true
    
    -- 棋子大小（相对格子大小的比例）
    self.size_ratio = 0.85
    
    -- 动画相关
    self.target_x = nil  -- 目标X（移动动画）
    self.target_y = nil  -- 目标Y
    self.move_time = 0   -- 移动时间
    self.move_duration = 0.2  -- 移动动画时长（秒）
    self.is_moving = false  -- 是否在移动中
    
    Logger.debug(string.format("创建棋子：%s %s，位置(%d, %d)", 
        color, PIECE_CHARS[color][piece_type], col, row))
    
    return self
end

--[[
    获取棋子的汉字
    返回：字符串
]]
function Piece:get_char()
    return PIECE_CHARS[self.color][self.type]
end

--[[
    获取棋子的分值
    返回：number
]]
function Piece:get_value()
    return PIECE_VALUES[self.type]
end

--[[
    设置棋盘坐标
    参数：
        col, row (number) - 新的棋盘坐标
        animate (boolean) - 是否播放移动动画，默认false
]]
function Piece:set_position(col, row, animate)
    animate = animate or false
    
    if not animate then
        self.col = col
        self.row = row
        self.is_moving = false
    else
        -- 目标位置
        self.target_col = col
        self.target_row = row
        self.move_time = 0
        self.is_moving = true
    end
end

--[[
    更新棋子（动画等）
    参数：
        dt (number) - 时间增量
        board (Board) - 棋盘对象，用来转换坐标
]]
function Piece:update(dt, board)
    -- 更新移动动画
    if self.is_moving and board then
        self.move_time = self.move_time + dt
        
        -- 计算进度，0到1
        local progress = self.move_time / self.move_duration
        
        if progress >= 1 then
            -- 动画结束
            progress = 1
            self.col = self.target_col
            self.row = self.target_row
            self.is_moving = false
        end
        
        -- 缓动效果（ease out，先快后慢）
        -- 用简单的平方缓动
        progress = 1 - (1 - progress) * (1 - progress)
        
        -- 计算插值后的坐标
        local start_x, start_y = board:board_to_screen(self.col, self.row)
        local end_x, end_y = board:board_to_screen(self.target_col, self.target_row)
        
        local Utils = require("core.utils")
        self.x = Utils.lerp(start_x, end_x, progress)
        self.y = Utils.lerp(start_y, end_y, progress)
    elseif board then
        -- 没在移动，直接用棋盘坐标转换
        self.x, self.y = board:board_to_screen(self.col, self.row)
    end
end

--[[
    绘制棋子
    参数：
        cell_size (number) - 格子大小，用来计算棋子尺寸
]]
function Piece:draw(cell_size)
    if not self.alive then
        return
    end
    
    local radius = cell_size * self.size_ratio / 2
    
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    
    -- ===== 棋子阴影（营造立体感）=====
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle("fill", 2, 3, radius)
    
    -- ===== 棋子本体 =====
    if self.color == "red" then
        -- 红方棋子：浅米色背景，红色字
        -- 外圈深棕色
        love.graphics.setColor(0.6, 0.4, 0.2, 1)
        love.graphics.circle("fill", 0, 0, radius)
        
        -- 内圈浅色
        love.graphics.setColor(0.95, 0.9, 0.8, 1)
        love.graphics.circle("fill", 0, 0, radius * 0.85)
        
        -- 文字颜色：红色
        love.graphics.setColor(0.8, 0.1, 0.1, 1)
    else
        -- 黑方棋子：浅米色背景，黑色字
        love.graphics.setColor(0.5, 0.35, 0.15, 1)
        love.graphics.circle("fill", 0, 0, radius)
        
        love.graphics.setColor(0.9, 0.85, 0.75, 1)
        love.graphics.circle("fill", 0, 0, radius * 0.85)
        
        -- 文字颜色：黑色
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
    end
    
    -- ===== 选中效果 =====
    if self.selected then
        -- 高亮外圈
        love.graphics.setLineWidth(3)
        love.graphics.setColor(1, 0.8, 0, 1)  -- 金黄色
        love.graphics.circle("line", 0, 0, radius + 3)
        love.graphics.setLineWidth(1)
        
        -- 稍微放大一点
        -- love.graphics.scale(1.1, 1.1)
    end
    
    -- ===== 棋子文字 =====
    local char = self:get_char()
    local font_size = math.floor(radius * 1.2)
    local font = love.graphics.newFont(font_size)
    love.graphics.setFont(font)
    
    local text_width = font:getWidth(char)
    local text_height = font:getHeight()
    
    love.graphics.print(char, -text_width / 2, -text_height / 2)
    
    -- 恢复默认字体
    love.graphics.setFont(love.graphics.newFont(16))
    
    love.graphics.pop()
end

--[[
    检查点是否在棋子范围内（点击检测用）
    参数：
        px, py (number) - 点的坐标（屏幕坐标）
        cell_size (number) - 格子大小
    返回：true/false
]]
function Piece:contains_point(px, py, cell_size)
    if not self.alive then
        return false
    end
    
    local radius = cell_size * self.size_ratio / 2
    local dx = px - self.x
    local dy = py - self.y
    return dx * dx + dy * dy <= radius * radius
end

Logger.info("棋子模块加载完成")

return Piece
