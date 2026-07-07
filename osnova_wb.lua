-- OSNOVA Wallbang Helper
-- Separate module. For now it only enables the WALLBANG tab inside Grenade Helper.

_G.WB = _G.WB or {}
local WB = _G.WB
WB.loaded = true
WB.version = "0.1-tab"

_G.OSNOVA_WALLBANG_ENABLED = true
if _G.__OSNOVA then
    _G.__OSNOVA.wb_on = true
end

function WB.uninstall()
    WB.loaded = false
    _G.OSNOVA_WALLBANG_ENABLED = false
    if _G.__OSNOVA then
        _G.__OSNOVA.wb_on = false
    end
    _G.WB = nil
end

callbacks.Register("Unload", "osnova_wb_unload", function()
    if WB and WB.uninstall then
        pcall(WB.uninstall)
    end
end)
