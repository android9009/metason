-- ============================================================
-- Combined Lua: Silent Skin Changer + Anti-Aim Builder
-- Generated merge
-- ============================================================

-- ============================================================
-- Silent Skin Changer
-- ============================================================
do
local ffi  = ffi
local band, rshift, bxor, lshift = bit.band, bit.rshift, bit.bxor, bit.lshift
local floor = math.floor

local off = {}

local DUMPER = "https://raw.githubusercontent.com/a2x/cs2-dumper/main/output/"

local FIELDS = {
    m_pWeaponServices      = "m_pWeaponServices",
    m_hMyWeapons           = "m_hMyWeapons",
    m_hActiveWeapon        = "m_hActiveWeapon",
    m_AttributeManager     = { "m_AttributeManager", "C_EconEntity" },
    m_Item                 = "m_Item",
    m_pGameSceneNode       = "m_pGameSceneNode",
    m_modelState           = { "m_modelState", "CSkeletonInstance" },
    m_hModel               = { "m_hModel", "CModelState" },
    m_nSubclassID          = "m_nSubclassID",
    m_iTeamNum             = "m_iTeamNum",
    m_iHealth              = "m_iHealth",
    m_lifeState            = "m_lifeState",
    m_hOwnerEntity         = "m_hOwnerEntity",
    m_hPlayerPawn          = "m_hPlayerPawn",
    m_steamID              = "m_steamID",
    m_iItemDefinitionIndex = "m_iItemDefinitionIndex",
    m_bRestoreCustomMat    = "m_bRestoreCustomMaterialAfterPrecache",
    m_iEntityQuality       = "m_iEntityQuality",
    m_iItemIDLow           = "m_iItemIDLow",
    m_iItemIDHigh          = "m_iItemIDHigh",
    m_iAccountID           = "m_iAccountID",
    m_OriginalOwnerXuidLow = { "m_OriginalOwnerXuidLow", "C_EconEntity" },
    m_bInitialized         = "m_bInitialized",
    m_bDisallowSOC         = "m_bDisallowSOC",
    m_AttributeList        = "m_AttributeList",
    m_Attributes           = "m_Attributes",
    m_nFallbackPaintKit    = { "m_nFallbackPaintKit", "C_EconEntity" },
    m_nFallbackSeed        = { "m_nFallbackSeed", "C_EconEntity" },
    m_flFallbackWear       = { "m_flFallbackWear", "C_EconEntity" },
    m_nFallbackStatTrak    = { "m_nFallbackStatTrak", "C_EconEntity" },
    m_EconGloves           = { "m_EconGloves", "C_CSPlayerPawn" },
    m_bNeedToReApplyGloves = { "m_bNeedToReApplyGloves", "C_CSPlayerPawn" },

}
local function pull_offset(j, name, after)
    local init = 1

    if after then local p = j:find('"' .. after .. '"%s*:%s*{'); if p then init = p end end
    local v = j:match('"' .. name .. '"%s*:%s*(%d+)', init)
    return v and tonumber(v) or nil
end
pcall(function()
    local j = http.Get(DUMPER .. "client_dll.json")
    if type(j) ~= "string" then return end
    for key, spec in pairs(FIELDS) do
        local name, after = spec, nil
        if type(spec) == "table" then name, after = spec[1], spec[2] end
        local v = pull_offset(j, name, after)
        if v then off[key] = v end
    end
end)
off.m_szWorldModel = 48
off.m_modelState = off.m_modelState or 336
off.m_hModel     = off.m_hModel     or 160

local function r_u8 (a) return ffi.cast("uint8_t*",  a)[0] end
local function r_u16(a) return ffi.cast("uint16_t*", a)[0] end
local function r_i32(a) return ffi.cast("int32_t*",  a)[0] end
local function r_u32(a) return ffi.cast("uint32_t*", a)[0] end
local function r_u64(a) return ffi.cast("uint64_t*", a)[0] end
local function r_ptr(a) return tonumber(ffi.cast("uint64_t*", a)[0]) end
local function w_u8 (a,v) ffi.cast("uint8_t*",  a)[0]=v end
local function w_u16(a,v) ffi.cast("uint16_t*", a)[0]=v end
local function w_i32(a,v) ffi.cast("int32_t*",  a)[0]=v end
local function w_u32(a,v) ffi.cast("uint32_t*", a)[0]=v end
local function w_u64(a,v) ffi.cast("uint64_t*", a)[0]=v end
local function w_f32(a,v) ffi.cast("float*",    a)[0]=v end
local function valid(p) return p ~= nil and p > 0x10000 and p < 0x7FFFFFFFFFFF end
local function read_cstr(a, max)
    if not valid(a) then return "" end
    local t = {}
    for i = 0, (max or 160) - 1 do
        local c = r_u8(a + i); if c == 0 then break end
        t[#t+1] = string.char(c)
    end
    return table.concat(t)
end

local function sig_rva(modBase, mod, pattern, instrLen)
    if not modBase then return nil end
    local a = mem.FindPattern(mod, pattern); if not a or a == 0 then return nil end
    a = tonumber(a)
    return (a + instrLen + r_i32(a + 3)) - modBase
end
local function sig_disp(mod, pattern)
    local a = mem.FindPattern(mod, pattern); if not a or a == 0 then return nil end
    return r_i32(tonumber(a) + 3)
end
do
    local cb = mem.GetModuleBase("client.dll")
    local eb = mem.GetModuleBase("engine2.dll")
    off.dwEntityList            = sig_rva(cb, "client.dll",  "48 89 0D ?? ?? ?? ?? E9 ?? ?? ?? ?? CC", 7)
    off.dwLocalPlayerController = sig_rva(cb, "client.dll",  "48 8B 05 ?? ?? ?? ?? 41 89 BE", 7)
    off.dwNetworkGameClient     = sig_rva(eb, "engine2.dll", "48 89 3D ?? ?? ?? ?? FF 87", 7)
    off.dwNetworkGameClient_signOnState = sig_disp("engine2.dll", "44 8B 81 ?? ?? ?? ?? 48 8D 0D")
    if not off.dwLocalPlayerController or not off.dwEntityList or not off.m_hMyWeapons then
        -- silent
    else
        -- silent
    end
end

local function tou32(x) x = x % 0x100000000; if x < 0 then x = x + 0x100000000 end; return x end
local function mul32(a, b)
    a = a % 0x100000000; b = b % 0x100000000
    local ah, al = floor(a/0x10000), a%0x10000
    local bh = floor(b/0x10000)
    return (al*(b%0x10000) + ((al*bh + ah*(b%0x10000)) % 0x10000)*0x10000) % 0x100000000
end
local MM = 0x5bd1e995
local function murmur2(str, seed)
    local len = #str
    local h = tou32(bxor(seed, len))
    local i, rem = 1, len
    while rem >= 4 do
        local b0,b1,b2,b3 = str:byte(i, i+3)
        local k = b0 + b1*256 + b2*65536 + b3*16777216
        k = mul32(k, MM); k = tou32(bxor(k, rshift(k, 24))); k = mul32(k, MM)
        h = mul32(h, MM); h = tou32(bxor(h, k))
        i = i + 4; rem = rem - 4
    end
    if rem >= 3 then h = tou32(bxor(h, lshift(str:byte(i+2), 16))) end
    if rem >= 2 then h = tou32(bxor(h, lshift(str:byte(i+1), 8))) end
    if rem >= 1 then h = tou32(bxor(h, str:byte(i))); h = mul32(h, MM) end
    h = tou32(bxor(h, rshift(h, 13))); h = mul32(h, MM); h = tou32(bxor(h, rshift(h, 15)))
    return h
end
local function subclass_hash(def) return murmur2(tostring(def):lower(), 0x31415926) end

local DLL = "client.dll"
-- client.dll 
local sig = {
    set_model      = "40 53 48 83 EC ?? 48 8B D9 4C 8B C2 48 8B 0D ?? ?? ?? ?? 48 8D 54 24 40",  -- CBaseModelEntity::SetModel
    update_subclass= "4C 8B DC 53 48 81 EC ?? ?? ?? ?? 48 8B 41",                                 -- CEconItemView subclass refresh
    set_mesh_mask  = "48 89 5C 24 ?? 48 89 74 24 ?? 57 48 83 EC ?? 48 8D 99 ?? ?? ?? ?? 48 8B 71", -- CSkeletonInstance mesh mask
    regen_skins    = "48 83 EC ?? E8 ?? ?? ?? ?? 48 85 C0 0F 84 ?? ?? ?? ?? 48 8B 10",            -- regenerate custom skins
}
-- a + 5 + rel32 -> CBodyComponent::SetBodyGroup
local SBG_SIG = "E8 ?? ?? ?? ?? EB 0C 48 8B CF"
local fn, fnptr = {}, {}
local function resolve()
    for name, pattern in pairs(sig) do
        if not fn[name] then local a = mem.FindPattern(DLL, pattern); if a and a ~= 0 then fn[name] = a end end
    end
    if not fn.set_body_group then
        local a = mem.FindPattern(DLL, SBG_SIG)
        if a and a ~= 0 then fn.set_body_group = a + 5 + r_i32(a + 1) end
    end
    if fn.set_model       and not fnptr.set_model       then fnptr.set_model       = ffi.cast("void(*)(void*, const char*)", fn.set_model) end
    if fn.update_subclass and not fnptr.update_subclass then fnptr.update_subclass = ffi.cast("void(*)(void*)",              fn.update_subclass) end
    if fn.set_mesh_mask   and not fnptr.set_mesh_mask   then fnptr.set_mesh_mask   = ffi.cast("void(*)(void*, uint64_t)",    fn.set_mesh_mask) end
    if fn.regen_skins     and not fnptr.regen_skins     then fnptr.regen_skins     = ffi.cast("void(*)(void)",               fn.regen_skins) end
    if fn.set_body_group  and not fnptr.set_body_group  then fnptr.set_body_group  = ffi.cast("void(*)(void*, const char*, unsigned int)", fn.set_body_group) end
end
local function vfunc(this, index)
    if not valid(this) then return nil end
    local vt = r_ptr(this); if not valid(vt) then return nil end
    local f = r_ptr(vt + index*8); if not valid(f) then return nil end
    return f
end
local function vcall_void(this, index)
    local f = vfunc(this, index); if not f then return end
    ffi.cast("void(*)(void*)", f)(ffi.cast("void*", this))
end
local function vcall_void_bool(this, index, b)
    local f = vfunc(this, index); if not f then return end
    ffi.cast("void(*)(void*, int)", f)(ffi.cast("void*", this), b and 1 or 0)
end

local KNIVES = {
    { name = "Default (no swap)", def = nil },
    { name = "Bayonet",        def = 500 }, { name = "Classic Knife",  def = 503 },
    { name = "Flip Knife",     def = 505 }, { name = "Gut Knife",      def = 506 },
    { name = "Karambit",       def = 507 }, { name = "M9 Bayonet",     def = 508 },
    { name = "Huntsman",       def = 509 }, { name = "Falchion",       def = 512 },
    { name = "Bowie Knife",    def = 514 }, { name = "Butterfly",      def = 515 },
    { name = "Shadow Daggers", def = 516 }, { name = "Paracord Knife", def = 517 },
    { name = "Survival Knife", def = 518 }, { name = "Ursus Knife",    def = 519 },
    { name = "Navaja Knife",   def = 520 }, { name = "Nomad Knife",    def = 521 },
    { name = "Stiletto",       def = 522 }, { name = "Talon Knife",    def = 523 },
    { name = "Skeleton Knife", def = 525 }, { name = "Kukri Knife",    def = 526 },
}
local WEAPONS = {
    { name = "AK-47",        def = 7  }, { name = "M4A4",         def = 16 },
    { name = "M4A1-S",       def = 60 }, { name = "AWP",          def = 9  },
    { name = "SSG 08",       def = 40 }, { name = "SCAR-20",      def = 38 },
    { name = "G3SG1",        def = 11 }, { name = "SG 553",       def = 39 },
    { name = "AUG",          def = 8  }, { name = "FAMAS",        def = 10 },
    { name = "Galil AR",     def = 13 }, { name = "Desert Eagle", def = 1  },
    { name = "R8 Revolver",  def = 64 }, { name = "Dual Berettas",def = 2  },
    { name = "Five-SeveN",   def = 3  }, { name = "Glock-18",     def = 4  },
    { name = "Tec-9",        def = 30 }, { name = "P2000",        def = 32 },
    { name = "P250",         def = 36 }, { name = "USP-S",        def = 61 },
    { name = "CZ75-Auto",    def = 63 }, { name = "MAC-10",       def = 17 },
    { name = "P90",          def = 19 }, { name = "PP-Bizon",     def = 26 },
    { name = "MP5-SD",       def = 23 }, { name = "MP7",          def = 33 },
    { name = "MP9",          def = 34 }, { name = "UMP-45",       def = 24 },
    { name = "M249",         def = 14 }, { name = "Negev",        def = 28 },
    { name = "XM1014",       def = 25 }, { name = "MAG-7",        def = 27 },
    { name = "Nova",         def = 35 }, { name = "Sawed-Off",    def = 29 },
}
local GLOVES = {
    { name = "Default (off)",      def = 0    },
    { name = "Bloodhound Gloves",  def = 5027 }, { name = "Sport Gloves",      def = 5030 },
    { name = "Driver Gloves",      def = 5031 }, { name = "Hand Wraps",        def = 5032 },
    { name = "Moto Gloves",        def = 5033 }, { name = "Specialist Gloves", def = 5034 },
    { name = "Hydra Gloves",       def = 5035 }, { name = "Broken Fang Gloves",def = 4725 },
}
local function is_knife(def) return def == 42 or def == 59 or (def >= 500 and def <= 526) end

local SKINS = {
  [1]={{"Blaze",37},{"Blue Ply",945},{"Bronze Deco",425},{"Calligraffiti",114},{"Cobalt Disruption",231},{"Code Red",711},{"Conspiracy",351},{"Corinthian",509},{"Crimson Web",232},{"Directive",603},{"Emerald JГ¶rmungandr",757},{"Fennec Fox",764},{"Firebreathing",1430},{"Golden Koi",185},{"Hand Cannon",328},{"Heat Treated",1054},{"Heirloom",273},{"Hypnotic",61},{"Kumicho Dragon",527},{"Light Rail",841},{"Mecha Industries",805},{"Meteorite",296},{"Midnight Storm",468},{"Mint Fan",1257},{"Mudder",90},{"Mulberry",1318},{"Naga",397},{"Night",40},{"Night Heist",1006},{"Ocean Drive",1090},{"Oxide Blaze",645},{"Pilot",347},{"Printstream",962},{"Serpent Strike",1189},{"Sputnik",1056},{"Starcade",938},{"Sunset Storm еЈ±",469},{"Sunset Storm ејђ",470},{"The Bronze",992},{"The Daily Deagle",1360},{"Tilted",138},{"Trigger Discipline",1050},{"Urban DDPAT",17},{"Urban Rubble",237}},
  [2]={{"Angel Eyes",1347},{"Anodized Navy",28},{"Balance",895},{"Black Limba",190},{"BorDeux",1335},{"Briar",330},{"Cartel",528},{"Cobalt Quartz",249},{"Cobra Strike",658},{"Colony",47},{"Contractor",46},{"Demolition",153},{"Dezastre",978},{"Drift Wood",824},{"Dualing Dragons",491},{"Duelist",447},{"Elite 1.6",903},{"Emerald",453},{"Flora Carnivora",1156},{"Heist",1005},{"Hemoglobin",220},{"Hideout",1169},{"Hydro Strike",112},{"Marina",261},{"Melondrama",1126},{"Moon in Libra",450},{"Oil Change",1086},{"Panther",276},{"Polished Malachite",1290},{"Pyre",860},{"Retribution",307},{"Rose Nacre",1263},{"Royal Consorts",625},{"Shred",710},{"Silver Pour",1373},{"Stained",43},{"Sweet Little Angels",139},{"Switch Board",998},{"Tread",1091},{"Twin Turbo",747},{"Urban Shock",396},{"Ventilators",544}},
  [3]={{"Angry Mob",837},{"Anodized Gunmetal",210},{"Autumn Thicket",1336},{"Berries And Cherries",1002},{"Boost Protocol",1093},{"Buddy",906},{"Candy Apple",3},{"Capillary",646},{"Case Hardened",44},{"Contractor",46},{"Coolant",784},{"Copper Galaxy",274},{"Crimson Blossom",729},{"Dark Polymer",1429},{"Fairy Tale",979},{"Fall Hazard",1082},{"Flame Test",693},{"Forest Night",78},{"Fowl Play",352},{"Fraise Crane",1380},{"Heat Treated",831},{"Hot Shot",377},{"Hybrid",1168},{"Hyper Beast",660},{"Jungle",151},{"Kami",265},{"Midnight Paintover",1062},{"Monkey Business",427},{"Neon Kimono",464},{"Nightshade",223},{"Nitro",254},{"Orange Peel",141},{"Retrobution",510},{"Scrawl",1128},{"Scumbria",605},{"Silver Quartz",252},{"Sky Blue",1262},{"Triumvirate",530},{"Urban Hazard",387},{"Violent Daimyo",585},{"Withered Vine",932}},
  [4]={{"AXIA",832},{"Block-18",1167},{"Blue Fissure",278},{"Brass",159},{"Bullet Queen",957},{"Bunsen Burner",479},{"Candy Apple",3},{"Catacombs",399},{"Clear Polymer",1039},{"Coral Bloom",1312},{"Death Rattle",293},{"Dragon Tattoo",48},{"Fade",38},{"Franklin",1016},{"Fully Tuned",1421},{"Gamma Doppler",1119},{"Gamma Doppler",1120},{"Gamma Doppler",1121},{"Gamma Doppler",1122},{"Gamma Doppler",1123},{"Glockingbird",1282},{"Gold Toof",129},{"Green Line",1200},{"Grinder",381},{"Groundwater",2},{"High Beam",799},{"Ironwork",623},{"Mirror Mosaic",1348},{"Moonrise",694},{"Neo-Noir",988},{"Night",40},{"Nuclear Garden",789},{"Ocean Topo",1265},{"Off World",680},{"Oxide Blaze",808},{"Pink DDPAT",84},{"Ramese's Reach",1240},{"Reactor",367},{"Red Tire",1079},{"Royal Legion",532},{"Sacrifice",918},{"Sand Dune",208},{"Shinobu",1208},{"Snack Attack",1100},{"Steel Disruption",230},{"Synth Leaf",732},{"Teal Graf",152},{"Trace Lock",1357},{"Twilight Galaxy",437},{"Umbral Rabbit",1227},{"Vogue",963},{"Warhawk",713},{"Wasteland Rebel",586},{"Water Elemental",353},{"Weasel",607},{"Winterized",1158},{"Wraiths",495}},
  [7]={{"Aphrodite",1397},{"Aquamarine Revenge",474},{"Asiimov",801},{"B the Monster",142},{"Baroque Purple",745},{"Black Laminate",172},{"Bloodsport",639},{"Blue Laminate",226},{"Breakthrough",1358},{"Cartel",394},{"Case Hardened",44},{"Crane Flight",1425},{"Crossfade",912},{"Elite Build",422},{"Emerald Pinstripe",300},{"Fire Serpent",180},{"First Class",341},{"Frontside Misty",490},{"Fuel Injector",524},{"Gold Arabesque",921},{"Green Laminate",1070},{"Head Shot",1221},{"Hydroponic",456},{"Ice Coaled",1143},{"Inheritance",1171},{"Jaguar",316},{"Jet Set",340},{"Jungle Spray",122},{"Leet Museo",1087},{"Legion of Anubis",959},{"Midnight Laminate",1218},{"Neon Revolution",600},{"Neon Rider",707},{"Nightwish",1141},{"Nouveau Rouge",1309},{"Olive Polycam",1179},{"Orbit Mk01",656},{"Panthera onca",1018},{"Phantom Disruptor",941},{"Point Disarray",506},{"Predator",170},{"Rat Rod",885},{"Red Laminate",14},{"Redline",282},{"Safari Mesh",72},{"Safety Net",795},{"Searing Rage",1207},{"Slate",1035},{"Steel Delta",1238},{"The Empress",675},{"The Oligarch",1352},{"The Outsiders",113},{"Uncharted",836},{"VariCamo Grey",1288},{"Vulcan",302},{"Wasteland Rebel",380},{"Wild Lotus",724},{"Wintergreen",1283},{"X-Ray",1004}},
  [8]={{"Akihabara Accept",455},{"Amber Fade",246},{"Amber Slipstream",708},{"Anodized Navy",197},{"Arctic Wolf",886},{"Aristocrat",583},{"Bengal Tiger",9},{"Carved Jade",1033},{"Chameleon",280},{"Colony",47},{"Commando Company",1308},{"Condemned",110},{"Contractor",46},{"Copperhead",10},{"Creep",1362},{"Daedalus",444},{"Death by Puppy",913},{"Eye of Zapems",134},{"Flame JГ¶rmungandr",758},{"Fleet Flock",541},{"Hot Rod",33},{"Lil' Pig",173},{"Luxe Trim",121},{"Midnight Lily",727},{"Momentum",845},{"Navy Murano",740},{"Plague",1088},{"Radiation Hazard",375},{"Random Access",779},{"Ricochet",507},{"Sand Storm",823},{"Snake Pit",1249},{"Spalted Wood",927},{"Steel Sentinel",1198},{"Storm",100},{"Stymphalian",690},{"Surveillance",995},{"Sweeper",794},{"Syd Mead",601},{"Tom Cat",942},{"Torque",305},{"Trigger Discipline",1339},{"Triqua",674},{"Wings",73}},
  [9]={{"Acheron",788},{"Arsenic Spill",1324},{"Asiimov",279},{"Atheris",838},{"Black Nile",1239},{"BOOM",174},{"Capillary",943},{"Chromatic Aberration",1144},{"Chrome Cannon",1170},{"CMYK",163},{"Containment Breach",887},{"Corticera",181},{"Crakow!",137},{"Desert Hydra",819},{"Dragon Lore",344},{"Duality",1222},{"Electric Hive",227},{"Elite Build",525},{"Exoskeleton",975},{"Exothermic",1378},{"Fade",1026},{"Fever Dream",640},{"Graphite",212},{"Green Energy",1280},{"Gungnir",756},{"Hyper Beast",475},{"Ice Coaled",1346},{"Lightning Strike",51},{"LongDog",1213},{"Man-o'-war",395},{"Medusa",446},{"Mortis",691},{"Neo-Noir",803},{"Oni Taiji",662},{"PAW",718},{"Phobos",584},{"Pink DDPAT",84},{"Pit Viper",251},{"POP AWP",1058},{"Printstream",1206},{"Queen's Gambit",1422},{"Redline",259},{"Safari Mesh",72},{"Silk Tiger",1029},{"Snake Camo",30},{"Sun in Leo",451},{"The End",1356},{"The Prince",736},{"Wildfire",917},{"Worm God",424}},
  [10]={{"2A2F",1202},{"Afterimage",154},{"Bad Trip",1184},{"Byproduct",1393},{"CaliCamo",240},{"Colony",47},{"Commemoration",919},{"Contrast Spray",22},{"Crypsis",835},{"Cyanospatter",92},{"Dark Water",60},{"Decommissioned",904},{"Djinn",429},{"Doomkitty",178},{"Eye of Athena",723},{"Faulty Wiring",1066},{"Grey Ghost",1321},{"Half Sleeve",461},{"Halftone Wash",882},{"Hexane",218},{"Macabre",659},{"Mecha Industries",626},{"Meltdown",1053},{"Meow 36",1146},{"Neural Net",477},{"Night Borre",863},{"Palm",1302},{"Prime Conspiracy",999},{"Pulse",260},{"Rapid Eye Movement",1127},{"Roll Cage",604},{"Sergeant",288},{"Spitfire",194},{"Styx",371},{"Sundown",869},{"Survivor Z",492},{"Teardown",244},{"Valence",529},{"Vendetta",1365},{"Waters of Nephthys",1241},{"Yeti Camo",1219},{"ZX Spectron",1092}},
  [11]={{"Ancient Ritual",1034},{"Arctic Camo",6},{"Azure Zebra",229},{"Black Sand",891},{"Chronos",438},{"Contractor",46},{"Demeter",195},{"Desert Storm",8},{"Digital Mesh",980},{"Dream Glade",1129},{"Flux",493},{"Green Apple",294},{"Green Cell",1305},{"High Seas",712},{"Hunter",677},{"Jungle Dashed",147},{"Keeping Tabs",1095},{"Murky",382},{"New Roots",930},{"Orange Crash",545},{"Orange Kimono",465},{"Polar Camo",74},{"Red Jasper",1328},{"Safari Mesh",72},{"Scavenger",806},{"Stinger",628},{"The Executioner",511},{"VariCamo",235},{"Ventilator",606},{"Violet Murano",739}},
  [13]={{"Acid Dart",1296},{"Akoben",842},{"Amber Fade",246},{"Aqua Terrace",460},{"Black Sand",629},{"Blue Titanium",216},{"CAUTION!",1071},{"Cerberus",379},{"Chatterbox",398},{"Chromatic Aberration",1038},{"Cold Fusion",790},{"Connexion",972},{"Control",1185},{"Crimson Tsunami",647},{"Destroyer",1147},{"Dusk Ruins",1032},{"Eco",428},{"Firefight",546},{"Galigator",1434},{"Green Apple",294},{"Grey Smoke",1275},{"Hunting Blind",241},{"Kami",308},{"Metallic Squeezer",239},{"NV",939},{"O-Ranger",1314},{"Orange DDPAT",83},{"Phoenix Blacklight",1013},{"Rainbow Spoon",1178},{"Robin's Egg",1264},{"Rocket Pop",478},{"Sage Spray",119},{"Sandstorm",264},{"Shattered",192},{"Signal",807},{"Sky Mandala",1383},{"Stone Cold",494},{"Sugar Rush",661},{"Tornado",101},{"Tuxedo",297},{"Urban Rubble",237},{"Vandal",981},{"VariCamo",235},{"Winter Forest",76}},
  [14]={{"Aztec",902},{"Blizzard Marbleized",75},{"Bock Blocks",1435},{"Contrast Spray",22},{"Deep Relief",983},{"Downtown",1148},{"Emerald Poison Dart",648},{"Gator Mesh",243},{"Humidor",827},{"Hypnosis",120},{"Impact Drill",472},{"Jungle",151},{"Jungle DDPAT",202},{"Magma",266},{"Midnight Palm",933},{"Nebula Crusader",496},{"O.S.I.P.R.",1042},{"Predator",170},{"Sage Camo",1298},{"Shipping Forecast",452},{"Sleet",1370},{"Spectre",547},{"Spectrogram",875},{"Submerged",1242},{"System Lock",401},{"Warbird",900}},
  [16]={{"Aeolian Dark",1364},{"Asiimov",255},{"Bullet Rain",155},{"Buzz Kill",632},{"Choppa",1210},{"Converter",793},{"Cyber Security",985},{"Dark Blossom",730},{"Daybreak",471},{"Desert Storm",8},{"Desert-Strike",336},{"Desolate Space",588},{"Etch Lord",1165},{"Evil Daimyo",480},{"Eye of Horus",1255},{"Faded Zebra",176},{"Full Throttle",1353},{"Global Offensive",993},{"Griffin",384},{"Hellfire",664},{"Hellish",1209},{"Howl",309},{"In Living Color",1041},{"Jungle Tiger",16},{"Magnesium",811},{"Mainframe",780},{"Modern Hunter",164},{"Naval Shred Camo",1266},{"Neo-Noir",695},{"Poly Mag",1149},{"Polysoup",874},{"Poseidon",449},{"Radiation Hazard",167},{"Red DDPAT",926},{"Royal Paladin",512},{"Sheet Lightning",1281},{"Spider Lily",1097},{"Steel Work",1313},{"Temukau",1228},{"The Battlestar",533},{"The Coalition",1063},{"The Emperor",844},{"Tooth Fairy",971},{"Tornado",101},{"Turbine",118},{"Urban DDPAT",17},{"X-Ray",215},{"Zirka",187},{"Zubastick",1432},{"йѕЌзЋ‹ (Dragon King)",400}},
  [17]={{"Acid Hex",1295},{"Allure",965},{"Aloha",665},{"Amber Fade",246},{"Bronzer",1334},{"Button Masher",1045},{"Calf Skin",748},{"Candy Apple",3},{"Carnivore",589},{"Case Hardened",44},{"Cat Fight",1349},{"Classic Crate",908},{"Commuter",343},{"Copper Borre",761},{"Curse",310},{"Derailment",1204},{"Disco Tech",947},{"Echoing Sands",1244},{"Ensnared",1131},{"Fade",38},{"Gold Brick",1025},{"Graven",188},{"Heat",284},{"Hot Snakes",1009},{"Indigo",333},{"Lapis Gator",534},{"Last Dive",651},{"Light Box",1164},{"Malachite",402},{"Monkeyflage",1150},{"Neon Rider",433},{"Nuclear Garden",372},{"Oceanic",682},{"Palm",157},{"Pipe Down",812},{"Pipsqueak",140},{"Poplar Thicket",1285},{"Propaganda",1067},{"Rangeen",498},{"Red Filigree",742},{"SaibДЃ Oni",126},{"Sakkaku",1229},{"Sienna Damask",826},{"Silver",32},{"Snow Splash",1367},{"Stalker",898},{"Storm Camo",1269},{"Strats",1075},{"Surfwood",871},{"Tatter",337},{"Tornado",101},{"Toybox",1098},{"Ultraviolet",98},{"Urban DDPAT",17},{"Whitefish",840}},
  [19]={{"Aeolian Light",1361},{"Ancient Earth",1020},{"Ash Wood",234},{"Asiimov",359},{"Astral JГ¶rmungandr",759},{"Attack Vector",936},{"Baroque Red",744},{"Blind Spot",228},{"Blue Tac",1277},{"Chopper",593},{"Cocoa Rampage",977},{"Cold Blooded",67},{"Death by Kitty",156},{"Death Grip",669},{"Deathgaze",1419},{"Desert DDPAT",925},{"Desert Halftone",1332},{"Desert Warfare",311},{"Elite Build",486},{"Emerald Dragon",182},{"Facility Negative",776},{"Fallout Warning",169},{"Freight",969},{"Glacier Mesh",111},{"Grim",611},{"Leather",342},{"Module",335},{"Mustard Gas",1291},{"Neoqueen",1233},{"Nostalgia",911},{"Off World",849},{"Randy Rush",127},{"Reef Grief",1256},{"Run and Hide",1000},{"Sand Spray",124},{"ScaraB Rush",1250},{"Schematic",1074},{"Scorched",175},{"Shallow Grave",636},{"Shapewood",516},{"Storm",100},{"Straight Dimes",1199},{"Sunset Lily",726},{"Teardown",244},{"Tiger Pit",1015},{"Traction",717},{"Trigon",283},{"Vent Rush",1154},{"Verdant Growth",828},{"Virus",20},{"Wash me",133},{"Wave Breaker",1190}},
  [23]={{"Acid Wash",888},{"Agent",915},{"Autumn Twilly",1061},{"Bamboo Garden",872},{"Co-Processor",781},{"Condition Zero",986},{"Desert Strike",949},{"Dirt Drop",753},{"Focus",1344},{"Gauss",846},{"Gold Leaf",1294},{"Kitbash",974},{"Lab Rats",800},{"Lime Hex",1274},{"Liquidation",1231},{"Necro Jr.",1137},{"Neon Squeezer",161},{"Nitro",798},{"Oxide Oasis",923},{"Phosphor",810},{"Picnic",1385},{"Savannah Halftone",768},{"Snow Splash",1366},{"Statics",1180}},
  [24]={{"Arctic Wolf",704},{"Blaze",37},{"Bone Pile",193},{"Briefing",615},{"Caramel",93},{"Carbon Fiber",70},{"Continuum",1351},{"Corporal",281},{"Crime Scene",1003},{"Crimson Foil",412},{"Day Lily",725},{"Delusion",392},{"Exposure",688},{"Facility Dark",778},{"Fade",879},{"Fallout Warning",169},{"Fragment",1426},{"Full Stop",250},{"Gold Bismuth",990},{"Grand Prix",436},{"Green Swirl",1303},{"Gunsmoke",15},{"Houndstooth",1008},{"Indigo",333},{"K.O. Factory",1194},{"Labyrinth",362},{"Late Night Transit",1203},{"Mechanism",1085},{"Metal Flowers",672},{"Minotaur's Labyrinth",441},{"Momentum",802},{"Moonrise",851},{"Motorized",1175},{"Mudder",90},{"Neo-Noir",131},{"Oscillator",1049},{"Plastique",916},{"Primal Saber",556},{"Riot",488},{"Roadblock",1157},{"Scaffold",652},{"Scorched",175},{"Urban DDPAT",17},{"Warm Blooded",1387},{"Wild Child",1236}},
  [25]={{"Ancient Lore",1021},{"Banana Leaf",731},{"Black Tie",557},{"Blaze Orange",166},{"Blue Spruce",96},{"Blue Steel",42},{"Blue Tire",1078},{"Bone Machine",370},{"CaliCamo",240},{"Canvas Cloud",1333},{"Charter",994},{"Copperflage",1287},{"Elegant Vines",821},{"Entombed",970},{"Fallout Warning",169},{"Frost Borre",760},{"Grassland",95},{"Gum Wall Camo",1267},{"Halftone Shift",834},{"Heaven Guard",314},{"Hieroglyph",1254},{"Incinegator",850},{"Irezumi",1174},{"Jungle",205},{"Mockingbird",1182},{"Monster Melt",146},{"Oxide Blaze",706},{"Quicksilver",407},{"Red Leather",348},{"Red Python",320},{"Run Run Run",1201},{"Scumbria",505},{"Seasons",654},{"Slipstream",616},{"Solitude",1215},{"Teclu Burner",521},{"Tranquility",393},{"Urban Perforated",135},{"VariCamo Blue",238},{"Watchdog",1103},{"XoooM",1381},{"XOXO",1046},{"Ziggy",689},{"Zombie Offensive",1135}},
  [26]={{"Anolis",829},{"Antique",306},{"Bamboo Print",457},{"Bizoom",1374},{"Blue Streak",13},{"Brass",159},{"Breaker Box",1083},{"Candy Apple",3},{"Carbon Fiber",70},{"Chemical Green",376},{"Cobalt Halftone",267},{"Cold Cell",770},{"Death Rattle",293},{"Embargo",884},{"Facility Sketch",775},{"Forest Leaves",25},{"Fuel Rod",508},{"Harvester",594},{"High Roller",676},{"Irradiated Alert",171},{"Judgement of Anubis",542},{"Jungle Slipstream",641},{"Lumen",1099},{"Modern Hunter",164},{"Night Ops",236},{"Night Riot",692},{"Osiris",349},{"Photic Zone",526},{"RMX",1418},{"Runic",973},{"Rust Coat",203},{"Sand Dashed",148},{"Seabird",873},{"Space Cat",1125},{"Thermal Currents",1392},{"Urban Dashed",149},{"Water Sigil",224},{"Wood Block Camo",1325}},
  [27]={{"BI83 Spectrum",1089},{"Bulldozer",39},{"Carbon Fiber",70},{"Chainmail",327},{"Cinquedea",737},{"Cobalt Core",499},{"Copper Coated",1245},{"Copper Oxide",1306},{"Core Breach",787},{"Counter Terrace",462},{"Firestarter",385},{"Foresight",1132},{"Hard Water",666},{"Hazard",198},{"Heat",431},{"Heaven Guard",291},{"Insomnia",1220},{"Irradiated Alert",171},{"Justice",948},{"MAGnitude",1355},{"Memento",177},{"Metallic DDPAT",34},{"Monster Call",961},{"Navy Sheen",822},{"Petroglyph",608},{"Popdog",909},{"Praetorian",535},{"Prism Terrace",1072},{"Resupply",1188},{"Rust Coat",754},{"Sand Dune",99},{"Seabird",473},{"Silver",32},{"Sonar",633},{"Storm",100},{"SWAG-7",703},{"Wildwood",773}},
  [28]={{"Anodized Navy",28},{"Army Sheen",298},{"Boroque Sand",920},{"Bratatat",317},{"Bulkhead",783},{"CaliCamo",240},{"Dazzle",610},{"Desert-Strike",355},{"dev_texture",1043},{"Drop Me",1152},{"Infrastructure",1080},{"Lionfish",698},{"Loudmouth",483},{"Man-o'-war",432},{"MjГ¶lnir",763},{"Nuclear Waste",369},{"Palm",201},{"Phoenix Stencil",1012},{"Power Loader",514},{"Prototype",950},{"Raw Ceramic",1300},{"Sour Grapes",1260},{"Terrain",285},{"Ultralight",958},{"Wall Bang",144}},
  [29]={{"Amber Fade",246},{"Analog Input",1160},{"Apocalypto",953},{"Bamboo Shadow",458},{"Black Sand",814},{"Brake Light",797},{"Clay Ambush",1014},{"Copper",41},{"Crimson Batik",1391},{"Devourer",720},{"First Class",345},{"Forest DDPAT",5},{"Fubar",552},{"Full Stop",250},{"Fusion",1427},{"Highwayman",390},{"Irradiated Alert",171},{"Jungle Thicket",870},{"Kissв™ҐLove",1155},{"Limelight",596},{"Morris",673},{"Mosaico",204},{"Orange DDPAT",83},{"Origami",434},{"Parched",880},{"Runoff",1272},{"Rust Coat",323},{"Sage Spray",119},{"Serenity",405},{"Snake Camo",30},{"Spirit Board",1140},{"The Kraken",256},{"Wasteland Princess",638},{"Yorick",517},{"Zander",655}},
  [30]={{"Army Mesh",242},{"Avalanche",520},{"Bamboo Forest",459},{"Bamboozle",839},{"Banana Leaf",1384},{"Blast From the Past",1024},{"Blue Blast",1279},{"Blue Titanium",216},{"Brass",159},{"Brother",964},{"Citric Acid",1322},{"Cracked Opal",684},{"Cut Out",671},{"Decimator",889},{"Flash Out",905},{"Fubar",816},{"Fuel Injector",614},{"Garter-9",1286},{"Groundwater",2},{"Hades",439},{"Ice Cap",599},{"Isaac",303},{"Jambiya",539},{"Mummy's Rot",1252},{"Nuclear Threat",179},{"Orange Murano",738},{"Ossified",36},{"Phoenix Chalk",1010},{"Raw Ceramic",1299},{"Re-Entry",555},{"Rebel",1235},{"Red Quartz",248},{"Remote Control",791},{"Rust Leaf",733},{"Safety Net",795},{"Sandstorm",289},{"Slag",1159},{"Snek-9",722},{"Terrace",463},{"Tiger Stencil",766},{"Titanium Bit",272},{"Tornado",206},{"Toxic",374},{"Urban DDPAT",17},{"VariCamo",235},{"Whiteout",1214}},
  [31]={{"Charged Up",1205},{"Dragon Snore",292},{"Earth Mandala",1382},{"Electric Blue",1268},{"Olympus",1172},{"Swamp DDPAT",1297},{"Tosai",1183}},
  [32]={{"Acid Etched",951},{"Amber Fade",246},{"Chainmail",327},{"Coach Class",346},{"Coral Halftone",878},{"Corticera",184},{"Dispatch",997},{"Fire Elemental",389},{"Gnarled",960},{"Granite Marbleized",21},{"Grassland",95},{"Grassland Leaves",104},{"Grip Tape",1359},{"Handgun",485},{"Imperial",515},{"Imperial Dragon",591},{"Ivory",357},{"Lifted Spirits",1138},{"Marsh",1292},{"Obsidian",894},{"Ocean Foam",211},{"Oceanic",550},{"Panther Camo",1019},{"Pathfinder",443},{"Pulse",338},{"Red FragCam",275},{"Red Wing",1342},{"Royal Baroque",1259},{"Scorpion",71},{"Silver",32},{"Space Race",1055},{"Sure Grip",1181},{"Turf",635},{"Urban Hazard",700},{"Wicked Sick",1224},{"Woodsman",667}},
  [33]={{"Abyssal Apparition",1133},{"Akoben",649},{"Amberline",1436},{"Anodized Navy",28},{"Armor Core",423},{"Army Recon",245},{"Asterion",442},{"Astrolabe",940},{"Bloodsport",696},{"Cirrus",627},{"Coral Paisley",1386},{"Fade",752},{"Forest DDPAT",5},{"Full Stop",250},{"Groundwater",209},{"Guerrilla",1096},{"Gunsmoke",15},{"Impire",536},{"Just Smile",1163},{"Mischief",847},{"Motherboard",782},{"Nemesis",481},{"Neon Ply",893},{"Ocean Foam",213},{"Olive Plaid",365},{"Orange Peel",141},{"Powercore",719},{"Prey",935},{"Scorched",175},{"Short Ochre",1326},{"Skulls",11},{"Smoking Kills",1354},{"Special Delivery",500},{"Sunbaked",1246},{"Tall Grass",1023},{"Teal Blossom",728},{"Urban Hazard",354},{"Vault Heist",1007},{"Whiteout",102}},
  [34]={{"Airlock",609},{"Arctic Tri-Tone",331},{"Army Sheen",298},{"Bee-Tron",1388},{"Bioleak",549},{"Black Sand",697},{"Broken Record",1341},{"Buff Blue",1278},{"Bulldozer",39},{"Capillary",715},{"Cobalt Paisley",1258},{"Dark Age",329},{"Dart",386},{"Deadly Poison",403},{"Dizzy",1375},{"Dry Season",199},{"Featherweight",1225},{"Food Chain",1037},{"Goo",679},{"Green Plaid",366},{"Hot Rod",33},{"Hydra",910},{"Hypnotic",61},{"Latte Rush",1211},{"Modest Threat",804},{"Mount Fuji",1094},{"Multi-Terrain",1330},{"Music Box",820},{"Nexus",1193},{"Old Roots",931},{"Orange Peel",141},{"Pandora's Box",448},{"Pine",1301},{"Rose Iron",262},{"Ruby Poison Dart",482},{"Sand Dashed",148},{"Sand Scale",630},{"Setting Sun",368},{"Shredded",1310},{"Slide",755},{"Stained Glass",867},{"Starlight Protector",1134},{"Storm",100},{"Urban Sovereign",1423},{"Wild Lily",734}},
  [35]={{"Antique",286},{"Army Sheen",298},{"Baroque Orange",746},{"Blaze Orange",166},{"Bloomstick",62},{"Caged Steel",299},{"Candy Apple",3},{"Clear Polymer",987},{"Currents",1368},{"Dark Sigil",1162},{"Exo",590},{"Forest Leaves",25},{"Ghost Camo",225},{"Gila",634},{"Graphite",214},{"Green Apple",294},{"Hyper Beast",537},{"Interlock",1077},{"Koi",356},{"Mandrel",785},{"Marsh Grass",1331},{"Modern Hunter",164},{"Moon in Libra",450},{"Ocular",1350},{"Plume",890},{"Polar Mesh",107},{"Predator",170},{"Quick Sand",929},{"Rain Station",1337},{"Ranger",484},{"Red Quartz",248},{"Rising Skull",263},{"Rising Sun",1192},{"Rust Coat",323},{"Sand Dune",99},{"Sobek's Bite",1247},{"Tempest",191},{"Toy Soldier",716},{"Turquoise Pour",1261},{"Walnut",158},{"Wild Six",699},{"Windblown",1051},{"Wood Fired",809},{"Wurst HГ¶lle",145},{"Yorkshire",324}},
  [36]={{"Apep's Curse",1248},{"Asiimov",551},{"Bengal Tiger",1030},{"Black & Tan",928},{"Bone Mask",27},{"Boreal Forest",77},{"Bullfrog",1345},{"Cartel",388},{"Cassette",968},{"Constructivist",1212},{"Contaminant",982},{"Contamination",373},{"Copper Oxide",1307},{"Crimson Kimono",466},{"Cyber Shell",1044},{"Dark Filigree",741},{"Digital Architect",1081},{"Drought",825},{"Epicenter",130},{"Exchanger",786},{"Facets",207},{"Facility Draft",777},{"Forest Night",78},{"Franklin",295},{"Gunsmoke",15},{"Hive",219},{"Inferno",907},{"Iron Clad",592},{"Kintsugi",1420},{"Mehndi",258},{"Metallic DDPAT",34},{"Mint Kimono",467},{"Modern Hunter",164},{"Muertos",404},{"Nevermore",813},{"Nuclear Threat",168},{"Plum Netting",1273},{"Re.built",1230},{"Red Rock",668},{"Red Tide",1315},{"Ripple",650},{"Sand Dune",99},{"Sedimentary",1317},{"See Ya Later",678},{"Sleet",1369},{"Small Game",774},{"Splash",162},{"Steel Disruption",230},{"Supernova",358},{"Undertow",271},{"Valence",426},{"Verdigris",848},{"Vino Primo",749},{"Visions",1153},{"Whiteout",102},{"Wingshot",501},{"X-Ray",125}},
  [38]={{"Army Sheen",298},{"Assault",914},{"Bloodsport",597},{"Blueprint",642},{"Brass",159},{"Caged",1343},{"Carbon Fiber",70},{"Cardiac",391},{"Contractor",46},{"Crimson Web",232},{"Cyrex",312},{"Emerald",196},{"Enforcer",954},{"Fragments",1226},{"Green Marine",502},{"Grotto",406},{"Jungle Slipstream",685},{"Magna Carta",1028},{"Outbreak",518},{"Palm",157},{"Poultrygeist",1139},{"Powercore",612},{"Sand Mesh",116},{"Short Ochre",1327},{"Splash Jam",165},{"Stone Mosaico",865},{"Storm",100},{"Torn",896},{"Trail Blazer",117},{"Wild Berry",883},{"Zinc",1371}},
  [39]={{"Aerial",598},{"Aloha",702},{"Anodized Navy",28},{"Army Sheen",298},{"Atlas",553},{"Barricade",861},{"Basket Halftone",1320},{"Berry Gel Coat",901},{"Bleached",934},{"Bulldozer",39},{"Candy Apple",864},{"Colony IV",897},{"Cyberforce",1234},{"Cyrex",487},{"Damascus Steel",247},{"Danger Close",815},{"Darkwing",955},{"Desert Blossom",765},{"Dragon Tech",1151},{"Fallout Warning",378},{"Gator Mesh",243},{"Hazard Pay",1084},{"Heavy Metal",1048},{"Hypnotic",61},{"Integrale",750},{"Lush Ruins",1022},{"Night Camo",1270},{"Ol' Rusty",966},{"Phantom",686},{"Pulse",287},{"Safari Print",1394},{"Tiger Moth",519},{"Tornado",101},{"Traveler",363},{"Triarch",613},{"Ultraviolet",98},{"Wave Spray",186},{"Waves Perforated",136}},
  [40]={{"Abyss",361},{"Acid Fade",253},{"Azure Glyph",1251},{"Big Iron",503},{"Blood in the Water",222},{"Bloodshot",899},{"Blue Spruce",96},{"Blush Pour",1316},{"Calligrafaux",1379},{"Carbon Fiber",70},{"Dark Water",60},{"Death Strike",1052},{"Death's Head",670},{"Detour",319},{"Dezastre",1161},{"Dragonfire",624},{"Fever Dream",956},{"Ghost Crusader",554},{"Green Ceramic",1304},{"Grey Smoke",1271},{"Halftone Whorl",877},{"Hand Brake",751},{"Jungle Dashed",147},{"Lichen Dashed",26},{"Mainframe 001",967},{"Mayan Dreams",200},{"Memorial",1187},{"Necropos",538},{"Orange Filigree",743},{"Parallax",989},{"Prey",935},{"Rapid Transit",128},{"Red Stone",762},{"Sand Dune",99},{"Sans Comic",1372},{"Sea Calico",868},{"Slashed",304},{"Spring Twilly",1060},{"Threat Detected",996},{"Tiger Tear",1289},{"Tropical Storm",233},{"Turbo Peek",1101},{"Zeno",513}},
  [60]={{"Atomic Alloy",301},{"Basilisk",383},{"Black Lotus",1166},{"Blood Tiger",217},{"Blue Phosphor",1017},{"Boreal Forest",77},{"Briefing",663},{"Bright Water",189},{"Chantico's Fire",548},{"Control Panel",792},{"Cyrex",360},{"Dark Water",60},{"Decimator",644},{"Electrum",1433},{"Emphorosaur-S",1223},{"Fade",1177},{"Fizzy POP",1059},{"Flashback",631},{"Glitched Paint",1311},{"Golden Coil",497},{"Guardian",257},{"Hot Rod",445},{"Hyper Beast",430},{"Icarus Fell",440},{"Imminent Danger",1073},{"Knight",326},{"Leaded Glass",681},{"Liquidation",1340},{"Master Piece",321},{"Mecha Industries",587},{"Moss Quartz",862},{"Mud-Spec",1243},{"Night Terror",1130},{"Nightmare",714},{"Nitro",254},{"Party Animal",1376},{"Player Two",946},{"Printstream",984},{"Rose Hex",1319},{"Solitude",1338},{"Stratosphere",1216},{"Vaporwave",106},{"VariCamo",235},{"Wash me plz",160},{"Welcome to the Jungle",1001}},
  [61]={{"27",115},{"Alpine Camo",830},{"Ancient Visions",1031},{"Black Lotus",1102},{"Bleeding Edge",1323},{"Blood Tiger",217},{"Blueprint",657},{"Business Class",364},{"Caiman",339},{"Check Engine",796},{"Cortex",705},{"Cyrex",637},{"Dark Water",60},{"Desert Tactical",1253},{"Flashback",817},{"Forest Leaves",25},{"Guardian",290},{"Jawbreaker",1173},{"Kill Confirmed",504},{"Lead Conduit",540},{"Monster Mashup",991},{"Neo-Noir",653},{"Night Ops",236},{"Orange Anolis",922},{"Orion",313},{"Overgrowth",183},{"Para Green",454},{"Pathfinder",443},{"PC-GRN",1186},{"Printstream",1142},{"Purple DDPAT",818},{"Road Rash",318},{"Royal Blue",332},{"Royal Guard",1217},{"Serum",221},{"Silent Shot",1431},{"Sleeping Potion",1377},{"Stainless",277},{"Target Acquired",1027},{"The Traitor",1040},{"Ticket to Hell",1136},{"Torque",489},{"Tropical Breeze",1284},{"Whiteout",1065}},
  [63]={{"Army Sheen",298},{"Chalice",325},{"Circaetus",1036},{"Copper Fiber",1195},{"Crimson Web",12},{"Distressed",944},{"Eco",709},{"Emerald",453},{"Emerald Quartz",859},{"Framework",1076},{"Green Plaid",366},{"Hexane",218},{"Honey Paisley",1390},{"Imprint",602},{"Indigo",333},{"Jungle Dashed",147},{"Midnight Palm",933},{"Nitro",322},{"Pink Pearl",1329},{"Poison Dart",315},{"Pole Position",435},{"Polymer",622},{"Red Astor",543},{"Silver",32},{"Slalom",937},{"Syndicate",1064},{"Tacticat",687},{"The Fuschia Is Now",269},{"Tigris",350},{"Tread Plate",268},{"Tuxedo",297},{"Twist",334},{"Vendetta",976},{"Victoria",270},{"Xiangliu",643},{"Yellow Jacket",476}},
  [64]={{"Amber Fade",523},{"Banana Cannon",1232},{"Blaze",37},{"Bone Forged",952},{"Bone Mask",27},{"Canal Spray",866},{"Cobalt Grip",1276},{"Crazy 8",1145},{"Crimson Web",12},{"Dark Chamber",1363},{"Desert Brush",924},{"Fade",522},{"Grip",701},{"Inlay",1237},{"Junk Yard",1047},{"Leafhopper",1293},{"Llama Cannon",683},{"Mauve Aside",1389},{"Memento",892},{"Night",40},{"Nitro",798},{"Phoenix Marker",1011},{"Reboot",595},{"Skull Crusher",843},{"Survivalist",721},{"Tango",123}},
  [500]={{"Autotronic",573},{"Black Laminate",563},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",578},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",580},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",558},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [503]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Fade",38},{"Forest DDPAT",5},{"Night Stripe",735},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Urban Masked",143}},
  [505]={{"Autotronic",574},{"Black Laminate",564},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",578},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",580},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",559},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [506]={{"Autotronic",575},{"Black Laminate",565},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",578},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",580},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",560},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [507]={{"Autotronic",576},{"Black Laminate",566},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",578},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",582},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",561},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [508]={{"Autotronic",577},{"Black Laminate",567},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",579},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",411},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",581},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",562},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [509]={{"Autotronic",1117},{"Black Laminate",1112},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",579},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",411},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",581},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",1107},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",620},{"Urban Masked",143}},
  [512]={{"Autotronic",1116},{"Black Laminate",1111},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",579},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",411},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",581},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",1106},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",621},{"Urban Masked",143}},
  [514]={{"Autotronic",1114},{"Black Laminate",1109},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",579},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",411},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",581},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",1104},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [515]={{"Autotronic",1115},{"Black Laminate",1110},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",579},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",411},{"Doppler",617},{"Doppler",418},{"Doppler",618},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",619},{"Fade",38},{"Forest DDPAT",5},{"Freehand",581},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",1105},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [516]={{"Autotronic",1118},{"Black Laminate",1113},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",579},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",411},{"Doppler",617},{"Doppler",418},{"Doppler",618},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",619},{"Fade",38},{"Forest DDPAT",5},{"Freehand",581},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",1108},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [517]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",621},{"Urban Masked",143}},
  [518]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [519]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",857},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [520]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",857},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [521]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [522]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",857},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [523]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",858},{"Doppler",417},{"Doppler",852},{"Doppler",853},{"Doppler",854},{"Doppler",855},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",856},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [525]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [526]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Fade",38},{"Forest DDPAT",5},{"Night Stripe",735},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Urban Masked",143}},
  [4725]={{"Jade",10085},{"Needle Point",10087},{"Unhinged",10088},{"Yellow-banded",10086}},
  [5027]={{"Bronzed",10008},{"Charred",10006},{"Guerrilla",10039},{"Snakebite",10007}},
  [5030]={{"Amphibious",10045},{"Arid",10019},{"Big Game",10074},{"Blaze",1407},{"Bronze Morph",10046},{"Creme Pinstripe",1408},{"Frosty",1406},{"Hedge Maze",10038},{"Nocts",10076},{"Occult",1417},{"Omega",10047},{"Pandora's Box",10037},{"Red Racer",1409},{"Scarlet Shamagh",10075},{"Slingshot",10073},{"Superconductor",10018},{"Ultra Violent",1410},{"Vice",10048},{"Violet Beadwork",1405}},
  [5031]={{"Black Tie",10072},{"Brocade Crane",1399},{"Brocade Flowers",1400},{"Convoy",10015},{"Crimson Weave",10016},{"Diamondback",10040},{"Dragon Fists",1401},{"Garden",1402},{"Hand Sweaters",1439},{"Imperial Plaid",10042},{"King Snake",10041},{"Lunar Weave",10013},{"Overtake",10043},{"Plum Quill",1412},{"Queen Jaguar",10071},{"Racing Green",10044},{"Rezan the Red",10069},{"Seigaiha",1404},{"Snow Leopard",10070},{"Wave Chaser",1398}},
  [5032]={{"Arboreal",10056},{"Badlands",10036},{"CAUTION!",10084},{"Cobalt Skulls",10053},{"Constrictor",10083},{"Desert Shamagh",10081},{"Duct Tape",10055},{"Giraffe",10082},{"Leather",10009},{"Overprint",10054},{"Slaughter",10021},{"Spruce DDPAT",10010}},
  [5033]={{"3rd Commando Company",10080},{"Blood Pressure",10079},{"Boom!",10027},{"Cool Mint",10028},{"Eclipse",10024},{"Finish Line",10077},{"Polygon",10052},{"POW!",10049},{"Smoke Out",10078},{"Spearmint",10026},{"Transport",10051},{"Turtle",10050}},
  [5034]={{"Big Swell",1437},{"Blackbook",1414},{"Buckshot",10062},{"Chocolate Chesterfield",1415},{"Cloud Chaser",1440},{"Crimson Kimono",10033},{"Crimson Web",10061},{"Emerald Web",10034},{"Fade",10063},{"Field Agent",10068},{"Forest DDPAT",10030},{"Foundation",10035},{"Lime Polycam",1413},{"Lt. Commander",10066},{"Marble Fade",10065},{"Mogul",10064},{"Pillow Punchers",1438},{"Sunburst",1416},{"Tiger Strike",10067}},
  [5035]={{"Case Hardened",10060},{"Emerald",10057},{"Mangrove",10058},{"Rattler",10059}},
}

local RARITY_BY_SKIN = {
    ["1:17"] = "LBLUE",
    ["1:37"] = "PURPLE",
    ["1:40"] = "LBLUE",
    ["1:61"] = "PINK",
    ["1:90"] = "LBLUE",
    ["1:114"] = "BLUE",
    ["1:138"] = "LBLUE",
    ["1:185"] = "RED",
    ["1:231"] = "PINK",
    ["1:232"] = "PURPLE",
    ["1:237"] = "BLUE",
    ["1:273"] = "PURPLE",
    ["1:296"] = "BLUE",
    ["1:328"] = "PURPLE",
    ["1:347"] = "PURPLE",
    ["1:351"] = "PINK",
    ["1:397"] = "PURPLE",
    ["1:425"] = "BLUE",
    ["1:468"] = "LBLUE",
    ["1:469"] = "PURPLE",
    ["1:470"] = "PURPLE",
    ["1:509"] = "BLUE",
    ["1:527"] = "PINK",
    ["1:603"] = "PURPLE",
    ["1:645"] = "BLUE",
    ["1:711"] = "RED",
    ["1:757"] = "PURPLE",
    ["1:764"] = "PINK",
    ["1:805"] = "PINK",
    ["1:841"] = "PURPLE",
    ["1:938"] = "PINK",
    ["1:945"] = "BLUE",
    ["1:962"] = "RED",
    ["1:992"] = "LBLUE",
    ["1:1006"] = "BLUE",
    ["1:1050"] = "PURPLE",
    ["1:1054"] = "PINK",
    ["1:1056"] = "BLUE",
    ["1:1090"] = "RED",
    ["1:1189"] = "PURPLE",
    ["1:1257"] = "BLUE",
    ["1:1318"] = "PURPLE",
    ["1:1360"] = "BLUE",
    ["1:1430"] = "PURPLE",
    ["2:28"] = "BLUE",
    ["2:43"] = "LBLUE",
    ["2:46"] = "WHITE",
    ["2:47"] = "WHITE",
    ["2:112"] = "PURPLE",
    ["2:139"] = "PURPLE",
    ["2:153"] = "PURPLE",
    ["2:190"] = "BLUE",
    ["2:220"] = "PURPLE",
    ["2:249"] = "PURPLE",
    ["2:261"] = "PURPLE",
    ["2:276"] = "BLUE",
    ["2:307"] = "BLUE",
    ["2:330"] = "WHITE",
    ["2:396"] = "PURPLE",
    ["2:447"] = "PURPLE",
    ["2:450"] = "WHITE",
    ["2:453"] = "BLUE",
    ["2:491"] = "BLUE",
    ["2:528"] = "BLUE",
    ["2:544"] = "BLUE",
    ["2:625"] = "PURPLE",
    ["2:658"] = "PINK",
    ["2:710"] = "BLUE",
    ["2:747"] = "PINK",
    ["2:824"] = "LBLUE",
    ["2:860"] = "LBLUE",
    ["2:895"] = "BLUE",
    ["2:903"] = "BLUE",
    ["2:978"] = "PURPLE",
    ["2:998"] = "LBLUE",
    ["2:1005"] = "WHITE",
    ["2:1086"] = "WHITE",
    ["2:1091"] = "BLUE",
    ["2:1126"] = "PINK",
    ["2:1156"] = "PURPLE",
    ["2:1169"] = "BLUE",
    ["2:1263"] = "LBLUE",
    ["2:1290"] = "LBLUE",
    ["2:1335"] = "WHITE",
    ["2:1347"] = "PURPLE",
    ["2:1373"] = "WHITE",
    ["3:3"] = "LBLUE",
    ["3:44"] = "PURPLE",
    ["3:46"] = "WHITE",
    ["3:78"] = "WHITE",
    ["3:141"] = "LBLUE",
    ["3:151"] = "WHITE",
    ["3:210"] = "WHITE",
    ["3:223"] = "BLUE",
    ["3:252"] = "BLUE",
    ["3:254"] = "BLUE",
    ["3:265"] = "BLUE",
    ["3:274"] = "PURPLE",
    ["3:352"] = "PINK",
    ["3:377"] = "LBLUE",
    ["3:387"] = "BLUE",
    ["3:427"] = "PINK",
    ["3:464"] = "PURPLE",
    ["3:510"] = "PURPLE",
    ["3:530"] = "PURPLE",
    ["3:585"] = "BLUE",
    ["3:605"] = "BLUE",
    ["3:646"] = "BLUE",
    ["3:660"] = "RED",
    ["3:693"] = "BLUE",
    ["3:729"] = "BLUE",
    ["3:784"] = "WHITE",
    ["3:831"] = "PURPLE",
    ["3:837"] = "RED",
    ["3:906"] = "PURPLE",
    ["3:932"] = "LBLUE",
    ["3:979"] = "PINK",
    ["3:1002"] = "PURPLE",
    ["3:1062"] = "LBLUE",
    ["3:1082"] = "PINK",
    ["3:1093"] = "PURPLE",
    ["3:1128"] = "BLUE",
    ["3:1168"] = "PURPLE",
    ["3:1262"] = "LBLUE",
    ["3:1336"] = "WHITE",
    ["3:1380"] = "BLUE",
    ["3:1429"] = "BLUE",
    ["4:2"] = "LBLUE",
    ["4:3"] = "BLUE",
    ["4:38"] = "PURPLE",
    ["4:40"] = "LBLUE",
    ["4:48"] = "PURPLE",
    ["4:84"] = "PURPLE",
    ["4:129"] = "RED",
    ["4:152"] = "BLUE",
    ["4:159"] = "PURPLE",
    ["4:208"] = "LBLUE",
    ["4:230"] = "PURPLE",
    ["4:278"] = "BLUE",
    ["4:293"] = "LBLUE",
    ["4:353"] = "PINK",
    ["4:367"] = "BLUE",
    ["4:381"] = "PURPLE",
    ["4:399"] = "BLUE",
    ["4:437"] = "PINK",
    ["4:479"] = "BLUE",
    ["4:495"] = "BLUE",
    ["4:532"] = "PURPLE",
    ["4:586"] = "RED",
    ["4:607"] = "PURPLE",
    ["4:623"] = "BLUE",
    ["4:680"] = "BLUE",
    ["4:694"] = "PURPLE",
    ["4:713"] = "BLUE",
    ["4:732"] = "PURPLE",
    ["4:789"] = "PURPLE",
    ["4:799"] = "LBLUE",
    ["4:808"] = "BLUE",
    ["4:832"] = "PINK",
    ["4:918"] = "BLUE",
    ["4:957"] = "RED",
    ["4:963"] = "PINK",
    ["4:988"] = "RED",
    ["4:1016"] = "PURPLE",
    ["4:1039"] = "BLUE",
    ["4:1079"] = "LBLUE",
    ["4:1100"] = "PINK",
    ["4:1119"] = "RED",
    ["4:1120"] = "RED",
    ["4:1121"] = "RED",
    ["4:1122"] = "RED",
    ["4:1123"] = "RED",
    ["4:1158"] = "BLUE",
    ["4:1167"] = "PURPLE",
    ["4:1200"] = "BLUE",
    ["4:1208"] = "PINK",
    ["4:1227"] = "PURPLE",
    ["4:1240"] = "PURPLE",
    ["4:1265"] = "LBLUE",
    ["4:1282"] = "PURPLE",
    ["4:1312"] = "BLUE",
    ["4:1348"] = "PINK",
    ["4:1357"] = "PURPLE",
    ["4:1421"] = "RED",
    ["7:14"] = "PINK",
    ["7:44"] = "PINK",
    ["7:72"] = "LBLUE",
    ["7:113"] = "PINK",
    ["7:122"] = "LBLUE",
    ["7:142"] = "RED",
    ["7:170"] = "LBLUE",
    ["7:172"] = "BLUE",
    ["7:180"] = "RED",
    ["7:226"] = "PURPLE",
    ["7:282"] = "PINK",
    ["7:300"] = "PURPLE",
    ["7:302"] = "RED",
    ["7:316"] = "RED",
    ["7:340"] = "PINK",
    ["7:341"] = "PURPLE",
    ["7:380"] = "RED",
    ["7:394"] = "PINK",
    ["7:422"] = "BLUE",
    ["7:456"] = "PINK",
    ["7:474"] = "RED",
    ["7:490"] = "PINK",
    ["7:506"] = "PINK",
    ["7:524"] = "RED",
    ["7:600"] = "RED",
    ["7:639"] = "RED",
    ["7:656"] = "PURPLE",
    ["7:675"] = "RED",
    ["7:707"] = "RED",
    ["7:724"] = "RED",
    ["7:745"] = "LBLUE",
    ["7:795"] = "PURPLE",
    ["7:801"] = "RED",
    ["7:836"] = "BLUE",
    ["7:885"] = "PURPLE",
    ["7:912"] = "BLUE",
    ["7:921"] = "RED",
    ["7:941"] = "PINK",
    ["7:959"] = "RED",
    ["7:1004"] = "RED",
    ["7:1018"] = "PINK",
    ["7:1035"] = "PURPLE",
    ["7:1070"] = "BLUE",
    ["7:1087"] = "RED",
    ["7:1141"] = "RED",
    ["7:1143"] = "PINK",
    ["7:1171"] = "RED",
    ["7:1179"] = "LBLUE",
    ["7:1207"] = "PINK",
    ["7:1218"] = "PURPLE",
    ["7:1221"] = "RED",
    ["7:1238"] = "BLUE",
    ["7:1283"] = "BLUE",
    ["7:1288"] = "LBLUE",
    ["7:1309"] = "PINK",
    ["7:1352"] = "RED",
    ["7:1358"] = "PURPLE",
    ["7:1397"] = "RED",
    ["7:1425"] = "PINK",
    ["8:9"] = "PINK",
    ["8:10"] = "BLUE",
    ["8:33"] = "BLUE",
    ["8:46"] = "WHITE",
    ["8:47"] = "WHITE",
    ["8:73"] = "BLUE",
    ["8:100"] = "WHITE",
    ["8:110"] = "LBLUE",
    ["8:121"] = "BLUE",
    ["8:134"] = "PURPLE",
    ["8:173"] = "PINK",
    ["8:197"] = "BLUE",
    ["8:246"] = "BLUE",
    ["8:280"] = "RED",
    ["8:305"] = "PURPLE",
    ["8:375"] = "LBLUE",
    ["8:444"] = "WHITE",
    ["8:455"] = "RED",
    ["8:507"] = "BLUE",
    ["8:541"] = "PINK",
    ["8:583"] = "PURPLE",
    ["8:601"] = "PINK",
    ["8:674"] = "BLUE",
    ["8:690"] = "PINK",
    ["8:708"] = "BLUE",
    ["8:727"] = "PURPLE",
    ["8:740"] = "WHITE",
    ["8:758"] = "PURPLE",
    ["8:779"] = "PURPLE",
    ["8:794"] = "WHITE",
    ["8:823"] = "PURPLE",
    ["8:845"] = "PINK",
    ["8:886"] = "PURPLE",
    ["8:913"] = "PINK",
    ["8:927"] = "LBLUE",
    ["8:942"] = "BLUE",
    ["8:995"] = "WHITE",
    ["8:1033"] = "BLUE",
    ["8:1088"] = "BLUE",
    ["8:1198"] = "LBLUE",
    ["8:1249"] = "WHITE",
    ["8:1308"] = "WHITE",
    ["8:1339"] = "BLUE",
    ["8:1362"] = "BLUE",
    ["9:30"] = "BLUE",
    ["9:51"] = "RED",
    ["9:72"] = "LBLUE",
    ["9:84"] = "PURPLE",
    ["9:137"] = "PINK",
    ["9:163"] = "RED",
    ["9:174"] = "PINK",
    ["9:181"] = "PINK",
    ["9:212"] = "PINK",
    ["9:227"] = "PINK",
    ["9:251"] = "PURPLE",
    ["9:259"] = "PINK",
    ["9:279"] = "RED",
    ["9:344"] = "RED",
    ["9:395"] = "RED",
    ["9:424"] = "PURPLE",
    ["9:446"] = "RED",
    ["9:451"] = "LBLUE",
    ["9:475"] = "RED",
    ["9:525"] = "PINK",
    ["9:584"] = "PURPLE",
    ["9:640"] = "PINK",
    ["9:662"] = "RED",
    ["9:691"] = "PINK",
    ["9:718"] = "PURPLE",
    ["9:736"] = "RED",
    ["9:756"] = "RED",
    ["9:788"] = "BLUE",
    ["9:803"] = "RED",
    ["9:819"] = "RED",
    ["9:838"] = "PURPLE",
    ["9:887"] = "RED",
    ["9:917"] = "RED",
    ["9:943"] = "BLUE",
    ["9:975"] = "PURPLE",
    ["9:1026"] = "RED",
    ["9:1029"] = "PINK",
    ["9:1058"] = "PURPLE",
    ["9:1144"] = "RED",
    ["9:1170"] = "RED",
    ["9:1206"] = "RED",
    ["9:1213"] = "RED",
    ["9:1222"] = "PINK",
    ["9:1239"] = "BLUE",
    ["9:1280"] = "PINK",
    ["9:1324"] = "BLUE",
    ["9:1346"] = "PINK",
    ["9:1356"] = "PINK",
    ["9:1378"] = "PURPLE",
    ["9:1422"] = "RED",
    ["10:22"] = "WHITE",
    ["10:47"] = "WHITE",
    ["10:60"] = "BLUE",
    ["10:92"] = "LBLUE",
    ["10:154"] = "PINK",
    ["10:178"] = "BLUE",
    ["10:194"] = "PURPLE",
    ["10:218"] = "BLUE",
    ["10:240"] = "LBLUE",
    ["10:244"] = "BLUE",
    ["10:260"] = "PURPLE",
    ["10:288"] = "PURPLE",
    ["10:371"] = "PURPLE",
    ["10:429"] = "PINK",
    ["10:461"] = "LBLUE",
    ["10:477"] = "PURPLE",
    ["10:492"] = "BLUE",
    ["10:529"] = "PURPLE",
    ["10:604"] = "RED",
    ["10:626"] = "PINK",
    ["10:659"] = "BLUE",
    ["10:723"] = "PINK",
    ["10:835"] = "BLUE",
    ["10:863"] = "WHITE",
    ["10:869"] = "BLUE",
    ["10:882"] = "LBLUE",
    ["10:904"] = "BLUE",
    ["10:919"] = "RED",
    ["10:999"] = "PURPLE",
    ["10:1053"] = "PINK",
    ["10:1066"] = "WHITE",
    ["10:1092"] = "PURPLE",
    ["10:1127"] = "PINK",
    ["10:1146"] = "BLUE",
    ["10:1184"] = "RED",
    ["10:1202"] = "BLUE",
    ["10:1219"] = "BLUE",
    ["10:1241"] = "PINK",
    ["10:1302"] = "WHITE",
    ["10:1321"] = "LBLUE",
    ["10:1365"] = "LBLUE",
    ["10:1393"] = "WHITE",
    ["11:6"] = "LBLUE",
    ["11:8"] = "WHITE",
    ["11:46"] = "WHITE",
    ["11:72"] = "WHITE",
    ["11:74"] = "WHITE",
    ["11:147"] = "WHITE",
    ["11:195"] = "BLUE",
    ["11:229"] = "BLUE",
    ["11:235"] = "LBLUE",
    ["11:294"] = "LBLUE",
    ["11:382"] = "BLUE",
    ["11:438"] = "PURPLE",
    ["11:465"] = "WHITE",
    ["11:493"] = "PINK",
    ["11:511"] = "PINK",
    ["11:545"] = "BLUE",
    ["11:606"] = "BLUE",
    ["11:628"] = "PURPLE",
    ["11:677"] = "BLUE",
    ["11:712"] = "PURPLE",
    ["11:739"] = "BLUE",
    ["11:806"] = "PURPLE",
    ["11:891"] = "BLUE",
    ["11:930"] = "BLUE",
    ["11:980"] = "BLUE",
    ["11:1034"] = "LBLUE",
    ["11:1095"] = "BLUE",
    ["11:1129"] = "PURPLE",
    ["11:1305"] = "WHITE",
    ["11:1328"] = "WHITE",
    ["13:76"] = "LBLUE",
    ["13:83"] = "PURPLE",
    ["13:101"] = "WHITE",
    ["13:119"] = "WHITE",
    ["13:192"] = "BLUE",
    ["13:216"] = "BLUE",
    ["13:235"] = "LBLUE",
    ["13:237"] = "LBLUE",
    ["13:239"] = "BLUE",
    ["13:241"] = "WHITE",
    ["13:246"] = "BLUE",
    ["13:264"] = "BLUE",
    ["13:294"] = "LBLUE",
    ["13:297"] = "BLUE",
    ["13:308"] = "BLUE",
    ["13:379"] = "PURPLE",
    ["13:398"] = "RED",
    ["13:428"] = "PINK",
    ["13:460"] = "BLUE",
    ["13:478"] = "BLUE",
    ["13:494"] = "PURPLE",
    ["13:546"] = "PURPLE",
    ["13:629"] = "BLUE",
    ["13:647"] = "PURPLE",
    ["13:661"] = "PINK",
    ["13:790"] = "LBLUE",
    ["13:807"] = "PURPLE",
    ["13:842"] = "BLUE",
    ["13:939"] = "LBLUE",
    ["13:972"] = "PURPLE",
    ["13:981"] = "BLUE",
    ["13:1013"] = "PURPLE",
    ["13:1032"] = "BLUE",
    ["13:1038"] = "PINK",
    ["13:1071"] = "PURPLE",
    ["13:1147"] = "BLUE",
    ["13:1178"] = "PINK",
    ["13:1185"] = "PURPLE",
    ["13:1264"] = "LBLUE",
    ["13:1275"] = "WHITE",
    ["13:1296"] = "LBLUE",
    ["13:1314"] = "LBLUE",
    ["13:1383"] = "BLUE",
    ["13:1434"] = "PURPLE",
    ["14:22"] = "WHITE",
    ["14:75"] = "LBLUE",
    ["14:120"] = "BLUE",
    ["14:151"] = "WHITE",
    ["14:170"] = "WHITE",
    ["14:202"] = "WHITE",
    ["14:243"] = "LBLUE",
    ["14:266"] = "BLUE",
    ["14:401"] = "BLUE",
    ["14:452"] = "LBLUE",
    ["14:472"] = "WHITE",
    ["14:496"] = "PURPLE",
    ["14:547"] = "BLUE",
    ["14:648"] = "PURPLE",
    ["14:827"] = "BLUE",
    ["14:875"] = "LBLUE",
    ["14:900"] = "BLUE",
    ["14:902"] = "PURPLE",
    ["14:933"] = "LBLUE",
    ["14:983"] = "BLUE",
    ["14:1042"] = "BLUE",
    ["14:1148"] = "PURPLE",
    ["14:1242"] = "WHITE",
    ["14:1298"] = "WHITE",
    ["14:1370"] = "WHITE",
    ["14:1435"] = "BLUE",
    ["16:8"] = "LBLUE",
    ["16:16"] = "LBLUE",
    ["16:17"] = "LBLUE",
    ["16:101"] = "LBLUE",
    ["16:118"] = "PURPLE",
    ["16:155"] = "RED",
    ["16:164"] = "PURPLE",
    ["16:167"] = "BLUE",
    ["16:176"] = "BLUE",
    ["16:187"] = "PURPLE",
    ["16:215"] = "RED",
    ["16:255"] = "RED",
    ["16:309"] = "ORANGE",
    ["16:336"] = "RED",
    ["16:384"] = "PURPLE",
    ["16:400"] = "PINK",
    ["16:449"] = "PINK",
    ["16:471"] = "PURPLE",
    ["16:480"] = "PURPLE",
    ["16:512"] = "RED",
    ["16:533"] = "RED",
    ["16:588"] = "PINK",
    ["16:632"] = "RED",
    ["16:664"] = "PINK",
    ["16:695"] = "RED",
    ["16:730"] = "LBLUE",
    ["16:780"] = "LBLUE",
    ["16:793"] = "BLUE",
    ["16:811"] = "BLUE",
    ["16:844"] = "RED",
    ["16:874"] = "PURPLE",
    ["16:926"] = "PURPLE",
    ["16:971"] = "PINK",
    ["16:985"] = "PINK",
    ["16:993"] = "BLUE",
    ["16:1041"] = "RED",
    ["16:1063"] = "RED",
    ["16:1097"] = "PURPLE",
    ["16:1149"] = "BLUE",
    ["16:1165"] = "PURPLE",
    ["16:1209"] = "PINK",
    ["16:1210"] = "BLUE",
    ["16:1228"] = "RED",
    ["16:1255"] = "RED",
    ["16:1266"] = "LBLUE",
    ["16:1281"] = "PURPLE",
    ["16:1313"] = "LBLUE",
    ["16:1353"] = "RED",
    ["16:1364"] = "LBLUE",
    ["16:1432"] = "BLUE",
    ["17:3"] = "LBLUE",
    ["17:17"] = "WHITE",
    ["17:32"] = "LBLUE",
    ["17:38"] = "BLUE",
    ["17:44"] = "PURPLE",
    ["17:98"] = "BLUE",
    ["17:101"] = "WHITE",
    ["17:126"] = "PURPLE",
    ["17:140"] = "BLUE",
    ["17:157"] = "LBLUE",
    ["17:188"] = "PURPLE",
    ["17:246"] = "BLUE",
    ["17:284"] = "PURPLE",
    ["17:310"] = "PURPLE",
    ["17:333"] = "WHITE",
    ["17:337"] = "PURPLE",
    ["17:343"] = "LBLUE",
    ["17:372"] = "BLUE",
    ["17:402"] = "PURPLE",
    ["17:433"] = "RED",
    ["17:498"] = "BLUE",
    ["17:534"] = "BLUE",
    ["17:589"] = "BLUE",
    ["17:651"] = "PURPLE",
    ["17:665"] = "BLUE",
    ["17:682"] = "BLUE",
    ["17:742"] = "PURPLE",
    ["17:748"] = "LBLUE",
    ["17:761"] = "BLUE",
    ["17:812"] = "PURPLE",
    ["17:826"] = "WHITE",
    ["17:840"] = "BLUE",
    ["17:871"] = "WHITE",
    ["17:898"] = "RED",
    ["17:908"] = "BLUE",
    ["17:947"] = "PINK",
    ["17:965"] = "PURPLE",
    ["17:1009"] = "PINK",
    ["17:1025"] = "PURPLE",
    ["17:1045"] = "PURPLE",
    ["17:1067"] = "PINK",
    ["17:1075"] = "WHITE",
    ["17:1098"] = "PINK",
    ["17:1131"] = "BLUE",
    ["17:1150"] = "BLUE",
    ["17:1164"] = "BLUE",
    ["17:1204"] = "PURPLE",
    ["17:1229"] = "PURPLE",
    ["17:1244"] = "LBLUE",
    ["17:1269"] = "WHITE",
    ["17:1285"] = "BLUE",
    ["17:1295"] = "LBLUE",
    ["17:1334"] = "WHITE",
    ["17:1349"] = "PURPLE",
    ["17:1367"] = "LBLUE",
    ["19:20"] = "PURPLE",
    ["19:67"] = "PINK",
    ["19:100"] = "WHITE",
    ["19:111"] = "BLUE",
    ["19:124"] = "WHITE",
    ["19:127"] = "PURPLE",
    ["19:133"] = "LBLUE",
    ["19:156"] = "RED",
    ["19:169"] = "LBLUE",
    ["19:175"] = "WHITE",
    ["19:182"] = "PINK",
    ["19:228"] = "PURPLE",
    ["19:234"] = "LBLUE",
    ["19:244"] = "BLUE",
    ["19:283"] = "PINK",
    ["19:311"] = "BLUE",
    ["19:335"] = "BLUE",
    ["19:342"] = "LBLUE",
    ["19:359"] = "RED",
    ["19:486"] = "BLUE",
    ["19:516"] = "PINK",
    ["19:593"] = "PURPLE",
    ["19:611"] = "BLUE",
    ["19:636"] = "PINK",
    ["19:669"] = "PURPLE",
    ["19:717"] = "BLUE",
    ["19:726"] = "LBLUE",
    ["19:744"] = "BLUE",
    ["19:759"] = "PURPLE",
    ["19:776"] = "BLUE",
    ["19:828"] = "LBLUE",
    ["19:849"] = "BLUE",
    ["19:911"] = "PINK",
    ["19:925"] = "WHITE",
    ["19:936"] = "PURPLE",
    ["19:969"] = "BLUE",
    ["19:977"] = "BLUE",
    ["19:1000"] = "PINK",
    ["19:1015"] = "BLUE",
    ["19:1020"] = "WHITE",
    ["19:1074"] = "BLUE",
    ["19:1154"] = "PURPLE",
    ["19:1190"] = "PURPLE",
    ["19:1199"] = "LBLUE",
    ["19:1233"] = "PURPLE",
    ["19:1250"] = "PURPLE",
    ["19:1256"] = "BLUE",
    ["19:1277"] = "WHITE",
    ["19:1291"] = "LBLUE",
    ["19:1332"] = "WHITE",
    ["19:1361"] = "BLUE",
    ["19:1419"] = "PINK",
    ["23:161"] = "LBLUE",
    ["23:753"] = "WHITE",
    ["23:768"] = "LBLUE",
    ["23:781"] = "BLUE",
    ["23:798"] = "LBLUE",
    ["23:800"] = "PURPLE",
    ["23:810"] = "PINK",
    ["23:846"] = "PURPLE",
    ["23:872"] = "WHITE",
    ["23:888"] = "BLUE",
    ["23:915"] = "PURPLE",
    ["23:923"] = "PINK",
    ["23:949"] = "BLUE",
    ["23:974"] = "PURPLE",
    ["23:986"] = "BLUE",
    ["23:1061"] = "PURPLE",
    ["23:1137"] = "BLUE",
    ["23:1180"] = "BLUE",
    ["23:1231"] = "BLUE",
    ["23:1274"] = "WHITE",
    ["23:1294"] = "BLUE",
    ["23:1344"] = "BLUE",
    ["23:1366"] = "LBLUE",
    ["23:1385"] = "LBLUE",
    ["24:15"] = "LBLUE",
    ["24:17"] = "WHITE",
    ["24:37"] = "BLUE",
    ["24:70"] = "LBLUE",
    ["24:90"] = "WHITE",
    ["24:93"] = "WHITE",
    ["24:131"] = "PINK",
    ["24:169"] = "LBLUE",
    ["24:175"] = "WHITE",
    ["24:193"] = "BLUE",
    ["24:250"] = "BLUE",
    ["24:281"] = "BLUE",
    ["24:333"] = "WHITE",
    ["24:362"] = "BLUE",
    ["24:392"] = "BLUE",
    ["24:412"] = "PURPLE",
    ["24:436"] = "PURPLE",
    ["24:441"] = "BLUE",
    ["24:488"] = "BLUE",
    ["24:556"] = "PINK",
    ["24:615"] = "BLUE",
    ["24:652"] = "PURPLE",
    ["24:672"] = "BLUE",
    ["24:688"] = "PURPLE",
    ["24:704"] = "PURPLE",
    ["24:725"] = "BLUE",
    ["24:778"] = "WHITE",
    ["24:802"] = "PINK",
    ["24:851"] = "PURPLE",
    ["24:879"] = "PINK",
    ["24:916"] = "PURPLE",
    ["24:990"] = "PURPLE",
    ["24:1003"] = "PURPLE",
    ["24:1008"] = "LBLUE",
    ["24:1049"] = "BLUE",
    ["24:1085"] = "LBLUE",
    ["24:1157"] = "BLUE",
    ["24:1175"] = "BLUE",
    ["24:1194"] = "PINK",
    ["24:1203"] = "BLUE",
    ["24:1236"] = "PINK",
    ["24:1303"] = "WHITE",
    ["24:1351"] = "PURPLE",
    ["24:1387"] = "BLUE",
    ["24:1426"] = "BLUE",
    ["25:42"] = "LBLUE",
    ["25:95"] = "WHITE",
    ["25:96"] = "WHITE",
    ["25:135"] = "WHITE",
    ["25:146"] = "PURPLE",
    ["25:166"] = "BLUE",
    ["25:169"] = "LBLUE",
    ["25:205"] = "WHITE",
    ["25:238"] = "BLUE",
    ["25:240"] = "LBLUE",
    ["25:314"] = "PURPLE",
    ["25:320"] = "BLUE",
    ["25:348"] = "BLUE",
    ["25:370"] = "BLUE",
    ["25:393"] = "PINK",
    ["25:407"] = "BLUE",
    ["25:505"] = "BLUE",
    ["25:521"] = "PURPLE",
    ["25:557"] = "PURPLE",
    ["25:616"] = "BLUE",
    ["25:654"] = "PURPLE",
    ["25:689"] = "PURPLE",
    ["25:706"] = "BLUE",
    ["25:731"] = "LBLUE",
    ["25:760"] = "BLUE",
    ["25:821"] = "PURPLE",
    ["25:834"] = "BLUE",
    ["25:850"] = "PINK",
    ["25:970"] = "PINK",
    ["25:994"] = "WHITE",
    ["25:1021"] = "PURPLE",
    ["25:1046"] = "PINK",
    ["25:1078"] = "WHITE",
    ["25:1103"] = "BLUE",
    ["25:1135"] = "PURPLE",
    ["25:1174"] = "BLUE",
    ["25:1182"] = "BLUE",
    ["25:1201"] = "BLUE",
    ["25:1215"] = "PURPLE",
    ["25:1254"] = "WHITE",
    ["25:1267"] = "LBLUE",
    ["25:1287"] = "BLUE",
    ["25:1333"] = "WHITE",
    ["25:1381"] = "LBLUE",
    ["26:3"] = "LBLUE",
    ["26:13"] = "PURPLE",
    ["26:25"] = "WHITE",
    ["26:70"] = "LBLUE",
    ["26:148"] = "WHITE",
    ["26:149"] = "WHITE",
    ["26:159"] = "BLUE",
    ["26:164"] = "BLUE",
    ["26:171"] = "WHITE",
    ["26:203"] = "BLUE",
    ["26:224"] = "BLUE",
    ["26:236"] = "LBLUE",
    ["26:267"] = "BLUE",
    ["26:293"] = "WHITE",
    ["26:306"] = "PURPLE",
    ["26:349"] = "PURPLE",
    ["26:376"] = "LBLUE",
    ["26:457"] = "WHITE",
    ["26:508"] = "PURPLE",
    ["26:526"] = "BLUE",
    ["26:542"] = "RED",
    ["26:594"] = "BLUE",
    ["26:641"] = "BLUE",
    ["26:676"] = "PINK",
    ["26:692"] = "BLUE",
    ["26:770"] = "LBLUE",
    ["26:775"] = "WHITE",
    ["26:829"] = "WHITE",
    ["26:873"] = "WHITE",
    ["26:884"] = "PURPLE",
    ["26:973"] = "BLUE",
    ["26:1083"] = "LBLUE",
    ["26:1099"] = "BLUE",
    ["26:1125"] = "PURPLE",
    ["26:1325"] = "WHITE",
    ["26:1374"] = "WHITE",
    ["26:1392"] = "WHITE",
    ["26:1418"] = "BLUE",
    ["27:32"] = "LBLUE",
    ["27:34"] = "LBLUE",
    ["27:39"] = "PURPLE",
    ["27:70"] = "LBLUE",
    ["27:99"] = "WHITE",
    ["27:100"] = "WHITE",
    ["27:171"] = "WHITE",
    ["27:177"] = "BLUE",
    ["27:198"] = "BLUE",
    ["27:291"] = "BLUE",
    ["27:327"] = "LBLUE",
    ["27:385"] = "BLUE",
    ["27:431"] = "PURPLE",
    ["27:462"] = "BLUE",
    ["27:473"] = "WHITE",
    ["27:499"] = "BLUE",
    ["27:535"] = "PURPLE",
    ["27:608"] = "PURPLE",
    ["27:633"] = "BLUE",
    ["27:666"] = "BLUE",
    ["27:703"] = "PURPLE",
    ["27:737"] = "PINK",
    ["27:754"] = "WHITE",
    ["27:773"] = "LBLUE",
    ["27:787"] = "PURPLE",
    ["27:822"] = "WHITE",
    ["27:909"] = "BLUE",
    ["27:948"] = "PINK",
    ["27:961"] = "PURPLE",
    ["27:1072"] = "PURPLE",
    ["27:1089"] = "PURPLE",
    ["27:1132"] = "BLUE",
    ["27:1188"] = "BLUE",
    ["27:1220"] = "BLUE",
    ["27:1245"] = "BLUE",
    ["27:1306"] = "WHITE",
    ["27:1355"] = "BLUE",
    ["28:28"] = "BLUE",
    ["28:144"] = "LBLUE",
    ["28:201"] = "LBLUE",
    ["28:240"] = "LBLUE",
    ["28:285"] = "BLUE",
    ["28:298"] = "WHITE",
    ["28:317"] = "BLUE",
    ["28:355"] = "BLUE",
    ["28:369"] = "LBLUE",
    ["28:432"] = "BLUE",
    ["28:483"] = "PURPLE",
    ["28:514"] = "PURPLE",
    ["28:610"] = "BLUE",
    ["28:698"] = "PURPLE",
    ["28:763"] = "PINK",
    ["28:783"] = "LBLUE",
    ["28:920"] = "WHITE",
    ["28:950"] = "BLUE",
    ["28:958"] = "BLUE",
    ["28:1012"] = "BLUE",
    ["28:1043"] = "PURPLE",
    ["28:1080"] = "BLUE",
    ["28:1152"] = "BLUE",
    ["28:1260"] = "LBLUE",
    ["28:1300"] = "WHITE",
    ["29:5"] = "WHITE",
    ["29:30"] = "LBLUE",
    ["29:41"] = "BLUE",
    ["29:83"] = "PURPLE",
    ["29:119"] = "WHITE",
    ["29:171"] = "WHITE",
    ["29:204"] = "LBLUE",
    ["29:246"] = "BLUE",
    ["29:250"] = "BLUE",
    ["29:256"] = "RED",
    ["29:323"] = "LBLUE",
    ["29:345"] = "BLUE",
    ["29:390"] = "PURPLE",
    ["29:405"] = "PURPLE",
    ["29:434"] = "BLUE",
    ["29:458"] = "WHITE",
    ["29:517"] = "BLUE",
    ["29:552"] = "BLUE",
    ["29:596"] = "PURPLE",
    ["29:638"] = "PINK",
    ["29:655"] = "BLUE",
    ["29:673"] = "BLUE",
    ["29:720"] = "PINK",
    ["29:797"] = "BLUE",
    ["29:814"] = "BLUE",
    ["29:870"] = "WHITE",
    ["29:880"] = "WHITE",
    ["29:953"] = "PURPLE",
    ["29:1014"] = "WHITE",
    ["29:1140"] = "BLUE",
    ["29:1155"] = "PINK",
    ["29:1160"] = "PURPLE",
    ["29:1272"] = "WHITE",
    ["29:1391"] = "WHITE",
    ["29:1427"] = "BLUE",
    ["30:2"] = "WHITE",
    ["30:17"] = "WHITE",
    ["30:36"] = "BLUE",
    ["30:159"] = "BLUE",
    ["30:179"] = "PURPLE",
    ["30:206"] = "WHITE",
    ["30:216"] = "BLUE",
    ["30:235"] = "LBLUE",
    ["30:242"] = "WHITE",
    ["30:248"] = "PURPLE",
    ["30:272"] = "PURPLE",
    ["30:289"] = "BLUE",
    ["30:303"] = "BLUE",
    ["30:374"] = "BLUE",
    ["30:439"] = "LBLUE",
    ["30:459"] = "WHITE",
    ["30:463"] = "BLUE",
    ["30:520"] = "PURPLE",
    ["30:539"] = "BLUE",
    ["30:555"] = "PURPLE",
    ["30:599"] = "BLUE",
    ["30:614"] = "PINK",
    ["30:671"] = "BLUE",
    ["30:684"] = "BLUE",
    ["30:722"] = "BLUE",
    ["30:733"] = "LBLUE",
    ["30:738"] = "LBLUE",
    ["30:766"] = "LBLUE",
    ["30:791"] = "PINK",
    ["30:795"] = "BLUE",
    ["30:816"] = "BLUE",
    ["30:839"] = "PURPLE",
    ["30:889"] = "PINK",
    ["30:905"] = "BLUE",
    ["30:964"] = "PURPLE",
    ["30:1010"] = "WHITE",
    ["30:1024"] = "BLUE",
    ["30:1159"] = "BLUE",
    ["30:1214"] = "PURPLE",
    ["30:1235"] = "BLUE",
    ["30:1252"] = "BLUE",
    ["30:1279"] = "WHITE",
    ["30:1286"] = "LBLUE",
    ["30:1299"] = "WHITE",
    ["30:1322"] = "LBLUE",
    ["30:1384"] = "LBLUE",
    ["31:292"] = "PINK",
    ["31:1172"] = "PINK",
    ["31:1183"] = "PURPLE",
    ["31:1205"] = "PURPLE",
    ["31:1268"] = "LBLUE",
    ["31:1297"] = "WHITE",
    ["31:1382"] = "BLUE",
    ["32:21"] = "LBLUE",
    ["32:32"] = "BLUE",
    ["32:71"] = "PURPLE",
    ["32:95"] = "LBLUE",
    ["32:104"] = "LBLUE",
    ["32:184"] = "PINK",
    ["32:211"] = "PINK",
    ["32:246"] = "PURPLE",
    ["32:275"] = "BLUE",
    ["32:327"] = "BLUE",
    ["32:338"] = "BLUE",
    ["32:346"] = "LBLUE",
    ["32:357"] = "BLUE",
    ["32:389"] = "RED",
    ["32:443"] = "LBLUE",
    ["32:485"] = "PURPLE",
    ["32:515"] = "BLUE",
    ["32:550"] = "BLUE",
    ["32:591"] = "PINK",
    ["32:635"] = "BLUE",
    ["32:667"] = "PURPLE",
    ["32:700"] = "BLUE",
    ["32:878"] = "LBLUE",
    ["32:894"] = "PURPLE",
    ["32:951"] = "PURPLE",
    ["32:960"] = "BLUE",
    ["32:997"] = "BLUE",
    ["32:1019"] = "LBLUE",
    ["32:1055"] = "PURPLE",
    ["32:1138"] = "BLUE",
    ["32:1181"] = "BLUE",
    ["32:1224"] = "PINK",
    ["32:1259"] = "BLUE",
    ["32:1292"] = "LBLUE",
    ["32:1342"] = "BLUE",
    ["32:1359"] = "BLUE",
    ["33:5"] = "WHITE",
    ["33:11"] = "BLUE",
    ["33:15"] = "LBLUE",
    ["33:28"] = "BLUE",
    ["33:102"] = "BLUE",
    ["33:141"] = "LBLUE",
    ["33:175"] = "WHITE",
    ["33:209"] = "WHITE",
    ["33:213"] = "PURPLE",
    ["33:245"] = "WHITE",
    ["33:250"] = "BLUE",
    ["33:354"] = "BLUE",
    ["33:365"] = "WHITE",
    ["33:423"] = "BLUE",
    ["33:442"] = "WHITE",
    ["33:481"] = "PINK",
    ["33:500"] = "PURPLE",
    ["33:536"] = "PURPLE",
    ["33:627"] = "BLUE",
    ["33:649"] = "BLUE",
    ["33:696"] = "RED",
    ["33:719"] = "PURPLE",
    ["33:728"] = "BLUE",
    ["33:752"] = "PURPLE",
    ["33:782"] = "LBLUE",
    ["33:847"] = "BLUE",
    ["33:893"] = "PURPLE",
    ["33:935"] = "WHITE",
    ["33:940"] = "LBLUE",
    ["33:1007"] = "LBLUE",
    ["33:1023"] = "LBLUE",
    ["33:1096"] = "BLUE",
    ["33:1133"] = "PINK",
    ["33:1163"] = "PURPLE",
    ["33:1246"] = "WHITE",
    ["33:1326"] = "WHITE",
    ["33:1354"] = "PINK",
    ["33:1386"] = "LBLUE",
    ["33:1436"] = "PURPLE",
    ["34:33"] = "BLUE",
    ["34:39"] = "PURPLE",
    ["34:61"] = "PURPLE",
    ["34:100"] = "WHITE",
    ["34:141"] = "LBLUE",
    ["34:148"] = "WHITE",
    ["34:199"] = "WHITE",
    ["34:262"] = "PURPLE",
    ["34:298"] = "WHITE",
    ["34:329"] = "BLUE",
    ["34:331"] = "PURPLE",
    ["34:366"] = "WHITE",
    ["34:368"] = "BLUE",
    ["34:386"] = "BLUE",
    ["34:403"] = "BLUE",
    ["34:448"] = "BLUE",
    ["34:482"] = "PURPLE",
    ["34:549"] = "BLUE",
    ["34:609"] = "PINK",
    ["34:630"] = "BLUE",
    ["34:679"] = "PURPLE",
    ["34:697"] = "BLUE",
    ["34:715"] = "BLUE",
    ["34:734"] = "PINK",
    ["34:755"] = "WHITE",
    ["34:804"] = "BLUE",
    ["34:820"] = "BLUE",
    ["34:867"] = "PURPLE",
    ["34:910"] = "PINK",
    ["34:931"] = "LBLUE",
    ["34:1037"] = "PINK",
    ["34:1094"] = "PURPLE",
    ["34:1134"] = "RED",
    ["34:1193"] = "BLUE",
    ["34:1211"] = "PINK",
    ["34:1225"] = "BLUE",
    ["34:1258"] = "BLUE",
    ["34:1278"] = "WHITE",
    ["34:1301"] = "WHITE",
    ["34:1310"] = "BLUE",
    ["34:1330"] = "WHITE",
    ["34:1341"] = "BLUE",
    ["34:1375"] = "WHITE",
    ["34:1388"] = "WHITE",
    ["34:1423"] = "PURPLE",
    ["35:3"] = "LBLUE",
    ["35:25"] = "WHITE",
    ["35:62"] = "PINK",
    ["35:99"] = "WHITE",
    ["35:107"] = "WHITE",
    ["35:145"] = "BLUE",
    ["35:158"] = "WHITE",
    ["35:164"] = "BLUE",
    ["35:166"] = "BLUE",
    ["35:170"] = "WHITE",
    ["35:191"] = "BLUE",
    ["35:214"] = "PURPLE",
    ["35:225"] = "BLUE",
    ["35:248"] = "PURPLE",
    ["35:263"] = "PURPLE",
    ["35:286"] = "PINK",
    ["35:294"] = "LBLUE",
    ["35:298"] = "WHITE",
    ["35:299"] = "LBLUE",
    ["35:323"] = "LBLUE",
    ["35:324"] = "BLUE",
    ["35:356"] = "PURPLE",
    ["35:450"] = "WHITE",
    ["35:484"] = "BLUE",
    ["35:537"] = "PINK",
    ["35:590"] = "BLUE",
    ["35:634"] = "PURPLE",
    ["35:699"] = "PURPLE",
    ["35:716"] = "PURPLE",
    ["35:746"] = "PURPLE",
    ["35:785"] = "WHITE",
    ["35:809"] = "BLUE",
    ["35:890"] = "BLUE",
    ["35:929"] = "BLUE",
    ["35:987"] = "PURPLE",
    ["35:1051"] = "BLUE",
    ["35:1077"] = "BLUE",
    ["35:1162"] = "BLUE",
    ["35:1192"] = "PURPLE",
    ["35:1247"] = "PURPLE",
    ["35:1261"] = "LBLUE",
    ["35:1331"] = "WHITE",
    ["35:1337"] = "LBLUE",
    ["35:1350"] = "PURPLE",
    ["35:1368"] = "WHITE",
    ["36:15"] = "LBLUE",
    ["36:27"] = "WHITE",
    ["36:34"] = "LBLUE",
    ["36:77"] = "WHITE",
    ["36:78"] = "WHITE",
    ["36:99"] = "WHITE",
    ["36:102"] = "BLUE",
    ["36:125"] = "PURPLE",
    ["36:130"] = "PINK",
    ["36:162"] = "PURPLE",
    ["36:164"] = "BLUE",
    ["36:168"] = "PURPLE",
    ["36:207"] = "LBLUE",
    ["36:219"] = "BLUE",
    ["36:230"] = "BLUE",
    ["36:258"] = "PINK",
    ["36:271"] = "PINK",
    ["36:295"] = "PINK",
    ["36:358"] = "PURPLE",
    ["36:373"] = "LBLUE",
    ["36:388"] = "PINK",
    ["36:404"] = "PINK",
    ["36:426"] = "BLUE",
    ["36:466"] = "LBLUE",
    ["36:467"] = "WHITE",
    ["36:501"] = "PURPLE",
    ["36:551"] = "PINK",
    ["36:592"] = "BLUE",
    ["36:650"] = "BLUE",
    ["36:668"] = "PURPLE",
    ["36:678"] = "RED",
    ["36:741"] = "LBLUE",
    ["36:749"] = "PURPLE",
    ["36:774"] = "BLUE",
    ["36:777"] = "WHITE",
    ["36:786"] = "BLUE",
    ["36:813"] = "PURPLE",
    ["36:825"] = "WHITE",
    ["36:848"] = "BLUE",
    ["36:907"] = "PURPLE",
    ["36:928"] = "BLUE",
    ["36:968"] = "BLUE",
    ["36:982"] = "BLUE",
    ["36:1030"] = "BLUE",
    ["36:1044"] = "PURPLE",
    ["36:1081"] = "PURPLE",
    ["36:1153"] = "PINK",
    ["36:1212"] = "LBLUE",
    ["36:1230"] = "BLUE",
    ["36:1248"] = "PINK",
    ["36:1273"] = "WHITE",
    ["36:1307"] = "WHITE",
    ["36:1315"] = "BLUE",
    ["36:1317"] = "LBLUE",
    ["36:1345"] = "BLUE",
    ["36:1369"] = "WHITE",
    ["36:1420"] = "PINK",
    ["38:46"] = "WHITE",
    ["38:70"] = "LBLUE",
    ["38:100"] = "WHITE",
    ["38:116"] = "WHITE",
    ["38:117"] = "BLUE",
    ["38:157"] = "LBLUE",
    ["38:159"] = "BLUE",
    ["38:165"] = "PINK",
    ["38:196"] = "PURPLE",
    ["38:232"] = "BLUE",
    ["38:298"] = "WHITE",
    ["38:312"] = "PINK",
    ["38:391"] = "PINK",
    ["38:406"] = "BLUE",
    ["38:502"] = "BLUE",
    ["38:518"] = "BLUE",
    ["38:597"] = "PINK",
    ["38:612"] = "PURPLE",
    ["38:642"] = "BLUE",
    ["38:685"] = "BLUE",
    ["38:865"] = "WHITE",
    ["38:883"] = "BLUE",
    ["38:896"] = "BLUE",
    ["38:914"] = "BLUE",
    ["38:954"] = "PURPLE",
    ["38:1028"] = "BLUE",
    ["38:1139"] = "BLUE",
    ["38:1226"] = "BLUE",
    ["38:1327"] = "WHITE",
    ["38:1343"] = "BLUE",
    ["38:1371"] = "WHITE",
    ["39:28"] = "BLUE",
    ["39:39"] = "PURPLE",
    ["39:61"] = "PURPLE",
    ["39:98"] = "BLUE",
    ["39:101"] = "WHITE",
    ["39:136"] = "WHITE",
    ["39:186"] = "BLUE",
    ["39:243"] = "LBLUE",
    ["39:247"] = "BLUE",
    ["39:287"] = "PURPLE",
    ["39:298"] = "WHITE",
    ["39:363"] = "LBLUE",
    ["39:378"] = "LBLUE",
    ["39:487"] = "PINK",
    ["39:519"] = "PURPLE",
    ["39:553"] = "BLUE",
    ["39:598"] = "BLUE",
    ["39:613"] = "PURPLE",
    ["39:686"] = "PURPLE",
    ["39:702"] = "BLUE",
    ["39:750"] = "PINK",
    ["39:765"] = "BLUE",
    ["39:815"] = "BLUE",
    ["39:861"] = "WHITE",
    ["39:864"] = "LBLUE",
    ["39:897"] = "PINK",
    ["39:901"] = "BLUE",
    ["39:934"] = "WHITE",
    ["39:955"] = "PURPLE",
    ["39:966"] = "BLUE",
    ["39:1022"] = "WHITE",
    ["39:1048"] = "BLUE",
    ["39:1084"] = "PINK",
    ["39:1151"] = "PURPLE",
    ["39:1234"] = "BLUE",
    ["39:1270"] = "WHITE",
    ["39:1320"] = "LBLUE",
    ["39:1394"] = "WHITE",
    ["40:26"] = "WHITE",
    ["40:60"] = "BLUE",
    ["40:70"] = "LBLUE",
    ["40:96"] = "WHITE",
    ["40:99"] = "WHITE",
    ["40:128"] = "PURPLE",
    ["40:147"] = "WHITE",
    ["40:200"] = "LBLUE",
    ["40:222"] = "RED",
    ["40:233"] = "LBLUE",
    ["40:253"] = "BLUE",
    ["40:304"] = "BLUE",
    ["40:319"] = "BLUE",
    ["40:361"] = "BLUE",
    ["40:503"] = "PINK",
    ["40:513"] = "BLUE",
    ["40:538"] = "BLUE",
    ["40:554"] = "PURPLE",
    ["40:624"] = "RED",
    ["40:670"] = "PURPLE",
    ["40:743"] = "BLUE",
    ["40:751"] = "BLUE",
    ["40:762"] = "WHITE",
    ["40:868"] = "PURPLE",
    ["40:877"] = "LBLUE",
    ["40:899"] = "PINK",
    ["40:935"] = "WHITE",
    ["40:956"] = "PURPLE",
    ["40:967"] = "BLUE",
    ["40:989"] = "PURPLE",
    ["40:996"] = "BLUE",
    ["40:1052"] = "PINK",
    ["40:1060"] = "BLUE",
    ["40:1101"] = "PINK",
    ["40:1161"] = "BLUE",
    ["40:1187"] = "BLUE",
    ["40:1251"] = "LBLUE",
    ["40:1271"] = "WHITE",
    ["40:1289"] = "LBLUE",
    ["40:1304"] = "WHITE",
    ["40:1316"] = "BLUE",
    ["40:1372"] = "WHITE",
    ["40:1379"] = "LBLUE",
    ["60:60"] = "PURPLE",
    ["60:77"] = "LBLUE",
    ["60:106"] = "RED",
    ["60:160"] = "LBLUE",
    ["60:189"] = "PURPLE",
    ["60:217"] = "BLUE",
    ["60:235"] = "BLUE",
    ["60:254"] = "PURPLE",
    ["60:257"] = "PINK",
    ["60:301"] = "PINK",
    ["60:321"] = "PINK",
    ["60:326"] = "PINK",
    ["60:360"] = "RED",
    ["60:383"] = "PURPLE",
    ["60:430"] = "RED",
    ["60:440"] = "PURPLE",
    ["60:445"] = "PINK",
    ["60:497"] = "RED",
    ["60:548"] = "RED",
    ["60:587"] = "RED",
    ["60:631"] = "PURPLE",
    ["60:644"] = "PINK",
    ["60:663"] = "BLUE",
    ["60:681"] = "PINK",
    ["60:714"] = "PINK",
    ["60:792"] = "PINK",
    ["60:862"] = "LBLUE",
    ["60:946"] = "RED",
    ["60:984"] = "RED",
    ["60:1001"] = "RED",
    ["60:1017"] = "PINK",
    ["60:1059"] = "BLUE",
    ["60:1073"] = "RED",
    ["60:1130"] = "PURPLE",
    ["60:1166"] = "PINK",
    ["60:1177"] = "RED",
    ["60:1216"] = "PINK",
    ["60:1223"] = "PURPLE",
    ["60:1243"] = "LBLUE",
    ["60:1311"] = "PURPLE",
    ["60:1319"] = "BLUE",
    ["60:1338"] = "PINK",
    ["60:1340"] = "PURPLE",
    ["60:1376"] = "PINK",
    ["60:1433"] = "PURPLE",
    ["61:25"] = "LBLUE",
    ["61:60"] = "PURPLE",
    ["61:115"] = "BLUE",
    ["61:183"] = "PURPLE",
    ["61:217"] = "BLUE",
    ["61:221"] = "PINK",
    ["61:236"] = "BLUE",
    ["61:277"] = "BLUE",
    ["61:290"] = "PURPLE",
    ["61:313"] = "PINK",
    ["61:318"] = "PURPLE",
    ["61:332"] = "LBLUE",
    ["61:339"] = "PINK",
    ["61:364"] = "BLUE",
    ["61:443"] = "LBLUE",
    ["61:454"] = "LBLUE",
    ["61:489"] = "BLUE",
    ["61:504"] = "RED",
    ["61:540"] = "BLUE",
    ["61:637"] = "PURPLE",
    ["61:653"] = "RED",
    ["61:657"] = "BLUE",
    ["61:705"] = "PINK",
    ["61:796"] = "BLUE",
    ["61:817"] = "PURPLE",
    ["61:818"] = "BLUE",
    ["61:830"] = "BLUE",
    ["61:922"] = "PURPLE",
    ["61:991"] = "PINK",
    ["61:1027"] = "PINK",
    ["61:1031"] = "PURPLE",
    ["61:1040"] = "RED",
    ["61:1065"] = "PINK",
    ["61:1102"] = "BLUE",
    ["61:1136"] = "PURPLE",
    ["61:1142"] = "RED",
    ["61:1173"] = "PINK",
    ["61:1186"] = "BLUE",
    ["61:1217"] = "PURPLE",
    ["61:1253"] = "LBLUE",
    ["61:1284"] = "BLUE",
    ["61:1323"] = "PURPLE",
    ["61:1377"] = "PURPLE",
    ["61:1431"] = "BLUE",
    ["63:12"] = "BLUE",
    ["63:32"] = "LBLUE",
    ["63:147"] = "WHITE",
    ["63:218"] = "BLUE",
    ["63:268"] = "PURPLE",
    ["63:269"] = "PINK",
    ["63:270"] = "RED",
    ["63:297"] = "BLUE",
    ["63:298"] = "WHITE",
    ["63:315"] = "BLUE",
    ["63:322"] = "BLUE",
    ["63:325"] = "PURPLE",
    ["63:333"] = "WHITE",
    ["63:334"] = "BLUE",
    ["63:350"] = "PURPLE",
    ["63:366"] = "WHITE",
    ["63:435"] = "PURPLE",
    ["63:453"] = "BLUE",
    ["63:476"] = "PINK",
    ["63:543"] = "PURPLE",
    ["63:602"] = "BLUE",
    ["63:622"] = "BLUE",
    ["63:643"] = "PINK",
    ["63:687"] = "PURPLE",
    ["63:709"] = "PURPLE",
    ["63:859"] = "BLUE",
    ["63:933"] = "LBLUE",
    ["63:937"] = "PURPLE",
    ["63:944"] = "BLUE",
    ["63:976"] = "BLUE",
    ["63:1036"] = "BLUE",
    ["63:1064"] = "PURPLE",
    ["63:1076"] = "WHITE",
    ["63:1195"] = "LBLUE",
    ["63:1329"] = "WHITE",
    ["63:1390"] = "WHITE",
    ["64:12"] = "BLUE",
    ["64:27"] = "WHITE",
    ["64:37"] = "BLUE",
    ["64:40"] = "WHITE",
    ["64:123"] = "BLUE",
    ["64:522"] = "RED",
    ["64:523"] = "PINK",
    ["64:595"] = "PURPLE",
    ["64:683"] = "PINK",
    ["64:701"] = "BLUE",
    ["64:721"] = "BLUE",
    ["64:798"] = "LBLUE",
    ["64:843"] = "PINK",
    ["64:866"] = "WHITE",
    ["64:892"] = "BLUE",
    ["64:924"] = "WHITE",
    ["64:952"] = "BLUE",
    ["64:1011"] = "LBLUE",
    ["64:1047"] = "BLUE",
    ["64:1145"] = "PURPLE",
    ["64:1232"] = "PURPLE",
    ["64:1237"] = "WHITE",
    ["64:1276"] = "WHITE",
    ["64:1293"] = "LBLUE",
    ["64:1363"] = "LBLUE",
    ["64:1389"] = "WHITE",
    ["500:5"] = "RED",
    ["500:12"] = "RED",
    ["500:38"] = "RED",
    ["500:40"] = "RED",
    ["500:42"] = "RED",
    ["500:43"] = "RED",
    ["500:44"] = "RED",
    ["500:59"] = "RED",
    ["500:72"] = "RED",
    ["500:77"] = "RED",
    ["500:98"] = "RED",
    ["500:143"] = "RED",
    ["500:175"] = "RED",
    ["500:409"] = "RED",
    ["500:410"] = "RED",
    ["500:413"] = "RED",
    ["500:414"] = "RED",
    ["500:415"] = "RED",
    ["500:416"] = "RED",
    ["500:417"] = "RED",
    ["500:418"] = "RED",
    ["500:419"] = "RED",
    ["500:420"] = "RED",
    ["500:421"] = "RED",
    ["500:558"] = "RED",
    ["500:563"] = "RED",
    ["500:568"] = "RED",
    ["500:569"] = "RED",
    ["500:570"] = "RED",
    ["500:571"] = "RED",
    ["500:572"] = "RED",
    ["500:573"] = "RED",
    ["500:578"] = "RED",
    ["500:580"] = "RED",
    ["503:5"] = "RED",
    ["503:12"] = "RED",
    ["503:38"] = "RED",
    ["503:42"] = "RED",
    ["503:43"] = "RED",
    ["503:44"] = "RED",
    ["503:59"] = "RED",
    ["503:72"] = "RED",
    ["503:77"] = "RED",
    ["503:143"] = "RED",
    ["503:175"] = "RED",
    ["503:735"] = "RED",
    ["505:5"] = "RED",
    ["505:12"] = "RED",
    ["505:38"] = "RED",
    ["505:40"] = "RED",
    ["505:42"] = "RED",
    ["505:43"] = "RED",
    ["505:44"] = "RED",
    ["505:59"] = "RED",
    ["505:72"] = "RED",
    ["505:77"] = "RED",
    ["505:98"] = "RED",
    ["505:143"] = "RED",
    ["505:175"] = "RED",
    ["505:409"] = "RED",
    ["505:410"] = "RED",
    ["505:413"] = "RED",
    ["505:414"] = "RED",
    ["505:415"] = "RED",
    ["505:416"] = "RED",
    ["505:417"] = "RED",
    ["505:418"] = "RED",
    ["505:419"] = "RED",
    ["505:420"] = "RED",
    ["505:421"] = "RED",
    ["505:559"] = "RED",
    ["505:564"] = "RED",
    ["505:568"] = "RED",
    ["505:569"] = "RED",
    ["505:570"] = "RED",
    ["505:571"] = "RED",
    ["505:572"] = "RED",
    ["505:574"] = "RED",
    ["505:578"] = "RED",
    ["505:580"] = "RED",
    ["506:5"] = "RED",
    ["506:12"] = "RED",
    ["506:38"] = "RED",
    ["506:40"] = "RED",
    ["506:42"] = "RED",
    ["506:43"] = "RED",
    ["506:44"] = "RED",
    ["506:59"] = "RED",
    ["506:72"] = "RED",
    ["506:77"] = "RED",
    ["506:98"] = "RED",
    ["506:143"] = "RED",
    ["506:175"] = "RED",
    ["506:409"] = "RED",
    ["506:410"] = "RED",
    ["506:413"] = "RED",
    ["506:414"] = "RED",
    ["506:415"] = "RED",
    ["506:416"] = "RED",
    ["506:417"] = "RED",
    ["506:418"] = "RED",
    ["506:419"] = "RED",
    ["506:420"] = "RED",
    ["506:421"] = "RED",
    ["506:560"] = "RED",
    ["506:565"] = "RED",
    ["506:568"] = "RED",
    ["506:569"] = "RED",
    ["506:570"] = "RED",
    ["506:571"] = "RED",
    ["506:572"] = "RED",
    ["506:575"] = "RED",
    ["506:578"] = "RED",
    ["506:580"] = "RED",
    ["507:5"] = "RED",
    ["507:12"] = "RED",
    ["507:38"] = "RED",
    ["507:40"] = "RED",
    ["507:42"] = "RED",
    ["507:43"] = "RED",
    ["507:44"] = "RED",
    ["507:59"] = "RED",
    ["507:72"] = "RED",
    ["507:77"] = "RED",
    ["507:98"] = "RED",
    ["507:143"] = "RED",
    ["507:175"] = "RED",
    ["507:409"] = "RED",
    ["507:410"] = "RED",
    ["507:413"] = "RED",
    ["507:414"] = "RED",
    ["507:415"] = "RED",
    ["507:416"] = "RED",
    ["507:417"] = "RED",
    ["507:418"] = "RED",
    ["507:419"] = "RED",
    ["507:420"] = "RED",
    ["507:421"] = "RED",
    ["507:561"] = "RED",
    ["507:566"] = "RED",
    ["507:568"] = "RED",
    ["507:569"] = "RED",
    ["507:570"] = "RED",
    ["507:571"] = "RED",
    ["507:572"] = "RED",
    ["507:576"] = "RED",
    ["507:578"] = "RED",
    ["507:582"] = "RED",
    ["508:5"] = "RED",
    ["508:12"] = "RED",
    ["508:38"] = "RED",
    ["508:40"] = "RED",
    ["508:42"] = "RED",
    ["508:43"] = "RED",
    ["508:44"] = "RED",
    ["508:59"] = "RED",
    ["508:72"] = "RED",
    ["508:77"] = "RED",
    ["508:98"] = "RED",
    ["508:143"] = "RED",
    ["508:175"] = "RED",
    ["508:409"] = "RED",
    ["508:411"] = "RED",
    ["508:413"] = "RED",
    ["508:414"] = "RED",
    ["508:415"] = "RED",
    ["508:416"] = "RED",
    ["508:417"] = "RED",
    ["508:418"] = "RED",
    ["508:419"] = "RED",
    ["508:420"] = "RED",
    ["508:421"] = "RED",
    ["508:562"] = "RED",
    ["508:567"] = "RED",
    ["508:568"] = "RED",
    ["508:569"] = "RED",
    ["508:570"] = "RED",
    ["508:571"] = "RED",
    ["508:572"] = "RED",
    ["508:577"] = "RED",
    ["508:579"] = "RED",
    ["508:581"] = "RED",
    ["509:5"] = "RED",
    ["509:12"] = "RED",
    ["509:38"] = "RED",
    ["509:40"] = "RED",
    ["509:42"] = "RED",
    ["509:43"] = "RED",
    ["509:44"] = "RED",
    ["509:59"] = "RED",
    ["509:72"] = "RED",
    ["509:77"] = "RED",
    ["509:143"] = "RED",
    ["509:175"] = "RED",
    ["509:409"] = "RED",
    ["509:411"] = "RED",
    ["509:413"] = "RED",
    ["509:414"] = "RED",
    ["509:415"] = "RED",
    ["509:416"] = "RED",
    ["509:417"] = "RED",
    ["509:418"] = "RED",
    ["509:419"] = "RED",
    ["509:420"] = "RED",
    ["509:421"] = "RED",
    ["509:568"] = "RED",
    ["509:569"] = "RED",
    ["509:570"] = "RED",
    ["509:571"] = "RED",
    ["509:572"] = "RED",
    ["509:579"] = "RED",
    ["509:581"] = "RED",
    ["509:620"] = "RED",
    ["509:1107"] = "RED",
    ["509:1112"] = "RED",
    ["509:1117"] = "RED",
    ["512:5"] = "RED",
    ["512:12"] = "RED",
    ["512:38"] = "RED",
    ["512:40"] = "RED",
    ["512:42"] = "RED",
    ["512:43"] = "RED",
    ["512:44"] = "RED",
    ["512:59"] = "RED",
    ["512:72"] = "RED",
    ["512:77"] = "RED",
    ["512:143"] = "RED",
    ["512:175"] = "RED",
    ["512:409"] = "RED",
    ["512:411"] = "RED",
    ["512:413"] = "RED",
    ["512:414"] = "RED",
    ["512:415"] = "RED",
    ["512:416"] = "RED",
    ["512:417"] = "RED",
    ["512:418"] = "RED",
    ["512:419"] = "RED",
    ["512:420"] = "RED",
    ["512:421"] = "RED",
    ["512:568"] = "RED",
    ["512:569"] = "RED",
    ["512:570"] = "RED",
    ["512:571"] = "RED",
    ["512:572"] = "RED",
    ["512:579"] = "RED",
    ["512:581"] = "RED",
    ["512:621"] = "RED",
    ["512:1106"] = "RED",
    ["512:1111"] = "RED",
    ["512:1116"] = "RED",
    ["514:5"] = "RED",
    ["514:12"] = "RED",
    ["514:38"] = "RED",
    ["514:40"] = "RED",
    ["514:42"] = "RED",
    ["514:43"] = "RED",
    ["514:44"] = "RED",
    ["514:59"] = "RED",
    ["514:72"] = "RED",
    ["514:77"] = "RED",
    ["514:98"] = "RED",
    ["514:143"] = "RED",
    ["514:175"] = "RED",
    ["514:409"] = "RED",
    ["514:411"] = "RED",
    ["514:413"] = "RED",
    ["514:414"] = "RED",
    ["514:415"] = "RED",
    ["514:416"] = "RED",
    ["514:417"] = "RED",
    ["514:418"] = "RED",
    ["514:419"] = "RED",
    ["514:420"] = "RED",
    ["514:421"] = "RED",
    ["514:568"] = "RED",
    ["514:569"] = "RED",
    ["514:570"] = "RED",
    ["514:571"] = "RED",
    ["514:572"] = "RED",
    ["514:579"] = "RED",
    ["514:581"] = "RED",
    ["514:1104"] = "RED",
    ["514:1109"] = "RED",
    ["514:1114"] = "RED",
    ["515:5"] = "RED",
    ["515:12"] = "RED",
    ["515:38"] = "RED",
    ["515:40"] = "RED",
    ["515:42"] = "RED",
    ["515:43"] = "RED",
    ["515:44"] = "RED",
    ["515:59"] = "RED",
    ["515:72"] = "RED",
    ["515:77"] = "RED",
    ["515:98"] = "RED",
    ["515:143"] = "RED",
    ["515:175"] = "RED",
    ["515:409"] = "RED",
    ["515:411"] = "RED",
    ["515:413"] = "RED",
    ["515:414"] = "RED",
    ["515:415"] = "RED",
    ["515:418"] = "RED",
    ["515:420"] = "RED",
    ["515:421"] = "RED",
    ["515:568"] = "RED",
    ["515:569"] = "RED",
    ["515:570"] = "RED",
    ["515:571"] = "RED",
    ["515:572"] = "RED",
    ["515:579"] = "RED",
    ["515:581"] = "RED",
    ["515:617"] = "RED",
    ["515:618"] = "RED",
    ["515:619"] = "RED",
    ["515:1105"] = "RED",
    ["515:1110"] = "RED",
    ["515:1115"] = "RED",
    ["516:5"] = "RED",
    ["516:12"] = "RED",
    ["516:38"] = "RED",
    ["516:40"] = "RED",
    ["516:42"] = "RED",
    ["516:43"] = "RED",
    ["516:44"] = "RED",
    ["516:59"] = "RED",
    ["516:72"] = "RED",
    ["516:77"] = "RED",
    ["516:98"] = "RED",
    ["516:143"] = "RED",
    ["516:175"] = "RED",
    ["516:409"] = "RED",
    ["516:411"] = "RED",
    ["516:413"] = "RED",
    ["516:414"] = "RED",
    ["516:415"] = "RED",
    ["516:418"] = "RED",
    ["516:420"] = "RED",
    ["516:421"] = "RED",
    ["516:568"] = "RED",
    ["516:569"] = "RED",
    ["516:570"] = "RED",
    ["516:571"] = "RED",
    ["516:572"] = "RED",
    ["516:579"] = "RED",
    ["516:581"] = "RED",
    ["516:617"] = "RED",
    ["516:618"] = "RED",
    ["516:619"] = "RED",
    ["516:1108"] = "RED",
    ["516:1113"] = "RED",
    ["516:1118"] = "RED",
    ["517:5"] = "RED",
    ["517:12"] = "RED",
    ["517:38"] = "RED",
    ["517:42"] = "RED",
    ["517:43"] = "RED",
    ["517:44"] = "RED",
    ["517:59"] = "RED",
    ["517:72"] = "RED",
    ["517:77"] = "RED",
    ["517:143"] = "RED",
    ["517:175"] = "RED",
    ["517:409"] = "RED",
    ["517:410"] = "RED",
    ["517:413"] = "RED",
    ["517:414"] = "RED",
    ["517:415"] = "RED",
    ["517:416"] = "RED",
    ["517:417"] = "RED",
    ["517:418"] = "RED",
    ["517:419"] = "RED",
    ["517:420"] = "RED",
    ["517:421"] = "RED",
    ["517:621"] = "RED",
    ["517:735"] = "RED",
    ["518:5"] = "RED",
    ["518:12"] = "RED",
    ["518:38"] = "RED",
    ["518:42"] = "RED",
    ["518:43"] = "RED",
    ["518:44"] = "RED",
    ["518:59"] = "RED",
    ["518:72"] = "RED",
    ["518:77"] = "RED",
    ["518:98"] = "RED",
    ["518:143"] = "RED",
    ["518:175"] = "RED",
    ["518:409"] = "RED",
    ["518:410"] = "RED",
    ["518:413"] = "RED",
    ["518:414"] = "RED",
    ["518:415"] = "RED",
    ["518:416"] = "RED",
    ["518:417"] = "RED",
    ["518:418"] = "RED",
    ["518:419"] = "RED",
    ["518:420"] = "RED",
    ["518:421"] = "RED",
    ["518:735"] = "RED",
    ["519:5"] = "RED",
    ["519:12"] = "RED",
    ["519:38"] = "RED",
    ["519:42"] = "RED",
    ["519:43"] = "RED",
    ["519:44"] = "RED",
    ["519:59"] = "RED",
    ["519:72"] = "RED",
    ["519:77"] = "RED",
    ["519:98"] = "RED",
    ["519:143"] = "RED",
    ["519:175"] = "RED",
    ["519:409"] = "RED",
    ["519:413"] = "RED",
    ["519:414"] = "RED",
    ["519:415"] = "RED",
    ["519:416"] = "RED",
    ["519:417"] = "RED",
    ["519:418"] = "RED",
    ["519:419"] = "RED",
    ["519:420"] = "RED",
    ["519:421"] = "RED",
    ["519:735"] = "RED",
    ["519:857"] = "RED",
    ["520:5"] = "RED",
    ["520:12"] = "RED",
    ["520:38"] = "RED",
    ["520:42"] = "RED",
    ["520:43"] = "RED",
    ["520:44"] = "RED",
    ["520:59"] = "RED",
    ["520:72"] = "RED",
    ["520:77"] = "RED",
    ["520:98"] = "RED",
    ["520:143"] = "RED",
    ["520:175"] = "RED",
    ["520:409"] = "RED",
    ["520:413"] = "RED",
    ["520:414"] = "RED",
    ["520:415"] = "RED",
    ["520:416"] = "RED",
    ["520:417"] = "RED",
    ["520:418"] = "RED",
    ["520:419"] = "RED",
    ["520:420"] = "RED",
    ["520:421"] = "RED",
    ["520:735"] = "RED",
    ["520:857"] = "RED",
    ["521:5"] = "RED",
    ["521:12"] = "RED",
    ["521:38"] = "RED",
    ["521:42"] = "RED",
    ["521:43"] = "RED",
    ["521:44"] = "RED",
    ["521:59"] = "RED",
    ["521:72"] = "RED",
    ["521:77"] = "RED",
    ["521:98"] = "RED",
    ["521:143"] = "RED",
    ["521:175"] = "RED",
    ["521:409"] = "RED",
    ["521:410"] = "RED",
    ["521:413"] = "RED",
    ["521:414"] = "RED",
    ["521:415"] = "RED",
    ["521:416"] = "RED",
    ["521:417"] = "RED",
    ["521:418"] = "RED",
    ["521:419"] = "RED",
    ["521:420"] = "RED",
    ["521:421"] = "RED",
    ["521:735"] = "RED",
    ["522:5"] = "RED",
    ["522:12"] = "RED",
    ["522:38"] = "RED",
    ["522:42"] = "RED",
    ["522:43"] = "RED",
    ["522:44"] = "RED",
    ["522:59"] = "RED",
    ["522:72"] = "RED",
    ["522:77"] = "RED",
    ["522:98"] = "RED",
    ["522:143"] = "RED",
    ["522:175"] = "RED",
    ["522:409"] = "RED",
    ["522:413"] = "RED",
    ["522:414"] = "RED",
    ["522:415"] = "RED",
    ["522:416"] = "RED",
    ["522:417"] = "RED",
    ["522:418"] = "RED",
    ["522:419"] = "RED",
    ["522:420"] = "RED",
    ["522:421"] = "RED",
    ["522:735"] = "RED",
    ["522:857"] = "RED",
    ["523:5"] = "RED",
    ["523:12"] = "RED",
    ["523:38"] = "RED",
    ["523:42"] = "RED",
    ["523:43"] = "RED",
    ["523:44"] = "RED",
    ["523:59"] = "RED",
    ["523:72"] = "RED",
    ["523:77"] = "RED",
    ["523:98"] = "RED",
    ["523:143"] = "RED",
    ["523:175"] = "RED",
    ["523:409"] = "RED",
    ["523:414"] = "RED",
    ["523:415"] = "RED",
    ["523:416"] = "RED",
    ["523:417"] = "RED",
    ["523:735"] = "RED",
    ["523:852"] = "RED",
    ["523:853"] = "RED",
    ["523:854"] = "RED",
    ["523:855"] = "RED",
    ["523:856"] = "RED",
    ["523:858"] = "RED",
    ["525:5"] = "RED",
    ["525:12"] = "RED",
    ["525:38"] = "RED",
    ["525:42"] = "RED",
    ["525:43"] = "RED",
    ["525:44"] = "RED",
    ["525:59"] = "RED",
    ["525:72"] = "RED",
    ["525:77"] = "RED",
    ["525:98"] = "RED",
    ["525:143"] = "RED",
    ["525:175"] = "RED",
    ["525:409"] = "RED",
    ["525:410"] = "RED",
    ["525:413"] = "RED",
    ["525:414"] = "RED",
    ["525:415"] = "RED",
    ["525:416"] = "RED",
    ["525:417"] = "RED",
    ["525:418"] = "RED",
    ["525:419"] = "RED",
    ["525:420"] = "RED",
    ["525:421"] = "RED",
    ["525:735"] = "RED",
    ["526:5"] = "RED",
    ["526:12"] = "RED",
    ["526:38"] = "RED",
    ["526:42"] = "RED",
    ["526:43"] = "RED",
    ["526:44"] = "RED",
    ["526:59"] = "RED",
    ["526:72"] = "RED",
    ["526:77"] = "RED",
    ["526:143"] = "RED",
    ["526:175"] = "RED",
    ["526:735"] = "RED",
    ["4725:10085"] = "GOLD",
    ["4725:10086"] = "GOLD",
    ["4725:10087"] = "GOLD",
    ["4725:10088"] = "GOLD",
    ["5027:10006"] = "GOLD",
    ["5027:10007"] = "GOLD",
    ["5027:10008"] = "GOLD",
    ["5027:10039"] = "GOLD",
    ["5030:1405"] = "GOLD",
    ["5030:1406"] = "GOLD",
    ["5030:1407"] = "GOLD",
    ["5030:1408"] = "GOLD",
    ["5030:1409"] = "GOLD",
    ["5030:1410"] = "GOLD",
    ["5030:1417"] = "GOLD",
    ["5030:10018"] = "GOLD",
    ["5030:10019"] = "GOLD",
    ["5030:10037"] = "GOLD",
    ["5030:10038"] = "GOLD",
    ["5030:10045"] = "GOLD",
    ["5030:10046"] = "GOLD",
    ["5030:10047"] = "GOLD",
    ["5030:10048"] = "GOLD",
    ["5030:10073"] = "GOLD",
    ["5030:10074"] = "GOLD",
    ["5030:10075"] = "GOLD",
    ["5030:10076"] = "GOLD",
    ["5031:1398"] = "GOLD",
    ["5031:1399"] = "GOLD",
    ["5031:1400"] = "GOLD",
    ["5031:1401"] = "GOLD",
    ["5031:1402"] = "GOLD",
    ["5031:1404"] = "GOLD",
    ["5031:1412"] = "GOLD",
    ["5031:1439"] = "GOLD",
    ["5031:10013"] = "GOLD",
    ["5031:10015"] = "GOLD",
    ["5031:10016"] = "GOLD",
    ["5031:10040"] = "GOLD",
    ["5031:10041"] = "GOLD",
    ["5031:10042"] = "GOLD",
    ["5031:10043"] = "GOLD",
    ["5031:10044"] = "GOLD",
    ["5031:10069"] = "GOLD",
    ["5031:10070"] = "GOLD",
    ["5031:10071"] = "GOLD",
    ["5031:10072"] = "GOLD",
    ["5032:10009"] = "GOLD",
    ["5032:10010"] = "GOLD",
    ["5032:10021"] = "GOLD",
    ["5032:10036"] = "GOLD",
    ["5032:10053"] = "GOLD",
    ["5032:10054"] = "GOLD",
    ["5032:10055"] = "GOLD",
    ["5032:10056"] = "GOLD",
    ["5032:10081"] = "GOLD",
    ["5032:10082"] = "GOLD",
    ["5032:10083"] = "GOLD",
    ["5032:10084"] = "GOLD",
    ["5033:10024"] = "GOLD",
    ["5033:10026"] = "GOLD",
    ["5033:10027"] = "GOLD",
    ["5033:10028"] = "GOLD",
    ["5033:10049"] = "GOLD",
    ["5033:10050"] = "GOLD",
    ["5033:10051"] = "GOLD",
    ["5033:10052"] = "GOLD",
    ["5033:10077"] = "GOLD",
    ["5033:10078"] = "GOLD",
    ["5033:10079"] = "GOLD",
    ["5033:10080"] = "GOLD",
    ["5034:1413"] = "GOLD",
    ["5034:1414"] = "GOLD",
    ["5034:1415"] = "GOLD",
    ["5034:1416"] = "GOLD",
    ["5034:1437"] = "GOLD",
    ["5034:1438"] = "GOLD",
    ["5034:1440"] = "GOLD",
    ["5034:10030"] = "GOLD",
    ["5034:10033"] = "GOLD",
    ["5034:10034"] = "GOLD",
    ["5034:10035"] = "GOLD",
    ["5034:10061"] = "GOLD",
    ["5034:10062"] = "GOLD",
    ["5034:10063"] = "GOLD",
    ["5034:10064"] = "GOLD",
    ["5034:10065"] = "GOLD",
    ["5034:10066"] = "GOLD",
    ["5034:10067"] = "GOLD",
    ["5034:10068"] = "GOLD",
    ["5035:10057"] = "GOLD",
    ["5035:10058"] = "GOLD",
    ["5035:10059"] = "GOLD",
    ["5035:10060"] = "GOLD",
}


local RARITY_LABEL = {
    WHITE  = "⚪ ",  -- Consumer / common
    LBLUE  = "🔹 ",  -- Industrial / light blue
    BLUE   = "🔵 ",  -- Mil-Spec
    PURPLE = "🟣 ",  -- Restricted / Mythical
    PINK   = "🌸 ",  -- Classified / Legendary; pink circle emoji usually doesn't exist
    RED    = "🔴 ",  -- Covert / Ancient
    GOLD   = "🟡 ",  -- Knives / Gloves / Extraordinary
    ORANGE = "🟠 ",  -- Contraband
}
local RARITY_ORDER = { WHITE = 1, LBLUE = 2, BLUE = 3, PURPLE = 4, PINK = 5, RED = 6, GOLD = 7, ORANGE = 8 }
local function skin_rarity(def, paint)
    if paint == 0 then return "WHITE" end
    local r = RARITY_BY_SKIN[tostring(def) .. ":" .. tostring(paint)]
    if r then return r end
    if (def and def >= 500 and def <= 526) or def == 4725 or def == 5027 or def == 5030 or def == 5031 or def == 5032 or def == 5033 or def == 5034 or def == 5035 then
        return "GOLD"
    end
    return "WHITE"
end

local SKIN_LEGACY_BY_SKIN = {
    ["1:17"] = true,
    ["1:90"] = true,
    ["1:185"] = true,
    ["1:231"] = true,
    ["1:232"] = true,
    ["1:237"] = true,
    ["1:273"] = true,
    ["1:296"] = true,
    ["1:328"] = true,
    ["1:347"] = true,
    ["1:351"] = true,
    ["1:397"] = true,
    ["1:425"] = true,
    ["1:468"] = true,
    ["1:469"] = true,
    ["1:470"] = true,
    ["1:509"] = true,
    ["1:527"] = true,
    ["1:603"] = true,
    ["1:645"] = true,
    ["1:711"] = true,
    ["1:757"] = true,
    ["1:764"] = true,
    ["1:805"] = true,
    ["1:841"] = true,
    ["1:945"] = true,
    ["1:962"] = true,
    ["1:992"] = true,
    ["1:1006"] = true,
    ["1:1050"] = true,
    ["1:1090"] = true,
    ["2:43"] = true,
    ["2:190"] = true,
    ["2:220"] = true,
    ["2:249"] = true,
    ["2:261"] = true,
    ["2:307"] = true,
    ["2:330"] = true,
    ["2:396"] = true,
    ["2:447"] = true,
    ["2:450"] = true,
    ["2:491"] = true,
    ["2:528"] = true,
    ["2:544"] = true,
    ["2:625"] = true,
    ["2:658"] = true,
    ["2:747"] = true,
    ["2:860"] = true,
    ["2:895"] = true,
    ["2:903"] = true,
    ["2:978"] = true,
    ["2:998"] = true,
    ["2:1005"] = true,
    ["2:1091"] = true,
    ["2:1126"] = true,
    ["2:1156"] = true,
    ["3:44"] = true,
    ["3:78"] = true,
    ["3:223"] = true,
    ["3:252"] = true,
    ["3:265"] = true,
    ["3:352"] = true,
    ["3:387"] = true,
    ["3:427"] = true,
    ["3:464"] = true,
    ["3:510"] = true,
    ["3:530"] = true,
    ["3:585"] = true,
    ["3:605"] = true,
    ["3:646"] = true,
    ["3:660"] = true,
    ["3:693"] = true,
    ["3:729"] = true,
    ["3:784"] = true,
    ["3:837"] = true,
    ["3:906"] = true,
    ["3:979"] = true,
    ["3:1082"] = true,
    ["3:1093"] = true,
    ["3:1128"] = true,
    ["4:48"] = true,
    ["4:84"] = true,
    ["4:159"] = true,
    ["4:230"] = true,
    ["4:278"] = true,
    ["4:293"] = true,
    ["4:353"] = true,
    ["4:367"] = true,
    ["4:381"] = true,
    ["4:399"] = true,
    ["4:479"] = true,
    ["4:495"] = true,
    ["4:532"] = true,
    ["4:586"] = true,
    ["4:607"] = true,
    ["4:623"] = true,
    ["4:680"] = true,
    ["4:694"] = true,
    ["4:713"] = true,
    ["4:732"] = true,
    ["4:789"] = true,
    ["4:808"] = true,
    ["4:918"] = true,
    ["4:957"] = true,
    ["4:963"] = true,
    ["4:988"] = true,
    ["4:1016"] = true,
    ["4:1039"] = true,
    ["4:1100"] = true,
    ["4:1119"] = true,
    ["4:1120"] = true,
    ["4:1121"] = true,
    ["4:1122"] = true,
    ["4:1123"] = true,
    ["4:1158"] = true,
    ["4:1227"] = true,
    ["4:1240"] = true,
    ["7:14"] = true,
    ["7:44"] = true,
    ["7:172"] = true,
    ["7:180"] = true,
    ["7:226"] = true,
    ["7:282"] = true,
    ["7:300"] = true,
    ["7:302"] = true,
    ["7:316"] = true,
    ["7:340"] = true,
    ["7:341"] = true,
    ["7:380"] = true,
    ["7:394"] = true,
    ["7:422"] = true,
    ["7:456"] = true,
    ["7:474"] = true,
    ["7:490"] = true,
    ["7:506"] = true,
    ["7:524"] = true,
    ["7:600"] = true,
    ["7:639"] = true,
    ["7:656"] = true,
    ["7:675"] = true,
    ["7:707"] = true,
    ["7:724"] = true,
    ["7:745"] = true,
    ["7:795"] = true,
    ["7:801"] = true,
    ["7:836"] = true,
    ["7:885"] = true,
    ["7:921"] = true,
    ["7:941"] = true,
    ["7:959"] = true,
    ["7:1004"] = true,
    ["7:1018"] = true,
    ["7:1035"] = true,
    ["7:1070"] = true,
    ["7:1087"] = true,
    ["7:1141"] = true,
    ["7:1143"] = true,
    ["7:1221"] = true,
    ["7:1238"] = true,
    ["8:9"] = true,
    ["8:10"] = true,
    ["8:73"] = true,
    ["8:280"] = true,
    ["8:305"] = true,
    ["8:455"] = true,
    ["8:507"] = true,
    ["8:541"] = true,
    ["8:583"] = true,
    ["8:601"] = true,
    ["8:674"] = true,
    ["8:690"] = true,
    ["8:708"] = true,
    ["8:727"] = true,
    ["8:740"] = true,
    ["8:758"] = true,
    ["8:779"] = true,
    ["8:823"] = true,
    ["8:845"] = true,
    ["8:886"] = true,
    ["8:913"] = true,
    ["8:927"] = true,
    ["8:942"] = true,
    ["8:995"] = true,
    ["8:1033"] = true,
    ["8:1088"] = true,
    ["8:1249"] = true,
    ["9:51"] = true,
    ["9:84"] = true,
    ["9:174"] = true,
    ["9:181"] = true,
    ["9:212"] = true,
    ["9:227"] = true,
    ["9:251"] = true,
    ["9:259"] = true,
    ["9:279"] = true,
    ["9:344"] = true,
    ["9:395"] = true,
    ["9:424"] = true,
    ["9:446"] = true,
    ["9:451"] = true,
    ["9:475"] = true,
    ["9:525"] = true,
    ["9:584"] = true,
    ["9:640"] = true,
    ["9:662"] = true,
    ["9:691"] = true,
    ["9:718"] = true,
    ["9:736"] = true,
    ["9:756"] = true,
    ["9:788"] = true,
    ["9:803"] = true,
    ["9:819"] = true,
    ["9:838"] = true,
    ["9:887"] = true,
    ["9:917"] = true,
    ["9:943"] = true,
    ["9:975"] = true,
    ["9:1029"] = true,
    ["9:1058"] = true,
    ["9:1144"] = true,
    ["9:1222"] = true,
    ["9:1239"] = true,
    ["10:60"] = true,
    ["10:92"] = true,
    ["10:154"] = true,
    ["10:178"] = true,
    ["10:218"] = true,
    ["10:240"] = true,
    ["10:260"] = true,
    ["10:288"] = true,
    ["10:371"] = true,
    ["10:429"] = true,
    ["10:477"] = true,
    ["10:492"] = true,
    ["10:529"] = true,
    ["10:604"] = true,
    ["10:626"] = true,
    ["10:723"] = true,
    ["10:863"] = true,
    ["10:904"] = true,
    ["10:919"] = true,
    ["10:999"] = true,
    ["10:1053"] = true,
    ["10:1092"] = true,
    ["10:1127"] = true,
    ["10:1146"] = true,
    ["10:1241"] = true,
    ["11:6"] = true,
    ["11:8"] = true,
    ["11:74"] = true,
    ["11:195"] = true,
    ["11:235"] = true,
    ["11:382"] = true,
    ["11:438"] = true,
    ["11:465"] = true,
    ["11:493"] = true,
    ["11:511"] = true,
    ["11:606"] = true,
    ["11:628"] = true,
    ["11:677"] = true,
    ["11:712"] = true,
    ["11:739"] = true,
    ["11:806"] = true,
    ["11:891"] = true,
    ["11:980"] = true,
    ["11:1034"] = true,
    ["11:1095"] = true,
    ["11:1129"] = true,
    ["13:76"] = true,
    ["13:83"] = true,
    ["13:192"] = true,
    ["13:235"] = true,
    ["13:237"] = true,
    ["13:264"] = true,
    ["13:308"] = true,
    ["13:379"] = true,
    ["13:398"] = true,
    ["13:428"] = true,
    ["13:460"] = true,
    ["13:478"] = true,
    ["13:494"] = true,
    ["13:546"] = true,
    ["13:629"] = true,
    ["13:661"] = true,
    ["13:790"] = true,
    ["13:807"] = true,
    ["13:972"] = true,
    ["13:981"] = true,
    ["13:1013"] = true,
    ["13:1032"] = true,
    ["13:1038"] = true,
    ["13:1147"] = true,
    ["14:75"] = true,
    ["14:202"] = true,
    ["14:266"] = true,
    ["14:401"] = true,
    ["14:452"] = true,
    ["14:496"] = true,
    ["14:547"] = true,
    ["14:900"] = true,
    ["14:902"] = true,
    ["14:983"] = true,
    ["14:1042"] = true,
    ["14:1148"] = true,
    ["14:1242"] = true,
    ["16:8"] = true,
    ["16:16"] = true,
    ["16:17"] = true,
    ["16:155"] = true,
    ["16:164"] = true,
    ["16:187"] = true,
    ["16:215"] = true,
    ["16:255"] = true,
    ["16:309"] = true,
    ["16:336"] = true,
    ["16:384"] = true,
    ["16:400"] = true,
    ["16:449"] = true,
    ["16:471"] = true,
    ["16:480"] = true,
    ["16:512"] = true,
    ["16:533"] = true,
    ["16:588"] = true,
    ["16:632"] = true,
    ["16:664"] = true,
    ["16:695"] = true,
    ["16:780"] = true,
    ["16:793"] = true,
    ["16:811"] = true,
    ["16:844"] = true,
    ["16:926"] = true,
    ["16:971"] = true,
    ["16:985"] = true,
    ["16:993"] = true,
    ["16:1041"] = true,
    ["16:1063"] = true,
    ["16:1097"] = true,
    ["16:1149"] = true,
    ["16:1228"] = true,
    ["16:1255"] = true,
    ["17:17"] = true,
    ["17:44"] = true,
    ["17:188"] = true,
    ["17:284"] = true,
    ["17:310"] = true,
    ["17:337"] = true,
    ["17:343"] = true,
    ["17:372"] = true,
    ["17:402"] = true,
    ["17:433"] = true,
    ["17:498"] = true,
    ["17:534"] = true,
    ["17:589"] = true,
    ["17:665"] = true,
    ["17:682"] = true,
    ["17:742"] = true,
    ["17:748"] = true,
    ["17:761"] = true,
    ["17:812"] = true,
    ["17:840"] = true,
    ["17:898"] = true,
    ["17:908"] = true,
    ["17:947"] = true,
    ["17:965"] = true,
    ["17:1009"] = true,
    ["17:1045"] = true,
    ["17:1067"] = true,
    ["17:1075"] = true,
    ["17:1098"] = true,
    ["17:1131"] = true,
    ["17:1150"] = true,
    ["17:1229"] = true,
    ["17:1244"] = true,
    ["19:20"] = true,
    ["19:67"] = true,
    ["19:156"] = true,
    ["19:169"] = true,
    ["19:182"] = true,
    ["19:228"] = true,
    ["19:283"] = true,
    ["19:311"] = true,
    ["19:335"] = true,
    ["19:342"] = true,
    ["19:359"] = true,
    ["19:486"] = true,
    ["19:516"] = true,
    ["19:593"] = true,
    ["19:611"] = true,
    ["19:636"] = true,
    ["19:669"] = true,
    ["19:717"] = true,
    ["19:744"] = true,
    ["19:759"] = true,
    ["19:776"] = true,
    ["19:849"] = true,
    ["19:911"] = true,
    ["19:925"] = true,
    ["19:969"] = true,
    ["19:977"] = true,
    ["19:1000"] = true,
    ["19:1015"] = true,
    ["19:1074"] = true,
    ["19:1154"] = true,
    ["19:1233"] = true,
    ["19:1250"] = true,
    ["23:781"] = true,
    ["23:800"] = true,
    ["23:810"] = true,
    ["23:846"] = true,
    ["23:872"] = true,
    ["23:888"] = true,
    ["23:915"] = true,
    ["23:923"] = true,
    ["23:949"] = true,
    ["23:974"] = true,
    ["23:986"] = true,
    ["23:1061"] = true,
    ["23:1137"] = true,
    ["23:1231"] = true,
    ["24:15"] = true,
    ["24:17"] = true,
    ["24:70"] = true,
    ["24:90"] = true,
    ["24:169"] = true,
    ["24:250"] = true,
    ["24:281"] = true,
    ["24:362"] = true,
    ["24:436"] = true,
    ["24:441"] = true,
    ["24:488"] = true,
    ["24:556"] = true,
    ["24:615"] = true,
    ["24:652"] = true,
    ["24:672"] = true,
    ["24:688"] = true,
    ["24:704"] = true,
    ["24:725"] = true,
    ["24:778"] = true,
    ["24:802"] = true,
    ["24:851"] = true,
    ["24:916"] = true,
    ["24:990"] = true,
    ["24:1003"] = true,
    ["24:1008"] = true,
    ["24:1049"] = true,
    ["24:1157"] = true,
    ["24:1236"] = true,
    ["25:42"] = true,
    ["25:166"] = true,
    ["25:169"] = true,
    ["25:238"] = true,
    ["25:240"] = true,
    ["25:314"] = true,
    ["25:320"] = true,
    ["25:348"] = true,
    ["25:370"] = true,
    ["25:393"] = true,
    ["25:407"] = true,
    ["25:505"] = true,
    ["25:521"] = true,
    ["25:557"] = true,
    ["25:616"] = true,
    ["25:654"] = true,
    ["25:689"] = true,
    ["25:706"] = true,
    ["25:731"] = true,
    ["25:760"] = true,
    ["25:821"] = true,
    ["25:850"] = true,
    ["25:970"] = true,
    ["25:994"] = true,
    ["25:1021"] = true,
    ["25:1046"] = true,
    ["25:1103"] = true,
    ["25:1135"] = true,
    ["25:1254"] = true,
    ["26:13"] = true,
    ["26:70"] = true,
    ["26:159"] = true,
    ["26:164"] = true,
    ["26:171"] = true,
    ["26:203"] = true,
    ["26:224"] = true,
    ["26:236"] = true,
    ["26:267"] = true,
    ["26:293"] = true,
    ["26:306"] = true,
    ["26:349"] = true,
    ["26:457"] = true,
    ["26:508"] = true,
    ["26:526"] = true,
    ["26:542"] = true,
    ["26:594"] = true,
    ["26:641"] = true,
    ["26:676"] = true,
    ["26:692"] = true,
    ["26:775"] = true,
    ["26:829"] = true,
    ["26:884"] = true,
    ["26:973"] = true,
    ["26:1099"] = true,
    ["26:1125"] = true,
    ["27:34"] = true,
    ["27:70"] = true,
    ["27:171"] = true,
    ["27:177"] = true,
    ["27:291"] = true,
    ["27:327"] = true,
    ["27:385"] = true,
    ["27:431"] = true,
    ["27:462"] = true,
    ["27:499"] = true,
    ["27:535"] = true,
    ["27:608"] = true,
    ["27:633"] = true,
    ["27:666"] = true,
    ["27:703"] = true,
    ["27:737"] = true,
    ["27:754"] = true,
    ["27:787"] = true,
    ["27:822"] = true,
    ["27:909"] = true,
    ["27:948"] = true,
    ["27:961"] = true,
    ["27:1072"] = true,
    ["27:1089"] = true,
    ["27:1132"] = true,
    ["27:1220"] = true,
    ["27:1245"] = true,
    ["28:240"] = true,
    ["28:298"] = true,
    ["28:317"] = true,
    ["28:355"] = true,
    ["28:432"] = true,
    ["28:483"] = true,
    ["28:514"] = true,
    ["28:610"] = true,
    ["28:763"] = true,
    ["28:783"] = true,
    ["28:920"] = true,
    ["28:950"] = true,
    ["28:958"] = true,
    ["28:1012"] = true,
    ["28:1043"] = true,
    ["28:1080"] = true,
    ["28:1152"] = true,
    ["29:5"] = true,
    ["29:83"] = true,
    ["29:171"] = true,
    ["29:204"] = true,
    ["29:250"] = true,
    ["29:256"] = true,
    ["29:323"] = true,
    ["29:345"] = true,
    ["29:390"] = true,
    ["29:405"] = true,
    ["29:434"] = true,
    ["29:458"] = true,
    ["29:517"] = true,
    ["29:552"] = true,
    ["29:596"] = true,
    ["29:638"] = true,
    ["29:655"] = true,
    ["29:673"] = true,
    ["29:720"] = true,
    ["29:797"] = true,
    ["29:814"] = true,
    ["29:880"] = true,
    ["29:953"] = true,
    ["29:1014"] = true,
    ["29:1140"] = true,
    ["29:1155"] = true,
    ["30:17"] = true,
    ["30:36"] = true,
    ["30:159"] = true,
    ["30:235"] = true,
    ["30:248"] = true,
    ["30:272"] = true,
    ["30:289"] = true,
    ["30:303"] = true,
    ["30:374"] = true,
    ["30:439"] = true,
    ["30:459"] = true,
    ["30:463"] = true,
    ["30:520"] = true,
    ["30:539"] = true,
    ["30:555"] = true,
    ["30:599"] = true,
    ["30:614"] = true,
    ["30:671"] = true,
    ["30:684"] = true,
    ["30:722"] = true,
    ["30:738"] = true,
    ["30:791"] = true,
    ["30:795"] = true,
    ["30:816"] = true,
    ["30:839"] = true,
    ["30:889"] = true,
    ["30:905"] = true,
    ["30:964"] = true,
    ["30:1010"] = true,
    ["30:1024"] = true,
    ["30:1235"] = true,
    ["30:1252"] = true,
    ["32:21"] = true,
    ["32:71"] = true,
    ["32:184"] = true,
    ["32:211"] = true,
    ["32:275"] = true,
    ["32:327"] = true,
    ["32:338"] = true,
    ["32:346"] = true,
    ["32:357"] = true,
    ["32:389"] = true,
    ["32:485"] = true,
    ["32:515"] = true,
    ["32:550"] = true,
    ["32:591"] = true,
    ["32:635"] = true,
    ["32:667"] = true,
    ["32:700"] = true,
    ["32:894"] = true,
    ["32:951"] = true,
    ["32:960"] = true,
    ["32:997"] = true,
    ["32:1019"] = true,
    ["32:1138"] = true,
    ["32:1224"] = true,
    ["33:5"] = true,
    ["33:11"] = true,
    ["33:15"] = true,
    ["33:213"] = true,
    ["33:250"] = true,
    ["33:354"] = true,
    ["33:365"] = true,
    ["33:423"] = true,
    ["33:481"] = true,
    ["33:500"] = true,
    ["33:627"] = true,
    ["33:696"] = true,
    ["33:719"] = true,
    ["33:782"] = true,
    ["33:847"] = true,
    ["33:893"] = true,
    ["33:1007"] = true,
    ["33:1023"] = true,
    ["33:1096"] = true,
    ["33:1133"] = true,
    ["33:1246"] = true,
    ["34:262"] = true,
    ["34:298"] = true,
    ["34:329"] = true,
    ["34:366"] = true,
    ["34:368"] = true,
    ["34:386"] = true,
    ["34:403"] = true,
    ["34:482"] = true,
    ["34:549"] = true,
    ["34:609"] = true,
    ["34:679"] = true,
    ["34:697"] = true,
    ["34:715"] = true,
    ["34:734"] = true,
    ["34:755"] = true,
    ["34:804"] = true,
    ["34:820"] = true,
    ["34:867"] = true,
    ["34:910"] = true,
    ["34:1037"] = true,
    ["34:1134"] = true,
    ["34:1225"] = true,
    ["35:62"] = true,
    ["35:158"] = true,
    ["35:164"] = true,
    ["35:166"] = true,
    ["35:191"] = true,
    ["35:214"] = true,
    ["35:248"] = true,
    ["35:263"] = true,
    ["35:286"] = true,
    ["35:298"] = true,
    ["35:299"] = true,
    ["35:323"] = true,
    ["35:356"] = true,
    ["35:450"] = true,
    ["35:484"] = true,
    ["35:537"] = true,
    ["35:590"] = true,
    ["35:634"] = true,
    ["35:699"] = true,
    ["35:716"] = true,
    ["35:746"] = true,
    ["35:785"] = true,
    ["35:809"] = true,
    ["35:890"] = true,
    ["35:929"] = true,
    ["35:987"] = true,
    ["35:1077"] = true,
    ["35:1247"] = true,
    ["36:15"] = true,
    ["36:34"] = true,
    ["36:77"] = true,
    ["36:78"] = true,
    ["36:125"] = true,
    ["36:164"] = true,
    ["36:207"] = true,
    ["36:219"] = true,
    ["36:230"] = true,
    ["36:258"] = true,
    ["36:271"] = true,
    ["36:295"] = true,
    ["36:358"] = true,
    ["36:373"] = true,
    ["36:388"] = true,
    ["36:404"] = true,
    ["36:426"] = true,
    ["36:466"] = true,
    ["36:501"] = true,
    ["36:551"] = true,
    ["36:592"] = true,
    ["36:650"] = true,
    ["36:668"] = true,
    ["36:678"] = true,
    ["36:741"] = true,
    ["36:749"] = true,
    ["36:777"] = true,
    ["36:786"] = true,
    ["36:848"] = true,
    ["36:907"] = true,
    ["36:928"] = true,
    ["36:968"] = true,
    ["36:982"] = true,
    ["36:1030"] = true,
    ["36:1044"] = true,
    ["36:1153"] = true,
    ["36:1230"] = true,
    ["36:1248"] = true,
    ["38:70"] = true,
    ["38:159"] = true,
    ["38:165"] = true,
    ["38:232"] = true,
    ["38:298"] = true,
    ["38:312"] = true,
    ["38:391"] = true,
    ["38:406"] = true,
    ["38:502"] = true,
    ["38:518"] = true,
    ["38:597"] = true,
    ["38:612"] = true,
    ["38:642"] = true,
    ["38:685"] = true,
    ["38:865"] = true,
    ["38:914"] = true,
    ["38:954"] = true,
    ["38:1028"] = true,
    ["38:1226"] = true,
    ["39:247"] = true,
    ["39:287"] = true,
    ["39:298"] = true,
    ["39:363"] = true,
    ["39:487"] = true,
    ["39:519"] = true,
    ["39:553"] = true,
    ["39:598"] = true,
    ["39:613"] = true,
    ["39:686"] = true,
    ["39:750"] = true,
    ["39:815"] = true,
    ["39:897"] = true,
    ["39:955"] = true,
    ["39:966"] = true,
    ["39:1048"] = true,
    ["39:1084"] = true,
    ["39:1151"] = true,
    ["39:1234"] = true,
    ["40:60"] = true,
    ["40:70"] = true,
    ["40:200"] = true,
    ["40:222"] = true,
    ["40:304"] = true,
    ["40:319"] = true,
    ["40:361"] = true,
    ["40:503"] = true,
    ["40:538"] = true,
    ["40:554"] = true,
    ["40:624"] = true,
    ["40:670"] = true,
    ["40:743"] = true,
    ["40:751"] = true,
    ["40:868"] = true,
    ["40:899"] = true,
    ["40:956"] = true,
    ["40:967"] = true,
    ["40:989"] = true,
    ["40:996"] = true,
    ["40:1052"] = true,
    ["40:1060"] = true,
    ["40:1101"] = true,
    ["40:1251"] = true,
    ["60:60"] = true,
    ["60:77"] = true,
    ["60:189"] = true,
    ["60:217"] = true,
    ["60:235"] = true,
    ["60:257"] = true,
    ["60:301"] = true,
    ["60:321"] = true,
    ["60:326"] = true,
    ["60:360"] = true,
    ["60:383"] = true,
    ["60:430"] = true,
    ["60:440"] = true,
    ["60:445"] = true,
    ["60:497"] = true,
    ["60:548"] = true,
    ["60:587"] = true,
    ["60:631"] = true,
    ["60:644"] = true,
    ["60:663"] = true,
    ["60:681"] = true,
    ["60:714"] = true,
    ["60:792"] = true,
    ["60:862"] = true,
    ["60:946"] = true,
    ["60:984"] = true,
    ["60:1001"] = true,
    ["60:1073"] = true,
    ["60:1130"] = true,
    ["60:1223"] = true,
    ["60:1243"] = true,
    ["61:60"] = true,
    ["61:183"] = true,
    ["61:217"] = true,
    ["61:221"] = true,
    ["61:236"] = true,
    ["61:277"] = true,
    ["61:290"] = true,
    ["61:313"] = true,
    ["61:318"] = true,
    ["61:332"] = true,
    ["61:339"] = true,
    ["61:364"] = true,
    ["61:454"] = true,
    ["61:489"] = true,
    ["61:504"] = true,
    ["61:540"] = true,
    ["61:637"] = true,
    ["61:653"] = true,
    ["61:657"] = true,
    ["61:705"] = true,
    ["61:817"] = true,
    ["61:818"] = true,
    ["61:922"] = true,
    ["61:991"] = true,
    ["61:1027"] = true,
    ["61:1031"] = true,
    ["61:1040"] = true,
    ["61:1102"] = true,
    ["61:1136"] = true,
    ["61:1142"] = true,
    ["61:1253"] = true,
    ["63:12"] = true,
    ["63:218"] = true,
    ["63:268"] = true,
    ["63:270"] = true,
    ["63:298"] = true,
    ["63:315"] = true,
    ["63:325"] = true,
    ["63:334"] = true,
    ["63:350"] = true,
    ["63:366"] = true,
    ["63:435"] = true,
    ["63:476"] = true,
    ["63:543"] = true,
    ["63:602"] = true,
    ["63:622"] = true,
    ["63:643"] = true,
    ["63:687"] = true,
    ["63:709"] = true,
    ["63:859"] = true,
    ["63:944"] = true,
    ["63:976"] = true,
    ["63:1036"] = true,
    ["63:1064"] = true,
    ["63:1076"] = true,
    ["64:12"] = true,
    ["64:595"] = true,
    ["64:683"] = true,
    ["64:701"] = true,
    ["64:721"] = true,
    ["64:843"] = true,
    ["64:892"] = true,
    ["64:924"] = true,
    ["64:952"] = true,
    ["64:1011"] = true,
    ["64:1047"] = true,
    ["64:1145"] = true,
    ["64:1232"] = true,
    ["64:1237"] = true,
    ["500:5"] = true,
    ["500:12"] = true,
    ["500:42"] = true,
    ["500:43"] = true,
    ["500:44"] = true,
    ["500:59"] = true,
    ["500:77"] = true,
    ["500:409"] = true,
    ["500:410"] = true,
    ["500:413"] = true,
    ["500:414"] = true,
    ["500:558"] = true,
    ["500:563"] = true,
    ["500:573"] = true,
    ["500:578"] = true,
    ["500:580"] = true,
    ["503:5"] = true,
    ["503:12"] = true,
    ["503:42"] = true,
    ["503:43"] = true,
    ["503:44"] = true,
    ["503:59"] = true,
    ["503:77"] = true,
    ["505:5"] = true,
    ["505:12"] = true,
    ["505:42"] = true,
    ["505:43"] = true,
    ["505:44"] = true,
    ["505:59"] = true,
    ["505:77"] = true,
    ["505:409"] = true,
    ["505:410"] = true,
    ["505:413"] = true,
    ["505:414"] = true,
    ["505:559"] = true,
    ["505:564"] = true,
    ["505:574"] = true,
    ["505:578"] = true,
    ["505:580"] = true,
    ["506:5"] = true,
    ["506:12"] = true,
    ["506:42"] = true,
    ["506:43"] = true,
    ["506:44"] = true,
    ["506:59"] = true,
    ["506:77"] = true,
    ["506:409"] = true,
    ["506:410"] = true,
    ["506:413"] = true,
    ["506:414"] = true,
    ["506:560"] = true,
    ["506:565"] = true,
    ["506:575"] = true,
    ["506:578"] = true,
    ["506:580"] = true,
    ["507:5"] = true,
    ["507:12"] = true,
    ["507:42"] = true,
    ["507:43"] = true,
    ["507:44"] = true,
    ["507:59"] = true,
    ["507:77"] = true,
    ["507:409"] = true,
    ["507:410"] = true,
    ["507:413"] = true,
    ["507:414"] = true,
    ["507:561"] = true,
    ["507:566"] = true,
    ["507:576"] = true,
    ["507:578"] = true,
    ["507:582"] = true,
    ["508:5"] = true,
    ["508:12"] = true,
    ["508:42"] = true,
    ["508:43"] = true,
    ["508:44"] = true,
    ["508:59"] = true,
    ["508:77"] = true,
    ["508:409"] = true,
    ["508:411"] = true,
    ["508:413"] = true,
    ["508:414"] = true,
    ["508:562"] = true,
    ["508:567"] = true,
    ["508:577"] = true,
    ["508:579"] = true,
    ["508:581"] = true,
    ["509:5"] = true,
    ["509:12"] = true,
    ["509:42"] = true,
    ["509:43"] = true,
    ["509:44"] = true,
    ["509:59"] = true,
    ["509:77"] = true,
    ["509:409"] = true,
    ["509:411"] = true,
    ["509:413"] = true,
    ["509:414"] = true,
    ["509:579"] = true,
    ["509:581"] = true,
    ["509:620"] = true,
    ["509:1107"] = true,
    ["509:1112"] = true,
    ["509:1117"] = true,
    ["512:5"] = true,
    ["512:12"] = true,
    ["512:42"] = true,
    ["512:43"] = true,
    ["512:44"] = true,
    ["512:59"] = true,
    ["512:77"] = true,
    ["512:409"] = true,
    ["512:411"] = true,
    ["512:413"] = true,
    ["512:414"] = true,
    ["512:579"] = true,
    ["512:581"] = true,
    ["512:1106"] = true,
    ["512:1111"] = true,
    ["512:1116"] = true,
    ["514:5"] = true,
    ["514:12"] = true,
    ["514:42"] = true,
    ["514:43"] = true,
    ["514:44"] = true,
    ["514:59"] = true,
    ["514:77"] = true,
    ["514:409"] = true,
    ["514:411"] = true,
    ["514:413"] = true,
    ["514:414"] = true,
    ["514:579"] = true,
    ["514:581"] = true,
    ["514:1104"] = true,
    ["514:1109"] = true,
    ["514:1114"] = true,
    ["515:5"] = true,
    ["515:12"] = true,
    ["515:42"] = true,
    ["515:43"] = true,
    ["515:44"] = true,
    ["515:59"] = true,
    ["515:77"] = true,
    ["515:409"] = true,
    ["515:411"] = true,
    ["515:413"] = true,
    ["515:414"] = true,
    ["515:579"] = true,
    ["515:581"] = true,
    ["515:1105"] = true,
    ["515:1110"] = true,
    ["515:1115"] = true,
    ["516:5"] = true,
    ["516:12"] = true,
    ["516:42"] = true,
    ["516:43"] = true,
    ["516:44"] = true,
    ["516:59"] = true,
    ["516:77"] = true,
    ["516:409"] = true,
    ["516:411"] = true,
    ["516:413"] = true,
    ["516:414"] = true,
    ["516:579"] = true,
    ["516:581"] = true,
    ["516:1108"] = true,
    ["516:1113"] = true,
    ["516:1118"] = true,
    ["517:5"] = true,
    ["517:12"] = true,
    ["517:42"] = true,
    ["517:43"] = true,
    ["517:44"] = true,
    ["517:59"] = true,
    ["517:77"] = true,
    ["517:409"] = true,
    ["517:410"] = true,
    ["517:413"] = true,
    ["517:414"] = true,
    ["518:5"] = true,
    ["518:12"] = true,
    ["518:42"] = true,
    ["518:43"] = true,
    ["518:44"] = true,
    ["518:59"] = true,
    ["518:77"] = true,
    ["518:409"] = true,
    ["518:410"] = true,
    ["518:413"] = true,
    ["518:414"] = true,
    ["519:5"] = true,
    ["519:12"] = true,
    ["519:42"] = true,
    ["519:43"] = true,
    ["519:44"] = true,
    ["519:59"] = true,
    ["519:77"] = true,
    ["519:409"] = true,
    ["519:413"] = true,
    ["519:414"] = true,
    ["519:857"] = true,
    ["520:5"] = true,
    ["520:12"] = true,
    ["520:42"] = true,
    ["520:43"] = true,
    ["520:44"] = true,
    ["520:59"] = true,
    ["520:77"] = true,
    ["520:409"] = true,
    ["520:413"] = true,
    ["520:414"] = true,
    ["520:857"] = true,
    ["521:5"] = true,
    ["521:12"] = true,
    ["521:42"] = true,
    ["521:43"] = true,
    ["521:44"] = true,
    ["521:59"] = true,
    ["521:77"] = true,
    ["521:409"] = true,
    ["521:410"] = true,
    ["521:413"] = true,
    ["521:414"] = true,
    ["522:5"] = true,
    ["522:12"] = true,
    ["522:42"] = true,
    ["522:43"] = true,
    ["522:44"] = true,
    ["522:59"] = true,
    ["522:77"] = true,
    ["522:409"] = true,
    ["522:413"] = true,
    ["522:414"] = true,
    ["522:857"] = true,
    ["523:5"] = true,
    ["523:12"] = true,
    ["523:42"] = true,
    ["523:43"] = true,
    ["523:44"] = true,
    ["523:59"] = true,
    ["523:77"] = true,
    ["523:409"] = true,
    ["523:414"] = true,
    ["523:856"] = true,
    ["523:858"] = true,
    ["525:5"] = true,
    ["525:12"] = true,
    ["525:42"] = true,
    ["525:43"] = true,
    ["525:44"] = true,
    ["525:59"] = true,
    ["525:77"] = true,
    ["525:409"] = true,
    ["525:410"] = true,
    ["525:413"] = true,
    ["525:414"] = true,
    ["526:5"] = true,
    ["526:12"] = true,
    ["526:42"] = true,
    ["526:43"] = true,
    ["526:44"] = true,
    ["526:59"] = true,
    ["526:77"] = true,
}
local function is_weapon_def_for_safe_filter(def)
    return def and def > 0 and def < 500
end
local function is_legacy_skin(def, paint)
    return SKIN_LEGACY_BY_SKIN[tostring(def) .. ":" .. tostring(paint)] == true
end

local state = {
    cfg          = {}, -- global weapon configs
    opts         = {},
    -- legacy/global fallback. Kept for old configs, but knives/gloves now use per-team tables below.
    knifeDef     = nil,
    gloveDef     = nil,
    teamKnifeDef = { t = nil, ct = nil },
    teamGloveDef = { t = nil, ct = nil },
    teamCfg      = { t = {}, ct = {} }, -- per-team knife/glove configs
    applied      = {},
    pendingReset = {},
    resetKnife   = false,
    resetGlove   = false,
    localModel       = nil,
    appliedLocalModel= nil,
    forceRefresh     = 0,
    resetGloveDone  = false,
}

local function copy_cfg_entry(c)
    if not c then return nil end
    return {
        paint = c.paint or 0,
        wear = c.wear or 0.0001,
        seed = c.seed or 0,
        stat = c.stat and true or false,
        statval = c.statval or 0,
        nametag = c.nametag or "",
        kind = c.kind or "weapon",
    }
end

local function side_from_team(team)
    if team == 2 then return "t" end
    if team == 3 then return "ct" end
    return nil
end

local function local_team_side(pawn)
    local team = 0
    if valid(pawn) and off.m_iTeamNum then
        pcall(function() team = r_i32(pawn + off.m_iTeamNum) end)
    end
    if team == 0 then
        local lp = entities.GetLocalPlayer()
        if lp then pcall(function() team = lp:GetFieldInt("m_iTeamNum") end) end
    end
    return side_from_team(team) or "ct"
end

local function team_cfg_for(side)
    side = (side == "t") and "t" or "ct"
    state.teamCfg[side] = state.teamCfg[side] or {}
    return state.teamCfg[side]
end

local function item_kind_for_def(def, fallback)
    if fallback then return fallback end
    if is_knife(def) then return "knife" end
    return nil
end

local function cfg_for_item(def, kind, side)
    kind = item_kind_for_def(def, kind)
    if kind == "knife" or kind == "glove" then
        local tc = team_cfg_for(side or local_team_side())
        return tc[def] or state.cfg[def]
    end
    return state.cfg[def]
end

local function selected_knife_def(side)
    side = (side == "t") and "t" or "ct"
    return state.teamKnifeDef[side] or state.knifeDef
end

local function selected_glove_def(side)
    side = (side == "t") and "t" or "ct"
    return state.teamGloveDef[side] or state.gloveDef
end

local function skin_list_for(def, show_legacy)
    local names  = { "[ NONE ] [ None ]" }
    local paints = { 0 }
    local src = def and SKINS[def]
    if src then
        local sorted = {}
        for i = 1, #src do
            local paint = src[i][2]
            local legacy = is_weapon_def_for_safe_filter(def) and is_legacy_skin(def, paint)
            -- By default hide legacy weapon finishes because many render broken in CS2 fallback mode.
            -- If show_legacy is enabled, keep them and mark with warning.
            if show_legacy or (not legacy) then
                local rarity = skin_rarity(def, paint)
                sorted[#sorted + 1] = { name = src[i][1], paint = paint, rarity = rarity, legacy = legacy, order = RARITY_ORDER[rarity] or 99 }
            end
        end
        if #sorted == 0 then
            -- fallback: if a weapon has only legacy entries, show them instead of empty list
            for i = 1, #src do
                local paint = src[i][2]
                local rarity = skin_rarity(def, paint)
                local legacy = is_weapon_def_for_safe_filter(def) and is_legacy_skin(def, paint)
                sorted[#sorted + 1] = { name = src[i][1], paint = paint, rarity = rarity, legacy = legacy, order = RARITY_ORDER[rarity] or 99 }
            end
        end
        table.sort(sorted, function(a, b)
            if a.legacy ~= b.legacy then return not a.legacy end -- safe first, legacy lower
            if a.order ~= b.order then return a.order > b.order end -- крутые сверху: GOLD/RED/PINK...
            if a.paint ~= b.paint then return a.paint < b.paint end
            return a.name < b.name
        end)
        for i = 1, #sorted do
            local r = sorted[i].rarity
            local warn = sorted[i].legacy and "⚠ " or ""
            names[i + 1]  = (RARITY_LABEL[r] or "[UNK] ") .. warn .. sorted[i].name
            paints[i + 1] = sorted[i].paint
        end
    end
    return names, paints
end


local function paint_allowed(def, paint)
    paint = tonumber(paint) or 0
    if paint == 0 then return true end
    local src = def and SKINS[def]
    if not src then return false end
    for i = 1, #src do
        if src[i][2] == paint then return true end
    end
    return false
end

local ITEMS = {}
local function add_item(name, def, kind) ITEMS[#ITEMS+1] = { name = name, def = def, kind = kind } end

for i = 1, #KNIVES do
    local k = KNIVES[i]
    if k.def then add_item("[K] " .. k.name, k.def, "knife") end
end
for i = 1, #WEAPONS do
    add_item("[W] " .. WEAPONS[i].name, WEAPONS[i].def, "weapon")
end
for i = 1, #GLOVES do
    local g = GLOVES[i]
    add_item(g.def == 0 and "[G] Default (off)" or "[G] " .. g.name, g.def, "glove")
end

local itemNames = {}; for i = 1, #ITEMS do itemNames[i] = ITEMS[i].name end

local DEF_TO_ITEM = {}
for i = 1, #ITEMS do
    if ITEMS[i].kind ~= "glove" then DEF_TO_ITEM[ITEMS[i].def] = i end
end

local Config = {}

local g_activeDef = nil

local function item_ptr(wpn) return wpn + off.m_AttributeManager + off.m_Item end

local function safe_wear(wear)
    if not wear or wear <= 0 then return 0.0001 end
    return wear
end

local function write_fallback(wpn, paint, wear, seed, stat, statval)
    w_i32(wpn + off.m_nFallbackPaintKit, paint)
    w_f32(wpn + off.m_flFallbackWear, safe_wear(wear))
    w_i32(wpn + off.m_nFallbackSeed, seed)
    w_i32(wpn + off.m_nFallbackStatTrak, stat and (statval or 0) or -1)
    w_u32(item_ptr(wpn) + off.m_iAccountID, stat and (statval or 0) or 0)
    w_u32(item_ptr(wpn) + off.m_iEntityQuality, stat and 9 or 0)
end

local function mark_item_custom(item)
    w_u32(item + off.m_iItemIDHigh, 0xFFFFFFFF)
    w_u8 (item + off.m_bInitialized, 1)
    w_u8 (item + off.m_bDisallowSOC, 0)
    w_u8 (item + off.m_bRestoreCustomMat, 1)
end

local function refresh_econ(wpn)
    vcall_void_bool(wpn, 10, true)
    vcall_void_bool(wpn, 110, true)
end

local function apply_knife_model(wpn)
    if fnptr.set_model then
        local vdata = r_ptr(wpn + off.m_nSubclassID + 8)
        if valid(vdata) then
            local s = read_cstr(vdata + off.m_szWorldModel, 160)
            if s:find("models/") and s:find("%.vmdl") then fnptr.set_model(ffi.cast("void*", wpn), s) end
        end
    end
    if fnptr.set_mesh_mask then
        local node = r_ptr(wpn + off.m_pGameSceneNode)
        if valid(node) then fnptr.set_mesh_mask(ffi.cast("void*", node), 2) end
    end
end

local function set_knife_subclass(wpn, def_target, quality)
    local item = item_ptr(wpn)
    w_u16(item + off.m_iItemDefinitionIndex, def_target)
    w_i32(item + off.m_iEntityQuality, quality)
    w_u32(wpn + off.m_nSubclassID, subclass_hash(def_target))
    if fnptr.update_subclass then fnptr.update_subclass(ffi.cast("void*", wpn)) end
    apply_knife_model(wpn)
    return item
end

local function process_knife(wpn, def_target, paint, wear, seed, stat, statval, nametag)
    local item = set_knife_subclass(wpn, def_target, stat and 9 or 3)
    mark_item_custom(item)
    write_fallback(wpn, paint, wear, seed, stat, statval)
    refresh_econ(wpn)
    vcall_void(wpn, 195)
end

local function process_weapon(wpn, paint, wear, seed, stat, statval, nametag)
    mark_item_custom(item_ptr(wpn))
    write_fallback(wpn, paint, wear, seed, stat, statval)
    refresh_econ(wpn)
end

local function restore_weapon(wpn)
    write_fallback(wpn, 0, 0.0001, 0, false)
    refresh_econ(wpn)
end

local function restore_knife(wpn, pawn)
    local def_target = (r_u8(pawn + off.m_iTeamNum) == 2) and 59 or 42
    set_knife_subclass(wpn, def_target, 0)
    write_fallback(wpn, 0, 0.0001, 0, false)
    refresh_econ(wpn)
    vcall_void(wpn, 195)
end

local ATTR_STRUCT = 72

local game_alloc, game_free
local function resolve_mem()
    if game_alloc then return true end
    pcall(function() ffi.cdef[[ void* GetModuleHandleA(const char*); ]] end)
    pcall(function() ffi.cdef[[ void* GetProcAddress(void*, const char*); ]] end)
    local tier0
    pcall(function() tier0 = ffi.C.GetModuleHandleA("tier0.dll") end)
    if not tier0 then return false end
    local pa, pf
    pcall(function() pa = ffi.C.GetProcAddress(tier0, "MemAlloc_AllocFunc") end)
    pcall(function() pf = ffi.C.GetProcAddress(tier0, "MemAlloc_FreeFunc") end)
    if not pa or not pf then return false end
    pcall(function()
        game_alloc = ffi.cast("void*(*)(size_t)", pa)
        game_free  = ffi.cast("void(*)(void*)", pf)
    end)
    return game_alloc ~= nil and game_free ~= nil
end

local function glove_attr_remove(item)
    local addr = item + off.m_AttributeList + off.m_Attributes
    local size = r_ptr(addr)
    local ptr  = r_ptr(addr + 8)
    w_u64(addr, 0); w_u64(addr + 8, 0)
    if game_free and size ~= 0 and valid(ptr) then
        pcall(function() game_free(ffi.cast("void*", ptr)) end)
    end
end

local function glove_attr_set(item, paint, seed, wear)
    glove_attr_remove(item)
    if paint <= 0 then return end
    if not resolve_mem() then return end
    wear = safe_wear(wear)
    local raw  = game_alloc(ATTR_STRUCT * 3)
    local bptr = tonumber(ffi.cast("uintptr_t", raw))
    if not bptr or bptr == 0 then return end
    for i = 0, (ATTR_STRUCT * 3) / 8 - 1 do w_u64(bptr + i * 8, 0) end
    local function mk(i, def, val)
        local b = bptr + i * ATTR_STRUCT
        w_u16(b + 0x30, def); w_f32(b + 0x34, val); w_f32(b + 0x38, val)
    end
    mk(0, 6, paint)
    mk(1, 7, seed)
    mk(2, 8, wear)
    local addr = item + off.m_AttributeList + off.m_Attributes
    w_u64(addr, 3)
    w_u64(addr + 8, bptr)
end

local function local_account_id(base)
    local ctrl = r_ptr(base + off.dwLocalPlayerController)
    if not valid(ctrl) then return 0 end
    local sid = r_u64(ctrl + off.m_steamID)
    return tonumber(sid % 0x100000000)
end

local glove_key, glove_apply = nil, 0
local function apply_gloves(base, pawn, gdef, paint, wear, seed)
    local g    = pawn + off.m_EconGloves
    local cur  = r_u16(g + off.m_iItemDefinitionIndex)
    local init = r_u8 (g + off.m_bInitialized)
    local key  = gdef.."|"..paint.."|"..floor(wear*100000).."|"..seed

    if key ~= glove_key then glove_key = key; glove_apply = 6 end
    local engine_reset = (cur ~= gdef) or (init == 0)
    if engine_reset and glove_apply <= 0 then glove_apply = 2 end

    if glove_apply > 0 then
        local acc = local_account_id(base)
        w_u8 (g + off.m_bInitialized, 0)
        w_u16(g + off.m_iItemDefinitionIndex, gdef)
        w_i32(g + off.m_iEntityQuality, 3)
        w_u32(g + off.m_iItemIDHigh, 0xFFFFFFFF)
        w_u32(g + off.m_iItemIDLow,  0xFFFFFFFF)
        w_u32(g + off.m_iAccountID, acc)
        w_u32(g + off.m_OriginalOwnerXuidLow, acc)
        glove_attr_set(g, paint, seed, wear)
        w_u8 (g + off.m_bDisallowSOC, 0)
        w_u8 (g + off.m_bRestoreCustomMat, 1)
        w_u8 (g + off.m_bInitialized, 1)
        w_u8 (pawn + off.m_bNeedToReApplyGloves, 1)
        if fnptr.set_body_group then
            pcall(function() fnptr.set_body_group(ffi.cast("void*", pawn), "first_or_third_person", 1) end)
        end
        glove_apply = glove_apply - 1
    end
end

local function reset_gloves(pawn)
    local g = pawn + off.m_EconGloves
    w_u8 (g + off.m_bInitialized, 0)
    w_u16(g + off.m_iItemDefinitionIndex, 0)
    glove_attr_remove(g)
    w_u8 (pawn + off.m_bNeedToReApplyGloves, 1)
    glove_key, glove_apply = nil, 0
    if fnptr.set_body_group then
        pcall(function() fnptr.set_body_group(ffi.cast("void*", pawn), "first_or_third_person", 1) end)
    end
end

local function handle_to_entity(elist, hnd)
    if not valid(elist) or hnd == 0 or hnd == 0xFFFFFFFF then return nil end
    local idx   = band(hnd, 0x7FFF)
    local chunk = r_ptr(elist + 8 * rshift(idx, 9) + 16); if not valid(chunk) then return nil end
    local e     = r_ptr(chunk + 112 * band(idx, 0x1FF))
    if valid(e) and valid(r_ptr(e)) then return e end
    return nil
end

local function pawn_alive(pawn)

    local ls = r_u8 (pawn + off.m_lifeState)
    local hp = r_i32(pawn + off.m_iHealth)
    return ls == 0 and hp > 0 and hp < 100000
end

local function in_game()
    local cl, so = off.dwNetworkGameClient, off.dwNetworkGameClient_signOnState
    if not cl or not so then return true end
    local eng = mem.GetModuleBase("engine2.dll"); if not eng then return true end
    local client = r_ptr(eng + cl); if not valid(client) then return false end
    return r_i32(client + so) == 6
end

local function get_live_local()
    local ok, lp = pcall(entities.GetLocalPlayer)
    if not ok or not lp then return nil end
    local alive = false
    pcall(function() alive = lp:IsAlive() end)
    return alive and lp or nil
end

local model_ffi_done = false
local function model_ffi()
    if model_ffi_done then return end
    model_ffi_done = true
    pcall(function() ffi.cdef[[
        typedef struct {
            uint32_t dwFileAttributes;
            uint32_t ftCreationLo, ftCreationHi;
            uint32_t ftAccessLo,   ftAccessHi;
            uint32_t ftWriteLo,    ftWriteHi;
            uint32_t nFileSizeHigh, nFileSizeLow;
            uint32_t dwReserved0,  dwReserved1;
            char     cFileName[260];
            char     cAlternateFileName[14];
        } AW_FIND_DATA;
        void*    FindFirstFileA(const char*, AW_FIND_DATA*);
        int      FindNextFileA(void*, AW_FIND_DATA*);
        int      FindClose(void*);
        uint32_t GetCurrentDirectoryA(uint32_t, char*);
        typedef struct {
            int32_t  m_nLength;
            uint32_t m_nAllocatedSize;
            union { char* p; char s[8]; } u;
        } AW_CBufStr;
    ]] end)
    pcall(function() ffi.cdef[[ void* GetModuleHandleA(const char*); ]] end)
    pcall(function() ffi.cdef[[ void* GetProcAddress(void*, const char*); ]] end)
end

local function find_invalid() return ffi.cast("void*", ffi.cast("intptr_t", -1)) end

local function models_root()
    model_ffi()
    local buf = ffi.new("char[?]", 1024)
    local n = ffi.C.GetCurrentDirectoryA(1024, buf)
    local cwd = ffi.string(buf, n)

    local root, count = cwd:gsub("[\\/]bin[\\/]win64.*$", "\\csgo")
    if count == 0 then return nil end
    return root
end

local SCAN_DIRS = { "agents\\models", "characters\\models" }

local function scan_into(dir, names, paths)
    local fd = ffi.new("AW_FIND_DATA")
    local h = ffi.C.FindFirstFileA(dir .. "\\*", fd)
    if h == find_invalid() then return end
    repeat
        local nm = ffi.string(fd.cFileName)
        if nm ~= "." and nm ~= ".." then
            local full = dir .. "\\" .. nm
            if band(fd.dwFileAttributes, 0x10) ~= 0 then
                scan_into(full, names, paths)
            elseif nm:sub(-7) == ".vmdl_c" then
                local stem = nm:sub(1, #nm - 7)

                if not stem:lower():match("_arms?$") then

                    local p = full:lower():find("\\csgo\\", 1, true)
                    if p then
                        local rel = full:sub(p + 6):gsub("\\", "/")
                        rel = rel:sub(1, #rel - 2)
                        names[#names + 1] = stem
                        paths[#paths + 1] = rel
                    end
                end
            end
        end
    until ffi.C.FindNextFileA(h, fd) == 0
    ffi.C.FindClose(h)
end

local g_modelNames, g_modelPaths
local function scan_models()
    if g_modelNames then return g_modelNames, g_modelPaths end
    local names, paths = { "[ OFF ]" }, { "" }
    pcall(function()
        local root = models_root()
        if root then
            for _, sub in ipairs(SCAN_DIRS) do scan_into(root .. "\\" .. sub, names, paths) end
        end
    end)
    g_modelNames, g_modelPaths = names, paths
    return names, paths
end
local function rescan_models()
    g_modelNames, g_modelPaths = nil, nil
    return scan_models()
end

local g_IRS = nil
local PRECACHE_SIG = "40 53 55 57 48 81 EC 80 00 00 00 48 8B 01 49 8B E8 48 8B FA"
local function resolve_model_fns()
    if fnptr.precache and g_IRS and fnptr.cbuf_insert then return true end
    model_ffi()
    if not fn.precache then
        local a = mem.FindPattern("resourcesystem.dll", PRECACHE_SIG)
        if a and a ~= 0 then fn.precache = a end
    end
    if fn.precache and not fnptr.precache then
        fnptr.precache = ffi.cast("void*(*)(void*, void*, const char*)", fn.precache)
    end
    if not g_IRS then
        pcall(function()
            local rs = ffi.C.GetModuleHandleA("resourcesystem.dll")
            local ci = rs and ffi.C.GetProcAddress(rs, "CreateInterface")
            if ci then
                local CI = ffi.cast("void*(*)(const char*, int*)", ci)
                local irs = CI("ResourceSystem013", nil)
                if irs ~= nil then g_IRS = irs end
            end
        end)
    end
    if not fnptr.cbuf_insert then
        pcall(function()
            local t0 = ffi.C.GetModuleHandleA("tier0.dll")
            local ins = t0 and ffi.C.GetProcAddress(t0, "?Insert@CBufferString@@QEAAPEBDHPEBDH_N@Z")
            if ins then fnptr.cbuf_insert = ffi.cast("const char*(*)(void*, int, const char*, int, int)", ins) end
        end)
    end
    return fnptr.precache ~= nil and g_IRS ~= nil and fnptr.cbuf_insert ~= nil
end

local function precache_model(path)
    if path == nil or path == "" then return end
    if not resolve_model_fns() then return end
    local cb = ffi.new("AW_CBufStr")
    cb.m_nLength = 0
    cb.m_nAllocatedSize = 0xC0000008
    cb.u.p = nil
    pcall(function() fnptr.cbuf_insert(cb, 0, path, -1, 0) end)
    pcall(function() fnptr.precache(g_IRS, cb, "") end)
end

local function apply_local_model(pawn, lp)
    if not fnptr.set_model then return end

    local team = 0
    if lp then pcall(function() team = lp:GetFieldInt("m_iTeamNum") end) end
    if team == 0 then pcall(function() team = r_u8(pawn + off.m_iTeamNum) end) end

    if state.origModelPawn ~= pawn then
        state.origModelPawn     = pawn
        state.appliedLocalModel = nil
        state.overrideActive    = false
        state.origModelName     = nil
        if lp then pcall(function()
            local nm = lp:GetModelName()
            if type(nm) == "string" and nm:find("%.vmdl") then
                if (team == 3 and nm:find("/tm_", 1, true)) or (team == 2 and nm:find("/ctm_", 1, true)) then
                    -- Ignore invalid team model when recording origModelName
                else
                    state.origModelName = nm
                end
            end
        end) end
    end
    local path = state.localModel
    if path and path ~= "" then
        if state.appliedLocalModel == path then return end
        precache_model(path)
        pcall(function() fnptr.set_model(ffi.cast("void*", pawn), path) end)
        state.appliedLocalModel = path
        state.overrideActive    = true
    else
        if state.appliedLocalModel == "OFF" then return end
        if state.overrideActive then
            local def_model = state.origModelName
            if not def_model or def_model == "" or (team == 3 and def_model:find("/tm_", 1, true)) or (team == 2 and def_model:find("/ctm_", 1, true)) then
                if team == 3 then
                    def_model = "agents/models/ctm_sas/ctm_sas.vmdl"
                elseif team == 2 then
                    def_model = "agents/models/tm_phoenix/tm_phoenix.vmdl"
                end
            end
            if def_model and def_model ~= "" then
                precache_model(def_model)
                pcall(function() fnptr.set_model(ffi.cast("void*", pawn), def_model) end)
            end
            state.overrideActive = false
        end
        state.appliedLocalModel = "OFF"
    end
end

local last_pawn_handle = 0
local last_run_side = nil
local function run()

    local lp = get_live_local()
    if not lp or not in_game() then
        if next(state.applied) then state.applied = {} end
        return
    end

    local base = mem.GetModuleBase(DLL); if not base then return end
    local ctrl = r_ptr(base + off.dwLocalPlayerController); if not valid(ctrl) then return end
    local myHandle = r_u32(ctrl + off.m_hPlayerPawn)
    if myHandle == 0 or myHandle == 0xFFFFFFFF then return end

    local elist = r_ptr(base + off.dwEntityList); if not valid(elist) then return end
    local pawn = handle_to_entity(elist, myHandle); if not valid(pawn) then return end
    if not valid(r_ptr(pawn + off.m_pGameSceneNode)) then return end

    -- Если сменился pawn (респавн/смена тимы) — сбрасываем всё
    if myHandle ~= last_pawn_handle then
        last_pawn_handle = myHandle
        state.applied = {}
        state.appliedLocalModel = nil
        state.overrideActive = false
        state.resetKnife = true
        state.resetGlove = true
        if fnptr.regen_skins then pcall(function() fnptr.regen_skins() end) end
    end

    if not pawn_alive(pawn) then
        if next(state.applied) then state.applied = {} end
        return
    end

    local applied = state.applied
    if (state.forceRefresh or 0) > 0 then
        state.applied = {}
        applied = state.applied
        state.forceRefresh = state.forceRefresh - 1
    end

    apply_local_model(pawn, lp)
    
    local side = local_team_side(pawn)
    if side ~= last_run_side then
        last_run_side = side
        state.applied = {}
        state.resetKnife = true
        state.resetGlove = true
    end
    local sideCfg = team_cfg_for(side)
    local gdef = selected_glove_def(side)

    if state.resetGlove then
        reset_gloves(pawn); state.resetGlove = false
    elseif gdef then
        local c = sideCfg[gdef] or state.cfg[gdef]
        if c then
            if paint_allowed(gdef, c.paint) then
                apply_gloves(base, pawn, gdef, c.paint, c.wear, c.seed)
            else
                sideCfg[gdef] = nil
                if state.gloveDef == gdef then state.gloveDef = nil end
                state.teamGloveDef[side] = nil
                state.resetGlove = true
            end
        end
    end

    local ws   = r_ptr(pawn + off.m_pWeaponServices); if not valid(ws) then return end
    local count= r_i32(ws + off.m_hMyWeapons)
    local arr  = r_ptr(ws + off.m_hMyWeapons + 8)
    if count<=0 or count>64 or not valid(arr) then return end

    local kdef = selected_knife_def(side)
    local kc   = kdef and (sideCfg[kdef] or state.cfg[kdef])

    local did = false
    for i = 0, count - 1 do
        local wpn = handle_to_entity(elist, r_u32(arr + i*4))
        if wpn then

            if r_u32(wpn + off.m_hOwnerEntity) == myHandle then
                do
                    local def = r_u16(item_ptr(wpn) + off.m_iItemDefinitionIndex)
                    if is_knife(def) then
                        if state.resetKnife and not (kdef and kc) then
                            restore_knife(wpn, pawn); applied[wpn] = nil; state.resetKnife = false; did = true
                        elseif kdef and kc then
                            if not paint_allowed(kdef, kc.paint) then
                                sideCfg[kdef] = nil
                                if state.knifeDef == kdef then state.knifeDef = nil end
                                state.teamKnifeDef[side] = nil
                                state.resetKnife = true
                                applied[wpn] = nil
                                did = true
                            else
                            local s = "k|"..kdef.."|"..kc.paint.."|"..kc.wear.."|"..kc.seed.."|"..tostring(kc.stat)
                            if applied[wpn] ~= s then
                                process_knife(wpn, kdef, kc.paint, kc.wear, kc.seed, kc.stat, 0); applied[wpn]=s; did=true
                            end
                            end
                        end
                    else
                        if state.pendingReset[def] then
                            restore_weapon(wpn); applied[wpn] = nil; state.pendingReset[def] = nil; did = true
                        else
                            local c = state.cfg[def]
                            if c then
                                if not paint_allowed(def, c.paint) then
                                    state.cfg[def] = nil
                                    state.pendingReset[def] = true
                                    applied[wpn] = nil
                                    did = true
                                elseif c.paint > 0 then
                                    local s = "w|"..c.paint.."|"..c.wear.."|"..c.seed.."|"..tostring(c.stat)
                                    if applied[wpn] ~= s then
                                        process_weapon(wpn, c.paint, c.wear, c.seed, c.stat, 0); applied[wpn]=s; did=true
                                    end
                                else
                                    local s = "w|none"
                                    if applied[wpn] ~= s then
                                        restore_weapon(wpn); applied[wpn]=s; did=true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if (did or (state.forceRefresh or 0) > 0) and fnptr.regen_skins then fnptr.regen_skins() end
end

local function active_weapon_def()
    if not get_live_local() then return nil end
    local base = mem.GetModuleBase(DLL); if not base then return nil end
    local ctrl = r_ptr(base + off.dwLocalPlayerController); if not valid(ctrl) then return nil end
    local elist = r_ptr(base + off.dwEntityList)
    local pawn = handle_to_entity(elist, r_u32(ctrl + off.m_hPlayerPawn)); if not valid(pawn) then return nil end
    local ws   = r_ptr(pawn + off.m_pWeaponServices); if not valid(ws) then return nil end
    local wpn  = handle_to_entity(elist, r_u32(ws + off.m_hActiveWeapon)); if not wpn then return nil end
    return r_u16(item_ptr(wpn) + off.m_iItemDefinitionIndex)
end

local CFG_FILE = "awchanger.txt"

local function file_write(path, data)
    local ok = false
    pcall(function()
        local f = file.Open(path, "w")
        if f then f:Write(data); f:Close(); ok = true end
    end)
    return ok
end

local function file_read(path)
    local data
    pcall(function()
        local f = file.Open(path, "r")
        if f then data = f:Read(); f:Close() end
    end)
    return data
end

function Config.serialize()
    local lines = { "AWCFG1",
                    "K " .. tostring(state.knifeDef or 0),
                    "G " .. tostring(state.gloveDef or 0) }

    -- Global weapon configs only. Knives/gloves are serialized per team below.
    for def, c in pairs(state.cfg) do
        if (c.kind or "weapon") == "weapon" then
            lines[#lines + 1] = string.format("E %d %d %.6f %d %d %s %d",
                def, c.paint or 0, c.wear or 0.0001, c.seed or 0, c.stat and 1 or 0, c.kind or "weapon", 0)
        end
    end

    -- Per-team knife/glove selections and skins.
    for _, side in ipairs({ "t", "ct" }) do
        if state.teamKnifeDef[side] then
            lines[#lines + 1] = string.format("KT %s %d", side, state.teamKnifeDef[side])
        end
        if state.teamGloveDef[side] then
            lines[#lines + 1] = string.format("GT %s %d", side, state.teamGloveDef[side])
        end
        local tc = state.teamCfg[side] or {}
        for def, c in pairs(tc) do
            if c.kind == "knife" or c.kind == "glove" then
                lines[#lines + 1] = string.format("TE %s %d %d %.6f %d %d %s %d",
                    side, def, c.paint or 0, c.wear or 0.0001, c.seed or 0, c.stat and 1 or 0, c.kind, c.statval or 0)
            end
        end
    end

    for k, v in pairs(state.opts) do
        local tv = type(v)
        local tag = (tv == "boolean") and "b" or (tv == "number") and "n" or "s"
        local sv  = (tv == "boolean") and (v and "1" or "0") or tostring(v)
        lines[#lines + 1] = string.format("O %s %s %s", k, tag, sv)
    end
    if state.localModel and state.localModel ~= "" then
        lines[#lines + 1] = "L " .. state.localModel
    end
    return table.concat(lines, "\n")
end

function Config.parse(str)
    if type(str) ~= "string" or not str:find("AWCFG1", 1, true) then return nil end
    local newCfg, kdef, gdef, opts, lmodel = {}, nil, nil, {}, nil
    local teamCfg = { t = {}, ct = {} }
    local teamKnifeDef = { t = nil, ct = nil }
    local teamGloveDef = { t = nil, ct = nil }

    for line in str:gmatch("[^\r\n]+") do
        if line:sub(1, 2) == "KT" then
            local side, v = line:match("^KT%s+(%a+)%s+(%-?%d+)")
            v = tonumber(v)
            if (side == "t" or side == "ct") and v and v ~= 0 then teamKnifeDef[side] = v end
        elseif line:sub(1, 2) == "GT" then
            local side, v = line:match("^GT%s+(%a+)%s+(%-?%d+)")
            v = tonumber(v)
            if (side == "t" or side == "ct") and v and v ~= 0 then teamGloveDef[side] = v end
        elseif line:sub(1, 2) == "TE" then
            local side, d, p, w, sd, st, kind, sv, nt =
                line:match("^TE%s+(%a+)%s+(%-?%d+)%s+(%-?%d+)%s+([%d%.eE%+%-]+)%s+(%-?%d+)%s+(%d)%s+(%a+)%s*(%d*)%|?(.*)$")
            d, p, w, sd = tonumber(d), tonumber(p), tonumber(w), tonumber(sd)
            if (side == "t" or side == "ct") and d then
                teamCfg[side][d] = { paint = p or 0, wear = w or 0.0001, seed = sd or 0,
                                     stat = (st == "1"), kind = kind or "knife", statval = tonumber(sv) or 0, nametag = nt or "" }
            end
        else
            local t = line:sub(1, 1)
            if t == "K" then
                local v = tonumber(line:match("^K%s+(%-?%d+)")); if v and v ~= 0 then kdef = v end
            elseif t == "G" then
                local v = tonumber(line:match("^G%s+(%-?%d+)")); if v and v ~= 0 then gdef = v end
            elseif t == "E" then
                local d, p, w, sd, st, kind, sv, nt =
                    line:match("^E%s+(%-?%d+)%s+(%-?%d+)%s+([%d%.eE%+%-]+)%s+(%-?%d+)%s+(%d)%s+(%a+)%s*(%d*)%|?(.*)$")
                d, p, w, sd = tonumber(d), tonumber(p), tonumber(w), tonumber(sd)
                if d then
                    newCfg[d] = { paint = p or 0, wear = w or 0.0001, seed = sd or 0,
                                  stat = (st == "1"), kind = kind or "weapon", statval = tonumber(sv) or 0, nametag = nt or "" }
                end
            elseif t == "O" then
                local k, tag, v = line:match("^O%s+(%S+)%s+(%a)%s+(.*)$")
                if k then
                    if     tag == "b" then opts[k] = (v == "1")
                    elseif tag == "n" then opts[k] = tonumber(v) or 0
                    else                   opts[k] = v end
                end
            elseif t == "L" then
                local v = line:match("^L%s+(.+)$")
                if v and v ~= "" then lmodel = v end
            end
        end
    end

    -- Migrate old one-team K/G config to both teams if no per-team config exists yet.
    for _, side in ipairs({ "t", "ct" }) do
        if not teamKnifeDef[side] and kdef then teamKnifeDef[side] = kdef end
        if not teamGloveDef[side] and gdef then teamGloveDef[side] = gdef end
        if kdef and newCfg[kdef] and not teamCfg[side][kdef] then
            teamCfg[side][kdef] = copy_cfg_entry(newCfg[kdef]); teamCfg[side][kdef].kind = "knife"
        end
        if gdef and newCfg[gdef] and not teamCfg[side][gdef] then
            teamCfg[side][gdef] = copy_cfg_entry(newCfg[gdef]); teamCfg[side][gdef].kind = "glove"
        end
    end

    -- Keep state.cfg clean: after migration, knives/gloves live in teamCfg.
    for def, c in pairs(newCfg) do
        if c.kind == "knife" or c.kind == "glove" then newCfg[def] = nil end
    end

    return newCfg, kdef, gdef, opts, lmodel, teamCfg, teamKnifeDef, teamGloveDef
end

function Config.applyTable(newCfg, kdef, gdef, opts, lmodel, teamCfg, teamKnifeDef, teamGloveDef)
    for def, c in pairs(state.cfg) do
        if c.kind == "weapon" and not newCfg[def] then state.pendingReset[def] = true end
    end
    state.resetKnife = true
    state.resetGlove = true
    state.cfg      = newCfg or {}
    state.knifeDef = kdef
    state.gloveDef = gdef
    state.teamCfg  = teamCfg or { t = {}, ct = {} }
    state.teamKnifeDef = teamKnifeDef or { t = nil, ct = nil }
    state.teamGloveDef = teamGloveDef or { t = nil, ct = nil }
    state.opts     = opts or {}
    state.localModel = lmodel
    state.appliedLocalModel = nil
    state.applied  = {}
end

function Config.save() return file_write(CFG_FILE, Config.serialize()) end

function Config.load()
    local newCfg, kdef, gdef, opts, lmodel, teamCfg, teamKnifeDef, teamGloveDef = Config.parse(file_read(CFG_FILE))
    if not newCfg then return false end
    Config.applyTable(newCfg, kdef, gdef, opts, lmodel, teamCfg, teamKnifeDef, teamGloveDef)
    saved_agent_path = state.localModel or ""
    return true
end

local function commit()
    state.applied = {}
    Config.save()
end

local C = {}
C.items     = ITEMS
C.names     = itemNames
C.defToItem = DEF_TO_ITEM
C.offsets   = off

function C.skinList(def, show_legacy) return skin_list_for(def, show_legacy) end
function C.isKnife(def)  return is_knife(def) end
function C.paintAllowed(def, paint) return paint_allowed(def, paint) end
function C.isLegacySkin(def, paint) return is_legacy_skin(def, paint) end
function C.activeDef()   return g_activeDef end
function C.knifeDef(side) return selected_knife_def(side or local_team_side()) end
function C.gloveDef(side) return selected_glove_def(side or local_team_side()) end
function C.getCfg(def, kind, side) return cfg_for_item(def, kind, side or local_team_side()) end
function C.currentSide() return local_team_side() end

function C.apply(item, paint, wear, seed, stat, statval, nametag, side)
    if not item then return "nothing selected" end
    side = (side == "t") and "t" or (side == "ct") and "ct" or local_team_side()
    paint = tonumber(paint) or 0
    if not paint_allowed(item.def, paint) then
        return string.format("wrong skin: paint %d does not belong to %s", paint, tostring(item.name))
    end

    if item.kind == "glove" and item.def == 0 then
        state.teamGloveDef[side] = nil
        team_cfg_for(side)[0] = nil
        state.resetGlove = true
        state.forceRefresh = 4
        commit()
        return "gloves " .. side .. ": default"
    end

    local entry = { paint = paint, wear = wear, seed = seed, stat = stat, statval = statval, nametag = nametag, kind = item.kind }

    if item.kind == "knife" then
        team_cfg_for(side)[item.def] = entry
        state.teamKnifeDef[side] = item.def
        state.knifeDef = item.def -- legacy fallback only
        state.cfg[item.def] = nil
    elseif item.kind == "glove" then
        team_cfg_for(side)[item.def] = entry
        state.teamGloveDef[side] = item.def
        state.gloveDef = item.def -- legacy fallback only
        state.cfg[item.def] = nil
    else
        state.cfg[item.def] = entry
    end

    if item.kind == "weapon" and is_legacy_skin(item.def, paint) then
        state.forceRefresh = 16 -- try harder for legacy skins; not guaranteed
    else
        state.forceRefresh = 4
    end
    commit()
    if item.kind == "weapon" and is_legacy_skin(item.def, paint) then
        return string.format("applied legacy: %s (paint %d) | aggressive refresh, may still look broken", item.name, paint)
    end
    if item.kind == "knife" or item.kind == "glove" then
        return string.format("applied [%s]: %s (paint %d)", side, item.name, paint)
    end
    return string.format("applied: %s (paint %d)", item.name, paint)
end

function C.remove(item, side)
    if not item then return "nothing selected" end
    side = (side == "t") and "t" or (side == "ct") and "ct" or local_team_side()

    if item.kind == "knife" then
        team_cfg_for(side)[item.def] = nil
        if state.teamKnifeDef[side] == item.def then state.teamKnifeDef[side] = nil end
        if state.knifeDef == item.def then state.knifeDef = nil end
        state.resetKnife = true
    elseif item.kind == "glove" then
        team_cfg_for(side)[item.def] = nil
        if state.teamGloveDef[side] == item.def then state.teamGloveDef[side] = nil end
        if state.gloveDef == item.def then state.gloveDef = nil end
        state.resetGlove = true
    else
        state.cfg[item.def] = nil
        state.pendingReset[item.def] = true
    end
    state.forceRefresh = 8
    commit()
    if item.kind == "knife" or item.kind == "glove" then
        return "removed [" .. side .. "]: " .. item.name
    end
    return "removed: " .. item.name
end

function C.resetAll()
    for def, c in pairs(state.cfg) do
        if c.kind == "weapon" then state.pendingReset[def] = true end
    end
    state.cfg        = {}
    state.knifeDef   = nil
    state.gloveDef   = nil
    state.teamKnifeDef = { t = nil, ct = nil }
    state.teamGloveDef = { t = nil, ct = nil }
    state.teamCfg      = { t = {}, ct = {} }
    state.resetKnife = true
    state.resetGlove = true
    state.forceRefresh = 10
    commit()
    return "reset all"
end

function C.clearConfig()
    C.resetAll()
    pcall(function() file.Delete(CFG_FILE) end)
    return "config cleared"
end

function C.loadConfig() return Config.load() end
function C.getOpt(k)     return state.opts[k] end
function C.setOpt(k, v)  state.opts[k] = v; Config.save() end

-- Skin Changer option: rare knife animations toggle.
-- The actual animation hook can read this through C.rareAnimations()
-- or directly via C.getOpt("rare_animations").
function C.rareAnimations()
    return (state.opts.rare_animations == true) or (state.opts.rare_anim == true)
end

function C.setRareAnimations(v)
    local on = v and true or false
    state.opts.rare_animations = on
    -- legacy alias, in case older pasted animation logic checks this name
    state.opts.rare_anim = on
    Config.save()
end
function C.forceRefresh(ticks)
    state.applied = {}
    state.forceRefresh = ticks or 12
    if fnptr.regen_skins then pcall(function() fnptr.regen_skins() end) end
    return "force refresh queued: " .. tostring(state.forceRefresh)
end

function C.modelList()     return scan_models() end
function C.refreshModels() return rescan_models() end
function C.getLocalModel() return state.localModel end
function C.setLocalModel(path)
    if path == nil or path == "" then state.localModel = nil
    else state.localModel = path end
    state.appliedLocalModel = nil
    Config.save()
    return state.localModel
end

callbacks.Register("CreateMove", function()
    local okd, d = pcall(active_weapon_def); g_activeDef = okd and d or nil
    local ok, err = pcall(run)
    -- silent errors
end)

resolve()
pcall(resolve_model_fns)
local n = 0; for _ in pairs(SKINS) do n = n + 1 end
local ok_root, root_str = pcall(models_root)
-- Загружаем сохранённый конфиг скинов и агента
Config.load()

-- ============================================================
-- Export API for external / appended UI
-- ============================================================
_G["AWCHANGER_API"] = C

-- ============================================================
-- Appended Skin Changer UI
-- ============================================================
local local_tab = gui.Reference("VISUALS", "Local")

-- ========== ЛЕВЫЙ GROUPBOX - СКИН ЧЕНДЖЕР ==========
local gb1 = gui.Groupbox(local_tab, "Skin Changer", 16, 0, 356, 600)

-- Сверху большой листбокс скинов
local skin_listbox = gui.Listbox(gb1, "sc_skinlist", 300, "[ Select weapon first ]")

-- Ниже wear/seed
local skin_wear         = gui.Slider(gb1, "sc_wear",  "Wear",           0.01, 0.0001, 1.0,    0.0001)
local skin_seed         = gui.Slider(gb1, "sc_seed",  "Seed",           0,    0,      1000,   1)
local skin_st           = gui.Checkbox(gb1, "sc_st",  "StatTrak™",      false)
local show_legacy_cb    = gui.Checkbox(gb1, "sc_legacy", "Show legacy skins (may be broken)", false)
local custom_model_cb   = gui.Checkbox(gb1, "sc_custom_model", "Custom Models (scanned only)", false)

local flag_remove  = false
local flag_refresh = false
local last_skin_idx = -1 -- для автоприменения

local btn_remove  = gui.Button(gb1, "Remove Selected", function() flag_remove  = true end)
local btn_refresh = gui.Button(gb1, "Force Refresh", function() flag_refresh = true end)

-- ========== ПРАВЫЙ GROUPBOX - ОРУЖИЕ/НОЖ/ПЕРЧАТКИ ==========
local gb2 = gui.Groupbox(local_tab, "Weapon / Knife / Gloves", 382, 219, 352, 300)

local cat_combo      = gui.Combobox(gb2, "sc_cat",  "Category", "Weapons", "Knives", "Gloves", "Agents")
local team_combo     = gui.Combobox(gb2, "sc_team", "Team", "Auto", "T", "CT")
local item_combo     = gui.Combobox(gb2, "sc_item", "Item",     "Loading...")
local auto_select_cb = gui.Checkbox(gb2, "sc_auto", "Auto select active weapon", true)
local always_agents_cb = gui.Checkbox(gb2, "sc_always_agents", "Always all agents (T & CT)", false)
local rare_anim_cb = gui.Checkbox(gb2, "sc_rare_animations", "Rare knife animations", false)
pcall(function()
    rare_anim_cb:SetDescription("Enables the saved Skin Changer option for rare knife animations.")
end)

-- ============================================================
-- Changer API
-- ============================================================
local C = nil
pcall(function() C = _G["AWCHANGER_API"] end)

local CAT_WEAPONS, CAT_KNIVES, CAT_GLOVES, CAT_AGENTS = {}, {}, {}, {}

local function is_game_agent_model(name, path)
    path = tostring(path or ""):lower()

    -- keep OFF/default option
    if path == "" then return true end

    -- CS2: agent models are under agents/models/
    if not path:find("agents/models/", 1, true) then return false end

    -- reject non-player garbage
    if path:find("arms", 1, true) then return false end
    if path:find("weapon", 1, true) then return false end
    if path:find("viewmodel", 1, true) then return false end
    if path:find("props", 1, true) then return false end
    if path:find("chicken", 1, true) then return false end
    if path:find("hostage", 1, true) then return false end
    if path:find("glove_", 1, true) then return false end

    -- CT models
    if path:find("agents/models/ctm_", 1, true) then return true end
    -- T models
    if path:find("agents/models/tm_", 1, true) then return true end

    return false
end

-- Hardcoded agent paths as fallback
local AGENT_PRESETS = {
    { name = "[ OFF ]",                 path = "", kind = "agent" },
    { name = "[CT] Diver A",            path = "agents/models/ctm_diver/ctm_diver_varianta.vmdl",        kind = "agent" },
    { name = "[CT] Diver B",            path = "agents/models/ctm_diver/ctm_diver_variantb.vmdl",        kind = "agent" },
    { name = "[CT] Diver C",            path = "agents/models/ctm_diver/ctm_diver_variantc.vmdl",        kind = "agent" },
    { name = "[CT] FBI Default",        path = "agents/models/ctm_fbi/ctm_fbi.vmdl",                     kind = "agent" },
    { name = "[CT] FBI A",              path = "agents/models/ctm_fbi/ctm_fbi_varianta.vmdl",            kind = "agent" },
    { name = "[CT] FBI B",              path = "agents/models/ctm_fbi/ctm_fbi_variantb.vmdl",            kind = "agent" },
    { name = "[CT] FBI C",              path = "agents/models/ctm_fbi/ctm_fbi_variantc.vmdl",            kind = "agent" },
    { name = "[CT] FBI D",              path = "agents/models/ctm_fbi/ctm_fbi_variantd.vmdl",            kind = "agent" },
    { name = "[CT] FBI E",              path = "agents/models/ctm_fbi/ctm_fbi_variante.vmdl",            kind = "agent" },
    { name = "[CT] FBI F",              path = "agents/models/ctm_fbi/ctm_fbi_variantf.vmdl",            kind = "agent" },
    { name = "[CT] FBI G",              path = "agents/models/ctm_fbi/ctm_fbi_variantg.vmdl",            kind = "agent" },
    { name = "[CT] FBI H",              path = "agents/models/ctm_fbi/ctm_fbi_varianth.vmdl",            kind = "agent" },
    { name = "[CT] Gendarmerie A",      path = "agents/models/ctm_gendarmerie/ctm_gendarmerie_varianta.vmdl",  kind = "agent" },
    { name = "[CT] Gendarmerie B",      path = "agents/models/ctm_gendarmerie/ctm_gendarmerie_variantb.vmdl",  kind = "agent" },
    { name = "[CT] Gendarmerie C",      path = "agents/models/ctm_gendarmerie/ctm_gendarmerie_variantc.vmdl",  kind = "agent" },
    { name = "[CT] Gendarmerie D",      path = "agents/models/ctm_gendarmerie/ctm_gendarmerie_variantd.vmdl",  kind = "agent" },
    { name = "[CT] Gendarmerie E",      path = "agents/models/ctm_gendarmerie/ctm_gendarmerie_variante.vmdl",  kind = "agent" },
    { name = "[CT] SAS Default",        path = "agents/models/ctm_sas/ctm_sas.vmdl",                     kind = "agent" },
    { name = "[CT] SAS F",              path = "agents/models/ctm_sas/ctm_sas_variantf.vmdl",            kind = "agent" },
    { name = "[CT] SAS G",              path = "agents/models/ctm_sas/ctm_sas_variantg.vmdl",            kind = "agent" },
    { name = "[CT] ST6 E",              path = "agents/models/ctm_st6/ctm_st6_variante.vmdl",            kind = "agent" },
    { name = "[CT] ST6 G",              path = "agents/models/ctm_st6/ctm_st6_variantg.vmdl",            kind = "agent" },
    { name = "[CT] ST6 I",              path = "agents/models/ctm_st6/ctm_st6_varianti.vmdl",            kind = "agent" },
    { name = "[CT] ST6 J",              path = "agents/models/ctm_st6/ctm_st6_variantj.vmdl",            kind = "agent" },
    { name = "[CT] ST6 K",              path = "agents/models/ctm_st6/ctm_st6_variantk.vmdl",            kind = "agent" },
    { name = "[CT] ST6 L",              path = "agents/models/ctm_st6/ctm_st6_variantl.vmdl",            kind = "agent" },
    { name = "[CT] ST6 M",              path = "agents/models/ctm_st6/ctm_st6_variantm.vmdl",            kind = "agent" },
    { name = "[CT] ST6 N",              path = "agents/models/ctm_st6/ctm_st6_variantn.vmdl",            kind = "agent" },
    { name = "[CT] SWAT E",             path = "agents/models/ctm_swat/ctm_swat_variante.vmdl",          kind = "agent" },
    { name = "[CT] SWAT F",             path = "agents/models/ctm_swat/ctm_swat_variantf.vmdl",          kind = "agent" },
    { name = "[CT] SWAT G",             path = "agents/models/ctm_swat/ctm_swat_variantg.vmdl",          kind = "agent" },
    { name = "[CT] SWAT H",             path = "agents/models/ctm_swat/ctm_swat_varianth.vmdl",          kind = "agent" },
    { name = "[CT] SWAT I",             path = "agents/models/ctm_swat/ctm_swat_varianti.vmdl",          kind = "agent" },
    { name = "[CT] SWAT J",             path = "agents/models/ctm_swat/ctm_swat_variantj.vmdl",          kind = "agent" },
    { name = "[CT] SWAT K",             path = "agents/models/ctm_swat/ctm_swat_variantk.vmdl",          kind = "agent" },
    { name = "[T] Balkan F",            path = "agents/models/tm_balkan/tm_balkan_variantf.vmdl",        kind = "agent" },
    { name = "[T] Balkan G",            path = "agents/models/tm_balkan/tm_balkan_variantg.vmdl",        kind = "agent" },
    { name = "[T] Balkan H",            path = "agents/models/tm_balkan/tm_balkan_varianth.vmdl",        kind = "agent" },
    { name = "[T] Balkan I",            path = "agents/models/tm_balkan/tm_balkan_varianti.vmdl",        kind = "agent" },
    { name = "[T] Balkan J",            path = "agents/models/tm_balkan/tm_balkan_variantj.vmdl",        kind = "agent" },
    { name = "[T] Balkan K",            path = "agents/models/tm_balkan/tm_balkan_variantk.vmdl",        kind = "agent" },
    { name = "[T] Balkan L",            path = "agents/models/tm_balkan/tm_balkan_variantl.vmdl",        kind = "agent" },
    { name = "[T] Jungle Raider A",     path = "agents/models/tm_jungle_raider/tm_jungle_raider_varianta.vmdl",   kind = "agent" },
    { name = "[T] Jungle Raider B",     path = "agents/models/tm_jungle_raider/tm_jungle_raider_variantb.vmdl",   kind = "agent" },
    { name = "[T] Jungle Raider B2",    path = "agents/models/tm_jungle_raider/tm_jungle_raider_variantb2.vmdl",  kind = "agent" },
    { name = "[T] Jungle Raider C",     path = "agents/models/tm_jungle_raider/tm_jungle_raider_variantc.vmdl",   kind = "agent" },
    { name = "[T] Jungle Raider D",     path = "agents/models/tm_jungle_raider/tm_jungle_raider_variantd.vmdl",   kind = "agent" },
    { name = "[T] Jungle Raider E",     path = "agents/models/tm_jungle_raider/tm_jungle_raider_variante.vmdl",   kind = "agent" },
    { name = "[T] Jungle Raider F",     path = "agents/models/tm_jungle_raider/tm_jungle_raider_variantf.vmdl",   kind = "agent" },
    { name = "[T] Jungle Raider F2",    path = "agents/models/tm_jungle_raider/tm_jungle_raider_variantf2.vmdl",  kind = "agent" },
    { name = "[T] Leet A",              path = "agents/models/tm_leet/tm_leet_varianta.vmdl",             kind = "agent" },
    { name = "[T] Leet B",              path = "agents/models/tm_leet/tm_leet_variantb.vmdl",             kind = "agent" },
    { name = "[T] Leet C",              path = "agents/models/tm_leet/tm_leet_variantc.vmdl",             kind = "agent" },
    { name = "[T] Leet D",              path = "agents/models/tm_leet/tm_leet_variantd.vmdl",             kind = "agent" },
    { name = "[T] Leet E",              path = "agents/models/tm_leet/tm_leet_variante.vmdl",             kind = "agent" },
    { name = "[T] Leet F",              path = "agents/models/tm_leet/tm_leet_variantf.vmdl",             kind = "agent" },
    { name = "[T] Leet G",              path = "agents/models/tm_leet/tm_leet_variantg.vmdl",             kind = "agent" },
    { name = "[T] Leet H",              path = "agents/models/tm_leet/tm_leet_varianth.vmdl",             kind = "agent" },
    { name = "[T] Leet I",              path = "agents/models/tm_leet/tm_leet_varianti.vmdl",             kind = "agent" },
    { name = "[T] Leet J",              path = "agents/models/tm_leet/tm_leet_variantj.vmdl",             kind = "agent" },
    { name = "[T] Leet K",              path = "agents/models/tm_leet/tm_leet_variantk.vmdl",             kind = "agent" },
    { name = "[T] Phoenix Default",     path = "agents/models/tm_phoenix/tm_phoenix.vmdl",                kind = "agent" },
    { name = "[T] Phoenix A",           path = "agents/models/tm_phoenix/tm_phoenix_varianta.vmdl",       kind = "agent" },
    { name = "[T] Phoenix B",           path = "agents/models/tm_phoenix/tm_phoenix_variantb.vmdl",       kind = "agent" },
    { name = "[T] Phoenix C",           path = "agents/models/tm_phoenix/tm_phoenix_variantc.vmdl",       kind = "agent" },
    { name = "[T] Phoenix D",           path = "agents/models/tm_phoenix/tm_phoenix_variantd.vmdl",       kind = "agent" },
    { name = "[T] Phoenix F",           path = "agents/models/tm_phoenix/tm_phoenix_variantf.vmdl",       kind = "agent" },
    { name = "[T] Phoenix G",           path = "agents/models/tm_phoenix/tm_phoenix_variantg.vmdl",       kind = "agent" },
    { name = "[T] Phoenix H",           path = "agents/models/tm_phoenix/tm_phoenix_varianth.vmdl",       kind = "agent" },
    { name = "[T] Phoenix I",           path = "agents/models/tm_phoenix/tm_phoenix_varianti.vmdl",       kind = "agent" },
    { name = "[T] Professional F",      path = "agents/models/tm_professional/tm_professional_varf.vmdl",  kind = "agent" },
    { name = "[T] Professional F1",     path = "agents/models/tm_professional/tm_professional_varf1.vmdl", kind = "agent" },
    { name = "[T] Professional F2",     path = "agents/models/tm_professional/tm_professional_varf2.vmdl", kind = "agent" },
    { name = "[T] Professional F3",     path = "agents/models/tm_professional/tm_professional_varf3.vmdl", kind = "agent" },
    { name = "[T] Professional F4",     path = "agents/models/tm_professional/tm_professional_varf4.vmdl", kind = "agent" },
    { name = "[T] Professional F5",     path = "agents/models/tm_professional/tm_professional_varf5.vmdl", kind = "agent" },
    { name = "[T] Professional G",      path = "agents/models/tm_professional/tm_professional_varg.vmdl",  kind = "agent" },
    { name = "[T] Professional H",      path = "agents/models/tm_professional/tm_professional_varh.vmdl",  kind = "agent" },
    { name = "[T] Professional I",      path = "agents/models/tm_professional/tm_professional_vari.vmdl",  kind = "agent" },
    { name = "[T] Professional J",      path = "agents/models/tm_professional/tm_professional_varj.vmdl",  kind = "agent" },
}
local function build_lists()
    if not C then return end
    CAT_WEAPONS, CAT_KNIVES, CAT_GLOVES, CAT_AGENTS = {}, {}, {}, {}
    for i = 1, #C.items do
        local it = C.items[i]
        if     it.kind == "weapon" then CAT_WEAPONS[#CAT_WEAPONS+1] = it
        elseif it.kind == "knife"  then CAT_KNIVES [#CAT_KNIVES +1] = it
        elseif it.kind == "glove"  then CAT_GLOVES [#CAT_GLOVES +1] = it
        end
    end

    -- Try scanning agents/models/ first
    local scanned = false
    if C.modelList then
        local names, paths = C.modelList()
        if names and #names > 1 then
            for i = 1, #(names or {}) do
                local nm, path = names[i], paths and paths[i] or ""
                if nm and path ~= nil and is_game_agent_model(nm, path) then
                    local duplicate = false
                    for j = 1, #CAT_AGENTS do
                        if CAT_AGENTS[j].path == path then duplicate = true; break end
                    end
                    if not duplicate then
                        CAT_AGENTS[#CAT_AGENTS + 1] = { name = nm, path = path, kind = "agent" }
                    end
                end
            end
            if #CAT_AGENTS > 1 then scanned = true end
        end
    end

    -- If scanning failed, use hardcoded presets
    if not scanned and #AGENT_PRESETS > 0 then
        CAT_AGENTS = {}
        for i = 1, #AGENT_PRESETS do
            CAT_AGENTS[#CAT_AGENTS + 1] = {
                name = AGENT_PRESETS[i].name,
                path = AGENT_PRESETS[i].path,
                kind = "agent"
            }
        end
    end

    if #CAT_AGENTS == 0 then
        CAT_AGENTS[1] = { name = "[ OFF ]", path = "", kind = "agent" }
    end
end

build_lists()
if C and C.getOpt and C.getOpt("show_legacy") ~= nil then
    show_legacy_cb:SetValue(C.getOpt("show_legacy") and true or false)
end
if C and C.getOpt and C.getOpt("custom_model") ~= nil then
    custom_model_cb:SetValue(C.getOpt("custom_model") and true or false)
end
if C and C.getOpt then
    local saved_rare_anim = C.getOpt("rare_animations")
    if saved_rare_anim == nil then saved_rare_anim = C.getOpt("rare_anim") end
    if saved_rare_anim ~= nil then
        rare_anim_cb:SetValue(saved_rare_anim and true or false)
    end
end
-- Загружаем сохранённый конфиг (скины + агент)
-- При старте накатываем агента для текущей команды
local team0 = 0
local lp0 = entities.GetLocalPlayer()
if lp0 then pcall(function() team0 = lp0:GetFieldInt("m_iTeamNum") end) end
local side0 = (team0 == 2) and "t" or (team0 == 3) and "ct" or nil
if side0 and C and C.getOpt then
    local saved0 = C.getOpt("agent_" .. side0) or ""
    saved_agent_path = saved0
    if saved0 ~= "" then
        C.setLocalModel(saved0)
    end
end

local cur_item   = nil
local cur_cat    = 0
local cur_paints = { 0 }
local last_team  = 0
local saved_agent_path = "" -- текущий путь агента (на всякий случай)

local function selected_ui_side()
    local v = team_combo:GetValue()
    if v == 1 then return "t" end
    if v == 2 then return "ct" end

    local team = 0
    local lp = entities.GetLocalPlayer()
    if lp then pcall(function() team = lp:GetFieldInt("m_iTeamNum") end) end
    if team == 2 then return "t" end
    if team == 3 then return "ct" end
    if C and C.currentSide then return C.currentSide() end
    return "ct"
end

-- Таблица рук для каждой команды

local function get_cat_list()
    if cur_cat == 0 then return CAT_WEAPONS
    elseif cur_cat == 1 then return CAT_KNIVES
    elseif cur_cat == 2 then return CAT_GLOVES
    else return CAT_AGENTS end
end

local function update_item_combo()
    if cur_cat == 3 then
        item_combo:SetOptions("[ Agents in list below ]")
        return
    end
    local list  = get_cat_list()
    local names = {}
    for i = 1, #list do names[i] = list[i].name end
    if #names == 0 then names = {"[ Empty ]"} end
    item_combo:SetOptions(unpack(names))
end

local function update_skin_listbox()
    local names, paints = {}, {}
    local target_val = nil
    local is_agent = (cur_cat == 3)

    if is_agent then
        local team = 0
        local lp = entities.GetLocalPlayer()
        if lp then pcall(function() team = lp:GetFieldInt("m_iTeamNum") end) end
        last_team = team

        local use_custom = custom_model_cb:GetValue()
        names = { "[ OFF ]" }
        paints = { "" }

        if use_custom then
            local scanned_names, scanned_paths
            if C and C.modelList then scanned_names, scanned_paths = C.modelList() end
            if scanned_names and #scanned_names > 1 then
                for i = 1, #scanned_names do
                    local nm = scanned_names[i]
                    local p = scanned_paths and scanned_paths[i] or ""
                    if p ~= "" and nm ~= "[ OFF ]" then
                        local lower = nm:lower()
                        if not lower:match("_arms?$") and not lower:find("weapon") and not lower:find("glove_") and not lower:find("viewmodel") and not lower:find("props") and not lower:find("chicken") and not lower:find("hostage") then
                            names[#names + 1] = nm
                            paints[#paints + 1] = p
                        end
                    end
                end
            end
        else
            local show_all = always_agents_cb:GetValue()
            for i = 1, #CAT_AGENTS do
                local a = CAT_AGENTS[i]
                if a.path ~= "" then
                    if show_all or (team == 2 and a.path:find("/tm_", 1, true)) or (team == 3 and a.path:find("/ctm_", 1, true)) or team == 0 then
                        names[#names + 1] = a.name
                        paints[#paints + 1] = a.path
                    end
                end
            end
        end

        local side = (team == 2) and "t" or (team == 3) and "ct" or nil
        target_val = (side and C and C.getOpt and C.getOpt("agent_" .. side)) or saved_agent_path
        if target_val == "" then target_val = nil end
    else
        if not cur_item or not C then
            skin_listbox:SetOptions("[ Select weapon first ]")
            cur_paints = { 0 }
            return
        end
        names, paints = C.skinList(cur_item.def, show_legacy_cb:GetValue())
        local cfg = C.getCfg(cur_item.def, cur_item.kind, selected_ui_side())
        if cfg and cfg.paint and cfg.paint > 0 then
            target_val = cfg.paint
            skin_wear:SetValue(cfg.wear or 0.01)
            skin_seed:SetValue(cfg.seed or 0)
            skin_st:SetValue(cfg.stat or false)
        else
            skin_wear:SetValue(0.01)
            skin_seed:SetValue(0)
            skin_st:SetValue(false)
        end
    end

    cur_paints = paints
    skin_listbox:SetOptions(unpack(names))

    -- Подсветить применённый скин
    local found = false
    if target_val then
        for i = 1, #paints do
            if paints[i] == target_val then
                skin_listbox:SetValue(i - 1)
                last_skin_idx = i - 1
                found = true
                break
            end
        end
    end
    if not found then
        skin_listbox:SetValue(0)
        last_skin_idx = 0
    end
end

local function do_apply()
    if not C then
        return
    end

    -- Agent/model changer category
    if cur_cat == 3 then
        local idx = skin_listbox:GetValue()
        local path = cur_paints[idx + 1] or ""
        saved_agent_path = path
        if C then
            local team = 0
            local lp3 = entities.GetLocalPlayer()
            if lp3 then pcall(function() team = lp3:GetFieldInt("m_iTeamNum") end) end
            local side = (team == 2) and "t" or (team == 3) and "ct" or nil
            if side and C.setOpt then
                C.setOpt("agent_" .. side, path)
            end
            if path == "" then
                C.setLocalModel(nil)
            else
                C.setLocalModel(path)
            end
            C.forceRefresh(16)
        end
        return
    end

    if not cur_item then return end

    local idx     = skin_listbox:GetValue()
    local paint   = cur_paints[idx + 1] or 0
    local wear    = skin_wear:GetValue()
    local seed    = math.floor(skin_seed:GetValue())
    local stat    = skin_st:GetValue()
    if C.isLegacySkin and C.isLegacySkin(cur_item.def, paint) then
    end
    C.apply(cur_item, paint, wear, seed, stat, 0, "", selected_ui_side())
end

local function do_force_refresh()
    if C and C.forceRefresh then
        C.forceRefresh(16)
    end
end

-- ============================================================
-- Авто выбор активного оружия
-- ============================================================
local function find_item_by_def(def)
    if not def then return nil, nil, nil end
    -- Ищем в weapons
    for i, it in ipairs(CAT_WEAPONS) do
        if it.def == def then return it, 0, i end
    end
    -- Ищем в knives
    for i, it in ipairs(CAT_KNIVES) do
        if it.def == def then return it, 1, i end
    end
    -- Ищем в gloves
    for i, it in ipairs(CAT_GLOVES) do
        if it.def == def then return it, 2, i end
    end
    return nil, nil, nil
end

-- ============================================================
-- Отслеживание изменений
-- ============================================================
local last_cat         = -1
local last_item_idx    = -1
local last_active      = -1
local last_show_legacy = nil
local last_custom_model = false
local last_always_agents = nil
local last_rare_anim = nil
local last_team_combo = -1

local function select_saved_team_item()
    if not C or not (cur_cat == 1 or cur_cat == 2) then return false end
    local side = selected_ui_side()
    local def = nil
    if cur_cat == 1 and C.knifeDef then
        def = C.knifeDef(side)
    elseif cur_cat == 2 and C.gloveDef then
        def = C.gloveDef(side)
    end
    if not def then return false end

    local list = get_cat_list()
    for i, it in ipairs(list) do
        if it.def == def then
            item_combo:SetValue(i - 1)
            last_item_idx = i - 1
            cur_item = it
            return true
        end
    end
    return false
end

-- ============================================================
-- Draw callback
-- ============================================================
callbacks.Register("Draw", "SkinChangerUI", function()

    -- Попытка подгрузить API
    if not C then
        if _G["AWCHANGER_API"] then
            C = _G["AWCHANGER_API"]
            build_lists()
            if C.getOpt and C.getOpt("show_legacy") ~= nil then
                show_legacy_cb:SetValue(C.getOpt("show_legacy") and true or false)
            end
            if C.getOpt then
                local saved_rare_anim = C.getOpt("rare_animations")
                if saved_rare_anim == nil then saved_rare_anim = C.getOpt("rare_anim") end
                if saved_rare_anim ~= nil then
                    rare_anim_cb:SetValue(saved_rare_anim and true or false)
                end
            end
            update_item_combo()
        end
        return
    end

    -- Show/hide legacy skins toggle
    local show_legacy_now = show_legacy_cb:GetValue()
    if show_legacy_now ~= last_show_legacy then
        last_show_legacy = show_legacy_now
        if C.setOpt then C.setOpt("show_legacy", show_legacy_now) end
        update_skin_listbox()
    end

    -- Custom models toggle + сохранение + обновление списка
    local custom_now = custom_model_cb:GetValue()
    if C and C.setOpt then
        C.setOpt("custom_model", custom_now)
    end
    if custom_now ~= last_custom_model then
        last_custom_model = custom_now
        if cur_cat == 3 then
            update_skin_listbox()
        end
    end

    -- Always all agents toggle + обновление списка
    local always_agents_now = always_agents_cb:GetValue()
    if always_agents_now ~= last_always_agents then
        last_always_agents = always_agents_now
        if cur_cat == 3 and not custom_now then
            update_skin_listbox()
        end
    end

    -- Rare knife animations toggle: сохраняем опцию в конфиг скинченджера.
    -- Если в сборке подключен sequence/animation hook, он может читать
    -- C.rareAnimations() / C.getOpt("rare_animations").
    local rare_anim_now = rare_anim_cb:GetValue()
    if rare_anim_now ~= last_rare_anim then
        last_rare_anim = rare_anim_now
        if C.setRareAnimations then
            C.setRareAnimations(rare_anim_now)
        elseif C.setOpt then
            C.setOpt("rare_animations", rare_anim_now)
            C.setOpt("rare_anim", rare_anim_now)
        end
    end



    -- Проверка смены команды: накатываем агента для этой команды
    local new_team = 0
    local lp2 = entities.GetLocalPlayer()
    if lp2 then pcall(function() new_team = lp2:GetFieldInt("m_iTeamNum") end) end
    if new_team ~= last_team then
        last_team = new_team
        -- Достаём агента для этой команды из opts
        local side = (new_team == 2) and "t" or (new_team == 3) and "ct" or nil
        if side then

            local saved = C and C.getOpt and C.getOpt("agent_" .. side)
            if saved and saved ~= "" then
                saved_agent_path = saved
                if C then
                    C.setLocalModel(saved)
                    C.forceRefresh(16)
                end
            else
                saved_agent_path = ""
                if C then C.setLocalModel(nil); C.forceRefresh(16) end
            end
        end
        if cur_cat == 3 then
            update_skin_listbox()
        elseif team_combo:GetValue() == 0 and (cur_cat == 1 or cur_cat == 2) then
            select_saved_team_item()
            update_skin_listbox()
        end
    end

    -- Авто выбор активного оружия (только для Weapons)
	if auto_select_cb:GetValue() and cur_cat == 0 then
        local active_def = C.activeDef()
        if active_def and active_def ~= last_active then
            last_active = active_def
            -- Ищем ТОЛЬКО в Weapons, не переключаем на ножи/перчатки
            local found_item, found_idx = nil, nil
            for i, it in ipairs(CAT_WEAPONS) do
                if it.def == active_def then
                    found_item = it
                    found_idx = i
                    break
                end
            end
            if found_item and found_idx then
                item_combo:SetValue(found_idx - 1)
                last_item_idx = found_idx - 1
                cur_item = found_item
                update_skin_listbox()
            end
        end
    else
        last_active = -1
    end

    -- Смена категории вручную
    local new_cat = cat_combo:GetValue()
    if new_cat ~= last_cat then
        last_cat      = new_cat
        cur_cat       = new_cat
        last_item_idx = -1
        cur_item      = nil
        update_item_combo()
        select_saved_team_item()
        update_skin_listbox()
    end

    -- Смена Team selector для ножей/перчаток
    local new_team_combo = team_combo:GetValue()
    if new_team_combo ~= last_team_combo then
        last_team_combo = new_team_combo
        if cur_cat == 1 or cur_cat == 2 then
            select_saved_team_item()
            update_skin_listbox()
        end
    end

    -- Прячем item_combo, auto_select, show_legacy при категории Agents
    -- Показываем custom_model только при Agents
    if cur_cat == 3 then
        item_combo:SetInvisible(true)
        team_combo:SetInvisible(true)
        auto_select_cb:SetInvisible(true)
        show_legacy_cb:SetInvisible(true)
        custom_model_cb:SetInvisible(false)
        always_agents_cb:SetInvisible(custom_model_cb:GetValue())
        rare_anim_cb:SetInvisible(true)
        skin_wear:SetInvisible(true)
        skin_seed:SetInvisible(true)

    else
        item_combo:SetInvisible(false)
        team_combo:SetInvisible(not (cur_cat == 1 or cur_cat == 2))
        auto_select_cb:SetInvisible(cur_cat ~= 0)
        show_legacy_cb:SetInvisible(false)
        custom_model_cb:SetInvisible(true)
        always_agents_cb:SetInvisible(true)
        rare_anim_cb:SetInvisible(cur_cat ~= 1)
        skin_wear:SetInvisible(false)
        skin_seed:SetInvisible(false)


    end

    -- Смена предмета вручную
    local new_item_idx = item_combo:GetValue()
    if new_item_idx ~= last_item_idx then
        last_item_idx = new_item_idx
        local list = get_cat_list()
        cur_item = list[new_item_idx + 1]
        update_skin_listbox()
    end

    -- Автоприменение: при смене скина/агента в листбоксе сразу apply
    local new_skin_idx = skin_listbox:GetValue()
    if new_skin_idx ~= last_skin_idx then
        last_skin_idx = new_skin_idx
        if (cur_item or cur_cat == 3) and C and new_skin_idx >= 0 then
            do_apply()
            if C.forceRefresh then C.forceRefresh(16) end
        end
    end

    -- Remove
    if flag_remove then
        flag_remove = false
        if cur_cat == 3 then
            if C.setLocalModel then C.setLocalModel(nil) end
            if C.forceRefresh then C.forceRefresh(16) end
            skin_listbox:SetValue(0)
            last_skin_idx = 0
        elseif cur_item then
            C.remove(cur_item, selected_ui_side())
            skin_listbox:SetValue(0)
            last_skin_idx = 0
            skin_wear:SetValue(0.01)
            skin_seed:SetValue(0)
        end
    end

    -- Force Refresh
    if flag_refresh then
        flag_refresh = false
        if cur_cat == 3 and C.refreshModels then
            C.refreshModels()
            build_lists()
            update_item_combo()
            update_skin_listbox()
        end
        do_force_refresh()
    end

end)
-- ============================================================
-- Unload: чистим всё при выгрузке скрипта
-- ============================================================
callbacks.Register("Unload", "osnova_skin_unload", function()
    -- Снимаем VM hook
    local VM = rawget(_G, "VM")
    if VM and VM.uninstall then pcall(VM.uninstall) end
    _G.AWCHANGER_API = nil
end)
end
