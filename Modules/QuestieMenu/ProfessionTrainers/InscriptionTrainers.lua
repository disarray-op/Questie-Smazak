---@type Townsfolk
local Townsfolk = QuestieSmazakLoader:ImportModule("Townsfolk")
---@type QuestieProfessions
local QuestieProfessions = QuestieSmazakLoader:ImportModule("QuestieProfessions")

---@type NpcId[]
local trainers = {}

if QuestieSmazak.IsMoP then
    trainers = {
        25263,26916,26959,26977,26995,28702,30706,30709,30710,30711,30713,30715,30716,30717,30721,30722,33603,33638,33679,45286,
        46716,47384,47396,47400,47418,47419,47420,47421,47431,48619,50247,56065,57620,62327,64691,65043,66355,
    }
elseif QuestieSmazak.IsCata then
    trainers = {
        25263,26916,26959,26977,26995,28702,30706,30709,30710,30711,30713,30715,30716,30717,30721,30722,33603,33638,33679,45286,
        46716,47384,47396,47400,47418,47419,47420,47421,47431,48619,50247,
    }
elseif QuestieSmazak.IsWotlk then
    trainers = {
        26916,26959,26977,26995,28702,30706,30709,30710,30711,30713,30715,30716,30717,30721,30722,33603,33638,33679,
    }
end

Townsfolk.SetProfessionTrainerIds(QuestieProfessions.professionKeys.INSCRIPTION, trainers)
