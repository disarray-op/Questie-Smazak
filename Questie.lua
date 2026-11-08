---@type QuestieCompat
local QuestieCompat = QuestieSmazakLoader:ImportModule("QuestieCompat")

local band = bit.band

-------------------------
--Import modules.
-------------------------
---@type QuestieOptionsDefaults
local QuestieOptionsDefaults = QuestieSmazakLoader:ImportModule("QuestieOptionsDefaults")
---@type EventHandler
local EventHandler = QuestieSmazakLoader:ImportModule("EventHandler")
---@type CommsVisibility
local CommsVisibility = QuestieSmazakLoader:ImportModule("CommsVisibility")
---@type QuestieQuest
local QuestieQuest = QuestieSmazakLoader:ImportModule("QuestieQuest")
---@type TrackerBaseFrame
local TrackerBaseFrame = QuestieSmazakLoader:ImportModule("TrackerBaseFrame")
---@type QuestieValidateGameCache
local QuestieValidateGameCache = QuestieSmazakLoader:ImportModule("QuestieValidateGameCache")
---@type QuestieInit
local QuestieInit = QuestieSmazakLoader:ImportModule("QuestieInit")
---@type Expansions
local Expansions = QuestieSmazakLoader:ImportModule("Expansions")
---@type QuestieProfiler
local QuestieProfiler = QuestieSmazakLoader:ImportModule("Profiler")
---@type WaypointRenderer
local WaypointRenderer = QuestieSmazakLoader:ImportModule("WaypointRenderer")
---@type QuestieWaypoints
local QuestieWaypoints = QuestieSmazakLoader:ImportModule("QuestieWaypoints")

---Called on ADDON_LOADED - Saved Variables are loaded at this point
function QuestieSmazak:OnInitialize()
    -- This has to happen OnInitialize to be available asap
    QuestieSmazak.db = LibStub("AceDB-3.0"):New("QuestieSmazakConfig", QuestieOptionsDefaults:Load(), true)

    -- These events basically all mean the same: The active profile changed.
    QuestieSmazak.db.RegisterCallback(QuestieSmazak, "OnProfileChanged", "RefreshConfig")
    QuestieSmazak.db.RegisterCallback(QuestieSmazak, "OnProfileCopied", "RefreshConfig")
    QuestieSmazak.db.RegisterCallback(QuestieSmazak, "OnProfileReset", "RefreshConfig")

    EventHandler:RegisterEarlyEvents()

    QuestieInit.OnAddonLoaded()
end

function QuestieSmazak:OnEnable()
    if QuestieSmazak.IsForever or Expansions.Current >= Expansions.Wotlk then
        -- Called when the addon is enabled
        if (QuestieSmazak.db.profile.trackerEnabled) then
            QuestieCompat.HideWatchFrame()
        end
    end
end

function QuestieSmazak:OnDisable()
    if QuestieSmazak.IsForever or Expansions.Current >= Expansions.Wotlk then
        -- Called when the addon is disabled
        QuestieCompat.ShowWatchFrame()
    end
end

---AceDB has already activated the new profile before this callback. RefreshConfig calls the
---local icon, quest, tracker, and waypoint line refresh paths, then schedules V1 from the newly
---active profile's tracking policy. QuestieQuest:SmoothReset may continue asynchronously.
---@param _event "OnProfileChanged"|"OnProfileCopied"|"OnProfileReset" AceDB callback name.
---@param _database AceDBObject-3.0 AceDB database whose new profile data is already active.
---@param _profileName string? New or source profile name; absent for profile reset.
function QuestieSmazak:RefreshConfig(_event, _database, _profileName)
    QuestieSmazak:SetIcons()
    QuestieQuest:SmoothReset()
    TrackerBaseFrame:OnProfileChange()
    -- Lines kept across the reset would otherwise keep the old profile's smoothing, width, colors and visibility.
    WaypointRenderer.RedrawAll()
    QuestieWaypoints.Refresh()
    CommsVisibility:ScheduleSnapshot("PROFILE_CHANGED")
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "Switched Ace Profile!")
end

---@class QuestieColor
---@field hex string Six-character RGB hex color used in WoW color escape sequences.
---@field rgb number[] Normalized RGB components, ordered as `{r, g, b}` for WoW tooltip APIs.

---@alias QuestieNamedColor
---| "red"
---| "gray"
---| "purple"
---| "blue"
---| "lightBlue"
---| "reputationBlue"
---| "repeatableBlue"
---| "yellow"
---| "orange"
---| "green"
---| "white"
---| "gold"
---| "lime"
---| "pvpRed"

---Creates a named color entry from a six-character RGB hex string.
---@param hex string Six-character RGB hex color.
---@return QuestieColor color
local function Color(hex)
    local r, g, b = string.match(hex, "^(%x%x)(%x%x)(%x%x)$")

    return {
        hex = hex,
        rgb = {tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255},
    }
end

---@type table<QuestieNamedColor, QuestieColor>
local COLORS = {
    red = Color("ff0000"),
    gray = Color("a6a6a6"),
    purple = Color("B900FF"),
    blue = Color("0000FF"),
    lightBlue = Color("00BBFF"),
    reputationBlue = Color("8080ff"),
    repeatableBlue = Color("21CCE7"),
    yellow = Color("ffff00"),
    orange = Color("FF6F22"),
    green = Color("00ff00"),
    white = Color("ffffff"),
    gold = Color("ffd100"), -- this is the default game color
    lime = Color("6ce314"), -- holiday green
    pvpRed = Color("E35639"),
}

---Colorizes a string with a color code.
---@param str string @The string to colorize.
---@param color QuestieNamedColor|string? @Named color or hex string in the format "RRGGBB".
---@return string colorizedText
function QuestieSmazak:Colorize(str, color)
    if not color then
        color = "yellow"
    end

    local namedColor = COLORS[color]
    local hex = namedColor and namedColor.hex or color

    return "|cFF" .. hex .. str .. "|r"
end

---Returns the requested color as normalized RGB components.
---@param color string? @Named color, "RRGGBB", "AARRGGBB", or "|cAARRGGBB..." color string.
---@return number? r @Red component, or nil for invalid input.
---@return number? g @Green component, or nil for invalid input.
---@return number? b @Blue component, or nil for invalid input.
function QuestieSmazak:ColorizeRGB(color)
    if color == nil then
        color = "yellow"
    end

    local namedColor = COLORS[color]
    if namedColor then
        return namedColor.rgb[1], namedColor.rgb[2], namedColor.rgb[3]
    end

    if type(color) ~= "string" then
        return nil, nil, nil
    end

    local hex = string.match(color, "^|[cC]%x%x(%x%x%x%x%x%x)") or string.match(color, "^%x%x(%x%x%x%x%x%x)$") or color
    if not string.match(hex, "^%x%x%x%x%x%x$") then
        return nil, nil, nil
    end

    local rgb = Color(hex).rgb
    return rgb[1], rgb[2], rgb[3]
end

function QuestieSmazak:GetClassColor(class)
    class = string.lower(class);

    if class == 'druid' then
        return '|cFFFF7D0A';
    elseif class == 'hunter' then
        return '|cFFABD473';
    elseif class == 'mage' then
        return '|cFF69CCF0';
    elseif class == 'paladin' then
        return '|cFFF58CBA';
    elseif class == 'priest' then
        return '|cFFFFFFFF';
    elseif class == 'rogue' then
        return '|cFFFFF569';
    elseif class == 'shaman' then
        return '|cFF0070DE';
    elseif class == 'warlock' then
        return '|cFF9482C9';
    elseif class == 'warrior' then
        return '|cFFC79C6E';
    else
        return '|cffff0000'; -- error red
    end
end

function QuestieSmazak.Error(...)
    QuestieSmazak:Print("|cffff0000[ERROR]|r", ...)
end

function QuestieSmazak.Warning(...)
    if QuestieSmazak.db.profile.debugEnabled then -- prints regardless of "debugPrint" toggle
        QuestieSmazak:Print("|cffffff00[WARNING]|r", ...)
    end
end

-- Global debug levels
-- When adding a new level here it MUST be assigned a corresponding number and name in
-- `debugLevel.values` of QuestieOptionsAdvanced.lua as well as text in QuestieSmazak.Debug below
QuestieSmazak.DEBUG_CRITICAL = 2 ^ 0
QuestieSmazak.DEBUG_ELEVATED = 2 ^ 1
QuestieSmazak.DEBUG_INFO = 2 ^ 2
QuestieSmazak.DEBUG_DEVELOP = 2 ^ 3
QuestieSmazak.DEBUG_SPAM = 2 ^ 4

function QuestieSmazak.Debug(msgDebugLevel, ...)
    if (QuestieSmazak.db.profile.debugEnabled) then
        local optionsDebugLevel = QuestieSmazak.db.profile.debugLevel or 0 -- 0 for fallback on Forever

        if (band(optionsDebugLevel, msgDebugLevel) == 0) or (not QuestieSmazak.db.profile.debugEnabledPrint) then
            return
        end

        local prefix = ""
        if (band(msgDebugLevel, QuestieSmazak.DEBUG_CRITICAL) ~= 0) then prefix = prefix.."|cff00f2e6[CRITICAL]|r" end
        if (band(msgDebugLevel, QuestieSmazak.DEBUG_ELEVATED) ~= 0) then prefix = prefix.."|cffebf441[ELEVATED]|r" end
        if (band(msgDebugLevel, QuestieSmazak.DEBUG_INFO) ~= 0) then prefix = prefix.."|cff00bc32[INFO]|r" end
        if (band(msgDebugLevel, QuestieSmazak.DEBUG_DEVELOP) ~= 0) then prefix = prefix.."|cff7c83ff[DEVELOP]|r" end
        if (band(msgDebugLevel, QuestieSmazak.DEBUG_SPAM) ~= 0) then prefix = prefix.."|cffff8484[SPAM]|r" end

        QuestieSmazak:Print(prefix, ...)
    end
end

QuestieSmazak.icons = {
    ["slay"] = "Interface\\Addons\\QuestieSmazak\\Icons\\slay.blp",
    ["loot"] = "Interface\\Addons\\QuestieSmazak\\Icons\\loot.blp",
    ["event"] = "Interface\\Addons\\QuestieSmazak\\Icons\\event.blp",
    ["object"] = "Interface\\Addons\\QuestieSmazak\\Icons\\object.blp",
    ["talk"] = "Interface\\Addons\\QuestieSmazak\\Icons\\chatbubblegossipicon.blp",
    ["available"] = "Interface\\Addons\\QuestieSmazak\\Icons\\available.blp",
    ["available_gray"] = "Interface\\Addons\\QuestieSmazak\\Icons\\available_gray.blp",
    ["complete"] = "Interface\\Addons\\QuestieSmazak\\Icons\\complete.blp",
    ["incomplete"] = "Interface\\Addons\\QuestieSmazak\\Icons\\incomplete.blp",
    ["interact"] = "Interface\\Addons\\QuestieSmazak\\Icons\\interact.blp",
    ["mount_up"] = "Interface\\Addons\\QuestieSmazak\\Icons\\mount_up.blp",
    ["glow"] = "Interface\\Addons\\QuestieSmazak\\Icons\\glow.blp",
    ["repeatable"] = "Interface\\Addons\\QuestieSmazak\\Icons\\repeatable.blp",
    ["repeatable_complete"] = "Interface\\Addons\\QuestieSmazak\\Icons\\repeatable_complete.blp",
    ["eventquest"] = "Interface\\Addons\\QuestieSmazak\\Icons\\eventquest.blp",
    ["eventquest_complete"] = "Interface\\Addons\\QuestieSmazak\\Icons\\eventquest_complete.blp",
    ["pvpquest"] = "Interface\\Addons\\QuestieSmazak\\Icons\\pvpquest.blp",
    ["pvpquest_complete"] = "Interface\\Addons\\QuestieSmazak\\Icons\\pvpquest_complete.blp",
    ["node"] = "Interface\\Addons\\QuestieSmazak\\Icons\\node.tga",
    ["player"] = "Interface\\WorldMap\\WorldMapPartyIcon",
    ["fav"] = "Interface\\Addons\\QuestieSmazak\\Icons\\fav.tga",
    ["hand"] = "Interface\\Addons\\QuestieSmazak\\Icons\\hand.blp",
    ["faction_alliance"] = "Interface\\Addons\\QuestieSmazak\\Icons\\icon_alliance.tga",
    ["faction_horde"] = "Interface\\Addons\\QuestieSmazak\\Icons\\icon_horde.tga",
    ["loot_mono"] = "Interface\\Addons\\QuestieSmazak\\Icons\\loot_mono.tga",
    ["node_cut"] = "Interface\\Addons\\QuestieSmazak\\Icons\\node_cut.tga",
    ["object_mono"] = "Interface\\Addons\\QuestieSmazak\\Icons\\object_mono.tga",
    ["route"] = "Interface\\Addons\\QuestieSmazak\\Icons\\route.tga",
    ["slay_mono"] = "Interface\\Addons\\QuestieSmazak\\Icons\\slay_mono.tga",
    ["sod_rune"] = "Interface\\Addons\\QuestieSmazak\\Icons\\sod_rune.tga",
    ["startend"] = "Interface\\Addons\\QuestieSmazak\\Icons\\startend.tga",
    ["startendstart"] = "Interface\\Addons\\QuestieSmazak\\Icons\\startendstart.tga",
    ["tracker_clean"] = "Interface\\Addons\\QuestieSmazak\\Icons\\tracker_clean.tga",
    ["tracker_close"] = "Interface\\Addons\\QuestieSmazak\\Icons\\tracker_close.tga",
    ["tracker_database"] = "Interface\\Addons\\QuestieSmazak\\Icons\\tracker_database.tga",
    ["tracker_giver"] = "Interface\\Addons\\QuestieSmazak\\Icons\\tracker_giver.tga",
    ["tracker_quests"] = "Interface\\Addons\\QuestieSmazak\\Icons\\tracker_quests.tga",
    ["tracker_search"] = "Interface\\Addons\\QuestieSmazak\\Icons\\tracker_search.tga",
    ["tracker_settings"] = "Interface\\Addons\\QuestieSmazak\\Icons\\tracker_settings.tga",
    ["node_fish"] = "Interface\\Addons\\QuestieSmazak\\Icons\\node_fish.blp",
    ["node_herb"] = "Interface\\Addons\\QuestieSmazak\\Icons\\node_herb.blp",
    ["node_ore"] = "Interface\\Addons\\QuestieSmazak\\Icons\\node_ore.blp",
    ["chest"] = "Interface\\Addons\\QuestieSmazak\\Icons\\chest.blp",
    ["petbattle"] = "Interface\\Addons\\QuestieSmazak\\Icons\\petbattle.png",
}

QuestieSmazak.usedIcons = {}

-- ! Keep these continuous 1...n and copy changes to DRAW_ORDER_BY_ICON_TYPE_LOOKUP in QuestieMapUtils.lua
QuestieSmazak.ICON_TYPE_SLAY = 1
QuestieSmazak.ICON_TYPE_LOOT = 2
QuestieSmazak.ICON_TYPE_EVENT = 3
QuestieSmazak.ICON_TYPE_OBJECT = 4
QuestieSmazak.ICON_TYPE_TALK = 5
QuestieSmazak.ICON_TYPE_AVAILABLE = 6
QuestieSmazak.ICON_TYPE_AVAILABLE_GRAY = 7
QuestieSmazak.ICON_TYPE_COMPLETE = 8
QuestieSmazak.ICON_TYPE_GLOW = 9
QuestieSmazak.ICON_TYPE_REPEATABLE = 10
QuestieSmazak.ICON_TYPE_REPEATABLE_COMPLETE = 11
QuestieSmazak.ICON_TYPE_INCOMPLETE = 12
QuestieSmazak.ICON_TYPE_EVENTQUEST = 13
QuestieSmazak.ICON_TYPE_EVENTQUEST_COMPLETE = 14
QuestieSmazak.ICON_TYPE_PVPQUEST = 15
QuestieSmazak.ICON_TYPE_PVPQUEST_COMPLETE = 16
QuestieSmazak.ICON_TYPE_INTERACT = 17
QuestieSmazak.ICON_TYPE_SODRUNE = 18
QuestieSmazak.ICON_TYPE_MOUNT_UP = 19
QuestieSmazak.ICON_TYPE_NODE_FISH = 20
QuestieSmazak.ICON_TYPE_NODE_HERB = 21
QuestieSmazak.ICON_TYPE_NODE_ORE = 22
QuestieSmazak.ICON_TYPE_CHEST = 23
QuestieSmazak.ICON_TYPE_PET_BATTLE = 24

-- Load icon pathes from SavedVariables or set the default ones
function QuestieSmazak.SetIcons()
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_SLAY] = QuestieSmazak.db.profile.ICON_SLAY or QuestieSmazak.icons["slay"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_LOOT] = QuestieSmazak.db.profile.ICON_LOOT or QuestieSmazak.icons["loot"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_EVENT] = QuestieSmazak.db.profile.ICON_EVENT or QuestieSmazak.icons["event"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_OBJECT] = QuestieSmazak.db.profile.ICON_OBJECT or QuestieSmazak.icons["object"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_TALK] = QuestieSmazak.db.profile.ICON_TALK or QuestieSmazak.icons["talk"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_AVAILABLE] = QuestieSmazak.db.profile.ICON_AVAILABLE or QuestieSmazak.icons["available"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_AVAILABLE_GRAY] = QuestieSmazak.db.profile.ICON_AVAILABLE_GRAY or QuestieSmazak.icons["available_gray"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_COMPLETE] = QuestieSmazak.db.profile.ICON_COMPLETE or QuestieSmazak.icons["complete"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_INCOMPLETE] = QuestieSmazak.db.profile.ICON_INCOMPLETE or QuestieSmazak.icons["incomplete"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_GLOW] = QuestieSmazak.db.profile.ICON_GLOW or QuestieSmazak.icons["glow"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_REPEATABLE] = QuestieSmazak.db.profile.ICON_REPEATABLE or QuestieSmazak.icons["repeatable"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_REPEATABLE_COMPLETE] = QuestieSmazak.db.profile.ICON_REPEATABLE_COMPLETE or QuestieSmazak.icons["repeatable_complete"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_EVENTQUEST] = QuestieSmazak.db.profile.ICON_EVENTQUEST or QuestieSmazak.icons["eventquest"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_EVENTQUEST_COMPLETE] = QuestieSmazak.db.profile.ICON_EVENTQUEST_COMPLETE or QuestieSmazak.icons["eventquest_complete"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_PVPQUEST] = QuestieSmazak.db.profile.ICON_PVPQUEST or QuestieSmazak.icons["pvpquest"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_PVPQUEST_COMPLETE] = QuestieSmazak.db.profile.ICON_PVPQUEST_COMPLETE or QuestieSmazak.icons["pvpquest_complete"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_INTERACT] = QuestieSmazak.db.profile.ICON_INTERACT or QuestieSmazak.icons["interact"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_SODRUNE] = QuestieSmazak.icons["sod_rune"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_MOUNT_UP] = QuestieSmazak.icons["mount_up"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_NODE_FISH] = QuestieSmazak.icons["node_fish"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_NODE_HERB] = QuestieSmazak.icons["node_herb"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_NODE_ORE] = QuestieSmazak.icons["node_ore"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_CHEST] = QuestieSmazak.icons["chest"]
    QuestieSmazak.usedIcons[QuestieSmazak.ICON_TYPE_PET_BATTLE] = QuestieSmazak.db.profile.ICON_TYPE_PET_BATTLE or QuestieSmazak.icons["petbattle"]
end

function QuestieSmazak:GetIconNameFromPath(path)
    for k, v in pairs(QuestieSmazak.icons) do
        if path == v then return k end
    end
end

QuestieSmazak.LOWLEVEL_NONE = 1
QuestieSmazak.LOWLEVEL_ALL = 2
QuestieSmazak.LOWLEVEL_OFFSET = 3
QuestieSmazak.LOWLEVEL_RANGE = 4

-- Profiling is opt-in and costs a player who never enables it nothing: no wrappers are installed, no timers
-- run, and no frames are built. QuestieSmazak.lua is last in each TOC Manifest, so arming here covers every QuestieSmazak
-- module, but that is well before AceDB exists - hence a plain saved variable rather than a profile setting.
-- Every TOC declares LoadSavedVariablesFirst, so the flag is already populated by the time this runs.
-- Optional profiling must never prevent Game Cache Validation or Addon Load callbacks.
-- "== true" and not truthiness, because QuestieSmazakLoader and the pre-hook armed on exactly that test hundreds
-- of lines ago: any looser test here would start a session those two never instrumented for.
if QuestieSmazakProfilerEnabled == true then
    local profilerStarted, profilerArmed, rejectionReported = pcall(QuestieProfiler.StartStartup, QuestieProfiler, true)
    if not profilerStarted then
        QuestieSmazak.Error("QuestieProfiler failed during Addon Load", profilerArmed)
    elseif profilerArmed ~= true and rejectionReported ~= true then
        -- Some ownership failures return quietly. Loud engine rejections set rejectionReported so this caller
        -- does not print a second, less useful error for the same failure.
        QuestieSmazak.Error("QuestieProfiler did not arm during Addon Load")
    end
end

-- Start checking the game's cache.
QuestieValidateGameCache.StartCheck()

-- QuestieSmazak.lua is the last file every TOC lists, so this line runs when addon load is complete and nothing
-- else. The load-timing window must close here, synchronously: ADDON_LOADED fires later, behind the
-- pre-hook's sweep and AceAddon's OnInitialize in handler order, and closing there charged their work to
-- this file's row. Closing and publishing stay separate so a missing profiler method cannot leave the loader
-- timing later runtime module calls as if they were still part of addon load.
if QuestieSmazakProfilerEnabled == true then
    local loadTimingClosed, loadTimingCloseError = pcall(QuestieSmazakLoader.FinishLoadTimings, QuestieSmazakLoader)
    if not loadTimingClosed then
        QuestieSmazak.Error("QuestieProfiler failed to close the load-timing capture", loadTimingCloseError)
    else
        local loadTimingsImported, loadTimingImportError =
            pcall(QuestieProfiler.ImportLoadTimings, QuestieProfiler)
        if not loadTimingsImported then
            QuestieSmazak.Error("QuestieProfiler failed to import load timings", loadTimingImportError)
        end
    end
end
