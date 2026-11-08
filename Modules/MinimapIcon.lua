---@class MinimapIcon : QuestieModule
local MinimapIcon = QuestieSmazakLoader:CreateModule("MinimapIcon")
local _MinimapIcon = MinimapIcon.private
-------------------------
--Import modules.
-------------------------
---@type QuestieQuest
local QuestieQuest = QuestieSmazakLoader:ImportModule("QuestieQuest")
---@type QuestieOptions
local QuestieOptions = QuestieSmazakLoader:ImportModule("QuestieOptions")
---@type QuestieJourney
local QuestieJourney = QuestieSmazakLoader:ImportModule("QuestieJourney")
---@type QuestieLib
local QuestieLib = QuestieSmazakLoader:ImportModule("QuestieLib")
---@type QuestieMenu
local QuestieMenu = QuestieSmazakLoader:ImportModule("QuestieMenu")
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieSmazakLoader:ImportModule("QuestieCombatQueue")
---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")
---@type QuestieStatus
local QuestieStatus = QuestieSmazakLoader:ImportModule("QuestieStatus")
---@type QuestieOptionsEngine
local QuestieOptionsEngine = QuestieSmazakLoader:ImportModule("QuestieOptionsEngine")

local _LibDBIcon = LibStub("LibDBIcon-1.0")

local minimapButton
local statusBadge

local statusStyles = {
    [QuestieStatus.Severity.Error] = {
        label = "Error", r = 1, g = 0.2, b = 0.2,
        icon = {atlas = "common-icon-redx", texture = "Interface\\RaidFrame\\ReadyCheck-NotReady"},
    },
    [QuestieStatus.Severity.Warning] = {
        label = "Warning", r = 1, g = 0.82, b = 0,
        icon = {texture = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"},
    },
    [QuestieStatus.Severity.Info] = {
        label = "Information", r = 0.4, g = 0.75, b = 1,
        icon = {texture = "Interface\\FriendsFrame\\InformationIcon"},
    },
}

---@param icon QuestieStatusIcon
---@return boolean loaded
local function _SetStatusTexture(icon)
    -- SetAtlas changes UVs; a later standalone texture must use its whole image.
    statusBadge:SetTexCoord(0, 1, 0, 1)
    if icon.atlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(icon.atlas) then
        statusBadge:SetAtlas(icon.atlas)
        return true
    end
    if icon.texture then
        return statusBadge:SetTexture(icon.texture)
    end
    return false
end

local function _UpdateStatusBadge()
    local issue = QuestieStatus.GetBadgeIssue()
    if not issue then
        statusBadge:Hide()
        return
    end

    if not (issue.icon and _SetStatusTexture(issue.icon)) then
        assert(_SetStatusTexture(statusStyles[issue.severity].icon), "QuestieSmazak minimap status icon could not be loaded")
    end
    statusBadge:Show()
end

local function _AddStatusLines(tooltip)
    for _, issue in ipairs(QuestieStatus.GetIssues()) do
        local style = statusStyles[issue.severity]
        tooltip:AddLine(" ")
        local message = l10n(issue.message, unpack(issue.args or {}))
        tooltip:AddLine(l10n(style.label) .. l10n(": ") .. message, style.r, style.g, style.b, true)
        for _, detail in ipairs(issue.details or {}) do
            local detailMessage = l10n(detail.message, unpack(detail.args or {}))
            tooltip:AddLine("  " .. detailMessage, 0.8, 0.8, 0.8, true)
        end
        if issue.action then
            tooltip:AddLine(l10n(issue.action), 1, 1, 1, true)
        end
    end
end

---@return boolean statusUIReady Whether a status badge was installed and its initial state rendered.
function MinimapIcon:Init()
    _LibDBIcon:Register("QuestieSmazak", _MinimapIcon:CreateDataBrokerObject(), QuestieSmazak.db.profile.minimap)

    minimapButton = _LibDBIcon:GetMinimapButton("QuestieSmazak")

    _MinimapIcon.RepositionIcon()
    if not minimapButton then
        return false
    end

    -- This texture belongs to QuestieSmazak, not LibDBIcon's icon/border machinery. Parent visibility,
    -- scale, and dragging carry it along without replacing any of the library's input scripts.
    statusBadge = minimapButton:CreateTexture(nil, "OVERLAY", nil, 1)
    statusBadge:SetSize(10, 10)
    statusBadge:SetPoint("TOPRIGHT", minimapButton, "TOPRIGHT", -1, -1)
    statusBadge:Hide()
    return QuestieStatus.SetOnChange(_UpdateStatusBadge)
end

function _MinimapIcon:CreateDataBrokerObject()
    local LDBDataObject = LibStub("LibDataBroker-1.1"):NewDataObject("QuestieSmazak", {
        type = "data source",
        text = QuestieSmazak.db.profile.ldbDisplayText,
        icon = "Interface\\Addons\\QuestieSmazak\\Icons\\questie.png",

        OnClick = _MinimapIcon.OnClick,

        ---@param tooltip any
        OnTooltipShow = function (tooltip)
            tooltip:AddDoubleLine(QuestieSmazak:Colorize("Questie-Smazak", 'gold'), QuestieSmazak:Colorize(QuestieLib:GetAddonVersionString(), 'gray'))
            _AddStatusLines(tooltip)
            if not QuestieSmazak.started then
                return
            end
            tooltip:AddLine(" ")
            tooltip:AddDoubleLine(QuestieSmazak:Colorize(l10n('Left Click'), 'lightBlue'), QuestieSmazak:Colorize(l10n('Toggle My Journey'), 'white'))
            tooltip:AddDoubleLine(QuestieSmazak:Colorize(l10n('Right Click'), 'lightBlue'), QuestieSmazak:Colorize(l10n('Toggle Menu'), 'white'))
            tooltip:AddLine(" ")
            tooltip:AddDoubleLine(QuestieSmazak:Colorize(l10n('Shift + Left Click'), 'lightBlue'), QuestieSmazak:Colorize(l10n('QuestieSmazak Options'), 'white'))
            tooltip:AddLine(" ")
            tooltip:AddDoubleLine(QuestieSmazak:Colorize(l10n('Ctrl + Left Click'), 'lightBlue'), QuestieSmazak:Colorize(l10n('Reload QuestieSmazak'), 'white'))
            tooltip:AddDoubleLine(QuestieSmazak:Colorize(l10n('Ctrl + Right Click'), 'lightBlue'), QuestieSmazak:Colorize(l10n('Hide Minimap Button'), 'white'))
            tooltip:AddLine(" ")
            local toggleLabel = QuestieSmazak.db.profile.enabled and l10n('Hide QuestieSmazak') or l10n('Show QuestieSmazak')
            tooltip:AddDoubleLine(QuestieSmazak:Colorize(l10n('Ctrl + Shift + Left Click'), 'lightBlue'), QuestieSmazak:Colorize(toggleLabel, 'white'))
        end,
    })

    self.LDBDataObject = LDBDataObject

    return LDBDataObject
end

function _MinimapIcon.OnClick(_, button)
    if (not QuestieSmazak.started) then
        return
    end

    if button == "LeftButton" then
        if IsShiftKeyDown() and IsControlKeyDown() then
            QuestieSmazak.db.profile.enabled = (not QuestieSmazak.db.profile.enabled)
            QuestieQuest:ToggleNotes(QuestieSmazak.db.profile.enabled)

            if minimapButton and minimapButton:IsMouseOver() then
                local onEnter = minimapButton:GetScript("OnEnter")
                if onEnter then
                    GameTooltip:Hide()
                    onEnter(minimapButton)
                end
            end

            -- Refresh config window if it's open to avoid desyncing the Checkbox
            QuestieOptionsEngine:RefreshStates()
            return
        end

        if IsShiftKeyDown() then
            if QuestieJourney:IsShown() then
                QuestieJourney:ToggleJourneyWindow()
            end
            QuestieOptionsEngine:ToggleConfigWindow()
            return
        end

        if IsControlKeyDown() then
            QuestieQuest:SmoothReset()
            return
        end

        if QuestieOptionsEngine:IsShown() then
            QuestieOptionsEngine:ToggleConfigWindow()
        end
        QuestieJourney:ToggleJourneyWindow()
    elseif button == "RightButton" then
        if IsControlKeyDown() then
            QuestieSmazak.db.profile.minimap.hide = true
            _LibDBIcon:Hide("QuestieSmazak")
            return
        end

        if QuestieMenu.IsOpen() then
            QuestieMenu:Hide()
            return
        end

        QuestieMenu:Show()
    end
end

--- Update the LibDataBroker text
function MinimapIcon:UpdateText(text)
    QuestieSmazak.db.profile.ldbDisplayText = text
    _MinimapIcon.LDBDataObject.text = text
end

---@param shouldShow boolean
function MinimapIcon.Toggle(shouldShow)
    QuestieSmazak.db.profile.minimap.hide = not shouldShow;

    if shouldShow then
        _LibDBIcon:Show("QuestieSmazak")
    else
        _LibDBIcon:Hide("QuestieSmazak")
    end
end

---@param shouldShow boolean
function MinimapIcon.ToggleCompartment(shouldShow)
    if shouldShow then
        _LibDBIcon:AddButtonToCompartment("QuestieSmazak")
    else
        _LibDBIcon:RemoveButtonFromCompartment("QuestieSmazak")
    end

    -- LibDBIcon clears this value when removing the button, so it has to be set afterwards
    QuestieSmazak.db.profile.minimap.showInCompartment = shouldShow
end

--- Points LibDBIcon at the active profile's minimap table and applies its settings
function MinimapIcon.RefreshProfile()
    local minimapDb = QuestieSmazak.db.profile.minimap
    _LibDBIcon:Refresh("QuestieSmazak", minimapDb)
    MinimapIcon.ToggleCompartment(minimapDb.showInCompartment == true)
end

function _MinimapIcon.RepositionIcon()
    local button = _LibDBIcon:GetMinimapButton("QuestieSmazak")
    if button then
        -- Slightly adjust the size and position of the icon to not overlap with the minimap button border
        button.icon:ClearAllPoints()
        button.icon:SetSize(17, 17)
        button.icon:SetPoint("CENTER", 0.5, 0.5)
    end
end