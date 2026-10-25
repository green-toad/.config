-- Загрузчик конфига: выполняет config.lua и печатает результат в JSON,
-- который читает Services/Config.qml.
--   lua lua/loader.lua /путь/к/config.lua

local path = arg and arg[1]

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

local function encode(v, depth)
  depth = depth or 0
  if depth > 20 then return "null" end
  local t = type(v)
  if t == "boolean" then return tostring(v) end
  if t == "number" then return string.format("%.14g", v) end
  if t == "string" then return esc(v) end
  if t == "table" then
    local out = {}
    if is_array(v) then
      for i = 1, #v do out[#out + 1] = encode(v[i], depth + 1) end
      return "[" .. table.concat(out, ",") .. "]"
    end
    for k, x in pairs(v) do
      out[#out + 1] = esc(tostring(k)) .. ":" .. encode(x, depth + 1)
    end
    return "{" .. table.concat(out, ",") .. "}"
  end
  return "null"
end

local function fail(msg)
  io.write(encode({ ok = false, error = tostring(msg) }))
  os.exit(0)
end

if not path then fail("не указан путь к config.lua") end

local chunk, err = loadfile(path)
if not chunk then fail(err) end

local ok, cfg = pcall(chunk)
if not ok then fail(cfg) end
if type(cfg) ~= "table" then fail("config.lua должен возвращать таблицу (return { ... })") end

io.write(encode({ ok = true, config = cfg }))
