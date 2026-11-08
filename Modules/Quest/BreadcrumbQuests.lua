---@type QuestieCompat
local QuestieCompat = QuestieSmazakLoader:ImportModule("QuestieCompat")

---@class BreadcrumbQuests
local BreadcrumbQuests = QuestieSmazakLoader:CreateModule("BreadcrumbQuests")

---@type QuestieDB
local QuestieDB = QuestieSmazakLoader:ImportModule("QuestieDB")
---@type QuestiePlayer
local QuestiePlayer = QuestieSmazakLoader:ImportModule("QuestiePlayer")
---@type ActiveQuests
local ActiveQuests = QuestieSmazakLoader:ImportModule("ActiveQuests")
---@type QuestieAnnounce
local QuestieAnnounce = QuestieSmazakLoader:ImportModule("QuestieAnnounce")
---@type QuestieLink
local QuestieLink = QuestieSmazakLoader:ImportModule("QuestieLink")
---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")

--- Abandons the given quest and prints a message referencing the incomplete breadcrumb quest.
---@param questId number
---@param breadcrumbQuestId number
---@return boolean @Whether the quest was abandoned
function BreadcrumbQuests.AbandonQuest(questId, breadcrumbQuestId)
    local questLogIndex = QuestieCompat.GetQuestLogIndexByID(questId)
    if questLogIndex and questLogIndex > 0 then
        QuestieCompat.SelectQuestLogEntry(questLogIndex)
        QuestieCompat.SetAbandonQuest()
        QuestieCompat.AbandonQuest()
        local questLink = QuestieLink:GetQuestHyperLink(questId)
        local breadcrumbLink = QuestieLink:GetQuestHyperLink(breadcrumbQuestId)
        QuestieSmazak:Print(l10n("Automatically abandoned quest %s because breadcrumb quest %s is not completed.", questLink or "no quest name", breadcrumbLink or "no quest name"))
        return true
    end
    return false
end

--- Checks if a quest has incomplete breadcrumbs and announces/abandons accordingly.
---@param questId number
function BreadcrumbQuests.CheckQuestBreadcrumbs(questId)
    if not (QuestieSmazak.db.profile.questAnnounceIncompleteBreadcrumb or QuestieSmazak.db.profile.autoAccept.abandonBreadcrumbFollowup) then
        return
    end

    local breadcrumbs = QuestieDB.QueryQuestSingle(questId, "breadcrumbs")
    if breadcrumbs then
        local lastIncompleteBreadcrumbId = nil
        for _, breadcrumbQuestId in ipairs(breadcrumbs) do
            -- We want to let users know when they picked up a quest without finishing its breadcrumb
            if (not QuestieSmazak.db.char.complete[breadcrumbQuestId]) and (not ActiveQuests.Get(breadcrumbQuestId)) then
                local requiredRaces = QuestieDB.QueryQuestSingle(breadcrumbQuestId, "requiredRaces")
                local requiredClasses = QuestieDB.QueryQuestSingle(breadcrumbQuestId, "requiredClasses")
                local availableUntilCompleted = QuestieDB.QueryQuestSingle(breadcrumbQuestId, "availableUntilCompleted")

                local exclusiveQuests = QuestieDB.QueryQuestSingle(breadcrumbQuestId, "exclusiveTo")
                local exclusiveQuestCompleted = false
                if exclusiveQuests then
                    for _, exclusiveQuestId in pairs(exclusiveQuests) do
                        if QuestieSmazak.db.char.complete[exclusiveQuestId] or ActiveQuests.Get(exclusiveQuestId) then
                            exclusiveQuestCompleted = true
                            break
                        end
                    end
                end

                if QuestiePlayer.HasRequiredRace(requiredRaces)
                    and QuestiePlayer.HasRequiredClass(requiredClasses)
                    and (not exclusiveQuestCompleted)
                    and (not availableUntilCompleted or not QuestieSmazak.db.char.complete[availableUntilCompleted]) then
                    if QuestieSmazak.db.profile.questAnnounceIncompleteBreadcrumb then
                        QuestieAnnounce.IncompleteBreadcrumbQuest(questId, breadcrumbQuestId)
                    end
                    lastIncompleteBreadcrumbId = breadcrumbQuestId
                end
            end
        end

        if lastIncompleteBreadcrumbId and QuestieSmazak.db.profile.autoAccept.abandonBreadcrumbFollowup then
            BreadcrumbQuests.AbandonQuest(questId, lastIncompleteBreadcrumbId)
        end
    end
end
