---@class AchievementEventHandler
local AchievementEventHandler = QuestieSmazakLoader:CreateModule("AchievementEventHandler")

---@type AchievementTracking
local AchievementTracking = QuestieSmazakLoader:ImportModule("AchievementTracking")
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieSmazakLoader:ImportModule("QuestieCombatQueue")
---@type QuestieTracker
local QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker")

-- Earned Achievement update. The game removes an earned achievement from its tracked list itself
function AchievementEventHandler.AchievementEarned()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] ACHIEVEMENT_EARNED")
    QuestieCombatQueue:Queue(function()
        QuestieTracker:Update()
    end)
end

-- Track/Untrack Achievement updates
---@param achievementId number?
function AchievementEventHandler.TrackedAchievementListChanged(achievementId)
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] TRACKED_ACHIEVEMENT_LIST_CHANGED")

    if achievementId and achievementId ~= 0 and AchievementTracking.IsTracked(achievementId) then
        -- Forces a newly tracked achievement and the Achievements zone out of a minimized state
        QuestieSmazak.db.char.collapsedQuests[achievementId] = nil
        QuestieSmazak.db.char.collapsedZones["Achievements"] = nil
    end

    QuestieCombatQueue:Queue(function()
        QuestieTracker:Update()
    end)
end

-- Timed based Achievement updates
-- TODO: Fired when a timed event for an achievement begins or ends. The achievement does not have to be actively tracked for this to trigger.
function AchievementEventHandler.TrackedAchievementUpdate()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] TRACKED_ACHIEVEMENT_UPDATE")
    QuestieCombatQueue:Queue(function()
        QuestieTracker:Update()
    end)
end

function AchievementEventHandler.CriteriaUpdate()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] CRITERIA_UPDATE")

    if next(AchievementTracking.GetTrackedIds()) then
        QuestieCombatQueue:Queue(function()
            QuestieTracker:Update()
        end)
    end
end

-- Money based Achievement updates
function AchievementEventHandler.ChatMsgMoney()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] CHAT_MSG_MONEY")
    QuestieCombatQueue:Queue(function()
        QuestieTracker:Update()
    end)
end

-- Emote based Achievement updates
function AchievementEventHandler.ChatMsgTextEmote()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] CHAT_MSG_TEXT_EMOTE")
    QuestieCombatQueue:Queue(function()
        QuestieTracker:Update()
    end)
end

-- Player equipment changed based Achievement updates
function AchievementEventHandler.PlayerEquipmentChanged()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[EVENT] PLAYER_EQUIPMENT_CHANGED")
    QuestieCombatQueue:Queue(function()
        QuestieTracker:Update()
    end)
end
