-- ============================================================================
-- 资源管理器
-- 功能：管理图片、音效、字体等资源的加载和缓存，避免重复加载
-- 类比：Web 的资源预加载，Unity 的 Resources 系统，游戏的资源池
-- 说明：LÖVE2D 加载资源是有开销的，加载过的缓存起来，下次直接用
-- ============================================================================

local Logger = require("core.logger")
local Utils = require("core.utils")

local ResourceManager = {}
ResourceManager.__index = ResourceManager

-- ============================================================================
-- 创建资源管理器
-- @return ResourceManager
-- ============================================================================
function ResourceManager.new()
  local self = setmetatable({}, ResourceManager)

  -- 缓存
  self.images = {}      -- 图片缓存
  self.sounds = {}      -- 音效缓存（短音效，static 类型）
  self.music = {}       -- 音乐缓存（长音乐，stream 类型）
  self.fonts = {}       -- 字体缓存
  self.shaders = {}     -- 着色器缓存

  -- 资源根目录
  self.image_dir = "assets/images/"
  self.sound_dir = "assets/sounds/"
  self.music_dir = "assets/music/"
  self.font_dir = "assets/fonts/"

  -- 统计
  self.total_loaded = 0
  self.total_failed = 0

  self.logger = Logger.get_default()

  return self
end

-- ============================================================================
-- 初始化
-- ============================================================================
function ResourceManager:init()
  self.logger:info("[ResourceManager] Initialized")
end

-- ============================================================================
-- 加载图片
-- @param string name 图片名称（不带路径和扩展名）
-- @param string path  完整路径（可选，默认从 image_dir 找）
-- @return userdata|nil Image 对象
-- ============================================================================
function ResourceManager:load_image(name, path)
  -- 已经缓存了，直接返回
  if self.images[name] then
    return self.images[name]
  end

  -- 没传路径的话，自动拼路径
  if not path then
    -- 尝试几种常见扩展名
    local exts = {".png", ".jpg", ".jpeg", ".bmp"}
    for _, ext in ipairs(exts) do
      local full_path = self.image_dir .. name .. ext
      if love and love.filesystem and love.filesystem.getInfo(full_path) then
        path = full_path
        break
      end
    end
    -- 都没找到的话，用 png 试试，可能会报错
    if not path then
      path = self.image_dir .. name .. ".png"
    end
  end

  -- 加载
  local image = nil
  local ok, err = pcall(function()
    image = love.graphics.newImage(path)
  end)

  if not ok or not image then
    self.logger:error("[ResourceManager] Failed to load image: " .. name .. " - " .. tostring(err))
    self.total_failed = self.total_failed + 1
    return nil
  end

  -- 缓存起来
  self.images[name] = image
  self.total_loaded = self.total_loaded + 1
  self.logger:debug("[ResourceManager] Loaded image: " .. name)

  return image
end

-- ============================================================================
-- 获取已加载的图片
-- ============================================================================
function ResourceManager:get_image(name)
  return self.images[name]
end

-- ============================================================================
-- 加载音效（短音效，加载到内存）
-- ============================================================================
function ResourceManager:load_sound(name, path)
  if self.sounds[name] then
    return self.sounds[name]
  end

  if not path then
    local exts = {".wav", ".ogg", ".mp3"}
    for _, ext in ipairs(exts) do
      local full_path = self.sound_dir .. name .. ext
      if love and love.filesystem and love.filesystem.getInfo(full_path) then
        path = full_path
        break
      end
    end
    if not path then
      path = self.sound_dir .. name .. ".ogg"
    end
  end

  local sound = nil
  local ok, err = pcall(function()
    sound = love.audio.newSource(path, "static")  -- static = 加载到内存
  end)

  if not ok or not sound then
    self.logger:error("[ResourceManager] Failed to load sound: " .. name .. " - " .. tostring(err))
    self.total_failed = self.total_failed + 1
    return nil
  end

  self.sounds[name] = sound
  self.total_loaded = self.total_loaded + 1
  self.logger:debug("[ResourceManager] Loaded sound: " .. name)

  return sound
end

function ResourceManager:get_sound(name)
  return self.sounds[name]
end

-- ============================================================================
-- 加载音乐（长音乐，流式播放，不全部加载到内存）
-- ============================================================================
function ResourceManager:load_music(name, path)
  if self.music[name] then
    return self.music[name]
  end

  if not path then
    local exts = {".ogg", ".mp3", ".wav"}
    for _, ext in ipairs(exts) do
      local full_path = self.music_dir .. name .. ext
      if love and love.filesystem and love.filesystem.getInfo(full_path) then
        path = full_path
        break
      end
    end
    if not path then
      path = self.music_dir .. name .. ".ogg"
    end
  end

  local music = nil
  local ok, err = pcall(function()
    music = love.audio.newSource(path, "stream")  -- stream = 流式加载
  end)

  if not ok or not music then
    self.logger:error("[ResourceManager] Failed to load music: " .. name .. " - " .. tostring(err))
    self.total_failed = self.total_failed + 1
    return nil
  end

  self.music[name] = music
  self.total_loaded = self.total_loaded + 1
  self.logger:debug("[ResourceManager] Loaded music: " .. name)

  return music
end

function ResourceManager:get_music(name)
  return self.music[name]
end

-- ============================================================================
-- 加载字体
-- @param string name 字体名
-- @param number size 字体大小
-- ============================================================================
function ResourceManager:load_font(name, size, path)
  size = size or 14
  local cache_key = name .. "_" .. size

  if self.fonts[cache_key] then
    return self.fonts[cache_key]
  end

  if not path then
    local exts = {".ttf", ".otf"}
    for _, ext in ipairs(exts) do
      local full_path = self.font_dir .. name .. ext
      if love and love.filesystem and love.filesystem.getInfo(full_path) then
        path = full_path
        break
      end
    end
  end

  local font = nil
  local ok, err = pcall(function()
    if path then
      font = love.graphics.newFont(path, size)
    else
      -- 没有找到字体文件，用默认字体
      font = love.graphics.newFont(size)
    end
  end)

  if not ok or not font then
    self.logger:error("[ResourceManager] Failed to load font: " .. name .. " - " .. tostring(err))
    -- 失败了就用默认字体
    font = love.graphics.newFont(size)
  end

  self.fonts[cache_key] = font
  self.total_loaded = self.total_loaded + 1
  self.logger:debug("[ResourceManager] Loaded font: " .. name .. " size: " .. size)

  return font
end

function ResourceManager:get_font(name, size)
  size = size or 14
  return self.fonts[name .. "_" .. size]
end

-- ============================================================================
-- 预加载一组资源
-- @param table resources 资源列表，格式：{ type = "image", name = "player" }
-- ============================================================================
function ResourceManager:preload(resources)
  local total = #resources
  local loaded = 0

  for _, res in ipairs(resources) do
    if res.type == "image" then
      self:load_image(res.name, res.path)
    elseif res.type == "sound" then
      self:load_sound(res.name, res.path)
    elseif res.type == "music" then
      self:load_music(res.name, res.path)
    elseif res.type == "font" then
      self:load_font(res.name, res.size, res.path)
    end
    loaded = loaded + 1
  end

  self.logger:info(string.format("[ResourceManager] Preloaded %d/%d resources", loaded, total))
end

-- ============================================================================
-- 卸载某个资源
-- ============================================================================
function ResourceManager:unload(type, name)
  if type == "image" then
    self.images[name] = nil
  elseif type == "sound" then
    if self.sounds[name] and self.sounds[name].release then
      self.sounds[name]:release()
    end
    self.sounds[name] = nil
  elseif type == "music" then
    if self.music[name] and self.music[name].release then
      self.music[name]:release()
    end
    self.music[name] = nil
  elseif type == "font" then
    self.fonts[name] = nil
  end
  self.logger:debug("[ResourceManager] Unloaded resource: " .. type .. "/" .. name)
end

-- ============================================================================
-- 卸载所有资源
-- ============================================================================
function ResourceManager:unload_all()
  -- 释放所有音源
  for name, sound in pairs(self.sounds) do
    if sound.release then sound:release() end
  end
  for name, music in pairs(self.music) do
    if music.release then music:release() end
  end

  self.images = {}
  self.sounds = {}
  self.music = {}
  self.fonts = {}
  self.shaders = {}

  self.total_loaded = 0
  self.total_failed = 0

  self.logger:info("[ResourceManager] All resources unloaded")
end

-- ============================================================================
-- 获取加载统计
-- ============================================================================
function ResourceManager:get_stats()
  return {
    images = Utils.table_length(self.images),
    sounds = Utils.table_length(self.sounds),
    music = Utils.table_length(self.music),
    fonts = Utils.table_length(self.fonts),
    total_loaded = self.total_loaded,
    total_failed = self.total_failed
  }
end

-- ============================================================================
-- 全局默认资源管理器实例
-- ============================================================================
local _default_manager = nil

function ResourceManager.get_default()
  if not _default_manager then
    _default_manager = ResourceManager.new()
  end
  return _default_manager
end

-- 快捷方法
function ResourceManager.init()
  ResourceManager.get_default():init()
end
function ResourceManager.load_image(name, path)
  return ResourceManager.get_default():load_image(name, path)
end
function ResourceManager.get_image(name)
  return ResourceManager.get_default():get_image(name)
end
function ResourceManager.load_sound(name, path)
  return ResourceManager.get_default():load_sound(name, path)
end
function ResourceManager.get_sound(name)
  return ResourceManager.get_default():get_sound(name)
end
function ResourceManager.load_music(name, path)
  return ResourceManager.get_default():load_music(name, path)
end
function ResourceManager.get_music(name)
  return ResourceManager.get_default():get_music(name)
end
function ResourceManager.load_font(name, size, path)
  return ResourceManager.get_default():load_font(name, size, path)
end
function ResourceManager.get_font(name, size)
  return ResourceManager.get_default():get_font(name, size)
end

return ResourceManager
