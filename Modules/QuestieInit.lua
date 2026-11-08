---@class QuestieInit
local QuestieInit = QuestieSmazakLoader:CreateModule("QuestieInit")
local _QuestieInit = QuestieInit.private

---@type ThreadLib
local ThreadLib = QuestieSmazakLoader:ImportModule("ThreadLib")
---@type Expansions
local Expansions = QuestieSmazakLoader:ImportModule("Expansions")

---@type QuestEventHandler
local QuestEventHandler = QuestieSmazakLoader:ImportModule("QuestEventHandler")
---@type QuestieAPI
local QuestieAPI = QuestieSmazakLoader:ImportModule("QuestieAPI")
---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")
---@type ZoneDB
local ZoneDB = QuestieSmazakLoader:ImportModule("ZoneDB")
---@type Migration
local Migration = QuestieSmazakLoader:ImportModule("Migration")
---@type QuestieProfessions
local QuestieProfessions = QuestieSmazakLoader:ImportModule("QuestieProfessions")
---@type QuestieTracker
local QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker")
---@type QuestieMap
local QuestieMap = QuestieSmazakLoader:ImportModule("QuestieMap")
---@type QuestieLib
local QuestieLib = QuestieSmazakLoader:ImportModule("QuestieLib")
---@type QuestiePlayer
local QuestiePlayer = QuestieSmazakLoader:ImportModule("QuestiePlayer")
---@type QuestieMenu
local QuestieMenu = QuestieSmazakLoader:ImportModule("QuestieMenu")
---@type QuestieQuest
local QuestieQuest = QuestieSmazakLoader:ImportModule("QuestieQuest")
---@type IsleOfQuelDanas
local IsleOfQuelDanas = QuestieSmazakLoader:ImportModule("IsleOfQuelDanas")
---@type EventHandler
local EventHandler = QuestieSmazakLoader:ImportModule("EventHandler")
---@type QuestieJourney
local QuestieJourney = QuestieSmazakLoader:ImportModule("QuestieJourney")
---@type HBDHooks
local HBDHooks = QuestieSmazakLoader:ImportModule("HBDHooks")
---@type GamepadMapHover
local GamepadMapHover = QuestieSmazakLoader:ImportModule("GamepadMapHover")
---@type ChatFilter
local ChatFilter = QuestieSmazakLoader:ImportModule("ChatFilter")
---@type QuestieShutUp
local QuestieShutUp = QuestieSmazakLoader:ImportModule("QuestieShutUp")
---@type Hooks
local Hooks = QuestieSmazakLoader:ImportModule("Hooks")
---@type QuestieValidateGameCache
local QuestieValidateGameCache = QuestieSmazakLoader:ImportModule("QuestieValidateGameCache")
---@type MinimapIcon
local MinimapIcon = QuestieSmazakLoader:ImportModule("MinimapIcon")
---@type DailyQuestComms
local DailyQuestComms = QuestieSmazakLoader:ImportModule("DailyQuestComms")
---@type CommsVisibility
local CommsVisibility = QuestieSmazakLoader:ImportModule("CommsVisibility")
---@type QuestieComms
local QuestieComms = QuestieSmazakLoader:ImportModule("QuestieComms");
---@type QuestieOptions
local QuestieOptions = QuestieSmazakLoader:ImportModule("QuestieOptions");
---@type QuestieCoords
local QuestieCoords = QuestieSmazakLoader:ImportModule("QuestieCoords");
---@type QuestieTooltips
local QuestieTooltips = QuestieSmazakLoader:ImportModule("QuestieTooltips");
---@type QuestieLink
local QuestieLink = QuestieSmazakLoader:ImportModule("QuestieLink");
---@type QuestieDBMIntegration
local QuestieDBMIntegration = QuestieSmazakLoader:ImportModule("QuestieDBMIntegration");
---@type TrackerQuestTimers
local TrackerQuestTimers = QuestieSmazakLoader:ImportModule("TrackerQuestTimers")
---@type ChallengeModeTimer
local ChallengeModeTimer = QuestieSmazakLoader:ImportModule("ChallengeModeTimer")
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieSmazakLoader:ImportModule("QuestieCombatQueue")
---@type QuestieSlash
local QuestieSlash = QuestieSmazakLoader:ImportModule("QuestieSlash")
---@type QuestXP
local QuestXP = QuestieSmazakLoader:ImportModule("QuestXP")
---@type Tutorial
local Tutorial = QuestieSmazakLoader:ImportModule("Tutorial")
---@type Phasing
local Phasing = QuestieSmazakLoader:ImportModule("Phasing")
---@type WorldMapButton
local WorldMapButton = QuestieSmazakLoader:ImportModule("WorldMapButton")
---@type AvailableQuests
local AvailableQuests = QuestieSmazakLoader:ImportModule("AvailableQuests")
---@type DailyQuests
local DailyQuests = QuestieSmazakLoader:ImportModule("DailyQuests")
---@type SeasonOfDiscovery
local SeasonOfDiscovery = QuestieSmazakLoader:ImportModule("SeasonOfDiscovery")
---@type WatchFrameHook
local WatchFrameHook = QuestieSmazakLoader:ImportModule("WatchFrameHook")
---@type QuestLogCache
local QuestLogCache = QuestieSmazakLoader:ImportModule("QuestLogCache")
---@type ContentPhases
local ContentPhases = QuestieSmazakLoader:ImportModule("ContentPhases")
---@type DropDB
local DropDB = QuestieSmazakLoader:ImportModule("DropDB")
---@type QuestieAnnounce
local QuestieAnnounce = QuestieSmazakLoader:ImportModule("QuestieAnnounce")
---@type CommsEncoding
local CommsEncoding = QuestieSmazakLoader:ImportModule("CommsEncoding")
---@type QuestieDB
local QuestieDB = QuestieSmazakLoader:ImportModule("QuestieDB")
---@type VersionCheckDB
local VersionCheckDB = QuestieSmazakLoader:ImportModule("VersionCheckDB")
---@type QuestieCorrections
local QuestieCorrections = QuestieSmazakLoader:ImportModule("QuestieCorrections")
---@type Townsfolk
local Townsfolk = QuestieSmazakLoader:ImportModule("Townsfolk")
---@type QuestieEvent
local QuestieEvent = QuestieSmazakLoader:ImportModule("QuestieEvent")

---@type QuestieStatus
local QuestieStatus = QuestieSmazakLoader:ImportModule("QuestieStatus")
---@type SourceModeStatus
local SourceModeStatus = QuestieSmazakLoader:ImportModule("SourceModeStatus")

local coYield = coroutine.yield
local startupFailed = false
local addonLoadedTicker, loginTicker

---Latch the first failure and stop both startup jobs, including one suspended inside a yielding dependency.
local function _StopStartup(id, report, action)
    if startupFailed then return end
    startupFailed = true
    QuestieSmazak.started = false
    if QuestieSmazak.API then QuestieSmazak.API.isReady = false end
    if addonLoadedTicker then addonLoadedTicker:Cancel() end
    if loginTicker then loginTicker:Cancel() end
    -- Lua errors can be nil or mutable objects; capture text before tooltip formatting.
    QuestieStatus.Set(id, {
        severity = QuestieStatus.Severity.Error,
        message = "QuestieSmazak could not start: %s",
        args = {tostring(report)},
        action = action or "Update QuestieSmazak and QuestieDB, then reload the UI.",
    })
end

---Support checks return diagnostics instead of throwing; retain their once-only chat report.
---@param valid boolean|nil @Only explicit false means validation failed.
---@param report string?
---@return boolean stopped
local function _StopOnSupportFailure(valid, report)
    if valid == false then
        if not startupFailed then
            _StopStartup("startup.support-validation", report)
            QuestieSmazak.Error(report)
        end
        return true
    end
    return startupFailed
end

-- ********************************************************************************
-- Start of QuestieInit.Stages ******************************************************

-- stage worker functions. Most are coroutines.
QuestieInit.Stages = {}

---@async
QuestieInit.Stages[1] = function() -- run as a coroutine
    if startupFailed then return false end
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_CRITICAL, "[QuestieInit:Stage1] Starting the real init.")

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage1] UI Locale initializing.")
    -- This needs to happen after ADDON_LOADED.
    l10n.InitializeUILocale()

    -- This gates login work, not the provider bindings already made during TOC file loading.
    local contractSupported, contractError = VersionCheckDB.Check()
    if not contractSupported then
        _StopStartup("startup.provider-contract", contractError)
        error(contractError, 0)
    end

    if type(LibQuestieDB.l10n) ~= "table" or type(LibQuestieDB.l10n.SetCorrection) ~= "function" then
        local report = "QuestieSmazak requires QuestieDB localization corrections. Update QuestieDB."
        _StopStartup("startup.provider-localization", report)
        error(report, 0)
    end

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage1] Entity data preloading.")
    -- After the provider gates, before the steps below: locale overrides and Policy Correction
    -- writes read entity IDs, which would otherwise load several types in one Source mode resume.
    QuestieDB.PreloadEntityData()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage1] Entity locale forwarding.")
    -- Entity localization is provider-owned; the effective UI locale is forwarded outside l10n.
    local effectiveLocale = l10n:GetUILocale()
    LibQuestieDB.l10n.SetLocale(effectiveLocale)
    l10n.PublishLocaleOverrideEntityNames()
    coYield()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage1] QuestieSmazak policy initializing.")
    -- Blacklists plus the static Policy Correction slots (gathering nodes, Content Phase).
    QuestieCorrections.Initialize()
    coYield()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage1] QuestieDB initializing.")
    -- Binds the ID maps and resets the caches against the applied composed view; queries and
    -- Objective Order were bound when QuestieDB.lua loaded.
    if _StopOnSupportFailure(QuestieDB.Initialize()) then return false end
    coYield()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage1] Townsfolk building.")
    -- Rebuilt from composed reads on every login until the provider exposes a stable data revision.
    Townsfolk.Initialize()
    Townsfolk:BuildCharacterTownsfolk()
    coYield()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage1] QuestieEvent initializing.")
    -- After QuestieDB, so the calendar callback's Darkmoon apply refreshes bound pointers and caches.
    QuestieEvent.Initialize()
    coYield()
end

---@async
---@return false|nil stopped
QuestieInit.Stages[2] = function()
    if startupFailed then return false end
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_INFO, "[QuestieInit:Stage2] Stage 2 start.")

    local objectDB = LibQuestieDB.Object
    if type(objectDB) ~= "table" or type(objectDB.BuildNameIndexAsync) ~= "function" then
        local report = "QuestieSmazak requires QuestieDB asynchronous Object name indexing. Update QuestieDB."
        _StopStartup("startup.provider-object-index", report)
        error(report, 0)
    end

    -- Object tooltips use database-wide name uniqueness for zone filtering even when Object IDs
    -- are hidden. Warm the provider index after locale and policy setup, not on the first hover.
    -- Require yielding builds to avoid the reported script timeout; smaller Hardcore batches
    -- keep each resume short. The provider returns only when the complete index is ready.
    objectDB.BuildNameIndexAsync(QuestieSmazak.IsHardcore and 250 or 1000)

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage2] QuestiePlayer initializing.")
    QuestiePlayer:Initialize()
    coYield()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage2] QuestieJourney initializing.")
    QuestieJourney:Initialize()

    local keepWaiting = true
    -- We had users reporting that a quest did not reach a valid state in the game cache.
    -- In this case we still need to continue the initialization process, even though a specific quest might be bugged
    C_Timer.After(3, function()
        if keepWaiting then
            QuestieSmazak.Debug(QuestieSmazak.DEBUG_CRITICAL, "[QuestieInit:Stage2] Timeout waiting for Game Cache validation. Continuing.")
            keepWaiting = false
        end
    end)

    -- Continue to the next Init Stage once Game Cache's Questlog is good
    while (not QuestieValidateGameCache.IsCacheGood()) and keepWaiting do
        coYield()
    end
    keepWaiting = false
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage2] Game cache good.")
end

QuestieInit.Stages[3] = function() -- run as a coroutine
    if startupFailed then return false end
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_INFO, "[QuestieInit:Stage3] Stage 3 start.")

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage3] QuestieTooltips initializing.")
    QuestieTooltips:Initialize()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage3] QuestieLink initializing.")
    QuestieLink.Initialize()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage3] DropDB initializing.")
    if _StopOnSupportFailure(DropDB:Initialize()) then return false end

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage3] Timers initializing.")
    TrackerQuestTimers:Initialize()
    if Expansions.Current >= Expansions.MoP then
        ChallengeModeTimer.Initialize()
    end

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage3] QuestieMap initializing.")
    QuestieMap:InitializeQueue()

    coYield()
    QuestieQuest:Initialize()
    coYield()

    -- Fill the QuestLogCache for first time
    local cacheMiss, _, questIdsChecked = QuestLogCache.CheckForChanges(nil)

    if cacheMiss then
        QuestieSmazak.Debug(QuestieSmazak.DEBUG_CRITICAL, "QuestieInit: Game Cache did not fill in time, waiting for valid cache.")
        questIdsChecked = QuestieInit.WaitForValidGameCache()
    end

    QuestEventHandler.InitQuestLogStates(questIdsChecked)
    coYield()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage3] Hydrating quest log for the first time.")
    QuestieQuest:GetAllQuestIds()
    coYield()

    QuestieCombatQueue.Initialize()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage3] QuestieTracker initializing.")
    QuestieTracker.Initialize()
    Hooks:HookQuestLogTitle()
    coYield()

    QuestEventHandler:Initialize()
    coYield()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage3] QuestieComms initializing.")
    CommsEncoding.Init()
    CommsVisibility:Initialize()
    DailyQuestComms.Initialize()
    if (not QuestieSmazak.IsClassic) then
        -- There are no random daily quests on Era, HC or SoD so we skip this
        DailyQuestComms.RequestUnavailableDailyQuests(true)
    end
    QuestieComms:Initialize()
    coYield()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage3] QuestieDBM initializing.")
    if QuestieSmazak.db.profile.dbmHUDEnable then
        QuestieDBMIntegration:EnableHUD()
    end

    WorldMapButton.Initialize()
    Townsfolk.PostBoot()
    coYield()

    QuestieAnnounce:InitializeLogoFilter()
    ChatFilter:RegisterEvents()

    local dateToday = date("%y-%m-%d")

    if (not QuestieSmazak.IsSoD) and QuestieSmazak.db.profile.showAQWarEffortQuests and ((not QuestieSmazak.db.profile.aqWarningPrintDate) or (QuestieSmazak.db.profile.aqWarningPrintDate < dateToday)) then
        QuestieSmazak.db.profile.aqWarningPrintDate = dateToday
        C_Timer.After(2, function()
            print("|cffff0000-----------------------------|r")
            QuestieSmazak:Print("|cffff0000" ..
                l10n("The AQ War Effort quests are shown for you. If your server is done you can hide those quests in the Icons settings of QuestieSmazak!") .. "|r");
            print("|cffff0000-----------------------------|r")
        end)
    end

    if QuestieSmazak.IsTBC and ContentPhases.activePhases.TBC == 5 and (not QuestieSmazak.db.profile.isIsleOfQuelDanasPhaseReminderDisabled) then
        C_Timer.After(2, function()
            QuestieSmazak:Print(l10n("Current active phase of Isle of Quel'Danas is '%s'. Check the General settings to change the phase or disable this message.",
                IsleOfQuelDanas.localizedPhaseNames[QuestieSmazak.db.global.isleOfQuelDanasPhase]))
        end)
    end

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage3] QuestieMenu initializing.")
    coYield()
    QuestieMenu:OnLogin()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage3] DailyQuests initializing.")
    coYield()
    DailyQuests.Initialize()

    coYield()
    if QuestieSmazak.db.profile.debugEnabled then
        QuestieSmazakLoader:PopulateGlobals()
    end

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage1] Tutorial initializing.")
    Tutorial.Initialize()
    coYield()

    if startupFailed then return false end
    QuestieSmazak.started = true

    -- We only update this if QuestieSmazak fully loads to make sure we don't update it on crashes/fast reloads
    QuestieLib.UpdateLastKnownDailyReset()

    -- register events that rely on questie being initialized
    EventHandler:RegisterLateEvents()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieInit:Stage3] Drawing available quests.")
    -- Last, because it runs for a while and must not block the rest of the init.
    AvailableQuests.CalculateAndDrawAll()

    -- Let other addons know that QuestieSmazak is ready
    if startupFailed then return false end
    QuestieSmazak.API.isReady = true
    QuestieAPI.PropagateOnReady()

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_CRITICAL, "[QuestieInit:Stage3] QuestieSmazak init done.")
end

-- End of QuestieInit.Stages ******************************************************
-- ********************************************************************************


---@async
---@return false|nil stopped
function _QuestieInit.StartStageCoroutine()
    for i = 1, #QuestieInit.Stages do
        if startupFailed or QuestieInit.Stages[i]() == false then return false end
        QuestieSmazak.Debug(QuestieSmazak.DEBUG_INFO, "[QuestieInit:StartStageCoroutine] Stage " .. i .. " done.")
        coYield()
    end
end

-- The UI elements might not be loaded at this point, so we must only initialize modules that do not rely on the UI
---@return false|nil stopped
function QuestieInit.OnAddonLoaded()
    if startupFailed then return false end

    local sourceMode = SourceModeStatus.Update()

    -- Keep the provider banner unless QuestieSmazak's replacement UI has registered successfully.
    local statusUIReady = MinimapIcon:Init() == true
    local modeIndicator = LibQuestieDB and LibQuestieDB.ModeIndicator
    if sourceMode and statusUIReady and modeIndicator and type(modeIndicator.Hide) == "function" then
        modeIndicator.Hide()
    end

    QuestieSmazak.SetIcons()

    Migration:Migrate()

    if _StopOnSupportFailure(ZoneDB.Initialize()) then return false end
    AvailableQuests.Initialize()
    QuestieProfessions:Init()
    if _StopOnSupportFailure(QuestXP.Init()) then return false end

    -- This block still runs on a later frame. Submit it only after synchronous support checks pass.
    addonLoadedTicker = ThreadLib.Thread(function()
        if startupFailed then return end
        HBDHooks:Init()
        if QuestieSmazak.IsForever then
            GamepadMapHover.Initialize()
        end
        QuestieShutUp:ToggleFilters(QuestieSmazak.db.profile.questieShutUp)
        QuestieCoords:Initialize()
        QuestieSlash.RegisterSlashCommands()

        IsleOfQuelDanas.Initialize() -- This has to happen before option init
        QuestieOptions.Initialize()
    end, 0, "Error during AddonLoaded initialization!", nil, function(err)
        _StopStartup("startup.addon-loaded", err, "Reload the UI. If the problem persists, report this error.")
    end)

    Phasing.Initialize()

    if QuestieSmazak.IsSoD then
        SeasonOfDiscovery.Initialize()
    end
end

-- called by the PLAYER_LOGIN event handler
---@return false|nil stopped
function QuestieInit:Init()
    if startupFailed then return false end
    loginTicker = ThreadLib.Thread(_QuestieInit.StartStageCoroutine, 0, l10n("Error during initialization!"), nil, function(err)
        _StopStartup("startup.login", err, "Reload the UI. If the problem persists, report this error.")
    end)

    if QuestieSmazak.db.profile.trackerEnabled then
        -- This needs to be called ASAP otherwise tracked Achievements in the Blizzard WatchFrame shows upon login
        WatchFrameHook.Hide()

        if Expansions.Current < Expansions.Wotlk and ScrollFrame_OnScrollRangeChanged then
            -- Need to hook this ASAP otherwise the scroll bars show up
            hooksecurefunc("ScrollFrame_OnScrollRangeChanged", function()
                if QuestieSmazakTrackedQuestsScrollFrame then
                    QuestieSmazakTrackedQuestsScrollFrame.ScrollBar:Hide()
                end
            end)
        end
    end
end

--- We really want to wait for the cache to be filled before we continue.
--- Other addons (e.g. ATT) can interfere with the cache and we need to make sure it's correct.
---@return table<number>
function QuestieInit.WaitForValidGameCache()
    local doWait = true
    local retries = 0
    local questIdsChecked

    local timer
    timer = C_Timer.NewTicker(1, function()
        local cacheMiss, _, newQuestIdsChecked = QuestLogCache.CheckForChanges(nil)
        if (not cacheMiss) or retries >= 3 then
            if retries == 3 then
                QuestieSmazak.Debug(QuestieSmazak.DEBUG_CRITICAL, "QuestieInit: Game Cache did not become valid in 3 seconds, continuing with initialization.")
            end
            doWait = false
            timer:Cancel()
        end
        questIdsChecked = newQuestIdsChecked
        retries = retries + 1
    end)

    while doWait do
        coYield()
    end

    return questIdsChecked
end
