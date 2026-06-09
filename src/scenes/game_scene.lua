--[[
    文件名：game_scene.lua
    功能：游戏场景（V0测试用，后面会加棋盘棋子等）
    作者：wren
    创建日期：2026-06-09
    依赖：scenes.base_scene, core.logger, core.event_bus, systems.render_system
]]

local BaseScene = require("scenes.base_scene")
local Logger = require("core.logger")
local EventBus = require("core.event_bus")
local RenderSystem = require("systems.render_system")
local InputSystem = require("systems.input_system")
local CameraSystem = require("systems.camera_system")
local Board = require("entities.board")
local Piece = require("entities.piece")
local GameState = require("game.game_state")
local Rules = require("game.rules")
local AI = require("game.ai")
local Config = require("core.config")
local Utils = require("core.utils")

-- 游戏场景类，继承自BaseScene
local GameScene = {}
GameScene.__index = GameScene
setmetatable(GameScene, {__index = BaseScene})

--[[
    构造函数
]]
function GameScene.new()
    local self = BaseScene.new()
    setmetatable(self, GameScene)
    
    self.name = "game"
    
    -- 测试用：鼠标点击的点列表，用来测试输入
    self._click_points = {}
    
    -- 测试用：当前鼠标位置
    self._mouse_x = 0
    self._mouse_y = 0
    
    -- 鼠标对应的棋盘坐标
    self._hover_col = 0
    self._hover_row = 0
    
    -- 相机
    self._camera = nil
    
    -- 棋盘
    self._board = nil
    
    -- 游戏状态
    self._game_state = nil
    
    -- 游戏模式："pvp"（双人对战） / "pve"（人机对战）
    self._game_mode = "pve"
    
    -- AI配置
    self._ai_color = "black"      -- AI执黑（默认玩家走红，AI走黑）
    self._ai_difficulty = "NORMAL" -- AI难度
    self._ai_thinking = false      -- AI是否正在思考
    self._ai_think_delay = 0.5     -- AI思考延迟（秒，假装在想，不然太快了）
    self._ai_delay_timer = 0       -- 延迟计时器
    
    return self
end

--[[
    进入场景
]]
function GameScene:enter(params)
    BaseScene.enter(self, params)
    
    Logger.info("游戏场景初始化")
    
    -- 初始化相机
    self._camera = CameraSystem.new()
    self._camera:set_viewport(love.graphics.getWidth(), love.graphics.getHeight())
    
    -- 初始化棋盘
    self._board = Board.new()
    -- 自适应窗口
    self._board:fit_to_window(love.graphics.getWidth(), love.graphics.getHeight())
    
    -- 初始化游戏状态，摆放棋子
    self._game_state = GameState.new()
    self._game_state:init_board()
    
    -- 订阅鼠标事件
    self._mouse_press_callback = function(data)
        self:_on_mouse_press(data)
    end
    EventBus:subscribe("input_mouse_left_pressed", self._mouse_press_callback)
    
    self._mouse_move_callback = function(data)
        self._mouse_x = data.x
        self._mouse_y = data.y
        -- 更新鼠标对应的棋盘坐标
        if self._board then
            local col, row = self._board:screen_to_board(data.x, data.y)
            self._hover_col = col
            self._hover_row = row
        end
    end
    EventBus:subscribe("input_mouse_move", self._mouse_move_callback)
    
    -- 订阅键盘事件
    self._key_press_callback = function(data)
        self:_on_key_press(data)
    end
    EventBus:subscribe("input_key_pressed", self._key_press_callback)
    
    -- 订阅滚轮回调
    self._wheel_callback = function(data)
        self:_on_wheel(data)
    end
    EventBus:subscribe("input_wheel_moved", self._wheel_callback)
end

--[[
    离开场景
]]
function GameScene:exit()
    BaseScene.exit(self)
    
    -- 取消订阅
    EventBus:unsubscribe("input_mouse_left_pressed", self._mouse_press_callback)
    EventBus:unsubscribe("input_mouse_move", self._mouse_move_callback)
    EventBus:unsubscribe("input_key_pressed", self._key_press_callback)
    EventBus:unsubscribe("input_wheel_moved", self._wheel_callback)
    
    Logger.info("游戏场景清理完成")
end

--[[
    鼠标按下处理
]]
function GameScene:_on_mouse_press(data)
    Logger.debug("游戏场景收到鼠标点击：" .. data.x .. ", " .. data.y)
    
    -- 把点击的点存起来，画出来
    table.insert(self._click_points, {
        x = data.x,
        y = data.y,
        time = 0  -- 用来做消失动画
    })
    
    -- 最多存50个点
    if #self._click_points > 50 then
        table.remove(self._click_points, 1)
    end
    
    -- 处理棋子点击
    if self._game_state and self._board then
        -- 游戏结束了就不让点了
        if self._game_state.game_over then
            return
        end
        
        -- 转换为棋盘坐标
        local col_f, row_f = self._board:screen_to_board(data.x, data.y)
        local col = math.floor(col_f + 0.5)
        local row = math.floor(row_f + 0.5)
        
        -- 检查是否点到了棋子
        local clicked_piece = self._game_state:get_piece_at(col, row)
        local selected_piece = self._game_state.selected_piece
        
        if selected_piece then
            -- 已经有选中的棋子
            if clicked_piece and clicked_piece.color == self._game_state.current_turn then
                -- 点的是己方其他棋子，切换选中
                self._game_state:select_piece(clicked_piece)
            else
                -- 点的是空白或者对方棋子，尝试走子
                local valid, reason = Rules.is_valid_move(
                    selected_piece, col, row, self._game_state
                )
                
                if valid then
                    -- 合法，走子
                    Logger.info(string.format("走子：%s %s (%d,%d) → (%d,%d)",
                        selected_piece.color, selected_piece:get_char(),
                        selected_piece.col, selected_piece.row, col, row))
                    
                    local captured = self._game_state:move_piece(
                        selected_piece, col, row, true  -- true表示播放动画
                    )
                    
                    if captured then
                        Logger.info(string.format("吃了对方的%s %s",
                            captured.color, captured:get_char()))
                    end
                else
                    -- 不合法，提示一下（log里）
                    Logger.debug("走子不合法：" .. reason)
                    -- 点空白处取消选中？还是保持选中让玩家再选？
                    -- 我们保持选中吧，这样玩家可以继续选目标
                    if not clicked_piece then
                        -- 点空白处，取消选中
                        self._game_state:select_piece(nil)
                    end
                end
            end
        else
            -- 还没选中棋子
            if clicked_piece then
                -- 只能选中己方的棋子（当前回合的）
                if clicked_piece.color == self._game_state.current_turn then
                    self._game_state:select_piece(clicked_piece)
                    Logger.debug(string.format("选中棋子：%s %s", 
                        clicked_piece.color, clicked_piece:get_char()))
                else
                    -- 点的是对方棋子，不能选中
                    Logger.debug("不能选对方的棋子")
                end
            end
            -- 点空白处什么都不做
        end
    end
end

--[[
    键盘按下处理
]]
function GameScene:_on_key_press(data)
    local key = data.key
    
    -- 按2键切回菜单
    if key == "2" then
        Logger.info("返回菜单场景")
        local SceneManager = require("scenes.scene_manager")
        SceneManager:switch_scene("menu")
    end
    
    -- 按c清除点击点
    if key == "c" then
        self._click_points = {}
        Logger.info("清除所有点击点")
    end
    
    -- 按r重置游戏
    if key == "r" then
        if self._game_state then
            self._game_state:init_board()
            Logger.info("游戏已重置")
        end
    end
    
    -- 按u悔棋
    if key == "u" then
        if self._game_state and not self._game_state.game_over then
            -- 悔一步，人机模式的话要悔两步，把AI的一步也悔掉
            self._game_state:undo_move()
            if self._game_mode == "pve" and #self._game_state.move_history > 0 then
                -- 再悔一步，把AI的也悔了，回到玩家走之前
                self._game_state:undo_move()
            end
        end
    end
    
    -- 按m切换对战模式（PVP/PVE）
    if key == "m" then
        self._game_mode = self._game_mode == "pve" and "pvp" or "pve"
        -- 重置游戏
        if self._game_state then
            self._game_state:init_board()
        end
        Logger.info("切换模式：" .. self._game_mode)
    end
    
    -- 按1-4切换AI难度
    if key == "1" then
        self._ai_difficulty = "EASY"
        Logger.info("AI难度：简单")
    end
    if key == "2" then
        self._ai_difficulty = "NORMAL"
        Logger.info("AI难度：中等")
    end
    if key == "3" then
        self._ai_difficulty = "HARD"
        Logger.info("AI难度：困难")
    end
    if key == "4" then
        self._ai_difficulty = "EXPERT"
        Logger.info("AI难度：专家（有点慢）")
    end
    
    -- 按s相机震动测试
    if key == "s" then
        self._camera:shake(10, 0.5)
        Logger.info("相机震动测试")
    end
end

--[[
    鼠标滚轮处理
]]
function GameScene:_on_wheel(data)
    -- 滚轮缩放棋盘（测试用）
    if self._board then
        local delta = data.y * 5
        local new_size = self._board.cell_size + delta
        new_size = Utils.clamp(new_size, 20, 150)
        self._board:set_cell_size(new_size)
        self._board.x = love.graphics.getWidth() / 2
        self._board.y = love.graphics.getHeight() / 2
        Logger.debug("格子大小调整为：" .. new_size .. "px")
    end
end

--[[
    窗口大小改变
]]
function GameScene:resize(w, h)
    if self._board then
        self._board:fit_to_window(w, h)
    end
    if self._camera then
        self._camera:set_viewport(w, h)
    end
end

--[[
    更新
]]
function GameScene:update(dt)
    -- 更新相机
    if self._camera then
        self._camera:update(dt)
    end
    
    -- 更新游戏状态（棋子动画等）
    if self._game_state and self._board then
        self._game_state:update(dt, self._board)
    end
    
    -- AI走棋逻辑
    if self._game_state and self._game_mode == "pve" and not self._game_state.game_over then
        if self._game_state.current_turn == self._ai_color then
            -- 轮到AI走
            if not self._ai_thinking then
                -- 开始思考
                self._ai_thinking = true
                self._ai_delay_timer = self._ai_think_delay
            else
                -- 思考中，计时
                self._ai_delay_timer = self._ai_delay_timer - dt
                if self._ai_delay_timer <= 0 then
                    -- 思考时间到，走棋
                    self:_ai_make_move()
                    self._ai_thinking = false
                end
            end
        end
    end
    
    -- 更新点击点的时间，做淡出效果
    for i = #self._click_points, 1, -1 do
        local point = self._click_points[i]
        point.time = point.time + dt
        -- 超过3秒就移除
        if point.time > 3 then
            table.remove(self._click_points, i)
        end
    end
end

--[[
    AI走一步棋
]]
function GameScene:_ai_make_move()
    if not self._game_state or self._game_state.game_over then
        return
    end
    
    -- AI思考，选出最优走法
    local best_move, score = AI.get_best_move(
        self._game_state,
        self._ai_color,
        self._ai_difficulty
    )
    
    if best_move then
        -- 走棋
        Logger.info(string.format("AI走子：%s %s (%d,%d) → (%d,%d)，评估分 %.2f",
            best_move.piece.color, best_move.piece:get_char(),
            best_move.piece.col, best_move.piece.row,
            best_move.to_col, best_move.to_row,
            score))
        
        self._game_state:move_piece(
            best_move.piece,
            best_move.to_col,
            best_move.to_row,
            true  -- 播放动画
        )
    else
        Logger.warn("AI没有找到合法走法")
    end
end

--[[
    绘制
]]
function GameScene:draw()
    RenderSystem:clear()
    
    -- ===== 背景层 =====
    RenderSystem:add_to_layer("BACKGROUND", function()
        -- 背景色（游戏场景的背景跟菜单不一样，区分一下）
        love.graphics.setColor(0.08, 0.1, 0.12, 1)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end)
    
    -- ===== 游戏层 =====
    RenderSystem:add_to_layer("GAME", function()
        -- 相机变换内绘制游戏内容
        if self._camera then
            self._camera:begin()
        end
        
        -- 绘制棋盘
        if self._board then
            self._board:draw()
        end
        
        -- 绘制可走位置标记（选中棋子时显示）
        if self._game_state and self._game_state.selected_piece and self._board then
            local valid_moves = Rules.get_valid_moves(
                self._game_state.selected_piece, self._game_state
            )
            
            for _, move in ipairs(valid_moves) do
                local x, y = self._board:board_to_screen(move.col, move.row)
                
                -- 看看这个位置有没有棋子（就是可以吃的）
                local target_piece = self._game_state:get_piece_at(move.col, move.row)
                
                if target_piece then
                    -- 可以吃的棋子，画个红圈
                    love.graphics.setColor(1, 0.2, 0.2, 0.6)
                    love.graphics.setLineWidth(3)
                    love.graphics.circle("line", x, y, self._board.cell_size * 0.45)
                    love.graphics.setLineWidth(1)
                else
                    -- 空位置，画个小圆点
                    love.graphics.setColor(0.2, 0.8, 0.2, 0.6)
                    love.graphics.circle("fill", x, y, 8)
                end
            end
        end
        
        -- 绘制棋子
        if self._game_state and self._board then
            self._game_state:draw_pieces(self._board.cell_size)
        end
        
        -- 画点击的点（测试用，后面换成棋子）
        for _, point in ipairs(self._click_points) do
            -- 透明度随时间减少，淡出效果
            local alpha = math.max(0, 1 - point.time / 3)
            love.graphics.setColor(0, 1, 0, alpha)
            love.graphics.circle("fill", point.x, point.y, 8)
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.circle("line", point.x, point.y, 8)
        end
        
        -- 鼠标悬停的棋盘位置标记
        if self._board then
            local col = math.floor(self._hover_col + 0.5)
            local row = math.floor(self._hover_row + 0.5)
            if self._board:is_valid_position(col, row) then
                local x, y = self._board:board_to_screen(col, row)
                love.graphics.setColor(1, 1, 0, 0.5)
                love.graphics.circle("fill", x, y, 10)
            end
        end
        
        if self._camera then
            self._camera:finish()
        end
    end)
    
    -- ===== UI层 =====
    RenderSystem:add_to_layer("UI", function()
        -- 左上角信息
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("游戏场景 (GameScene) - V0.1 棋盘版", 10, 10)
        love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 30)
        love.graphics.print("鼠标位置: " .. math.floor(self._mouse_x) .. ", " .. math.floor(self._mouse_y), 10, 50)
        love.graphics.print("点击次数: " .. #self._click_points, 10, 70)
        
        -- 棋盘坐标
        if self._board then
            local col = math.floor(self._hover_col + 0.5)
            local row = math.floor(self._hover_row + 0.5)
            local valid = self._board:is_valid_position(col, row) and "有效" or "棋盘外"
            love.graphics.print(string.format("棋盘坐标: (%.1f, %.1f) → 格子(%d, %d) %s", 
                self._hover_col, self._hover_row, col, row, valid), 10, 90)
            love.graphics.print("格子大小: " .. self._board.cell_size .. "px", 10, 110)
        end
        
        -- 当前回合和选中信息
        if self._game_state then
            local turn_text = self._game_state.current_turn == "red" and "红方回合" or "黑方回合"
            love.graphics.print("当前回合: " .. turn_text, 10, 130)
            
            if self._game_state.selected_piece then
                local piece = self._game_state.selected_piece
                love.graphics.print(string.format("选中棋子: %s %s", 
                    piece.color == "red" and "红" or "黑", piece:get_char()), 10, 150)
            end
            
            love.graphics.print("棋子总数: " .. #self._game_state.pieces, 10, 170)
            love.graphics.print("走子步数: " .. #self._game_state.move_history, 10, 190)
            
            -- 将军提示
            local in_check = Rules.is_in_check(self._game_state.current_turn, self._game_state)
            if in_check then
                love.graphics.setColor(1, 0.3, 0.3, 1)
                love.graphics.print("⚠ 将军！", 10, 210)
                love.graphics.setColor(1, 1, 1, 1)
            end
            
            -- 模式和难度
            local mode_text = self._game_mode == "pve" and "人机对战" or "双人对战"
            love.graphics.print("游戏模式: " .. mode_text, 10, 230)
            if self._game_mode == "pve" then
                local diff_name = AI.DIFFICULTY[self._ai_difficulty] and AI.DIFFICULTY[self._ai_difficulty].name or "未知"
                love.graphics.print("AI难度: " .. diff_name, 10, 250)
            end
        end
        
        -- AI思考提示
        if self._game_mode == "pve" and self._ai_thinking then
            love.graphics.setColor(1, 0.8, 0.2, 1)
            local thinking_text = "AI思考中..."
            local text_w = love.graphics.getFont():getWidth(thinking_text)
            love.graphics.print(thinking_text, love.graphics.getWidth() - text_w - 20, 20)
            love.graphics.setColor(1, 1, 1, 1)
        end
        
        -- 游戏结束提示（在最上面）
        if self._game_state and self._game_state.game_over then
            local w = 400
            local h = 200
            local x = love.graphics.getWidth() / 2 - w / 2
            local y = love.graphics.getHeight() / 2 - h / 2
            
            -- 半透明背景
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.rectangle("fill", x, y, w, h, 10, 10)
            
            -- 边框
            love.graphics.setColor(0.8, 0.6, 0.2, 1)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", x, y, w, h, 10, 10)
            love.graphics.setLineWidth(1)
            
            -- 标题
            local title = ""
            local sub_title = ""
            if self._game_state.status == "checkmate" then
                title = "将 死！"
                sub_title = (self._game_state.winner == "red" and "红方" or "黑方") .. " 获胜"
            elseif self._game_state.status == "stalemate" then
                title = "困 毙！"
                sub_title = (self._game_state.winner == "red" and "红方" or "黑方") .. " 获胜"
            end
            
            love.graphics.setColor(1, 0.9, 0.5, 1)
            local title_font = love.graphics.newFont(48)
            love.graphics.setFont(title_font)
            local title_w = title_font:getWidth(title)
            love.graphics.print(title, x + w / 2 - title_w / 2, y + 30)
            
            love.graphics.setColor(1, 1, 1, 1)
            local sub_font = love.graphics.newFont(24)
            love.graphics.setFont(sub_font)
            local sub_w = sub_font:getWidth(sub_title)
            love.graphics.print(sub_title, x + w / 2 - sub_w / 2, y + 100)
            
            -- 提示
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
            local hint = "按 R 重新开始 | 按 U 悔棋"
            local hint_font = love.graphics.newFont(16)
            love.graphics.setFont(hint_font)
            local hint_w = hint_font:getWidth(hint)
            love.graphics.print(hint, x + w / 2 - hint_w / 2, y + 160)
            
            -- 恢复默认字体
            love.graphics.setFont(love.graphics.newFont(16))
        end
        
        -- 底部提示
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        local hint = "点击己方棋子走棋 | U 悔棋 | M 切换模式 | 1-4 切换难度 | R 重开 | 2 返回菜单"
        local hint_width = love.graphics.getFont():getWidth(hint)
        love.graphics.print(hint, (love.graphics.getWidth() - hint_width) / 2, love.graphics.getHeight() - 30)
    end)
    
    -- ===== 调试层 =====
    RenderSystem:add_to_layer("DEBUG", function()
        -- 鼠标十字线，帮助定位
        love.graphics.setColor(1, 0, 0, 0.3)
        love.graphics.line(self._mouse_x, 0, self._mouse_x, love.graphics.getHeight())
        love.graphics.line(0, self._mouse_y, love.graphics.getWidth(), self._mouse_y)
    end)
    
    -- 执行绘制
    RenderSystem:draw()
end

return GameScene
