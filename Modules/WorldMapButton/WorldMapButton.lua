---@class WorldMapButton
---@field Initialize function
local WorldMapButton = QuestieSmazakLoader:CreateModule("WorldMapButton")

---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")
---@type QuestieLib
local QuestieLib = QuestieSmazakLoader:ImportModule("QuestieLib")
---@type QuestieQuest
local QuestieQuest = QuestieSmazakLoader:ImportModule("QuestieQuest")
---@type QuestieMenu
local QuestieMenu = QuestieSmazakLoader:ImportModule("QuestieMenu")
---@type QuestieOptionsEngine
local QuestieOptionsEngine = QuestieSmazakLoader:ImportModule("QuestieOptionsEngine")

local KButtons = LibStub("Krowi_WorldMapButtons-1.4")
if QuestieSmazak.IsForever then
    -- Krowi classifies version 1.x as the old Classic map. Forever has modern overlay buttons;
    -- its old-map workaround reparents them away from the map and breaks GetMapID/TriggerEvent.
    KButtons.HasNoOverlay = false
end

---@type AceConfigDialog-3.0
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local mapButton

function WorldMapButton.Initialize()
    mapButton = KButtons:Add("QuestieSmazakWorldMapButtonTemplate", "BUTTON")

    QuestieSmazak.WorldMap = {
        Button = mapButton
    }

    WorldMapButton.Toggle(QuestieSmazak.db.profile.mapShowHideEnabled)
end

---@param shouldShow boolean
function WorldMapButton.Toggle(shouldShow)
    if shouldShow then
        mapButton:Show()
    else
        mapButton:Hide()
    end
end

---@param self Frame
---@return nil
local function UpdateTooltip(self)
    local tooltip = GameTooltip
    tooltip:SetOwner(self, "ANCHOR_NONE");
    tooltip:ClearLines()
    tooltip:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 0);
    tooltip:AddDoubleLine(QuestieSmazak:Colorize("Questie-Smazak", 'gold'), QuestieSmazak:Colorize(QuestieLib:GetAddonVersionString(), 'gray'))
    tooltip:AddLine(" ")
    local toggleLabel = QuestieSmazak.db.profile.enabled and l10n('Hide QuestieSmazak') or l10n('Show QuestieSmazak')
    tooltip:AddDoubleLine(QuestieSmazak:Colorize(l10n('Left Click'), 'lightBlue'), QuestieSmazak:Colorize(toggleLabel, 'white'))
    tooltip:AddDoubleLine(QuestieSmazak:Colorize(l10n('Right Click'), 'lightBlue'), QuestieSmazak:Colorize(l10n('Toggle Menu'), 'white'))
    tooltip:Show()
end

QuestieSmazakWorldMapButtonMixin = {
    OnLoad = function() end,
    OnHide = function() end,
    OnMouseDown = function(_, button)
        if button == "LeftButton" then
            QuestieSmazak.db.profile.enabled = (not QuestieSmazak.db.profile.enabled)
            QuestieQuest:ToggleNotes(QuestieSmazak.db.profile.enabled)
            if GameTooltip:IsShown() and GameTooltip:GetOwner() == mapButton then
                UpdateTooltip(mapButton)
            end
            -- Refresh options UI if open to reflect new state
            QuestieOptionsEngine:RefreshStates()
        elseif button == "RightButton" then
            if QuestieMenu.IsOpen() then
                QuestieMenu:Hide()
            else
                QuestieMenu:Show()
            end
        end
    end,
    OnMouseUp = function() end,
    OnEnter = function(self)
        UpdateTooltip(self)
    end,
    OnLeave = function() end,
    OnClick = function() end, -- Only fires on left click
    Refresh = function() end,
}
