--[[
    文件名：board.lua
    功能：中国象棋棋盘实体
    说明：包含棋盘数据结构、坐标转换、渲染
    作者：wren
    创建日期：2026-06-09
    依赖：core.logger, core.config
]]

local Logger = require("core.logger")

-- 棋盘类
local Board = {}
Board.__index = Board

-- 棋盘常量
-- 中国象棋是9列10行（9路10线）
Board.COLS = 9   -- 列数（x方向）
Board.ROWS = 10  -- 行数（y方向）
Board.RIVER_ROW = 5  -- 楚河汉界在第5行和第6行之间（0-indexed的话，行4和行5之间）

--[[
    构造函数
    参数：
        x, y (number) - 棋盘在屏幕上的中心位置
        cell_size (number) - 每个格子的大小（像素）
    返回：新的棋盘对象
]]
function Board.new(x, y, cell_size)
    local self = setmetatable({}, Board)
    
    -- 棋盘中心位置
    self.x = x or 0
    self.y = y or 0
    
    -- 格子大小
    self.cell_size = cell_size or 60
    
    -- 棋盘的像素尺寸
    self.width = (Board.COLS - 1) * self.cell_size   -- 8格宽
    self.height = (Board.ROWS - 1) * self.cell_size  -- 9格高
    
    -- 棋盘背景颜色（木纹色）
    self.bg_color = {0.75, 0.6, 0.4, 1}  -- 浅棕色
    self.border_color = {0.4, 0.25, 0.1, 1}  -- 深棕色边框
    self.line_color = {0.2, 0.15, 0.05, 1}  -- 深棕色线条
    self.river_color = {0.6, 0.7, 0.8, 0.3}  -- 浅蓝色河流
    
    -- 边缘暗角强度（营造纵深感）
    self.vignette_strength = 0.3
    
    Logger.debug("棋盘创建完成，格子大小：" .. self.cell_size .. "px")
    return self
end

--[[
    设置棋盘位置（中心）
    参数：
        x, y (number) - 中心坐标
]]
function Board:set_position(x, y)
    self.x = x
    self.y = y
end

--[[
    设置格子大小
    参数：
        size (number) - 新的格子大小
]]
function Board:set_cell_size(size)
    self.cell_size = size
    self.width = (Board.COLS - 1) * self.cell_size
    self.height = (Board.ROWS - 1) * self.cell_size
end

--[[
    棋盘坐标 转 屏幕坐标
    棋盘坐标：col 0-8（列），row 0-9（行）
    屏幕坐标：像素位置（棋盘左上角为基准？不，中心为基准？）
    注意：这里的屏幕坐标是相对于棋盘原点（左上角）的，还是相对于棋盘中心的？
    我们用：棋盘左上角为棋盘坐标系的原点，(0,0)在左上角
    但棋盘整体位置是self.x, self.y（中心）
    
    参数：
        col, row (number) - 棋盘坐标（0-8, 0-9），可以是小数
    返回：屏幕坐标 screen_x, screen_y
]]
function Board:board_to_screen(col, row)
    -- 棋盘左上角的屏幕坐标
    local left = self.x - self.width / 2
    local top = self.y - self.height / 2
    
    -- 格子的坐标是交叉点，所以直接乘cell_size
    local screen_x = left + col * self.cell_size
    local screen_y = top + row * self.cell_size
    
    return screen_x, screen_y
end

--[[
    屏幕坐标 转 棋盘坐标
    参数：
        screen_x, screen_y (number) - 屏幕坐标
    返回：棋盘坐标 col, row（可能是小数，需要取整的话外面处理）
]]
function Board:screen_to_board(screen_x, screen_y)
    -- 棋盘左上角的屏幕坐标
    local left = self.x - self.width / 2
    local top = self.y - self.height / 2
    
    local col = (screen_x - left) / self.cell_size
    local row = (screen_y - top) / self.cell_size
    
    return col, row
end

--[[
    检查棋盘坐标是否在棋盘范围内
    参数：
        col, row (number) - 棋盘坐标（整数）
    返回：true/false
]]
function Board:is_valid_position(col, row)
    return col >= 0 and col < Board.COLS and row >= 0 and row < Board.ROWS
end

--[[
    检查某个位置是否在楚河汉界的哪一边
    参数：
        row (number) - 行号
    返回："red"（红方，下方，行号大的一侧） 或 "black"（黑方，上方，行号小的一侧）
    注意：红方在下（行5-9），黑方在上（行0-4），楚河汉界在中间
]]
function Board:get_side(row)
    if row < 5 then
        return "black"  -- 上方是黑方
    else
        return "red"    -- 下方是红方
    end
end

--[[
    检查两个位置之间是否有棋子阻挡（直线）
    用于车、炮的走法判断
    参数：
        from_col, from_row - 起点
        to_col, to_row - 终点
        get_piece_func(col, row) - 获取某个位置棋子的函数，返回nil表示空
    返回：
        has_piece (boolean) - 中间是否有棋子
        count (number) - 中间棋子数量
]]
function Board:count_pieces_between(from_col, from_row, to_col, to_row, get_piece_func)
    local count = 0
    
    -- 同一行（横向）
    if from_row == to_row then
        local min_col = math.min(from_col, to_col)
        local max_col = math.max(from_col, to_col)
        for col = min_col + 1, max_col - 1 do
            if get_piece_func(col, from_row) then
                count = count + 1
            end
        end
    -- 同一列（纵向）
    elseif from_col == to_col then
        local min_row = math.min(from_row, to_row)
        local max_row = math.max(from_row, to_row)
        for row = min_row + 1, max_row - 1 do
            if get_piece_func(from_col, row) then
                count = count + 1
            end
        end
    else
        -- 不是直线，返回-1表示无效
        return false, -1
    end
    
    return count > 0, count
end

--[[
    绘制棋盘
    说明：直接绘制，V0.1阶段先不用分层
]]
function Board:draw()
    love.graphics.push()
    
    -- ===== 1. 棋盘背景 =====
    -- 画一个稍大的背景板，带边框，营造棋盘厚度感
    local margin = self.cell_size * 0.5  -- 边框外的边距
    local bg_x = self.x - self.width / 2 - margin
    local bg_y = self.y - self.height / 2 - margin
    local bg_w = self.width + margin * 2
    local bg_h = self.height + margin * 2
    
    -- 底层深色（模拟厚度阴影）
    love.graphics.setColor(0.3, 0.2, 0.1, 1)
    love.graphics.rectangle("fill", bg_x + 4, bg_y + 4, bg_w, bg_h, 8, 8)
    
    -- 主背景
    love.graphics.setColor(self.bg_color)
    love.graphics.rectangle("fill", bg_x, bg_y, bg_w, bg_h, 8, 8)
    
    -- 边框
    love.graphics.setColor(self.border_color)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", bg_x, bg_y, bg_w, bg_h, 8, 8)
    love.graphics.setLineWidth(1)
    
    -- ===== 2. 网格线 =====
    love.graphics.setColor(self.line_color)
    love.graphics.setLineWidth(1.5)
    
    local left = self.x - self.width / 2
    local top = self.y - self.height / 2
    local right = self.x + self.width / 2
    local bottom = self.y + self.height / 2
    
    -- 竖线（9条）
    -- 注意：楚河汉界那里，竖线是断开的
    for col = 0, Board.COLS - 1 do
        local x = left + col * self.cell_size
        
        if col == 0 or col == Board.COLS - 1 then
            -- 最左和最右的竖线是连续的（边框线）
            love.graphics.setLineWidth(2)
            love.graphics.line(x, top, x, bottom)
            love.graphics.setLineWidth(1.5)
        else
            -- 中间的竖线，楚河汉界处断开
            love.graphics.line(x, top, x, top + 4 * self.cell_size)  -- 上半部分
            love.graphics.line(x, top + 5 * self.cell_size, x, bottom)  -- 下半部分
        end
    end
    
    -- 横线（10条）
    for row = 0, Board.ROWS - 1 do
        local y = top + row * self.cell_size
        love.graphics.line(left, y, right, y)
    end
    
    -- ===== 3. 楚河汉界 =====
    -- 先画一条浅蓝的横条表示河流
    local river_y = top + 4.5 * self.cell_size
    local river_height = self.cell_size * 0.8
    love.graphics.setColor(self.river_color)
    love.graphics.rectangle("fill", left, river_y - river_height / 2, self.width, river_height)
    
    -- 楚河汉界文字
    love.graphics.setColor(0.3, 0.2, 0.1, 0.8)
    local river_font = love.graphics.newFont(math.floor(self.cell_size * 0.7))
    love.graphics.setFont(river_font)
    
    local chu_he = "楚 河"
    local han_jie = "汉 界"
    
    local chu_x = left + self.width * 0.25 - river_font:getWidth(chu_he) / 2
    local han_x = left + self.width * 0.75 - river_font:getWidth(han_jie) / 2
    local text_y = river_y - river_font:getHeight() / 2
    
    love.graphics.print(chu_he, chu_x, text_y)
    love.graphics.print(han_jie, han_x, text_y)
    
    -- 恢复默认字体
    love.graphics.setFont(love.graphics.newFont(16))
    
    -- ===== 4. 九宫格斜线 =====
    -- 上方九宫格（黑方，行0-2，列3-5）
    -- 左上到右下
    love.graphics.line(
        left + 3 * self.cell_size, top + 0 * self.cell_size,
        left + 5 * self.cell_size, top + 2 * self.cell_size
    )
    -- 右上到左下
    love.graphics.line(
        left + 5 * self.cell_size, top + 0 * self.cell_size,
        left + 3 * self.cell_size, top + 2 * self.cell_size
    )
    
    -- 下方九宫格（红方，行7-9，列3-5）
    -- 左上到右下
    love.graphics.line(
        left + 3 * self.cell_size, top + 7 * self.cell_size,
        left + 5 * self.cell_size, top + 9 * self.cell_size
    )
    -- 右上到左下
    love.graphics.line(
        left + 5 * self.cell_size, top + 7 * self.cell_size,
        left + 3 * self.cell_size, top + 9 * self.cell_size
    )
    
    -- ===== 5. 炮位和兵位标记（小圆点）=====
    -- 这些位置放小十字或者小圆点，是炮和兵的位置
    local mark_positions = {
        -- 黑方炮位
        {1, 2}, {7, 2},
        -- 红方炮位
        {1, 7}, {7, 7},
        -- 黑方兵位
        {0, 3}, {2, 3}, {4, 3}, {6, 3}, {8, 3},
        -- 红方兵位
        {0, 6}, {2, 6}, {4, 6}, {6, 6}, {8, 6},
    }
    
    love.graphics.setColor(self.line_color)
    for _, pos in ipairs(mark_positions) do
        local col, row = pos[1], pos[2]
        local x, y = self:board_to_screen(col, row)
        self:_draw_position_mark(x, y)
    end
    
    -- ===== 6. 边缘暗角（营造纵深感）=====
    -- 用径向渐变的暗角，V0.1先用简单的四角阴影
    -- 后面版本可以用shader做更真实的
    love.graphics.setBlendMode("multiply")  -- 相乘模式，变暗
    local vignette_size = margin * 2
    
    -- 四个角的暗角
    -- 左上角
    love.graphics.setColor(1 - self.vignette_strength, 1 - self.vignette_strength, 1 - self.vignette_strength, 1)
    -- 暂时先不画，等后面加shader，先留个位置
    
    love.graphics.setBlendMode("alpha")  -- 恢复正常混合模式
    
    love.graphics.pop()
end

--[[
    绘制位置标记（小十字，炮位兵位的标记）
    参数：
        x, y - 中心坐标
]]
function Board:_draw_position_mark(x, y)
    local size = self.cell_size * 0.1  -- 标记大小
    local line_len = self.cell_size * 0.15  -- 每根线的长度
    
    love.graphics.setLineWidth(1)
    
    -- 左上
    love.graphics.line(x - size - line_len, y - size, x - size, y - size)
    love.graphics.line(x - size, y - size - line_len, x - size, y - size)
    
    -- 右上
    love.graphics.line(x + size, y - size, x + size + line_len, y - size)
    love.graphics.line(x + size, y - size - line_len, x + size, y - size)
    
    -- 左下
    love.graphics.line(x - size - line_len, y + size, x - size, y + size)
    love.graphics.line(x - size, y + size, x - size, y + size + line_len)
    
    -- 右下
    love.graphics.line(x + size, y + size, x + size + line_len, y + size)
    love.graphics.line(x + size, y + size, x + size, y + size + line_len)
end

--[[
    自适应窗口大小，让棋盘刚好能放下
    参数：
        window_w, window_h (number) - 窗口大小
        padding (number) - 边距比例，默认0.1（10%）
]]
function Board:fit_to_window(window_w, window_h, padding)
    padding = padding or 0.1
    
    -- 可用空间
    local avail_w = window_w * (1 - padding * 2)
    local avail_h = window_h * (1 - padding * 2)
    
    -- 计算合适的格子大小
    local cell_w = avail_w / (Board.COLS - 1 + 1)  -- +1是因为左右各留半个格子的边距
    local cell_h = avail_h / (Board.ROWS - 1 + 1)
    
    local cell_size = math.floor(math.min(cell_w, cell_h))
    
    self:set_cell_size(cell_size)
    self.x = window_w / 2
    self.y = window_h / 2
    
    Logger.debug("棋盘自适应：格子大小 " .. cell_size .. "px，窗口 " .. window_w .. "x" .. window_h)
end

Logger.info("棋盘模块加载完成")

return Board
