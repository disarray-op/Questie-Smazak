---@class AchievementCriteriaCheckmark
local AchievementCriteriaCheckmark = QuestieSmazakLoader:CreateModule("AchievementCriteriaCheckmark")

---@param index number
---@param parent TrackerLineFrame
---@return Button
function AchievementCriteriaCheckmark.New(index, parent)
    local criteriaMark = CreateFrame("Button", "QuestieSmazaklinePool.criteriaMark" .. index, parent)
    criteriaMark.texture = criteriaMark:CreateTexture(nil, "OVERLAY", nil, 0)
    criteriaMark.texture:SetWidth(QuestieSmazak.db.profile.trackerFontSizeObjective)
    criteriaMark.texture:SetHeight(QuestieSmazak.db.profile.trackerFontSizeObjective)
    criteriaMark.texture:SetAllPoints(criteriaMark)

    criteriaMark:SetWidth(1)
    criteriaMark:SetHeight(1)
    criteriaMark:SetPoint("RIGHT", parent.label, "LEFT", -4, 0)
    criteriaMark:SetFrameLevel(100)

    function criteriaMark:SetCriteria(criteria)
        if criteria ~= self.mode then
            self.mode = criteria

            if criteria == true then
                self.texture:SetTexture("Interface\\Addons\\QuestieSmazak\\Icons\\Checkmark")
                ---------------------------------------------------------------------
                -- Just in case we decide to show the minus sign for incompletes
                ---------------------------------------------------------------------
                --self.texture:SetAlpha(1)
                --else
                --self.texture:SetTexture("Interface\\Addons\\QuestieSmazak\\Icons\\Minus")
                --self.texture:SetAlpha(0.5)
                ---------------------------------------------------------------------
            end

            self:SetWidth(QuestieSmazak.db.profile.trackerFontSizeObjective)
            self:SetHeight(QuestieSmazak.db.profile.trackerFontSizeObjective)
        end
    end

    criteriaMark:SetCriteria(false)
    criteriaMark:Hide()

    return criteriaMark
end
