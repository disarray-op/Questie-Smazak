-- This file does not use the module system, so it names its own load-timing interval.
QuestieSmazakLoader:StampLoadBoundary()

local addonName, _ = ...

-- Check addon is not renamed to avoid conflicts in global name space.
if addonName ~= "QuestieSmazak" then
    local msg = {"You have renamed QuestieSmazak addon.", "This is restricted to avoid issues.", "Please remove '" .. addonName .. "'",
        "and reinstall the original version."}
    StaticPopupDialogs["QUESTIE_ADDON_NAME_ERROR"] = {
        text = "|cffff0000ERROR|r\n" .. msg[1] .. "\n" .. msg[2] .. "\n\n" .. msg[3] .. "\n" .. msg[4],
        button2 = "OK",
        hasEditBox = false,
        whileDead = true,
    }

    C_Timer.After(4, function()
        DEFAULT_CHAT_FRAME:AddMessage("---------------------------------")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000ERROR|r: |cff42f5ad" .. msg[1] .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000ERROR|r: |cff42f5ad" .. msg[2] .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000ERROR|r: |cff42f5ad" .. msg[3] .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000ERROR|r: |cff42f5ad" .. msg[4] .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("---------------------------------")
        error("ERROR: " .. msg[1] .. " " .. msg[2] .. " " .. msg[3])
    end)
    StaticPopup_Show("QUESTIE_ADDON_NAME_ERROR")
    return
end

if QuestieSmazak then
    C_Timer.After(4, function()
        error("ERROR!! -> QuestieSmazak already loaded! Please only have one QuestieSmazak installed!")
        for _ = 1, 10 do
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000ERROR!!|r -> QuestieSmazak already loaded! Please only have one QuestieSmazak installed!")
        end
    end);
    error("ERROR!! -> QuestieSmazak already loaded! Please only have one QuestieSmazak installed!")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000ERROR!!|r -> QuestieSmazak already loaded! Please only have one QuestieSmazak installed!")
    QuestieSmazak = {}
    return
end

--Initialized below
---@class QuestieSmazak : AceAddon, AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, AceComm-3.0, AceBucket-3.0
QuestieSmazak = LibStub("AceAddon-3.0"):NewAddon("QuestieSmazak", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceComm-3.0", "AceBucket-3.0")

QuestieSmazak.API = {
    isReady = false,
}

-- preinit placeholder to stop tukui crashing from literally force-removing one of our features no matter what users select in the config ui
QuestieSmazak.db = {profile = {minimap = {hide = false}}}

-- prevent multiple warnings for the same ID, not sure the best place to put this
QuestieSmazak._sessionWarnings = {}

-- Forever shares Retail's project ID, but uses Classic content. Detect it by interface version instead.
local interfaceVersion = select(4, GetBuildInfo())
---@type boolean
QuestieSmazak.IsForever = interfaceVersion >= 16000 and interfaceVersion < 17000

--- Addon is running on Classic MoP client
---@type boolean
QuestieSmazak.IsMoP = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC

--- Addon is running on Classic Cata client
---@type boolean
QuestieSmazak.IsCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC

--- Addon is running on Classic Wotlk client
---@type boolean
QuestieSmazak.IsWotlk = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

--- Addon is running on Classic TBC client
---@type boolean
QuestieSmazak.IsTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

--- Uses Classic content: Era, its seasons, or Forever. API availability must be checked separately.
---@type boolean
QuestieSmazak.IsClassic = QuestieSmazak.IsForever or WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

--- Addon is running on Classic "Vanilla" client and on Era realm (non-seasonal)
---@type boolean
QuestieSmazak.IsEra = QuestieSmazak.IsClassic and (not C_Seasons.HasActiveSeason())

-- See https://warcraft.wiki.gg/wiki/API_C_Seasons.GetActiveSeason

--- Addon is running on Classic "Vanilla" client and on Season of Mastery realm specifically
---@type boolean
QuestieSmazak.IsSoM = QuestieSmazak.IsClassic and C_Seasons.HasActiveSeason() and (C_Seasons.GetActiveSeason() == Enum.SeasonID.SeasonOfMastery)

--- Addon is running on Classic "Vanilla" client and on Season of Discovery realm specifically
---@type boolean
QuestieSmazak.IsSoD = QuestieSmazak.IsClassic and C_Seasons.HasActiveSeason() and (C_Seasons.GetActiveSeason() == Enum.SeasonID.SeasonOfDiscovery)

--- Addon is running on Classic "WotLK" client and on a Titan Forged realm specifically
---@type boolean
QuestieSmazak.IsTitanReforged = QuestieSmazak.IsWotlk and C_Seasons.HasActiveSeason() and (C_Seasons.GetActiveSeason() == 109) -- There is no entry in Enum.SeasonID for this

--- Addon is running on Classic "Vanilla" client and on Classic Anniversary realm ( )
---@type boolean
QuestieSmazak.IsAnniversaryEra = QuestieSmazak.IsClassic and C_Seasons.HasActiveSeason() and (C_Seasons.GetActiveSeason() == Enum.SeasonID.Fresh)

--- Addon is running on Classic "Vanilla" client and on Classic Anniversary realm ( )
---@type boolean
QuestieSmazak.IsAnniversaryTBC = QuestieSmazak.IsTBC and C_Seasons.HasActiveSeason() and (C_Seasons.GetActiveSeason() == Enum.SeasonID.Fresh)

--- Addon is running on Classic "Vanilla" client and on Classic Anniversary Hardcore realm
---@type boolean
QuestieSmazak.IsAnniversaryHardcore = QuestieSmazak.IsClassic and C_Seasons.HasActiveSeason() and (C_Seasons.GetActiveSeason() == Enum.SeasonID.FreshHardcore)

--- Addon is running on a HardCore realm specifically
---@type boolean
QuestieSmazak.IsHardcore = C_GameRules and C_GameRules.IsHardcoreActive()

--- Addon is running on a Chinese realm
---@type boolean
QuestieSmazak.IsChinaRegion = GetCurrentRegion() == 5

--- Addon is running on EU realm
---@type boolean
QuestieSmazak.IsEURegion = GetCurrentRegion() == 3
