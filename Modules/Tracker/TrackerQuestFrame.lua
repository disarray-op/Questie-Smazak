---@class TrackerQuestFrame
local TrackerQuestFrame = QuestieSmazakLoader:CreateModule("TrackerQuestFrame")
-------------------------
--Import QuestieTracker modules.
-------------------------
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieSmazakLoader:ImportModule("QuestieCombatQueue")
---@type TrackerBaseFrame
local TrackerBaseFrame = QuestieSmazakLoader:ImportModule("TrackerBaseFrame")
---@type TrackerFadeTicker
local TrackerFadeTicker = QuestieSmazakLoader:ImportModule("TrackerFadeTicker")
---@type TrackerUtils
local TrackerUtils = QuestieSmazakLoader:ImportModule("TrackerUtils")

local questFrame, trackerBaseFrame, trackerHeaderFrame

function TrackerQuestFrame.Initialize(baseFrame, headerFrame)
    trackerBaseFrame = baseFrame
    trackerHeaderFrame = headerFrame

    -- TrackerQuestFrame
    questFrame = CreateFrame("Frame", "QuestieSmazakTrackedQuests", trackerBaseFrame)
    questFrame:SetWidth(25)
    questFrame:SetHeight(25)

    TrackerQuestFrame.PositionTrackedQuestsFrame()

    questFrame:EnableMouse(true)
    questFrame:SetMovable(true)
    questFrame:SetResizable(true)
    questFrame:RegisterForDrag("LeftButton")
    questFrame:SetScript("OnDragStart", TrackerBaseFrame.OnDragStart)
    questFrame:SetScript("OnDragStop", TrackerBaseFrame.OnDragStop)
    questFrame:SetScript("OnEnter", TrackerFadeTicker.Unfade)
    questFrame:SetScript("OnLeave", TrackerFadeTicker.Fade)

    questFrame.ScrollFrame = CreateFrame("ScrollFrame", "QuestieSmazakTrackedQuestsScrollFrame", questFrame, "ScrollFrameTemplate")
    questFrame.ScrollFrame:SetAllPoints(questFrame)
    questFrame.ScrollFrame.ScrollBar:Hide()

    questFrame.ScrollChildFrame = CreateFrame("Frame", "QuestieSmazakTrackedQuestsScrollChildFrame")
    questFrame.ScrollChildFrame:SetSize(questFrame.ScrollFrame:GetWidth(), (questFrame.ScrollFrame:GetHeight()))

    questFrame.ScrollFrame:SetScrollChild(questFrame.ScrollChildFrame)

    questFrame:Hide()

    TrackerQuestFrame.questFrame = questFrame

    return questFrame
end

function TrackerQuestFrame:Update()
    if QuestieSmazak.db.char.isTrackerExpanded then
        questFrame:ClearAllPoints()
        TrackerQuestFrame.PositionTrackedQuestsFrame()

        questFrame:Show()

        -- Enables Click-Through when the tracker is locked
        if IsControlKeyDown() or (not QuestieSmazak.db.profile.trackerLocked) then
            QuestieCombatQueue:Queue(function()
                questFrame:EnableMouse(true)
                questFrame:SetMovable(true)
                questFrame:SetResizable(true)
            end)
        else
            QuestieCombatQueue:Queue(function()
                questFrame:EnableMouse(false)
                questFrame:SetMovable(false)
                questFrame:SetResizable(false)
            end)
        end
    else
        questFrame:Hide()
    end
end

function TrackerQuestFrame.PositionTrackedQuestsFrame()
    local QuestieTrackerLoc = QuestieSmazak.db.profile.TrackerLocation
    if QuestieSmazak.db.profile.trackerHeaderEnabled or (QuestieSmazak.db.profile.alwaysShowTracker and not TrackerUtils.HasQuest()) then
        if QuestieSmazak.db.profile.moveHeaderToBottom then
            -- Move the tracker header to the bottom
            questFrame:SetPoint("BOTTOMLEFT", trackerHeaderFrame, "TOPLEFT", 0, 4)
        else
            -- Move the tracker header to the top
            questFrame:SetPoint("TOPLEFT", trackerHeaderFrame, "BOTTOMLEFT", 0, 0)
        end
    elseif QuestieTrackerLoc and (QuestieTrackerLoc[1] == "BOTTOMLEFT" or QuestieTrackerLoc[1] == "BOTTOMRIGHT") then
        -- No header. TrackedQuestsFrame is attached to the bottom.
        questFrame:SetPoint("BOTTOMLEFT", trackerBaseFrame, "BOTTOMLEFT", 0, 10)
    else
        -- No header. TrackedQuestsFrame is attached to the top.
        questFrame:SetPoint("TOPLEFT", trackerBaseFrame, "TOPLEFT", 0, -10)
    end
end
