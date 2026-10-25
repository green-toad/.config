-- Загрузчик конфига: выполняет config.lua и печатает результат в JSON,
-- который читает Services/Config.qml.
--   lua lua/loader.lua /путь/к/config.lua
--
-- Здесь же "нормализация": запись виджета/блока может быть
--   "wifi"                              -> { type = "wifi" }
--   { "clock", format = "HH:mm" }       -> { type = "clock", format = ... }
--   { "row", "cpu", { "ram" } }         -> { type = "row", items = { ... } }

local path = arg and arg[1]

-- ---------------------------------------------------------------- JSON
local esc_map = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }

local function esc(s)
  return '"' .. (s:gsub('[%c"\\]', function(c)
    return esc_map[c] or string.format("\\u%04x", c:byte())
  end)) .. '"'
end

local function is_array(t)
  local n = 0
  for k in pairs(t) do
    if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then return false end
    n = n + 1
  end
  return n == #t
end

local encode
function encode(v, depth)
  depth = depth or 0
  if depth > 40 then return "null" end
  local t = type(v)
  if t == "nil" then return "null" end
  if t == "boolean" then return tostring(v) end
  if t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return "null" end
    return string.format("%.14g", v)
  end
  if t == "string" then return esc(v) end
  if t == "table" then
    local out = {}
    if is_array(v) then
      for i = 1, #v do out[#out + 1] = encode(v[i], depth + 1) end
      return "[" .. table.concat(out, ",") .. "]"
    end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
      out[#out + 1] = esc(tostring(k)) .. ":" .. encode(v[k], depth + 1)
    end
    return "{" .. table.concat(out, ",") .. "}"
  end
  return "null" -- функции и прочее не сериализуем
end

-- ---------------------------------------------------------- нормализация
local norm

local function norm_list(list)
  local res = {}
  if type(list) ~= "table" then return res end
  for _, e in ipairs(list) do
    local n = norm(e)
    if n then res[#res + 1] = n end
  end
  return res
end

function norm(entry)
  if type(entry) == "string" then return { type = entry } end
  if type(entry) ~= "table" then return nil end

  local out = {}
  for k, v in pairs(entry) do
    if type(k) == "string" then out[k] = v end
  end
  out.type = entry[1] or entry.type

  if #entry > 1 then
    -- позиционные дети: { "row", "cpu", { "ram" } }
    local items = {}
    for i = 2, #entry do
      local n = norm(entry[i])
      if n then items[#items + 1] = n end
    end
    out.items = items
  elseif type(out.items) == "table" then
    out.items = norm_list(out.items)
  end
  return out
end

-- ---------------------------------------------------------------- запуск
local function fail(msg)
  io.write(encode({ ok = false, error = tostring(msg) }))
  os.exit(0)
end

if not path then fail("не указан путь к config.lua") end

local dir = path:match("^(.*)/[^/]*$")
if dir then package.path = dir .. "/?.lua;" .. package.path end

local chunk, err = loadfile(path)
if not chunk then fail(err) end

local ok, cfg = pcall(chunk)
if not ok then fail(cfg) end
if type(cfg) ~= "table" then fail("config.lua должен возвращать таблицу (return { ... })") end

if type(cfg.bar) == "table" then
  for _, zone in ipairs({ "left", "center", "right" }) do
    if cfg.bar[zone] ~= nil then cfg.bar[zone] = norm_list(cfg.bar[zone]) end
  end
end
if type(cfg.dropdowns) == "table" then
  for _, d in pairs(cfg.dropdowns) do
    if type(d) == "table" and d.content ~= nil then d.content = norm_list(d.content) end
  end
end

io.write(encode({ ok = true, config = cfg }))
