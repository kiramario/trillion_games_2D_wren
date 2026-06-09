--[[
    文件名：rules.lua
    功能：中国象棋走法规则校验
    说明：所有走法规则都集中在这里，方便维护
    作者：wren
    创建日期：2026-06-09
    依赖：core.logger, entities.board
]]

local Logger = require("core.logger")

local Rules = {}

--[[
    检查某个棋子是否能走到某个位置
    参数：
        piece (Piece) - 要走的棋子
        to_col, to_row (number) - 目标位置
        game_state (GameState) - 游戏状态，用来查其他棋子
        check_self_check (boolean) - 是否检查自将（走了之后自己会不会被将军），默认true
    返回：
        valid (boolean) - 是否合法
        reason (string) - 不合法的原因（调试用）
]]
function Rules.is_valid_move(piece, to_col, to_row, game_state, check_self_check)
    if check_self_check == nil then
        check_self_check = true  -- 默认检查自将
    end
    
    if not piece or not piece.alive then
        return false, "棋子不存在或已被吃"
    end
    
    local from_col = piece.col
    local from_row = piece.row
    
    -- 目标位置和当前位置一样，不算走
    if from_col == to_col and from_row == to_row then
        return false, "目标位置和当前位置相同"
    end
    
    -- 检查目标位置是否在棋盘内
    if to_col < 0 or to_col > 8 or to_row < 0 or to_row > 9 then
        return false, "目标位置超出棋盘"
    end
    
    -- 检查目标位置是否有己方棋子（不能吃自己人）
    local target_piece = game_state:get_piece_at(to_col, to_row)
    if target_piece and target_piece.color == piece.color then
        return false, "目标位置有己方棋子"
    end
    
    -- 根据棋子类型调用对应的校验函数
    local valid, reason = false, ""
    
    if piece.type == "king" then
        valid, reason = Rules._check_king(piece, from_col, from_row, to_col, to_row, game_state)
    elseif piece.type == "advisor" then
        valid, reason = Rules._check_advisor(piece, from_col, from_row, to_col, to_row, game_state)
    elseif piece.type == "elephant" then
        valid, reason = Rules._check_elephant(piece, from_col, from_row, to_col, to_row, game_state)
    elseif piece.type == "horse" then
        valid, reason = Rules._check_horse(piece, from_col, from_row, to_col, to_row, game_state)
    elseif piece.type == "chariot" then
        valid, reason = Rules._check_chariot(piece, from_col, from_row, to_col, to_row, game_state)
    elseif piece.type == "cannon" then
        valid, reason = Rules._check_cannon(piece, from_col, from_row, to_col, to_row, game_state)
    elseif piece.type == "pawn" then
        valid, reason = Rules._check_pawn(piece, from_col, from_row, to_col, to_row, game_state)
    else
        return false, "未知棋子类型"
    end
    
    if not valid then
        return false, reason
    end
    
    -- 如果需要检查自将，模拟走一下，看看会不会被将军
    if check_self_check then
        if Rules._would_be_in_check(piece, to_col, to_row, game_state) then
            return false, "走子后会被将军（不能送将）"
        end
    end
    
    return true
end

--[[
    获取某个棋子所有合法的走法
    参数：
        piece (Piece) - 棋子
        game_state (GameState) - 游戏状态
    返回：
        moves (table) - 合法位置列表，每个元素是 {col, row}
]]
function Rules.get_valid_moves(piece, game_state)
    local moves = {}
    
    if not piece or not piece.alive then
        return moves
    end
    
    -- 遍历棋盘所有位置，检查是否合法
    -- 象棋棋盘很小，9x10=90个位置，暴力遍历完全没问题
    for col = 0, 8 do
        for row = 0, 9 do
            if Rules.is_valid_move(piece, col, row, game_state) then
                table.insert(moves, {col = col, row = row})
            end
        end
    end
    
    return moves
end

-- ========== 各个棋子的走法校验 ==========

--[[
    将/帅的走法：
    1. 只能在九宫格里走
    2. 每次走一步，上下左右
    3. 两个将不能在同一条直线上直接对面（将帅对脸）
]]
function Rules._check_king(piece, from_col, from_row, to_col, to_row, game_state)
    -- 1. 只能走一步
    local dx = math.abs(to_col - from_col)
    local dy = math.abs(to_row - from_row)
    if (dx == 1 and dy == 0) or (dx == 0 and dy == 1) then
        -- 走一步，继续检查
    else
        return false, "将/帅只能走一步"
    end
    
    -- 2. 只能在九宫格里
    -- 九宫格范围：列 3-5，行：红方 7-9，黑方 0-2
    if to_col < 3 or to_col > 5 then
        return false, "将/帅不能出九宫"
    end
    if piece.color == "red" then
        if to_row < 7 or to_row > 9 then
            return false, "将/帅不能出九宫"
        end
    else
        if to_row < 0 or to_row > 2 then
            return false, "将/帅不能出九宫"
        end
    end
    
    -- 3. 检查将帅对脸（飞将）
    -- 如果走了之后两个将在同一条直线上且中间没子，不行
    -- 暂时先不检查，V0.4将军判断的时候一起处理
    
    return true
end

--[[
    士/仕的走法：
    1. 只能在九宫格里走
    2. 每次走一步斜线
]]
function Rules._check_advisor(piece, from_col, from_row, to_col, to_row, game_state)
    -- 1. 只能走斜线一步
    local dx = math.abs(to_col - from_col)
    local dy = math.abs(to_row - from_row)
    if dx ~= 1 or dy ~= 1 then
        return false, "士/仕只能走一步斜线"
    end
    
    -- 2. 只能在九宫格里
    if to_col < 3 or to_col > 5 then
        return false, "士/仕不能出九宫"
    end
    if piece.color == "red" then
        if to_row < 7 or to_row > 9 then
            return false, "士/仕不能出九宫"
        end
    else
        if to_row < 0 or to_row > 2 then
            return false, "士/仕不能出九宫"
        end
    end
    
    return true
end

--[[
    象/相的走法：
    1. 走田字（斜着走两步）
    2. 不能过河
    3. 田字中间有子不能走（塞象眼）
]]
function Rules._check_elephant(piece, from_col, from_row, to_col, to_row, game_state)
    -- 1. 走田字：dx=2, dy=2
    local dx = math.abs(to_col - from_col)
    local dy = math.abs(to_row - from_row)
    if dx ~= 2 or dy ~= 2 then
        return false, "象/相只能走田字"
    end
    
    -- 2. 不能过河
    -- 红方象不能过河（row不能小于5），黑方象不能过河（row不能大于4）
    if piece.color == "red" then
        if to_row < 5 then
            return false, "象/相不能过河"
        end
    else
        if to_row > 4 then
            return false, "象/相不能过河"
        end
    end
    
    -- 3. 塞象眼：田字中间的位置不能有子
    local eye_col = (from_col + to_col) / 2
    local eye_row = (from_row + to_row) / 2
    local eye_piece = game_state:get_piece_at(eye_col, eye_row)
    if eye_piece then
        return false, "塞象眼，不能走"
    end
    
    return true
end

--[[
    马的走法：
    1. 走日字（一横一竖，或者一竖一横，两步+一步）
    2. 马旁边（靠近走的方向的那一侧）有子不能走（蹩马腿）
]]
function Rules._check_horse(piece, from_col, from_row, to_col, to_row, game_state)
    local dx = math.abs(to_col - from_col)
    local dy = math.abs(to_row - from_row)
    
    -- 1. 走日字：要么dx=1 dy=2，要么dx=2 dy=1
    if not ((dx == 1 and dy == 2) or (dx == 2 and dy == 1)) then
        return false, "马只能走日字"
    end
    
    -- 2. 蹩马腿判断
    -- 看往哪个方向走，马腿的位置就是中间那个
    local leg_col, leg_row
    
    if dx == 1 and dy == 2 then
        -- 竖着走两格，横着走一格，马腿在竖方向中间
        leg_col = from_col
        leg_row = from_row + (to_row - from_row) / 2
    else
        -- dx == 2 and dy == 1，横着走两格，竖着走一格，马腿在横方向中间
        leg_col = from_col + (to_col - from_col) / 2
        leg_row = from_row
    end
    
    local leg_piece = game_state:get_piece_at(leg_col, leg_row)
    if leg_piece then
        return false, "蹩马腿，不能走"
    end
    
    return true
end

--[[
    车的走法：
    1. 直线走，任意步数
    2. 中间不能有棋子阻挡
]]
function Rules._check_chariot(piece, from_col, from_row, to_col, to_row, game_state)
    -- 1. 必须是直线（同一行或同一列）
    if from_col ~= to_col and from_row ~= to_row then
        return false, "车只能走直线"
    end
    
    -- 2. 中间不能有棋子
    local has_piece, count = game_state._count_pieces_between and 
        game_state:_count_pieces_between(from_col, from_row, to_col, to_row) or
        Rules._count_pieces_between(from_col, from_row, to_col, to_row, game_state)
    
    if has_piece then
        return false, "车中间有棋子阻挡"
    end
    
    return true
end

--[[
    炮的走法：
    1. 空走（不吃子）：和车一样，直线走，中间不能有子
    2. 吃子：直线走，中间必须恰好有一个棋子当炮架
]]
function Rules._check_cannon(piece, from_col, from_row, to_col, to_row, game_state)
    -- 1. 必须是直线
    if from_col ~= to_col and from_row ~= to_row then
        return false, "炮只能走直线"
    end
    
    -- 目标位置有没有棋子
    local target_piece = game_state:get_piece_at(to_col, to_row)
    
    -- 中间棋子数
    local has_piece, count = Rules._count_pieces_between(from_col, from_row, to_col, to_row, game_state)
    
    if not target_piece then
        -- 空走，中间不能有子
        if count > 0 then
            return false, "炮空走时中间不能有棋子"
        end
        return true
    else
        -- 吃子，中间必须恰好有一个炮架
        if count ~= 1 then
            return false, "炮吃子时必须隔一个棋子"
        end
        return true
    end
end

--[[
    兵/卒的走法：
    1. 每次只能走一步
    2. 没过河的时候，只能往前走
    3. 过河之后，可以往前走，也可以左右走，但不能后退
]]
function Rules._check_pawn(piece, from_col, from_row, to_col, to_row, game_state)
    local dx = math.abs(to_col - from_col)
    local dy = to_row - from_row  -- 这里不用绝对值，因为要判断方向
    
    -- 1. 只能走一步
    if dx + math.abs(dy) ~= 1 then
        return false, "兵/卒每次只能走一步"
    end
    
    if piece.color == "red" then
        -- 红方：往前是row减小（往上走）
        if dy > 0 then
            return false, "兵/卒不能后退"
        end
        
        -- 检查有没有过河
        -- 红方的兵，初始row=6，过河后row <= 4
        -- 或者说：在自己这边（row >= 5）只能往前走
        if from_row >= 5 then
            -- 还没过河，只能往前走（不能左右走）
            if dx ~= 0 then
                return false, "没过河的兵/卒不能左右走"
            end
        end
        -- 过河了可以左右走
        
    else
        -- 黑方：往前是row增大（往下走）
        if dy < 0 then
            return false, "兵/卒不能后退"
        end
        
        -- 黑方的兵，初始row=3，过河后row >= 5
        if from_row <= 4 then
            -- 还没过河，只能往前走
            if dx ~= 0 then
                return false, "没过河的兵/卒不能左右走"
            end
        end
        -- 过河了可以左右走
    end
    
    return true
end

--[[
    辅助函数：计算两个位置之间的棋子数（直线）
    参数：
        from_col, from_row - 起点
        to_col, to_row - 终点
        game_state - 游戏状态
    返回：
        has_piece (boolean) - 是否有棋子
        count (number) - 棋子数量，不是直线返回-1
]]
function Rules._count_pieces_between(from_col, from_row, to_col, to_row, game_state)
    local count = 0
    
    -- 同一行
    if from_row == to_row then
        local min_col = math.min(from_col, to_col)
        local max_col = math.max(from_col, to_col)
        for col = min_col + 1, max_col - 1 do
            if game_state:get_piece_at(col, from_row) then
                count = count + 1
            end
        end
    -- 同一列
    elseif from_col == to_col then
        local min_row = math.min(from_row, to_row)
        local max_row = math.max(from_row, to_row)
        for row = min_row + 1, max_row - 1 do
            if game_state:get_piece_at(from_col, row) then
                count = count + 1
            end
        end
    else
        -- 不是直线
        return false, -1
    end
    
    return count > 0, count
end

--[[
    检查某一方的将是否被将军
    参数：
        color (string) - 要检查的一方颜色
        game_state (GameState) - 游戏状态
    返回：
        in_check (boolean) - 是否被将军
        checking_pieces (table) - 哪些棋子在将军
]]
function Rules.is_in_check(color, game_state)
    -- 找到这一方的将
    local king = game_state:get_king(color)
    if not king then
        return false, {}  -- 将都没了，那已经输了
    end
    
    local checking_pieces = {}
    
    -- 遍历对方所有棋子，看有没有能直接吃到将的
    local enemy_color = color == "red" and "black" or "red"
    local enemy_pieces = game_state:get_pieces_by_color(enemy_color)
    
    for _, piece in ipairs(enemy_pieces) do
        if Rules.is_valid_move(piece, king.col, king.row, game_state) then
            table.insert(checking_pieces, piece)
        end
    end
    
    return #checking_pieces > 0, checking_pieces
end

--[[
    检查两个将是否对脸（飞将）
    参数：
        game_state (GameState) - 游戏状态
    返回：
        facing (boolean) - 是否对脸
]]
function Rules.kings_are_facing(game_state)
    local red_king = game_state:get_king("red")
    local black_king = game_state:get_king("black")
    
    if not red_king or not black_king then
        return false  -- 有一个将没了，不存在对脸
    end
    
    -- 必须在同一列
    if red_king.col ~= black_king.col then
        return false
    end
    
    -- 中间有没有棋子
    local min_row = math.min(red_king.row, black_king.row)
    local max_row = math.max(red_king.row, black_king.row)
    
    for row = min_row + 1, max_row - 1 do
        if game_state:get_piece_at(red_king.col, row) then
            return false  -- 中间有棋子，不对脸
        end
    end
    
    return true  -- 同列且中间没子，将帅对脸
end

--[[
    模拟走一步，看看走了之后己方会不会被将军
    参数：
        piece (Piece) - 要走的棋子
        to_col, to_row (number) - 目标位置
        game_state (GameState) - 游戏状态
    返回：
        in_check (boolean) - 走了之后是否会被将军
]]
function Rules._would_be_in_check(piece, to_col, to_row, game_state)
    local from_col = piece.col
    local from_row = piece.row
    local color = piece.color
    
    -- 目标位置的棋子（会被吃掉）
    local target_piece = game_state:get_piece_at(to_col, to_row)
    
    -- ===== 模拟走子 =====
    -- 1. 从原位置移除
    game_state.board[from_col][from_row] = nil
    
    -- 2. 放到新位置
    game_state.board[to_col][to_row] = piece
    
    -- 3. 临时更新piece的坐标
    piece.col = to_col
    piece.row = to_row
    
    -- 4. 如果目标位置有棋子，先标记一下（暂时不真删，后面恢复）
    if target_piece then
        target_piece.alive = false
    end
    
    -- ===== 检查会不会被将军 =====
    -- 检查将军 或者 将帅对脸
    local in_check = Rules.is_in_check(color, game_state) or Rules.kings_are_facing(game_state)
    
    -- ===== 恢复原状 =====
    -- 1. 恢复piece坐标
    piece.col = from_col
    piece.row = from_row
    
    -- 2. 恢复原位置
    game_state.board[from_col][from_row] = piece
    
    -- 3. 恢复目标位置
    if target_piece then
        game_state.board[to_col][to_row] = target_piece
        target_piece.alive = true
    else
        game_state.board[to_col][to_row] = nil
    end
    
    return in_check
end

--[[
    检查某一方是否将死（被将军且没有任何解法）
    参数：
        color (string) - 要检查的一方
        game_state (GameState) - 游戏状态
    返回：
        checkmate (boolean) - 是否将死
]]
function Rules.is_checkmate(color, game_state)
    -- 首先得是被将军状态
    if not Rules.is_in_check(color, game_state) then
        return false
    end
    
    -- 看看有没有任何一步棋可以解将
    local pieces = game_state:get_pieces_by_color(color)
    for _, piece in ipairs(pieces) do
        local moves = Rules.get_valid_moves(piece, game_state)
        if #moves > 0 then
            -- 有能走的棋，就没被将死
            return false
        end
    end
    
    -- 所有棋子都没有合法走法，就是将死了
    return true
end

--[[
    检查某一方是否困毙（没被将军但无路可走）
    参数：
        color (string) - 要检查的一方
        game_state (GameState) - 游戏状态
    返回：
        stalemate (boolean) - 是否困毙
]]
function Rules.is_stalemate(color, game_state)
    -- 首先不能是被将军
    if Rules.is_in_check(color, game_state) then
        return false
    end
    
    -- 看看有没有任何一步可以走
    local pieces = game_state:get_pieces_by_color(color)
    for _, piece in ipairs(pieces) do
        local moves = Rules.get_valid_moves(piece, game_state)
        if #moves > 0 then
            return false  -- 有能走的棋，没困毙
        end
    end
    
    -- 所有棋子都走不动，就是困毙
    return true
end

Logger.info("走法规则模块加载完成")

return Rules
