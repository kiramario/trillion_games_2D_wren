--[[
    文件名：render_system.lua
    功能：渲染系统，分层管理绘制顺序
    特点：按层级绘制，同一层按添加顺序绘制，上层盖在下层上面
    类比：相当于 CSS 的 z-index 分层，或 Photoshop 的图层
    作者：wren
    创建日期：2026-06-09
    依赖：core.logger, core.config
]]

local Logger = require("core.logger")
local Config = require("core.config")

local RenderSystem = {}

-- 渲染层列表，按层级从小到大排列（小的先画，在下面）
-- 每一层是一个数组，里面放绘制函数
RenderSystem._layers = {}

-- 总层数（从配置里拿）
RenderSystem._layer_count = 0

--[[
    初始化渲染系统
]]
function RenderSystem:init()
    -- 从配置里获取所有渲染层，按层级号排序
    local layers = Config.render_layers
    if not layers then
        Logger.error("渲染层配置不存在！")
        return
    end
    
    -- 按层级值排序，确保绘制顺序正确
    local layer_names = {}
    for name, order in pairs(layers) do
        table.insert(layer_names, {name = name, order = order})
    end
    table.sort(layer_names, function(a, b) return a.order < b.order end)
    
    -- 初始化每一层
    self._layers = {}
    for _, layer in ipairs(layer_names) do
        self._layers[layer.order] = {
            name = layer.name,
            items = {}  -- 绘制项列表，每个项是一个函数
        }
        self._layer_count = math.max(self._layer_count, layer.order)
    end
    
    Logger.info("渲染系统初始化完成，共 " .. self._layer_count .. " 层")
end

--[[
    添加绘制函数到指定层
    参数：
        layer_name (string) - 层名称，比如 "GAME", "UI"
        draw_func (function) - 绘制函数，无参数
    返回：无
    示例：
        RenderSystem:add_to_layer("UI", function()
            love.graphics.print("Hello", 100, 100)
        end)
]]
function RenderSystem:add_to_layer(layer_name, draw_func)
    if type(draw_func) ~= "function" then
        Logger.error("添加到渲染层失败：不是函数")
        return
    end
    
    -- 获取层的顺序号
    local layer_order = Config.get("render_layers." .. layer_name)
    if not layer_order then
        Logger.error("渲染层不存在：" .. tostring(layer_name))
        return
    end
    
    -- 确保层存在
    if not self._layers[layer_order] then
        Logger.error("渲染层未初始化：" .. layer_name)
        return
    end
    
    -- 添加到层的绘制列表里
    table.insert(self._layers[layer_order].items, draw_func)
end

--[[
    清空所有层的绘制项
    一般每帧开头调用，然后重新添加这一帧要画的东西
]]
function RenderSystem:clear()
    for i = 1, self._layer_count do
        if self._layers[i] then
            self._layers[i].items = {}
        end
    end
end

--[[
    按层级顺序绘制所有内容
    一般在 love.draw() 里调用
]]
function RenderSystem:draw()
    -- 从第1层开始，一层一层往上画
    for i = 1, self._layer_count do
        local layer = self._layers[i]
        if layer and #layer.items > 0 then
            -- 绘制这一层的所有项
            for _, draw_func in ipairs(layer.items) do
                -- 用pcall保护，一个绘制函数出错不影响其他的
                local ok, err = pcall(draw_func)
                if not ok then
                    Logger.error("绘制出错，层：" .. layer.name .. "，错误：" .. tostring(err))
                end
            end
        end
    end
end

--[[
    获取某一层的绘制项数量（调试用）
    参数：
        layer_name (string) - 层名称
    返回：数量
]]
function RenderSystem:get_layer_item_count(layer_name)
    local layer_order = Config.get("render_layers." .. layer_name)
    if not layer_order or not self._layers[layer_order] then
        return 0
    end
    return #self._layers[layer_order].items
end

--[[
    打印所有层的信息（调试用）
]]
function RenderSystem:dump_layers()
    Logger.debug("=== 渲染层信息 ===")
    for i = 1, self._layer_count do
        local layer = self._layers[i]
        if layer then
            Logger.debug(string.format("层 %d (%s)：%d 个绘制项", i, layer.name, #layer.items))
        end
    end
    Logger.debug("==================")
end

Logger.info("渲染系统模块加载完成")

return RenderSystem
