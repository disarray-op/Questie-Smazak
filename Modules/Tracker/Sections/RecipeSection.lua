---@class RecipeSection
local RecipeSection = QuestieSmazakLoader:CreateModule("RecipeSection")

---@type LineBuilder
local LineBuilder = QuestieSmazakLoader:ImportModule("LineBuilder")
---@type TrackerRecipes
local TrackerRecipes = QuestieSmazakLoader:ImportModule("TrackerRecipes")
---@type QuestieLib
local QuestieLib = QuestieSmazakLoader:ImportModule("QuestieLib")
---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")

local ZONE_NAME = "Recipes"

function RecipeSection.Draw()
    local recipes = TrackerRecipes.GetTrackedRecipes()
    if #recipes == 0 then
        return
    end

    local line, collapsed = LineBuilder.AddHeader({key = ZONE_NAME, text = l10n("Recipes")})
    if (not line) then
        return
    end

    if collapsed then
        return
    end

    for _, recipe in ipairs(recipes) do
        line = LineBuilder.AddTitle({text = recipe.Name, clickMode = "recipe", target = recipe})
        if (not line) then
            return
        end

        for _, reagent in ipairs(recipe.Reagents) do
            local colorCollected = math.min(reagent.Collected, reagent.Needed)
            line = LineBuilder.AddObjective({
                text = QuestieLib:GetRGBForObjective({Collected = colorCollected, Needed = reagent.Needed}) ..
                    reagent.Name .. ": " .. reagent.Collected .. "/" .. reagent.Needed,
                clickMode = "recipe",
                target = recipe,
            })
            if (not line) then
                return
            end
        end

        LineBuilder.FinishEntry(line)
    end
end
