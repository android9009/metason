-- osnova_gh.lua — Grenade Helper for AIMWARE CS2
-- Separate window, syncs visibility with AIMWARE menu

local GH = {}
_G.GH = GH

-- ============================================================
-- GUI Window
-- ============================================================
local gh_window = gui.Window("osnova_gh_win", "Grenade Helper", 100, 100, 500, 351)
gh_window:SetActive(false) -- hidden by default

-- Check if AIMWARE menu is open to sync visibility
local function gh_sync_menu()
    local menu_open = false
    pcall(function()
        local mref = gui.Reference("MENU")
        if mref then menu_open = mref:IsActive() end
    end)
    gh_window:SetActive(menu_open)
end

-- ============================================================
-- State
-- ============================================================
GH.locations = {} -- loaded locations for current map
GH.current_map = nil
GH.selected_index = -1

-- ============================================================
-- Map detection
-- ============================================================
local function gh_get_map()
    local map = nil
    pcall(function()
        local data = common.GetMapName and common.GetMapName() or nil
        if data and data ~= "" then map = data:lower():gsub("%.bsp$", "") end
    end)
    return map
end

-- ============================================================
-- File I/O: load/save locations
-- ============================================================
local function gh_load()
    local map = gh_get_map()
    if not map or map == "" then return end
    GH.current_map = map
    GH.locations = {}
    
    local data = nil
    pcall(function() data = file.Read("gh_" .. map .. ".json") end)
    if not data or data == "" then return end
    
    -- Simple JSON parse (array of objects)
    pcall(function()
        -- Try to parse basic JSON
        local decoded = {}
        for name, weapon, px, py, pz, vx, vy in data:gmatch(
            '{"name":"(.-)","weapon":"(.-)","pos":%[([^,]+),([^,]+),([^%]]+)%],"view":%[([^,]+),([^%]]+)%]}'
        ) do
            decoded[#decoded + 1] = {
                name = name,
                weapon = weapon,
                pos = { tonumber(px), tonumber(py), tonumber(pz) },
                view = { tonumber(vx), tonumber(vy) }
            }
        end
        GH.locations = decoded
    end)
end

local function gh_save()
    if not GH.current_map then return end
    local lines = {}
    for i, loc in ipairs(GH.locations) do
        lines[#lines + 1] = string.format(
            '{"name":"%s","weapon":"%s","pos":[%s,%s,%s],"view":[%s,%s]}',
            loc.name, loc.weapon,
            tostring(loc.pos[1]), tostring(loc.pos[2]), tostring(loc.pos[3]),
            tostring(loc.view[1]), tostring(loc.view[2])
        )
    end
    local json = table.concat(lines, "\n")
    pcall(function() file.Write("gh_" .. GH.current_map .. ".json", json) end)
end

-- ============================================================
-- GUI elements inside window
-- ============================================================
local gb_main = gui.Groupbox(gh_window, "Grenade Helper", 16, 16, 468, 300)

-- Location list
local gh_list = gui.Listbox(gb_main, "gh_locations", 200, "No locations loaded")

-- Buttons row
local gb_actions = gui.Groupbox(gh_window, "Actions", 16, 230, 468, 80)
local btn_add = gui.Button(gb_actions, "Add Location", function()
    local lp = entities.GetLocalPlayer()
    if not lp then return end
    
    local pos = lp:GetAbsOrigin()
    local va = nil
    pcall(function() va = lp:GetPropVector("m_angEyeAngles") end)
    if not va then
        pcall(function()
            local ang = lp:GetAbsAngles()
            va = Vector3(ang.x, ang.y, ang.z)
        end)
    end
    if not pos or not va then return end
    
    -- Determine current weapon
    local weapon = "smoke"
    pcall(function()
        local wt = lp:GetWeaponType()
        if wt == 9 then
            -- grenade type detection
            local def = nil
            local api = rawget(_G, "AWCHANGER_API")
            if api and api.activeDef then def = api.activeDef() end
            if def == 45 then weapon = "smoke"
            elseif def == 44 then weapon = "he"
            elseif def == 43 then weapon = "flash"
            elseif def == 46 or def == 48 then weapon = "molotov"
            elseif def == 47 then weapon = "decoy"
            end
        end
    end)
    
    local new_loc = {
        name = "Location " .. (#GH.locations + 1),
        weapon = weapon,
        pos = { pos.x, pos.y, pos.z },
        view = { va.x, va.y }
    }
    GH.locations[#GH.locations + 1] = new_loc
    
    -- Update listbox
    local items = {}
    for i, loc in ipairs(GH.locations) do
        items[#items + 1] = loc.weapon:upper() .. " - " .. loc.name
    end
    if #items == 0 then items = {"No locations loaded"} end
    gh_list:SetOptions(unpack(items))
    
    gh_save()
end)

local btn_remove = gui.Button(gb_actions, "Remove Selected", function()
    local sel = gh_list:GetValue() + 1
    if sel > 0 and sel <= #GH.locations then
        table.remove(GH.locations, sel)
        
        local items = {}
        for i, loc in ipairs(GH.locations) do
            items[#items + 1] = loc.weapon:upper() .. " - " .. loc.name
        end
        if #items == 0 then items = {"No locations loaded"} end
        gh_list:SetOptions(unpack(items))
        
        gh_save()
    end
end)

local btn_teleport = gui.Button(gb_actions, "Teleport to Selected", function()
    local sel = gh_list:GetValue() + 1
    if sel > 0 and sel <= #GH.locations then
        local loc = GH.locations[sel]
        if loc and loc.pos then
            client.Command(string.format(
                "setpos %s %s %s; setang %s %s",
                tostring(loc.pos[1]), tostring(loc.pos[2]), tostring(loc.pos[3]),
                tostring(loc.view[1]), tostring(loc.view[2])
            ), true)
        end
    end
end)

-- ============================================================
-- Auto-aim + auto-throw state
-- ============================================================
local gh_auto_active = false
local gh_auto_target = nil
local gh_throw_tick = 0

-- ============================================================
-- Draw callback: render locations on screen + sync menu
-- ============================================================
local gh_font = draw.CreateFont("Verdana", 14, 700)

local function gh_on_draw()
    gh_sync_menu()
    
    -- Check map change
    local map = gh_get_map()
    if map ~= GH.current_map then
        gh_load()
        local items = {}
        for i, loc in ipairs(GH.locations) do
            items[#items + 1] = loc.weapon:upper() .. " - " .. loc.name
        end
        if #items == 0 then items = {"No locations loaded"} end
        gh_list:SetOptions(unpack(items))
    end
    
    local lp = entities.GetLocalPlayer()
    if not lp then return end
    
    local alive = false
    pcall(function() alive = lp:IsAlive() end)
    if not alive then return end
    
    local my_pos = lp:GetAbsOrigin()
    if not my_pos then return end
    
    draw.SetFont(gh_font)
    
    -- Draw all locations on screen
    local closest_dist = 999999
    local closest_loc = nil
    
    for i, loc in ipairs(GH.locations) do
        if loc.pos and loc.pos[1] then
            local lpos = Vector3(loc.pos[1], loc.pos[2], loc.pos[3])
            local dist = (lpos - my_pos):Length()
            
            -- Track closest
            if dist < closest_dist then
                closest_dist = dist
                closest_loc = loc
            end
            
            -- Draw if within range
            if dist < 1500 then
                local sx, sy = client.WorldToScreen(lpos)
                if sx and sy then
                    -- Color by weapon type
                    local r, g, b = 255, 255, 255
                    if loc.weapon == "smoke" then r, g, b = 180, 180, 180
                    elseif loc.weapon == "flash" then r, g, b = 255, 255, 100
                    elseif loc.weapon == "he" then r, g, b = 255, 80, 80
                    elseif loc.weapon == "molotov" then r, g, b = 255, 150, 50
                    end
                    
                    -- Distance-based alpha
                    local alpha = math.max(40, math.min(255, 255 - (dist / 1500) * 200))
                    
                    -- Draw dot
                    draw.Color(r, g, b, alpha)
                    draw.FilledRect(sx - 4, sy - 4, sx + 5, sy + 5)
                    
                    -- Draw outline
                    draw.Color(0, 0, 0, alpha)
                    draw.OutlinedRect(sx - 5, sy - 5, sx + 6, sy + 6)
                    
                    -- Draw name + distance
                    draw.Color(r, g, b, alpha)
                    local label = string.format("%s [%s] %.0fm", loc.name, loc.weapon:upper(), dist)
                    local tw, th = draw.GetTextSize(label)
                    draw.Text(sx - math.floor(tw / 2), sy - 20, label)
                end
            end
        end
    end
    
    -- Auto-aim indicator for closest location
    if closest_loc and closest_dist < 50 then
        local sw, sh = draw.GetScreenSize()
        draw.Color(100, 255, 100, 255)
        draw.SetFont(gh_font)
        local info = string.format("Ready: %s [%s] — Hold hotkey to auto-throw", closest_loc.name, closest_loc.weapon:upper())
        local tw, th = draw.GetTextSize(info)
        draw.Text(math.floor(sw / 2 - tw / 2), sh - 60, info)
        
        gh_auto_target = closest_loc
    else
        gh_auto_target = nil
    end
end

-- ============================================================
-- CreateMove: auto-aim + auto-throw
-- ============================================================
local gh_hotkey = 0 -- will be set from GUI

local function gh_on_createmove(cmd)
    if not gh_auto_target then return end
    
    -- Check hotkey (default: E = KEY_USE = 15, but we use gui.Keybox value)
    local hk = 0
    pcall(function() hk = gh_hotkey:GetValue() end)
    if hk == 0 or not input.IsButtonDown(hk) then return end
    
    local loc = gh_auto_target
    if not loc or not loc.view then return end
    
    -- Set view angles to the saved position
    local va = cmd:GetViewAngles()
    va.x = loc.view[1]
    va.y = loc.view[2]
    va.z = 0
    cmd:SetViewAngles(va)
    
    -- Determine throw strength and attack buttons
    local strength = 1 -- full throw by default
    
    -- Attack based on grenade type
    if strength == 1 then
        -- Full throw: just LMB
        local buttons = cmd:GetButtons()
        cmd:SetButtons(bit.bor(buttons, IN_ATTACK))
    end
end

-- ============================================================
-- Hotkey GUI element
-- ============================================================
gh_hotkey = gui.Keybox(gb_main, "gh_hotkey", "Auto-Throw Hotkey", 0)
gh_hotkey:SetDescription("Hold this key near a location to auto-aim and throw")

-- ============================================================
-- Callbacks
-- ============================================================
callbacks.Register("Draw", "osnova_gh_draw", gh_on_draw)
callbacks.Register("CreateMove", "osnova_gh_cm", gh_on_createmove)

-- Load locations on start
gh_load()

-- ============================================================
-- Uninstall / cleanup function (called when checkbox is disabled)
-- ============================================================
function GH.uninstall()
    pcall(function() callbacks.Unregister("Draw", "osnova_gh_draw") end)
    pcall(function() callbacks.Unregister("CreateMove", "osnova_gh_cm") end)
    pcall(function() callbacks.Unregister("Unload", "osnova_gh_unload") end)
    -- Hide window
    pcall(function() gh_window:SetActive(false) end)
    _G.GH = nil
    print("[osnova] Grenade Helper unloaded")
end

-- Unload callback
callbacks.Register("Unload", "osnova_gh_unload", function()
    pcall(function() callbacks.Unregister("Draw", "osnova_gh_draw") end)
    pcall(function() callbacks.Unregister("CreateMove", "osnova_gh_cm") end)
    pcall(function() gh_window:SetActive(false) end)
    _G.GH = nil
end)

print("[osnova] Grenade Helper loaded")
