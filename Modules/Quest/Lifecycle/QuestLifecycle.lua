---@class QuestLifecycle
local QuestLifecycle = QuestieSmazakLoader:CreateModule("QuestLifecycle")

---@type QuestieTooltips
local QuestieTooltips = QuestieSmazakLoader:ImportModule("QuestieTooltips")
---@type QuestiePlayer
local QuestiePlayer = QuestieSmazakLoader:ImportModule("QuestiePlayer")
---@type QuestieDB
local QuestieDB = QuestieSmazakLoader:ImportModule("QuestieDB")
---@type AvailableQuests
local AvailableQuests = QuestieSmazakLoader:ImportModule("AvailableQuests")
---@type QuestieQuest
local QuestieQuest = QuestieSmazakLoader:ImportModule("QuestieQuest")
---@type Expansions
local Expansions = QuestieSmazakLoader:ImportModule("Expansions")
---@type QuestieTracker
local QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker")
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieSmazakLoader:ImportModule("QuestieCombatQueue")
---@type CommsVisibility
local CommsVisibility = QuestieSmazakLoader:ImportModule("CommsVisibility")
---@type QuestLogCache
local QuestLogCache = QuestieSmazakLoader:ImportModule("QuestLogCache")
---@type ActiveQuests
local ActiveQuests = QuestieSmazakLoader:ImportModule("ActiveQuests")

local pairs = pairs

local allianceTournamentMarkerQuests = {
    [13684] = true,
    [13685] = true,
    [13688] = true,
    [13689] = true,
    [13690] = true,
    [13593] = true,
    [13703] = true,
    [13704] = true,
    [13705] = true,
    [13706] = true
}
local hordeTournamentMarkerQuests = {
    [13691] = true,
    [13693] = true,
    [13694] = true,
    [13695] = true,
    [13696] = true,
    [13707] = true,
    [13708] = true,
    [13709] = true,
    [13710] = true,
    [13711] = true
}
local xiaoFollowUpQuests = {[29577] = true, [29981] = true, [30079] = true}

local allianceChampionMarkerQuests = {[13699] = true, [13713] = true, [13723] = true, [13724] = true, [13725] = true}
local hordeChampionMarkerQuests = {[13726] = true, [13727] = true, [13728] = true, [13729] = true, [13731] = true}

---Clears the progress QuestieSmazak derived for a quest, so the next population starts from the quest log.
---@param quest Quest
local function _ResetProgress(quest)
    quest.Objectives = {}
    quest.WasComplete = nil
    quest.isComplete = nil
end

---Draws a logged quest from scratch: its objectives or finisher replace its starter/finisher frames.
---@param questId QuestId
---@param quest Quest
local function _RedrawLoggedQuest(questId, quest)
    -- Remove the starter/finisher frames first, then draw objective notes once the
    -- unload coroutine has finished. This prevents the draw coroutines from racing
    -- with the unload coroutine and leaving stale entries in questIdFrames.
    QuestLifecycle.RemoveFramesOfLoggedQuest(questId, function()
        QuestieQuest:PopulateQuestLogInfo(quest)
        -- This needs to happen after QuestieQuest:PopulateQuestLogInfo because that is the place where quest.Objectives is generated
        QuestieSmazak:SendMessage("QC_ID_BROADCAST_QUEST_UPDATE", questId)
        QuestieQuest:PopulateObjectiveNotes(quest)

        AvailableQuests.CalculateAndDrawAll()
    end)
end

---@param questId number
function QuestLifecycle:AcceptQuest(questId)
    local quest = QuestieDB.GetQuest(questId)

    if (not quest) then
        -- Tracking belongs to the live quest log even when map enrichment is unavailable.
        QuestieSmazak.db.char.collapsedQuests[questId] = nil
        QuestieSmazak.db.char.AutoUntrackedQuests[questId] = nil
        CommsVisibility:ScheduleSnapshot("ACCEPT_QUEST")
        QuestieCombatQueue:Queue(function()
            QuestieTracker:Update()
        end)
        return
    end

    -- QUEST_ACCEPTED fires only for a new acceptance, so a quest QuestieSmazak already logs is reset and added again. Its
    -- completion cannot tell whether that is needed: a failed quest re-accepted in place can be complete at once, when
    -- the giver hands over the quest item with the quest.
    if ActiveQuests.Get(questId) then
        QuestieSmazak.Debug(QuestieSmazak.DEBUG_INFO, "[QuestLifecycle:AcceptQuest] Quest", questId, " was accepted before and needs to be reset.")

        _ResetProgress(quest)

        -- Reset tooltips
        QuestieTooltips:RemoveQuest(questId)
    end

    local childQuests = QuestieDB.QueryQuestSingle(questId, "childQuests")
    if childQuests then
        for _, childQuestId in pairs(childQuests) do
            -- Daily quest status is reset after parent accept
            if QuestieDB.IsDailyQuest(childQuestId) then
                QuestieSmazak.db.char.complete[childQuestId] = nil
            end
        end
    end

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_INFO, "[QuestLifecycle:AcceptQuest] Quest", questId, "will be added to the quest log.")

    ActiveQuests.Add(questId, quest)

    if allianceTournamentMarkerQuests[questId] then
        QuestieSmazak.db.char.complete[13686] = true -- Alliance Tournament Eligibility Marker
    elseif hordeTournamentMarkerQuests[questId] then
        QuestieSmazak.db.char.complete[13687] = true -- Horde Tournament Eligibility Marker
    elseif xiaoFollowUpQuests[questId] then
        QuestieSmazak.db.char.complete[30087] = true -- Xiao's Breadcrumbs Hidden Prequest
    end

    -- Re-accepted quest can be collapsed. Expand it. Especially dailies.
    QuestieSmazak.db.char.collapsedQuests[questId] = nil
    -- Re-accepted quest can be untracked. Clear it. Especially timed quests.
    QuestieSmazak.db.char.AutoUntrackedQuests[questId] = nil

    -- QuestieV1 snapshots are full-state maps. Re-accepting can clear a stale remote
    -- false entry, so notify peers after the local quest-log/tracking state is updated.
    CommsVisibility:ScheduleSnapshot("ACCEPT_QUEST")

    _RedrawLoggedQuest(questId, quest)
end

---Tracks a quest a quest log scan found in the game's log without QuestieSmazak accepting it: the game listed it only after
---QuestieSmazak's start-up, or QuestieSmazak missed its QUEST_ACCEPTED. It is set up as at login, not as an accept, so the
---player's collapsed and untracked choices are not reset; the quest giver's "!", drawn while QuestieSmazak did not have the
---quest, goes first.
---@param questId number
function QuestLifecycle:AdoptQuest(questId)
    local quest = QuestieDB.GetQuest(questId)
    if not quest then
        return
    end

    ActiveQuests.Add(questId, quest)
    CommsVisibility:ScheduleSnapshot("ACCEPT_QUEST")

    -- As in AcceptQuest: draw the quest once the unload coroutine has removed its starter frames.
    QuestLifecycle.RemoveFramesOfLoggedQuest(questId, function()
        QuestieQuest:AddToQuestLog(quest)
        -- Party members learn of the quest and its progress here, as from AcceptQuest. AddToQuestLog sends nothing, so
        -- start-up does not send every quest on its own: a joining party member asks for the whole quest log.
        QuestieSmazak:SendMessage("QC_ID_BROADCAST_QUEST_UPDATE", questId)
        AvailableQuests.CalculateAndDrawAll()
    end)
end

---Removes the quest's starter/finisher frames, then runs onComplete only if the same acceptance of the quest is still
---logged. The unload coroutine spans several frames. A quest turned in or abandoned meanwhile has left QuestLogCache,
---so populating or drawing it then would fail or bring it back.
---@param questId QuestId
---@param onComplete function
function QuestLifecycle.RemoveFramesOfLoggedQuest(questId, onComplete)
    local acceptance = ActiveQuests.Get(questId)
    AvailableQuests.RemoveQuest(questId, function()
        if (not ActiveQuests.IsCurrent(acceptance)) or (not QuestLogCache.TryGetQuest(questId)) then
            return
        end
        onComplete()
    end)
end

---Updates a logged quest after its quest log entry changed. A quest that fell back to incomplete after it was complete,
---or lost the item it starts with, is reset and drawn again; any other quest is drawn for its current state.
---@param questId QuestId
function QuestLifecycle:UpdateQuest(questId)
    local quest = QuestieDB.GetQuest(questId)
    if (not quest) or QuestieSmazak.db.char.complete[questId] then
        return
    end

    if quest:IsComplete() == 0 and (quest.WasComplete or
        (quest.sourceItemId > 0 and QuestieQuest:CheckQuestSourceItem(questId, false) == false)) then
        QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestLifecycle:UpdateQuest] Quest was once complete or Quest Item(s) were removed. Resetting quest.")

        _ResetProgress(quest)
        -- Work still pending from before the reset must not draw over the redraw below
        ActiveQuests.Add(questId, quest)
        QuestieQuest:CheckQuestSourceItem(questId, true)
        QuestieSmazak.db.char.collapsedQuests[questId] = nil
        _RedrawLoggedQuest(questId, quest)
        return
    end

    QuestieQuest:UpdateQuest(questId)
end

---@param questId number
function QuestLifecycle:CompleteQuest(questId)
    local acceptance = ActiveQuests.Remove(questId)
    -- Quests which are turn in only were never added to the quest log
    if acceptance and acceptance.quest then
        acceptance.quest.WasComplete = nil
        acceptance.quest.isComplete = nil
    end

    -- Only quests that are daily quests or aren't repeatable should be marked complete,
    -- otherwise objectives for repeatable quests won't track correctly - #1433
    QuestieSmazak.db.char.complete[questId] = (not QuestieDB.IsRepeatable(questId)) or QuestieDB.IsDailyQuest(questId) or QuestieDB.IsWeeklyQuest(questId) or
        QuestieDB.IsMonthlyQuest(questId);

    if Expansions.Current >= Expansions.Wotlk then
        if allianceChampionMarkerQuests[questId] then
            QuestieSmazak.db.char.complete[13700] = true -- Alliance Champion Marker
            QuestieSmazak.db.char.complete[13686] = nil -- Alliance Tournament Eligibility Marker
        elseif hordeChampionMarkerQuests[questId] then
            QuestieSmazak.db.char.complete[13701] = true -- Horde Champion Marker
            QuestieSmazak.db.char.complete[13687] = nil -- Horde Tournament Eligibility Marker
        end
    end
    if Expansions.Current >= Expansions.MoP then
        if questId == 31450 then -- A New Fate (Pandaren faction quest)
            QuestiePlayer:Initialize() -- Reinitialize to update player race flags
        end
    end

    local childQuests = QuestieDB.QueryQuestSingle(questId, "childQuests")
    if childQuests then
        for _, childQuestId in pairs(childQuests) do
            if (not ActiveQuests.Get(childQuestId)) then
                -- Make sure all other childQuests are unloaded: all exclusives, chains etc
                AvailableQuests.RemoveQuest(childQuestId)
            end
        end
    end

    QuestieTracker:RemoveQuest(questId)
    QuestieCombatQueue:Queue(function()
        QuestieTracker:Update()
    end)

    -- Removing the quest from our snapshot clears any previous false visibility entry on peers.
    CommsVisibility:ScheduleSnapshot("COMPLETE_QUEST")

    AvailableQuests.RemoveQuest(questId, function()
        AvailableQuests.CalculateAndDrawAll()
    end)

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_INFO, "[QuestLifecycle:CompleteQuest]", questId)
end

---@param questId number
function QuestLifecycle:AbandonQuest(questId)
    local acceptance = ActiveQuests.Remove(questId)
    -- Unknown quests have tracker state without an entry in the enriched map quest log.
    QuestieTracker:RemoveQuest(questId)
    QuestieCombatQueue:Queue(function()
        QuestieTracker:Update()
    end)

    if (not acceptance) then
        return
    end

    local quest = QuestieDB.GetQuest(questId)

    if (not quest) then
        return
    end

    _ResetProgress(quest)

    if allianceTournamentMarkerQuests[questId] then
        QuestieSmazak.db.char.complete[13686] = nil -- Alliance Tournament Eligibility Marker
    elseif hordeTournamentMarkerQuests[questId] then
        QuestieSmazak.db.char.complete[13687] = nil -- Horde Tournament Eligibility Marker
    end

    local childQuests = QuestieDB.QueryQuestSingle(questId, "childQuests")
    if childQuests then
        for _, childQuestId in pairs(childQuests) do
            if (not ActiveQuests.Get(childQuestId)) then
                -- Make sure all other childQuests are unloaded: all exclusives, chains etc
                AvailableQuests.RemoveQuest(childQuestId)
            end
        end
    end

    -- Removing the quest from our snapshot clears any previous false visibility entry on peers.
    CommsVisibility:ScheduleSnapshot("ABANDON_QUEST")

    AvailableQuests.RemoveQuest(questId, function()
        AvailableQuests.CalculateAndDrawAll()
    end)

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_INFO, "[QuestLifecycle:AbandonQuest]", questId)
end
