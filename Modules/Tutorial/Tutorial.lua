---@class Tutorial
local Tutorial = QuestieSmazakLoader:CreateModule("Tutorial")

---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieSmazakLoader:ImportModule("QuestieCombatQueue")
---@type Expansions
local Expansions = QuestieSmazakLoader:ImportModule("Expansions")

function Tutorial.Initialize()
    if ((Expansions.Current >= Expansions.Wotlk) or QuestieSmazak.IsForever) and GetCVar("questPOI") ~= nil and (not QuestieSmazak.db.global.tutorialObjectiveTypeChosen) then
        QuestieCombatQueue:Queue(function()
            Tutorial.CreateChooseObjectiveTypeFrame()
        end)
    end

    if QuestieSmazak.IsSoD and (not QuestieSmazak.db.profile.tutorialShowRunesDone) then
        QuestieCombatQueue:Queue(function()
            Tutorial.ShowRunes()
        end)
    end

    if (not QuestieSmazak.db.profile.tutorialRejectInBattlegroundsDone) and not QuestieSmazak.IsForever then
        QuestieCombatQueue:Queue(function()
            Tutorial.AutoRejectInBattlegroundsFrame()
        end)
    end
end
