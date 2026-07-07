-- OSNOVA Wallbang Helper
-- Separate module. Grenade Helper only provides the WALLBANG tab container and calls WB.DrawTab().

local unpack = unpack or table.unpack

_G.WB = _G.WB or {}
local WB = _G.WB
WB.loaded = true
WB.version = "0.2-builder"

_G.OSNOVA_WALLBANG_ENABLED = true
if _G.__OSNOVA then _G.__OSNOVA.wb_on = true end

WB.data_file = "osnova_wb_locations.txt"
WB.current_map = "unknown"
WB.maps = WB.maps or {}
WB.selected_map = WB.selected_map or "de_mirage"
WB.selected_location = WB.selected_location or 0
WB.map_scroll = WB.map_scroll or 0
WB.loc_scroll = WB.loc_scroll or 0
WB.renaming = false
WB.rename_buf = ""

local f_title = draw.CreateFont("Segoe UI", 15, 700, false, true)
local f_tabs = draw.CreateFont("Segoe UI Semibold", 12, 600, false, true)
local f_main = draw.CreateFont("Segoe UI", 12, 400, false, true)
local f_group = draw.CreateFont("Segoe UI Semibold", 11, 700, false, true)
local f_bind = draw.CreateFont("Segoe UI", 10, 400, false, true)

local DEFAULT_MAPS = {
    "de_mirage", "de_inferno", "de_dust2", "de_nuke", "de_ancient", "de_anubis",
    "de_overpass", "de_vertigo", "de_train", "de_cache", "de_cbble"
}

local function mouse_in(x, y, w, h)
    local mx, my = input.GetMousePos()
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

local function normalize_map_name(map)
    map = tostring(map or "unknown")
    map = map:gsub("\\", "/")
    map = map:match("([^/]+)$") or map
    map = map:gsub("%.bsp$", "")
    map = map:gsub("%.vpk$", "")
    return map
end

local function get_map_name()
    local map = nil
    local tries = {
        function() return engine and engine.GetMapName and engine.GetMapName() end,
        function() return engine and engine.GetLevelName and engine.GetLevelName() end,
        function() return client and client.GetMapName and client.GetMapName() end,
        function() return globals and globals.MapName and globals.MapName() end,
    }
    for _, fn in ipairs(tries) do
        local ok, v = pcall(fn)
        if ok and v and tostring(v) ~= "" then map = tostring(v); break end
    end
    return normalize_map_name(map or "unknown")
end

local function encode_lua_string(str)
    str = tostring(str or "")
    local out = { '"' }
    for i = 1, string.len(str) do
        table.insert(out, string.format("\\%03d", string.byte(str, i)))
    end
    table.insert(out, '"')
    return table.concat(out)
end

local function serialize_value(v, indent)
    indent = indent or 0
    local t = type(v)
    if t == "number" or t == "boolean" then return tostring(v) end
    if t == "string" then return encode_lua_string(v) end
    if t ~= "table" then return "nil" end
    local pad = string.rep(" ", indent)
    local out = { "{\n" }
    for k, val in pairs(v) do
        local key = type(k) == "number" and ("[" .. k .. "]") or ("[" .. encode_lua_string(tostring(k)) .. "]")
        table.insert(out, pad .. "  " .. key .. " = " .. serialize_value(val, indent + 2) .. ",\n")
    end
    table.insert(out, pad .. "}")
    return table.concat(out)
end

local function ensure_map(map)
    map = normalize_map_name(map or WB.current_map)
    WB.maps[map] = WB.maps[map] or { locations = {} }
    WB.maps[map].locations = WB.maps[map].locations or {}
    return WB.maps[map]
end

local function save_db()
    pcall(function() file.Write(WB.data_file, "return " .. serialize_value(WB.maps)) end)
end

local function load_db()
    local ok, data = pcall(function() return file.Read(WB.data_file) end)
    if ok and data and data ~= "" then
        local loader = loadstring or load
        local ok_load, loaded = pcall(function()
            local fn = loader(data)
            return fn and fn()
        end)
        if ok_load and type(loaded) == "table" then
            WB.maps = loaded
        end
    end

    WB.current_map = get_map_name()
    ensure_map(WB.current_map)
    if not WB.selected_map or WB.selected_map == "" then WB.selected_map = WB.current_map end
end

local function get_maps()
    local seen, maps = {}, {}
    for _, m in ipairs(DEFAULT_MAPS) do
        if not seen[m] then seen[m] = true; table.insert(maps, m) end
    end
    for m, _ in pairs(WB.maps or {}) do
        local nm = normalize_map_name(m)
        if not seen[nm] then seen[nm] = true; table.insert(maps, nm) end
    end
    table.sort(maps, function(a, b) return tostring(a) < tostring(b) end)
    return maps
end

local function get_locs(map)
    return ensure_map(map or WB.selected_map).locations
end

local function current_point()
    local lp = entities.GetLocalPlayer()
    if not lp or not lp:IsAlive() then return nil end
    local o = lp:GetAbsOrigin()
    return o.x, o.y, o.z + 64
end

local function new_location()
    local locs = get_locs(WB.selected_map)
    local loc = {
        name = "New Wallbang",
        from_x = nil, from_y = nil, from_z = nil,
        to_x = nil, to_y = nil, to_z = nil,
        step = 1,
    }
    table.insert(locs, loc)
    WB.selected_location = #locs
    save_db()
end

local function edit_point()
    local locs = get_locs(WB.selected_map)
    local loc = locs[WB.selected_location]
    if not loc then return end
    local x, y, z = current_point()
    if not x then return end

    if (not loc.from_x) or loc.step == 1 then
        loc.from_x, loc.from_y, loc.from_z = x, y, z
        loc.step = 2
    else
        loc.to_x, loc.to_y, loc.to_z = x, y, z
        loc.step = 1
    end
    save_db()
end

local function draw_button(x, y, w, h, label, callback)
    local hover = mouse_in(x, y, w, h)
    local down = hover and input.IsButtonDown(1)
    local bg = down and 235 or (hover and 42 or 24)
    local fg = down and 12 or (hover and 255 or 210)
    local border = hover and 95 or 46

    draw.Color(0, 0, 0, hover and 95 or 55)
    draw.ShadowRect(x, y, x + w, y + h, hover and 10 or 6)
    draw.Color(bg, bg, bg, 255)
    draw.RoundedRectFill(x, y, x + w, y + h, 5, 5, 5, 5, 5)
    draw.Color(border, border, border, 255)
    draw.RoundedRect(x, y, x + w, y + h, 5, 5, 5, 5, 5)

    draw.SetFont(f_main)
    draw.Color(fg, fg, fg, 255)
    local tw, th = draw.GetTextSize(label)
    draw.Text(x + (w - tw) / 2, y + (h - th) / 2, label)

    if hover and input.IsButtonPressed(1) and callback then callback() end
end

local function draw_listbox(x, y, w, h, items, mode)
    draw.Color(13, 13, 13, 255)
    draw.FilledRect(x, y, x + w, y + h)
    draw.Color(35, 35, 35, 255)
    draw.OutlinedRect(x, y, x + w, y + h)

    local scroll_key = mode == "map" and "map_scroll" or "loc_scroll"
    if mouse_in(x, y, w, h) then WB[scroll_key] = math.max(0, (WB[scroll_key] or 0) - input.GetMouseWheelDelta()) end
    local sc = WB[scroll_key] or 0

    for i = sc + 1, #items do
        local iy = y + (i - sc - 1) * 22
        if iy + 22 > y + h then break end
        local hover = mouse_in(x, iy, w, 22)
        local selected = mode == "map" and (WB.selected_map == items[i]) or (WB.selected_location == i)

        if selected then
            draw.Color(255, 255, 255, 40)
            draw.FilledRect(x + 1, iy + 1, x + w - 1, iy + 21)
            draw.Color(255, 255, 255, 220)
            draw.FilledRect(x + 1, iy + 1, x + 3, iy + 21)
        elseif hover then
            draw.Color(255, 255, 255, 8)
            draw.FilledRect(x + 1, iy + 1, x + w - 1, iy + 21)
        end

        local text = tostring(items[i].name or items[i])
        if mode == "loc" then
            local loc = items[i]
            local state = (loc.from_x and loc.to_x) and " [2/2]" or (loc.from_x and " [1/2]" or " [0/2]")
            text = text .. state
        end
        if selected and WB.renaming and mode == "loc" then text = WB.rename_buf .. "_" end

        draw.SetFont(f_main)
        draw.Color(selected and 255 or 160, selected and 255 or 160, selected and 255 or 160, 255)
        draw.Text(x + 10, iy + 4, text)

        if hover and input.IsButtonPressed(1) then
            if mode == "map" then
                WB.selected_map = items[i]
                WB.selected_location = 0
                WB.loc_scroll = 0
                ensure_map(WB.selected_map)
            else
                WB.selected_location = i
            end
        end
    end
end

local function process_rename()
    if not WB.renaming then return end
    for i = 32, 126 do
        if input.IsButtonPressed(i) then WB.rename_buf = WB.rename_buf .. string.char(i) end
    end
    if input.IsButtonPressed(8) then WB.rename_buf = WB.rename_buf:sub(1, -2) end
    if input.IsButtonPressed(13) then
        local locs = get_locs(WB.selected_map)
        local loc = locs[WB.selected_location]
        if loc then loc.name = WB.rename_buf; save_db() end
        WB.renaming = false
    end
end

function WB.DrawTab(cx, cy, cw, ch)
    WB.current_map = get_map_name()
    ensure_map(WB.current_map)
    process_rename()

    local gap = 12
    local left_w = math.floor((cw - gap) * 0.42)
    local right_w = cw - left_w - gap
    local lx, rx = cx, cx + left_w + gap

    draw.Color(0, 0, 0, 70)
    draw.ShadowRect(lx, cy, lx + left_w, cy + ch, 10)
    draw.Color(12, 12, 13, 245)
    draw.RoundedRectFill(lx, cy, lx + left_w, cy + ch, 6, 6, 6, 6, 6)
    draw.Color(35, 35, 35, 255)
    draw.RoundedRect(lx, cy, lx + left_w, cy + ch, 6, 6, 6, 6, 6)

    draw.Color(0, 0, 0, 70)
    draw.ShadowRect(rx, cy, rx + right_w, cy + ch, 10)
    draw.Color(12, 12, 13, 245)
    draw.RoundedRectFill(rx, cy, rx + right_w, cy + ch, 6, 6, 6, 6, 6)
    draw.Color(35, 35, 35, 255)
    draw.RoundedRect(rx, cy, rx + right_w, cy + ch, 6, 6, 6, 6, 6)

    draw.SetFont(f_group)
    draw.Color(255, 255, 255, 255)
    draw.Text(lx + 14, cy - 7, "MAP DATABASE")
    draw.Text(rx + 14, cy - 7, "WALLBANG LOCATIONS")

    draw.SetFont(f_bind)
    draw.Color(140, 140, 140, 255)
    draw.Text(rx + 12, cy + 2, "Current map: " .. tostring(WB.current_map))

    draw_listbox(lx + 10, cy + 15, left_w - 20, ch - 25, get_maps(), "map")

    local locs = get_locs(WB.selected_map)
    draw_listbox(rx + 10, cy + 20, right_w - 20, ch - 117, locs, "loc")

    local bw = right_w - 20
    local by = cy + ch - 74
    draw_button(rx + 10, by, bw / 2 - 2, 22, "Create", function() new_location() end)
    draw_button(rx + 10 + bw / 2 + 2, by, bw / 2 - 2, 22, "Rename", function()
        if WB.selected_location > 0 and locs[WB.selected_location] then
            WB.renaming = true
            WB.rename_buf = locs[WB.selected_location].name or "Wallbang"
        end
    end)
    draw_button(rx + 10, by + 26, bw / 2 - 2, 22, "Delete", function()
        if WB.selected_location > 0 and locs[WB.selected_location] then
            table.remove(locs, WB.selected_location)
            if WB.selected_location > #locs then WB.selected_location = #locs end
            save_db()
        end
    end)

    local edit_label = "Edit"
    local loc = locs[WB.selected_location]
    if loc then edit_label = loc.from_x and (loc.to_x and "Set From" or "Set To") or "Set From" end
    draw_button(rx + 10 + bw / 2 + 2, by + 26, bw / 2 - 2, 22, edit_label, function() edit_point() end)

    draw.SetFont(f_bind)
    draw.Color(125, 125, 125, 255)
    draw.Text(rx + 12, cy + ch - 20, "Edit: 1st click = FROM, 2nd click = TO")
end

function WB.uninstall()
    WB.loaded = false
    _G.OSNOVA_WALLBANG_ENABLED = false
    if _G.__OSNOVA then _G.__OSNOVA.wb_on = false end
    pcall(function() callbacks.Unregister("Unload", "osnova_wb_unload") end)
    _G.WB = nil
end

load_db()

callbacks.Register("Unload", "osnova_wb_unload", function()
    if WB and WB.uninstall then pcall(WB.uninstall) end
end)
