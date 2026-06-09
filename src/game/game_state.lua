--[[
    文件名：game_state.lua
    功能：游戏状态管理，管理棋盘上的棋子、回合、游戏进度等
    作者：wren
    创建日期：2026-06-09
    依赖：core.logger, entities.piece
]]

local Logger = require("core.logger")
local Piece = require("entities.piece")

local GameState = {}
GameState.__index = GameState

--[[
    构造函数
    返回：新的游戏状态对象
]]
function GameState.new()
    local self = setmetatable({}, GameState)
    
    -- 所有棋子列表
    self.pieces = {}
    
    -- 棋盘上的棋子二维数组（方便快速查找某个位置有没有棋子）
    -- board[col][row] = piece 或者 nil
    -- col 0-8, row 0-9
    self.board = {}
    for col = 0, 8 do
        self.board[col] = {}
    end
    
    -- 当前回合（红方先走）
    self.current_turn = "red"
    
    -- 游戏是否结束
    self.game_over = false
    self.winner = nil  -- "red" / "black" / nil
    
    -- 选中的棋子
    self.selected_piece = nil
    
    -- 走子历史（用来悔棋）
    self.move_history = {}
    
    Logger.info("游戏状态创建完成")
    return self
end

--[[
    初始化棋盘，摆放初始棋子
    中国象棋初始布局
]]
function GameState:init_board()
    Logger.info("初始化棋盘，摆放棋子")
    
    -- 清空
    self.pieces = {}
    for col = 0, 8 do
        self.board[col] = {}
    end
    
    -- ===== 黑方棋子（上方，row 0-4）=====
    
    -- 黑方底线棋子（row 0）
    -- 车 马 象 士 将 士 象 马 车
    local baseline_pieces = {
        "chariot", "horse", "elephant", "advisor", "king",
        "advisor", "elephant", "horse", "chariot"
    }
    for col = 0, 8 do
        local piece = Piece.new(baseline_pieces[col + 1], "black", col, 0)
        self:add_piece(piece)
    end
    
    -- 黑方炮（row 2）
    local piece = Piece.new("cannon", "black", 1, 2)
    self:add_piece(piece)
    piece = Piece.new("cannon", "black", 7, 2)
    self:add_piece(piece)
    
    -- 黑方兵（row 3）
    for i = 0, 4 do
        local col = i * 2  -- 0, 2, 4, 6, 8
        local piece = Piece.new("pawn", "black", col, 3)
        self:add_piece(piece)
    end
    
    -- ===== 红方棋子（下方，row 5-9）=====
    
    -- 红方底线棋子（row 9）
    for col = 0, 8 do
        local piece = Piece.new(baseline_pieces[col + 1], "red", col, 9)
        self:add_piece(piece)
    end
    
    -- 红方炮（row 7）
    piece = Piece.new("cannon", "red", 1, 7)
    self:add_piece(piece)
    piece = Piece.new("cannon", "red", 7, 7)
    self:add_piece(piece)
    
    -- 红方兵（row 6）
    for i = 0, 4 do
        local col = i * 2
        local piece = Piece.new("pawn", "red", col, 6)
        self:add_piece(piece)
    end
    
    -- 重置回合
    self.current_turn = "red"
    self.game_over = false
    self.winner = nil
    self.selected_piece = nil
    self.move_history = {}
    
    Logger.info(string.format("棋盘初始化完成，共 %d 个棋子", #self.pieces))
end

--[[
    添加一个棋子到棋盘
    参数：
        piece (Piece) - 棋子对象
]]
function GameState:add_piece(piece)
    table.insert(self.pieces, piece)
    self.board[piece.col][piece.row] = piece
end

--[[
    移除一个棋子
    参数：
        piece (Piece) - 要移除的棋子
]]
function GameState:remove_piece(piece)
    -- 从棋盘数组里移除
    self.board[piece.col][piece.row] = nil
    
    -- 从pieces列表里移除
    for i, p in ipairs(self.pieces) do
        if p == piece then
            table.remove(self.pieces, i)
            break
        end
    end
    
    piece.alive = false
    
    -- 如果移除的是选中的棋子，取消选中
    if self.selected_piece == piece then
        self.selected_piece = nil
    end
end

--[[
    获取某个位置的棋子
    参数：
        col, row (number) - 棋盘坐标
    返回：Piece对象 或 nil（该位置没有棋子）
]]
function GameState:get_piece_at(col, row)
    -- 检查坐标是否合法
    if col < 0 or col > 8 or row < 0 or row > 9 then
        return nil
    end
    return self.board[col][row]
end

--[[
    移动棋子
    参数：
        piece (Piece) - 要移动的棋子
        to_col, to_row (number) - 目标位置
        animate (boolean) - 是否播放动画，默认false
    返回：
        captured_piece (Piece) - 被吃掉的棋子，如果没有吃子返回nil
]]
function GameState:move_piece(piece, to_col, to_row, animate)
    animate = animate or false
    
    if not piece or not piece.alive then
        return nil
    end
    
    local from_col = piece.col
    local from_row = piece.row
    
    -- 目标位置的棋子（会被吃掉）
    local captured_piece = self:get_piece_at(to_col, to_row)
    
    -- 如果目标位置有棋子，先移除（吃掉）
    if captured_piece then
        Logger.info(string.format("%s %s 吃了 %s %s", 
            piece.color, piece:get_char(),
            captured_piece.color, captured_piece:get_char()))
        self:remove_piece(captured_piece)
    end
    
    -- 从原位置的board数组里移除
    self.board[from_col][from_row] = nil
    
    -- 移动棋子
    piece:set_position(to_col, to_row, animate)
    
    -- 更新board数组
    self.board[to_col][to_row] = piece
    
    -- 记录到历史
    table.insert(self.move_history, {
        piece = piece,
        from_col = from_col,
        from_row = from_row,
        to_col = to_col,
        to_row = to_row,
        captured_piece = captured_piece,
        turn = self.current_turn,
    })
    
    -- 切换回合
    self.current_turn = self.current_turn == "red" and "black" or "red"
    
    -- 取消选中
    self.selected_piece = nil
    
    return captured_piece
end

--[[
    选中一个棋子
    参数：
        piece (Piece) - 要选中的棋子，传nil表示取消选中
]]
function GameState:select_piece(piece)
    -- 先取消之前选中的
    if self.selected_piece then
        self.selected_piece.selected = false
    end
    
    if piece and piece.alive then
        self.selected_piece = piece
        piece.selected = true
        Logger.debug(string.format("选中棋子：%s %s (%d, %d)", 
            piece.color, piece:get_char(), piece.col, piece.row))
    else
        self.selected_piece = nil
        Logger.debug("取消选中棋子")
    end
end

--[[
    检查某个位置是否有己方棋子
    参数：
        col, row (number) - 位置
        color (string) - 颜色
    返回：true/false
]]
function GameState:has_friendly_piece(col, row, color)
    local piece = self:get_piece_at(col, row)
    return piece ~= nil and piece.color == color
end

--[[
    检查某个位置是否有敌方棋子
    参数：
        col, row (number) - 位置
        color (string) - 己方颜色
    返回：true/false
]]
function GameState:has_enemy_piece(col, row, color)
    local piece = self:get_piece_at(col, row)
    return piece ~= nil and piece.color ~= color
end

--[[
    获取某一方所有活着的棋子
    参数：
        color (string) - 颜色
    返回：棋子数组
]]
function GameState:get_pieces_by_color(color)
    local result = {}
    for _, piece in ipairs(self.pieces) do
        if piece.color == color and piece.alive then
            table.insert(result, piece)
        end
    end
    return result
end

--[[
    获取某一方的将/帅
    参数：
        color (string) - 颜色
    返回：Piece对象，找不到返回nil
]]
function GameState:get_king(color)
    for _, piece in ipairs(self.pieces) do
        if piece.color == color and piece.type == "king" and piece.alive then
            return piece
        end
    end
    return nil
end

--[[
    更新所有棋子（动画等）
    参数：
        dt (number) - 时间增量
        board (Board) - 棋盘对象
]]
function GameState:update(dt, board)
    for _, piece in ipairs(self.pieces) do
        if piece.alive then
            piece:update(dt, board)
        end
    end
end

--[[
    绘制所有棋子
    参数：
        cell_size (number) - 格子大小
]]
function GameState:draw_pieces(cell_size)
    -- 按顺序绘制，保证层级正确：未选中的先画，选中的后画（在最上面）
    
    -- 先画没选中的
    for _, piece in ipairs(self.pieces) do
        if piece.alive and not piece.selected then
            piece:draw(cell_size)
        end
    end
    
    -- 再画选中的（在最上面）
    if self.selected_piece and self.selected_piece.alive then
        self.selected_piece:draw(cell_size)
    end
end

Logger.info("游戏状态模块加载完成")

return GameState
