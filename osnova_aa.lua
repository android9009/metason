_G.__AA = _G.__AA or {}
-- CSS2 - Anti-Aim Builder
-- Yaw Base:
--   Local View - yaw stays around the local view, shaped by Offset + Modifier.
--   Auto Yaw   - built-in tuned values per weapon class + movement state.
-- Yaw Offset shifts the base yaw; Modifier adds a jitter pattern on top.
-- Plus pitch, manual directions, conditions, on-screen indicator.
-- Sets view angles in PreMove (matches the working Aimware example).

-- ============================================================
-- Централизованная база байтовых паттернов (osnova_signatures.lua).
-- Оффсеты netvar-полей (dwEntityList, dwLocalPlayerController и т.д.)
-- по-прежнему приходят из AWCHANGER_API.offsets (считает их osnova_skin.lua
-- через ту же централизованную базу) - тут ничего менять не нужно.
-- Этот блок нужен только для паттернов, которые ищутся напрямую в этом
-- файле (сейчас - VM_SIG для viewmodel offset хука). Если файл недоступен -
-- всё падает на прежние hardcoded паттерны, чит не ломается.
-- ============================================================
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

local TAB  = gui.Reference("Ragebot", "Anti-Aim")
-- manual directions / conditions / indicator live in the Auto Peek tab
local TAB2 = gui.Reference("Ragebot", "Auto Peek")
-- extra duck peek assist keybox lives in Ragebot > Main
local TABM = gui.Reference("Ragebot", "Main")
-- air stop checkbox lives in Ragebot > Automate
local TABAUT
pcall(function() TABAUT = gui.Reference("Ragebot", "Automate") end)
TABAUT = TABAUT or TAB2 or TABM
-- viewmodel offset sliders live in World > Camera. fall back to Ragebot > Main
-- if that reference name differs in this build.
local TABM1
pcall(function() TABM1 = gui.Reference("World", "Camera") end)
local VMTAB = TABM1 or TABM

-- custom scope lives in World > Extra
local TABEXTRA
pcall(function() TABEXTRA = gui.Reference("World", "Extra") end)
local SCOPETAB = TABEXTRA or VMTAB or TABM

-- logs live in Miscellaneous > Features.
-- Region changer gets its own root tab under Miscellaneous, like Skin Changer is attached to Visuals > Local.
local MISCROOT, MISCTAB, REGIONTAB
pcall(function() MISCROOT = gui.Reference("Miscellaneous") end)
pcall(function() if not MISCROOT then MISCROOT = gui.Reference("MISC") end end)
pcall(function() if not MISCROOT then MISCROOT = gui.Reference("Misc") end end)

pcall(function() MISCTAB = gui.Reference("Miscellaneous", "Features") end)
pcall(function() if not MISCTAB then MISCTAB = gui.Reference("MISC", "Features") end end)
pcall(function() if not MISCTAB then MISCTAB = gui.Reference("Misc", "Features") end end)
MISCROOT = MISCROOT or MISCTAB or TABM
MISCTAB = MISCTAB or MISCROOT or TABM
pcall(function() REGIONTAB = gui.Tab(MISCROOT, "aw_region_changer_tab", "Region") end)
REGIONTAB = REGIONTAB or MISCROOT

-- ============================================================
-- constants
-- ============================================================
STATES = { "Standing", "Moving", "Crouched", "In Air" }

IN_ATTACK   = bit.lshift(1, 0)
IN_ATTACK2  = bit.lshift(1, 11) -- right mouse / secondary attack
IN_JUMP     = bit.lshift(1, 1)
IN_DUCK     = bit.lshift(1, 2)
IN_FORWARD  = bit.lshift(1, 3)
IN_BACK     = bit.lshift(1, 4)
ON_USE      = bit.lshift(1, 5)
IN_LEFT     = bit.lshift(1, 9)
IN_RIGHT    = bit.lshift(1, 10)
MOVE_BITS   = IN_FORWARD + IN_BACK + IN_LEFT + IN_RIGHT
FL_ONGROUND = bit.lshift(1, 0)
FL_DUCKING  = bit.lshift(1, 1)
MOVETYPE_LADDER = 9
DUCK_COOLDOWN_TICKS = 96 -- ~1.5s re-crouch after a shot (64 tick)

-- Grenade throw fix: old/simple method.
-- When LMB/RMB is released with a grenade primed, skip anti-aim from that moment.
local GRENADE_NO_AA_TICKS_LMB = 12 -- starts on LMB release
local GRENADE_NO_AA_TICKS_RMB = 15 -- starts on RMB release

SWEEP_TICKS          = 2  -- ticks to rotate between manuals (through back)

-- Auto Yaw: tuned yaw offset (relative to local view) per state.
-- state index: 1 Standing, 2 Moving, 3 Crouched, 4 In Air.
AUTO_YAW = {
	knife   = { -167, -164, -169, -167 }, -- knife (GetWeaponType == 0)
	pistol  = { -169, -169, -162, -173 }, -- pistols (GetWeaponType == 1)
	other   = { -145, -152, -158, -154 }, -- rifles & snipers
	-- grenades = rifles/snipers base + grenade yaw correction:
	-- Standing -145 + -22 = -167
	-- Moving   -152 + -18 = -170
	-- Crouched -158 + -12 = -170
	-- In Air   -154 + -16 = -170
	grenade = { -167, -170, -170, -170 },
}

-- Manual Left / Right yaw offset (relative to local view) per state.
-- Used in BOTH Local View and Auto Yaw. Knife uses the pistol values.
-- each entry: { left, right }; state index 1 Standing,2 Moving,3 Crouch,4 Air.
MANUAL = {
	pistol = { { 100, -75 }, { 100, -80 }, { 111, -65 }, { 93, -78 } },
	other  = { { 124, -52 }, { 117, -67 }, { 108, -70 }, { 120, -62 } },
}

-- ============================================================
-- viewmodel offset hook (ported from femka / femboytap)
-- an FFI trampoline on client.dll adds page+4/+8/+12 (x/y/z) to the viewmodel
-- position vector. uses ffi exposed on _G (same as femka). all in pcall so a
-- missing signature / no ffi just disables it instead of crashing the script.
-- ============================================================
local VM = {}
do
	local ffi = rawget(_G, "ffi")
	-- Не найден точно такой же паттерн в централизованной базе (CalcViewmodel/
	-- CalcViewmodelView - другие функции с другими паттернами), поэтому тут
	-- просто hardcoded паттерн как раньше. aa_sig_pattern оставлен на будущее,
	-- если этот паттерн когда-нибудь появится в базе под своим именем.
	local VM_SIG = aa_sig_pattern("ViewmodelOffsetHook", "E8 ?? ?? ?? ?? 48 8B CB E8 ?? ?? ?? ?? 84 C0 74 11 F3 0F 10 45 B0")
	local page, match, origRel, ok = nil, nil, nil, false

	local function r_i32(a) return ffi.cast("int32_t*", a)[0] end
	local function w_u8 (a, v) ffi.cast("uint8_t*", a)[0] = v end
	local function w_i32(a, v) ffi.cast("int32_t*", a)[0] = v end
	local function w_f32(a, v) ffi.cast("float*",   a)[0] = v end

	local function le64(v)
		local t = {}
		for _ = 1, 8 do t[#t + 1] = v % 256; v = math.floor(v / 256) end
		return t
	end

	local function alloc_near(target, size)
		local gran = 0x10000
		local base = target - (target % gran)
		for i = 1, 0x8000 do
			local lo, hi = base - i * gran, base + i * gran
			if lo > 0x10000 then
				local p = ffi.C.VirtualAlloc(ffi.cast("void*", lo), size, 0x3000, 0x40)
				if p ~= nil then return p end
			end
			local p2 = ffi.C.VirtualAlloc(ffi.cast("void*", hi), size, 0x3000, 0x40)
			if p2 ~= nil then return p2 end
		end
		return nil
	end

	local function install()
		if type(ffi) ~= "table" then return false end
		pcall(function() ffi.cdef [[
			void* VirtualAlloc(void*, size_t, uint32_t, uint32_t);
			int   VirtualProtect(void*, size_t, uint32_t, uint32_t*);
			void* GetCurrentProcess(void);
			int   FlushInstructionCache(void*, void*, size_t);
		]] end)

		local a = mem.FindPattern("client.dll", VM_SIG)
		if not a or a == 0 then return false end
		match = a
		local orig = a + 5 + r_i32(a + 1)

		local p = alloc_near(orig, 0x1000)
		if p == nil then return false end
		page = tonumber(ffi.cast("uintptr_t", p))
		local code = page + 16

		local b = { 0x53, 0x56, 0x48,0x83,0xEC,0x28, 0x48,0x89,0xD6, 0x48,0xB8 }
		for _, v in ipairs(le64(orig)) do b[#b + 1] = v end
		for _, v in ipairs({ 0xFF,0xD0, 0x48,0xBB }) do b[#b + 1] = v end
		for _, v in ipairs(le64(page)) do b[#b + 1] = v end
		for _, v in ipairs({
			0x8B,0x0B, 0x85,0xC9, 0x74,0x2B,
			0xF3,0x0F,0x10,0x4B,0x04, 0xF3,0x0F,0x58,0x0E, 0xF3,0x0F,0x11,0x0E,
			0xF3,0x0F,0x10,0x4B,0x08, 0xF3,0x0F,0x58,0x4E,0x04, 0xF3,0x0F,0x11,0x4E,0x04,
			0xF3,0x0F,0x10,0x4B,0x0C, 0xF3,0x0F,0x58,0x4E,0x08, 0xF3,0x0F,0x11,0x4E,0x08,
			0x48,0x83,0xC4,0x28, 0x5E, 0x5B, 0xC3,
		}) do b[#b + 1] = v end
		for i = 0, #b - 1 do w_u8(code + i, b[i + 1]) end
		w_i32(page, 0); w_f32(page + 4, 0); w_f32(page + 8, 0); w_f32(page + 12, 0)

		local rel = code - (match + 5)
		if rel < -2147483648 or rel > 2147483647 then return false end
		origRel = r_i32(match + 1)
		local old = ffi.new("uint32_t[1]")
		ffi.C.VirtualProtect(ffi.cast("void*", match), 5, 0x40, old)
		w_i32(match + 1, rel)
		ffi.C.VirtualProtect(ffi.cast("void*", match), 5, old[0], old)
		pcall(function() ffi.C.FlushInstructionCache(ffi.C.GetCurrentProcess(), ffi.cast("void*", match), 5) end)
		return true
	end

	pcall(function() ok = install() end)

	function VM.set(on, x, y, z)
		if not ok or not page then return end
		pcall(function()
			w_i32(page, on and 1 or 0)
			w_f32(page + 4, x or 0)
			w_f32(page + 8, y or 0)
			w_f32(page + 12, z or 0)
		end)
	end

	function VM.uninstall()
		if not (ok and match and origRel) then return end
		pcall(function()
			local old = ffi.new("uint32_t[1]")
			ffi.C.VirtualProtect(ffi.cast("void*", match), 5, 0x40, old)
			w_i32(match + 1, origRel)
			ffi.C.VirtualProtect(ffi.cast("void*", match), 5, old[0], old)
		end)
	end
end
pcall(function() callbacks.Register("Unload", function() pcall(VM.uninstall) end) end)

-- ============================================================
-- Matchmaking region changer (ported from femka, silent/no prints)
-- ============================================================
local RG = { ok = false, ids = {}, names = {}, allow = {}, add = 200, enabled = false, installed = false, minimize = true }
do
	local f = rawget(_G, "ffi")
	local floor = math.floor
	local CITY = {
		ams = "Amsterdam", atl = "Atlanta", bom = "Mumbai", maa = "Chennai",
		can = "Guangzhou", sha = "Shanghai", tyo = "Tokyo", hkg = "Hong Kong",
		seo = "Seoul", sgp = "Singapore", syd = "Sydney", dxb = "Dubai",
		fra = "Frankfurt", lhr = "London", lux = "Luxembourg", par = "Paris",
		mad = "Madrid", sto = "Stockholm", vie = "Vienna", waw = "Warsaw",
		hel = "Helsinki", iad = "Washington", ord = "Chicago", lax = "Los Angeles",
		sea = "Seattle", dfw = "Dallas", okc = "Oklahoma", gru = "Sao Paulo",
		sao = "Sao Paulo", scl = "Santiago", lim = "Lima", bog = "Bogota",
		eat = "Moscow", sto2 = "Stockholm", jhb = "Johannesburg", pwj = "Tianjin",
		pwg = "Guangzhou", pwz = "Chengdu", tsn = "Tianjin", cpt = "Cape Town",
	}

	local function decode(id)
		local code = ""
		for sh = 24, 0, -8 do
			local c = floor(id / 2 ^ sh) % 256
			if c >= 32 and c < 127 then code = code .. string.char(c) end
		end
		return (code:gsub("%s", ""))
	end

	function RG.label(id)
		local code = decode(id)
		local city = CITY[code:lower()]
		if city then return city .. " (" .. code .. ")" end
		return code ~= "" and code or ("#" .. tostring(id))
	end

	if type(f) == "table" then
		pcall(function() f.cdef[[
			void* GetModuleHandleA(const char*);
			void* GetProcAddress(void*, const char*);
			void* VirtualAlloc(void*, size_t, uint32_t, uint32_t);
			int   VirtualProtect(void*, size_t, uint32_t, uint32_t*);
			void* GetCurrentProcess(void);
			int   FlushInstructionCache(void*, void*, size_t);
		]] end)

		local IDX_COUNT, IDX_LIST = 10, 11
		local TARGETS = {
			{ rva = 0x13F050, steal = 17 },             -- GetPingToDataCenter
			{ rva = 0x13EBB0, steal = 15, call = 10 },  -- GetDirectPingToPOP
		}
		local DLL  = "steamnetworkingsockets.dll"
		local ACCS = { "SteamNetworkingUtils_LibV4", "SteamNetworkingUtils_LibV3", "SteamNetworkingUtils_LibV2" }

		local hmod, base
		pcall(function() hmod = f.C.GetModuleHandleA(DLL) end)
		base = hmod ~= nil and tonumber(f.cast("uintptr_t", hmod)) or nil

		local utils, vtbl, getCount, getList
		if hmod ~= nil then
			local acc
			for _, nm in ipairs(ACCS) do
				local pp
				pcall(function() pp = f.C.GetProcAddress(hmod, nm) end)
				if pp ~= nil then acc = pp; break end
			end
			if acc ~= nil then
				local ok2, u = pcall(function() return f.cast("void*(*)(void)", acc)() end)
				if ok2 and u ~= nil then utils = u end
			end
			if utils ~= nil then
				pcall(function()
					vtbl = f.cast("void***", utils)[0]
					if vtbl ~= nil then
						getCount = f.cast("int(*)(void*)", vtbl[IDX_COUNT])
						getList  = f.cast("int(*)(void*, uint32_t*, int)", vtbl[IDX_LIST])
					end
				end)
			end
		end

		local function w_u8(a, v)  f.cast("uint8_t*",  a)[0] = v end
		local function w_i32(a, v) f.cast("int32_t*",  a)[0] = v end
		local function le64(a, v)  f.cast("uint64_t*", a)[0] = f.cast("uint64_t", v) end

		local function alloc_near(target)
			local gran = 0x10000
			local b = target - (target % gran)
			for i = 1, 0x8000 do
				local lo = b - i * gran
				if lo > 0x10000 then
					local p2 = f.C.VirtualAlloc(f.cast("void*", lo), 64, 0x3000, 0x40)
					if p2 ~= nil then return p2 end
				end
				local p3 = f.C.VirtualAlloc(f.cast("void*", b + i * gran), 64, 0x3000, 0x40)
				if p3 ~= nil then return p3 end
			end
			return nil
		end

		local hooks, keeps = {}, {}

		local function hookFunc(rva, steal, callOff)
			if not base then return nil end
			local T = base + rva
			local b0 = f.cast("uint8_t*", T)
			local p2 = alloc_near(T); if p2 == nil then return nil end
			local TR = tonumber(f.cast("uintptr_t", p2))

			local saved = {}
			for i = 0, steal - 1 do saved[i] = b0[i]; w_u8(TR + i, b0[i]) end

			if callOff then
				local relOrig = f.cast("int32_t*", T + callOff + 1)[0]
				local callTarget = (T + callOff + 5) + relOrig
				local newRel = callTarget - (TR + callOff + 5)
				if newRel < -2147483648 or newRel > 2147483647 then return nil end
				w_i32(TR + callOff + 1, newRel)
			end

			w_u8(TR + steal, 0xFF); w_u8(TR + steal + 1, 0x25); w_i32(TR + steal + 2, 0)
			le64(TR + steal + 6, T + steal)

			local orig = f.cast("int(*)(void*, uint32_t, uint32_t*)", f.cast("void*", TR))
			local cb = f.cast("int(*)(void*, uint32_t, uint32_t*)", function(self, popid, via)
				local r = orig(self, popid, via)
				if RG.enabled and r >= 0 and next(RG.allow) ~= nil then
					if RG.allow[tonumber(popid)] then
						if RG.minimize then return 1 end
					else
						return r + RG.add
					end
				end
				return r
			end)
			keeps[#keeps + 1] = cb

			local old = f.new("uint32_t[1]")
			if f.C.VirtualProtect(f.cast("void*", T), steal, 0x40, old) == 0 then return nil end
			w_u8(T, 0xFF); w_u8(T + 1, 0x25); w_i32(T + 2, 0); le64(T + 6, tonumber(f.cast("uintptr_t", cb)))
			for i = 14, steal - 1 do w_u8(T + i, 0x90) end
			f.C.VirtualProtect(f.cast("void*", T), steal, old[0], old)
			pcall(function() f.C.FlushInstructionCache(f.C.GetCurrentProcess(), f.cast("void*", T), steal) end)

			hooks[#hooks + 1] = { T = T, saved = saved, steal = steal }
			return orig
		end

		local function install()
			if not base then return false end
			local any = false
			for _, t in ipairs(TARGETS) do
				local o = nil
				pcall(function() o = hookFunc(t.rva, t.steal, t.call) end)
				if o then
					any = true
					if not RG.ping then RG.ping = o end
				end
			end
			RG.installed = any
			return any
		end

		function RG.uninstall()
			for _, h in ipairs(hooks) do
				pcall(function()
					local old = f.new("uint32_t[1]")
					f.C.VirtualProtect(f.cast("void*", h.T), h.steal, 0x40, old)
					for i = 0, h.steal - 1 do w_u8(h.T + i, h.saved[i]) end
					f.C.VirtualProtect(f.cast("void*", h.T), h.steal, old[0], old)
					f.C.FlushInstructionCache(f.C.GetCurrentProcess(), f.cast("void*", h.T), h.steal)
				end)
			end
			RG.installed = false
		end

		local function pingOf(id)
			if not RG.ping then return nil end
			local r
			pcall(function()
				local via = f.new("uint32_t[1]")
				r = RG.ping(nil, id, via)
			end)
			if r and r >= 0 and r < 100000 then return r end
			return nil
		end

		function RG.enumerate()
			if utils == nil or not getCount or not getList then return end
			local n = getCount(utils)
			if n <= 0 then return end
			if n > 256 then n = 256 end
			local buf = f.new("uint32_t[?]", n)
			local got = getList(utils, buf, n)
			if got < 0 then return end
			if got > n then got = n end
			local all, hasPing = {}, {}
			for i = 0, got - 1 do
				local id = tonumber(buf[i])
				local known = CITY[decode(id):lower()] ~= nil
				local ping = pingOf(id)
				local nm = RG.label(id) .. (ping and ("  " .. tostring(ping) .. "ms") or "")
				local e = { id = id, name = nm, known = known, ping = ping }
				all[#all + 1] = e
				if ping ~= nil and ping <= 250 then hasPing[#hasPing + 1] = e end
			end
			local use = (#hasPing > 0) and hasPing or all
			table.sort(use, function(a, b)
				if (a.ping ~= nil) ~= (b.ping ~= nil) then return a.ping ~= nil end
				if a.ping and b.ping and a.ping ~= b.ping then return a.ping < b.ping end
				if a.known ~= b.known then return a.known end
				return a.name < b.name
			end)
			local ids, names = {}, {}
			for _, e in ipairs(use) do ids[#ids + 1] = e.id; names[#names + 1] = e.name end
			if #ids > 0 then RG.ids = ids; RG.names = names end
		end

		pcall(function() RG.ok = install() end)
		if utils ~= nil and vtbl ~= nil then pcall(RG.enumerate) end
	end

	if #RG.names == 0 then RG.names = { "[ join a server, then Refresh ]" } end
end
pcall(function() callbacks.Register("Unload", function()
	pcall(RG.uninstall)
	-- сбрасываем при выгрузке

end) end)

-- ============================================================
-- GUI
-- ============================================================
g = {}

g.master = gui.Checkbox(TAB, "aa_master", "Enable AA Builder", false)
g.builder_mode = gui.Combobox(TAB, "aa_builder_mode", "AA Builder", "Builder", "Defensive Builder", "Round End AA")
g.defensive_enable = gui.Checkbox(TAB, "aa_defensive_enable", "Enable Defensive Builder", false)
g.roundend_enable = gui.Checkbox(TAB, "aa_roundend_enable", "Enable Round End AA", false)

-- Round End AA Yaw
g.re_yaw = gui.Combobox(TAB, "aa_re_yaw", "Round End Yaw", "Off", "Static", "Random", "Spin")
g.re_yaw_static = gui.Slider(TAB, "aa_re_yaw_static", "Round End Yaw Static", 90, -180, 180, 0.1)
g.re_yaw_spin  = gui.Slider(TAB, "aa_re_yaw_spin",  "Round End Yaw Spin Speed", 10, -60, 60, 0.1)

-- Round End AA Pitch
g.re_pitch = gui.Combobox(TAB, "aa_re_pitch", "Round End Pitch", "Off", "Directional", "Static", "Zero", "Up", "Down")
g.re_pitch_static = gui.Slider(TAB, "aa_re_pitch_static", "Round End Pitch Static", -89, -89, 89, 0.1)
g.re_pitch_dir_from = gui.Slider(TAB, "aa_re_pitch_dir_from", "Round End Pitch Dir From", -89, -89, 89, 0.1)
g.re_pitch_dir_to   = gui.Slider(TAB, "aa_re_pitch_dir_to",   "Round End Pitch Dir To",   89, -89, 89, 0.1)
g.re_pitch_dir_speed = gui.Slider(TAB, "aa_re_pitch_dir_speed", "Round End Pitch Dir Speed", 10, 1, 60, 0.1)
-- Auto Yaw is always applied; this only picks the reference the yaw is built on
g.base   = gui.Combobox(TAB, "aa_base",   "Yaw Base", "Local View", "At Target")
g.base:SetValue(1) -- default: At Target

-- Conditions selector: every movement condition has its own yaw/modifier/pitch settings.
-- Manual keys / general conditions still live in Ragebot > Auto Peek as before.
g.cond = gui.Combobox(TAB, "aa_condition", "Conditions", "Standing", "Moving", "Crouched", "In Air")

local function cond_var_name(name)
    return string.lower(name:gsub("%s+", "_"))
end

local function make_cond_controls(idx, name)
    local id = cond_var_name(name)
    local c = {}

    -- yaw offset shifts the base yaw (0 = the base value itself)
    c.yaw_offset = gui.Slider(TAB, "aa_" .. id .. "_yaw_offset", name .. " Yaw Offset", 0, -180, 180, 0.1)

    -- modifier: jitter pattern applied on top of the base yaw
    c.modifier   = gui.Combobox(TAB, "aa_" .. id .. "_modifier", name .. " Modifier", "Disabled", "Center", "Offset", "3-Way", "5-Way", "Anti-Nixware", "Spin")
    c.mod_left   = gui.Slider  (TAB, "aa_" .. id .. "_mod_left",   name .. " Modifier Left",   0, 0, 180, 0.1)
    c.mod_right  = gui.Slider  (TAB, "aa_" .. id .. "_mod_right",  name .. " Modifier Right",  0, 0, 180, 0.1)
    c.mod_offset = gui.Slider  (TAB, "aa_" .. id .. "_mod_offset", name .. " Modifier Offset", 60, -180, 180, 0.1)
    c.mod_3way   = gui.Slider  (TAB, "aa_" .. id .. "_mod_3way",   name .. " Modifier Range",  45, 0, 180, 0.1)
    c.mod_5way   = gui.Slider  (TAB, "aa_" .. id .. "_mod_5way",   name .. " Modifier Range",  45, 0, 180, 0.1)
    c.mod_spin   = gui.Slider  (TAB, "aa_" .. id .. "_mod_spin",   name .. " Modifier Speed",  10, -60, 60, 0.1)
    c.mod_delay  = gui.Slider  (TAB, "aa_" .. id .. "_mod_delay",  name .. " Modifier Delay",   4, 1, 32, 1)
    c.mod_random = gui.Checkbox(TAB, "aa_" .. id .. "_mod_random", name .. " Modifier Random", false)

    -- pitch per condition
    c.pitch       = gui.Combobox(TAB, "aa_" .. id .. "_pitch",       name .. " Pitch", "Disabled", "Down", "Up", "Jitter", "Zero", "Custom")
    c.pitch:SetValue(1) -- default: Down
    c.pitch_value = gui.Slider  (TAB, "aa_" .. id .. "_pitch_value", name .. " Pitch Offset", -89, -89, 89, 0.1)

    return c
end

g.cond_cfg = {}
for i = 1, #STATES do
    g.cond_cfg[i] = make_cond_controls(i, STATES[i])
end

-- ============================================================
-- Defensive Builder
-- ============================================================
local DEF_YAW_OPTIONS   = { "Off", "Sideways", "Static", "Directional", "L/R" }
local DEF_MOD_OPTIONS   = { "Disabled", "Center", "Offset", "3-Way", "5-Way", "Spin" }
local DEF_PITCH_OPTIONS = { "Disabled", "Down", "Up", "Jitter", "Zero", "Custom", "Directional", "Random" }

local function def_cond_var_name(name)
    return "def_" .. string.lower(name:gsub("%s+", "_"))
end

local function make_def_cond_controls(idx, name)
    local id = def_cond_var_name(name)
    local c = {}

    -- Defensive Yaw mode (0 Off, 1 Sideways, 2 Static, 3 Directional, 4 L/R)
    c.yaw = gui.Combobox(TAB, "aa_" .. id .. "_yaw", name .. " Yaw", unpack(DEF_YAW_OPTIONS))

    -- Yaw sub-sliders per mode
    c.yaw_sideways  = gui.Slider(TAB, "aa_" .. id .. "_yaw_sideways",  name .. " Yaw Sideways",  90,   0, 180, 0.1)
    c.yaw_static    = gui.Slider(TAB, "aa_" .. id .. "_yaw_static",    name .. " Yaw Static",    90, -180, 180, 0.1)
    c.yaw_dir_from  = gui.Slider(TAB, "aa_" .. id .. "_yaw_dir_from",  name .. " Yaw Dir From", -90, -180, 180, 0.1)
    c.yaw_dir_to    = gui.Slider(TAB, "aa_" .. id .. "_yaw_dir_to",    name .. " Yaw Dir To",    90, -180, 180, 0.1)
    c.yaw_dir_speed = gui.Slider(TAB, "aa_" .. id .. "_yaw_dir_speed", name .. " Yaw Dir Speed",  10,    1,  60, 0.1)
    c.yaw_lr_left   = gui.Slider(TAB, "aa_" .. id .. "_yaw_lr_left",   name .. " Yaw L/R Left",  -90, -180, 180, 0.1)
    c.yaw_lr_right  = gui.Slider(TAB, "aa_" .. id .. "_yaw_lr_right",  name .. " Yaw L/R Right",  90, -180, 180, 0.1)
    c.yaw_lr_delay  = gui.Slider(TAB, "aa_" .. id .. "_yaw_lr_delay",  name .. " Yaw L/R Delay",   4,    1,  32, 1)
    c.yaw_lr_random = gui.Slider(TAB, "aa_" .. id .. "_yaw_lr_random", name .. " Yaw L/R Random",  0,    0,  32, 1)

    -- Modifier (0 Disabled, 1 Center, 2 Offset, 3 3-Way, 4 5-Way, 5 Spin)
    c.modifier   = gui.Combobox(TAB, "aa_" .. id .. "_modifier", name .. " Modifier", unpack(DEF_MOD_OPTIONS))
    c.mod_left   = gui.Slider  (TAB, "aa_" .. id .. "_mod_left",   name .. " Modifier Left",   0,   0, 180, 0.1)
    c.mod_right  = gui.Slider  (TAB, "aa_" .. id .. "_mod_right",  name .. " Modifier Right",  0,   0, 180, 0.1)
    c.mod_offset = gui.Slider  (TAB, "aa_" .. id .. "_mod_offset", name .. " Modifier Offset", 60, -180, 180, 0.1)
    c.mod_3way   = gui.Slider  (TAB, "aa_" .. id .. "_mod_3way",   name .. " Modifier Range",  45,    0, 180, 0.1)
    c.mod_5way   = gui.Slider  (TAB, "aa_" .. id .. "_mod_5way",   name .. " Modifier Range",  45,    0, 180, 0.1)
    c.mod_spin   = gui.Slider  (TAB, "aa_" .. id .. "_mod_spin",   name .. " Modifier Speed",  10,  -60,  60, 0.1)
    c.mod_delay  = gui.Slider  (TAB, "aa_" .. id .. "_mod_delay",  name .. " Modifier Delay",   4,    1,  32, 1)
    c.mod_random = gui.Checkbox(TAB, "aa_" .. id .. "_mod_random", name .. " Modifier Random", false)

    -- Pitch (0 Disabled, 1 Down, 2 Up, 3 Jitter, 4 Zero, 5 Custom, 6 Directional, 7 Random)
    c.pitch       = gui.Combobox(TAB, "aa_" .. id .. "_pitch",       name .. " Pitch", unpack(DEF_PITCH_OPTIONS))
    c.pitch_value = gui.Slider  (TAB, "aa_" .. id .. "_pitch_value", name .. " Pitch Offset", -89, -89, 89, 0.1)

    -- Pitch sub-sliders
    c.pitch_jitter_from  = gui.Slider(TAB, "aa_" .. id .. "_pitch_jitter_from",  name .. " Pitch Jitter From",  -89, -89, 89, 0.1)
    c.pitch_jitter_to    = gui.Slider(TAB, "aa_" .. id .. "_pitch_jitter_to",    name .. " Pitch Jitter To",     89, -89, 89, 0.1)
    c.pitch_jitter_delay = gui.Slider(TAB, "aa_" .. id .. "_pitch_jitter_delay", name .. " Pitch Jitter Delay",   4,   1, 32, 1)
    c.pitch_dir_from     = gui.Slider(TAB, "aa_" .. id .. "_pitch_dir_from",     name .. " Pitch Dir From",     -89, -89, 89, 0.1)
    c.pitch_dir_to       = gui.Slider(TAB, "aa_" .. id .. "_pitch_dir_to",       name .. " Pitch Dir To",        89, -89, 89, 0.1)
    c.pitch_dir_speed    = gui.Slider(TAB, "aa_" .. id .. "_pitch_dir_speed",    name .. " Pitch Dir Speed",     10,   1, 60, 0.1)

    return c
end

g.def_cond = gui.Combobox(TAB, "aa_def_condition", "Defensive Conditions", "Standing", "Moving", "Crouched", "In Air")
g.def_cond_cfg = {}
for i = 1, #STATES do
    g.def_cond_cfg[i] = make_def_cond_controls(i, STATES[i])
end



-- manual directions (Auto Peek tab)
g.key_right   = gui.Keybox(TAB2, "aa_key_right",   "Manual Right",   0)
g.key_left    = gui.Keybox(TAB2, "aa_key_left",    "Manual Left",    0)
g.key_forward = gui.Keybox(TAB2, "aa_key_forward", "Manual Forward", 0)
g.fwd_mode    = gui.Combobox(TAB2, "aa_fwd_mode",   "Forward: Mode", "Toggle", "Hold")

-- brief jitter at the moment a manual direction is switched
-- conditions
g.on_ladder    = gui.Checkbox(TAB2, "aa_on_ladder",    "Disable on Ladder",  true)
g.on_use       = gui.Checkbox(TAB2, "aa_on_use",       "Disable on Use",     true)
g.disable_shot = gui.Checkbox(TAB2, "aa_disable_shot", "Disable on Shot",    true)
g.indicator    = gui.Checkbox(TAB2, "aa_indicator",    "Indicator",          true)

-- VAC-NET preset: при включении ставит At Target, 3-Way 55°, delay 2, Custom Pitch 45° на все кондишны
-- при выключении — возвращает все настройки обратно
g.vacnet       = gui.Checkbox(TAB2, "aa_vacnet",       "VAC-NET",            false)

-- Defensive Builder global tick sliders (Auto Peek tab)
g.def_tick   = gui.Slider(TAB2, "aa_def_tick",   "Defensive Tick", 4, 1, 128, 1)
g.build_tick = gui.Slider(TAB2, "aa_build_tick", "Builder Tick",   4, 1, 128, 1)
g.rand_tick  = gui.Slider(TAB2, "aa_rand_tick",  "Random Tick",    0, 0, 128, 1)

-- extra duck peek assist (Ragebot > Main): hold the bind and you stay crouched,
-- standing up automatically whenever an enemy is on screen (Shadow-style, but
-- without bullet-trace damage which this API can't do)
g.duck_peek    = gui.Keybox(TABM, "aa_duck_peek", "Duck Peek Assist+", 0)
g.air_stop     = gui.Checkbox(TABAUT, "aa_air_stop", "Air Stop (Scout only)", false)

-- Miscellaneous > Features: logs / hitlogs (only multibox; if nothing selected = logs off)
local add_screen_log
local log_entries, log_pending = {}, {}
g.logs_types  = gui.Multibox(MISCTAB, "Logs")
g.logs_hit    = gui.Checkbox(g.logs_types, "misc_logs_hit",    "Hit", true)
g.logs_kill   = gui.Checkbox(g.logs_types, "misc_logs_kill",   "Kill", true)
g.logs_hurt   = gui.Checkbox(g.logs_types, "misc_logs_hurt",   "Hurt", true)
g.logs_miss   = gui.Checkbox(g.logs_types, "misc_logs_miss",   "Miss", false)
g.logs_fire   = gui.Checkbox(g.logs_types, "misc_logs_fire",   "Weapon Fire", false)
g.logs_vote   = gui.Checkbox(g.logs_types, "misc_logs_vote",   "Vote Reveal", false)

function logs_enabled()
	return g.logs_hit:GetValue() or g.logs_kill:GetValue() or g.logs_hurt:GetValue() or g.logs_miss:GetValue() or g.logs_fire:GetValue() or g.logs_vote:GetValue()
end

-- ============================================================
-- FFI-резолв имён игроков (прямое чтение из памяти, как в femboytap)
-- Используется для голосований и логов
-- ============================================================
do
	local ffi_vote = rawget(_G, "ffi")
	local bit_vote = rawget(_G, "bit")
	local band_v, rshift_v = (bit_vote or {}).band, (bit_vote or {}).rshift

	local function h_r_ptr(a)
		if type(ffi_vote) ~= "table" then return nil end
		local ok, v = pcall(function() return tonumber(ffi_vote.cast("uint64_t*", a)[0]) end)
		return ok and v or nil
	end
	local function valid(p) return p ~= nil and p > 0x10000 and p < 0x7FFFFFFFFFFF end

	local VOFF = {}
	pcall(function()
		local CAPI = rawget(_G, "AWCHANGER_API") or {}
		VOFF.dwEntityList = CAPI.offsets and CAPI.offsets.dwEntityList
		VOFF.dwLocalPlayerController = CAPI.offsets and CAPI.offsets.dwLocalPlayerController
	end)
	pcall(function()
		local j = http.Get("https://raw.githubusercontent.com/a2x/cs2-dumper/main/output/client_dll.json")
		VOFF.m_iszPlayerName = j and tonumber(j:match('"m_iszPlayerName"%s*:%s*(%d+)')) or nil
	end)

	local function slot_v(elist, idx)
		if not (valid(elist) and band_v and rshift_v) then return nil end
		local chunk = h_r_ptr(elist + 8 * rshift_v(idx, 9) + 16)
		if not valid(chunk) then return nil end
		local e = h_r_ptr(chunk + 112 * band_v(idx, 0x1FF))
		if valid(e) and valid(h_r_ptr(e)) then return e end
		return nil
	end

	local function ctrlList_v()
		if not (type(ffi_vote) == "table" and VOFF.dwEntityList and VOFF.dwLocalPlayerController) then return nil, nil end
		local base = mem.GetModuleBase("client.dll")
		if not base then return nil, nil end
		local lctrl = h_r_ptr(base + VOFF.dwLocalPlayerController)
		local elist = h_r_ptr(base + VOFF.dwEntityList)
		if valid(lctrl) and valid(elist) then return lctrl, elist end
		return nil, nil
	end

	-- Прямое чтение имени игрока по его UserID (который также является слотом в entity list)
	function vote_name_by_userid(uid)
		uid = tonumber(uid) or 0
		if uid <= 0 then return nil end
		-- Сначала пробуем обычные методы
		local name = nil
		pcall(function() name = client.GetPlayerNameByUserID(uid) end)
		if name and name ~= "" then return name end
		local idx = nil
		pcall(function() idx = client.GetPlayerIndexByUserID(uid) end)
		if idx and idx > 0 then
			pcall(function() name = client.GetPlayerNameByIndex(idx) end)
			if name and name ~= "" then return name end
		end

		-- FFI fallback: читаем напрямую из памяти, как в femboytap
		-- Внимание: UserID = slot - 1, поэтому передаём uid как слот (femboytap так и делает)
		if not VOFF.m_iszPlayerName or type(ffi_vote) ~= "table" then return nil end
		local _, elist = ctrlList_v()
		if not valid(elist) then return nil end
		local c = slot_v(elist, (tonumber(uid) or 0) + 1)  -- +1 как в femboytap/HS.nameOf
		if not valid(c) then return nil end
		local nm
		pcall(function() nm = ffi_vote.string(ffi_vote.cast("const char*", c + VOFF.m_iszPlayerName)) end)
		if nm and #nm > 0 and #nm < 64 then return nm end
		return nil
	end

end

function vote_log(text)
	if not (g.logs_vote and g.logs_vote:GetValue()) then return end
	if add_screen_log then
		add_screen_log("vote", tostring(text or ""))
	else
		pcall(function() print("[Vote] " .. tostring(text or "")) end)
	end
end

-- Vote Reveal state (только для лога, без авто-действий)
VB = VB or {
	yes = 0,
	no = 0,
	voters = {},
}

local function vb_reset()
	VB.yes = 0
	VB.no = 0
	VB.voters = {}
end

-- ============================================================
-- ВАЖНО: поля событий строго по официальной схеме CS2 (core.gameevents):
--   vote_started { issue:string, param1:string, votedata:string, team:byte, initiator:long }
--   vote_cast    { vote_option:int, userid:... }  (структура как в femboytap)
-- Раньше здесь param1 читался через GetInt (а это STRING в схеме) - несовпадение
-- типа поля protobuf-события на уровне API чита может крашить нативно (мимо
-- pcall), это и было вероятной причиной краша при старте голосования.
-- Переписано строго по рабочему образцу из femboytap.txt: entityid/disp_str,
-- никакого param1-as-int, никакой обработки vote_passed/vote_failed (в CS2
-- эти ивенты либо не приходят по FireGameEvent, либо их поля недокументированы
-- и небезопасны для угадывания - лучше не трогать вовсе).
-- ============================================================
function vote_on_event(ev)
	local name = nil
	pcall(function() name = ev:GetName() end)

	if name == "vote_started" or name == "vote_begin" then
		vb_reset()

		local initiator = 0
		pcall(function() initiator = ev:GetInt("entityid") end)
		if not initiator or initiator <= 0 then
			pcall(function() initiator = ev:GetInt("userid") end)
		end

		local tid = nil
		pcall(function()
			local disp = ev:GetString("disp_str")
			if type(disp) == "string" then
				local m = disp:match(":(%d+):")
				if m then tid = tonumber(m) end
			end
		end)

		if g.logs_vote and g.logs_vote:GetValue() then
			local who = vote_name_by_userid(initiator) or "player"
			local target = tid and (vote_name_by_userid(tid) or "player") or "player"
			vote_log(who .. " started a vote to kick " .. target)
		end

	elseif name == "vote_cast" then
		local opt = nil
		pcall(function() opt = ev:GetInt("vote_option") end)
		if opt == nil or opt < 0 then return end

		local voter = 0
		pcall(function() voter = ev:GetInt("userid") end)

		local yes = (opt == 0)
		local who = vote_name_by_userid(voter) or "player"
		VB.voters[#VB.voters + 1] = {name = who, option = opt}

		if yes then
			VB.yes = VB.yes + 1
			if g.logs_vote and g.logs_vote:GetValue() then
				vote_log(who .. " voted yes [" .. VB.yes .. "]")
			end
		else
			VB.no = VB.no + 1
			if g.logs_vote and g.logs_vote:GetValue() then
				vote_log(who .. " voted no")
			end
		end
	end
end

-- Anti-kick / reconnect bypass firewall toggle
g.anti_kick = gui.Checkbox(MISCTAB, "misc_anti_kick", "Anti-kick", false)
g.blockbot_enable = gui.Checkbox(MISCTAB, "aa_blockbot_enable", "Blockbot", false)
g.blockbot_key = gui.Keybox(MISCTAB, "aa_blockbot_key", "Blockbot Key", 0)


AK = AK or {
    enabled = false,
    ready = false,
    steam = nil,
    rule = "ReconnectBypass",
    task_enable = "ReconnectBypass_Enable",
    task_disable = "ReconnectBypass_Disable",
    pending_task = nil,
    install_requested = false,
    next_task_check = 0,
    reconnect_at = -1000,
    reconnect_tries = 0,
}

function AK.init()
    if AK.ready then return true end
    AK.ffi = rawget(_G, "ffi")
    if not AK.ffi then return false end
    pcall(function()
        AK.ffi.cdef[[
            typedef void* HANDLE;
            void* ShellExecuteA(void* hwnd, const char* lpOperation, const char* lpFile, const char* lpParameters, const char* lpDirectory, int nShowCmd);
            int RegOpenKeyExA(void* hKey, const char* lpSubKey, unsigned long ulOptions, unsigned long samDesired, void** phkResult);
            int RegQueryValueExA(void* hKey, const char* lpValueName, unsigned long* lpReserved, unsigned long* lpType, unsigned char* lpData, unsigned long* lpcbData);
            int RegCloseKey(void* hKey);
            int system(const char* command);
        ]]
    end)
    pcall(function() AK.shell32 = AK.ffi.load("Shell32") end)
    pcall(function() AK.advapi = AK.ffi.load("Advapi32") end)
    pcall(function() AK.msvcrt = AK.ffi.load("msvcrt") end)
    AK.ready = AK.shell32 ~= nil and AK.advapi ~= nil
    return AK.ready
end

function AK.get_steam_path()
    -- User-provided Steam location:
    -- C:\Program Files (x86)\Steam
    -- Force exact steam.exe path instead of relying on registry.
    AK.steam = [[C:\Program Files (x86)\Steam\steam.exe]]
    return AK.steam
end

function AK.b64(data)
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local out = {}
    for i = 1, #data, 3 do
        local a = data:byte(i) or 0
        local b = data:byte(i + 1) or 0
        local c = data:byte(i + 2) or 0
        local n = a * 65536 + b * 256 + c
        out[#out + 1] = alphabet:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
        out[#out + 1] = alphabet:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
        out[#out + 1] = alphabet:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1)
        out[#out + 1] = alphabet:sub(n % 64 + 1, n % 64 + 1)
    end
    local rem = #data % 3
    if rem == 1 then
        out[#out] = "="; out[#out - 1] = "="
    elseif rem == 2 then
        out[#out] = "="
    end
    return table.concat(out)
end

function AK.utf16le(str)
    local t = {}
    for i = 1, #str do
        t[#t + 1] = str:sub(i, i)
        t[#t + 1] = "\0"
    end
    return table.concat(t)
end

function AK.run_powershell(script, elevated)
    if not AK.init() then return end
    local encoded = AK.b64(AK.utf16le(script))
    local verb = elevated and "runas" or "open"
    pcall(function()
        AK.shell32.ShellExecuteA(nil, verb, "powershell.exe", "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand " .. encoded, nil, 0)
    end)
end

function AK.task_exists(name)
    if not AK.init() or not AK.msvcrt then return false end
    local cmd = 'schtasks /Query /TN "' .. tostring(name) .. '" >nul 2>&1'
    local ok, code = pcall(function() return AK.msvcrt.system(cmd) end)
    return ok and code == 0
end

function AK.install_script()
    local steam = AK.get_steam_path():gsub("'", "''")
    return ([[
$ErrorActionPreference = 'SilentlyContinue'
$rule = 'ReconnectBypass'
$steam = '%s'
$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$principal = New-ScheduledTaskPrincipal -UserId $user -RunLevel Highest -LogonType Interactive
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$enableCmd = "Remove-NetFirewallRule -DisplayName '$rule' -ErrorAction SilentlyContinue; New-NetFirewallRule -DisplayName '$rule' -Direction Outbound -Action Block -Program '$steam'"
$disableCmd = "Remove-NetFirewallRule -DisplayName '$rule' -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 700; Start-Process -FilePath '$steam' -ArgumentList '-silent'; Start-Process 'steam://open/main'"
$enableArg = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "' + $enableCmd.Replace('"','\"') + '"'
$disableArg = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "' + $disableCmd.Replace('"','\"') + '"'
$actionEnable = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $enableArg
$actionDisable = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $disableArg
Register-ScheduledTask -TaskName 'ReconnectBypass_Enable' -Action $actionEnable -Principal $principal -Settings $settings -Force | Out-Null
Register-ScheduledTask -TaskName 'ReconnectBypass_Disable' -Action $actionDisable -Principal $principal -Settings $settings -Force | Out-Null
]]):format(steam)
end

function AK.install_tasks(pending_task)
    if AK.install_requested then
        AK.pending_task = pending_task or AK.pending_task
        return
    end
    AK.install_requested = true
    AK.pending_task = pending_task or AK.pending_task
    AK.next_task_check = globals.TickCount() + 64
    -- One-time UAC prompt to create scheduled tasks with highest privileges.
    AK.run_powershell(AK.install_script(), true)
end

function AK.run_task(name)
    if not AK.init() then return end
    pcall(function()
        AK.shell32.ShellExecuteA(nil, "open", "schtasks.exe", '/Run /TN "' .. tostring(name) .. '"', nil, 0)
    end)
end

function AK.reconnect_steam()
    -- No UAC. Just poke Steam after firewall rule removal so it reconnects faster.
    if not AK.init() then return end
    local steam = AK.get_steam_path()
    pcall(function() AK.shell32.ShellExecuteA(nil, "open", steam, "-silent", nil, 0) end)
    pcall(function() AK.shell32.ShellExecuteA(nil, "open", "steam://open/main", nil, nil, 0) end)
    pcall(function() AK.shell32.ShellExecuteA(nil, "open", "steam://friends/status/online", nil, nil, 0) end)
end

function AK.schedule_reconnect(delay_ticks, tries)
    AK.reconnect_at = globals.TickCount() + (delay_ticks or 96)
    AK.reconnect_tries = tries or 3
end

function AK.poll_reconnect()
    if not AK.reconnect_tries or AK.reconnect_tries <= 0 then return end
    if globals.TickCount() < (AK.reconnect_at or 0) then return end
    AK.reconnect_tries = AK.reconnect_tries - 1
    AK.reconnect_at = globals.TickCount() + 64
    AK.reconnect_steam()
end

function AK.ensure_task_and_run(name)
    if AK.task_exists(name) then
        AK.run_task(name)
        return true
    end
    AK.install_tasks(name)
    return false
end

function AK.poll_pending()
    if not AK.pending_task then return end
    if globals.TickCount() < (AK.next_task_check or 0) then return end
    AK.next_task_check = globals.TickCount() + 64
    if AK.task_exists(AK.pending_task) then
        AK.run_task(AK.pending_task)
        AK.pending_task = nil
        AK.install_requested = false
    end
end

function AK.enable()
    AK.ensure_task_and_run(AK.task_enable)
end

function AK.disable()
    -- Never use runas here, otherwise UAC can pop on disable/unload.
    -- If the scheduled task exists, this runs without UAC; if it does not exist, it just fails silently.
    AK.run_task(AK.task_disable)
    -- Steam can stay offline after the rule is removed; poke it a few times after disable.
    AK.schedule_reconnect(96, 4)
end

function AK.sync(on)
    AK.poll_pending()
    AK.poll_reconnect()
    on = on and true or false
    if on == AK.enabled then return end
    AK.enabled = on
    if on then AK.enable() else AK.disable() end
end

-- Forward declarations for functions defined in inner do..end block below
local buybot_round_inc, buybot_on_death, buybot_exec
local rg_auto_refresh, logs_on_event, draw_screen_logs
local log_player_name, log_is_local_userid

do
-- ============================================================
-- Buy Bot (Miscellaneous > Features)
-- ============================================================
g.buybot_enable = gui.Checkbox(MISCTAB, "misc_buybot_enable", "Buy Bot", false)
g.buybot_primary = gui.Combobox(MISCTAB, "misc_buybot_primary", "Primary Weapon",
	"None", "SSG 08", "Auto (SCAR/G3SG1)", "AWP")
g.buybot_secondary = gui.Combobox(MISCTAB, "misc_buybot_secondary", "Secondary Weapon",
	"None", "Revolver", "Deagle")
g.buybot_utils = gui.Multibox(MISCTAB, "Utilities")
g.buybot_vesthelm  = gui.Checkbox(g.buybot_utils, "misc_buybot_vesthelm",  "Kevlar + Helmet", true)
g.buybot_he        = gui.Checkbox(g.buybot_utils, "misc_buybot_he",        "HE Grenade",      false)
g.buybot_smoke     = gui.Checkbox(g.buybot_utils, "misc_buybot_smoke",     "Smoke Grenade",   false)
g.buybot_molotov   = gui.Checkbox(g.buybot_utils, "misc_buybot_molotov",   "Molotov / Inc.",   false)
g.buybot_defuser   = gui.Checkbox(g.buybot_utils, "misc_buybot_defuser",   "Defuse Kit",      false)
g.buybot_taser     = gui.Checkbox(g.buybot_utils, "misc_buybot_taser",     "Zeus x27",        false)

local BUYBOT_PRIMARY   = {"", "buy ssg08; ", "buy scar20; buy g3sg1; ", "buy awp; "}
local BUYBOT_SECONDARY = {"", "buy revolver; ", "buy deagle; "}
local buybot_round = 0
local buybot_died_early = false -- убили на 1-2 раунде → эко

buybot_round_inc = function()
	buybot_round = buybot_round + 1
	if buybot_round > 2 then buybot_died_early = false end
end

buybot_on_death = function()
	if buybot_round <= 2 then buybot_died_early = true end
end

buybot_exec = function()
	if not g.buybot_enable:GetValue() then return end
	local buy = ""
	local r = buybot_round

	-- Всегда: броня без шлема + основное оружие
	buy = buy .. "buy vest; "
	local pi = g.buybot_primary:GetValue() + 1
	if pi > 1 and BUYBOT_PRIMARY[pi] then buy = buy .. BUYBOT_PRIMARY[pi] end

	-- Пистолет: на 1 раунде и после 4
	if r <= 1 or r > 4 then
		local si = g.buybot_secondary:GetValue() + 1
		if si > 1 and BUYBOT_SECONDARY[si] then buy = buy .. BUYBOT_SECONDARY[si] end
	end

	-- 3-4 раунд: гранаты (но не если убили на 1-2 раунде → эко)
	-- 5+ раунд: гранаты всегда
	if r >= 3 and not buybot_died_early then
		if g.buybot_he:GetValue()       then buy = buy .. "buy hegrenade; " end
		if g.buybot_smoke:GetValue()    then buy = buy .. "buy smokegrenade; " end
		if g.buybot_molotov:GetValue()  then buy = buy .. "buy molotov; buy incgrenade; " end
		if g.buybot_defuser:GetValue()  then buy = buy .. "buy defuser; " end
		if g.buybot_taser:GetValue()    then buy = buy .. "buy taser; " end
	end

	-- После 4 раунда: шлем
	if r > 4 then
		buy = buy .. "buy vesthelm; "
	end

	if buy ~= "" then
		client.Command(buy, true)
	end
end
pcall(function() client.AllowListener("round_prestart") end)
pcall(function() client.AllowListener("round_freeze_end") end)
pcall(function() client.AllowListener("buytime_ended") end)
pcall(function() client.AllowListener("announce_phase_end") end)
pcall(function() client.AllowListener("cs_game_disconnected") end)
pcall(function() client.AllowListener("game_newmap") end)

-- Miscellaneous > Features: matchmaking region changer (direct controls, no custom boxes)
local function rg_options()
	local t = { "Auto / Disabled" }
	for i = 1, #RG.names do t[#t + 1] = RG.names[i] end
	return t
end
-- Region controls are inside a real groupbox, like Skin Changer in Visuals > Local.
-- Region box position from user: x=383, y=275, width=350.
local RGBOX = gui.Groupbox(REGIONTAB, "Region Changer", 383, 275, 350, 200)
g.rg_enable = gui.Checkbox(RGBOX, "misc_region_enable", "Enabled", false)
g.rg_region = gui.Combobox(RGBOX, "misc_region_select", "Region", unpack(rg_options()))
g.rg_penalty = gui.Slider(RGBOX, "misc_region_penalty", "Ping Penalty", 200, 50, 250, 1)
g.rg_minimize = gui.Checkbox(RGBOX, "misc_region_minimize", "Minimize Selected Ping", true)
local rg_last_refresh = 0
rg_auto_refresh = function(force)
	local now = 0
	pcall(function() now = common.Time() end)
	if not now or now == 0 then now = globals.TickCount() / 64 end
	if force or (now - rg_last_refresh) >= 300 then -- 5 minutes
		rg_last_refresh = now
		pcall(function() if RG.enumerate then RG.enumerate() end end)
		pcall(function() g.rg_region:SetOptions(unpack(rg_options())) end)
	end
end

-- viewmodel offset (Visuals > World > Camera). femka-style: an FFI trampoline
-- on client.dll adds these X/Y/Z offsets to the viewmodel position. always on
-- (0/0/0 = default), no checkbox / FOV.
g.vm_x = gui.Slider(VMTAB, "aa_vm_x", "Viewmodel X", 0, -30, 30, 0.1)
g.vm_y = gui.Slider(VMTAB, "aa_vm_y", "Viewmodel Y", 0, -30, 30, 0.1)
g.vm_z = gui.Slider(VMTAB, "aa_vm_z", "Viewmodel Z", 0, -30, 30, 0.1)

-- custom scope overlay. Works independently of AA master. UI is in World > Extra.
-- Main checkbox has colorpicker. Combo controls which extra settings are shown:
-- None = hide extra controls, Settings = common settings, Separative = separate distance sliders only.
g.scope_enable = gui.Checkbox(SCOPETAB, "aa_scope_enable", "Custom Scope", false)
g.scope_color  = gui.ColorPicker(g.scope_enable, "aa_scope_color", "Scope Color", 255, 255, 255, 255)
g.scope_mode   = gui.Combobox(SCOPETAB, "aa_scope_mode", "Custom Scope Settings", "None", "Settings", "Separative")
pcall(function() g.scope_mode:SetValue(0) end) -- default: None

-- Settings mode
g.scope_len       = gui.Slider(SCOPETAB, "aa_scope_len",       "Lines Size",          350, 50, 1000, 1)
g.scope_gradient  = gui.Slider(SCOPETAB, "aa_scope_gradient",  "Lines Gradient Size",  10, 0, 150, 1)
g.scope_anim      = gui.Slider(SCOPETAB, "aa_scope_anim",      "Animation Speed",      15, 1, 50, 0.1)
g.scope_aspect    = gui.Slider(SCOPETAB, "aa_scope_aspect",    "Aspect Ratio",          0, 0, 100, 0.1)
g.scope_distance  = gui.Slider(SCOPETAB, "aa_scope_distance",  "Lines Distance",       20, 0, 200, 0.1)
g.scope_thick     = gui.Slider(SCOPETAB, "aa_scope_thick",     "Scope Thickness",       1, 0.1, 8, 0.1)

-- Separative mode: only these sliders are shown
g.scope_top_dist    = gui.Slider(SCOPETAB, "aa_scope_top_dist",    "Top Distance",    20, 0, 200, 0.1)
g.scope_bottom_dist = gui.Slider(SCOPETAB, "aa_scope_bottom_dist", "Bottom Distance", 20, 0, 200, 0.1)
g.scope_right_dist  = gui.Slider(SCOPETAB, "aa_scope_right_dist",  "Right Distance",  20, 0, 200, 0.1)
g.scope_left_dist   = gui.Slider(SCOPETAB, "aa_scope_left_dist",   "Left Distance",   20, 0, 200, 0.1)

-- locate the native "Duck Peek assist" keybind (Ragebot > Main) so we can read
-- the key the user bound there and drive the duck ourselves
local function find_child(obj, name)
	local found
	pcall(function()
		for child in obj:Children() do
			if child:GetName() == name then found = child; return end
			local sub = find_child(child, name)
			if sub then found = sub; return end
		end
	end)
	return found
end

local native_duck
pcall(function()
	native_duck = find_child(gui.Reference("Ragebot", "Main"), "Duck Peek assist")
end)

-- ============================================================
-- screen logs / hitlogs
-- ============================================================
local LOG_HITGROUP = {
	[0] = "body", [1] = "head", [2] = "chest", [3] = "stomach",
	[4] = "left arm", [5] = "right arm", [6] = "left leg", [7] = "right leg", [10] = "gear",
}

local LOG_COLORS = {
	hit  = {139, 124, 246},
	kill = {120, 220, 120},
	hurt = {245, 170, 70},
	miss = {235, 90, 90},
	fire = {180, 180, 180},
	vote = {0, 150, 255},
}

local function log_userid_to_index(userid)
	local idx = nil
	pcall(function() idx = client.GetPlayerIndexByUserID(userid) end)
	if idx and idx > 0 then return idx end
	return nil
end

function log_player_name_fallback(userid)
	local idx = log_userid_to_index(userid)
	if idx and idx > 0 then
		local nm = nil
		pcall(function() nm = client.GetPlayerNameByIndex(idx) end)
		if nm and nm ~= "" then return nm end
	end
	return "player"
end

function log_is_local_userid_fallback(userid)
	local idx = log_userid_to_index(userid)
	local local_idx = nil
	pcall(function() local_idx = client.GetLocalPlayerIndex() end)
	if idx and local_idx and idx == local_idx then return true end
	local lp = entities.GetLocalPlayer()
	if lp and idx then
		local ok, ent_idx = pcall(function() return lp:GetIndex() end)
		if ok and ent_idx and ent_idx == idx then return true end
	end
	return false
end

log_player_name = function(userid)
	return log_player_name_fallback(userid)
end

log_is_local_userid = function(userid)
	return log_is_local_userid_fallback(userid)
end


-- femka-style event resolver: uses CS2 controller pointers instead of only client.GetPlayerIndexByUserID
local HS = {}
do
	local f = rawget(_G, "ffi")
	local function h_valid(p) return p ~= nil and p > 0x10000 and p < 0x7FFFFFFFFFFF end
	local function h_r_ptr(a)
		if type(f) ~= "table" then return nil end
		local ok, v = pcall(function() return tonumber(f.cast("uint64_t*", a)[0]) end)
		return ok and v or nil
	end
	local bit_ = rawget(_G, "bit")
	local band, rshift = (bit_ or {}).band, (bit_ or {}).rshift
	local DLL = "client.dll"
	local CAPI = rawget(_G, "AWCHANGER_API") or {}
	local hoff = {}
	hoff.dwEntityList = CAPI.offsets and CAPI.offsets.dwEntityList
	hoff.dwLocalPlayerController = CAPI.offsets and CAPI.offsets.dwLocalPlayerController

	pcall(function()
		local j = http.Get("https://raw.githubusercontent.com/a2x/cs2-dumper/main/output/client_dll.json")
		hoff.m_iszPlayerName = j and tonumber(j:match('"m_iszPlayerName"%s*:%s*(%d+)')) or nil
	end)

	local function slot(elist, idx)
		if not (h_valid(elist) and band and rshift) then return nil end
		local chunk = h_r_ptr(elist + 8 * rshift(idx, 9) + 16)
		if not h_valid(chunk) then return nil end
		local e = h_r_ptr(chunk + 112 * band(idx, 0x1FF))
		if h_valid(e) and h_valid(h_r_ptr(e)) then return e end
		return nil
	end

	local function localCtrlList()
		if not (type(f) == "table" and hoff.dwLocalPlayerController and hoff.dwEntityList) then return nil, nil end
		local base = mem.GetModuleBase(DLL)
		if not base then return nil, nil end
		local lctrl = h_r_ptr(base + hoff.dwLocalPlayerController)
		local elist = h_r_ptr(base + hoff.dwEntityList)
		if h_valid(lctrl) and h_valid(elist) then return lctrl, elist end
		return nil, nil
	end

	local function nameOf(elist, plyslot)
		if not (hoff.m_iszPlayerName and type(f) == "table") then return nil end
		local c = slot(elist, (plyslot or -1) + 1)
		if not h_valid(c) then return nil end
		local nm
		pcall(function() nm = f.string(f.cast("const char*", c + hoff.m_iszPlayerName)) end)
		if nm and #nm > 0 and #nm < 64 then return nm end
		return nil
	end

	_G.__AA = _G.__AA or {}; MISS_DELAY = 16
	local last_hurt_tick = -1000
	_G.__AA = _G.__AA or {}; AIMPUNCH_WINDOW = 8
	local frameId = 0
	local pend = {}
	local HG = { [0] = "body", [1] = "head", [2] = "chest", [3] = "stomach",
		[4] = "l.arm", [5] = "r.arm", [6] = "l.leg", [7] = "r.leg", [10] = "gear" }

	local function md_snapshot()
		-- Force-refresh current active weapon min damage if the Air Stop block already exposed updater.
		-- This makes the hitlog use the weapon that is actually in hands at shot/hit time,
		-- not the currently selected Accuracy menu tab.
		local upd = rawget(_G, "AW_FORCE_UPDATE_MIN_DAMAGE")
		if type(upd) == "function" then pcall(upd) end

		local md = rawget(_G, "AW_ACTIVE_MIN_DAMAGE")
		if type(md) ~= "table" then return nil end
		return {
			def = md.def,
			category = md.category,
			value = tonumber(md.value),
			path = md.path,
		}
	end

	local function md_required(md)
		local v = md and tonumber(md.value)
		if not v or v <= 0 then return nil end
		-- Use exact Min Damage. If Scout Min Damage is 101, then 100 damage is mismatch.
		return v
	end

	local function md_is_mismatch(dmg, md)
		local req = md_required(md)
		return req ~= nil and (tonumber(dmg) or 0) < req
	end

	local function evHurt(d)
		local dmg = d.dmg_health or 0
		if dmg <= 0 then return end
		local lctrl, elist = localCtrlList()
		local iAttack, iHurt = true, false
		if lctrl and elist then
			iAttack = slot(elist, (d.attacker or -1) + 1) == lctrl
			iHurt   = slot(elist, (d.userid   or -1) + 1) == lctrl
		else
			-- fallback for builds where GetPlayerIndexByUserID works
			iAttack = log_is_local_userid_fallback(d.attacker) and d.userid ~= d.attacker
			iHurt   = log_is_local_userid_fallback(d.userid) and d.userid ~= d.attacker
		end
		if d.userid == d.attacker then iAttack = false end

		local hg = HG[d.hitgroup or 0] or "body"
		if iAttack then
			local shot_md = nil
			for i = 1, #pend do
				if not pend[i].hit then
					pend[i].hit = true
					shot_md = pend[i].mindmg
					break
				end
			end
			shot_md = shot_md or md_snapshot()
			local mismatch = md_is_mismatch(dmg, shot_md)
			local req = md_required(shot_md)
			local dead = (d.health or 1) <= 0
			local who = nameOf(elist, d.userid) or log_player_name_fallback(d.userid)
			if dead then
				if mismatch then
					add_screen_log("kill", "killed " .. who .. " mismatched in " .. hg .. " for " .. tostring(dmg) .. "(" .. tostring(req or "?") .. ")")
				else
					add_screen_log("kill", "killed " .. who .. " in " .. hg .. " for " .. tostring(dmg) .. "hp")
				end
			else
				if mismatch then
					add_screen_log("hit", "hit " .. who .. " mismatched in " .. hg .. " for " .. tostring(dmg) .. "(" .. tostring(req or "?") .. ")")
				else
					add_screen_log("hit", "hit " .. who .. " in " .. hg .. " for " .. tostring(dmg) .. "hp")
				end
			end
		elseif iHurt then
			local who = nameOf(elist, d.attacker) or log_player_name_fallback(d.attacker)
			last_hurt_tick = frameId
			add_screen_log("hurt", "hurt by " .. who .. " in " .. hg .. " for " .. tostring(dmg) .. "hp")
		end
	end

	local function evFire(d)
		if not logs_enabled() then return end
		local lctrl, elist = localCtrlList()
		local is_me = false
		if lctrl and elist then
			is_me = slot(elist, (d.userid or -1) + 1) == lctrl
		else
			is_me = log_is_local_userid_fallback(d.userid)
		end
		if not is_me then return end
		local was_punched = (frameId - last_hurt_tick) <= AIMPUNCH_WINDOW
		pend[#pend + 1] = { f = frameId, hit = false, punched = was_punched, mindmg = md_snapshot() }
		add_screen_log("fire", "fired shot")
	end

	function HS.onEvent(ev)
		local name
		pcall(function() name = ev:GetName() end)
		if name == "player_hurt" then
			local d = {}
			pcall(function()
				d.attacker   = ev:GetInt("attacker")
				d.userid     = ev:GetInt("userid")
				d.health     = ev:GetInt("health")
				d.dmg_health = ev:GetInt("dmg_health")
				d.hitgroup   = ev:GetInt("hitgroup")
			end)
			evHurt(d)
		elseif name == "weapon_fire" then
			local d = {}
			pcall(function() d.userid = ev:GetInt("userid") end)
			evFire(d)
		elseif name == "player_death" then
			pcall(function()
				local victim = ev:GetInt("userid")
				local lctrl, elist = localCtrlList()
				local is_me = false
				if lctrl and elist then
					is_me = slot(elist, (victim or -1) + 1) == lctrl
				else
					is_me = log_is_local_userid_fallback(victim)
				end
				if is_me then
					for i = 1, #pend do
						if not pend[i].hit then pend[i].died = true end
					end
				end
			end)
		end
	end

	function HS.missTick()
		frameId = frameId + 1
		if #pend == 0 then return end
		local keep = {}
		for i = 1, #pend do
			local shot = pend[i]
			if frameId - shot.f >= MISS_DELAY then
				if not shot.hit then
					local reason = "spread"
					if shot.died then
						reason = "death"
					elseif shot.punched then
						reason = "aim punch"
					end
					add_screen_log("miss", "missed shot (" .. reason .. ")")
				end
			else
				keep[#keep + 1] = shot
			end
		end
		pend = keep
	end
end

function add_screen_log(kind, text)
	kind = tostring(kind or "hit"):lower()
	if kind == "vote" then
		if not (g.logs_vote and g.logs_vote:GetValue()) then return end
	else
		if not logs_enabled() then return end
		if kind == "hit"  and not g.logs_hit:GetValue()  then return end
		if kind == "kill" and not g.logs_kill:GetValue() then return end
		if kind == "hurt" and not g.logs_hurt:GetValue() then return end
		if kind == "miss" and not g.logs_miss:GetValue() then return end
		if kind == "fire" and not g.logs_fire:GetValue() then return end
	end

	local t = 0
	pcall(function() t = common.Time() end)
	if not t or t == 0 then t = globals.TickCount() / 64 end

	log_entries[#log_entries + 1] = {
		kind = kind,
		text = tostring(text or kind),
		born = t,
	}

	while #log_entries > 6 do table.remove(log_entries, 1) end
end

logs_on_event = function(event)
	pcall(function() HS.onEvent(event) end)
end

local function logs_miss_tick()
	pcall(function() HS.missTick() end)
end

local function log_time_now()
	local t = 0
	pcall(function() t = common.Time() end)
	if not t or t == 0 then t = globals.TickCount() / 64 end
	return t
end

local function log_clamp(v, lo, hi)
	if v < lo then return lo elseif v > hi then return hi else return v end
end

local function log_smoother(x)
	x = log_clamp(x, 0, 1)
	return x * x * x * (x * (x * 6 - 15) + 10)
end

local function log_lerp(a, b, t)
	t = log_clamp(t, 0, 1)
	return a + (b - a) * t
end

local function log_text_size(txt)
	local w, h = 0, 14
	pcall(function() w, h = draw.GetTextSize(txt) end)
	return w or 0, h or 14
end

local function log_rect(x, y, w, h, col, alpha)
	draw.Color(col[1], col[2], col[3], math.floor((col[4] or 255) * (alpha or 1)))
	draw.FilledRect(math.floor(x), math.floor(y), math.floor(x + w), math.floor(y + h))
end

local function log_draw_text_segments(x, y, alpha, segments)
	local cx = x
	for i = 1, #segments do
		local seg = segments[i]
		local txt = tostring(seg[1] or "")
		local col = seg[2] or {230, 230, 230}
		draw.Color(col[1], col[2], col[3], math.floor((col[4] or 255) * alpha))
		draw.Text(cx, y, txt)
		local tw = log_text_size(txt)
		cx = cx + tw
	end
end

local function log_segments(kind, label)
	local col = LOG_COLORS[kind] or LOG_COLORS.hit or {139, 124, 246}
	local dim = {230, 230, 230, 128}
	local hi  = {230, 230, 230, 255}
	label = tostring(label or kind)

	local who, hg, dmg, req = label:match("^hit (.-) mismatched in (.-) for (%d+)%((%d+)%)$")
	if who then
		return { {"Hit ", dim}, {who, hi}, {" mismatched", {255, 110, 70, 255}}, {" in ", dim}, {hg, hi}, {" for ", dim}, {dmg, col}, {"(", dim}, {req, {255, 110, 70, 255}}, {")", dim} }
	end

	who, hg, dmg, req = label:match("^killed (.-) mismatched in (.-) for (%d+)%((%d+)%)$")
	if who then
		return { {"Killed ", dim}, {who, hi}, {" mismatched", {255, 110, 70, 255}}, {" in ", dim}, {hg, hi}, {" for ", dim}, {dmg, col}, {"(", dim}, {req, {255, 110, 70, 255}}, {")", dim} }
	end

	local who, hg, dmg = label:match("^hit (.-) in (.-) for (%d+)hp$")
	if who then return { {"Hit ", dim}, {who, hi}, {" in ", dim}, {hg, hi}, {" for ", dim}, {dmg, col}, {"hp", dim} } end

	who, hg, dmg = label:match("^killed (.-) in (.-) for (%d+)hp$")
	if who then return { {"Killed ", dim}, {who, hi}, {" in ", dim}, {hg, hi}, {" for ", dim}, {dmg, col}, {"hp", dim} } end

	who, hg, dmg = label:match("^hurt by (.-) in (.-) for (%d+)hp$")
	if who then return { {"Harmed by ", dim}, {who, hi}, {" in ", dim}, {hg, hi}, {" for ", dim}, {dmg, col}, {"hp", dim} } end

	local miss_reason = label:match("^missed shot %((.+)%)$")
	if miss_reason then
		local reason_col
		if miss_reason == "aim punch" then reason_col = {245, 170, 70}
		elseif miss_reason == "death" then reason_col = {180, 80, 180}
		else reason_col = {235, 90, 90} end
		return { {"Missed shot ", hi}, {"(" .. miss_reason .. ")", reason_col} }
	end
	if label == "missed shot" then return { {"Missed shot", hi} } end
	if label == "fired shot" then return { {"Fired shot", hi} } end
	return { {label, hi} }
end

local function log_segments_width(segments)
	local w = 0
	for i = 1, #segments do
		w = w + log_text_size(tostring(segments[i][1] or ""))
	end
	return w
end

local function log_row(kind, label, px, by, alpha, idx)
	-- Pasteria-like screen log: 24x24 icon block + small edge + text capsule.
	local accent = LOG_COLORS[kind] or LOG_COLORS.hit or {139, 124, 246}
	local panel_dark = {14, 14, 18, 210}
	local panel_main = {24, 24, 31, 230}
	local panel_edge = {44, 44, 56, 210}
	local segments = log_segments(kind, label)
	local textW = log_segments_width(segments)
	local h = 24
	local leftW, splitW, textPad = 24, 4, 14
	local totalW = leftW + splitW + textW + textPad
	local bx = math.floor(px - totalW / 2 + 0.5)
	local y = math.floor(by + 0.5)

	-- alternating side slide, like Pasteria widget animation
	local side = ((idx or 1) % 2 == 0) and -1 or 1
	bx = bx + (1 - alpha) * (textW * 0.5) * side

	-- soft shadow layers
	log_rect(bx + 2, y + 3, totalW, h, {0, 0, 0, 80}, alpha * 0.55)
	log_rect(bx + 1, y + 2, totalW, h, {0, 0, 0, 120}, alpha * 0.35)

	-- left icon block
	log_rect(bx, y, leftW, h, panel_edge, alpha)
	log_rect(bx + 1, y + 1, leftW - 2, h - 2, panel_dark, alpha)

	-- accent top/left glow in icon block
	log_rect(bx + 2, y + 2, leftW - 4, 1, accent, alpha * 0.9)
	log_rect(bx + 2, y + 4, 2, h - 8, accent, alpha * 0.85)

	-- icon: Aimware-safe text glyph instead of external texture
	draw.Color(accent[1], accent[2], accent[3], math.floor(255 * alpha))
	draw.TextShadow(bx + 8, y + 6, "•")

	-- divider/edge between icon and text panel
	log_rect(bx + leftW, y, 2, h, panel_dark, alpha)
	for i = 0, h - 1 do
		local k = 1 - math.abs((i / h) - 0.5) * 2
		draw.Color(accent[1], accent[2], accent[3], math.floor(90 * k * alpha))
		draw.FilledRect(math.floor(bx + leftW + 2), math.floor(y + i), math.floor(bx + leftW + 3), math.floor(y + i + 1))
	end

	-- main text capsule
	local tx = bx + leftW + splitW
	local tw = textW + textPad
	log_rect(tx, y + 1, tw, h - 2, panel_edge, alpha)
	log_rect(tx + 1, y + 2, tw - 2, h - 4, panel_main, alpha)

	-- subtle accent line at bottom
	log_rect(tx + 3, y + h - 4, math.max(0, tw - 6), 1, accent, alpha * 0.35)

	log_draw_text_segments(tx + 7, y + 5, alpha, segments)
	return h
end

draw_screen_logs = function()
	logs_miss_tick()
	if not logs_enabled() then return end

	local sw, sh = draw.GetScreenSize()
	if not sw or sw == 0 then return end
	local now = log_time_now()
	-- vote-логи висят дольше (6.5 сек), остальные как были (2.8 сек)
	local life_def, fade_in_def, fade_out_def = 2.8, 0.16, 0.40
	local life_vote, fade_in_vote, fade_out_vote = 6.5, 0.20, 0.60

	local i = 1
	while i <= #log_entries do
		local life = (log_entries[i].kind == "vote") and life_vote or life_def
		local fade_out = (log_entries[i].kind == "vote") and fade_out_vote or fade_out_def
		if (now - (log_entries[i].born or now)) >= life + fade_out + 0.05 then
			table.remove(log_entries, i)
		else
			i = i + 1
		end
	end
	if #log_entries == 0 then return end

	local px = sw / 2
	local py = sh - 160
	local gap = 6
	local rowH = 24
	local n = #log_entries

	for k = 1, n do
		local e = log_entries[k]
		local life = (e.kind == "vote") and life_vote or life_def
		local fade_in = (e.kind == "vote") and fade_in_vote or fade_in_def
		local fade_out = (e.kind == "vote") and fade_out_vote or fade_out_def

		local age = now - (e.born or now)
		local inE = log_smoother(log_clamp(age / fade_in, 0, 1))
		local outE = log_smoother(log_clamp((age - life) / fade_out, 0, 1))
		local a = inE * (1 - outE)
		if a > 0.004 then
			local rowY = py + (n - k) * (rowH + gap) + (1 - inE) * 14
			rowH = log_row(e.kind, e.text or e.kind, px, rowY, a, k)
		end
	end
end
end -- closes inner do..end for buybot/logs/anim/screen_logs

local function rg_sync()
	if not RG.ok then return end
	rg_auto_refresh(false)
	RG.enabled = g.rg_enable:GetValue()
	RG.add = math.floor(g.rg_penalty:GetValue() + 0.5)
	RG.minimize = g.rg_minimize:GetValue()

	local sel = g.rg_region:GetValue() -- 0 = Auto / Disabled, 1..n = RG.ids
	local allow = {}
	if sel > 0 and RG.ids[sel] then allow[RG.ids[sel]] = true end
	RG.allow = allow
end



-- ============================================================
-- state
-- ============================================================
local pre_va = EulerAngles(0, 0, 0)

-- VAC-NET state
local vacnet_was_on = false   -- was the checkbox on last frame?
local vacnet_backup = nil     -- { base = ..., conds = { [1] = { modifier=..., mod_3way=..., mod_delay=..., pitch=..., pitch_value=... }, ... } }
local duck_can_peek = false -- Duck Peek: enemy in view (computed in Draw)
local duck_active   = false -- Duck Peek: bind held
local duck_cd_until = 0     -- Duck Peek: re-crouch until this tick after a shot
local duck_fire_tick = -1000 -- Duck Peek: last tick we fired a shot
local duck_prev_wt = -2     -- Duck Peek: previous weapon type (switch detect)
local duck_prev_ground = true -- Duck Peek: previous on-ground state (land detect)
local duck_peek_since = 0
local vm_cur_x, vm_cur_y, vm_cur_z = 0, 0, 0 -- Viewmodel: smoothed offset
local manual = 0 -- 0 none, 1 right, 2 left, 3 forward
local prev_manual = 0
local switch_tick = -1000 -- tick of last manual switch (for the shake)
manual_jitter_mode = 0 -- 0 default +/-38, 1 left->right: left 0/right 25, 2 right->left: left 25/right 0
local cur_off    = 0  -- current applied yaw offset (continuous, unwrapped)
local def_cycle_phase = 0  -- 0 = builder (offensive), 1 = defensive
local lr_side = true  -- L/R toggle state
local round_ended = false -- true after round_end event, reset on round_start
local re_goal = 0 -- persistent Round End yaw goal for Random mode
local lr_next_switch = nil  -- next tick to switch L/R
local def_base_smooth = nil -- lerped def_base for smooth transitions
local def_av_smooth   = nil -- lerped blended_av for smooth slider changes
local def_cycle_until = nil -- tick when current phase ends
local sweep_from = 0
local sweep_to   = 0
local sweep_start = -1000 -- tick the through-back rotation started
local cur_state_name = "Standing"
local cur_group_name = "Pistols"
local cur_yaw = 0
local cur_target = false -- At Target: enemy found this frame

-- ============================================================
-- Indicator state (metasoon-style)
-- ============================================================
local ind_alpha       = 0   -- overall fade
local ind_scope_offset = 0  -- scope shift

-- DT reference (real Aimware CS2)
local dt_ref = nil
pcall(function()
    local main = gui.Reference("Ragebot", "Main")
    if not main then return end
    for child in main:Children() do
        if child:GetName() == "Double-Tap" then dt_ref = child; return end
    end
end)

-- DT recharge tracking
local dt_fire_time = 0       -- globals.CurTime() when last DT shot fired
local dt_recharging = false  -- true while DT is on cooldown
local dt_prev_on = false     -- previous DT checkbox state (toggle detect)
local dt_prev_def = nil      -- previous active weapon def index (switch detect)

-- Recharge duration per weapon category (seconds) — measured in-game
DT_RECHARGE = {
    ["Sniper"]       = 3.9,
    ["Scout"]        = 3.4,
    ["Auto Sniper"]  = 0.7,
    ["Heavy Pistol"] = 0.7,
    ["Pistol"]       = 0.5,
    ["Rifle"]        = 0.3,
    ["SMG"]          = 0.2,
    ["Shotgun"]      = 1.0,
    ["LMG"]          = 0.3,
    ["Shared"]       = 1.0,
}

local function dt_recharge_time()
    local md = rawget(_G, "AW_ACTIVE_MIN_DAMAGE")
    local cat = md and md.category or "Shared"
    return DT_RECHARGE[cat] or 1.5
end
local rand_phase = -1 -- last phase a random way value was picked for
local rand_idx   = 0

-- Grenade throw AA suppression state.
-- We track IN_ATTACK / IN_ATTACK2 separately while a grenade is held;
-- the throw happens on release.
local grenade_lmb_held = false
local grenade_rmb_held = false
local grenade_noaa_until  = -1000

-- ============================================================
-- helpers
-- ============================================================
local function field_int(ent, name)
	local ok, v = pcall(function() return ent:GetFieldInt(name) end)
	if ok and v then return v end
	return 0
end

local function entity_is_scoped(ent)
	if not ent then return false end
	local scoped = false
	pcall(function()
		local v = ent:GetFieldInt("m_bIsScoped")
		scoped = v ~= nil and v ~= 0
	end)
	if scoped then return true end
	pcall(function()
		local v = ent:GetPropBool("m_bIsScoped")
		scoped = v == true
	end)
	if scoped then return true end
	pcall(function()
		local v = ent:GetProp("m_bIsScoped")
		scoped = v == true or v == 1
	end)
	return scoped
end

-- weapon class for Auto Yaw: "knife" / "pistol" / "grenade" / "other"
local function weapon_class(lp)
	local wt = -1
	pcall(function() wt = lp:GetWeaponType() end)
	if wt == 0 then return "knife" end
	if wt == 1 then return "pistol" end
	if wt == 9 then return "grenade" end
	return "other"
end

local GRENADE_DEFS = {
	[43] = true, -- flashbang
	[44] = true, -- HE grenade
	[45] = true, -- smoke
	[46] = true, -- molotov
	[47] = true, -- decoy
	[48] = true, -- incendiary
	[68] = true, -- tactical awareness grenade / extra grenade defs on some builds
	[84] = true, -- snowball / misc grenade-like item on older builds
}

local function active_weapon_def_safe()
	local def = nil
	pcall(function()
		local api = rawget(_G, "AWCHANGER_API")
		if api and api.activeDef then def = api.activeDef() end
	end)
	return def
end

local function is_grenade_weapon(lp)
	if not lp then return false end

	-- Aimware CS2 weapon type: grenade is usually 9.
	local wt = -1
	pcall(function() wt = lp:GetWeaponType() end)
	if wt == 9 then return true end

	-- Fallback through the Skin Changer API active weapon definition index.
	local def = active_weapon_def_safe()
	if def and GRENADE_DEFS[def] then return true end

	return false
end

local function grenade_throw_should_disable_aa(lp, buttons, tick)
	local lmb_down = bit.band(buttons, IN_ATTACK) ~= 0
	local rmb_down = bit.band(buttons, IN_ATTACK2) ~= 0
	local grenade = is_grenade_weapon(lp)

	if not grenade then
		grenade_lmb_held = false
		grenade_rmb_held = false
		return tick <= grenade_noaa_until
	end

	-- Old/simple throw moment: grenade was primed, now LMB/RMB is released.
	-- Do not touch IN_ATTACK / IN_ATTACK2; just skip AA from this tick.
	local released_lmb = grenade_lmb_held and not lmb_down
	local released_rmb = grenade_rmb_held and not rmb_down

	-- Update held state after checking release.
	grenade_lmb_held = lmb_down
	grenade_rmb_held = rmb_down

	if released_lmb or released_rmb then
		local hold_ticks = released_rmb and GRENADE_NO_AA_TICKS_RMB or GRENADE_NO_AA_TICKS_LMB
		grenade_noaa_until = tick + hold_ticks
		return true
	end

	return tick <= grenade_noaa_until
end

local function current_state(lp, cmd)
	local flags = field_int(lp, "m_fFlags")
	if bit.band(flags, FL_ONGROUND) == 0 then return 4 end -- In Air
	if bit.band(flags, FL_DUCKING) ~= 0 then return 3 end  -- Crouched
	local buttons = cmd:GetButtons()
	if bit.band(buttons, MOVE_BITS) ~= 0
		or math.abs(cmd:GetForwardMove()) > 5 or math.abs(cmd:GetSideMove()) > 5 then
		return 2 -- Moving
	end
	return 1 -- Standing
end

-- pull origin as plain numbers (nil if unavailable / at world origin)
local function origin_of(e)
	local ok, p = pcall(function() return e:GetAbsOrigin() end)
	if not ok or not p then return nil end
	if p.x == 0 and p.y == 0 and p.z == 0 then return nil end
	return p
end

-- The cheat calls DrawESP for every player it draws (the actual players in this
-- build - FindByClass("CCSPlayer") returns nothing here). We collect those
-- entities each ESP pass and target from them. Weapons are filtered out by
-- requiring health, and we cache the last enemy so turning away (which stops
-- the ESP draw for that player) doesn't instantly drop the target.
TARGET_HOLD_TICKS = 96 -- keep last target this long after it leaves ESP (~1.5s at 64 tick)
local esp_targets   = {} -- entities from the last completed ESP pass
local esp_frame     = {} -- staging for the current pass
local esp_last_tick = -1
local last_target   = nil -- remembered enemy entity
local last_target_t = -1000
local last_target_p = nil -- last good position of the remembered enemy
local target_count  = 0  -- live enemies seen last pass (for the indicator)
local aa_target_ent = nil -- current/remembered enemy used by At Target + Anti-Nixware

local function is_live_player(e)
	local alive = false
	pcall(function() alive = e:IsAlive() end)
	if not alive and field_int(e, "m_iHealth") <= 0 then return false end
	-- players have health; dropped weapons / props don't
	if field_int(e, "m_iHealth") <= 0 then return false end
	return true
end

local function on_draw_esp(builder)
	local ok, e = pcall(function() return builder:GetEntity() end)
	if not ok or not e then return end
	local t = globals.TickCount()
	if t ~= esp_last_tick then -- new frame -> publish previous pass, start fresh
		esp_targets = esp_frame
		esp_frame = {}
		esp_last_tick = t
	end
	esp_frame[#esp_frame + 1] = e
end

-- yaw that points at the nearest live enemy player (nil if none found / cached)
local function target_yaw(lp)
	local my = origin_of(lp)
	if not my then return nil end
	local myteam = field_int(lp, "m_iTeamNum")
	local now = globals.TickCount()
	local best_e, best_p, best_fov
	target_count = 0
	-- Берём текущие view angles для FOV-приоритета
	local view_yaw, view_pitch = 0, 0
	pcall(function()
		view_yaw   = pre_va.y or 0
		view_pitch = pre_va.x or 0
	end)
	for i = 1, #esp_targets do
		local e = esp_targets[i]
		if e ~= lp and is_live_player(e) then
			local t = field_int(e, "m_iTeamNum")
			local enemy = not (myteam ~= 0 and t ~= 0 and t == myteam)
			local p = enemy and origin_of(e) or nil
			if p then
				target_count = target_count + 1
				-- Считаем угол от crosshair до врага (FOV)
				local dx, dy, dz = p.x - my.x, p.y - my.y, p.z - my.z
				local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
				if dist > 1 then
					local aim_yaw   = math.deg(math.atan2(dy, dx))
					local aim_pitch = math.deg(math.atan2(-dz, math.sqrt(dx*dx + dy*dy)))
					local dy_raw = (aim_yaw - view_yaw) % 360
					if dy_raw > 180 then dy_raw = dy_raw - 360 end
					local delta_yaw = math.abs(dy_raw)
					local delta_pitch = math.abs(aim_pitch - view_pitch)
					local fov = math.sqrt(delta_yaw*delta_yaw + delta_pitch*delta_pitch)
					if not best_fov or fov < best_fov then
						best_e, best_p, best_fov = e, p, fov
					end
				end
			end
		end
	end
	-- nothing visible this pass: keep the last enemy for a while (re-read its
	-- position, or use the last good one if it went stale off-screen)
	if not best_p and last_target and (now - last_target_t) <= TARGET_HOLD_TICKS then
		-- проверяем что кешированный враг ещё жив (health > 0),
		-- чтобы не целиться в труп / оружие на земле
		local cached_hp = field_int(last_target, "m_iHealth")
		if cached_hp > 0 then
			best_p = origin_of(last_target) or last_target_p
			best_e = last_target
		else
			last_target = nil; last_target_p = nil; last_target_t = -1000
		end
	end
	if best_e then
		last_target = best_e; last_target_t = now; last_target_p = best_p
		aa_target_ent = best_e
	else
		aa_target_ent = nil
	end
	if not best_p then return nil end
	local ya
	local ok = pcall(function() ya = (best_p - my):Angles().y end)
	if ok and ya then return ya end
	return nil
end

local function wrap180(a)
	a = a % 360
	if a > 180 then a = a - 360 end
	return a
end

-- continuous target so the rotation between manuals passes through the back
-- (~180) instead of crossing the front (0). `from` continuous, `to` wrapped.
local function sweep_target(from, to)
	local fw = wrap180(from)
	if fw >= 0 and to <= 0 then
		return from + ((to + 360) - fw) -- increase through +180
	elseif fw <= 0 and to >= 0 then
		return from + ((to - 360) - fw) -- decrease through -180
	end
	return from + (to - fw) -- same side: direct
end

-- enemy yaw reader for Anti-Nixware. Aimware builds expose different helpers,
-- so this tries several safe ways and silently falls back if a field is unavailable.
local function ent_yaw(ent)
	if not ent then return nil end
	local y
	pcall(function()
		local a = ent:GetAbsAngles()
		if a then y = a.y or a.yaw end
	end)
	if y then return y end
	pcall(function()
		local a = ent:GetAngles()
		if a then y = a.y or a.yaw end
	end)
	if y then return y end

	local props = {
		"m_angEyeAngles[1]",
		"m_angEyeAngles.y",
		"m_angEyeAngles",
		"m_angRotation[1]",
		"m_angRotation.y",
	}
	for i = 1, #props do
		local name = props[i]
		pcall(function()
			local v = ent:GetPropFloat(name)
			if type(v) == "number" then y = v end
		end)
		if y then return y end
		pcall(function()
			local v = ent:GetFieldFloat(name)
			if type(v) == "number" then y = v end
		end)
		if y then return y end
		pcall(function()
			local v = ent:GetProp(name)
			if type(v) == "number" then y = v
			elseif type(v) == "table" then y = v.y or v.yaw end
		end)
		if y then return y end
	end
	return nil
end

local anti_nix_last_yaw = nil
local anti_nix_last_target = nil
local anti_nix_inverted = false
local anti_nix_last_flip = -1000
local anti_nix_last_shot_tick = -100000 -- after shot: wait 0.5s, then disable jitter for 0.3s
local anti_nix_disable_until = -100000  -- on enemy 180 snap: disable jitter for 0.6s

local function anti_nix_jitter_blocked(tick)
	-- 64 tick timing: 0.5s = 32 ticks, 0.3s = 19 ticks.
	-- After our shot, keep jitter for 0.5s, then turn it off for 0.3s.
	local after_shot = tick - anti_nix_last_shot_tick
	if after_shot >= 32 and after_shot <= 51 then return true end
	-- If enemy yaw snaps ~180, pause jitter for 0.6s.
	if tick < anti_nix_disable_until then return true end
	return false
end

local function anti_nixware_invert_offset(tick, target)
	if not target then return anti_nix_inverted and 180 or 0 end
	local y = ent_yaw(target)
	if not y then return anti_nix_inverted and 180 or 0 end

	if target ~= anti_nix_last_target then
		anti_nix_last_target = target
		anti_nix_last_yaw = y
		anti_nix_inverted = false
		anti_nix_last_flip = tick
		return 0
	end

	if anti_nix_last_yaw then
		local delta = math.abs(wrap180(y - anti_nix_last_yaw))
		-- If enemy/Nixware resolver side snaps around 180 degrees, mirror our normal yaw.
		-- Example: your Yaw Offset is 0 -> after snap it becomes +180; next snap -> back to 0.
		if delta >= 140 and (tick - anti_nix_last_flip) > 2 then
			anti_nix_inverted = not anti_nix_inverted
			anti_nix_last_flip = tick
			anti_nix_disable_until = tick + 38 -- 0.6s at 64 tick
		end
	end
	anti_nix_last_yaw = y
	return anti_nix_inverted and 180 or 0
end

-- modifier jitter offset (added on top of the base yaw). the Delay slider sets
-- how many ticks each step lasts (higher = slower jitter).
local spin_angles = {}
local spin_speeds = {}

local function modifier_jitter(tick, cfg)
	local m = cfg.modifier:GetValue() -- 0 Disabled,1 Center,2 Offset,3 3-Way,4 5-Way,5 Anti-Nixware, 6 Spin
	if m == 0 then return 0 end
	local phase = math.floor(tick / math.max(1, cfg.mod_delay:GetValue()))
	if m == 1 then -- Center: alternate -left / +right
		return ((phase % 2) == 0) and -cfg.mod_left:GetValue() or cfg.mod_right:GetValue()
	elseif m == 2 then -- Offset: alternate 0 / offset
		return ((phase % 2) == 0) and 0 or cfg.mod_offset:GetValue()
	elseif m == 3 or m == 4 then -- 3-Way / 5-Way
		local vals
		if m == 3 then
			local a = cfg.mod_3way:GetValue()
			vals = { -a, 0, a }
		else
			local a = cfg.mod_5way:GetValue()
			vals = { -a, -a / 2, 0, a / 2, a }
		end
		local idx
		if cfg.mod_random:GetValue() then -- pick a random way per step
			if phase ~= rand_phase then
				rand_phase = phase
				rand_idx = math.random(1, #vals)
			end
			idx = rand_idx
		else -- go through the ways in order
			idx = (phase % #vals) + 1
		end
		return vals[idx]
	elseif m == 5 then -- Anti-Nixware: 1-tick Center preset left 112 / right 102
		if anti_nix_jitter_blocked(tick) then return 0 end
		return ((tick % 2) == 0) and -112 or 102
	elseif m == 6 then -- Spin
		local target_speed = cfg.mod_spin:GetValue()
		local cur_speed = spin_speeds[cfg] or 0
		cur_speed = cur_speed + (target_speed - cur_speed) * 0.08
		spin_speeds[cfg] = cur_speed

		local cur_angle = (spin_angles[cfg] or 0) + cur_speed
		if cur_angle >= 360 then cur_angle = cur_angle - 360 end
		if cur_angle < 0 then cur_angle = cur_angle + 360 end
		spin_angles[cfg] = cur_angle
		return cur_angle
	end
	return 0
end

-- ============================================================
-- main anti-aim
-- ============================================================
-- force crouch (try the method API, fall back to the field API)
local function force_duck(cmd)
	local ok = pcall(function()
		local b = cmd:GetButtons()
		if bit.band(b, IN_DUCK) == 0 then cmd:SetButtons(b + IN_DUCK) end
	end)
	if not ok then pcall(function() cmd.in_duck = true end) end
end

-- Shadow-style duck peek check: trace a line from our STANDING eye position to
-- an enemy's hitboxes. if the line reaches the enemy (not blocked by world /
-- another player) then we'd have a clear shot from standing -> stand up to peek.
-- otherwise something's in the way from up there, so stay crouched.
STAND_EYE_Z = 64        -- standing view height (origin + 64)
local DUCK_BONES  = { 0, 2, 4, 6 } -- head, chest, stomach, pelvis

local function same_entity(a, b)
	if a == b then return true end
	local ia, ib
	pcall(function() ia = a:GetIndex() end)
	pcall(function() ib = b:GetIndex() end)
	return ia ~= nil and ia == ib
end

MIN_DAMAGE = 88
-- STAND_EYE_Z и DUCK_BONES уже объявлены выше

-- пока заглушка
-- сюда потом подключается твой FFI autowall
local function dist3d(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function get_aw_damage(from, to, enemy)
    local tr

    pcall(function()
        tr = engine.TraceLine(from, to)
    end)

    if not tr then
        return 0
    end

    -- прямой LOS
    if (tr.entity and same_entity(tr.entity, enemy))
        or (tr.fraction and tr.fraction > 0.97) then
        return 100
    end

    if not tr.endpos then
        return 0
    end

    local thickness = dist3d(from, tr.endpos)

	-- более агрессивная оценка прострела
	local dmg = 100 - thickness * 0.20

	-- если трасса почти сразу упёрлась в мир,
	-- считаем, что это тонкая стенка
	if tr.fraction and tr.fraction < 0.04 then
		dmg = dmg + 25
	end

	-- не даём урону падать слишком сильно
	if dmg < 15 then
		dmg = 15
	end

	if dmg > 100 then
		dmg = 100
	end

    return dmg
end

local function enemy_hittable_standing(lp)
    local my = origin_of(lp)

    if not my then
        return false
    end

    local myteam = field_int(lp, "m_iTeamNum")

    local from = Vector3(
        my.x,
        my.y,
        my.z + STAND_EYE_Z
    )

    for i = 1, #esp_targets do
        local e = esp_targets[i]

        if e and e ~= lp and is_live_player(e) then
            local team = field_int(e, "m_iTeamNum")

            if team ~= myteam then
                for _, hb in ipairs(DUCK_BONES) do
                    local pos

                    pcall(function()
                        pos = e:GetHitboxPosition(hb)
                    end)

                    if pos then
                        local dmg = get_aw_damage(from, pos, e)

                        if dmg >= MIN_DAMAGE then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end


-- ============================================================
-- Air Stop (Ragebot > Automate)
-- Uses the same enemy check as Duck Peek Assist: ESP cache + TraceLine hitbox check.
-- No SetForwardMove/SetSideMove and no +movement client commands.
-- ============================================================
AIR_STOP_SHOT_DELAY = 8
AIR_STOP_KILL_DELAY = 14
AIR_STOP_RESTORE_TICKS = 6

-- Separate Air Stop autowall. Duck Peek keeps using its original get_aw_damage().
AIR_STOP_MIN_DAMAGE = 88
AIR_STOP_MAX_WALL_SPAN = 48 -- rejects wall + gap + second wall baits
AIR_STOP_WALL_EXIT_EPS = 6

local AS = {
    active = false,
    auto_ref = nil,
    auto_saved = nil,
    pause_until = -1000,
    restore_until = -1000,
    saved = { w = false, a = false, s = false, d = false },
    keys = { w = false, a = false, s = false, d = false, shift = false },
    last_o = nil,
    last_t = nil,
    last_v = nil,

    -- Current active weapon min damage cache. No drawing/logging, just read and store.
    md_refs = {},
    md_value = nil,
    md_category = "Shared",
    md_def = nil,
    md_path = "",
}

local AS_FFI = rawget(_G, "ffi")
pcall(function()
    if AS_FFI then
        AS_FFI.cdef[[
            void keybd_event(unsigned char bVk, unsigned char bScan, unsigned long dwFlags, unsigned long dwExtraInfo);
            short GetAsyncKeyState(int vKey);
        ]]
    end
end)

local VK_SHIFT, VK_W, VK_A, VK_S, VK_D = 0x10, 0x57, 0x41, 0x53, 0x44
local KEYUP = 0x0002

local function as_key(vk, down)
    if not AS_FFI then return end
    pcall(function() AS_FFI.C.keybd_event(vk, 0, down and 0 or KEYUP, 0) end)
end

local function as_down(vk)
    if not AS_FFI then return false end
    local ok, v = pcall(function() return AS_FFI.C.GetAsyncKeyState(vk) end)
    return ok and v and bit.band(v, 0x8000) ~= 0 or false
end

local function as_save_user_keys()
    AS.saved.w = as_down(VK_W) and not AS.keys.w
    AS.saved.a = as_down(VK_A) and not AS.keys.a
    AS.saved.s = as_down(VK_S) and not AS.keys.s
    AS.saved.d = as_down(VK_D) and not AS.keys.d
end

local function as_restore_user_keys(ticks)
    if AS.saved.w then as_key(VK_W, true) end
    if AS.saved.a then as_key(VK_A, true) end
    if AS.saved.s then as_key(VK_S, true) end
    if AS.saved.d then as_key(VK_D, true) end
    AS.restore_until = globals.TickCount() + (ticks or AIR_STOP_RESTORE_TICKS)
end

local function as_keep_restore()
    if globals.TickCount() > (AS.restore_until or -1000) then return end
    if AS.saved.w then as_key(VK_W, true) end
    if AS.saved.a then as_key(VK_A, true) end
    if AS.saved.s then as_key(VK_S, true) end
    if AS.saved.d then as_key(VK_D, true) end
end

local function as_set_script_keys(w, s, a, d)
    if w or s or a or d then
        as_save_user_keys()
        -- force override physical WASD before pressing counter keys
        as_key(VK_W, false); as_key(VK_A, false); as_key(VK_S, false); as_key(VK_D, false)
        AS.keys.w, AS.keys.a, AS.keys.s, AS.keys.d = false, false, false, false
        AS.active = true
    end

    if AS.keys.w and not w then as_key(VK_W, false); AS.keys.w = false end
    if AS.keys.s and not s then as_key(VK_S, false); AS.keys.s = false end
    if AS.keys.a and not a then as_key(VK_A, false); AS.keys.a = false end
    if AS.keys.d and not d then as_key(VK_D, false); AS.keys.d = false end

    if w then as_key(VK_W, true); AS.keys.w = true end
    if s then as_key(VK_S, true); AS.keys.s = true end
    if a then as_key(VK_A, true); AS.keys.a = true end
    if d then as_key(VK_D, true); AS.keys.d = true end
end

local function as_release(restore)
    local was_active = AS.active
    as_set_script_keys(false, false, false, false)
    if AS.keys.shift then as_key(VK_SHIFT, false); AS.keys.shift = false end
    AS.active = false
    if restore and was_active then as_restore_user_keys(AIR_STOP_RESTORE_TICKS) end
end

local function as_find_auto(obj)
    if not obj then return nil end
    local found
    pcall(function()
        for child in obj:Children() do
            local nm = ""
            pcall(function() nm = child:GetName() end)
            local l = tostring(nm):lower()
            if l == "auto strafe" or (l:find("auto", 1, true) and l:find("strafe", 1, true)) then
                found = child; return
            end
            local sub = as_find_auto(child)
            if sub then found = sub; return end
        end
    end)
    return found
end

local function as_auto_ref()
    if AS.auto_ref then return AS.auto_ref end
    local refs = {
        {"Miscellaneous", "Movement"}, {"MISC", "Movement"}, {"Misc", "Movement"},
        {"Miscellaneous"}, {"MISC"}, {"Misc"}, {"MENU"},
    }
    for i = 1, #refs do
        local r
        pcall(function() r = gui.Reference(unpack(refs[i])) end)
        local f = as_find_auto(r)
        if f then AS.auto_ref = f; return f end
    end
    return nil
end

local function as_auto_off()
    local r = as_auto_ref(); if not r then return end
    if AS.auto_saved == nil then pcall(function() AS.auto_saved = r:GetValue() and true or false end) end
    pcall(function() r:SetValue(false) end)
end

local function as_auto_restore()
    local r = as_auto_ref(); if not r or AS.auto_saved == nil then return end
    pcall(function() r:SetValue(AS.auto_saved and true or false) end)
    AS.auto_saved = nil
end

local AS_DEF_TO_CATEGORY = {
    [31] = "Zeus",

    [2] = "Pistol", [3] = "Pistol", [4] = "Pistol", [30] = "Pistol",
    [32] = "Pistol", [36] = "Pistol", [61] = "Pistol", [63] = "Pistol",

    [1] = "Heavy Pistol", [64] = "Heavy Pistol",

    [17] = "Submachine Gun", [19] = "Submachine Gun", [23] = "Submachine Gun",
    [24] = "Submachine Gun", [26] = "Submachine Gun", [33] = "Submachine Gun", [34] = "Submachine Gun",

    [7] = "Rifle", [8] = "Rifle", [10] = "Rifle", [13] = "Rifle",
    [16] = "Rifle", [39] = "Rifle", [60] = "Rifle",

    [25] = "Shotgun", [27] = "Shotgun", [29] = "Shotgun", [35] = "Shotgun",

    [40] = "Scout",
    [9] = "Sniper",
    [11] = "Auto Sniper", [38] = "Auto Sniper",

    [14] = "Light Machine Gun", [28] = "Light Machine Gun",
}

local function as_weapon_category_from_def(def)
    return AS_DEF_TO_CATEGORY[def] or "Shared"
end

local function as_direct_mindmg_ref(category)
    category = category or "Shared"
    if AS.md_refs[category] ~= nil then return AS.md_refs[category] end

    local obj = nil
    pcall(function()
        local root = gui.Reference("Ragebot", "Accuracy")
        if not root then return end
        local weapon = root:Reference(category)
        if not weapon then return end
        obj = weapon:Reference("Min Damage")
    end)

    -- Cache false too, so wrong paths don't get retried/spammed every tick.
    AS.md_refs[category] = obj or false
    return AS.md_refs[category]
end

as_update_min_damage = function()
    -- Read active weapon's min damage and cache it.
    local def = active_weapon_def_safe()
    local category = as_weapon_category_from_def(def)
    local ref = as_direct_mindmg_ref(category)
    local v = nil

    if ref and ref ~= false then
        pcall(function() v = tonumber(ref:GetValue()) end)
    end

    -- Fallback to Shared if the weapon category ref is missing.
    if v == nil and category ~= "Shared" then
        local shared = as_direct_mindmg_ref("Shared")
        if shared and shared ~= false then
            pcall(function() v = tonumber(shared:GetValue()) end)
        end
    end

    AS.md_def = def
    AS.md_category = category
    AS.md_value = v
    AS.md_path = "Ragebot / Accuracy / " .. tostring(category) .. " / Min Damage"

    _G.AW_ACTIVE_MIN_DAMAGE = {
        def = AS.md_def,
        category = AS.md_category,
        value = AS.md_value,
        path = AS.md_path,
        source = "active_weapon_def_safe",
    }
end

_G.AW_FORCE_UPDATE_MIN_DAMAGE = as_update_min_damage

local function as_vec(ent, name)
    local v
    pcall(function() v = ent:GetPropVector(name) end); if v and v.x then return v end
    pcall(function() v = ent:GetFieldVector(name) end); if v and v.x then return v end
    pcall(function() v = ent:GetProp(name) end); if v and v.x then return v end
    pcall(function() v = ent:GetField(name) end); if v and v.x then return v end
    pcall(function() v = ent[name] end); if v and v.x then return v end
    return nil
end

local function as_velocity(lp)
    local direct = as_vec(lp, "m_vecAbsVelocity") or as_vec(lp, "m_vecVelocity")
    if direct and direct.x then return direct end

    local o = origin_of(lp)
    local t = globals.TickCount()
    local v
    if o and AS.last_o and AS.last_t and t > AS.last_t then
        local dt = (t - AS.last_t) / 64
        if dt > 0 then
            v = { x = (o.x - AS.last_o.x) / dt, y = (o.y - AS.last_o.y) / dt, z = ((o.z or 0) - (AS.last_o.z or 0)) / dt }
        end
    end
    if o then AS.last_o = { x = o.x, y = o.y, z = o.z or 0 }; AS.last_t = t end
    return v
end


local function as_trace_line(a, b)
    local tr = nil
    pcall(function()
        tr = engine.TraceLine(a, b)
    end)
    return tr
end

local function as_trace_reaches_enemy_or_end(tr, enemy)
    if not tr then return false end
    if tr.entity and same_entity(tr.entity, enemy) then return true end
    if tr.fraction and tr.fraction > 0.97 then return true end
    return false
end

local function as_point_along(from, dir, dist)
    return Vector3(
        (from.x or 0) + dir.x * dist,
        (from.y or 0) + dir.y * dist,
        (from.z or 0) + dir.z * dist
    )
end

local function as_get_aw_damage(from, to, enemy)
    -- Air Stop-only safer pseudo-autowall.
    -- Duck Peek Assist still uses get_aw_damage() above.
    -- This rejects cases where first wall is penetrable but another wall remains behind it.
    local total_dist = dist3d(from, to)
    if total_dist <= 1 then return 0 end

    local dir = {
        x = ((to.x or 0) - (from.x or 0)) / total_dist,
        y = ((to.y or 0) - (from.y or 0)) / total_dist,
        z = ((to.z or 0) - (from.z or 0)) / total_dist,
    }

    local tr = as_trace_line(from, to)
    if as_trace_reaches_enemy_or_end(tr, enemy) then
        return 100
    end

    if not tr or not tr.endpos then return 0 end

    -- Reverse trace estimates the exit side of the obstructing material.
    -- If there is wall + air gap + second wall, this span becomes too large.
    local rev = as_trace_line(to, from)
    if not rev or not rev.endpos then return 0 end

    local wall_span = dist3d(tr.endpos, rev.endpos)
    if wall_span <= 0 or wall_span > AIR_STOP_MAX_WALL_SPAN then
        return 0
    end

    -- After the estimated wall exit, trace again to enemy.
    -- If another wall remains, reject the bait.
    local hit_dist = dist3d(from, tr.endpos)
    local exit_dist = hit_dist + wall_span + AIR_STOP_WALL_EXIT_EPS
    if exit_dist >= total_dist then return 0 end

    local exit_point = as_point_along(from, dir, exit_dist)
    local after = as_trace_line(exit_point, to)
    if not as_trace_reaches_enemy_or_end(after, enemy) then
        return 0
    end

    local dmg = 100 - wall_span * 0.25
    if dmg < 0 then dmg = 0 end
    if dmg > 100 then dmg = 100 end
    return dmg
end

local function as_enemy_hittable_standing(lp)
    local my = origin_of(lp)
    if not my then return false end

    local myteam = field_int(lp, "m_iTeamNum")
    local from = Vector3(my.x, my.y, (my.z or 0) + STAND_EYE_Z)

    for i = 1, #esp_targets do
        local e = esp_targets[i]
        if e and e ~= lp and is_live_player(e) then
            local team = field_int(e, "m_iTeamNum")
            if not (myteam ~= 0 and team ~= 0 and team == myteam) then
                for _, hb in ipairs(DUCK_BONES) do
                    local pos = nil
                    pcall(function() pos = e:GetHitboxPosition(hb) end)
                    if pos then
                        local dmg = as_get_aw_damage(from, pos, e)
                        if dmg >= AIR_STOP_MIN_DAMAGE then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

local function as_is_scout(lp)
    -- SSG 08 / Scout weapon definition index is 40.
    -- If active def cannot be read, do NOT air-stop to avoid stopping on AWP/autos/pistols/nades/knife.
    local def = active_weapon_def_safe()
    return def == 40
end

local function as_air_stop(cmd, lp)
    if not g.air_stop:GetValue() then
        as_auto_restore(); as_release(true); return
    end

    -- Only Scout/SSG 08. Do not air-stop with grenades, knife, pistols, AWP, autos, rifles, etc.
    if not as_is_scout(lp) then
        as_auto_restore(); as_release(true); AS.last_o = nil; AS.last_t = nil; return
    end

    local flags = field_int(lp, "m_fFlags")
    local in_air = bit.band(flags, FL_ONGROUND) == 0
    if not in_air then
        as_auto_restore(); as_release(true); AS.last_o = nil; AS.last_t = nil; return
    end

    local now = globals.TickCount()
    if now < AS.pause_until then
        as_auto_restore(); as_release(false); as_keep_restore(); return
    end

    -- Air Stop target check uses its own safer autowall.
    -- Duck Peek Assist still uses the original enemy_hittable_standing().
    if not as_enemy_hittable_standing(lp) then
        as_auto_restore(); as_release(true); as_keep_restore(); return
    end

    as_auto_off()
    if not AS.keys.shift then as_key(VK_SHIFT, true); AS.keys.shift = true end

    local v = as_velocity(lp)
    if not v or not v.x then as_release(false); return end

    local yaw = math.rad(pre_va.y or 0)
    local fx, fy = math.cos(yaw), math.sin(yaw)
    local rx, ry = math.sin(yaw), -math.cos(yaw)
    local rel_f = fx * v.x + fy * v.y
    local rel_s = rx * v.x + ry * v.y
    local th = 1

    -- velocity vector -> opposite keys
    local press_s = rel_f > th
    local press_w = rel_f < -th
    local press_a = rel_s > th
    local press_d = rel_s < -th
    as_set_script_keys(press_w, press_s, press_a, press_d)
end

local function as_pause(ticks)
    AS.pause_until = globals.TickCount() + (ticks or AIR_STOP_SHOT_DELAY)
    as_auto_restore()
    as_release(false)
    as_restore_user_keys(ticks or AIR_STOP_RESTORE_TICKS)
end

local blockbot_target = nil
local function get_velocity(e)
    local v = nil
    -- Пробуем разные варианты получения скорости для CS2
    pcall(function() v = e:GetPropVector("m_vecVelocity") end)
    if not v then pcall(function() v = e:GetPropVector("m_vVelocity") end) end
    if not v then pcall(function() v = e:GetAbsVelocity() end) end
    return v or Vector3(0,0,0)
end

local function handle_blockbot(cmd)
    if not g.blockbot_enable or not g.blockbot_enable:GetValue() then 
        blockbot_target = nil
        return 
    end
    local key = g.blockbot_key:GetValue()
    if key == 0 or not input.IsButtonDown(key) then 
        blockbot_target = nil
        return 
    end

    local lp = entities.GetLocalPlayer()
    if not lp or not lp:IsAlive() then return end
    
    local my_pos = origin_of(lp)
    if not my_pos then return end

    -- Поиск цели (если текущая невалидна или далеко)
    if not blockbot_target or not blockbot_target:IsAlive() or (origin_of(blockbot_target) and (origin_of(blockbot_target) - my_pos):Length() > 400) then
        local best_dist = 300
        blockbot_target = nil
        
        local players = entities.FindByClass("C_CSPlayerPawn")
        if not players or #players == 0 then players = entities.FindByClass("CCSPlayer") end
        
        if players then
            for i = 1, #players do
                local p = players[i]
                if p:GetIndex() ~= lp:GetIndex() and is_live_player(p) then
                    local pos = origin_of(p)
                    if pos then
                        local dx, dy = pos.x - my_pos.x, pos.y - my_pos.y
                        local dist = math.sqrt(dx*dx + dy*dy)
                        if dist < best_dist then
                            best_dist = dist
                            blockbot_target = p
                        end
                    end
                end
            end
        end
    end

    if not blockbot_target then return end

    local target_pos = origin_of(blockbot_target)
    if not target_pos then return end

    local target_vel = get_velocity(blockbot_target)
    local target_speed = math.sqrt(target_vel.x*target_vel.x + target_vel.y*target_vel.y)
    
    local is_on_head = false
    local height_diff = my_pos.z - target_pos.z
    if height_diff > 45 and height_diff < 105 then
        is_on_head = true
    end

    local move_pos_x, move_pos_y = target_pos.x, target_pos.y
    
    if is_on_head then
        -- На голове: предикшн, чтобы не слететь
        if target_speed > 5 then
            move_pos_x = target_pos.x + target_vel.x * (globals.TickInterval() * 3)
            move_pos_y = target_pos.y + target_vel.y * (globals.TickInterval() * 3)
        end
    else
        -- На земле: встаем ПЕРЕД челом
        if target_speed > 15 then
            local vx = target_vel.x / target_speed
            local vy = target_vel.y / target_speed
            move_pos_x = target_pos.x + vx * 25
            move_pos_y = target_pos.y + vy * 25
        end
    end

    local dx = move_pos_x - my_pos.x
    local dy = move_pos_y - my_pos.y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    if dist > 0.8 then
        local va = cmd:GetViewAngles()
        local move_yaw = math.deg(math.atan2(dy, dx))
        local forward = math.cos(math.rad(move_yaw - va.y))
        local side = math.sin(math.rad(move_yaw - va.y))
        
        local m_f = forward * 450
        local m_s = side * 450
        
        cmd:SetForwardMove(m_f)
        cmd:SetSideMove(m_s)
        
        -- Прожим кнопок для CS2 (обязательно)
        local b = cmd:GetButtons()
        if m_f > 50 then b = bit.bor(b, IN_FORWARD) end
        if m_f < -50 then b = bit.bor(b, IN_BACK) end
        if m_s > 50 then b = bit.bor(b, IN_LEFT) end
        if m_s < -50 then b = bit.bor(b, IN_RIGHT) end
        cmd:SetButtons(b)
    else
        -- Если уже в нужной точке - стопаемся
        cmd:SetForwardMove(0)
        cmd:SetSideMove(0)
    end
end


local function pre_move(cmd)
	pre_va = cmd:GetViewAngles()
	pcall(handle_blockbot, cmd)


	-- Read current active weapon Min Damage silently. No text/logs.
	pcall(as_update_min_damage)

	-- Air Stop is independent of AA master. It uses Duck Peek Assist enemy check.
	do
		local alp = entities.GetLocalPlayer()
		local alive = false
		if alp then pcall(function() alive = alp:IsAlive() end) end
		if alive then as_air_stop(cmd, alp) else as_auto_restore(); as_release(false) end
	end

	-- duck peek assist (bind held). stay crouched, and only stand to peek when
	-- the cheat sees a target (enemy on screen) but we haven't been able to fire
	-- for ~200ms - i.e. something is blocking the shot from the crouch. while
	-- we're actively firing (hitting from the crouch) we stay down. After a shot
	-- we re-crouch ~1.5s. Independent of the AA builder.
	do
		-- just switched weapon, or just landed from the air: wait ~1.5s before
		-- the duck peek is allowed to stand (gun isn't ready / you just landed).
		local now = globals.TickCount()
		local dlp = entities.GetLocalPlayer()
		if dlp then
			local wt = -1
			pcall(function() wt = dlp:GetWeaponType() end)
			local onground = bit.band(field_int(dlp, "m_fFlags"), FL_ONGROUND) ~= 0
			if wt ~= duck_prev_wt or (onground and not duck_prev_ground) then
				duck_cd_until = now + DUCK_COOLDOWN_TICKS
			end
			duck_prev_wt = wt
			duck_prev_ground = onground
		end
	end

	if duck_active then
		-- stand only when a clear shot exists from standing (computed in Draw via
		-- TraceLine) and we're not in the post-shot / switch / landing cooldown.
		local in_cd = globals.TickCount() < duck_cd_until
		local buttons = cmd:GetButtons()
		if bit.band(buttons, IN_ATTACK) ~= 0 then
			duck_cd_until = globals.TickCount() + 96
		end
		local stable_peek =
			duck_can_peek and
			duck_peek_since ~= 0 and
			globals.TickCount() - duck_peek_since > 4

		if not (stable_peek and not in_cd) then
			force_duck(cmd)
		end
	end

	if not g.master:GetValue() then return end

	local lp = entities.GetLocalPlayer()
	if not lp or not lp:IsAlive() then return end

	local move_type = field_int(lp, "m_nActualMoveType")
	local buttons   = cmd:GetButtons()
	local tick      = globals.TickCount()

	-- Grenades are thrown on LMB/RMB release. Do not apply anti-aim on that
	-- release window, otherwise the grenade can fly by the AA angle.
	if grenade_throw_should_disable_aa(lp, buttons, tick) then return end

	if g.on_ladder:GetValue() and move_type == MOVETYPE_LADDER then return end
	if g.on_use:GetValue() and bit.band(buttons, ON_USE) ~= 0 then return end
	if g.disable_shot:GetValue() and bit.band(buttons, IN_ATTACK) ~= 0 then return end

	local va     = cmd:GetViewAngles()
	local state  = current_state(lp, cmd)
	local wclass = weapon_class(lp)
	local bmode  = g.base:GetValue() -- 0 Local View, 1 At Target
	local has_target = false
	local base = pre_va.y -- local view
	if bmode == 1 then
		local ty = target_yaw(lp)
		if ty then base = ty; has_target = true end
	end

	-- ============================================================
	-- Defensive Builder: cycle between offensive (Builder Tick) and defensive (Defensive Tick)
	-- ============================================================
	-- ============================================================
	-- Round End AA: activates when round_end event fires
	-- ============================================================
	local roundend_active = g.builder_mode:GetValue() == 2 and g.roundend_enable:GetValue()
	if roundend_active and round_ended then
		local re_yaw = g.re_yaw:GetValue()    -- 0 Off, 1 Static, 2 Random, 3 Spin
		local re_pm  = g.re_pitch:GetValue()   -- 0 Off, 1 Directional, 2 Static, 3 Zero, 4 Up, 5 Down

		-- Round End Yaw (persistent re_goal for Random)
		if re_yaw == 0 then
			re_goal = 0  -- Off: keep current offset
		elseif re_yaw == 1 then
			re_goal = g.re_yaw_static:GetValue()
		elseif re_yaw == 2 then
			if tick % 16 == 0 then re_goal = math.random(-180, 180) end
			-- keep last random value
		elseif re_yaw == 3 then
			local spd = g.re_yaw_spin:GetValue()
			re_goal = (tick * spd) % 360 - 180
		end

		-- Round End Pitch
		local re_pitch_val
		if re_pm == 0 then
			re_pitch_val = nil  -- Off: keep player pitch
		elseif re_pm == 1 then
			local pdf = g.re_pitch_dir_from:GetValue()
			local pdt = g.re_pitch_dir_to:GetValue()
			local pds = g.re_pitch_dir_speed:GetValue()
			local prange = math.abs(pdt - pdf)
			if prange < 0.1 then prange = 1 end
			local raw = tick * pds * 0.1
			local period = 2 * prange
			local phase = raw % period
			if phase > prange then phase = period - phase end
			re_pitch_val = pdf + ((pdt > pdf) and phase or -phase)
		elseif re_pm == 2 then
			re_pitch_val = g.re_pitch_static:GetValue()
		elseif re_pm == 3 then
			re_pitch_val = 0
		elseif re_pm == 4 then
			re_pitch_val = -89
		elseif re_pm == 5 then
			re_pitch_val = 89
		end

		-- Lerp yaw smoothly
		local re_diff = wrap180(re_goal - cur_off)
		if math.abs(re_diff) < 1 then
			cur_off = cur_off + re_diff
		else
			cur_off = cur_off + re_diff * 0.45
		end

		va.y = base + cur_off
		if re_pitch_val ~= nil then va.x = re_pitch_val end
		va.z = 0
		has_target = (base ~= pre_va.y)
		cur_target = has_target

		cur_group_name = "Round End"
		cur_state_name = "AA"
		cur_yaw = wrap180(va.y)
		cmd:SetViewAngles(va)
		return  -- skip everything else
	end

	local defensive_active = g.builder_mode:GetValue() == 1 and g.defensive_enable:GetValue()
	local in_defensive_phase = false

	if defensive_active then
		local def_tick  = g.def_tick:GetValue()
		local build_tick = g.build_tick:GetValue()
		local rand_tick = g.rand_tick:GetValue()

		-- Initialise cycle if first tick or cycle ended
		if not def_cycle_until or tick >= def_cycle_until then
			if def_cycle_phase == 0 then
				-- Builder phase just ended → switch to defensive
				def_cycle_phase = 1
				local extra = (rand_tick > 0) and math.random(-rand_tick, rand_tick) or 0
				def_cycle_until = tick + def_tick + extra
			else
				-- Defensive phase just ended → switch to builder
				def_cycle_phase = 0
				local extra = (rand_tick > 0) and math.random(-rand_tick, rand_tick) or 0
				def_cycle_until = tick + build_tick + extra
			end
		end

		in_defensive_phase = (def_cycle_phase == 1)
	end

	-- pitch value + how "down" it is (1 = full down -> full Auto Yaw,
	-- 0 = level/up -> straight yaw). Auto Yaw is scaled by this factor.
	local cfg = g.cond_cfg[state] or g.cond_cfg[1]
	local pm = cfg.pitch:GetValue() -- 0 Disabled,1 Down,2 Up,3 Jitter,4 Zero,5 Custom
	local pitch_val, pfactor
	if pm == 1 then     pitch_val = 89;  pfactor = 1
	elseif pm == 2 then pitch_val = -89; pfactor = 0
	elseif pm == 3 then pitch_val = (tick % 2 == 0) and 89 or -89; pfactor = (pitch_val > 0) and 1 or 0
	elseif pm == 4 then pitch_val = 0;   pfactor = 0
	elseif pm == 5 then pitch_val = cfg.pitch_value:GetValue(); pfactor = math.max(0, math.min(1, pitch_val / 89))
	else                pitch_val = nil; pfactor = math.max(0, math.min(1, pre_va.x / 89)) end -- Disabled: keep player's pitch

	-- target yaw offset for the active mode (manual offsets are tuned per weapon
	-- and state; knife -> pistol)
	local mcls = (wclass == "other" or wclass == "grenade") and "other" or "pistol"
	local goal
	if manual == 1 then
		goal = MANUAL[mcls][state][2] -- right
	elseif manual == 2 then
		goal = MANUAL[mcls][state][1] -- left
	elseif manual == 3 then
		goal = 0 -- forward
	else
		-- Auto Yaw is always on. Pitch blends the yaw: full down = tuned
		-- per-weapon/state value, level/up = straight back (+/-180). + Yaw
		-- Offset + Modifier jitter, built on the chosen base reference.
		local av   = AUTO_YAW[wclass][state]
		local back = (av < 0) and -180 or 180
		local anti_nix_inv = (cfg.modifier:GetValue() == 5) and anti_nixware_invert_offset(tick, aa_target_ent) or 0
		goal = back + (av - back) * pfactor + cfg.yaw_offset:GetValue() + anti_nix_inv + modifier_jitter(tick, cfg)
	end

	-- detect a manual switch: left<->right rotates through the back
	if manual ~= prev_manual then
		local old_manual = prev_manual
		if manual == 1 or manual == 2 then
			sweep_from  = cur_off
			sweep_to    = sweep_target(cur_off, goal)
			sweep_start = tick
		end
		-- trigger jitter on ANY manual state change: on, off, left<->right, right<->left
		-- special directional jitter for left<->right:
		-- left -> right: modifier left 0 / right 25
		-- right -> left: modifier left 25 / right 0
		if old_manual == 2 and manual == 1 then
			manual_jitter_mode = 1
		elseif old_manual == 1 and manual == 2 then
			manual_jitter_mode = 2
		else
			manual_jitter_mode = 0
		end
		switch_tick = tick
		prev_manual = manual
	end

	if not in_defensive_phase then
		if (manual == 1 or manual == 2) and (tick - sweep_start) < SWEEP_TICKS then
			local p = (tick - sweep_start) / SWEEP_TICKS
			cur_off = sweep_from + (sweep_to - sweep_from) * p
		else
			-- Плавный переход между кондишнами (lerp вместо мгновенного прыжка)
			local diff = wrap180(goal - cur_off)
			local smooth = 0.35 -- 0.0 = мгновенно, 1.0 = очень медленно
			if math.abs(diff) < 1 then
				cur_off = cur_off + diff -- близко → snap
			else
				cur_off = cur_off + diff * (1 - smooth)
			end
		end
		-- Manual jitter: ~3.5 ticks after manual on/off/switch.
		-- TickCount is integer, so this behaves as roughly 4 game ticks.
		-- left -> right: 0/+25. right -> left: -25/0. other changes: +/-38.
		local manual_jitter = 0
		if (tick - switch_tick) < 3.5 then
			if manual_jitter_mode == 1 then
				manual_jitter = ((tick % 2) == 0) and 0 or 25
			elseif manual_jitter_mode == 2 then
				manual_jitter = ((tick % 2) == 0) and -25 or 0
			else
				manual_jitter = ((tick % 2) == 0) and 38 or -38
			end
		end
		va.y = base + cur_off + manual_jitter
	end

	-- apply pitch (nil = Disabled -> keep the player's pitch)
	if pitch_val ~= nil then va.x = pitch_val end

	-- ============================================================
	-- Defensive override: if we're in the defensive phase, replace
	-- the offensive yaw/pitch with the defensive builder's output.
	-- ============================================================
	if in_defensive_phase then
		local def_cfg = g.def_cond_cfg[state] or g.def_cond_cfg[1]
		local yawmode = def_cfg.yaw:GetValue()    -- 0 Off, 1 Sideways, 2 Static, 3 Directional, 4 L/R
		local def_tick = g.def_tick:GetValue()

		-- Compute defensive yaw goal (At Target base, centered on Auto Yaw)
		-- Pitch blends Auto Yaw: full down = tuned yaw, level/up = straight back (±180°)
		local def_ty = target_yaw(lp)
		local def_base_target = def_ty or base  -- use offensive base (At Target or Local View) as fallback
		if not def_base_smooth then def_base_smooth = def_base_target end
		def_base_smooth = def_base_smooth + wrap180(def_base_target - def_base_smooth) * 0.35
		local av  = AUTO_YAW[wclass][state]  -- offensive auto yaw center
		local back = (av < 0) and -180 or 180
		local def_pm = def_cfg.pitch:GetValue() -- 0 Disabled,1 Down,2 Up,3 Jitter,4 Zero,5 Custom,6 Directional,7 Random
		-- pre-compute pitch factor so yaw blending works before pitch is applied
		local def_pfactor
		if def_pm == 0 then     def_pfactor = math.max(0, math.min(1, pre_va.x / 89))      -- Disabled: real pitch
		elseif def_pm == 1 then def_pfactor = 1                                              -- Down: full auto yaw
		elseif def_pm == 2 then def_pfactor = 0                                              -- Up: straight back
		elseif def_pm == 3 then def_pfactor = (tick % 2 == 0) and 1 or 0                     -- Jitter: alternating
		elseif def_pm == 4 then def_pfactor = 0                                              -- Zero: straight back
		elseif def_pm == 5 then def_pfactor = math.max(0, math.min(1, def_cfg.pitch_value:GetValue() / 89)) -- Custom
		elseif def_pm == 6 then def_pfactor = 0.5                                            -- Directional: mid blend
		else                  def_pfactor = 0.5 end                                          -- Random: mid blend
		local blended_av_target = back + (av - back) * def_pfactor
		if not def_av_smooth then def_av_smooth = blended_av_target end
		def_av_smooth = def_av_smooth + wrap180(blended_av_target - def_av_smooth) * 0.4
		local blended_av = def_av_smooth

		local def_goal  -- this is the OFFSET goal (cur_off lerps to this), NOT full yaw
		if yawmode == 0 then
			def_goal = blended_av  -- Off = blended Auto Yaw
		elseif yawmode == 1 then
			local side = def_cfg.yaw_sideways:GetValue()
			def_goal = blended_av + ((tick % 8 < 4) and side or -side)
		elseif yawmode == 2 then
			local st = def_cfg.yaw_static:GetValue()
			def_goal = blended_av + st
		elseif yawmode == 3 then
			local dfrom  = def_cfg.yaw_dir_from:GetValue()
			local dto    = def_cfg.yaw_dir_to:GetValue()
			local dspeed = def_cfg.yaw_dir_speed:GetValue()
			-- continuous sweep forward, no reset, lerp handles wrapping
			def_goal = blended_av + dfrom + tick * dspeed * 0.1
		elseif yawmode == 4 then
			local lr_left   = def_cfg.yaw_lr_left:GetValue()
			local lr_right  = def_cfg.yaw_lr_right:GetValue()
			local lr_delay  = def_cfg.yaw_lr_delay:GetValue()
			local lr_random = def_cfg.yaw_lr_random:GetValue()
			-- randomise delay: re-roll the switch tick when entering a new phase
			if not lr_next_switch or tick >= lr_next_switch then
				local extra = (lr_random > 0) and math.random(-lr_random, lr_random) or 0
				lr_next_switch = tick + lr_delay + extra
				lr_side = not lr_side  -- flip left/right
			end
			local side_yaw = lr_side and lr_left or lr_right
			def_goal = blended_av + side_yaw
		else
			def_goal = blended_av
		end

		-- Defensive modifier jitter
		local def_m = def_cfg.modifier:GetValue() -- 0 Disabled,1 Center,2 Offset,3 3-Way,4 5-Way,5 Spin
		local build_tick = g.build_tick:GetValue()
		local def_jitter = 0
		if def_m == 1 then
			def_jitter = ((tick % (build_tick * 2) < build_tick) and def_cfg.mod_left:GetValue() or -def_cfg.mod_right:GetValue())
		elseif def_m == 2 then
			def_jitter = def_cfg.mod_offset:GetValue()
		elseif def_m == 3 then
			local rng = def_cfg.mod_3way:GetValue()
			local delay = def_cfg.mod_delay:GetValue()
			if def_cfg.mod_random:GetValue() then
				local rd = math.random(0, 2)
				def_jitter = (rd == 0 and -rng) or (rd == 1 and 0) or rng
			else
				local idx = math.floor(tick / delay) % 3
				def_jitter = (idx == 0 and -rng) or (idx == 1 and 0) or rng
			end
		elseif def_m == 4 then
			local rng = def_cfg.mod_5way:GetValue()
			local delay = def_cfg.mod_delay:GetValue()
			if def_cfg.mod_random:GetValue() then
				local rd = math.random(0, 4)
				def_jitter = -rng + (rng * 2 / 3) * rd
			else
				local idx = math.floor(tick / delay) % 5
				def_jitter = -rng + (rng * 2 / 4) * idx
			end
		elseif def_m == 5 then
			local spd = def_cfg.mod_spin:GetValue()
			def_jitter = (tick * spd) % 360 - 180
		end

		-- Defensive pitch
		local rand_tick = g.rand_tick:GetValue()
		local def_pitch_val = nil
		if def_pm == 0 then
			def_pitch_val = pre_va.x  -- Disabled: keep player's real pitch
		elseif def_pm == 1 then
			def_pitch_val = 89
		elseif def_pm == 2 then
			def_pitch_val = -89
		elseif def_pm == 3 then
			local jfrom = def_cfg.pitch_jitter_from:GetValue()
			local jto   = def_cfg.pitch_jitter_to:GetValue()
			local jdelay = def_cfg.pitch_jitter_delay:GetValue()
			def_pitch_val = ((tick % (jdelay * 2) < jdelay) and jfrom or jto)
		elseif def_pm == 4 then
			def_pitch_val = 0
		elseif def_pm == 5 then
			def_pitch_val = def_cfg.pitch_value:GetValue()
		elseif def_pm == 6 then
			local pdf = def_cfg.pitch_dir_from:GetValue()
			local pdt = def_cfg.pitch_dir_to:GetValue()
			local pds = def_cfg.pitch_dir_speed:GetValue()
			-- triangle wave: from→to→back→from, no sudden jumps
			local prange = math.abs(pdt - pdf)
			if prange < 0.1 then prange = 1 end
			local raw = tick * pds * 0.1
			local period = 2 * prange
			local phase = raw % period
			if phase > prange then phase = period - phase end
			def_pitch_val = pdf + ((pdt > pdf) and phase or -phase)
		elseif def_pm == 7 then
			if tick % math.max(1, rand_tick) == 0 then
				def_pitch_val = math.random(-89, 89)
			else
				def_pitch_val = pre_va.x
			end
		end

		-- Lerp defensive goal smoothly
		local def_diff = wrap180(def_goal - cur_off)
		if math.abs(def_diff) < 1 then
			cur_off = cur_off + def_diff
		else
			cur_off = cur_off + def_diff * 0.65
		end

		-- Override with defensive values
		va.y = def_base_smooth + cur_off + def_jitter
		if def_pitch_val ~= nil then va.x = def_pitch_val end
		has_target = (def_ty ~= nil)
		cur_target = has_target
	end

	va.z = 0

	cur_group_name = (wclass == "knife") and "Knife"
		or (wclass == "pistol") and "Pistols"
		or (wclass == "grenade") and "Grenades" or "Rifles & Snipers"
	cur_state_name = STATES[state]
	if in_defensive_phase then cur_state_name = cur_state_name .. " [DEF]" end
	cur_yaw = wrap180(va.y)
	cur_target = has_target
	cmd:SetViewAngles(va)
end

-- ============================================================
-- input + UI visibility + indicator
-- ============================================================
local function handle_key(keybox, id)
	local key = keybox:GetValue()
	if key ~= 0 and input.IsButtonPressed(key) then
		if manual == id then
			manual = 0
			switch_tick = globals.TickCount() -- trigger jitter on manual off
		else
			manual = id
			switch_tick = globals.TickCount() -- trigger switch jitter
		end
	end
end

screen_x, screen_y = draw.GetScreenSize()

scope_alpha = 0
scope_saved_mode = -1 -- last mode we saw (for backup/restore)
scope_backup = nil    -- saved slider values when switching to None
scope_current = {
	line_length = 350,
	gradient = 10,
	aspect = 0,
	thickness = 1,
	top = 20,
	bottom = 20,
	right = 20,
	left = 20,
}
scope_last_time = common.Time()

function scope_lerp(a, b, t)
	return a + (b - a) * t
end

-- Indicator lerp (clamped)
local function ind_lerp(a, b, t)
	t = math.min(math.max(t, 0), 1)
	return a + (b - a) * t
end

-- Map current AA state to indicator condition string (metasoon style)
local function ind_get_condition()
	local dlp = entities.GetLocalPlayer()
	if not dlp then return "STANDING" end
	local alive = false
	pcall(function() alive = dlp:IsAlive() end)
	if not alive then return "STANDING" end
	-- re-use the state index that pre_move already set
	-- cur_state_name is like "Standing", "Moving", "Crouched", "In Air"
	local s = cur_state_name
	if s == "In Air" then return "AIR" end
	if s == "Moving" then return "MOVING" end
	if s == "Crouched" then return "CROUCH" end
	if s:find("DEF") then return "DEFENSIVE" end
	return "STANDING"
end

function draw_scope_rect(x1, y1, x2, y2, r, gcol, b, a)
	if a <= 0 then return end
	draw.Color(r, gcol, b, math.max(0, math.min(255, math.floor(a))))
	draw.FilledRect(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
end

function draw_scope_horiz(x1, x2, y, thickness, grad, r, gcol, b, a)
	local left, right = math.min(x1, x2), math.max(x1, x2)
	local pixels = math.floor(right - left)
	if pixels <= 1 then return end
	thickness = math.max(1, thickness)
	local half = thickness / 2
	grad = math.floor(math.max(0, math.min(grad or 0, pixels / 2, 50)))
	if grad < 2 then
		draw_scope_rect(left, y - half, right, y - half + thickness, r, gcol, b, a)
		return
	end
	for p = 0, grad - 1 do
		local al = a * (p / grad)
		draw_scope_rect(left + p, y - half, left + p + 1, y - half + thickness, r, gcol, b, al)
	end
	if pixels > grad * 2 then
		draw_scope_rect(left + grad, y - half, right - grad, y - half + thickness, r, gcol, b, a)
	end
	for p = pixels - grad, pixels - 1 do
		local al = a * ((pixels - p) / grad)
		draw_scope_rect(left + p, y - half, left + p + 1, y - half + thickness, r, gcol, b, al)
	end
end

function draw_scope_vert(y1, y2, x, thickness, grad, r, gcol, b, a)
	local top, bottom = math.min(y1, y2), math.max(y1, y2)
	local pixels = math.floor(bottom - top)
	if pixels <= 1 then return end
	thickness = math.max(1, thickness)
	local half = thickness / 2
	grad = math.floor(math.max(0, math.min(grad or 0, pixels / 2, 50)))
	if grad < 2 then
		draw_scope_rect(x - half, top, x - half + thickness, bottom, r, gcol, b, a)
		return
	end
	for p = 0, grad - 1 do
		local al = a * (p / grad)
		draw_scope_rect(x - half, top + p, x - half + thickness, top + p + 1, r, gcol, b, al)
	end
	if pixels > grad * 2 then
		draw_scope_rect(x - half, top + grad, x - half + thickness, bottom - grad, r, gcol, b, a)
	end
	for p = pixels - grad, pixels - 1 do
		local al = a * ((pixels - p) / grad)
		draw_scope_rect(x - half, top + p, x - half + thickness, top + p + 1, r, gcol, b, al)
	end
end

function draw_custom_scope()
	if not g.scope_enable:GetValue() then return end
	local lp = entities.GetLocalPlayer()
	if not lp then return end
	local alive = false
	pcall(function() alive = lp:IsAlive() end)
	if not alive then return end

	local now = common.Time()
	local dt = math.max(0, math.min(0.1, now - (scope_last_time or now)))
	scope_last_time = now

	local scoped = entity_is_scoped(lp)
	local mode = g.scope_mode:GetValue() -- 0 None, 1 Settings, 2 Separative

	-- None mode hides controls, but must NOT ignore their values.
	-- If user switched to None, use the backup saved at switch time; if no backup exists, use live sliders.
	local none_vals = (mode == 0) and scope_backup or nil
	local use_common_values = (mode == 0 or mode == 1)
	local common_len      = none_vals and none_vals.len      or g.scope_len:GetValue()
	local common_gradient = none_vals and none_vals.gradient or g.scope_gradient:GetValue()
	local common_anim     = none_vals and none_vals.anim     or g.scope_anim:GetValue()
	local common_aspect   = none_vals and none_vals.aspect   or g.scope_aspect:GetValue()
	local common_distance = none_vals and none_vals.distance or g.scope_distance:GetValue()
	local common_thick    = none_vals and none_vals.thick    or g.scope_thick:GetValue()

	local anim_speed = use_common_values and common_anim or 15
	local blend = math.max(0, math.min(1, dt * anim_speed))
	scope_alpha = scope_lerp(scope_alpha or 0, scoped and 1 or 0, blend)
	if scope_alpha < 0.01 then return end

	local target = {
		line_length = use_common_values and common_len or 350,
		gradient = use_common_values and common_gradient or 10,
		aspect = use_common_values and common_aspect or 0,
		thickness = use_common_values and common_thick or 1,
		top = (mode == 2) and g.scope_top_dist:GetValue() or (use_common_values and common_distance or 20),
		bottom = (mode == 2) and g.scope_bottom_dist:GetValue() or (use_common_values and common_distance or 20),
		right = (mode == 2) and g.scope_right_dist:GetValue() or (use_common_values and common_distance or 20),
		left = (mode == 2) and g.scope_left_dist:GetValue() or (use_common_values and common_distance or 20),
	}

	for k, v in pairs(target) do
		scope_current[k] = scope_lerp(scope_current[k] or v, v, blend)
	end

	local sw, sh = draw.GetScreenSize()
	local cx, cy = sw / 2, sh / 2
	local mult = sh / 1080
	local r, gcol, b, a = g.scope_color:GetValue()
	local alpha = a * scope_alpha
	local current = scope_current
	local ar_mult = 1 + ((current.aspect or 0) / 100) * 2
	local line_len = (current.line_length or 350) * mult * scope_alpha
	local v_len = line_len
	local h_len = line_len * ar_mult
	local v_grad = (current.gradient or 10) * mult
	local h_grad = (current.gradient or 10) * mult * ar_mult
	local thick = math.max(0.1, (current.thickness or 1) * mult)
	local top_d = (current.top or 20) * mult * scope_alpha
	local bot_d = (current.bottom or 20) * mult * scope_alpha
	local right_d = (current.right or 20) * mult * scope_alpha * ar_mult
	local left_d = (current.left or 20) * mult * scope_alpha * ar_mult

	draw_scope_vert(cy - top_d, cy - top_d - v_len, cx, thick, v_grad, r, gcol, b, alpha)
	draw_scope_vert(cy + bot_d, cy + bot_d + v_len, cx, thick, v_grad, r, gcol, b, alpha)
	draw_scope_horiz(cx + right_d, cx + right_d + h_len, cy, thick, h_grad, r, gcol, b, alpha)
	draw_scope_horiz(cx - left_d, cx - left_d - h_len, cy, thick, h_grad, r, gcol, b, alpha)
end

function handle_forward()
	local key = g.key_forward:GetValue()
	if key == 0 then return end
	if g.fwd_mode:GetValue() == 1 then -- Hold
		if input.IsButtonDown(key) then
			if manual ~= 3 then manual = 3; switch_tick = globals.TickCount() end
		elseif manual == 3 then
			manual = 0
			switch_tick = globals.TickCount() -- trigger jitter on manual forward off
		end
	else -- Toggle
		handle_key(g.key_forward, 3)
	end
end

-- ============================================================
-- Extracted sub-functions for on_draw (fix >200 locals limit)
-- ============================================================

-- VAC-NET preset toggle + UI lock
local function handle_vacnet()
	local vacnet_on = g.vacnet:GetValue()
	if vacnet_on and not vacnet_was_on then
		vacnet_backup = { base = g.base:GetValue(), conds = {} }
		for i = 1, #g.cond_cfg do
			local c = g.cond_cfg[i]
			vacnet_backup.conds[i] = {
				modifier    = c.modifier:GetValue(),
				mod_3way    = c.mod_3way:GetValue(),
				mod_delay   = c.mod_delay:GetValue(),
				mod_random  = c.mod_random:GetValue(),
				pitch       = c.pitch:GetValue(),
				pitch_value = c.pitch_value:GetValue(),
			}
		end
		g.base:SetValue(1)
		for i = 1, #g.cond_cfg do
			local c = g.cond_cfg[i]
			c.modifier:SetValue(3)
			c.mod_3way:SetValue(55)
			c.mod_delay:SetValue(2)
			c.mod_random:SetValue(false)
			c.pitch:SetValue(5)
			c.pitch_value:SetValue(-45)
		end
		vacnet_was_on = true
	elseif not vacnet_on and vacnet_was_on then
		if vacnet_backup then
			g.base:SetValue(vacnet_backup.base)
			for i = 1, #g.cond_cfg do
				local saved = vacnet_backup.conds[i]
				if saved then
					local c = g.cond_cfg[i]
					c.modifier:SetValue(saved.modifier)
					c.mod_3way:SetValue(saved.mod_3way)
					c.mod_delay:SetValue(saved.mod_delay)
					c.mod_random:SetValue(saved.mod_random)
					c.pitch:SetValue(saved.pitch)
					c.pitch_value:SetValue(saved.pitch_value)
				end
			end
			vacnet_backup = nil
		end
		vacnet_was_on = false
	end
	local vl = g.vacnet:GetValue()
	g.builder_mode:SetDisabled(vl)
	g.base:SetDisabled(vl)
	g.cond:SetDisabled(vl)
	g.defensive_enable:SetDisabled(vl)
	g.roundend_enable:SetDisabled(vl)
end

-- Builder + Defensive + RoundEnd + Scope visibility
local function handle_builder_vis()
	g.builder_mode:SetInvisible(not g.master:GetValue())
	g.defensive_enable:SetInvisible(not (g.master:GetValue() and g.builder_mode:GetValue() == 1))
	g.roundend_enable:SetInvisible(not (g.master:GetValue() and g.builder_mode:GetValue() == 2))

	local bv = g.master:GetValue() and g.builder_mode:GetValue() == 0
	g.base:SetInvisible(not bv)
	g.cond:SetInvisible(not bv)

	local dv = g.master:GetValue() and g.builder_mode:GetValue() == 1 and g.defensive_enable:GetValue()
	g.def_cond:SetInvisible(not dv)
	g.def_tick:SetInvisible(not dv)
	g.build_tick:SetInvisible(not dv)
	g.rand_tick:SetInvisible(not dv)

	local rv = g.master:GetValue() and g.builder_mode:GetValue() == 2 and g.roundend_enable:GetValue()
	g.re_yaw:SetInvisible(not rv)
	g.re_yaw_static:SetInvisible((not rv) or g.re_yaw:GetValue() ~= 1)
	g.re_yaw_spin:SetInvisible((not rv) or g.re_yaw:GetValue() ~= 3)
	g.re_pitch:SetInvisible(not rv)
	g.re_pitch_static:SetInvisible((not rv) or g.re_pitch:GetValue() ~= 2)
	g.re_pitch_dir_from:SetInvisible((not rv) or g.re_pitch:GetValue() ~= 1)
	g.re_pitch_dir_to:SetInvisible((not rv) or g.re_pitch:GetValue() ~= 1)
	g.re_pitch_dir_speed:SetInvisible((not rv) or g.re_pitch:GetValue() ~= 1)

	-- Defensive condition controls
	local di = g.def_cond:GetValue() + 1
	for i = 1, #g.def_cond_cfg do
		local cfg = g.def_cond_cfg[i]
		local act = dv and (i == di)
		local ym = cfg.yaw:GetValue()
		cfg.yaw:SetInvisible(not act)
		cfg.yaw_sideways:SetInvisible((not act) or ym ~= 1)
		cfg.yaw_static:SetInvisible((not act) or ym ~= 2)
		cfg.yaw_dir_from:SetInvisible((not act) or ym ~= 3)
		cfg.yaw_dir_to:SetInvisible((not act) or ym ~= 3)
		cfg.yaw_dir_speed:SetInvisible((not act) or ym ~= 3)
		cfg.yaw_lr_left:SetInvisible((not act) or ym ~= 4)
		cfg.yaw_lr_right:SetInvisible((not act) or ym ~= 4)
		cfg.yaw_lr_delay:SetInvisible((not act) or ym ~= 4)
		cfg.yaw_lr_random:SetInvisible((not act) or ym ~= 4)
		local m = cfg.modifier:GetValue()
		cfg.modifier:SetInvisible(not act)
		cfg.mod_left:SetInvisible((not act) or m ~= 1)
		cfg.mod_right:SetInvisible((not act) or m ~= 1)
		cfg.mod_offset:SetInvisible((not act) or m ~= 2)
		cfg.mod_3way:SetInvisible((not act) or m ~= 3)
		cfg.mod_5way:SetInvisible((not act) or m ~= 4)
		cfg.mod_spin:SetInvisible((not act) or m ~= 5)
		cfg.mod_delay:SetInvisible((not act) or m == 0 or m == 5)
		cfg.mod_random:SetInvisible((not act) or not (m == 3 or m == 4))
		local pm = cfg.pitch:GetValue()
		cfg.pitch:SetInvisible(not act)
		cfg.pitch_value:SetInvisible((not act) or pm ~= 5)
		cfg.pitch_jitter_from:SetInvisible((not act) or pm ~= 3)
		cfg.pitch_jitter_to:SetInvisible((not act) or pm ~= 3)
		cfg.pitch_jitter_delay:SetInvisible((not act) or pm ~= 3)
		cfg.pitch_dir_from:SetInvisible((not act) or pm ~= 6)
		cfg.pitch_dir_to:SetInvisible((not act) or pm ~= 6)
		cfg.pitch_dir_speed:SetInvisible((not act) or pm ~= 6)
	end

	-- Scope mode backup/restore + visibility
	local sm = g.scope_mode:GetValue()
	g.scope_mode:SetInvisible(false)
	if sm ~= scope_saved_mode then
		if sm == 0 and scope_saved_mode ~= -1 then
			scope_backup = {
				len = g.scope_len:GetValue(), gradient = g.scope_gradient:GetValue(),
				anim = g.scope_anim:GetValue(), aspect = g.scope_aspect:GetValue(),
				distance = g.scope_distance:GetValue(), thick = g.scope_thick:GetValue(),
				top = g.scope_top_dist:GetValue(), bottom = g.scope_bottom_dist:GetValue(),
				right = g.scope_right_dist:GetValue(), left = g.scope_left_dist:GetValue(),
			}
		elseif scope_saved_mode == 0 and scope_backup then
			g.scope_len:SetValue(scope_backup.len)
			g.scope_gradient:SetValue(scope_backup.gradient)
			g.scope_anim:SetValue(scope_backup.anim)
			g.scope_aspect:SetValue(scope_backup.aspect)
			g.scope_distance:SetValue(scope_backup.distance)
			g.scope_thick:SetValue(scope_backup.thick)
			g.scope_top_dist:SetValue(scope_backup.top)
			g.scope_bottom_dist:SetValue(scope_backup.bottom)
			g.scope_right_dist:SetValue(scope_backup.right)
			g.scope_left_dist:SetValue(scope_backup.left)
		end
		scope_saved_mode = sm
	end
	g.scope_len:SetInvisible(sm ~= 1)
	g.scope_gradient:SetInvisible(sm ~= 1)
	g.scope_anim:SetInvisible(sm ~= 1)
	g.scope_aspect:SetInvisible(sm ~= 1)
	g.scope_distance:SetInvisible(sm ~= 1)
	g.scope_thick:SetInvisible(sm ~= 1)
	g.scope_top_dist:SetInvisible(sm ~= 2)
	g.scope_bottom_dist:SetInvisible(sm ~= 2)
	g.scope_right_dist:SetInvisible(sm ~= 2)
	g.scope_left_dist:SetInvisible(sm ~= 2)

	-- Builder condition controls + VAC-NET lock
	local si = g.cond:GetValue() + 1
	local vl = g.vacnet:GetValue()
	for i = 1, #g.cond_cfg do
		local cfg = g.cond_cfg[i]
		local act = bv and (i == si)
		if act then
			local yo = cfg.yaw_offset:GetValue()
			if math.abs(yo) <= 1.5 and yo ~= 0 then
				cfg.yaw_offset:SetValue(0)
			end
		end
		local m = cfg.modifier:GetValue()
		cfg.yaw_offset:SetInvisible(not act)
		cfg.modifier:SetInvisible(not act)
		cfg.mod_left:SetInvisible((not act) or m ~= 1)
		cfg.mod_right:SetInvisible((not act) or m ~= 1)
		cfg.mod_offset:SetInvisible((not act) or m ~= 2)
		cfg.mod_3way:SetInvisible((not act) or m ~= 3)
		cfg.mod_5way:SetInvisible((not act) or m ~= 4)
		cfg.mod_spin:SetInvisible((not act) or m ~= 5)
		cfg.mod_delay:SetInvisible((not act) or m == 0 or m == 5 or m == 6)
		cfg.mod_random:SetInvisible((not act) or not (m == 3 or m == 4))
		cfg.pitch:SetInvisible(not act)
		cfg.pitch_value:SetInvisible((not act) or cfg.pitch:GetValue() ~= 5)
		cfg.yaw_offset:SetDisabled(vl)
		cfg.modifier:SetDisabled(vl)
		cfg.mod_left:SetDisabled(vl)
		cfg.mod_right:SetDisabled(vl)
		cfg.mod_offset:SetDisabled(vl)
		cfg.mod_3way:SetDisabled(vl)
		cfg.mod_5way:SetDisabled(vl)
		cfg.mod_spin:SetDisabled(vl)
		cfg.mod_delay:SetDisabled(vl)
		cfg.mod_random:SetDisabled(vl)
		cfg.pitch:SetDisabled(vl)
		cfg.pitch_value:SetDisabled(vl)
	end
end

-- ============================================================
-- paint_indicators — full metasoon-style indicator for Aimware
-- ============================================================
-- Indicator (metasoon-style, draggable, centered)
-- ============================================================
local ind_font = draw.CreateFont("Verdana", 12, 800)

-- drag state (persisted across frames)
local ind_drag_x = 0   -- offset from center
local ind_drag_y = 28  -- offset from center (default: slightly below crosshair)
local ind_dragging = false
local ind_drag_off_x = 0
local ind_drag_off_y = 0

local function paint_indicators()
	if not g.indicator:GetValue() then return end

	local cx = screen_x * 0.5 + ind_drag_x
	local cy = screen_y * 0.5 + ind_drag_y

	local me = entities.GetLocalPlayer()
	local alive = false
	if me then pcall(function() alive = me:IsAlive() end) end

	-- scope offset — shift right when scoped so it clears the scope overlay
	ind_scope_offset = ind_lerp(ind_scope_offset, me and entity_is_scoped(me) and 50 or 0, 0.12)
	cx = cx + ind_scope_offset

	-- DT (real reference, no lerp — instant on/off)
	local dt = false
	if dt_ref then
		pcall(function()
			local v = dt_ref:GetValue()
			dt = (v == true or v == 1 or (type(v) == "number" and v ~= 0))
		end)
	end

	-- DT toggle detect: DT just turned on → start recharge
	if dt and not dt_prev_on then
		dt_fire_time = globals.CurTime()
		dt_recharging = true
	end
	dt_prev_on = dt

	-- Weapon switch detect: active weapon changed → start DT recharge
	if dt then
		local cur_def = active_weapon_def_safe()
		if dt_prev_def ~= nil and cur_def ~= dt_prev_def then
			dt_fire_time = globals.CurTime()
			dt_recharging = true
		end
		dt_prev_def = cur_def
	else
		dt_prev_def = nil
	end

	-- DT recharge check
	if dt_recharging then
		local elapsed = globals.CurTime() - dt_fire_time
		if elapsed >= dt_recharge_time() then
			dt_recharging = false
		end
	end

	-- smooth alpha (only for overall fade, not DT)
	ind_alpha = ind_lerp(ind_alpha, alive and 1 or 0, 0.04)

	draw.SetFont(ind_font)

	local px, py = cx, cy
	local line_gap = 2  -- extra spacing between lines

	-- helper: centered text line, advance py
	local function draw_line(text, cr, cg, cb, ca, alpha)
		if alpha <= 0.01 then return end
		local fa = math.floor(ca * alpha * ind_alpha)
		if fa < 1 then return end
		local tw, th = draw.GetTextSize(text)
		draw.Color(cr, cg, cb, fa)
		draw.TextShadow(math.floor(px - tw * 0.5), py, text)
		py = py + th + line_gap
	end

	-- ── dragging ──
	local start_py = py
	local est_height = 14 + line_gap
	if g.vacnet:GetValue() then est_height = est_height + 14 + line_gap end
	if dt then est_height = est_height + 14 + line_gap end
	est_height = est_height + 14 + line_gap  -- condition
	local md_raw = rawget(_G, "AW_ACTIVE_MIN_DAMAGE")
	if md_raw and md_raw.value then
		local md_cat = md_raw.category or ""
		if (md_cat == "Scout" or md_cat == "Sniper" or md_cat == "Auto Sniper") and md_raw.value <= 30 then
			est_height = est_height + 14 + line_gap
		end
	end

	local box_w = 140
	local box_x1 = px - box_w * 0.5
	local box_y1 = start_py
	local box_x2 = px + box_w * 0.5
	local box_y2 = start_py + est_height

	local mx, my = input.GetMousePos()
	local lmb = input.IsButtonDown(1)

	if ind_dragging then
		if lmb then
			ind_drag_x = mx - ind_drag_off_x
			ind_drag_y = my - ind_drag_off_y

			-- snap to center (8px threshold like metasoon)
			if math.abs(ind_drag_x) < 8 then ind_drag_x = 0 end
			if math.abs(ind_drag_y) < 8 then ind_drag_y = 0 end

			-- ── metasoon grid while dragging ──
			local igcx = math.floor(screen_x * 0.5)
			local igcy = math.floor(screen_y * 0.5)

			-- vertical line
			draw.Color(255, 255, 255, 75)
			draw.FilledRect(igcx, 0, igcx + 1, screen_y)

			-- horizontal line
			draw.FilledRect(0, igcy, screen_x, igcy + 1)

			-- center dot
			draw.Color(255, 255, 255, 130)
			draw.FilledRect(igcx - 2, igcy - 2, igcx + 3, igcy + 3)
		else
			ind_dragging = false
		end
	else
		if lmb then
			if mx >= box_x1 and mx <= box_x2 and my >= box_y1 and my <= box_y2 then
				ind_dragging = true
				ind_drag_off_x = mx - ind_drag_x
				ind_drag_off_y = my - ind_drag_y
			end
		end
	end

	-- ── draw lines ──

	-- banner (metasoon: px-1 offset, centered)
	local banner = "METASOON"
	local bw, bh = draw.GetTextSize(banner)
	draw.Color(210, 210, 210, math.floor(255 * ind_alpha))
	draw.TextShadow(math.floor(px - bw * 0.5) - 1, py, banner)
	py = py + bh + line_gap

	-- VAC-NET badge
	if g.vacnet:GetValue() then
		draw_line("VAC-NET ACTIVE", 255, 60, 60, 255, 1)
	end

	if blockbot_target then
		draw_line("BLOCKBOT", 210, 210, 210, 255, 1)
	end

	-- indicator
	local cond = "STANDING"

	if alive then
		cond = ind_get_condition()
	end
	draw_line("-" .. cond .. "-", 255, 255, 255, 255, 1)

	-- DT line — instant, no fade
	if dt then
		if dt_recharging then
			local remaining = dt_recharge_time() - (globals.CurTime() - dt_fire_time)
			if remaining < 0 then remaining = 0 end
			draw_line("DT RECHARGING " .. string.format("%.1f", remaining) .. "s", 255, 64, 64, 255, 1)
		else
			draw_line("DT READY", 192, 255, 109, 255, 1)
		end
	end

	-- MD — shows when min damage is LOW on sniper weapons (override active)
	local md_raw = rawget(_G, "AW_ACTIVE_MIN_DAMAGE")
	if md_raw and md_raw.value then
		local md_val = md_raw.value
		local md_cat = md_raw.category or ""
		-- Only snipers: Scout, Sniper (AWP), Auto Sniper
		if md_cat == "Scout" or md_cat == "Sniper" or md_cat == "Auto Sniper" then
			if md_val <= 30 then
				draw_line("MD", 192, 255, 109, 255, 1)
			end
		end
	end
end

-- ============================================================
-- on_draw — main draw callback (refactored to fix >200 locals)
-- ============================================================
function on_draw()
	-- viewmodel easing
	local tx, ty, tz = g.vm_x:GetValue(), g.vm_y:GetValue(), g.vm_z:GetValue()
	local s = 0.15
	vm_cur_x = vm_cur_x + (tx - vm_cur_x) * s
	vm_cur_y = vm_cur_y + (ty - vm_cur_y) * s
	vm_cur_z = vm_cur_z + (tz - vm_cur_z) * s
	VM.set(true, vm_cur_x, vm_cur_y, vm_cur_z)

	draw_custom_scope()
	draw_screen_logs()
	rg_sync()
	pcall(function() AK.sync(g.anti_kick:GetValue()) end)

	-- Buy Bot visibility
	local bb_on = g.buybot_enable:GetValue()
	g.buybot_primary:SetInvisible(not bb_on)
	g.buybot_secondary:SetInvisible(not bb_on)
	g.buybot_utils:SetInvisible(not bb_on)

	-- Blockbot visibility
	g.blockbot_key:SetInvisible(not g.blockbot_enable:GetValue())

	-- Builder + scope + VAC-NET visibility
	handle_builder_vis()
	handle_vacnet()

	-- Duck Peek
	local dk = g.duck_peek:GetValue()
	if dk == 0 and native_duck then pcall(function() dk = native_duck:GetValue() end) end
	duck_active = type(dk) == "number" and dk ~= 0 and input.IsButtonDown(dk)

	local dlp = entities.GetLocalPlayer()
	local alive = false
	if dlp then pcall(function() alive = dlp:IsAlive() end) end
	duck_can_peek = false
	if alive and weapon_class(dlp) ~= "knife" then
		duck_can_peek = enemy_hittable_standing(dlp)
	end
	if duck_can_peek then
		if duck_peek_since == 0 then duck_peek_since = globals.TickCount() end
	else
		duck_peek_since = 0
	end

	if not g.master:GetValue() then return end

	-- manual direction toggles
	handle_key(g.key_right, 1)
	handle_key(g.key_left, 2)
	handle_forward()

	-- indicators
	paint_indicators()
end

-- duck peek re-crouch logic (no hitlog UI):
--   our shot           -> re-crouch ~1.5s (miss / hit-without-kill both count)
--   our shot kills      -> clear the cooldown (no need to hide, peek the next one)
function on_event(event)
	local name = event:GetName()
	pcall(function() vote_on_event(event) end)
	pcall(function() logs_on_event(event) end)
	-- Buy Bot: счётчик раундов + покупка
	if name == "round_start" then
		round_ended = false
		pcall(buybot_round_inc)
		pcall(buybot_exec)
	elseif name == "round_prestart" or name == "round_freeze_end" then
		pcall(buybot_exec)
	elseif name == "announce_phase_end" or name == "cs_game_disconnected" or name == "game_newmap" then
		buybot_round = 0; buybot_died_early = false
	end
	if name == "round_end" then round_ended = true end

	if name == "weapon_fire" then
		local ok = pcall(function()
			local uid = event:GetInt("userid")
			if client.GetPlayerIndexByUserID(uid) == client.GetLocalPlayerIndex() then
				duck_fire_tick = globals.TickCount()
				duck_cd_until  = globals.TickCount() + DUCK_COOLDOWN_TICKS
				anti_nix_last_shot_tick = globals.TickCount()
				as_pause(AIR_STOP_SHOT_DELAY)
			end
		end)
		if not ok then
			duck_fire_tick = globals.TickCount()
			duck_cd_until  = globals.TickCount() + DUCK_COOLDOWN_TICKS
			anti_nix_last_shot_tick = globals.TickCount()
			as_pause(AIR_STOP_SHOT_DELAY)
		end
		-- DT recharge: fired a shot with DT on → start cooldown
		if duck_fire_tick == globals.TickCount() and dt_ref then
			local dt_on = false
			pcall(function()
				local v = dt_ref:GetValue()
				dt_on = (v == true or v == 1 or (type(v) == "number" and v ~= 0))
			end)
			if dt_on then
				dt_fire_time = globals.CurTime()
				dt_recharging = true
			end
		end
	elseif name == "player_hurt" then
		pcall(function()
			local by_me = client.GetPlayerIndexByUserID(event:GetInt("attacker")) == client.GetLocalPlayerIndex()
			if by_me and event:GetInt("health") <= 0 then
				duck_cd_until = 0 -- killed → can peek next
				as_pause(AIR_STOP_KILL_DELAY)
				-- сбрасываем At Target если убили текущего таргета
				local victim_idx = client.GetPlayerIndexByUserID(event:GetInt("userid"))
				if last_target then
					local target_idx = nil
					pcall(function() target_idx = last_target:GetIndex() end)
					if target_idx and target_idx == victim_idx then
						last_target   = nil
						last_target_p = nil
						last_target_t = -1000
						aa_target_ent = nil
					end
				end
			end
		end)
	elseif name == "player_death" then
		-- Buy Bot: если нас убили на 1-2 раунде → эко
		pcall(function()
			local victim_idx = client.GetPlayerIndexByUserID(event:GetInt("userid"))
			local attacker_idx = client.GetPlayerIndexByUserID(event:GetInt("attacker"))
			local local_idx  = client.GetLocalPlayerIndex()
			if victim_idx == local_idx then buybot_on_death() end
			if victim_idx == local_idx or attacker_idx == local_idx then as_pause(AIR_STOP_KILL_DELAY) end
		end)
		-- мгновенный сброс At Target при смерти любого врага
		pcall(function()
			local victim_idx = client.GetPlayerIndexByUserID(event:GetInt("userid"))
			local local_idx  = client.GetLocalPlayerIndex()
			if victim_idx ~= local_idx and last_target then
				local target_idx = nil
				pcall(function() target_idx = last_target:GetIndex() end)
				if target_idx and target_idx == victim_idx then
					last_target   = nil
					last_target_p = nil
					last_target_t = -1000
					aa_target_ent = nil
				end
			end
		end)
	elseif name == "round_start" or name == "round_prestart" then
		-- сброс всех таргетов при начале раунда
		last_target   = nil
		last_target_p = nil
		last_target_t = -1000
		aa_target_ent = nil
		target_count  = 0
		esp_targets   = {}
		esp_frame     = {}
	end
end
pcall(function() client.AllowListener("weapon_fire") end)
pcall(function() client.AllowListener("player_hurt") end)
pcall(function() client.AllowListener("player_death") end)
pcall(function() client.AllowListener("round_start") end)
pcall(function() client.AllowListener("round_end") end)
pcall(function() client.AllowListener("round_prestart") end)
pcall(function() client.AllowListener("vote_started") end)
pcall(function() client.AllowListener("vote_begin") end)
pcall(function() client.AllowListener("vote_cast") end)

-- ============================================================
-- callbacks
-- ============================================================
callbacks.Register("PreMove", "aa_premove", pre_move)
callbacks.Register("Draw", "aa_draw", on_draw)
callbacks.Register("DrawESP", "aa_esp", on_draw_esp)
callbacks.Register("FireGameEvent", "aa_event", on_event)
callbacks.Register("Unload", "aa_air_stop_unload", function()
	pcall(function() if AK and AK.enabled then AK.sync(false) end end)
	as_auto_restore()
	as_release(false)
end)

-- ============================================================
-- Unload: чистим всё при выгрузке скрипта
-- ============================================================
callbacks.Register("Unload", "osnova_aa_unload", function()
    pcall(function() callbacks.Unregister("PreMove", "aa_premove") end)
    pcall(function() callbacks.Unregister("Draw", "aa_draw") end)
    pcall(function() callbacks.Unregister("DrawESP", "aa_esp") end)
    pcall(function() callbacks.Unregister("FireGameEvent", "aa_event") end)
    pcall(function() callbacks.Unregister("Unload", "aa_air_stop_unload") end)
    pcall(function() callbacks.Unregister("Unload", "osnova_aa_unload") end)

    -- Снимаем VM hook
    local VM = rawget(_G, "VM")
    if VM and VM.uninstall then pcall(VM.uninstall) end

    -- Отключаем AK
    local AK = rawget(_G, "AK")
    if AK and AK.enabled and AK.sync then pcall(AK.sync, false) end

    -- Снимаем RG hook
    local RG = rawget(_G, "RG")
    if RG and RG.uninstall then pcall(RG.uninstall) end

    _G.__AA = nil
    _G.g = nil
    _G.AK = nil
    _G.RG = nil
    _G.VM = nil
    _G.VB = nil

    print("[osnova] AA Builder unloaded and cleaned")
end)

