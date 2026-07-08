-- OSNOVA Wallbang Helper
-- Separate module. Grenade Helper only provides the WALLBANG tab container and calls WB.DrawTab().

local unpack = unpack or table.unpack

-- === ICON LOADER INJECTED ===
_G.WB_ICONS = _G.WB_ICONS or {
    queue = {},
    cache = {},
    list = {
    [1] = "weapon_deagle.png",
    [2] = "weapon_elite.png",
    [3] = "weapon_fiveseven.png",
    [4] = "weapon_glock.png",
    [7] = "weapon_ak47.png",
    [8] = "weapon_aug.png",
    [9] = "weapon_awp.png",
    [10] = "weapon_famas.png",
    [11] = "weapon_g3sg1.png",
    [13] = "weapon_galilar.png",
    [14] = "weapon_m249.png",
    [16] = "weapon_m4a1.png",
    [17] = "weapon_mac10.png",
    [19] = "weapon_p90.png",
    [24] = "weapon_ump45.png",
    [25] = "weapon_xm1014.png",
    [26] = "weapon_bizon.png",
    [27] = "weapon_mag7.png",
    [28] = "weapon_negev.png",
    [29] = "weapon_sawedoff.png",
    [30] = "weapon_tec9.png",
    [32] = "weapon_hkp2000.png",
    [33] = "weapon_mp7.png",
    [34] = "weapon_mp9.png",
    [35] = "weapon_nova.png",
    [36] = "weapon_p250.png",
    [38] = "weapon_scar20.png",
    [39] = "weapon_sg556.png",
    [40] = "weapon_ssg08.png",
    [60] = "weapon_m4a1_silencer.png",
    [61] = "weapon_usp_silencer.png",
    [63] = "weapon_cz75a.png",
    [64] = "weapon_revolver.png",
    ["default"] = "weapon_c4.png",
    ["scout"] = "weapon_ssg08.png",
    ["pistol"] = "weapon_deagle.png",
    ["rifle"] = "weapon_ak47.png",
    ["awp"] = "weapon_awp.png",
    ["auto"] = "weapon_scar20.png"
}
}

do
    local BASE_URL = "https://raw.githubusercontent.com/android9009/metason/main/icon/"
    local function make_rgba_white(rgba_string)
        local new_rgba = {}
        for i = 1, #rgba_string, 4 do
            local a = string.byte(rgba_string, i + 3)
            table.insert(new_rgba, string.char(255, 255, 255, a))
        end
        return table.concat(new_rgba)
    end

    for id, file in pairs(_G.WB_ICONS.list) do
        http.Get(BASE_URL .. file, function(data)
            if data then
                local rgba, width, height = common.DecodePNG(data)
                if rgba then
                    _G.WB_ICONS.queue[id] = { rgba = make_rgba_white(rgba), width = width, height = height }
                end
            end
        end)
    end
end
-- ============================



-- === ICON LOADER INJECTED ===
local osnova_icons = {
    ["all"] = "weapon_c4.png", -- fallback icon
    ["scout"] = "weapon_ssg08.png",
    ["pistol"] = "weapon_deagle.png",
    ["rifle"] = "weapon_ak47.png",
    ["awp"] = "weapon_awp.png",
    ["auto"] = "weapon_scar20.png"
}
local BASE_URL = "https://raw.githubusercontent.com/android9009/metason/main/icon/"
local textures_to_create = {}


local function make_rgba_white(rgba_string)
    local new_rgba = {}
    for i = 1, #rgba_string, 4 do
        local a = string.byte(rgba_string, i + 3)
        table.insert(new_rgba, string.char(255, 255, 255, a))
    end
    return table.concat(new_rgba)
end

for id, file in pairs(osnova_icons) do
    http.Get(BASE_URL .. file, function(data)
        if data then
            local rgba, width, height = common.DecodePNG(data)
            if rgba then
                textures_to_create[id] = { rgba = make_rgba_white(rgba), width = width, height = height }
            end
        end
    end)
end
-- ============================



_G.WB = _G.WB or {}
local WB = _G.WB
WB.loaded = true
WB.version = "0.2-builder"
WB.tab_name = "WALLBANG"

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
    map = tostring(map or "")
    map = map:gsub("\\", "/")
    map = map:match("([^/]+)$") or map
    map = map:gsub("%.bsp$", "")
    map = map:gsub("%.vpk$", "")
    if map == "" or map == "empty" or map == "nil" then
        map = "unknown"
    end
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
    WB.selected_map = normalize_map_name(WB.selected_map)
    if not WB.selected_map or WB.selected_map == "unknown" then WB.selected_map = WB.current_map end
end

local function get_maps()
    local seen, maps = {}, {}
    for _, m in ipairs(DEFAULT_MAPS) do
        if not seen[m] then seen[m] = true; table.insert(maps, m) end
    end
    for m, md in pairs(WB.maps or {}) do
        local nm = normalize_map_name(m)
        local has_locs = md and md.locations and #md.locations > 0
        if nm ~= "unknown" or has_locs or WB.selected_map == "unknown" then
            if not seen[nm] then seen[nm] = true; table.insert(maps, nm) end
        end
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
    -- Save marker at feet/origin height, not eye height.
    return o.x, o.y, o.z
end

local WB_WEAPON_FILTERS = {
    { id = "all", label = "All Weapons" },
    { id = "scout", label = "Scout" },
    { id = "pistol", label = "Pistols" },
    { id = "rifle", label = "Rifles" },
    { id = "awp", label = "AWP" },
    { id = "auto", label = "Auto Sniper" },
}

local WB_FILTER_LABEL = {
    all = "All",
    scout = "Scout",
    pistol = "Pistols",
    rifle = "Rifles",
    awp = "AWP",
    auto = "Auto",
}


local WD = { off = { dwEntityList = 38696576, dwLocalPlayerController = 36832624, m_hPlayerPawn = 2316, m_pWeaponServices = 4576, m_hActiveWeapon = 96, m_AttributeManager = 4480, m_Item = 80, m_iItemDefinitionIndex = 442 }, ready = false, tried = false }

local function wd_setup()
    if WD.tried then return end
    WD.tried = true
    local ffi = rawget(_G, "ffi")
    if type(ffi) ~= "table" then return end
    WD.ffi = ffi
    pcall(function() ffi.cdef[[ ]] end)
    local function r_ptr(a)
        local ok, v = pcall(function() return tonumber(ffi.cast("uint64_t*", a)[0]) end)
        return ok and v or nil
    end
    local function r_u16(a)
        local ok, v = pcall(function() return tonumber(ffi.cast("uint16_t*", a)[0]) end)
        return ok and v or nil
    end
    local function r_u32(a)
        local ok, v = pcall(function() return tonumber(ffi.cast("uint32_t*", a)[0]) end)
        return ok and v or nil
    end
    local function valid(p) return p ~= nil and p > 0x10000 and p < 0x7FFFFFFFFFFF end
    WD.r_ptr, WD.r_u16, WD.r_u32, WD.valid = r_ptr, r_u16, r_u32, valid
    WD.ready = true
end

local function wd_handle_to_entity(elist, hnd)
    local band, rshift = bit.band, bit.rshift
    if not (WD.valid(elist) and hnd and hnd ~= 0 and hnd ~= 0xFFFFFFFF) then return nil end
    local idx = band(hnd, 0x7FFF)
    local chunk = WD.r_ptr(elist + 8 * rshift(idx, 9) + 16)
    if not WD.valid(chunk) then return nil end
    local e = WD.r_ptr(chunk + 112 * band(idx, 0x1FF))
    if WD.valid(e) and WD.valid(WD.r_ptr(e)) then return e end
    return nil
end

local function ffi_active_weapon_def()
    wd_setup()
    if not WD.ready then return nil end
    local base = mem.GetModuleBase("client.dll")
    if not base then return nil end
    local ctrl = WD.r_ptr(base + WD.off.dwLocalPlayerController)
    if not WD.valid(ctrl) then return nil end
    local elist = WD.r_ptr(base + WD.off.dwEntityList)
    if not WD.valid(elist) then return nil end
    local pawn_handle = WD.r_u32(ctrl + WD.off.m_hPlayerPawn)
    local pawn = wd_handle_to_entity(elist, pawn_handle)
    if not WD.valid(pawn) then return nil end
    local ws = WD.r_ptr(pawn + WD.off.m_pWeaponServices)
    if not WD.valid(ws) then return nil end
    local wpn = wd_handle_to_entity(elist, WD.r_u32(ws + WD.off.m_hActiveWeapon))
    if not wpn then return nil end
    local item = wpn + WD.off.m_AttributeManager + WD.off.m_Item
    return WD.r_u16(item + WD.off.m_iItemDefinitionIndex)
end

local function active_weapon_def()
    local def = nil
    pcall(function()
        local api = rawget(_G, "AWCHANGER_API")
        if api and api.activeDef then def = api.activeDef() end
    end)
    if not def then
        pcall(function() def = ffi_active_weapon_def() end)
    end
    return def
end

local function current_weapon_filter()
    local def = active_weapon_def()
    if def == 40 then return "scout" end
    if def == 9 then return "awp" end
    if def == 11 or def == 38 then return "auto" end

    local pistols = { [1]=true,[2]=true,[3]=true,[4]=true,[30]=true,[32]=true,[36]=true,[61]=true,[63]=true,[64]=true }
    if pistols[def] then return "pistol" end

    local rifles = { [7]=true,[8]=true,[10]=true,[13]=true,[16]=true,[39]=true,[60]=true }
    if rifles[def] then return "rifle" end

    local lp = entities.GetLocalPlayer()
    local wt = -1
    if lp then pcall(function() wt = lp:GetWeaponType() end) end
    if wt == 1 then return "pistol" end

    return "unknown"
end

local function loc_weapon_allowed(loc)
    local f = loc and loc.weapon_filter or "all"
    if not f or f == "" or f == "all" then return true end
    local cur = current_weapon_filter()
    -- If location is filtered to Scout/Pistol/Rifle/AWP/Auto, then knife,
    -- grenade, zeus, bomb, or unknown weapon must NOT show it.
    if cur == "unknown" then return false end
    return f == cur
end

local function cycle_weapon_filter(loc)
    if not loc then return end
    local cur = loc.weapon_filter or "all"
    local idx = 1
    for i, it in ipairs(WB_WEAPON_FILTERS) do
        if it.id == cur then idx = i break end
    end
    idx = idx + 1
    if idx > #WB_WEAPON_FILTERS then idx = 1 end
    loc.weapon_filter = WB_WEAPON_FILTERS[idx].id
    save_db()
end

local WB_RENDER_MAX_DISTANCE = 450
local WB_RENDER_FADE_START = 350

local function get_local_origin()
    local lp = entities.GetLocalPlayer()
    if not lp or not lp:IsAlive() then return nil end
    return lp:GetAbsOrigin()
end

local function dist3(origin, x, y, z)
    local dx = (x or 0) - origin.x
    local dy = (y or 0) - origin.y
    local dz = (z or 0) - origin.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function wb_alpha_by_distance(dist)
    if dist > WB_RENDER_MAX_DISTANCE then return 0 end
    if dist <= WB_RENDER_FADE_START then return 255 end
    local fade = 1 - ((dist - WB_RENDER_FADE_START) / (WB_RENDER_MAX_DISTANCE - WB_RENDER_FADE_START))
    if fade < 0 then fade = 0 elseif fade > 1 then fade = 1 end
    return 255 * fade
end

local function wb_scale_by_distance(dist)
    if dist <= 250 then return 1 end
    local t = math.min(1, (dist - 250) / (WB_RENDER_MAX_DISTANCE - 250))
    return 1 - 0.45 * t
end

local function draw_world_label(sx, sy, text, r, g, b, alpha, scale, icon_id)
    scale = scale or 1
    draw.SetFont(scale < 0.75 and f_bind or f_main)
    local tw, th = draw.GetTextSize(text)
    local pad_x = math.max(5, math.floor(8 * scale))
    local pad_y = math.max(3, math.floor(4 * scale))
    local x1 = sx + 10 * scale
    local y1 = sy - (th + pad_y * 2) / 2
    local tex_w, tex_h = 0, 0
    local tex = nil
    if icon_id and _G.WB_ICONS.cache[icon_id] then
        tex = _G.WB_ICONS.cache[icon_id]
        tex_w = math.floor(tex.width * scale * 0.7)
        tex_h = math.floor(tex.height * scale * 0.7)
        if tex_w > 0 then tex_w = tex_w + 5 end
    end

    local x2 = x1 + tw + pad_x * 2 + 3 + tex_w
    local y2 = math.max(y1 + th + pad_y * 2, y1 + tex_h + pad_y * 2)

    draw.Color(0, 0, 0, alpha * 0.32)
    draw.ShadowRect(x1, y1, x2, y2, 8)
    draw.Color(12, 12, 12, alpha * 0.82)
    draw.RoundedRectFill(x1, y1, x2, y2, 4, 4, 4, 4, 4)
    draw.Color(r, g, b, alpha * 0.65)
    draw.RoundedRect(x1, y1, x2, y2, 4, 4, 4, 4, 4)
    draw.Color(r, g, b, alpha)
    draw.RoundedRectFill(x1 + 2, y1 + 2, x1 + 5, y2 - 2, 2, 2, 0, 2, 0)
    
    local text_x = x1 + pad_x + 3
    if tex then
        draw.Color(255, 255, 255, alpha)
        draw.SetTexture(tex.texture)
        local icon_y = y1 + (y2 - y1 - tex_h) / 2
        draw.FilledRect(text_x, icon_y, text_x + tex_w - 5, icon_y + tex_h)
        draw.SetTexture(nil)
        text_x = text_x + tex_w
    end
    
    draw.Color(230, 230, 230, alpha)
    draw.Text(text_x, y1 + (y2 - y1 - th) / 2, text)
end

local function draw_world_point(x, y, z, label, r, g, b, alpha, scale, icon_id)
    if not (x and y and z) then return nil, nil end
    local sx, sy = client.WorldToScreen(Vector3(x, y, z))
    if not sx or not sy or alpha <= 2 then return nil, nil end

    scale = scale or 1
    local radius = math.max(3, 5 * scale)
    draw.Color(r, g, b, alpha * 0.12)
    draw.OutlinedCircle(sx, sy, radius + 8 * scale)
    draw.Color(r, g, b, alpha * 0.20)
    draw.OutlinedCircle(sx, sy, radius + 4 * scale)
    draw.Color(r, g, b, alpha * 0.90)
    draw.FilledCircle(sx, sy, radius)
    draw.Color(255, 255, 255, alpha * 0.70)
    draw.FilledCircle(sx, sy, math.max(1.5, radius * 0.38))

    draw_world_label(sx, sy, label, r, g, b, alpha, scale, icon_id)
    return sx, sy
end


local function get_render_icon_id(loc)
    local def = active_weapon_def()
    if def and def > 0 then
        if _G.WB_ICONS.cache[def] then
            return def
        end
        if def >= 500 and def <= 525 and _G.WB_ICONS.cache["knife"] then
            return "knife"
        end
    end
    -- Fallback to the filter's default
    local f = loc and loc.weapon_filter or "all"
    if f == "all" then return "default" end
    return f
end

local function draw_wallbang_tracer(loc, alpha, r, g, b)
    if not (loc and loc.from_x and loc.from_y and loc.from_z and loc.to_x and loc.to_y and loc.to_z) then return end
    if alpha <= 2 then return end

    -- Draw the line in visible sampled pieces instead of requiring both endpoints
    -- to be on screen. This prevents the tracer from disappearing when one marker
    -- is offscreen / behind camera while part of the line is still visible.
    local last_x, last_y = nil, nil
    local samples = 24

    for i = 0, samples do
        local t = i / samples
        local x = loc.from_x + (loc.to_x - loc.from_x) * t
        local y = loc.from_y + (loc.to_y - loc.from_y) * t
        local z = loc.from_z + (loc.to_z - loc.from_z) * t
        local sx, sy = client.WorldToScreen(Vector3(x, y, z))

        if sx and sy then
            if last_x and last_y then
                draw.Color(255, 255, 255, alpha * 0.32)
                draw.Line(last_x, last_y, sx, sy)
                draw.Color(r, g, b, alpha * 0.58)
                draw.Line(last_x + 1, last_y + 1, sx + 1, sy + 1)
            end
            last_x, last_y = sx, sy
        else
            -- break the segment only for this invisible sample; next visible sample
            -- starts a new segment instead of killing the whole tracer.
            last_x, last_y = nil, nil
        end
    end
end

local function render_wallbang_world()

    for id, data in pairs(_G.WB_ICONS.queue) do
        _G.WB_ICONS.cache[id] = {
            texture = draw.CreateTexture(data.rgba, data.width, data.height),
            width = data.width,
            height = data.height
        }
        _G.WB_ICONS.queue[id] = nil
    end

    if not (WB.loaded and _G.OSNOVA_WALLBANG_ENABLED) then return end
    local origin = get_local_origin()
    if not origin then return end

    local map = get_map_name()
    local locs = get_locs(map)
    for _, loc in pairs(locs or {}) do
        if not loc_weapon_allowed(loc) then goto continue_wb_loc end
        local best_dist = nil
        if loc.from_x then best_dist = dist3(origin, loc.from_x, loc.from_y, loc.from_z) end
        if loc.to_x then
            local d2 = dist3(origin, loc.to_x, loc.to_y, loc.to_z)
            best_dist = best_dist and math.min(best_dist, d2) or d2
        end
        if best_dist then
            local alpha = wb_alpha_by_distance(best_dist)
            if alpha > 2 then
                local scale = wb_scale_by_distance(best_dist)
                local selected = (loc == get_locs(WB.selected_map)[WB.selected_location])
                local from_r, from_g, from_b = selected and 255 or 120, 255, selected and 255 or 120
                local to_r, to_g, to_b = 255, selected and 235 or 170, 95
                local name = loc.name or "Wallbang"
                draw_wallbang_tracer(loc, alpha, to_r, to_g, to_b)
                draw_world_point(loc.from_x, loc.from_y, loc.from_z, name, from_r, from_g, from_b, alpha, scale, get_render_icon_id(loc))
                draw_world_point(loc.to_x, loc.to_y, loc.to_z, name, to_r, to_g, to_b, alpha, scale, nil)
            end
        end
        ::continue_wb_loc::
    end
end

local function new_location()
    WB.selected_map = normalize_map_name(WB.selected_map)
    if WB.selected_map == "unknown" and WB.current_map and WB.current_map ~= "unknown" then
        WB.selected_map = WB.current_map
    end
    local locs = get_locs(WB.selected_map)
    local loc = {
        name = "New Wallbang",
        from_x = nil, from_y = nil, from_z = nil,
        to_x = nil, to_y = nil, to_z = nil,
        step = 1,
        weapon_filter = "all",
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
        local selected = false
        if mode == "map" then
            selected = (normalize_map_name(WB.selected_map) == normalize_map_name(items[i]))
        else
            selected = (WB.selected_location == i)
        end

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
            local wf = WB_FILTER_LABEL[loc.weapon_filter or "all"] or tostring(loc.weapon_filter or "All")
            text = text .. state .. " [" .. wf .. "]"
        end
        if selected and WB.renaming and mode == "loc" then text = WB.rename_buf .. "_" end

        draw.SetFont(f_main)
        draw.Color(selected and 255 or 160, selected and 255 or 160, selected and 255 or 160, 255)
        local text_x = x + 10
        local tex = nil
        
        if mode == "loc" and items[i].weapon_filter then
            local filter_id = items[i].weapon_filter
            -- Use the helper we wrote earlier: get_render_icon_id? Wait, in WB menu it should show what is CONFIGURED for that spot, not the active weapon.
            -- So just use items[i].weapon_filter directly.
            if _G.WB_ICONS.cache[filter_id] then
                tex = _G.WB_ICONS.cache[filter_id]
            elseif filter_id == "all" and _G.WB_ICONS.cache["default"] then
                tex = _G.WB_ICONS.cache["default"]
            end
        end

        if tex then
            local max_icon_h = 14
            local scale = math.min(1.0, max_icon_h / tex.height)
            local tex_w = math.floor(tex.width * scale * 0.7)
            local tex_h = math.floor(tex.height * scale * 0.7)
            
            draw.Color(selected and 255 or 160, selected and 255 or 160, selected and 255 or 160, 255)
            draw.SetTexture(tex.texture)
            local tex_y = iy + math.floor((22 - tex_h) / 2)
            draw.FilledRect(text_x, tex_y, text_x + tex_w, tex_y + tex_h)
            draw.SetTexture(nil)
            text_x = text_x + tex_w + 5
        end

        draw.Text(text_x, iy + 4, text)

        if hover and input.IsButtonPressed(1) then
            if mode == "map" then
                WB.selected_map = normalize_map_name(items[i])
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
    WB.selected_map = normalize_map_name(WB.selected_map)
    if WB.selected_map == "unknown" and WB.current_map ~= "unknown" then WB.selected_map = WB.current_map end
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

    -- Add Auto-walk Keybind UI
    local kw, kh = 120, 20
    draw.SetFont(f_main)
    draw.Color(230, 230, 230, 255)
    draw.Text(rx + 12, cy + 20, "Auto-Walk Key")
    
    local key_label = WB.autowalk_key == 0 and "None" or tostring(WB.autowalk_key)
    if WB._binding then key_label = "Press a key..." end
    
    local bx, by = rx + right_w - kw - 12, cy + 16
    draw.Color(0, 0, 0, 70)
    draw.ShadowRect(bx, by, bx + kw, by + kh, 8)
    draw.Color(20, 20, 20, 255)
    draw.RoundedRectFill(bx, by, bx + kw, by + kh, 3, 3, 3, 3, 3)
    draw.Color(45, 45, 45, 255)
    draw.RoundedRect(bx, by, bx + kw, by + kh, 3, 3, 3, 3, 3)
    
    draw.Color(180, 180, 180, 255)
    local tw, th = draw.GetTextSize(key_label)
    draw.Text(bx + (kw - tw)/2, by + (kh - th)/2, key_label)
    
    if mouse_in(bx, by, kw, kh) and input.IsButtonPressed(1) then
        WB._binding = true
    end
    
    if WB._binding then
        for i = 1, 255 do
            if i ~= 1 and i ~= 2 and input.IsButtonPressed(i) then
                if i == 27 then -- ESC
                    WB.autowalk_key = 0
                else
                    WB.autowalk_key = i
                end
                WB._binding = false
                break
            end
        end
    end

    draw_listbox(lx + 10, cy + 15, left_w - 20, ch - 25, get_maps(), "map")

    local locs = get_locs(WB.selected_map)
    draw_listbox(rx + 10, cy + 20, right_w - 20, ch - 143, locs, "loc")

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

    local weapon_label = "Weapon: All"
    if loc then
        weapon_label = "Weapon: " .. (WB_FILTER_LABEL[loc.weapon_filter or "all"] or tostring(loc.weapon_filter or "All"))
    end
    draw_button(rx + 10, by + 52, bw, 22, weapon_label, function()
        cycle_weapon_filter(locs[WB.selected_location])
    end)
end

function WB.uninstall()
    WB.loaded = false
    _G.OSNOVA_WALLBANG_ENABLED = false
    if _G.__OSNOVA then _G.__OSNOVA.wb_on = false end
    pcall(function() callbacks.Unregister("Draw", "osnova_wb_world") end)
    pcall(function() callbacks.Unregister("Unload", "osnova_wb_unload") end)
    _G.WB = nil
end

load_db()


WB.autowalk_key = WB.autowalk_key or 0

callbacks.Register("CreateMove", "osnova_wb_autowalk", function(cmd)
    if not (WB.loaded and _G.OSNOVA_WALLBANG_ENABLED) then return end
    
    local lp = entities.GetLocalPlayer()
    if not lp or not lp:IsAlive() then return end

    if WB.autowalk_key and WB.autowalk_key > 0 and input.IsButtonDown(WB.autowalk_key) then
        local origin = lp:GetAbsOrigin()
        
        local map = get_map_name()
        local locs = get_locs(map)
        local best_loc = nil
        local best_dist = math.huge
        
        for _, loc in ipairs(locs) do
            if loc.from_x and loc.from_y and loc.from_z and loc_weapon_allowed(loc) then
                local d = dist3(origin, loc.from_x, loc.from_y, loc.from_z)
                if d < best_dist and d < 350 then
                    best_dist = d
                    best_loc = loc
                end
            end
        end
        
        if best_loc then
            local dx = best_loc.from_x - origin.x
            local dy = best_loc.from_y - origin.y
            local dist2d = math.sqrt(dx*dx + dy*dy)
            
            if dist2d > 2.0 then
                -- Calculate world angle to target
                local target_yaw = math.deg(math.atan2(dy, dx))
                -- Get view angle
                local view_angles = engine.GetViewAngles()
                local cur_yaw = view_angles.yaw or view_angles.y or 0
                
                -- Relative angle
                local diff = math.rad(target_yaw - cur_yaw)
                
                -- Apply to cmd
                local max_speed = 250
                if dist2d < 15 then max_speed = 100 end
                if dist2d < 5 then max_speed = 30 end
                
                cmd.forwardmove = math.cos(diff) * max_speed
                cmd.sidemove = -math.sin(diff) * max_speed
                
                -- Force stop buttons
                cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(bit.bor(8, 16, 512, 1024)))) -- IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT
            else
                cmd.forwardmove = 0
                cmd.sidemove = 0
            end
        end
    end
end)

callbacks.Register("Draw", "osnova_wb_world", render_wallbang_world)
callbacks.Register("Unload", "osnova_wb_unload", function()
    pcall(function() callbacks.Unregister("CreateMove", "osnova_wb_autowalk") end)
    if WB and WB.uninstall then pcall(WB.uninstall) end
end)
