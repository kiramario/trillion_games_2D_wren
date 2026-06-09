--[[
    文件名：resource_manager.lua
    功能：资源管理器，统一加载和缓存图片、音效、字体等资源
    类比：相当于浏览器的资源缓存，或 Unity 的 Resources 系统
    作者：wren
    创建日期：2026-06-09
    依赖：core.logger
]]

local Logger = require("core.logger")

local ResourceManager = {}

-- 资源缓存，key是路径，value是资源对象
ResourceManager._cache = {
    images = {},
    sounds = {},
    fonts = {},
    -- 后续可以加其他类型：shaders, data等
}

-- 资源基础路径
-- 这样后面改目录结构不用到处改路径
ResourceManager._paths = {
    images = "assets/images/",
    sounds = "assets/sounds/",
    fonts = "assets/fonts/",
}

--[[
    加载图片，有缓存直接返回缓存的
    参数：
        path (string) - 图片路径，相对于 images 目录
    返回：Image 对象（LÖVE2D的Image）
    示例：local img = ResourceManager:load_image("board.png")
]]
function ResourceManager:load_image(path)
    -- 检查缓存
    if self._cache.images[path] then
        Logger.debug("图片命中缓存：" .. path)
        return self._cache.images[path]
    end
    
    -- 完整路径
    local full_path = self._paths.images .. path
    Logger.debug("加载图片：" .. full_path)
    
    -- 用pcall保护，加载失败不崩溃
    local ok, image = pcall(function()
        return love.graphics.newImage(full_path)
    end)
    
    if not ok then
        Logger.error("图片加载失败：" .. full_path .. "，错误：" .. tostring(image))
        return nil
    end
    
    -- 存入缓存
    self._cache.images[path] = image
    return image
end

--[[
    加载音效，有缓存直接返回
    参数：
        path (string) - 音效路径，相对于 sounds 目录
        type (string) - 类型，"static"（短音效）或 "stream"（长音乐），默认static
    返回：Source 对象
]]
function ResourceManager:load_sound(path, sound_type)
    sound_type = sound_type or "static"
    
    -- 缓存key要包含类型，因为同一个文件不同类型是不同的对象
    local cache_key = path .. "_" .. sound_type
    if self._cache.sounds[cache_key] then
        Logger.debug("音效命中缓存：" .. path)
        return self._cache.sounds[cache_key]
    end
    
    local full_path = self._paths.sounds .. path
    Logger.debug("加载音效：" .. full_path)
    
    local ok, source = pcall(function()
        return love.audio.newSource(full_path, sound_type)
    end)
    
    if not ok then
        Logger.error("音效加载失败：" .. full_path .. "，错误：" .. tostring(source))
        return nil
    end
    
    self._cache.sounds[cache_key] = source
    return source
end

--[[
    加载字体，有缓存直接返回
    参数：
        path (string) - 字体路径，相对于 fonts 目录；可以是 nil 表示默认字体
        size (number) - 字体大小，默认16
    返回：Font 对象
    说明：同一个字体不同大小是不同的对象，所以缓存key要包含大小
]]
function ResourceManager:load_font(path, size)
    size = size or 16
    
    -- 缓存key
    local cache_key = (path or "default") .. "_" .. size
    if self._cache.fonts[cache_key] then
        Logger.debug("字体命中缓存：" .. tostring(path) .. "，大小：" .. size)
        return self._cache.fonts[cache_key]
    end
    
    local font
    if path then
        -- 加载自定义字体
        local full_path = self._paths.fonts .. path
        Logger.debug("加载字体：" .. full_path .. "，大小：" .. size)
        
        local ok, loaded_font = pcall(function()
            return love.graphics.newFont(full_path, size)
        end)
        
        if not ok then
            Logger.error("字体加载失败：" .. full_path .. "，错误：" .. tostring(loaded_font))
            Logger.warn("使用默认字体代替")
            font = love.graphics.newFont(size)
        else
            font = loaded_font
        end
    else
        -- 使用默认字体
        Logger.debug("加载默认字体，大小：" .. size)
        font = love.graphics.newFont(size)
    end
    
    self._cache.fonts[cache_key] = font
    return font
end

--[[
    卸载图片资源
    参数：
        path (string) - 图片路径
]]
function ResourceManager:unload_image(path)
    if self._cache.images[path] then
        -- LÖVE2D的Image对象会自动被GC释放，这里只要把引用清掉就行
        self._cache.images[path] = nil
        Logger.debug("卸载图片：" .. path)
    end
end

--[[
    卸载所有某类型的资源
    参数：
        type (string) - 资源类型："images", "sounds", "fonts"；不传就卸载所有
]]
function ResourceManager:unload_all(resource_type)
    if resource_type then
        if self._cache[resource_type] then
            self._cache[resource_type] = {}
            Logger.debug("卸载所有" .. resource_type .. "资源")
        end
    else
        -- 卸载所有
        for k, _ in pairs(self._cache) do
            self._cache[k] = {}
        end
        Logger.debug("卸载所有资源")
    end
end

--[[
    获取缓存统计信息（调试用）
    返回：各类型资源的数量
]]
function ResourceManager:get_cache_stats()
    local stats = {}
    for type_name, cache in pairs(self._cache) do
        stats[type_name] = Utils and Utils.table_length and Utils.table_length(cache) or 0
    end
    return stats
end

Logger.info("资源管理器初始化完成")

return ResourceManager
