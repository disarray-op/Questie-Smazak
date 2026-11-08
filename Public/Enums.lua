---@class QuestieAPI
local QuestieAPI = QuestieSmazakLoader:CreateModule("QuestieAPI")

QuestieAPI.Enums = {
    ---@enum QuestUpdateTriggerReason
    QuestUpdateTriggerReason = {
        QUEST_ACCEPTED = 1,
        QUEST_UPDATED = 2,
        QUEST_TURNED_IN = 3,
        QUEST_ABANDONED = 4,
    }
}
QuestieSmazak.API.Enums = QuestieAPI.Enums
