-- osnova_signatures.lua
-- Централизованная база ПАТТЕРНОВ/СИГНАТУР (эта Lua) для всех остальных
-- скриптов (osnova_aa.lua, osnova_skin.lua, no_visual_duck.lua и т.д.).
--
-- Разделение ответственности:
--   * ОФФСЕТЫ NETVAR-ПОЛЕЙ (m_flDuckAmount, m_iHealth, dwEntityList и т.п.)
--     по-прежнему тянутся динамически с a2x/cs2-dumper (http.Get(...client_dll.json))
--     как это уже сделано в osnova_aa.lua/osnova_skin.lua - они обновляются
--     дампером при каждом патче игры и не должны хардкодиться тут.
--   * БАЙТОВЫЕ ПАТТЕРНЫ ФУНКЦИЙ (mem.FindPattern) берутся ИЗ ЭТОГО файла -
--     это то, что не публикует cs2-dumper (он даёт только netvar-оффсеты,
--     не паттерны для сигнатурного поиска функций/хуков).
--
-- Сгенерировано из пользовательского дампа сигнатур (298 записей: 241 raw, 23 rel32, 34 riprel).
--
-- kind:
--   raw    - паттерн указывает прямо на начало функции
--   rel32  - паттерн указывает на E8-call, адрес функции нужно разрешить
--            через rel32 (адрес_call + 5 + rel32_значение)
--   riprel - паттерн указывает на инструкцию с RIP-relative адресацией к
--            ГЛОБАЛЬНОЙ ПЕРЕМЕННОЙ/УКАЗАТЕЛЮ (не функции), напр. pGameEntitySystem,
--            pViewMatrix, pWeaponC4 - разрешается так же через rel32, но результат
--            это адрес переменной, а не код
--
-- Использование из другого скрипта (пример):
--   local SIG = loadstring(http.Get("<raw-url-до-этого-файла>"))()
--   local addr = SIG.resolve_raw("OverrideView")           -- kind=raw, адрес сразу
--   local addr2 = SIG.resolve_rel32("SomeName", 1)          -- kind=rel32, offset call'а
--   -- offsets (netvar) отдельно - см. пример fetch_dumper_offsets() ниже

local SIG = {}

SIG.DB = {
	["AddNametagEntity"] = { module = "client.dll", rva = 0x78CBD0, pattern = "40 55 53 56 48 8D AC 24 ? ? ? ? 48 81 EC ? ? ? ? 48 8B DA", kind = "raw" },
	["AddStattrakEntity"] = { module = "client.dll", rva = 0xA4F570, pattern = "48 8B C4 48 89 58 08 48 89 70 10 57 48 83 EC 50 33 F6 8B FA 48 8B D1", kind = "raw" },
	["AnimGraphRebuild"] = { module = "client.dll", rva = 0x8B1630, pattern = "40 55 56 48 83 EC 28 4C 89 74 24 58 48 8B F1 80 FA FF 75 04 0F B6 51 18", kind = "raw" },
	["ApplyEconCustomization"] = { module = "client.dll", rva = 0x7AA6D0, pattern = "48 89 5C 24 ? 57 48 83 EC ? 8B FA 48 8B D9 E8 ? ? ? ? 48 8B CB E8 ? ? ? ? 48 85 C0 74", kind = "raw" },
	["AutowallInit"] = { module = "client.dll", rva = 0x8E47F0, pattern = "40 53 48 83 EC ? 48 8B D9 48 81 C1 ? ? ? ? E8 ? ? ? ?", kind = "raw" },
	["AutowallTraceData"] = { module = "client.dll", rva = 0x9912D0, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 57 48 83 EC ? 48 8B 09", kind = "raw" },
	["AutowallTracePos"] = { module = "client.dll", rva = 0x80A330, pattern = "40 55 56 41 54 41 55 41 57 48 8B EC", kind = "raw" },
	["BulkRegenIterator"] = { module = "client.dll", rva = 0x7900E1, pattern = "57 48 83 EC 40 0F B6 F9 E8 ? ? ? ? 48 85 C0 0F 84", kind = "raw" },
	["C_BaseEntity_ProcessInterpolatedList"] = { module = "client.dll", rva = 0xA6EBB0, pattern = "4C 8B DC 49 89 5B 10 49 89 6B 18 49 89 73 20 57 41 54 41 57 48 83 EC 60 49 C7 43 B0 E1 07 00 00", kind = "raw" },
	["C_BaseEntity_RestoreData"] = { module = "client.dll", rva = 0xA743F0, pattern = "40 55 53 56 41 54 41 57 48 8D AC 24 20 FF FF FF 48 81 EC E0 01 00 00 48 8B D9 45 8B E1 48 8B 89", kind = "raw" },
	["C_BaseEntity_SaveData"] = { module = "client.dll", rva = 0xA74600, pattern = "48 8B C4 55 56 57 41 56 41 57 48 8D A8 E8 FD FF FF 48 81 EC F0 02 00 00 48 83 B9 A0 05 00 00 00", kind = "raw" },
	["C_BaseEntity_StartParticleSystem"] = { module = "client.dll", rva = 0xDA8EA0, pattern = "48 89 5C 24 08 55 48 8B EC 48 83 EC 40 E8 ? ? ? ? 48 8D 05 ? ? ? ? 33 DB 48 8D 15", kind = "raw" },
	["C_CSWeaponBase_GetEconWpnData"] = { module = "client.dll", rva = 0x796D50, pattern = "40 53 48 83 EC 40 48 8B D9 E8 ? ? ? ? 48 8B C8 E8 ? ? ? ? 48 85 C0 75 ? 48 8B 43 10", kind = "raw" },
	["C_EconEntity_BuildModernWeaponSkinMaterial"] = { module = "client.dll", rva = 0xD8AA10, pattern = "48 85 C9 0F 84 ? ? 00 00 48 8B C4 48 89 50 10 48 89 48 08 55 41 54 41 56 41 57 48 8D A8 B8 FA", kind = "raw" },
	["CacheParticleEffect"] = { module = "client.dll", rva = 0x208110, pattern = "4C 8B DC 53 48 81 EC ? ? ? ? F2 0F 10 05", kind = "raw" },
	["CalcSpread"] = { module = "client.dll", rva = 0xC826B0, pattern = "48 8B C4 48 89 58 ? 48 89 68 ? 48 89 70 ? 57 41 54 41 55 41 56 41 57 48 81 EC ? ? ? ? 4C 63 EA", kind = "raw" },
	["CalculateInterpolation"] = { module = "client.dll", rva = 0x14DAB30, pattern = "E8 ? ? ? ? 8B 45 ? 3B 45 60 75 04 32 D2 EB 09 BA 01 00 00 00 41 0F 4C D5 C0 EA 07 84 D2 0F 85 87", kind = "rel32" },
	["CalculateWorldSpaceBones"] = { module = "client.dll", rva = 0xA0DEF0, pattern = "48 89 4C 24 ? 55 53 56 57 41 54 41 55 41 56 41 57 B8 ? ? ? ? E8 ? ? ? ? 48 2B E0 48 8D 6C 24 ? 48 8B 81", kind = "raw" },
	["CalcViewmodel"] = { module = "client.dll", rva = 0x851940, pattern = "40 55 53 56 41 56 41 57 48 8B EC", kind = "raw" },
	["CalcViewmodelTransform_v2"] = { module = "client.dll", rva = 0x7A4130, pattern = "48 89 5C 24 20 55 56 57 41 54 41 55 41 56 41 57 48 8D 6C 24 80 48 81 EC 80 01 00 00 48 8B FA", kind = "raw" },
	["CalcViewmodelView"] = { module = "client.dll", rva = 0xC6F9E0, pattern = "40 53 48 83 EC 60 48 8B 41 08 49 8B D8 8B 48 30 48 C1 E9 0C F6 C1 01 0F 85 48 01 00 00 41 B8 07", kind = "raw" },
	["ThinkReturn"] = { module = "client.dll", rva = 0x31AA4F, pattern = "BA 04 00 00 00 FF 15 ? ? ? ? 84 C0 0F 84", kind = "raw" },
	["CAttributeStringFill"] = { module = "client.dll", rva = 0xEB5560, pattern = "E8 ? ? ? ? 41 83 CF 08", kind = "rel32" },
	["CAttributeStringInit"] = { module = "client.dll", rva = 0x5F8BB0, pattern = "E8 ? ? ? ? 48 8D 05 ? ? ? ? 48 89 7D ? 48 89 45 ? 49 8D 4F", kind = "rel32" },
	["ChangeModel"] = { module = "client.dll", rva = 0x8DDAD0, pattern = "40 53 48 83 EC ? 48 8B D9 4C 8B C2 48 8B 0D ? ? ? ? 48 8D 54 24", kind = "raw" },
	["TakeDamageOld"] = { module = "client.dll", rva = 0x224270, pattern = "40 55 53 56 57 41 54 48 8D 6C 24 E0 48 81 EC 20 01 00 00 4D 8B E0 48 8B FA 48 8B F1 E8", kind = "raw" },
	["SetBodygroup"] = { module = "client.dll", rva = 0x8DC780, pattern = "85 D2 0F 88 CB 01 00 00 55 53 56 41 56 48 8B EC 48 83 EC 78 45 8B F0 8B DA 48 8B F1 E8 ? ? ?", kind = "raw" },
	["SetBodyGroup"] = { module = "client.dll", rva = 0x8DC780, pattern = "85 D2 0F 88 ? ? ? ? 55 53 56 41 56 48 8B EC 48 83 EC 78", kind = "raw" },
	["CBufferStringInit"] = { module = "client.dll", rva = 0x17F4C60, pattern = "48 89 5C 24 ? 57 48 83 EC ? 8B 41 ? 48 8D 79", kind = "raw" },
	["HudChat_OnSayText2"] = { module = "client.dll", rva = 0x10D6240, pattern = "48 89 5C 24 08 55 56 57 41 54 41 55 41 56 41 57 48 8D AC 24 70 F3 FF FF 48 81 EC 90 0D 00 00 81 A5 DC 0C 00 00 FF FF 0F FF 33 F6 8B 5A 6C 48 8B", kind = "raw" },
	["OnVoteResult"] = { module = "client.dll", rva = 0xE19860, pattern = "48 89 5C 24 08 48 89 6C 24 10 48 89 74 24 18 57 41 56 41 57 48 81 EC 90 01 00 00 65 48 8B 04 25 58 00 00 00 49 8B E8 44 8B 15 ? ? ? ? 8B FA", kind = "raw" },
	["EquipItemInLoadout"] = { module = "client.dll", rva = 0x7C3EA0, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 89 54 24 ? 57 41 54 41 55 41 56 41 57 48 83 EC ? 0F B7 FA", kind = "raw" },
	["MovementServices_CheckJumpButton"] = { module = "client.dll", rva = 0xAD2290, pattern = "4C 89 44 24 18 55 56 41 56 48 8D AC 24 70 EC FF FF B8 90 14 00 00", kind = "raw" },
	["ProcessForceSubtickMoves"] = { module = "client.dll", rva = 0x9D8D80, pattern = "40 55 53 48 8D AC 24 68 FF FF FF 48 81 EC 98 01 00 00 8B 15 ? ? ? ? 48 8B D9 65 48 8B 04 25 58 00 00 00 B9 98 00 00 00 48 8B 04 D0 8B 04 01 39 05 ? ? ? ? 0F 8F B6 07 00 00", kind = "raw" },
	["QueueForceSubtickMove"] = { module = "client.dll", rva = 0x9CA720, pattern = "48 83 EC 28 8B 0D ? ? ? ? 65 48 8B 04 25 58 00 00 00 BA 98 00 00 00 48 8B 04 C8 8B 04 02 39 05 ? ? ? ? 0F 8F F4 11 00 00", kind = "raw" },
	["RunCommand_Context"] = { module = "client.dll", rva = 0x9DE980, pattern = "48 8B C4 48 81 EC C8 00 00 00 48 89 58 10 48 89 68 18 48 8B EA 48 89 70 20 48 8B F1 48 89 78 F8", kind = "raw" },
	["ThirdPersonReset"] = { module = "client.dll", rva = 0xACB5E0, pattern = "48 8B 40 08 44 38 ? 75 10 44 88 ? 01", kind = "raw" },
	["GetItemInLoadout"] = { module = "client.dll", rva = 0x7C5AC0, pattern = "40 55 48 83 EC ? 49 63 E8", kind = "raw" },
	["GetInaccuracy"] = { module = "client.dll", rva = 0x797760, pattern = "48 89 5C 24 ? 55 56 57 48 81 EC ? ? ? ? 44", kind = "raw" },
	["NoSpread1"] = { module = "client.dll", rva = 0xC81D90, pattern = "48 89 5C 24 08 57 48 81 EC F0 00", kind = "raw" },
	["CEconItemCreateInstance"] = { module = "client.dll", rva = 0x1008D90, pattern = "48 83 EC 28 B9 48 00 00 00 E8", kind = "raw" },
	["GetAttributeDefinitionByName"] = { module = "client.dll", rva = 0x105F0E0, pattern = "48 89 5C 24 10 48 89 6C 24 18 57 41 56 41 57 48 83 EC 60 48 8D 05", kind = "raw" },
	["GetCustomPaintKitIndex"] = { module = "client.dll", rva = 0x10BB560, pattern = "48 89 5C 24 ? 57 48 83 EC ? 8B 15 ? ? ? ? 48 8B F9 65 48 8B 04 25 ? ? ? ? B9 ? ? ? ? 48 8B 04 D0 8B 04 01 39 05 ? ? ? ? 0F 8F ? ? ? ? E8 ? ? ? ? 8B 58 ? 39 1D ? ? ? ? 74 ? E8 ? ? ? ? 48 8B 15 ? ? ? ? 48 8B C8 E8 ? ? ? ? 48 89 05 ? ? ? ? 89 1D ? ? ? ? EB ? 48 8B 05 ? ? ? ? 48 85 C0 74", kind = "raw" },
	["QueuePostDataUpdates"] = { module = "client.dll", rva = 0x14C0B20, pattern = "48 89 5C 24 08 48 89 74 24 10 57 48 83 EC 40 80 B9 DA 0B 00 00 00 49 8B D8 8B FA 48 8B F1 74 61", kind = "raw" },
	["BuildBoneMergeWork"] = { module = "client.dll", rva = 0x942320, pattern = "40 55 56 57 41 54 41 55 41 56 41 57 48 83 EC 50 48 8D 6C 24 50 80 A1 06 01 00 00 FB 4C 8B F9 80", kind = "raw" },
	["PerformBatchedInvalidatePhysicsRecursive"] = { module = "client.dll", rva = 0x940F40, pattern = "40 57 48 81 EC 90 00 00 00 84 C9 74 4D BF 01 00 00 00 F0 0F C1 3D ? ? ? ? FF C7 83 FF 01 0F 85 63 05 00 00 48 8D 0D ? ? ? ? 48 8D 15", kind = "raw" },
	["StartHierarchicalAttachment"] = { module = "client.dll", rva = 0x98EEF0, pattern = "48 89 5C 24 10 48 89 6C 24 18 48 89 74 24 20 57 41 54 41 55 41 56 41 57 48 83 EC 30 48 8B F9 8B", kind = "raw" },
	["TraceShape_Client"] = { module = "client.dll", rva = 0x9913B0, pattern = "48 89 5C 24 20 48 89 4C 24 08 55 57 41 54 41 55 41 56 48 8D AC 24 10 E0 FF FF B8 F0 20 00 00", kind = "raw" },
	["OnGlowTypeChanged"] = { module = "client.dll", rva = 0xB103C0, pattern = "48 89 5C 24 08 48 89 74 24 10 57 48 83 EC 20 48 8B 05 ? ? ? ? 48 8B D9 F3 0F 10 41 4C", kind = "raw" },
	["CInputPtrGlobal"] = { module = "client.dll", rva = 0x2079860, pattern = "4C 8B 05 ? ? ? ? 41 8B 80 50 0B 00 00 85 C0", kind = "riprel" },
	["ClearHUDWeaponIcon"] = { module = "client.dll", rva = 0xDF3910, pattern = "E8 ? ? ? ? 8B F8 C6 84 24 ? ? ? ? ?", kind = "rel32" },
	["Client_DispatchSpawn"] = { module = "client.dll", rva = 0x14E87D0, pattern = "4C 8B DC 55 56 48 83 EC 78 49 8B 68 08 48 8B F1 48 85 ED 0F 84 72 01 00 00 49 89 5B 08 49 8D 4B", kind = "raw" },
	["ClientModeCSNormal_OnEvent"] = { module = "client.dll", rva = 0xC60050, pattern = "40 53 57 48 81 EC 78 02 00 00 48 8B CA 48 8B FA", kind = "raw" },
	["OnPostDataUpdate"] = { module = "client.dll", rva = 0x9AE960, pattern = "48 89 5C 24 08 48 89 74 24 18 55 57 41 56 48 8B EC 48 83 EC 50 45 8B F1 48 8B FA 48 8B F1 45 85", kind = "raw" },
	["ComputeRandomSeed"] = { module = "client.dll", rva = 0xC81D90, pattern = "48 89 5C 24 ? 57 48 81 EC ? ? ? ? ? ? ? ? 48 8D 8C 24", kind = "raw" },
	["ConCommand_firstperson"] = { module = "client.dll", rva = 0xACD130, pattern = "48 83 EC 28 48 8B 0D ? ? ? ? 48 8D 54 24 ? 48 8B 01 FF 90 08 03 00 00 83 7C 24 ? 00 75 ? 48 8B 05 ? ? ? ? C6 80 29 02 00 00 00 C7 80 A8 06 00 00 00", kind = "raw" },
	["ConCommand_thirdperson"] = { module = "client.dll", rva = 0xACD210, pattern = "48 83 EC 38 48 8B 0D ? ? ? ? 48 8D 54 24 ? 48 8B 01 FF 90 08 03 00 00 83 7C 24 ? 00 0F 85 ? ? ? ? 4C 8B 05 ? ? ? ? 41 8B 80 50 0B 00 00", kind = "raw" },
	["ConvarGet"] = { module = "client.dll", rva = 0x8C1FF2, pattern = "8B D0 48 8D 0D ? ? ? ? E8 ? ? ? ? 0F 10 45 ? 83 F0 74", kind = "raw" },
	["Constructor"] = { module = "client.dll", rva = 0xE24EF0, pattern = "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC 30 48 8B F1 48 8B FA B9 ? ? ? ? E8 ? ? ? ? 48 8B D8 48 85 C0 74", kind = "raw" },
	["StartDefuse"] = { module = "client.dll", rva = 0x7B22D0, pattern = "40 55 53 56 48 8D AC 24 C0 FE FF FF 48 81 EC 40 02 00 00 48 8B DA 48 8B F1 BA FF FF FF FF", kind = "raw" },
	["Update"] = { module = "client.dll", rva = 0xB514D0, pattern = "48 8B C4 89 50 ? 48 89 48 ? 55 53 57", kind = "raw" },
	["CreateBaseTypeCache"] = { module = "client.dll", rva = 0x1523B60, pattern = "40 53 48 83 EC ? 4C 8B 49 ? 44 8B D2", kind = "raw" },
	["CreateEconItem"] = { module = "client.dll", rva = 0x1008D90, pattern = "48 83 EC 28 B9 48 00 00 00 E8 ? ? ? ? 48 85", kind = "raw" },
	["CreateEntityByClassName"] = { module = "client.dll", rva = 0x1616E86, pattern = "4C 8D 05 ? ? ? ? 4C 8B CF BA 03 00 00 00 FF 15 ? ? ? ? EB ? 0F B7 C8 48", kind = "raw" },
	["CreateInterface"] = { module = "client.dll", rva = 0x1847A20, pattern = "4C 8B 0D ? ? ? ? 4C 8B D2 4C 8B D9 4D 85 C9 74 ? 49 8B 41 08", kind = "raw" },
	["CreateMove"] = { module = "client.dll", rva = 0xC621E0, pattern = "48 8B C4 4C 89 40 18 48 89 48 08 55 53 41 54 41 55", kind = "raw" },
	["CreateNewSubtickMoveStep"] = { module = "client.dll", rva = 0x4B22D0, pattern = "E8 ? ? ? ? 48 8B D0 48 8B CE E8 ? ? ? ? 48 8B C8", kind = "rel32" },
	["CreateParticleEffect"] = { module = "client.dll", rva = 0x989930, pattern = "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? F3 0F 10 1D ? ? ? ? 41 8B F8 8B DA 4C 8D 05", kind = "raw" },
	["CreateSOSubclassEconItem"] = { module = "client.dll", rva = 0x1008D90, pattern = "48 83 EC 28 B9 48 00 00 00 E8 ? ? ? ? 48 85", kind = "raw" },
	["CreateSubtickMoveStep"] = { module = "client.dll", rva = 0x4B22D0, pattern = "E8 ? ? ? ? 48 8B D0 49 8D 4E ? E8 ? ? ? ? 4C 8B C8 4C 8D 43 ? 49 8B D1 48 8B CE E8 ? ? ? ? 48 8B D8 48 85 C0 0F 84 ? ? ? ? 48 3B 06 0F 83 ? ? ? ? 0F B7 00 66 C7 45 ? ? ? 66 3B 45 ? 74 ? E9 ? ? ? ? 40 80 FF ? 0F 85 ? ? ? ? 41 83 4E", kind = "rel32" },
	["CreateTrace"] = { module = "client.dll", rva = 0x8074D0, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 57 41 56 41 57 48 83 EC ? ? ? ? ? 4D 8D 71", kind = "raw" },
	["BuildTemplateMaterialFromFile"] = { module = "client.dll", rva = 0x13CF710, pattern = "48 89 54 24 10 55 53 41 55 41 57 48 8D AC 24 18 F9 FF FF 48 81 EC E8 07 00 00 4C 8B FA 48 85 D2", kind = "raw" },
	["CSBaseGunFireData"] = { module = "client.dll", rva = 0x14FAE00, pattern = "48 8B C4 55 53 56 57 41 54 41 55 41 56 41 57 48 8D 68 A8 48 81 EC ? ? ? ? 4C 8B 69", kind = "raw" },
	["GetTransformsForHitboxList"] = { module = "client.dll", rva = 0xA1D490, pattern = "48 89 5C 24 18 55 56 57 41 55 41 57 48 81 EC A0 00 00 00 49 63 28 4D 8B F8 48 8B FA 48 8B D9 85", kind = "raw" },
	["OnBodyGroupChoiceChanged"] = { module = "client.dll", rva = 0xA280E0, pattern = "48 89 5C 24 08 57 48 83 EC 20 49 63 D8 49 8B F9 45 85 C0 78 20 3B 99 18 02 00 00 7D 18", kind = "raw" },
	["OnSkeletonModelChanged"] = { module = "client.dll", rva = 0xA282F0, pattern = "49 8B 00 48 89 81 B8 00 00 00 C6 81 B0 00 00 00 01 C3", kind = "raw" },
	["PostDataUpdate"] = { module = "client.dll", rva = 0xA29280, pattern = "48 8B C4 4C 89 40 18 89 50 10 55 57 48 8D A8 68 FE FF FF 48 81 EC 88 02 00 00 48 89 70 E0 48 8B", kind = "raw" },
	["SetMaterialGroup"] = { module = "client.dll", rva = 0xA2F600, pattern = "3B 91 C4 03 00 00 74 24 89 91 C4 03 00 00 48 8B 81 28 02 00 00 48 85 C0 74 12", kind = "raw" },
	["SetMeshGroupMask"] = { module = "client.dll", rva = 0xA30920, pattern = "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? 48 8D 99", kind = "raw" },
	["SetMeshGroupMask"] = { module = "client.dll", rva = 0xA28250, pattern = "48 89 5C 24 08 48 89 74 24 10 57 48 83 EC 20 49 8B 00 49 8B F8 48 8B F2 48 8B D9 48 39 81 C8 01", kind = "raw" },
	["Shutdown"] = { module = "client.dll", rva = 0xAE8C60, pattern = "48 89 5C 24 08 55 56 57 41 54 41 55 41 56 41 57 48 81 EC 40 02 00 00 8B 0D ? ? ? ? BA 02 00 00", kind = "raw" },
	["ParseSubtickDuration"] = { module = "client.dll", rva = 0xAD4D0, pattern = "40 55 48 8D AC 24 70 FD FF FF 48 81 EC 90 03 00 00 F2 0F 10 05 ? ? ? ? 48 8D 05", kind = "raw" },
	["ParseSubtickFraction"] = { module = "client.dll", rva = 0xAD810, pattern = "40 55 48 8D AC 24 40 FE FF FF 48 81 EC C0 02 00 00 F2 0F 10 05 ? ? ? ? 48 8D 05", kind = "raw" },
	["CompositeMaterialInput_AddToTail"] = { module = "client.dll", rva = 0x78B802, pattern = "41 B9 88 02 00 00 8B 57 14 81 E2 FF FF FF 3F 8D 71 01 44 8B C6 FF 15", kind = "raw" },
	["DamageFeedbackEmitter"] = { module = "client.dll", rva = 0x822540, pattern = "48 89 4C 24 08 55 53 41 54 41 55 41 57 48 8D AC 24 E0 FE FF FF 48 81 EC 20 02 00 00 48 83 79 38", kind = "raw" },
	["DestroyParticle"] = { module = "client.dll", rva = 0x948CC0, pattern = "83 FA ? 0F 84 ? ? ? ? 41 54", kind = "raw" },
	["DispatchEffect"] = { module = "client.dll", rva = 0x35AAC0, pattern = "48 89 5C 24 ? 57 48 83 EC ? 48 8B F9 48 8B DA 48 8D 4C 24", kind = "raw" },
	["DispatchSpawn_caller"] = { module = "client.dll", rva = 0x14E87D0, pattern = "4C 8B DC 55 56 48 83 EC 78 49 8B 68 08 48 8B F1 48 85 ED 0F 84 72 01 00 00", kind = "raw" },
	["DispatchUpdateOnRemove"] = { module = "client.dll", rva = 0x14E6270, pattern = "48 89 5C 24 10 48 89 74 24 18 48 89 7C 24 20 55 41 56 41 57 48 8B EC 48 83 EC 60 48 8D B9 80 00 00 00 45 33 FF 4D 8B F0", kind = "raw" },
	["DrawCrosshair"] = { module = "client.dll", rva = 0x7B2940, pattern = "48 89 5C 24 08 57 48 83 EC 20 48 8B D9 E8 ? ? ? ? 48 85", kind = "raw" },
	["DrawLegs"] = { module = "client.dll", rva = 0x1102F00, pattern = "40 55 53 56 41 56 41 57 48 8D AC 24 ? ? ? ? 48 81 EC ? ? ? ? F2 0F 10 42", kind = "raw" },
	["DrawOverHead"] = { module = "client.dll", rva = 0xA69AD0, pattern = "40 53 48 83 EC ? 48 8B D9 83 FA ? 75 ? 48 8B 0D ? ? ? ? 48 8D 54 24 ? 48 8B 01 FF 90 ? ? ? ? 8B 10", kind = "raw" },
	["DrawScopeOverlay"] = { module = "client.dll", rva = 0x85F950, pattern = "48 8B C4 53 57 48 83 EC ? 48 8B FA", kind = "raw" },
	["DrawSmokeArray"] = { module = "client.dll", rva = 0xC7EE40, pattern = "40 55 41 54 41 55 48 8D AC 24 ? ? ? ? 48 81 EC ? ? ? ? 4C 8B E2", kind = "raw" },
	["DrawSmokeVertex"] = { module = "client.dll", rva = 0xC7ED50, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 57 41 56 41 57 48 83 EC ? 48 8B 9C 24 ? ? ? ? 4D 8B F8", kind = "raw" },
	["DrawTeamIntro"] = { module = "client.dll", rva = 0x705140, pattern = "48 83 EC ? ? ? ? ? 44 38 89", kind = "raw" },
	["DrawViewPunch2"] = { module = "client.dll", rva = 0x806D90, pattern = "48 89 5C 24 08 48 89 6C 24 10 48 89 74 24 18 48 89 7C 24 20 41 56 48 83 EC 40 49 8B E9 49 8B F8", kind = "raw" },
	["EmitPanoramaSound"] = { module = "client.dll", rva = 0xB676E0, pattern = "40 53 48 81 EC ? ? ? ? ? ? ? 48 8B 05", kind = "raw" },
	["EmitSoundByHandle"] = { module = "client.dll", rva = 0xB67470, pattern = "40 53 48 83 EC 30 4C 89 4C 24 20 48 8B D9 45 8B C8 4C 8B C2 48 8B D1 48 8D 0D ?? ?? ?? ?? E8", kind = "raw" },
	["FindHudElement"] = { module = "client.dll", rva = 0xDC79D8, pattern = "48 8D 15 ? ? ? ? 45 33 C0 B9 ? ? ? ? FF 15 ? ? ? ? EB ? 48 8B 15", kind = "raw" },
	["FindSOCache"] = { module = "client.dll", rva = 0x1831310, pattern = "48 89 5C 24 08 57 48 83 EC 30 4C 8B 52 08 48 8B D9 8B 0A", kind = "raw" },
	["FirstPersonLegs"] = { module = "client.dll", rva = 0x1102F00, pattern = "40 55 53 56 41 56 41 57 48 8D AC 24 ? ? ? ? 48 81 EC ? ? ? ? F2 0F 10 42", kind = "raw" },
	["FlashOverlay"] = { module = "client.dll", rva = 0x1104B90, pattern = "85 D2 0F 88 ? ? ? ? 48 89 4C 24 08 55 56", kind = "raw" },
	["ForceButtonsDown"] = { module = "client.dll", rva = 0x9D2F60, pattern = "40 53 57 41 56 48 81 EC ? ? ? ? 48 83 79", kind = "raw" },
	["FrameStageNotify"] = { module = "client.dll", rva = 0xAD5720, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 57 48 83 EC ? 48 8B F9 33 ED", kind = "raw" },
	["FX_FireBullets"] = { module = "client.dll", rva = 0xC81E40, pattern = "48 8B C4 4C 89 48 20 48 89 50 10 55 53 57 41 54 41 55 48 8D A8 58 FB FF FF 48 81 EC A0 05 00 00", kind = "raw" },
	["GameEventManager_AddListener"] = { module = "client.dll", rva = 0x93C8D0, pattern = "48 89 5C 24 10 48 89 6C 24 18 56 57 41 56 48 83 EC 50 41 0F B6 E9 48 8D 99 E0 00 00 00 49 8B F0", kind = "raw" },
	["GameEventManager_UnserializeEvent"] = { module = "client.dll", rva = 0x995760, pattern = "48 8B C4 48 89 50 10 55 41 54 41 55 41 56 48 8D 68 D8 48 81 EC 08 01 00 00 48 89 58 D8 4C 8D B1", kind = "raw" },
	["GameTraceLine"] = { module = "client.dll", rva = 0x708920, pattern = "4C 8B DC 49 89 5B 08 49 89 6B 10 49 89 73 18 57 41 56 41 57 48 81 EC B0 00 00 00 0F 57 C0 4C 8B F9 66 0F 7F 44 24 70", kind = "raw" },
	["GetAbsOrigin"] = { module = "client.dll", rva = 0x20DF60, pattern = "F8 ? 75 ? E8 ? ? ? ? F3", kind = "riprel" },
	["GetAttributeDefByName"] = { module = "client.dll", rva = 0x105F0E0, pattern = "48 89 5C 24 10 48 89 6C 24 18 57 41 56 41 57 48 83 EC 60 48 8D 05", kind = "raw" },
	["GetBaseEntity"] = { module = "client.dll", rva = 0x969F10, pattern = "4C 8D 49 ? 81 FA", kind = "raw" },
	["GetBombsiteACenter"] = { module = "client.dll", rva = 0x84FD70, pattern = "54 24 ? E8 ? ? ? ? EB 0A", kind = "riprel" },
	["GetBombsiteBCenter"] = { module = "client.dll", rva = 0x84FDD0, pattern = "EB 0A 48 8D 54 24 ? E8 ? ? ? ? F2", kind = "riprel" },
	["GetBonePositionByName"] = { module = "client.dll", rva = 0x8CAA40, pattern = "40 53 48 83 EC ? 48 8B 89 ? ? ? ? 48 8B DA 48 8B 01 FF 50 ? 48 8B C8", kind = "raw" },
	["GetChatObject"] = { module = "client.dll", rva = 0x10D6090, pattern = "E8 ? ? ? ? 48 8B E8 48 85 C0 0F 84 ? ? ? ? 4C 8D 05", kind = "rel32" },
	["GetClientSystem"] = { module = "client.dll", rva = 0x1048470, pattern = "E8 ? ? ? ? 48 8B C8 E8 ? ? ? ? 8B D8 85 C0 74 33", kind = "rel32" },
	["GetControllerCmd"] = { module = "client.dll", rva = 0x8C05F0, pattern = "40 53 48 83 EC 20 8B DA E8 ? ? ? ? 4C", kind = "raw" },
	["GetEconItemSystem"] = { module = "client.dll", rva = 0x10BCF60, pattern = "48 83 EC 28 48 8B 05 ? ? ? ? 48 85 C0 0F 85 ? ? ? ? 48 89 5C 24 ? B9 10 00 00 00 48 89 7C 24 ? E8 ? ? ? ? 33 FF 48 8B D8 48 85 C0 74 ? 48 8D 05 ? ? ? ? 48 89 7B ? B9 A0 09 00 00 48 89 03 E8 ? ? ? ? 48 85 C0 74 ? 48 8B C8 E8 ? ? ? ? 48 8B F8 48 8D 05 ? ? ? ? 48 89 7B ? 48 89 03 48 8B C7", kind = "raw" },
	["GetEntityByIndex"] = { module = "client.dll", rva = 0x969F10, pattern = "4C 8D 49 ? 81 FA", kind = "raw" },
	["GetEntityHandle"] = { module = "client.dll", rva = 0x9511C0, pattern = "48 85 C9 74 32 48 8B 49 10 48 85 C9 74 29 44 8B 41 10 BA", kind = "raw" },
	["GetGameModeName"] = { module = "client.dll", rva = 0xEDA560, pattern = "48 83 EC ? 48 8B 0D ? ? ? ? ? ? ? FF 90 ? ? ? ? 48 85 C0 74 ? 48 8B 0D ? ? ? ? ? ? ? 4C 8B 42", kind = "raw" },
	["GetGlowColor"] = { module = "client.dll", rva = 0xB0E1F0, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 57 48 83 EC ? 48 8B F2 48 8B F9 48 8B 54 24", kind = "raw" },
	["GetHitGroup"] = { module = "client.dll", rva = 0xA1AA10, pattern = "40 53 48 83 EC 20 48 83 79 10 00 48 8B D9 74 16 E8 ?? ?? ?? ?? 84 C0 75 0D 48 8B 43 10 8B 40 38", kind = "raw" },
	["GetInventoryManager"] = { module = "client.dll", rva = 0x7C8180, pattern = "E8 ? ? ? ? 48 8B D3 48 8B C8 4C 8B 00 41 FF 90 00 02", kind = "rel32" },
	["GetItemViewByID"] = { module = "client.dll", rva = 0x1061AC0, pattern = "48 89 54 24 ? 53 48 83 EC ? 48 8B D9 48 85 D2 75 ? 33 C0 48 83 C4 ? 5B C3 48 83 C1 38 48 8D", kind = "raw" },
	["GetLocalControllerById"] = { module = "client.dll", rva = 0x8E3980, pattern = "48 83 EC 28 83 F9 FF 75 ? 48 8B 0D ? ? ? ? 48 8D 54 24 ? 48 8B 01 FF 90 ? ? ? ? 8B 08 48 63 C1 4C 8D 05", kind = "raw" },
	["GetLocalPawn"] = { module = "client.dll", rva = 0x8E3980, pattern = "48 83 EC ? 83 F9 ? 75 ? 48 8B 0D ? ? ? ? 48 8D 54 24 ? ? ? ? FF 90 ? ? ? ? ? ? 48 63 C1 4C 8D 05", kind = "raw" },
	["GetMapName"] = { module = "client.dll", rva = 0xEE5290, pattern = "48 83 EC ? 48 8B 0D ? ? ? ? ? ? ? FF 90 ? ? ? ? 48 8B C8 48 83 C4", kind = "raw" },
	["GetMatrixForView"] = { module = "client.dll", rva = 0x16A1A0, pattern = "40 53 48 83 EC 60 0F 29 74 24 50 0F 57 DB F3 0F 10 ? ? ? ? ? 49 8B D8", kind = "raw" },
	["GetPlayerInterp"] = { module = "client.dll", rva = 0x8BBE50, pattern = "40 53 48 83 EC ? 48 8B D9 48 8B 0D ? ? ? ? 48 83 C1", kind = "raw" },
	["GetPlayerTeamName"] = { module = "client.dll", rva = 0xEEC110, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 57 48 83 EC ? 48 8B CA 48 8B EA", kind = "raw" },
	["GetRemovedAimpunch"] = { module = "client.dll", rva = 0x112DD7, pattern = "F2 0F 10 44 24 ? F2 0F 11 84 24 ? ? ? ? FF 15", kind = "raw" },
	["GetRemovedAimPunch_E8"] = { module = "client.dll", rva = 0x84FB70, pattern = "E8 ? ? ? ? 4C 8B C0 48 8D 55 ? 48 8B CB E8 ? ? ? ? 48 8D 0D", kind = "rel32" },
	["GetServerName"] = { module = "client.dll", rva = 0xEF0C50, pattern = "40 53 48 83 EC ? 48 8B D9 48 8B 0D ? ? ? ? 48 85 C9 74 ? E8 ? ? ? ? 48 85 C0", kind = "raw" },
	["GetSurfaceData"] = { module = "client.dll", rva = 0x955E30, pattern = "E8 ? ? ? ? 80 78 18 00", kind = "rel32" },
	["GetTickBase"] = { module = "client.dll", rva = 0x8C03F0, pattern = "E8 ? ? ? ? EB ? 48 8B 05 ? ? ? ? 8B 40", kind = "rel32" },
	["GetUserCmdManager"] = { module = "client.dll", rva = 0x8C0680, pattern = "41 56 41 57 48 83 EC ? 48 8D 54 24", kind = "raw" },
	["GetViewAngles"] = { module = "client.dll", rva = 0xAD8B20, pattern = "4C 8B C1 85 D2 74 08 48 8D 05 ? ? ? ? C3", kind = "raw" },
	["GetViewModelOffsets"] = { module = "client.dll", rva = 0x851940, pattern = "40 55 53 56 41 56 41 57 48 8B EC 48 83 EC 20 4D 8B F8 4C 8B F2 48 8B F1 E8", kind = "raw" },
	["GetWeaponInAccuracyRecoveryTime"] = { module = "client.dll", rva = 0x7981D0, pattern = "E8 ? ? ? ? F3 0F 10 B7 ? ? ? ? F3 0F 5E F8", kind = "rel32" },
	["GetWorldFovResolver"] = { module = "client.dll", rva = 0x80FAA0, pattern = "40 53 48 83 EC 50 48 8B D9 E8 ? ? ? ? 48 85 C0 74 ? 48 8B C8 48 83 C4 50 5B E9", kind = "raw" },
	["GlobalLightUpdateState"] = { module = "client.dll", rva = 0xA8E380, pattern = "40 57 48 81 EC C0 00 00 00 48 8B F9 BA FF FF FF FF 48 8D 0D ? ? ? ? E8", kind = "raw" },
	["GloveApply_PerTick"] = { module = "client.dll", rva = 0xBC4D60, pattern = "40 55 56 57 48 8D AC 24 ? ? ? ? 48 81 EC ? ? ? ? 48 8B B9 A0 00 00 00", kind = "raw" },
	["GlowObjectManager_GetInstance"] = { module = "client.dll", rva = 0xB0E300, pattern = "48 8B 05 ? ? ? ? C3 CC CC CC CC CC CC CC CC 8B 41 38 C3", kind = "raw" },
	["HandleEntityList"] = { module = "client.dll", rva = 0x1C3C50, pattern = "E8 ? ? ? ? 84 C0 74 ? 48 63 03", kind = "rel32" },
	["HandleTeamIntro"] = { module = "client.dll", rva = 0x705140, pattern = "48 83 EC ? ? ? ? ? 44 38 89", kind = "raw" },
	["HudChatPrintf"] = { module = "client.dll", rva = 0x10D3B10, pattern = "E8 ? ? ? ? 49 8B 4E 20 BA ? ? ? ?", kind = "rel32" },
	["InfoForResourceTypeCCompositeMaterial_TypeManager"] = { module = "client.dll", rva = 0x13EC2C0, pattern = "40 55 41 56 48 83 EC 68 48 8B EA 83 F9 06 0F 87 B4 02 00 00", kind = "raw" },
	["InitFilter"] = { module = "client.dll", rva = 0x32C140, pattern = "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? 0F B6 41 ? 33 FF 24 C9 C7 41 ?", kind = "raw" },
	["InitPlayerMovementTraceFilter"] = { module = "client.dll", rva = 0x842B10, pattern = "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? 0F B6 41 ? 33 FF C7 41 ?", kind = "raw" },
	["InsecureEmitter"] = { module = "client.dll", rva = 0xC50750, pattern = "48 89 5C 24 20 56 48 83 EC 20 48 8B D9 48 89 6C 24 30 48 8B E9 48 8B 0D ? ? ? ? 48 8B 01", kind = "raw" },
	["IsDemoOrHltv"] = { module = "client.dll", rva = 0xF06BF0, pattern = "48 83 EC ? 48 8B 0D ? ? ? ? ? ? ? FF 90 ? ? ? ? 84 C0 75 ? 38 05", kind = "raw" },
	["IsLocalPlayerWatchingOwnDemo"] = { module = "client.dll", rva = 0xF07600, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 56 57 41 56 48 83 EC ? 48 8B 0D", kind = "raw" },
	["IsOverwatch"] = { module = "client.dll", rva = 0xF07840, pattern = "48 83 EC ? E8 ? ? ? ? 0F B6 40 ? 48 83 C4 ? C3", kind = "raw" },
	["KillFeedbackEmitter"] = { module = "client.dll", rva = 0x84D580, pattern = "48 89 5C 24 08 48 89 74 24 18 48 89 7C 24 20 55 41 56 41 57 48 8B EC 48 81 EC 80 00 00 00 44 8B", kind = "raw" },
	["LevelInit"] = { module = "client.dll", rva = 0x8D2960, pattern = "40 55 56 41 56 48 8D 6C 24 ? 48 81 EC ? ? ? ? 48", kind = "raw" },
	["LevelShutdown"] = { module = "client.dll", rva = 0xAC04E0, pattern = "48 83 EC ? 48 8B 0D ? ? ? ? 48 8D 15", kind = "raw" },
	["LookupBone"] = { module = "client.dll", rva = 0x8CAA40, pattern = "E8 ? ? ? ? 48 8B 8D ? ? ? ? B3", kind = "rel32" },
	["ManageGlowSceneObject"] = { module = "client.dll", rva = 0xADF430, pattern = "E8 ? ? ? ? 48 8B 4F ? 0F 28 7C", kind = "riprel" },
	["MarkInterpLatchFlagsDirty"] = { module = "client.dll", rva = 0x2185C0, pattern = "40 53 56 57 48 83 EC ? 80 3D ? ? ? ? 00", kind = "raw" },
	["MatchFoundHandler"] = { module = "client.dll", rva = 0xC60C20, pattern = "48 85 D2 0F 84 ? ? ? ? 48 8B C4 55 53 56 57 48 8D A8", kind = "raw" },
	["ModernSubtickJumpCheck"] = { module = "client.dll", rva = 0x848380, pattern = "48 89 5C 24 10 48 89 6C 24 18 57 48 83 EC 40 48 8B EA 48 8B D9 48 8B 49 08 BA 02 00 00 00 E8 ? ? ? ? 48 8B 7B 08 48 83 7F 38 00", kind = "raw" },
	["ModulationUpdate"] = { module = "client.dll", rva = 0x9DD2E0, pattern = "48 89 5C 24 08 57 48 83 EC 20 8B FA 48 8B D9 E8 ? ? ? ? 84 C0 0F 84", kind = "raw" },
	["NoClipOnChange"] = { module = "client.dll", rva = 0x167150, pattern = "48 89 5C 24 10 48 89 74 24 18 48 89 7C 24 20 55 48 8B EC 48 83 EC 30 48 8D 05", kind = "raw" },
	["OnAddEntity"] = { module = "client.dll", rva = 0x96AF50, pattern = "48 89 74 24 ? 57 48 83 EC ? 41 B9 ? ? ? ? 41 8B C0 41 23 C1 48 8B F2 41 83 F8 ? 48 8B F9 44 0F 45 C8 41 81 F9 ? ? ? ? 73 ? FF 81", kind = "raw" },
	["OnRemoveEntity"] = { module = "client.dll", rva = 0x96B7B0, pattern = "48 89 74 24 ? 57 48 83 EC ? 41 B9 ? ? ? ? 41 8B C0 41 23 C1 48 8B F2 41 83 F8 ? 48 8B F9 44 0F 45 C8 41 81 F9 ? ? ? ? 73 ? FF 89", kind = "raw" },
	["PanoramaEvent"] = { module = "client.dll", rva = 0xCAC850, pattern = "40 56 57 41 57 48 83 EC ? 48 8B 3D ? ? ? ? 4D 85 C0", kind = "raw" },
	["ParticleCollection"] = { module = "client.dll", rva = 0x1F52E0, pattern = "48 89 5C 24 ? 57 48 83 EC ? 0F 28 05", kind = "raw" },
	["pClientMode"] = { module = "client.dll", rva = 0x2353FF0, pattern = "48 8D 0D ? ? ? ? 48 69 C0 ? ? ? ? 48 03 C1 C3 CC CC", kind = "riprel" },
	["pCSGOInput"] = { module = "client.dll", rva = 0x2079860, pattern = "48 8B 0D ? ? ? ? 4C 8B C6 8B 10 E8", kind = "riprel" },
	["pCvar"] = { module = "client.dll", rva = 0x2558308, pattern = "48 83 EC ? ? 8B ? ? ? ? ? 48 8D 54 ? ? 4C", kind = "riprel" },
	["pEntityList"] = { module = "client.dll", rva = 0x24E76A0, pattern = "48 89 0D ? ? ? ? E9 ? ? ? ? CC", kind = "riprel" },
	["pEntitySystem"] = { module = "client.dll", rva = 0x232A490, pattern = "48 89 ? ? ? ? ? 4C 63 ? ? ? ? ? 44 3B ? ? ? ? ? 0F", kind = "riprel" },
	["pGameEntitySystem"] = { module = "client.dll", rva = 0x24E76A0, pattern = "48 8B 1D ? ? ? ? 48 89 1D ? ? ? ?", kind = "riprel" },
	["pGameRules"] = { module = "client.dll", rva = 0x2341158, pattern = "48 8B 1D ? ? ? ? 48 8D 54 24 ? 0F 28 D0 48 8D 4C 24 ?", kind = "riprel" },
	["pGameTraceManager"] = { module = "client.dll", rva = 0x20459A0, pattern = "48 8B 0D ? ? ? ? 48 8B D0 C7 44 24 ? 04 00 00 00 48 C7 44 24 ? 01 30 1C 00", kind = "riprel" },
	["pGetBBox"] = { module = "client.dll", rva = 0x2341158, pattern = "48 8B 0D ? ? ? ? 48 85 C9 74 ? ? ? ? 48 FF A0 ? ? ? ? 48 8D 05", kind = "riprel" },
	["pGetRenderFov"] = { module = "client.dll", rva = 0x80FAA0, pattern = "E8 ? ? ? ? F3 0F 11 06 48 8B 5C 24 58", kind = "rel32" },
	["pGlobalVariables"] = { module = "client.dll", rva = 0x20616D0, pattern = "48 89 15 ? ? ? ? 48 89 42", kind = "riprel" },
	["pGlowManager"] = { module = "client.dll", rva = 0x233DF50, pattern = "48 8B 05 ? ? ? ? C3 CC CC CC CC CC CC CC CC 8B 41", kind = "riprel" },
	["pHudPanel"] = { module = "client.dll", rva = 0x23B04D0, pattern = "48 89 35 ? ? ? ? E8 ? ? ? ? 48 85", kind = "riprel" },
	["PhysicsRunThink_Ctrl"] = { module = "client.dll", rva = 0x8D9C20, pattern = "48 89 5C 24 ? 57 48 81 EC ? ? ? ? ? ? ? 48 8B F9 FF 90", kind = "raw" },
	["PhysicsRunThink_Pawn"] = { module = "client.dll", rva = 0xB12380, pattern = "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? 8B 81 ? ? ? ? 48 8B F9", kind = "raw" },
	["PlayParticleEffect"] = { module = "client.dll", rva = 0x9AD410, pattern = "48 89 5C 24 ? 48 89 7C 24 ? 55 41 56 41 57 48 8D 6C 24 ? 48 81 EC ? ? ? ? 48 8B D9", kind = "raw" },
	["PlayVSound_client"] = { module = "client.dll", rva = 0x15219C0, pattern = "48 89 5C 24 ? 48 89 74 24 ? 48 89 7C 24 ? 55 48 8D 6C 24 ? 48 81 EC ? ? ? ? 33 FF", kind = "raw" },
	["pLocalPlayerController"] = { module = "client.dll", rva = 0x2320720, pattern = "48 8B 05 ? ? ? ? 41 89 BE", kind = "riprel" },
	["pMainMenuPanel"] = { module = "client.dll", rva = 0x23A3698, pattern = "EC ? 48 8B 05 ? ? ? ? 48 8D 15 ? ? ? ? 48", kind = "riprel" },
	["PostProcessQuery"] = { module = "client.dll", rva = 0x16A9E0, pattern = "48 89 5C 24 08 66 41 0F 6E C8 48 8D 1D ? ? ? ? 66 0F 70 C9 00 4C 8B DA 4C 8B D1 0F 1F 40 00 45 33 C0 49 8B C2", kind = "raw" },
	["pParticleManager"] = { module = "client.dll", rva = 0x2045B48, pattern = "48 8B 0D ? ? ? ? 41 B8 ? ? ? ? F3 0F 11 74 24 ? 48 C7 44 24 ? ? ? ? ?", kind = "riprel" },
	["pPlantedC4s"] = { module = "client.dll", rva = 0x234FF90, pattern = "0F ? ? ? ? ? 39 ? ? ? ? ? 7E ? 48 8B 0D", kind = "riprel" },
	["pPrediction"] = { module = "client.dll", rva = 0x23415A0, pattern = "48 8D 05 ? ? ? ? C3 CC CC CC CC CC CC CC CC 40 53 56 41 54", kind = "riprel" },
	["ProcessImpacts"] = { module = "client.dll", rva = 0x9D1880, pattern = "48 8B C4 53 56 41 55", kind = "raw" },
	["ProcessMovement"] = { module = "client.dll", rva = 0x9DC8C0, pattern = "E8 ? ? ? ? 48 8B 06 48 8B CE FF 90 ? ? ? ? 48 85 DB", kind = "rel32" },
	["ProcessSubTickInput"] = { module = "client.dll", rva = 0xAC96D0, pattern = "89 54 24 10 48 89 4C 24 08 53 56 57 48 83 EC 70", kind = "raw" },
	["pSensitivity"] = { module = "client.dll", rva = 0x233EA60, pattern = "48 8D 0D ? ? ? ? 66 0F 6E CD", kind = "riprel" },
	["pUiEngine"] = { module = "client.dll", rva = 0x24FEAF0, pattern = "48 89 78 ? 48 89 0D ? ? ? ?", kind = "riprel" },
	["pViewMatrix"] = { module = "client.dll", rva = 0x2346B30, pattern = "48 8D 0D ? ? ? ? 48 C1 E0 06", kind = "riprel" },
	["pViewRender"] = { module = "client.dll", rva = 0x2346EE0, pattern = "48 89 05 ? ? ? ? 48 8B C8 48 85 C0", kind = "riprel" },
	["pViewToProjectionMatrix"] = { module = "client.dll", rva = 0x2346AF0, pattern = "48 89 4C 24 ? 4C 8D 0D ? ? ? ? 48 8B 0D", kind = "riprel" },
	["pVPhys2World"] = { module = "client.dll", rva = 0x20459A0, pattern = "4C 8B 25 ? ? ? ? 24", kind = "riprel" },
	["pWeaponC4"] = { module = "client.dll", rva = 0x22BED20, pattern = "48 8B 15 ? ? ? ? 48 8B 5C 24 ? FF C0 89 05 ? ? ? ? 48 8B C6 48 89 34 EA 80 BE", kind = "riprel" },
	["pWorldToProjectionMatrix"] = { module = "client.dll", rva = 0x2346B30, pattern = "48 8D 0D ? ? ? ? 48 C1 E0 06", kind = "riprel" },
	["RegenerateWeaponSkin"] = { module = "client.dll", rva = 0x78DE00, pattern = "40 55 53 41 57 48 8D AC 24 ? ? ? ? 48 81 EC ? ? ? ? 44 0F B6 FA 48 8B D9 BA ? ? ? ? 48 8D 0D ? ? ? ? E8 ? ? ? ?", kind = "raw" },
	["RegenerateWeaponSkin_v2"] = { module = "client.dll", rva = 0x78DE00, pattern = "40 55 53 41 57 48 8D AC 24 ? ? ? ? 48 81 EC ? ? ? ? 44 0F B6 FA 48 8B D9 BA ? ? ? ? 48 8D 0D ? ? ? ? E8", kind = "raw" },
	["RegenerateWeaponSkins"] = { module = "client.dll", rva = 0x7B2A90, pattern = "48 83 EC ? E8 ? ? ? ? 48 85 C0 0F 84 ? ? ? ? 48 8B 10", kind = "raw" },
	["RemoveLegs"] = { module = "client.dll", rva = 0x1102F00, pattern = "40 55 53 56 41 56 41 57 48 8D AC 24 ? ? ? ? 48 81 EC ? ? ? ? F2 0F 10 42", kind = "raw" },
	["RenderDecals"] = { module = "client.dll", rva = 0x10FF540, pattern = "44 88 4C 24 ? 55 53 57 41 54 41 55 48 8D 6C 24 ? 48 81 EC ? ? ? ?", kind = "raw" },
	["RepeatedPtrField_AddAllocatedForParse"] = { module = "client.dll", rva = 0x11719F0, pattern = "48 89 5C 24 ? 57 48 83 EC ? 48 8B D9 48 8B FA 48 8B 49 ? 48 85 C9 74 ? 8B 01", kind = "raw" },
	["ReportHit"] = { module = "client.dll", rva = 0x602800, pattern = "E8 ? ? ? ? 48 8B AC 24 D8 00 00 00 48 81 C4", kind = "rel32" },
	["SendChatMessage"] = { module = "client.dll", rva = 0x10D3B10, pattern = "E8 ? ? ? ? 49 8B 4E 20 BA ? ? ? ?", kind = "rel32" },
	["SerializeUserCmd"] = { module = "client.dll", rva = 0x8D9DB0, pattern = "40 55 56 41 57 48 83 EC 60 8B 4A 20 45 33 FF 44 8B 42 30", kind = "raw" },
	["SetAbsOrigin_Pawn"] = { module = "client.dll", rva = 0x21F4A0, pattern = "48 89 5C 24 ? 57 48 83 EC ? ? ? ? 48 8B FA 48 8B D9 FF 90 ? ? ? ? 84 C0 0F 85", kind = "raw" },
	["SetBodyGroup_inv"] = { module = "client.dll", rva = 0xD9CD30, pattern = "85 D2 0F 88 ? ? ? ? 53 55", kind = "raw" },
	["SetCollisionBounds"] = { module = "client.dll", rva = 0x8065F0, pattern = "48 83 EC ? F2 0F 10 02 8B 42 08", kind = "raw" },
	["SetDynamicAttributeValue"] = { module = "client.dll", rva = 0x1016900, pattern = "48 89 6C 24 ? 57 41 56 41 57 48 81 EC ? ? ? ? 48 8B FA C7 44 24 ? ? ? ? ? 4D 8B F8", kind = "raw" },
	["SetDynamicAttributeValue_raw"] = { module = "client.dll", rva = 0x1016900, pattern = "48 89 6C 24 ? 57 41 56 41 57 48 81 EC ? ? ? ? 48 8B FA C7 44 24", kind = "raw" },
	["SetItemItemIdFunction"] = { module = "client.dll", rva = 0xDA62D0, pattern = "CF 48 8B D0 48 8B 5C 24 ? 48 83 C4 ? 5F E9 ? ? ? ?", kind = "riprel" },
	["SetMeshGroupMask"] = { module = "client.dll", rva = 0xA30920, pattern = "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? 48 8D 99 ? ? ? ? 48 8B 71", kind = "raw" },
	["SetModel"] = { module = "client.dll", rva = 0x8DDAD0, pattern = "40 53 48 83 EC ? 48 8B D9 4C 8B C2 48 8B 0D ? ? ? ? 48 8D 54 24", kind = "raw" },
	["SetPlayerReady"] = { module = "client.dll", rva = 0xF26C10, pattern = "40 53 48 83 EC 20 48 8B DA 48 8D 15 ? ? ? ? 48 8B CB FF 15 ? ? ? ? 85 C0 75 14 BA", kind = "raw" },
	["SetSceneObjectAttributeFloat4"] = { module = "client.dll", rva = 0x174260, pattern = "E8 ? ? ? ? FF C6 48 83 C3 ? 49 3B", kind = "riprel" },
	["SetTraceData"] = { module = "client.dll", rva = 0x7D6930, pattern = "E8 ? ? ? ? 8B 85 ? ? ? ? 48 8D 54 24 ? F2 0F 10 45", kind = "rel32" },
	["SetTraceInit"] = { module = "client.dll", rva = 0xAFB750, pattern = "E8 ? ? ? ? F2 0F 10 ? 4C 8D ?", kind = "rel32" },
	["SetTypeKV3"] = { module = "client.dll", rva = 0x182D140, pattern = "40 53 48 83 EC 30 4C 8B 11 41 B9 ? ? ? ? 49 83 CA 01 0F B6 C2 80 FA 06 48 8B D9 44 0F 45 C8", kind = "raw" },
	["SetupCmd"] = { module = "client.dll", rva = 0x8BD910, pattern = "48 83 EC 28 E8 ? ? ? ? 8B 80", kind = "raw" },
	["SetupMapInfo"] = { module = "client.dll", rva = 0xC8C340, pattern = "48 8B C4 48 89 58 ? 48 89 68 ? 48 89 70 ? 57 48 81 EC ? ? ? ? 0F 29 70 ? 48 8B EA 0F 29 78 ? 45 33 C0", kind = "raw" },
	["SetupMove"] = { module = "client.dll", rva = 0xD22B90, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 56 57 41 56 48 83 EC ? 48 8B EA 4C 8B F1 E8 ? ? ? ? 48 8D 15", kind = "raw" },
	["SetupMovementMoves"] = { module = "client.dll", rva = 0x119994F, pattern = "48 8B ? E8 ? ? ? ? 48 8B 5C 24 ? 48 8B 6C 24 ? 48 83 C4 30", kind = "raw" },
	["SetViewAngle"] = { module = "client.dll", rva = 0xAE7DB0, pattern = "85 D2 75 3D 48 63 81 ? ? ? ?", kind = "raw" },
	["SetViewAngles"] = { module = "client.dll", rva = 0xAE7DB0, pattern = "85 D2 75 ? 48 63 81", kind = "raw" },
	["SharedRandomFloat"] = { module = "client.dll", rva = 0xA31C20, pattern = "4C 8B DC 49 89 5B 08 49 89 73 10 57 48 81 EC 00 01 00 00 8B 05 ? ? ? ? 48 8D 54 24 40", kind = "raw" },
	["ShouldShowHudElements"] = { module = "client.dll", rva = 0xF27C00, pattern = "48 83 EC ? BA ? ? ? ? 48 8D 0D ? ? ? ? E8 ? ? ? ? 48 85 C0 75 ? 48 8B 05 ? ? ? ? 48 8B 40 ? ? ? 00 74 ? BA", kind = "raw" },
	["ShowMessageBox"] = { module = "client.dll", rva = 0xCA8FF0, pattern = "44 88 4C 24 ? 53 41 56", kind = "raw" },
	["SOCreated"] = { module = "client.dll", rva = 0x387780, pattern = "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? 48 8B FA 48 8B F1", kind = "raw" },
	["SomeTimingFromPawn"] = { module = "client.dll", rva = 0xA5A090, pattern = "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? 49 63 D8 48 8B F1", kind = "raw" },
	["Spawner_PerTickOrchestrator"] = { module = "client.dll", rva = 0xBC7940, pattern = "48 8B C4 55 53 48 8D A8 ? ? ? ? 48 81 EC ? ? ? ? 80 B9 B1 13 00 00 00", kind = "raw" },
	["SpectatorInput"] = { module = "client.dll", rva = 0x7DBA90, pattern = "48 89 5C 24 10 55 56 57 41 56 41 57 48 8B EC 48 83 EC 60 48 8B 01 41 8B F8 48 8B DA 48 8B F1 FF", kind = "raw" },
	["SpreadSeedGen"] = { module = "client.dll", rva = 0xC81D90, pattern = "48 89 5C 24 08 57 48 81 EC F0 00 00 00 F3 0F 10 0A 48 8D 8C 24 10 01 00 00 41 8B D8 48 8B FA E8", kind = "raw" },
	["SubmitCommendation"] = { module = "client.dll", rva = 0xF2D260, pattern = "48 89 74 24 ? 55 57 41 56 48 8D 6C 24 ? 48 81 EC ? ? ? ? 48 8B CA", kind = "raw" },
	["SubmitPlayerReport"] = { module = "client.dll", rva = 0xF2D540, pattern = "48 89 5C 24 ? 56 48 83 EC ? 48 8B CA", kind = "raw" },
	["TestSurfaces"] = { module = "client.dll", rva = 0x8099E0, pattern = "40 53 57 41 56 48 83 EC 50 8B", kind = "raw" },
	["ThirdPersonOffHandler"] = { module = "client.dll", rva = 0xACD130, pattern = "48 83 EC 28 48 8B 0D ? ? ? ? 48 8D 54 24 ? 48 8B 01 FF 90 08 03 00 00 83 7C 24 ? 00 75 ? 48 8B 05 ? ? ? ? C6 80 29 02 00 00 00 C7 80 A8 06 00 00 00", kind = "raw" },
	["ThirdPersonOnHandler"] = { module = "client.dll", rva = 0xACD210, pattern = "48 83 EC 38 48 8B 0D ? ? ? ? 48 8D 54 24 ? 48 8B 01 FF 90 08 03 00 00 83 7C 24 ? 00 0F 85 ? ? ? ? 4C 8B 05 ? ? ? ? 41 8B 80 50 0B 00 00", kind = "raw" },
	["TraceCreate"] = { module = "client.dll", rva = 0x8074D0, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 57 41 56 41 57 48 83 EC 50 F2 0F 10 02", kind = "raw" },
	["TraceGetInfo"] = { module = "client.dll", rva = 0x809B00, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 57 48 83 EC 60 48 8B E9 0F 29 74 24", kind = "raw" },
	["TraceHandleBulletPen"] = { module = "client.dll", rva = 0x823BF0, pattern = "48 8B C4 44 89 48 20 48 89 50 10 48 89 48 08 55 57 41 57", kind = "raw" },
	["TraceInitData"] = { module = "client.dll", rva = 0x803220, pattern = "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC 20 48 8D 79 ? 33 F6 C7 47", kind = "raw" },
	["TraceInitFilter"] = { module = "client.dll", rva = 0x32C140, pattern = "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? 0F B6 41 ? 33 FF 24", kind = "raw" },
	["TraceInitInfo"] = { module = "client.dll", rva = 0x160E4E0, pattern = "40 55 41 55 41 57 48 83 EC 30", kind = "raw" },
	["TracePlayerBBox"] = { module = "client.dll", rva = 0xB74790, pattern = "48 89 5C 24 ? 55 57 41 54 41 55 41 56", kind = "raw" },
	["TraceShape"] = { module = "client.dll", rva = 0x9913B0, pattern = "48 89 5C 24 ? 48 89 4C 24 ? 55 57", kind = "raw" },
	["TraceToExit"] = { module = "client.dll", rva = 0x8074D0, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 57 41 56 41 57 48 83 EC ? F2 0F 10 02", kind = "raw" },
	["TransformScale3dVMT"] = { module = "client.dll", rva = 0x1B0C2F0, pattern = "48 8D 0D ? ? ? ? F3 0F 10 4B ? F3 0F 10 43", kind = "riprel" },
	["TransformTranslate3dVMT"] = { module = "client.dll", rva = 0x1B03918, pattern = "00 00 80 00 48 8D 05 ? ? ? ? 48 C7 42 ? 00", kind = "riprel" },
	["UnknownParticleFunction"] = { module = "client.dll", rva = 0x989DF0, pattern = "40 56 48 83 EC ? 41 8B F0", kind = "raw" },
	["UnlockInventory"] = { module = "client.dll", rva = 0x702450, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 57 48 83 EC ? 48 8B E9 48 8B 0D ? ? ? ? ? ? ? FF 50", kind = "raw" },
	["UntrustedFlagSetter"] = { module = "client.dll", rva = 0x157095, pattern = "74 26 C6 05 ? ? ? ? 01 33 C0 83 F8 01", kind = "raw" },
	["UpdateGlobalVars"] = { module = "client.dll", rva = 0xAE7800, pattern = "48 8B 0D ? ? ? ? 4C 8D 05 ? ? ? ? 48 85 D2", kind = "raw" },
	["UpdateOnRemove"] = { module = "client.dll", rva = 0x14DC810, pattern = "48 89 5C 24 08 48 89 74 24 10 57 48 83 EC 40 48 8B D9 C6 05 ? ? ? ? 01 48 8B 49", kind = "raw" },
	["UpdatePostProcessing"] = { module = "client.dll", rva = 0xF2ADA0, pattern = "48 85 D2 0F 84 ? ? ? ? 48 89 5C 24 08 57 48 83 EC 60 80", kind = "raw" },
	["UpdateSkybox"] = { module = "client.dll", rva = 0x25ADA0, pattern = "48 89 5C 24 ? 57 48 83 EC ? 48 8B F9 E8 ? ? ? ? 48 8B 47", kind = "raw" },
	["UpdateSubClass"] = { module = "client.dll", rva = 0x1FAE80, pattern = "4C 8B DC 53 48 81 EC ? ? ? ? 48 8B 41 10 48 8B D9 8B 50 30 C1 EA 04", kind = "raw" },
	["UpdateTurningInAccuracy"] = { module = "client.dll", rva = 0x7B1AF0, pattern = "E8 ? ? ? ? F3 0F 10 87 ? ? ? ? 44 0F 2F C8", kind = "rel32" },
	["ViewModelHideZoomed"] = { module = "client.dll", rva = 0x7A20A0, pattern = "48 89 5C 24 20 55 56 57 41 54 41 56 48 8B EC 48 83 EC 50 48 8D 05", kind = "raw" },
	["WriteSubtickFromEntry"] = { module = "client.dll", rva = 0xC59D90, pattern = "48 89 5C 24 ? 55 57 41 56 48 8D 6C 24 ? 48 81 EC B0 00 00 00 8B 01 48 8B F9 81 4A 10 00 02", kind = "raw" },
	["OverrideView"] = { module = "client.dll", rva = 0xC63230, pattern = "40 57 48 83 EC ? 48 8B FA E8 ? ? ? ? BA", kind = "raw" },
	["InitTraceInfo"] = { module = "client.dll", rva = 0x160E4E0, pattern = "40 55 41 55 41 57 48 83 EC", kind = "raw" },
	["GetTraceInfo_v2"] = { module = "client.dll", rva = 0x809B00, pattern = "48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 57 48 83 EC ? 48 8B E9 0F 29 74 24", kind = "raw" },
	["HandleBulletPenetration_v2"] = { module = "client.dll", rva = 0x823BF0, pattern = "48 8B C4 44 89 48 ? 48 89 50 ? 48 89 48 ? 55 57", kind = "raw" },
	["GetMapBspName"] = { module = "client.dll", rva = 0xEE2B90, pattern = "48 8B 0D ? ? ? ? ? ? ? 48 FF A0 ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? 48 89 5C 24 ? 57", kind = "raw" },
	["GetPlayerModel"] = { module = "client.dll", rva = 0xEEAD70, pattern = "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? 48 8B CA FF 15 ? ? ? ? 48 8B 1D ? ? ? ? 48 8B F0 8B 5B ? 85 DB 74 ? 33 FF 0F 1F 44 00 ? 8B CF E8 ? ? ? ? 48 85 C0 74 ? 8B 88 ? ? ? ? C1 E9 ? F6 C1 ? 74 ? 48 63 C7 EB ? 48 8B C8 E8 ? ? ? ? 48 3B C6 74 ? FF C7 3B FB 75 ? BF ? ? ? ? 8B CF E8 ? ? ? ? 48 8B D8 48 85 C0 74 ? 48 8B C8 E8 ? ? ? ? 48 85 C0 48 0F 45 D8 48 8B CB E8 ? ? ? ? 0F B7 D8 E8 ? ? ? ? 8B D3 45 33 C0 48 8B C8 E8 ? ? ? ? 48 8B D8", kind = "raw" },
	["IsLatched"] = { module = "client.dll", rva = 0xF07490, pattern = "0F B6 81 ? ? ? ? C3 ? ? ? ? ? ? ? ? 48 83 EC ? 33 C9", kind = "raw" },
	["SetAttribute"] = { module = "client.dll", rva = 0x174040, pattern = "48 89 6C 24 ? 48 89 74 24 ? 57 48 83 EC ? 66 0F 6E CA 49 8B F0 66 0F 70 C9 00 8B EA 48 8B F9 45 33 C9 48 8B C1", kind = "raw" },
	["HasOngoingMatch"] = { module = "client.dll", rva = 0xEF66B0, pattern = "0F B6 05 ? ? ? ? 24", kind = "raw" },
	["ActionReconnectToOngoingMatch"] = { module = "client.dll", rva = 0xEBE540, pattern = "48 83 EC ? F6 05 ? ? ? ? ? 74 ? 48 8B 0D", kind = "raw" },
	["ActionAbandonOngoingMatch"] = { module = "client.dll", rva = 0xEBD5E0, pattern = "40 57 48 83 EC ? 33 FF", kind = "raw" },
	["ActionMatchmaking"] = { module = "client.dll", rva = 0xEBDAB0, pattern = "48 89 5C 24 ? 55 57 41 56 48 81 EC ? ? ? ? 48 8B 0D", kind = "raw" },
	["GetCooldownSecondsRemaining"] = { module = "client.dll", rva = 0xED4A10, pattern = "48 83 EC ? 8B 05 ? ? ? ? C1 E8 ? A8 ? 74 ? 48 8D 4C 24", kind = "raw" },
	["GetCooldownType"] = { module = "client.dll", rva = 0xED4A80, pattern = "8B 15 ? ? ? ? 8D 42 ? 83 F8", kind = "raw" },
	["CooldownIsPermanent"] = { module = "client.dll", rva = 0xEC7450, pattern = "8B 0D ? ? ? ? 8D 41 ? A9", kind = "raw" },
	["GetCooldownReason"] = { module = "client.dll", rva = 0xED48A0, pattern = "8B 05 ? ? ? ? 48 8D 15 ? ? ? ? FF C8", kind = "raw" },
	["ActionAcknowledgePenalty"] = { module = "client.dll", rva = 0xEBD720, pattern = "E9 ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? 48 89 5C 24 ? 48 89 74 24 ? 57 48 81 EC ? ? ? ? 41 8B D9", kind = "raw" },
	["ShowFairPlayGuidelinesForCooldown"] = { module = "client.dll", rva = 0xF27CD0, pattern = "8B 05 ? ? ? ? 32 D2", kind = "raw" },
	["GetTournamentTeamCount"] = { module = "client.dll", rva = 0xEF4B10, pattern = "40 53 48 83 EC ? 8B 05 ? ? ? ? 33 DB C1 E8 ? A8 ? 74 ? 48 8B 05 ? ? ? ? 48 8D 0D ? ? ? ? 48 85 C0 48 0F 45 C8 8B 41 ? ? ? A8 ? 74 ? 48 8B 49 ? 48 83 E1 ? 48 83 79 ? ? 76 ? ? ? ? ? ? 74 ? FF 15 ? ? ? ? 85 C0 0F 44 1D ? ? ? ? 8B C3 48 83 C4 ? 5B C3 48 89 5C 24", kind = "raw" },
	["GetTournamentTeamNameByIndex"] = { module = "client.dll", rva = 0xEF4DD0, pattern = "40 53 48 83 EC ? 8B 05 ? ? ? ? C1 E8 ? 49 63 D8 A8 ? 74 ? 48 8B 05 ? ? ? ? 48 8D 0D ? ? ? ? 48 85 C0 48 0F 45 C8 8B 41 ? ? ? A8 ? 74 ? 48 8B 49 ? 48 83 E1 ? 48 83 79 ? ? 76 ? ? ? ? ? ? 00 74 ? FF 15 ? ? ? ? 85 C0 75 ? 85 DB 78 ? 3B 1D ? ? ? ? 7D ? 48 8B 05 ? ? ? ? 48 8B 54 D8 ? 8B 42 ? C1 E8 ? A8 ? 74 ? 48 8B 42 ? 48 83 E0 ? 48 83 78 ? ? 76 ? ? ? ? 48 83 C4 ? 5B C3 48 8D 05 ? ? ? ? 48 83 C4 ? 5B C3 ? ? ? ? 48 89 5C 24", kind = "raw" },
	["GetTournamentTeamTagByIndex"] = { module = "client.dll", rva = 0xEF4F40, pattern = "40 53 48 83 EC ? 8B 05 ? ? ? ? C1 E8 ? 49 63 D8 A8 ? 74 ? 48 8B 05 ? ? ? ? 48 8D 0D ? ? ? ? 48 85 C0 48 0F 45 C8 8B 41 ? ? ? A8 ? 74 ? 48 8B 49 ? 48 83 E1 ? 48 83 79 ? ? 76 ? ? ? ? ? ? 00 74 ? FF 15 ? ? ? ? 85 C0 75 ? 85 DB 78 ? 3B 1D ? ? ? ? 7D ? 48 8B 05 ? ? ? ? 48 8B 44 D8", kind = "raw" },
	["GetTournamentTeamFlagByIndex"] = { module = "client.dll", rva = 0xEF4C50, pattern = "40 53 48 83 EC ? 8B 05 ? ? ? ? C1 E8 ? 49 63 D8 A8 ? 74 ? 48 8B 05 ? ? ? ? 48 8D 0D ? ? ? ? 48 85 C0 48 0F 45 C8 8B 41 ? ? ? A8 ? 74 ? 48 8B 49 ? 48 83 E1 ? 48 83 79 ? ? 76 ? ? ? ? ? ? 00 74 ? FF 15 ? ? ? ? 85 C0 75 ? 85 DB 78 ? 3B 1D ? ? ? ? 7D ? 48 8B 05 ? ? ? ? 48 8B 54 D8 ? 8B 42 ? ? ? A8", kind = "raw" },
	["GetTournamentTeamNameByID"] = { module = "client.dll", rva = 0xEF4CF0, pattern = "48 89 5C 24 ? 57 48 83 EC ? 8B 05 ? ? ? ? 33 DB C1 E8 ? 41 8B F8 A8 ? 0F 84 ? ? ? ? 48 8B 05 ? ? ? ? 48 8D 0D ? ? ? ? 48 85 C0 48 0F 45 C8 8B 41 ? ? ? A8 ? 74 ? 48 8B 49 ? 48 83 E1 ? 48 83 79 ? ? 76 ? ? ? ? ? ? 74 ? FF 15 ? ? ? ? 85 C0 75 ? 48 63 05 ? ? ? ? 85 C0 7E ? 4C 8B 15 ? ? ? ? 4C 8B C8 48 8B CB 49 8D 52 ? 66 0F 1F 44 00 ? ? ? ? 41 8B 40 ? C1 E8", kind = "raw" },
	["GetTournamentTeamTagByID"] = { module = "client.dll", rva = 0xEF4E70, pattern = "48 89 5C 24 ? 57 48 83 EC ? 8B 05 ? ? ? ? 33 DB C1 E8 ? 41 8B F8 A8 ? 74", kind = "raw" },
	["GetTournamentTeamFlagByID"] = { module = "client.dll", rva = 0xEF4B70, pattern = "48 89 5C 24 ? 57 48 83 EC ? 8B 05 ? ? ? ? 33 DB C1 E8 ? 41 8B F8 A8 ? 0F 84 ? ? ? ? 48 8B 05 ? ? ? ? 48 8D 0D ? ? ? ? 48 85 C0 48 0F 45 C8 8B 41 ? ? ? A8 ? 74 ? 48 8B 49 ? 48 83 E1 ? 48 83 79 ? ? 76 ? ? ? ? ? ? 74 ? FF 15 ? ? ? ? 85 C0 75 ? 48 63 05 ? ? ? ? 85 C0 7E ? 4C 8B 15 ? ? ? ? 4C 8B C8 48 8B CB 49 8D 52 ? 66 0F 1F 44 00 ? ? ? ? 41 8B 40 ? ? ? A8", kind = "raw" },
	["GetTournamentStageCount"] = { module = "client.dll", rva = 0xEF4A10, pattern = "40 53 48 83 EC ? 8B 05 ? ? ? ? 33 DB C1 E8 ? A8 ? 74 ? 48 8B 05 ? ? ? ? 48 8D 0D ? ? ? ? 48 85 C0 48 0F 45 C8 8B 41 ? ? ? A8 ? 74 ? 48 8B 49 ? 48 83 E1 ? 48 83 79 ? ? 76 ? ? ? ? ? ? 74 ? FF 15 ? ? ? ? 85 C0 0F 44 1D ? ? ? ? 8B C3 48 83 C4 ? 5B C3 40 53", kind = "raw" },
	["GetTournamentStageNameByIndex"] = { module = "client.dll", rva = 0xEF4A70, pattern = "40 53 48 83 EC ? 8B 05 ? ? ? ? C1 E8 ? 49 63 D8 A8 ? 74 ? 48 8B 05 ? ? ? ? 48 8D 0D ? ? ? ? 48 85 C0 48 0F 45 C8 8B 41 ? ? ? A8 ? 74 ? 48 8B 49 ? 48 83 E1 ? 48 83 79 ? ? 76 ? ? ? ? ? ? 00 74 ? FF 15 ? ? ? ? 85 C0 75 ? 85 DB 78 ? 3B 1D ? ? ? ? 7D ? 48 8B 05 ? ? ? ? 48 8B 54 D8 ? 8B 42 ? C1 E8 ? A8 ? 74 ? 48 8B 42 ? 48 83 E0 ? 48 83 78 ? ? 76 ? ? ? ? 48 83 C4 ? 5B C3 48 8D 05 ? ? ? ? 48 83 C4 ? 5B C3 ? ? ? ? 40 53", kind = "raw" },
	["GetDirectChallengeCode"] = { module = "client.dll", rva = 0xED6CF0, pattern = "48 83 EC ? F7 05", kind = "raw" },
	["GetDirectChallengeCodeForClan"] = { module = "client.dll", rva = 0xED6D40, pattern = "48 81 EC ? ? ? ? 85 D2", kind = "raw" },
	["GenerateDirectChallengeCode"] = { module = "client.dll", rva = 0xED0750, pattern = "48 83 EC ? E8 ? ? ? ? 48 8B 05", kind = "raw" },
	["ValidateDirectChallengeCode"] = { module = "client.dll", rva = 0xF32660, pattern = "40 53 41 56 48 83 EC ? 4D 8B F0", kind = "raw" },
	["GetRotatingOfficialMapGroupCurrentState"] = { module = "client.dll", rva = 0xEF0390, pattern = "48 81 EC ? ? ? ? 48 8B CA 48 8D 15", kind = "raw" },
}

function SIG.get(name)
	return SIG.DB[name]
end

-- Безопасный низкоуровневый поиск (никогда не кидает ошибку).
-- ВАЖНО: паттерны в этой базе используют одиночный "?" (формат IDA), а
-- mem.FindPattern в Aimware ожидает двойной "??" для байта-маски (см. пример
-- в доках: mem.FindPattern("client.dll", "C3 ?? CC")). Нормализуем тут один
-- раз (по токенам через пробел), чтобы не переписывать все 298 паттернов вручную.
local function normalize_pattern(pattern)
	local parts = {}
	for token in pattern:gmatch("%S+") do
		if token == "?" then
			parts[#parts + 1] = "??"
		else
			parts[#parts + 1] = token
		end
	end
	return table.concat(parts, " ")
end

function SIG.find(module_name, pattern)
	local ok, addr = pcall(function() return mem.FindPattern(module_name, normalize_pattern(pattern)) end)
	if not ok or not addr or addr == 0 then return nil end
	return tonumber(addr)
end

local function r_i32(ffi_lib, a)
	local ok, v = pcall(function() return ffi_lib.cast("int32_t*", a)[0] end)
	return ok and v or nil
end

-- kind="raw": возвращает адрес функции напрямую (nil, err при неудаче)
function SIG.resolve_raw(name)
	local e = SIG.DB[name]
	if not e then return nil, "not found in db: " .. tostring(name) end
	if e.kind ~= "raw" then return nil, "entry is not kind=raw: " .. name end
	local addr = SIG.find(e.module, e.pattern)
	if not addr then return nil, "pattern not found (outdated?): " .. name end
	return addr, e
end

-- kind="rel32"/"riprel": паттерн указывает на call/lea/mov с относительным
-- адресом; call_off - смещение байта opcode (E8/48 8B 05 и т.п.) ВНУТРИ
-- найденного совпадения (обычно 0, если паттерн начинается прямо с него).
-- instr_len - полная длина инструкции с rel32 (обычно 5 для E8 xx xx xx xx,
-- 7 для нескольких REX+opcode+modrm+rel32 вариантов - сверяйся с дизасмом).
function SIG.resolve_rel32(name, call_off, instr_len)
	local ffi_lib = rawget(_G, "ffi")
	if type(ffi_lib) ~= "table" then return nil, "ffi not available" end
	local e = SIG.DB[name]
	if not e then return nil, "not found in db: " .. tostring(name) end
	if e.kind ~= "rel32" and e.kind ~= "riprel" then
		return nil, "entry is not kind=rel32/riprel: " .. name
	end
	local found = SIG.find(e.module, e.pattern)
	if not found then return nil, "pattern not found (outdated?): " .. name end
	call_off = call_off or 0
	instr_len = instr_len or 5
	local rel = r_i32(ffi_lib, found + call_off + (instr_len - 4))
	if not rel then return nil, "could not read rel32 for: " .. name end
	local target = found + call_off + instr_len + rel
	return target, e, found
end

-- ============================================================
-- Оффсеты netvar-полей - НЕ хардкодятся тут, тянутся динамически с
-- a2x/cs2-dumper, как это уже сделано в остальных скриптах. Обёртка
-- ниже даётся только для единообразия (чтобы все скрипты брали оффсеты
-- одним и тем же способом через этот файл, вместо копипасты http.Get
-- в каждом скрипте).
-- ============================================================
local DUMPER_URL = "https://raw.githubusercontent.com/a2x/cs2-dumper/main/output/client_dll.json"
local dumper_cache = nil

-- Возвращает офсет по имени поля (и опционально имени класса-контекста,
-- см. поведение как в osnova_skin.lua pull_offset: after-имя ограничивает
-- поиск конкретным классом, если одноимённое поле встречается в нескольких).
function SIG.dumper_offset(field_name, after_class)
	if not dumper_cache then
		local ok, j = pcall(function() return http.Get(DUMPER_URL) end)
		if ok and type(j) == "string" then dumper_cache = j end
	end
	if not dumper_cache then return nil end
	local init = 1
	if after_class then
		local p = dumper_cache:find('"' .. after_class .. '"%s*:%s*{')
		if p then init = p end
	end
	local v = dumper_cache:match('"' .. field_name .. '"%s*:%s*(%d+)', init)
	return v and tonumber(v) or nil
end

-- ============================================================
-- Структуры (не netvar, а C++ layout из присланных SDK-заголовков).
-- Эти оффсеты статичны относительно layout класса и не публикуются
-- cs2-dumper'ом (он работает только с schema/netvar системой игры).
-- ============================================================
SIG.STRUCT = {
	-- c_view_setup - структура, которую OverrideView(thisptr, viewSetup)
	-- принимает вторым параметом (см. presented c_view_setup.hpp)
	c_view_setup = {
		m_fov           = 0x04D8,
		m_viewmodel_fov = 0x04DC,
		m_origin        = 0x04E0, -- vec3_t: x,y,z по 4 байта (float) каждая
		m_angles        = 0x04F8, -- vec3_t
		m_aspect_ratio  = 0x0518,
	},
}

return SIG
