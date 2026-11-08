---@class AchievementSection
local AchievementSection = QuestieSmazakLoader:CreateModule("AchievementSection")

---@type AchievementTracking
local AchievementTracking = QuestieSmazakLoader:ImportModule("AchievementTracking")
---@type LineBuilder
local LineBuilder = QuestieSmazakLoader:ImportModule("LineBuilder")
---@type TrackerAchievements
local TrackerAchievements = QuestieSmazakLoader:ImportModule("TrackerAchievements")
---@type QuestieLib
local QuestieLib = QuestieSmazakLoader:ImportModule("QuestieLib")
---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")

local ZONE_NAME = "Achievements"

function AchievementSection.Draw()
    local objectiveColor = QuestieSmazak.db.profile.trackerColorObjectives
    local line, zoneCheck

    -- Tracked achievements are listed under their own "Zone" called Achievements.
    local firstAchieveInZone = false

    local achievementIds = AchievementTracking.GetTrackedIds()

    for _, achieve in ipairs(TrackerAchievements.GetAchievements(achievementIds)) do
        -- Add Achievement Zone
        if zoneCheck ~= ZONE_NAME then
            firstAchieveInZone = true
        end

        if firstAchieveInZone then
            line = LineBuilder.AddHeader({
                key = ZONE_NAME,
                text = l10n("Achievements") .. ": " .. #achievementIds .. "/" .. AchievementTracking.GetMaxTracked(),
                collapsedText = l10n("Achievements") .. " +",
            })
            if (not line) then
                break
            end

            firstAchieveInZone = false
            zoneCheck = ZONE_NAME
        end

        -- Add Achievements
        if (not QuestieSmazak.db.char.collapsedZones[ZONE_NAME]) then
            local title = achieve.Name
            if QuestieSmazak.db.profile.enableTooltipsQuestID then
                title = title .. " (" .. achieve.Id .. ")"
            end

            local collapsed
            line, collapsed = LineBuilder.AddTitle({
                text = title,
                clickMode = "achieve",
                target = achieve,
                collapseId = achieve.Id,
                zoneKey = ZONE_NAME,
            })
            if (not line) then
                break
            end

            -- Add achievement Objectives (if applicable)
            if (not collapsed) then
                for _, criteria in ipairs(achieve.Criteria) do
                    if criteria.IsDescription then
                        -- Achievements without criteria show their description
                        line = LineBuilder.AddObjective({
                            text = QuestieLib:GetRGBForObjective(criteria) .. criteria.Text,
                            clickMode = "achieve",
                            target = achieve,
                        })
                        if (not line) then
                            return
                        end
                    else
                        local target = achieve
                        if criteria.LinkedAchievementId then
                            target = {Id = criteria.LinkedAchievementId}
                        end

                        local text = QuestieLib:GetRGBForObjective(criteria) .. criteria.Text
                        if criteria.Progress then
                            text = text .. ": " .. criteria.Progress
                        end

                        line = LineBuilder.AddObjective({text = text, clickMode = "achieve", target = target})
                        if (not line) then
                            break
                        end

                        -- Criteria without progress show a mark instead
                        if (not criteria.Progress) and (not QuestieSmazak.db.profile.hideCompletedAchieveObjectives) and (not objectiveColor or objectiveColor == "white") then
                            line.criteriaMark:SetCriteria(criteria.Completed)

                            if line.criteriaMark.mode == true then
                                line.criteriaMark:Show()
                            end
                        end
                    end
                end
            end

            LineBuilder.FinishEntry(line)
        end
    end
end
