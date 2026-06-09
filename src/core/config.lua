-- ============================================================================
-- 配置管理器
-- 功能：集中管理所有配置项，支持默认配置和运行时修改
-- 类比：JS 的 config 对象，Java 的 application.yml，Python 的 config.py
-- ============================================================================

local Utils = require("src.core.utils")

local Config = {}
Config.__index = Config

-- 默认配置
local DEFAULT_CONFIG = {
  -- 窗口配置
  window = {
    width = 960,
    height = 640,
    title = "Trillion Games 2D",
    fullscreen = false,
    resizable = true,
    vsync = true
  },

  -- 游戏配置
  game = {
    debug_mode = false,
    language = "zh-CN"
  },

  -- 音频配置
  audio = {
    master_volume = 1.0,
    sound_volume = 1.0,
    music_volume = 0.7,
    sound_enabled = true,
    music_enabled = true
  },

  -- 输入配置
  input = {
    -- 按键映射
    key_map = {
      cancel = "escape",
      confirm = "return",
      up = "w",
      down = "s",
      left = "a",
      right = "d"
    }
  },

  -- 渲染配置
  render = {
    max_particles = 1000,
    enable_particles = true,
    enable_shadows = true,
    bloom_effect = false
  }
}

-- ============================================================================
-- 创建配置管理器
-- @param table user_config 用户自定义配置，会覆盖默认配置
-- @return Config
-- ============================================================================
function Config.new(user_config)
  local self = setmetatable({}, Config)

  -- 深拷贝默认配置
  self.config = Utils.deep_copy(DEFAULT_CONFIG)

  -- 如果有用户配置，合并进去
  if user_config then
    self:merge(user_config)
  end

  return self
end

-- ============================================================================
-- 获取配置项
-- 支持点号路径，比如 config:get("window.width")
-- 类比：JS 的 lodash.get
-- ============================================================================
function Config:get(key_path, default_value)
  local keys = Utils.split(key_path, ".")
  local value = self.config

  for _, key in ipairs(keys) do
    if type(value) ~= "table" or value[key] == nil then
      return default_value
    end
    value = value[key]
  end

  return value
end

-- ============================================================================
-- 设置配置项
-- 也支持点号路径
-- ============================================================================
function Config:set(key_path, value)
  local keys = Utils.split(key_path, ".")
  local current = self.config

  -- 找到最后一个父级
  for i = 1, #keys - 1 do
    local key = keys[i]
    if type(current[key]) ~= "table" then
      current[key] = {}
    end
    current = current[key]
  end

  -- 设置值
  local last_key = keys[#keys]
  current[last_key] = value
end

-- ============================================================================
-- 合并另一个配置表
-- 类比：JS 的 Object.assign，深合并
-- ============================================================================
function Config:merge(another_config)
  local function merge_tables(t1, t2)
    for k, v in pairs(t2) do
      if type(v) == "table" and type(t1[k]) == "table" then
        merge_tables(t1[k], v)
      else
        t1[k] = v
      end
    end
  end

  merge_tables(self.config, another_config)
end

-- ============================================================================
-- 获取整个配置表（只读，请勿修改）
-- ============================================================================
function Config:get_all()
  return self.config
end

-- ============================================================================
-- 重设置为默认配置
-- ============================================================================
function Config:reset()
  self.config = Utils.deep_copy(DEFAULT_CONFIG)
end

-- ============================================================================
-- 全局默认配置实例
-- ============================================================================
local _default_config = Config.new()

function Config.get_default()
  return _default_config
end

-- 快捷方式，直接用 Config.get / Config.set
function Config.get(key_path, default_value)
  return _default_config:get(key_path, default_value)
end

function Config.set(key_path, value)
  _default_config:set(key_path, value)
end

return Config
