---@class TrackerSuperTrack
local TrackerSuperTrack = QuestieSmazakLoader:CreateModule("TrackerSuperTrack")

---@type QuestieCompat
local QuestieCompat = QuestieSmazakLoader:ImportModule("QuestieCompat")
---@type TrackerUtils
local TrackerUtils = QuestieSmazakLoader:ImportModule("TrackerUtils")
---@type QuestieQuest
local QuestieQuest = QuestieSmazakLoader:ImportModule("QuestieQuest")
---@type QuestieTracker
local QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker")
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieSmazakLoader:ImportModule("QuestieCombatQueue")

---Follows super tracking changes made outside QuestieSmazak, e.g. on the Blizzard map or quest log.
---Changes QuestieSmazak made itself already match its focus, so only the tracker is redrawn.
---Ignored unless the follow option is on.
function TrackerSuperTrack.OnSuperTrackingChanged()
    if (not QuestieSmazak.db.profile.trackerFollowSuperTracking) then
        return
    end

    local questId = QuestieCompat.GetSuperTrackedQuestID()
    local focus = QuestieSmazak.db.char.TrackerFocus

    if questId then
        if focus ~= questId then
            if TrackerUtils:FocusQuest(questId) then
                QuestieQuest.ToggleQuestNotes(false)
            elseif focus then
                -- QuestieSmazak can not focus the new quest, so drop the old quest focus instead of showing it as focused.
                TrackerUtils:UnFocus()
                QuestieQuest.ToggleQuestNotes(true)
            end
        end
    elseif focus then
        TrackerUtils:UnFocus()
        QuestieQuest.ToggleQuestNotes(true)
    end

    -- The focus buttons also show Blizzard's super tracked quest, so every change needs a redraw.
    QuestieCombatQueue:Queue(function()
        QuestieTracker:Update()
    end)
end
