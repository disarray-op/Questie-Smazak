---@type QuestieCompat
local QuestieCompat = QuestieSmazakLoader:ImportModule("QuestieCompat")

---@class WatchFrameHook
local WatchFrameHook = QuestieSmazakLoader:CreateModule("WatchFrameHook")

local QuestTimerFrame = QuestTimerFrame

function WatchFrameHook.Hide()
    if QuestTimerFrame then
        QuestTimerFrame:Hide()
    end

    QuestieCompat.HideWatchFrame()
end