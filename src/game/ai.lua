--[[
    文件名：ai.lua
    功能：中国象棋AI
    算法：Minimax + Alpha-Beta 剪枝
    作者：wren
    创建日期：2026-06-09
    依赖：core.logger, game.rules
]]

local Logger = require("core.logger")
local Rules = require("game.rules")

local AI = {}

-- 难度配置
-- 每个难度对应搜索深度
AI.DIFFICULTY = {
    EASY = { depth = 1, name = "简单" },
    NORMAL = { depth = 2, name = "中等" },
    HARD = { depth = 3, name = "困难" },
    EXPERT = { depth = 4, name = "专家" },
}

-- 棋子基础分值
-- 红方是正，黑方是负（从AI的视角，假设AI是黑方的话就是负分）
-- 不对，评估函数一般是：对于当前局面，正分表示红方占优，负分表示黑方占优
local PIECE_VALUES = {
    king = 10000,
    chariot = 900,
    cannon = 450,
    horse = 400,
    elephant = 200,
    advisor = 200,
    pawn = 100,
}

-- 兵的位置加分表（过河的兵更值钱）
-- 行号 0-9，值是额外加分
-- 对于红方的兵，越往上（row越小）越值钱
-- 对于黑方的兵，越往下（row越大）越值钱
local PAWN_BONUS = {
    [0] = 200,  -- 冲到对方底线的兵
    [1] = 180,
    [2] = 150,
    [3] = 120,
    [4] = 90,   -- 刚过河
    [5] = 0,    -- 还在己方河沿
    [6] = 0,    -- 初始位置
    [7] = 0,
    [8] = 0,
    [9] = 0,
}

-- 马的位置加分（中心的马更灵活）
local HORSE_BONUS = {
    [0] = 0,
    [1] = 10,
    [2] = 20,
    [3] = 30,
    [4] = 40,
    [5] = 40,
    [6] = 30,
    [7] = 20,
    [8] = 10,
}

--[[
    评估函数：给当前局面打分
    正分：红方占优
    负分：黑方占优
    参数：
        game_state (GameState) - 游戏状态
    返回：number - 分数
]]
function AI.evaluate(game_state)
    local score = 0
    
    -- 遍历所有棋子，计算总分
    for _, piece in ipairs(game_state.pieces) do
        if piece.alive then
            local value = PIECE_VALUES[piece.type] or 0
            
            -- 位置加分
            if piece.type == "pawn" then
                -- 兵的位置加分
                if piece.color == "red" then
                    -- 红方兵，row越小（越往上）越值钱
                    value = value + PAWN_BONUS[piece.row]
                else
                    -- 黑方兵，row越大（越往下）越值钱
                    value = value + PAWN_BONUS[9 - piece.row]
                end
            elseif piece.type == "horse" then
                -- 马的位置加分（列方向，中间更灵活）
                value = value + HORSE_BONUS[piece.col]
                -- 行方向同理
                local row_bonus = piece.row < 5 and HORSE_BONUS[piece.row] or HORSE_BONUS[9 - piece.row]
                value = value + row_bonus
            end
            
            -- 红方加，黑方减
            if piece.color == "red" then
                score = score + value
            else
                score = score - value
            end
        end
    end
    
    -- 灵活度加分：走法多的稍微加一点分
    -- 为了性能，先不加，后面可以优化
    
    -- 将军稍微加一点分
    if Rules.is_in_check("red", game_state) then
        score = score - 50  -- 红方被将军，减分
    end
    if Rules.is_in_check("black", game_state) then
        score = score + 50  -- 黑方被将军，加分（红方优势）
    end
    
    return score
end

--[[
    生成所有合法走法
    参数：
        game_state (GameState) - 游戏状态
        color (string) - 哪一方的走法
    返回：moves数组，每个元素 {piece, to_col, to_row, score（预估）}
]]
function AI.generate_moves(game_state, color)
    local moves = {}
    
    local pieces = game_state:get_pieces_by_color(color)
    for _, piece in ipairs(pieces) do
        local valid_moves = Rules.get_valid_moves(piece, game_state)
        for _, move in ipairs(valid_moves) do
            table.insert(moves, {
                piece = piece,
                to_col = move.col,
                to_row = move.row,
                -- 预估分数：吃子的话优先，用于排序剪枝更有效
                target_piece = game_state:get_piece_at(move.col, move.row),
            })
        end
    end
    
    -- 排序：吃子的排在前面，吃大子的排在最前面，这样alpha-beta剪枝效果更好
    table.sort(moves, function(a, b)
        local a_val = a.target_piece and PIECE_VALUES[a.target_piece.type] or 0
        local b_val = b.target_piece and PIECE_VALUES[b.target_piece.type] or 0
        return a_val > b_val
    end)
    
    return moves
end

--[[
    执行一步走法（临时的，用来模拟）
    参数：
        game_state (GameState) - 游戏状态
        move (table) - 走法 {piece, to_col, to_row}
    返回：被吃掉的棋子（如果有的话）
]]
function AI.make_move(game_state, move)
    local piece = move.piece
    local from_col = piece.col
    local from_row = piece.row
    local to_col = move.to_col
    local to_row = move.to_row
    
    -- 目标位置的棋子
    local target_piece = game_state:get_piece_at(to_col, to_row)
    
    -- 移动
    game_state.board[from_col][from_row] = nil
    game_state.board[to_col][to_row] = piece
    
    piece.col = to_col
    piece.row = to_row
    
    if target_piece then
        target_piece.alive = false
    end
    
    -- 切换回合
    game_state.current_turn = game_state.current_turn == "red" and "black" or "red"
    
    return target_piece
end

--[[
    撤销一步走法（模拟后恢复）
    参数：
        game_state (GameState) - 游戏状态
        move (table) - 走法
        captured_piece (Piece) - 被吃掉的棋子
]]
function AI.unmake_move(game_state, move, captured_piece)
    local piece = move.piece
    local from_col = piece.col
    local from_row = piece.row
    local to_col = move.piece.col  -- 不对，from是原来的位置，to是现在的位置
    -- 哦不对，move里存的是目标位置，piece里现在存的是目标位置，原来的位置是move.piece.col？不，move里有piece，还有to_col to_row。
    -- 原来的位置存在哪？哦刚才make_move的时候没存原来的位置，这就麻烦了。
    -- 等等，move里有piece，还有to_col, to_row。原来的位置就是piece的col和row在move之前的值。
    -- 不对，我们已经改了piece.col了。哦，那我们make_move的时候应该把原来的位置存下来，或者move里的piece是引用，col已经被改了。
    -- 其实move里的piece是引用，原来的位置我们已经丢了。
    -- 那怎么办？我们可以在make_move的时候返回更多信息，或者move结构里存from_col from_row。
    
    -- 哦我刚才设计move的时候就有piece，我们走之前的位置就是piece.col和piece.row，但走之后就变了。
    -- 那我们改一下，move里存from_col和from_row，或者make_move返回更多信息。
    
    -- 先简单粗暴点，直接在move里加from_col from_row，或者在unmake的时候用move.to_col to_row作为当前位置，回到原来的。
    -- 不对，走之前的位置我们没存啊。
    
    -- 哦，move结构里的piece的col和row，在make_move之前是原来的位置，make_move之后变成新的了。
    -- 那我们在make_move的时候，把原来的位置存在move里？或者干脆在move里就存from_col from_row。
    
    -- 先改一下generate_moves，加上from_col from_row。不对，我们现在已经写到这里了，先临时想个办法。
    -- 其实我们有move.to_col和move.to_row，这就是目标位置，也就是现在的位置。原来的位置是...哎，原来的位置我们没存。
    
    -- 那我换个方式：make_move返回一个表，里面包含所有恢复需要的信息。
    -- 不过现在先写一半了，我重新整理一下。
end

-- 等等，上面的思路有问题，make_move和unmake_move要设计好。
-- 我重新写这两个函数。

--[[
    执行一步走法（临时的，用来模拟）
    参数：
        game_state (GameState) - 游戏状态
        move (table) - 走法 {piece, to_col, to_row}
    返回：move_info - 用来撤销的信息
]]
function AI.make_move(game_state, move)
    local piece = move.piece
    local from_col = piece.col
    local from_row = piece.row
    local to_col = move.to_col
    local to_row = move.to_row
    
    -- 目标位置的棋子
    local target_piece = game_state:get_piece_at(to_col, to_row)
    
    -- 保存原来的回合
    local prev_turn = game_state.current_turn
    
    -- 移动
    game_state.board[from_col][from_row] = nil
    game_state.board[to_col][to_row] = piece
    
    piece.col = to_col
    piece.row = to_row
    
    if target_piece then
        target_piece.alive = false
    end
    
    -- 切换回合
    game_state.current_turn = game_state.current_turn == "red" and "black" or "red"
    
    -- 返回撤销需要的信息
    return {
        piece = piece,
        from_col = from_col,
        from_row = from_row,
        to_col = to_col,
        to_row = to_row,
        captured_piece = target_piece,
        prev_turn = prev_turn,
    }
end

--[[
    撤销一步走法（模拟后恢复）
    参数：
        game_state (GameState) - 游戏状态
        move_info (table) - make_move返回的信息
]]
function AI.unmake_move(game_state, move_info)
    local piece = move_info.piece
    local from_col = move_info.from_col
    local from_row = move_info.from_row
    local to_col = move_info.to_col
    local to_row = move_info.to_row
    local captured_piece = move_info.captured_piece
    
    -- 把棋子移回去
    game_state.board[to_col][to_row] = nil
    game_state.board[from_col][from_row] = piece
    
    piece.col = from_col
    piece.row = from_row
    
    -- 恢复被吃掉的棋子
    if captured_piece then
        captured_piece.alive = true
        game_state.board[to_col][to_row] = captured_piece
    end
    
    -- 恢复回合
    game_state.current_turn = move_info.prev_turn
end

--[[
    Minimax 算法 + Alpha-Beta 剪枝
    参数：
        game_state (GameState) - 游戏状态
        depth (number) - 剩余搜索深度
        alpha (number) - alpha值，红方的最低分
        beta (number) - beta值，黑方的最高分
        maximizing (boolean) - 当前是不是极大层（红方走，要最大化分数）
    返回：
        best_score (number) - 最优分数
        best_move (table) - 最优走法（最顶层才有）
]]
function AI.minimax(game_state, depth, alpha, beta, maximizing)
    -- 深度到0，或者游戏结束，返回评估分
    if depth == 0 or game_state.game_over then
        return AI.evaluate(game_state), nil
    end
    
    local best_move = nil
    local current_color = maximizing and "red" or "black"
    local moves = AI.generate_moves(game_state, current_color)
    
    -- 没有合法走法，说明将死或者困毙
    if #moves == 0 then
        return AI.evaluate(game_state), nil
    end
    
    if maximizing then
        -- 极大层：红方走，要最大化分数
        local max_eval = -math.huge
        
        for _, move in ipairs(moves) do
            -- 执行走法
            local move_info = AI.make_move(game_state, move)
            
            -- 递归搜索
            local eval, _ = AI.minimax(game_state, depth - 1, alpha, beta, false)
            
            -- 撤销走法
            AI.unmake_move(game_state, move_info)
            
            -- 更新最大值
            if eval > max_eval then
                max_eval = eval
                best_move = move
            end
            
            -- Alpha-Beta 剪枝
            alpha = math.max(alpha, eval)
            if beta <= alpha then
                break  -- beta剪枝
            end
        end
        
        return max_eval, best_move
    else
        -- 极小层：黑方走，要最小化分数
        local min_eval = math.huge
        
        for _, move in ipairs(moves) do
            -- 执行走法
            local move_info = AI.make_move(game_state, move)
            
            -- 递归搜索
            local eval, _ = AI.minimax(game_state, depth - 1, alpha, beta, true)
            
            -- 撤销走法
            AI.unmake_move(game_state, move_info)
            
            -- 更新最小值
            if eval < min_eval then
                min_eval = eval
                best_move = move
            end
            
            -- Alpha-Beta 剪枝
            beta = math.min(beta, eval)
            if beta <= alpha then
                break  -- alpha剪枝
            end
        end
        
        return min_eval, best_move
    end
end

--[[
    AI选择一步最优走法
    参数：
        game_state (GameState) - 当前游戏状态
        ai_color (string) - AI的颜色（red/black），默认黑方
        difficulty (string) - 难度，默认NORMAL
    返回：
        best_move (table) - 最优走法 {piece, to_col, to_row}
        score (number) - 评估分数
]]
function AI.get_best_move(game_state, ai_color, difficulty)
    ai_color = ai_color or "black"
    difficulty = difficulty or "NORMAL"
    
    local depth = AI.DIFFICULTY[difficulty] and AI.DIFFICULTY[difficulty].depth or 2
    
    -- 记录开始时间
    local start_time = os.clock()
    
    -- 判断当前是极大层还是极小层
    -- 如果AI是红方，就是极大层；如果是黑方，就是极小层
    local maximizing = ai_color == "red"
    
    local score, best_move = AI.minimax(
        game_state,
        depth,
        -math.huge,
        math.huge,
        maximizing
    )
    
    -- 计算用时
    local elapsed = os.clock() - start_time
    Logger.debug(string.format("AI思考完成：深度%d，用时%.2f秒，评估分%.2f",
        depth, elapsed, score))
    
    return best_move, score
end

--[[
    简单AI：随机走一步合法的
    用来做最简单的难度，或者测试用
]]
function AI.get_random_move(game_state, color)
    local moves = AI.generate_moves(game_state, color)
    if #moves == 0 then
        return nil
    end
    return moves[math.random(#moves)]
end

Logger.info("AI模块加载完成")

return AI
