---@type QuestieCompat
local QuestieCompat = QuestieSmazakLoader:ImportModule("QuestieCompat")

---@class EventHandler
local EventHandler = QuestieSmazakLoader:CreateModule("EventHandler")
local _EventHandler = {}

-------------------------
--Import modules.
-------------------------
---@type Expansions
local Expansions = QuestieSmazakLoader:ImportModule("Expansions")
---@type QuestEventHandler
local QuestEventHandler = QuestieSmazakLoader:ImportModule("QuestEventHandler")
---@type QuestLogCache
local QuestLogCache = QuestieSmazakLoader:ImportModule("QuestLogCache")
---@type AchievementEventHandler
local AchievementEventHandler = QuestieSmazakLoader:ImportModule("AchievementEventHandler")
---@type GroupEventHandler
local GroupEventHandler = QuestieSmazakLoader:ImportModule("GroupEventHandler")
---@type QuestieJourney
local QuestieJourney = QuestieSmazakLoader:ImportModule("QuestieJourney")
---@type QuestieProfessions
local QuestieProfessions = QuestieSmazakLoader:ImportModule("QuestieProfessions")
---@type QuestieTracker
local QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker")
---@type TrackerBaseFrame
local TrackerBaseFrame = QuestieSmazakLoader:ImportModule("TrackerBaseFrame")
---@type TrackerQuestFrame
local TrackerQuestFrame = QuestieSmazakLoader:ImportModule("TrackerQuestFrame")
---@type TrackerRecipes
local TrackerRecipes = QuestieSmazakLoader:ImportModule("TrackerRecipes")
---@type TrackerUtils
local TrackerUtils = QuestieSmazakLoader:ImportModule("TrackerUtils")
---@type TrackerSuperTrack
local TrackerSuperTrack = QuestieSmazakLoader:ImportModule("TrackerSuperTrack")
---@type QuestieReputation
local QuestieReputation = QuestieSmazakLoader:ImportModule("QuestieReputation")
---@type QuestieNameplate
local QuestieNameplate = QuestieSmazakLoader:ImportModule("QuestieNameplate")
---@type QuestieMap
local QuestieMap = QuestieSmazakLoader:ImportModule("QuestieMap")
---@type QuestiePlayer
local QuestiePlayer = QuestieSmazakLoader:ImportModule("QuestiePlayer")
---@type AutoQuesting
local AutoQuesting = QuestieSmazakLoader:ImportModule("AutoQuesting")
---@type QuestieAnnounce
local QuestieAnnounce = QuestieSmazakLoader:ImportModule("QuestieAnnounce")
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieSmazakLoader:ImportModule("QuestieCombatQueue")
---@type QuestieInit
local QuestieInit = QuestieSmazakLoader:ImportModule("QuestieInit")
---@type MinimapIcon
local MinimapIcon = QuestieSmazakLoader:ImportModule("MinimapIcon")
---@type QuestgiverFrame
local QuestgiverFrame = QuestieSmazakLoader:ImportModule("QuestgiverFrame")
---@type QuestieDebugOffer
local QuestieDebugOffer = QuestieSmazakLoader:ImportModule("QuestieDebugOffer")
---@type AvailableQuests
local AvailableQuests = QuestieSmazakLoader:ImportModule("AvailableQuests")
---@type QuestieMenu
local QuestieMenu = QuestieSmazakLoader:ImportModule("QuestieMenu")
---@type WatchFrameHook
local WatchFrameHook = QuestieSmazakLoader:ImportModule("WatchFrameHook")
---@type AutoCompleteFrame
local AutoCompleteFrame = QuestieSmazakLoader:ImportModule("AutoCompleteFrame")
---@type QuestieOptionsEngine
local QuestieOptionsEngine = QuestieSmazakLoader:ImportModule("QuestieOptionsEngine")

local questAcceptedMessage = string.gsub(ERR_QUEST_ACCEPTED_S, "(%%s)", "(.+)")
local questCompletedMessage = string.gsub(ERR_QUEST_COMPLETE_S, "(%%s)", "(.+)")
--* Calculated in _EventHandler:PlayerLogin()
---en/br/es/fr/gb/it/mx: "You are now %s with %s." (e.g. "You are now Honored with Stormwind."), all other languages are very alike
local FACTION_STANDING_CHANGED_PATTERN

function EventHandler:RegisterEarlyEvents()
    QuestieSmazak:RegisterEvent("PLAYER_LOGIN", _EventHandler.PlayerLogin)

    local questPOIHandled = false
    QuestieSmazak:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isInitialLogin, isReloadingUi)
        QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] PLAYER_ENTERING_WORLD")
        if not questPOIHandled then
            if GetCVar("questPOI") == "0" and WorldMapFrame:IsShown() then
                -- We need to manually hide the map, because having questPOI set to 0 will open it on login, thanks to Blizzard.
                -- Don't use WorldMapFrame:Hide() that will cause taint issues
                HideUIPanel(WorldMapFrame)
                tinsert(UISpecialFrames, "WorldMapFrame") -- This helps to not taint when in combat on login
            end
            questPOIHandled = true
        end

        -- Instance changes need a layout even when quests are unchanged, which quest-log checks skip:
        -- the Challenge Mode keystone after login, and the proximity sort restarting after leaving an instance.
        QuestieCombatQueue:Queue(function()
            QuestieTracker:Update()
        end)
    end)
end

function EventHandler:RegisterLateEvents()
    QuestieSmazak:RegisterEvent("PLAYER_LEVEL_UP", _EventHandler.PlayerLevelUp)
    QuestieSmazak:RegisterEvent("PLAYER_REGEN_DISABLED", _EventHandler.PlayerRegenDisabled)
    QuestieSmazak:RegisterEvent("PLAYER_REGEN_ENABLED", _EventHandler.PlayerRegenEnabled)

    -- Miscellaneous Events
    QuestieSmazak:RegisterEvent("MAP_EXPLORATION_UPDATED", _EventHandler.MapExplorationUpdated)
    QuestieSmazak:RegisterEvent("MODIFIER_STATE_CHANGED", function(...)
        _EventHandler.ModifierStateChanged(...)
    end)
    QuestieSmazak:RegisterEvent("PLAYER_ALIVE", function(...)
        QuestieTracker:UpdateDurabilityFrame()
        QuestieTracker:UpdateVoiceOverFrame()

        -- HandleZoneChanged() defers minimizedByInstance's expand while the player is a ghost.
        -- Re-run it on resurrection so the tracker restores if the player released/left the
        -- instance while dead and only became alive again after already leaving it.
        QuestieTracker.HandleZoneChanged()
    end)

    -- Events to update a players professions and reputations
    -- Skill chat can be secret; batch refreshes without retaining the chat arguments.
    local skillUpdatePending = false
    QuestieSmazak:RegisterEvent("CHAT_MSG_SKILL", function()
        if skillUpdatePending then
            return
        end

        skillUpdatePending = true
        QuestieSmazak:ScheduleTimer(function()
            skillUpdatePending = false
            _EventHandler.ChatMsgSkill()
        end, 2)
    end)
    -- Learning or unlearning a profession need not print CHAT_MSG_SKILL
    QuestieSmazak:RegisterBucketEvent("SKILL_LINES_CHANGED", 2, _EventHandler.ChatMsgSkill)
    QuestieSmazak:RegisterBucketEvent("CHAT_MSG_COMBAT_FACTION_CHANGE", 2, function()
        QuestEventHandler.ReputationChange()
        _EventHandler:ChatMsgCompatFactionChange()
    end)
    QuestieSmazak:RegisterEvent("CHAT_MSG_SYSTEM", _EventHandler.ChatMsgSystem)

    -- Spell objectives
    QuestieSmazak:RegisterEvent("NEW_RECIPE_LEARNED", function() -- Needed for some spells that don't necessarily appear in the spellbook, but are definitely spells
        QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] NEW_RECIPE_LEARNED")
        QuestEventHandler.NewRecipeLearned()
        AvailableQuests.CalculateAndDrawAll()
    end)

    -- UI Quest Events
    QuestieSmazak:RegisterEvent("UI_INFO_MESSAGE", _EventHandler.UiInfoMessage)
    QuestieSmazak:RegisterEvent("QUEST_FINISHED", function()
        AutoQuesting.OnQuestFinished()
        if Expansions.Current >= Expansions.Cata then
            -- There might be other quest events which need to finish first, so we wait a bit before checking.
            -- This is easier, than actually figuring out which events are fired in which order for this logic.
            C_Timer.After(0.5, function()
                AutoCompleteFrame.CheckAutoCompleteQuests()
            end)
        end
    end)
    QuestieSmazak:RegisterEvent("QUEST_ACCEPTED", function(_, questLogIndex, questId)
        if QuestieSmazak.IsForever then
            -- Forever sends only the quest ID; Classic sends the log index followed by the ID.
            questId = questLogIndex
            questLogIndex = QuestieCompat.GetQuestLogIndexByID(questId)
        end
        QuestEventHandler.QuestAccepted(questLogIndex, questId)
    end)
    QuestieSmazak:RegisterEvent("QUEST_DETAIL", function() -- When the quest is presented!
        AvailableQuests.ValidateAvailableQuestsFromQuestDetail()
        AutoQuesting.OnQuestDetail()
        if QuestieSmazak.IsSoD or QuestieSmazak.db.profile.enableBugHintsForAllFlavors then
            QuestieDebugOffer.QuestDialog()
        end
    end)
    QuestieSmazak:RegisterEvent("QUEST_PROGRESS", AutoQuesting.OnQuestProgress)
    QuestieSmazak:RegisterEvent("GOSSIP_SHOW", function()
        AvailableQuests.ValidateAvailableQuestsFromGossipShow()
        AutoQuesting.OnGossipShow()
        QuestgiverFrame.GossipMark()
    end)
    QuestieSmazak:RegisterEvent("QUEST_GREETING", function()
        AvailableQuests.ValidateAvailableQuestsFromQuestGreeting()
        AutoQuesting.OnQuestGreeting()
        QuestgiverFrame.GreetingMark()
    end)
    QuestieSmazak:RegisterEvent("QUEST_ACCEPT_CONFIRM", AutoQuesting.OnQuestAcceptConfirm) -- If an escort quest is taken by people close by
    QuestieSmazak:RegisterEvent("GOSSIP_CLOSED", function() -- Called twice when the stopping to talk to an NPC
        AutoQuesting.OnGossipClosed()
    end)
    QuestieSmazak:RegisterEvent("QUEST_COMPLETE", function() -- When complete window shows
        AutoQuesting.OnQuestComplete()
        if QuestieSmazak.IsSoD or QuestieSmazak.db.profile.enableBugHintsForAllFlavors then
            QuestieDebugOffer.QuestDialog()
        end
    end)
    QuestieSmazak:RegisterEvent("QUEST_REMOVED", function(_, questId) QuestEventHandler.QuestRemoved(questId) end)
    QuestieSmazak:RegisterEvent("QUEST_TURNED_IN", function(_, questId, xpReward, moneyReward) QuestEventHandler.QuestTurnedIn(questId, xpReward, moneyReward) end)
    QuestieSmazak:RegisterEvent("QUEST_LOG_UPDATE", function()
        QuestEventHandler.QuestLogUpdate()
        QuestgiverFrame.RecheckGreeting()
        QuestgiverFrame.RecheckGossip()
    end)
    QuestieSmazak:RegisterEvent("QUEST_WATCH_UPDATE", function(_, questId) QuestEventHandler.QuestWatchUpdate(questId) end)
    if QuestieCompat.IsSuperTrackingSupported() then
        QuestieSmazak:RegisterEvent("SUPER_TRACKING_CHANGED", TrackerSuperTrack.OnSuperTrackingChanged)
    end
    QuestieSmazak:RegisterEvent("QUEST_AUTOCOMPLETE", function(_, questId) QuestEventHandler.QuestAutoComplete(questId) end)
    QuestieSmazak:RegisterEvent("UNIT_QUEST_LOG_CHANGED", function(_, unitTarget) QuestEventHandler.UnitQuestLogChanged(unitTarget) end)
    QuestieSmazak:RegisterEvent("CURRENCY_DISPLAY_UPDATE", function(...)
        QuestEventHandler.CurrencyDisplayUpdate(...)
        if TrackerRecipes.HasCurrencyReagents() then
            _EventHandler.UpdateTracker()
        end
    end)
    QuestieSmazak:RegisterEvent("CRITERIA_UPDATE", QuestEventHandler.CriteriaUpdate)
    QuestieSmazak:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, eventType) QuestEventHandler.PlayerInteractionManagerFrameHide(eventType) end)

    -- The client's quest data is stale from PLAYER_LEAVING_WORLD on, and whether LOADING_SCREEN_ENABLED comes before
    -- or after it is not known: either one protects the cache.
    QuestieSmazak:RegisterEvent("PLAYER_LEAVING_WORLD", function()
        QuestLogCache.OnLoadingScreenEnabled()
    end)
    QuestieSmazak:RegisterEvent("LOADING_SCREEN_ENABLED", function()
        QuestLogCache.OnLoadingScreenEnabled()
    end)

    QuestieSmazak:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] ZONE_CHANGED_NEW_AREA")
        QuestieTracker.HandleZoneChanged()
    end)

    -- Pet Battle Events (MoP onwards)
    if Expansions.Current >= Expansions.MoP then
        QuestieSmazak:RegisterEvent("PET_BATTLE_OPENING_START", function()
            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] PET_BATTLE_OPENING_START")
            if QuestieSmazak.db.profile.trackerEnabled and QuestieSmazak.db.profile.hideTrackerInPetBattles then
                QuestieCombatQueue:Queue(function()
                    QuestieTracker:Hide()
                end)
            end
        end)

        QuestieSmazak:RegisterEvent("PET_BATTLE_CLOSE", function()
            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] PET_BATTLE_CLOSE")
            if QuestieSmazak.db.profile.trackerEnabled and QuestieSmazak.db.profile.hideTrackerInPetBattles then
                QuestieCombatQueue:Queue(function()
                    QuestieTracker:Show()
                end)
            end
        end)

        -- Additional pet battle events to handle edge cases
        QuestieSmazak:RegisterEvent("PET_BATTLE_PET_CHANGED", function()
            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] PET_BATTLE_PET_CHANGED")
            -- Ensure tracker stays hidden during pet changes/deaths
            if QuestieSmazak.db.profile.trackerEnabled and QuestieSmazak.db.profile.hideTrackerInPetBattles and C_PetBattles and C_PetBattles.IsInBattle() then
                QuestieCombatQueue:Queue(function()
                    QuestieTracker:Hide()
                end)
            end
        end)

        QuestieSmazak:RegisterEvent("PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE", function()
            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE")
            -- Ensure tracker stays hidden during battle round transitions
            if QuestieSmazak.db.profile.trackerEnabled and QuestieSmazak.db.profile.hideTrackerInPetBattles and C_PetBattles and C_PetBattles.IsInBattle() then
                QuestieCombatQueue:Queue(function()
                    QuestieTracker:Hide()
                end)
            end
        end)
    end

    -- UI Achievement Events
    if Expansions.Current >= Expansions.Wotlk and QuestieSmazak.db.profile.trackerEnabled then
        QuestieSmazak:RegisterEvent("ACHIEVEMENT_EARNED", AchievementEventHandler.AchievementEarned)

        QuestieSmazak:RegisterEvent("TRACKED_ACHIEVEMENT_UPDATE", AchievementEventHandler.TrackedAchievementUpdate)
        QuestieSmazak:RegisterEvent("TRACKED_ACHIEVEMENT_LIST_CHANGED", function(_, achievementId)
            AchievementEventHandler.TrackedAchievementListChanged(achievementId)
        end)

        -- This fires pretty often, multiple times for a single Achievement change and also for things most likely not related to Achievements at all.
        -- We use a bucket to hinder this from spamming
        QuestieSmazak:RegisterBucketEvent("CRITERIA_UPDATE", 2, AchievementEventHandler.CriteriaUpdate)

        QuestieSmazak:RegisterEvent("CHAT_MSG_MONEY", AchievementEventHandler.ChatMsgMoney)
        QuestieSmazak:RegisterEvent("CHAT_MSG_TEXT_EMOTE", AchievementEventHandler.ChatMsgTextEmote)
        QuestieSmazak:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", AchievementEventHandler.PlayerEquipmentChanged)
    end

    if TrackerRecipes.IsSupported() then
        QuestieSmazak:RegisterEvent("TRACKED_RECIPE_UPDATE", _EventHandler.UpdateTracker)
        -- A bucket, because QuestieTracker temporarily registers BAG_UPDATE_DELAYED as a plain event for quest items
        QuestieSmazak:RegisterBucketEvent("BAG_UPDATE_DELAYED", 0.5, function()
            if TrackerRecipes.HasTrackedRecipes() then
                _EventHandler.UpdateTracker()
            end
        end)
        -- C_Item.RequestLoadItemDataByID answers with ITEM_DATA_LOAD_RESULT, not GET_ITEM_INFO_RECEIVED
        QuestieSmazak:RegisterEvent("ITEM_DATA_LOAD_RESULT", function(_, itemId, success)
            if success and TrackerRecipes.OnItemInfoReceived(itemId) then
                _EventHandler.UpdateTracker()
            end
        end)
    end

    if Expansions.Current >= Expansions.MoP then
        -- Challenge Mode and Scenario Events
        QuestieSmazak:RegisterEvent("CHALLENGE_MODE_START", function()
            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] CHALLENGE_MODE_START")
            QuestieTracker:Update() -- Update the Tracker right away, because players are not infight on start
        end)

        QuestieSmazak:RegisterEvent("CHALLENGE_MODE_RESET", function()
            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] CHALLENGE_MODE_RESET")
            QuestieCombatQueue:Queue(function()
                QuestieTracker:Update()
            end)
        end)

        QuestieSmazak:RegisterEvent("SCENARIO_CRITERIA_UPDATE", function(_, criteriaIndex)
            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] SCENARIO_CRITERIA_UPDATE")
            QuestieTracker.UpdateScenarioLines(criteriaIndex)
            QuestieTracker.UpdateScenarioLines(0) -- Always update 0 index, because that is the trash count
            QuestieCombatQueue:Queue(function()
                QuestieTracker:Update()
            end)
        end)

        QuestieSmazak:RegisterEvent("SCENARIO_UPDATE", function()
            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] SCENARIO_UPDATE")
            QuestieCombatQueue:Queue(function()
                QuestieTracker:Update()
            end)
        end)

        QuestieSmazak:RegisterEvent("SCENARIO_POI_UPDATE", function()
            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] SCENARIO_POI_UPDATE")
            QuestieCombatQueue:Queue(function()
                QuestieTracker:Update()
            end)
        end)
    end

    -- QuestieSmazak Debug Offer
    if QuestieSmazak.IsSoD or QuestieSmazak.db.profile.enableBugHintsForAllFlavors then
        QuestieSmazak:RegisterEvent("LOOT_OPENED", QuestieDebugOffer.LootWindow)
    end

    if Expansions.Current >= Expansions.Cata and QuestieSmazak.db.profile.trackerEnabled then
        -- This is fired pretty often when an auto complete quest frame is showing. We want the default one to be hidden though.
        QuestieSmazak:RegisterEvent("UPDATE_ALL_UI_WIDGETS", function()
            QuestieCombatQueue:Queue(WatchFrameHook.Hide)
        end)
    end

    -- QuestieSmazak Comms Events

    -- Party join event for QuestieComms, Use bucket to hinder this from spamming (Ex someone using a raid invite addon etc)
    QuestieSmazak:RegisterBucketEvent("GROUP_ROSTER_UPDATE", 1, GroupEventHandler.GroupRosterUpdate)
    QuestieSmazak:RegisterEvent("GROUP_JOINED", GroupEventHandler.GroupJoined)
    QuestieSmazak:RegisterEvent("GROUP_LEFT", GroupEventHandler.GroupLeft)

    -- On a /reload (or login) while already in a group, GROUP_JOINED does not fire, so request party quest logs now;
    -- otherwise we never receive party members' objectives until the group changes.
    if IsInGroup() then
        GroupEventHandler.GroupJoined()
    end

    -- Nameplate / Target Frame Objective Events
    QuestieSmazak:RegisterEvent("NAME_PLATE_UNIT_ADDED", QuestieNameplate.NameplateCreated)
    QuestieSmazak:RegisterEvent("NAME_PLATE_UNIT_REMOVED", QuestieNameplate.NameplateDestroyed)
    QuestieSmazak:RegisterEvent("PLAYER_TARGET_CHANGED", function(...)
        QuestieNameplate:DrawTargetFrame()
        --if QuestieSmazak.IsSoD then QuestieDebugOffer.NPCTarget() end;
    end)

    -- quest announce
    QuestieSmazak:RegisterEvent("CHAT_MSG_LOOT", function(_, text, notPlayerName, _, _, playerName)
        QuestieTracker.QuestItemLooted(_, text)
        QuestieAnnounce.ItemLooted(_, text, notPlayerName, _, _, playerName)
    end)
end

function _EventHandler:PlayerLogin()
    -- Check config exists
    if not QuestieSmazak.db or not QuestieSmazakConfig then
        -- Did you move QuestieSmazak.db = LibStub("AceDB-3.0"):New("QuestieSmazakConfig",.......) out of QuestieSmazak:OnInitialize() ?
        QuestieSmazak.Error("Config DB from saved variables is not loaded and initialized. Please report this issue on QuestieSmazak github or discord.")
        error("Config DB from saved variables is not loaded and initialized. Please report this issue on QuestieSmazak github or discord.")
        return
    end

    do
        -- All this information was researched here: https://www.townlong-yak.com/framexml/live/GlobalStrings.lua

        local locale = GetLocale()
        local FACTION_STANDING_CHANGED_LOCAL = FACTION_STANDING_CHANGED or "You are now %s with %s."
        local replaceCount -- Just init it with an impossible value
        local replaceString = ".+"

        --! Has to got from least likely to work to most, otherwise you will get false positives
        local replaceTypes = {
            ruRU = "%(%%%d$s%)", --ruRU "|3-6(%2$s) |3-6(%1$s)." ("Ваша репутация с %2$s теперь %1$s.
            zhTW = "%%s%(%%s%)", --zhTW "你在%2$s中的聲望達到了%1$s。"")
            deDE = "%%%d$s", --deDE  "Die Fraktion '%2$s' ist Euch gegenüber jetzt '%1$s' eingestellt." or "Die Fraktion %2$s ist Euch gegenüber jetzt '%1$s' eingestellt."
            zhCNkoKR = "%%%d$s", --zhCN(zhTW?)/koKR "你在%2$s中的声望达到了%1$s。" / "%2$s에 대해 %1$s 평판이 되었습니다."
            enPlus = "%%s", -- European languages except (deDE)
        }

        if locale == "zhCN" or locale == "koKR" then --CN/KR "你在%2$s中的声望达到了%1$s。" / "%2$s에 대해 %1$s 평판이 되었습니다."
            FACTION_STANDING_CHANGED_PATTERN, replaceCount = string.gsub(FACTION_STANDING_CHANGED_LOCAL, replaceTypes.zhCNkoKR, replaceString)
        elseif locale == "deDE" then --DE  "Die Fraktion '%2$s' ist Euch gegenüber jetzt '%1$s' eingestellt." or "Die Fraktion %2$s ist Euch gegenüber jetzt '%1$s' eingestellt."
            FACTION_STANDING_CHANGED_PATTERN, replaceCount = string.gsub(FACTION_STANDING_CHANGED_LOCAL, replaceTypes.deDE, replaceString) -- Germans are always special
        elseif locale == "zhTW" then --TW "你的聲望已達到%s(%s)。", should we remove the parentheses?
            FACTION_STANDING_CHANGED_PATTERN, replaceCount = string.gsub(FACTION_STANDING_CHANGED_LOCAL, replaceTypes.zhTW, replaceString)
        elseif locale == "ruRU" then --RU "|3-6(%2$s) |3-6(%1$s).", should we remove the parentheses?
            FACTION_STANDING_CHANGED_PATTERN, replaceCount = string.gsub(FACTION_STANDING_CHANGED_LOCAL, replaceTypes.ruRU, replaceString)
        else
            FACTION_STANDING_CHANGED_PATTERN, replaceCount = string.gsub(FACTION_STANDING_CHANGED_LOCAL, replaceTypes.enPlus, replaceString)
        end

        --? A fallback to try everything if the replaceCount is still -1 or 0
        if replaceCount and replaceCount < 1 then
            for _, replaceType in pairs(replaceTypes) do
                FACTION_STANDING_CHANGED_PATTERN, replaceCount = string.gsub(FACTION_STANDING_CHANGED_LOCAL, replaceType, replaceString)
                if replaceCount > 0 then
                    break
                end
            end
        end

        --? Nothing worked :(
        if replaceCount and replaceCount < 1 then --- Error: Default to match EVERYTHING, because it's better that it works
            FACTION_STANDING_CHANGED_PATTERN = ".+"
            QuestieSmazak.Error("Something went wrong with the FACTION_STANDING_CHANGED_PATTERN!")
            QuestieSmazak.Error("FACTION_STANDING_CHANGED is set to " .. tostring(FACTION_STANDING_CHANGED) .. ", please report this on GitHub!")
        end
    end

    -- Start real QuestieSmazak init
    QuestieInit:Init()
end

--- Fires when a System Message (yellow text) is output to the main chat window
---@param message string The message value from the CHAT_MSG_SYSTEM event
function _EventHandler:ChatMsgSystem(message)
    if issecretvalue and issecretvalue(message) then
        -- The text cannot identify reputation changes; check the current faction state instead.
        _EventHandler:ChatMsgCompatFactionChange()
        return
    end

    -- When a new quest is accepted or completed quest is turned in, update the LibDataBroker text with the appropriate message
    if string.find(message, questCompletedMessage) == 1 or string.find(message, questAcceptedMessage) == 1 then
        MinimapIcon:UpdateText(message)
    elseif string.find(message, FACTION_STANDING_CHANGED_PATTERN) then -- When you discover a new faction or increase standing eg. Neutral -> Friendly
        local factionChanged, newFaction = QuestieReputation:Update(false)
        if factionChanged or newFaction then
            QuestieCombatQueue:Queue(function()
                QuestieTracker:Update()
            end)

            AvailableQuests.CalculateAndDrawAll()
        end
    end
end

local _QuestProgressMessages = {
    ["ERR_QUEST_OBJECTIVE_COMPLETE_S"] = true,
    ["ERR_QUEST_UNKNOWN_COMPLETE"] = true,
    ["ERR_QUEST_ADD_KILL_SII"] = true,
    ["ERR_QUEST_ADD_FOUND_SII"] = true,
    ["ERR_QUEST_ADD_ITEM_SII"] = true,
    ["ERR_QUEST_ADD_PLAYER_KILL_SII"] = true,
    ["ERR_QUEST_FAILED_S"] = true,
}

--- Fires when a UI Info Message (yellow text) appears near the top of the screen
---@param errorType number The error type value from the UI_INFO_MESSAGE event
---@param message string The message value from the UI_INFO_MESSAGE event
function _EventHandler:UiInfoMessage(errorType, message)
    if _QuestProgressMessages[GetGameMessageInfo(errorType)] then
        MinimapIcon:UpdateText(message)
    end
end

--- Fires on MAP_EXPLORATION_UPDATED.
function _EventHandler:MapExplorationUpdated()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] MAP_EXPLORATION_UPDATED")
    if QuestieSmazak.db.profile.hideUnexploredMapIcons then
        QuestieMap.utils.MapExplorationUpdate()
    end

    -- Exploratory based Achievement updates
    if Expansions.Current >= Expansions.Wotlk then
        QuestieCombatQueue:Queue(function()
            QuestieTracker:Update()
        end)
    end
end

--- Fires when the player levels up
---@param level number
function _EventHandler:PlayerLevelUp(level)
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] PLAYER_LEVEL_UP", level)

    QuestiePlayer:SetPlayerLevel(level)
    QuestieJourney:PlayerLevelUp(level)

    -- Quest difficulty colors might have changed with the new level
    QuestieCombatQueue:Queue(function()
        QuestieTracker:Update()
        AvailableQuests.ResetLevelRequirementCache()
        AvailableQuests.CalculateAndDrawAll()
    end)
end

--- Fires when a modifier key changed
function _EventHandler:ModifierStateChanged(key, down)
    if key == "LSHIFT" or key == "RSHIFT" then
        -- Unless the Shift Key is down, don't run this code. We've recieved reports that our tooltips
        -- are apperearing when using the Shift Modifier for other areas of the UI and other addons.
        -- Since we're hooking into Blizzards GameTooltip, it's possible that certain edge cases would
        -- cause our Tooltips to appear instead and since the mouse isn't over "our" frame, it's not
        -- getting reset properly and getting stuck to the Mouse Cursor.

        -- QuestieSmazak Map Icons
        if QuestieCompat.MouseIsOver(WorldMapFrame) and WorldMapFrame:IsShown() or QuestieCompat.MouseIsOver(Minimap) then
            if GameTooltip and GameTooltip:IsShown() and GameTooltip._Rebuild then
                GameTooltip:Hide()
                GameTooltip:ClearLines()
                GameTooltip:SetOwner(GameTooltip._owner, "ANCHOR_CURSOR")
                GameTooltip:_Rebuild() -- rebuild the tooltip
                GameTooltip:SetFrameStrata("TOOLTIP")
                GameTooltip:Show()
            end
        end

        -- QuestieSmazak Tracker Sizer
        if QuestieTracker.started then
            if QuestieCompat.MouseIsOver(QuestieSmazak_BaseFrame.sizer) then
                if down == 1 then
                    if GameTooltip and GameTooltip:IsShown() and GameTooltip._SizerToolTip then
                        GameTooltip:Hide()
                        GameTooltip:ClearLines()
                        GameTooltip:SetOwner(GameTooltip._owner, "ANCHOR_CURSOR")
                        GameTooltip._SizerToolTip()
                        GameTooltip:SetFrameStrata("TOOLTIP")
                        GameTooltip:Show()
                    end
                else
                    if GameTooltip:IsShown() then
                        GameTooltip:Hide()
                        GameTooltip._SizerToolTip = nil
                    end
                end
            end
        end
    end

    if QuestieSmazak.db.profile.trackerLocked then
        if QuestieTracker.started then
            -- This is a safety catch for race conditions to prevent the Tracker Sizer
            -- from becoming stuck to the mouse pointer when the player releases the
            -- CTRL key first before releasing the Left Mouse Button.
            if (key == "LCTRL" or key == "RCTRL") and down == 0 then
                if IsMouseButtonDown("LeftButton") then
                    -- Tracker is being sized
                    if TrackerBaseFrame.isSizing ~= false and TrackerBaseFrame.isMoving ~= true then
                        TrackerBaseFrame.OnResizeStop(self, "LeftButton")
                        return
                    end
                    -- Tracker is being moved
                    if TrackerBaseFrame.isMoving ~= false and TrackerBaseFrame.isSizing ~= true then
                        TrackerBaseFrame.OnDragStop(self, "LeftButton")
                        return
                    end
                end
            end
            QuestieCombatQueue:Queue(function()
                TrackerBaseFrame:Update()
                TrackerQuestFrame:Update()
            end)
        end
    end
end

---Refreshes skill-gated quests after skill chat or skill line changes.
function _EventHandler:ChatMsgSkill()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] Profession skills changed")

    -- Redraw for professions gained or lost as well as skill thresholds crossed.
    local isProfUpdate, isNewProfession = QuestieProfessions:Update()
    if isProfUpdate or isNewProfession then
        AvailableQuests.CalculateAndDrawAll()
    end
    if QuestieSmazak.db.profile.townsfolkKnownProfessions then
        QuestieMenu.RefreshKnownProfessionTrainers()
    end

    -- Skill based Achievement updates
    if Expansions.Current >= Expansions.Wotlk then
        QuestieCombatQueue:Queue(function()
            QuestieTracker:Update()
        end)
    end
end

--- Fires when some chat messages about reputations are displayed
function _EventHandler:ChatMsgCompatFactionChange()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] CHAT_MSG_COMBAT_FACTION_CHANGE")
    local factionChanged, newFaction = QuestieReputation:Update(false)
    if factionChanged or newFaction then
        QuestieCombatQueue:Queue(function()
            QuestieTracker:Update()
        end)

        AvailableQuests.CalculateAndDrawAll()
    end
end

local optionsHiddenByCombat, journeyHiddenByCombat = false, false

function _EventHandler:PlayerRegenDisabled()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] PLAYER_REGEN_DISABLED")

    -- Let's make sure the frame exists - might be nil if player is in combat upon login
    if QuestieTracker then
        QuestieTracker.HandleCombatStarted()
    end

    -- Let's make sure the frame exists - might be nil if player is in combat upon login
    if QuestieSmazakConfigFrame then
        if QuestieSmazakConfigFrame:IsShown() then
            optionsHiddenByCombat = true
            QuestieSmazakConfigFrame:Hide()
        end
    end

    -- Let's make sure the frame exists - might be nil if player is in combat upon login
    if QuestieJourney then
        if QuestieJourney:IsShown() then
            journeyHiddenByCombat = true
            QuestieJourney:ToggleJourneyWindow()
        end
    end

    -- The Native settings panel can be shown in combat, unlike Ace, but some of its options
    -- (like toggling the tracker) cannot be changed in combat, so we disable those ones in combat.
    -- Changing their enabled/disabled visible state requires calling RefreshStates(),
    -- so we refresh them at the start and end of combat if the settings panel is visible.
    -- There is a delay here because InCombatLockdown() doesn't return accurately immediately following PLAYER_REGEN_DISABLED.
    C_Timer.After(0.1, function() QuestieOptionsEngine:RefreshStates() end)
end

function _EventHandler:PlayerRegenEnabled()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] PLAYER_REGEN_ENABLED")

    QuestieTracker.HandleCombatEnded()

    if optionsHiddenByCombat then
        QuestieSmazakConfigFrame:Show()
        optionsHiddenByCombat = false
    end

    if journeyHiddenByCombat then
        QuestieJourney:ToggleJourneyWindow()
        journeyHiddenByCombat = false
    end

    C_Timer.After(0.1, function() QuestieOptionsEngine:RefreshStates() end)
end

function _EventHandler.UpdateTracker()
    QuestieCombatQueue:Queue(function()
        QuestieTracker:Update()
    end)
end
