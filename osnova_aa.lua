_G.__AA = _G.__AA or {}
-- CSS2 - Anti-Aim Builder + FIXED BLOCKBOT & AIR STOP

local AA_SIG = nil
pcall(function()
	local src = http.Get("https://raw.githubusercontent.com/android9009/metason/main/osnova_signatures.lua")
	if type(src) == "string" and #src > 500 then
		local chunk = loadstring(src, "=osnova_signatures")
		if chunk then
			local ok, mod = pcall(chunk)
			if ok and type(mod) == "table" then AA_SIG = mod end
		end
	end
end)

local function aa_sig_pattern(name, fallback)
	if AA_SIG then
		local e = AA_SIG.get(name)
		if e and e.pattern then return e.pattern end
	end
	return fallback
end

local ffi = rawget(_G, "ffi")
pcall(function()
    if ffi then
        ffi.cdef[[
            void keybd_event(unsigned char bVk, unsigned char bScan, unsigned long dwFlags, unsigned long dwExtraInfo);
            short GetAsyncKeyState(int vKey);
            void* GetModuleHandleA(const char*);
            void* GetProcAddress(void*, const char*);
            void* VirtualAlloc(void*, size_t, uint32_t, uint32_t);
            int   VirtualProtect(void*, size_t, uint32_t, uint32_t*);
            void* GetCurrentProcess(void);
            int   FlushInstructionCache(void*, void*, size_t);
        ]]
    end
end)

local VK_SHIFT, VK_W, VK_A, VK_S, VK_D = 0x10, 0x57, 0x41, 0x53, 0x44
local KEYUP = 0x0002

-- UI References
local TAB  = gui.Reference("Ragebot", "Anti-Aim")
local TABM = gui.Reference("Ragebot", "Main")
local MISCROOT, MISCTAB
pcall(function() MISCROOT = gui.Reference("Miscellaneous") end)
pcall(function() if not MISCROOT then MISCROOT = gui.Reference("MISC") end end)
pcall(function() MISCTAB = gui.Reference("Miscellaneous", "Features") end)
MISCTAB = MISCTAB or MISCROOT or TABM

-- Constants
IN_FORWARD = 8; IN_BACK = 16; IN_LEFT = 512; IN_RIGHT = 1024; FL_ONGROUND = 1

-- AS / Blockbot Shared State
local AS = {
    active = false,
    keys = { w=false, a=false, s=false, d=false, shift=false },
    saved = { w=false, a=false, s=false, d=false },
    auto_saved = nil,
}

local function as_key(vk, down)
    if not ffi then return end
    pcall(function() ffi.C.keybd_event(vk, 0, down and 0 or KEYUP, 0) end)
end

local function as_down(vk)
    if not ffi then return false end
    local ok, v = pcall(function() return ffi.C.GetAsyncKeyState(vk) end)
    return ok and v and bit.band(v, 0x8000) ~= 0 or false
end

local function as_auto_ref()
    local r
    pcall(function() r = gui.Reference("Ragebot", "Main", "Movement", "Auto Steer") end)
    if not r then pcall(function() r = gui.Reference("Ragebot", "Main", "Movement", "Autostrafer") end) end
    return r
end

local function as_auto_off()
    local r = as_auto_ref(); if not r then return end
    if AS.auto_saved == nil then AS.auto_saved = r:GetValue() end
    r:SetValue(false)
end

local function as_auto_restore()
    local r = as_auto_ref(); if not r or AS.auto_saved == nil then return end
    r:SetValue(AS.auto_saved)
    AS.auto_saved = nil
end

local function as_set_script_keys(w, s, a, d)
    if w or s or a or d then
        if not AS.active then
            AS.saved.w = as_down(VK_W); AS.saved.a = as_down(VK_A)
            AS.saved.s = as_down(VK_S); AS.saved.d = as_down(VK_D)
            as_key(VK_W, false); as_key(VK_A, false); as_key(VK_S, false); as_key(VK_D, false)
        end
        AS.active = true
    end

    if AS.keys.w ~= w then as_key(VK_W, w); AS.keys.w = w end
    if AS.keys.s ~= s then as_key(VK_S, s); AS.keys.s = s end
    if AS.keys.a ~= a then as_key(VK_A, a); AS.keys.a = a end
    if AS.keys.d ~= d then as_key(VK_D, d); AS.keys.d = d end
end

local function as_release()
    as_set_script_keys(false, false, false, false)
    if AS.saved.w then as_key(VK_W, true) end
    if AS.saved.a then as_key(VK_A, true) end
    if AS.saved.s then as_key(VK_S, true) end
    if AS.saved.d then as_key(VK_D, true) end
    AS.saved = { w=false, a=false, s=false, d=false }
    AS.active = false
    as_auto_restore()
end

-- Blockbot logic
local blockbot_target = nil
local function handle_blockbot(cmd)
    if not g.blockbot_enable:GetValue() then 
        if blockbot_target then as_release() end
        blockbot_target = nil
        return 
    end

    local lp = entities.GetLocalPlayer()
    if not lp or not lp:IsAlive() then as_release(); return end
    
    local my_pos = lp:GetAbsOrigin()
    if not blockbot_target or not blockbot_target:IsAlive() then
        local players = entities.FindByClass("C_CSPlayerPawn")
        local best_dist = 300
        for i=1, #players do
            local p = players[i]
            if p:GetIndex() ~= lp:GetIndex() and p:IsAlive() then
                local d = (p:GetAbsOrigin() - my_pos):Length()
                if d < best_dist then best_dist = d; blockbot_target = p end
            end
        end
    end

    if not blockbot_target then as_release(); return end
    
    as_auto_off()
    local t_pos = blockbot_target:GetAbsOrigin()
    local t_vel = blockbot_target:GetPropVector("m_vecVelocity") or Vector3(0,0,0)
    local move_pos = t_pos + t_vel * (globals.TickInterval() * 3)
    
    local diff = move_pos - my_pos
    if diff:Length2D() > 1.5 then
        local va = cmd:GetViewAngles()
        local move_yaw = math.deg(math.atan2(diff.y, diff.x))
        local f = math.cos(math.rad(move_yaw - va.y))
        local s = math.sin(math.rad(move_yaw - va.y))
        
        cmd:SetForwardMove(f * 450)
        cmd:SetSideMove(s * 450)
        as_set_script_keys(f > 0.45, f < -0.45, s > 0.45, s < -0.45)
    else
        as_set_script_keys(false, false, false, false)
    end
end

-- GUI
g = {}
g.master = gui.Checkbox(TAB, "aa_master", "Enable AA Builder", false)
g.blockbot_enable = gui.Checkbox(MISCTAB, "aa_blockbot_enable", "Blockbot", false)
g.anti_kick = gui.Checkbox(MISCTAB, "misc_anti_kick", "Anti-kick", false)
g.air_stop = gui.Checkbox(TABM, "misc_air_stop", "Air Stop (Scout)", false)

-- Air Stop logic
local function handle_airstop(cmd, lp)
    if not g.air_stop:GetValue() then return end
    -- Scout only (def 40)
    local wp = lp:GetPropEntity("m_hActiveWeapon")
    if not wp or wp:GetPropInt("m_AttributeManager.m_Item.m_iItemDefinitionIndex") ~= 40 then return end
    
    if bit.band(lp:GetPropInt("m_fFlags"), FL_ONGROUND) ~= 0 then as_release(); return end
    
    as_auto_off()
    local vel = lp:GetPropVector("m_vecVelocity")
    if vel:Length2D() < 5 then as_release(); return end
    
    local va = cmd:GetViewAngles()
    local move_yaw = math.deg(math.atan2(-vel.y, -vel.x))
    local f = math.cos(math.rad(move_yaw - va.y))
    local s = math.sin(math.rad(move_yaw - va.y))
    
    as_set_script_keys(f > 0.45, f < -0.45, s > 0.45, s < -0.45)
end

function pre_move(cmd)
    local lp = entities.GetLocalPlayer()
    if not lp or not lp:IsAlive() then return end
    
    handle_airstop(cmd, lp)
    handle_blockbot(cmd)
end

callbacks.Register("PreMove", "aa_premove", pre_move)
print("[osnova] AA Builder + FIXED AS/Blockbot loaded")
