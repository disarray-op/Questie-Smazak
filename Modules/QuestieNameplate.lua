---@class QuestieNameplate
local QuestieNameplate = QuestieSmazakLoader:CreateModule("QuestieNameplate")
local _QuestieNameplate = {}
-------------------------
--Import modules.
-------------------------
---@type QuestieTooltips
local QuestieTooltips = QuestieSmazakLoader:ImportModule("QuestieTooltips")

local activeGUIDs = {}
local npFrames = {}
local npUnusedFrames = {}
local npFramesCount = 0

local activeTargetFrame


---@param token string
function QuestieNameplate:NameplateCreated(token)
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_SPAM, "[QuestieNameplate:NameplateCreated]")
    -- if nameplates are disabled, don't create new nameplates.
    if (not QuestieSmazak.db.profile.nameplateEnabled) or (QuestieSmazak.IsForever and IsInInstance()) then
        return
    end

    -- to avoid memory issues
    if npFramesCount >= 300 then
        return
    end

    local unitGUID = UnitGUID(token)
    local unitName, _ = UnitName(token)

    if (not unitGUID) or (not unitName) then
        return
    end

    local unitType, _, _, _, _, _, _ = strsplit("-", unitGUID)
    if unitType ~= "Creature" and unitType ~= "Vehicle" then
        -- We only draw name plates on NPCs/creatures and Vehicles (oddness with Chillmaw being a Vehicle?!?!) and skip players, pets, etc
        return
    end

    local icon = QuestieNameplate.GetIcon(unitGUID)

    if icon then
        activeGUIDs[unitGUID] = token

        local f = _QuestieNameplate.GetFrame(unitGUID)
        f.Icon:SetTexture(icon)
        f.lastIcon = icon -- this is used to prevent updating the texture when it's already what it needs to be
        f:Show()
    end
end

---@param token string
function QuestieNameplate:NameplateDestroyed(token)
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_SPAM, "[QuestieNameplate:NameplateDestroyed]")

    -- The removed unit's GUID may be missing or restricted. Clean up the identity we recorded at creation.
    for guid, activeToken in pairs(activeGUIDs) do
        if activeToken == token then
            activeGUIDs[guid] = nil
            _QuestieNameplate.RemoveFrame(guid)
        end
    end
end

function QuestieNameplate:UpdateNameplate()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_SPAM, "[QuestieNameplate:UpdateNameplate]")

    for guid, token in pairs(activeGUIDs) do
        local unitName, _ = UnitName(token)
        if unitName then
            local icon = QuestieNameplate.GetIcon(guid)

            if icon then
                local frame = _QuestieNameplate.GetFrame(guid)
                -- check if the texture needs to be changed
                if frame.lastIcon ~= icon then
                    frame.lastIcon = icon
                    frame.Icon:SetTexture(icon)
                end
            else
                -- tooltip removed but we still have the frame active, remove it
                activeGUIDs[guid] = nil
                _QuestieNameplate.RemoveFrame(guid)
            end
        end
    end
end

---@param xPos number
---@param yPos number
---@param scale number
function QuestieNameplate.SetIconPosition(xPos, yPos, scale)
    QuestieNameplate.SetIconXPosition(xPos)
    QuestieNameplate.SetIconYPosition(yPos)
    QuestieNameplate.SetIconScale(scale)

    QuestieNameplate:RedrawIcons()
end

---@param xPos number
function QuestieNameplate.SetIconXPosition(xPos)
    if (type(xPos) ~= "number") then
        return
    end

    QuestieSmazak.db.profile.nameplateX = xPos
end

---@param yPos number
function QuestieNameplate.SetIconYPosition(yPos)
    if (type(yPos) ~= "number") then
        return
    end

    QuestieSmazak.db.profile.nameplateY = yPos
end

---@param scale number
function QuestieNameplate.SetIconScale(scale)
    if (type(scale) ~= "number") then
        return
    end

    QuestieSmazak.db.profile.nameplateScale = scale
end

function QuestieNameplate:RedrawIcons()
    for _, frame in pairs(npFrames) do
        local iconScale = QuestieSmazak.db.profile.nameplateScale

        frame:SetPoint("LEFT", QuestieSmazak.db.profile.nameplateX, QuestieSmazak.db.profile.nameplateY)
        frame:SetWidth(16 * iconScale)
        frame:SetHeight(16 * iconScale)
    end
end

function QuestieNameplate:HideCurrentFrames()
    for guid, _ in pairs(activeGUIDs) do
        activeGUIDs[guid] = nil
        _QuestieNameplate.RemoveFrame(guid)
    end
end

---@param guid string
---@return string | nil
function QuestieNameplate.GetIcon(guid)
    if (not guid) then
        return nil
    end

    local _, _, _, _, _, npcId, _ = strsplit("-", guid)
    if (not npcId) then
        return nil
    end

    return _QuestieNameplate.GetValidIcon(QuestieTooltips.lookupByKey["m_" .. npcId])
end

function QuestieNameplate:DrawTargetFrame()
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_SPAM, "[QuestieNameplate:DrawTargetFrame]")

    if (not QuestieSmazak.db.profile.nameplateTargetFrameEnabled) or (QuestieSmazak.IsForever and IsInInstance()) then
        return
    end

    -- always remove the previous frame if it exists
    if activeTargetFrame ~= nil then
        activeTargetFrame.Icon:SetTexture(nil)
        activeTargetFrame:Hide()
    end

    local unitGUID = UnitGUID("target")
    local unitName = UnitName("target")

    if (not unitName) or (not unitGUID) then
        -- We need the GUID and name, this should not happen
        return
    end

    local unitType, _, _, _, _, _, _ = strsplit("-", unitGUID)
    if unitType ~= "Creature" and unitType ~= "Vehicle" then
        -- We only draw name plates on NPCs/creatures and Vehicles (oddness with Chillmaw being a Vehicle?!?!) and skip players, pets, etc
        return
    end

    local icon = QuestieNameplate.GetIcon(unitGUID)
    if (not icon) then
        return
    end

    if not activeTargetFrame then
        activeTargetFrame = _QuestieNameplate.GetTargetFrameIconFrame()
    end

    activeTargetFrame.Icon:SetTexture(icon)
    activeTargetFrame:Show()
end

function QuestieNameplate:HideCurrentTargetFrame()
    if (not activeTargetFrame) then
        return
    end

    activeTargetFrame.Icon:SetTexture(nil)
    activeTargetFrame:Hide()
    activeTargetFrame = nil
end

function QuestieNameplate:RedrawFrameIcon()
    if (not QuestieSmazak.db.profile.nameplateTargetFrameEnabled) or (not activeTargetFrame) then
        return
    end

    local iconScale = QuestieSmazak.db.profile.nameplateTargetFrameScale
    activeTargetFrame:SetWidth(16 * iconScale)
    activeTargetFrame:SetHeight(16 * iconScale)
    activeTargetFrame:SetPoint("RIGHT", QuestieSmazak.db.profile.nameplateTargetFrameX, QuestieSmazak.db.profile.nameplateTargetFrameY)
end

---@param guid string
function _QuestieNameplate.GetFrame(guid)
    if npFrames[guid] then
        return npFrames[guid]
    end

    local parent = C_NamePlate.GetNamePlateForUnit(activeGUIDs[guid])

    local frame = tremove(npUnusedFrames)

    if (not frame) then
        frame = CreateFrame("Frame")
        npFramesCount = npFramesCount + 1
    end

    local iconScale = QuestieSmazak.db.profile.nameplateScale

    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(10)
    frame:SetWidth(16 * iconScale)
    frame:SetHeight(16 * iconScale)
    frame:EnableMouse(false)
    frame:SetParent(parent)
    frame:SetPoint("LEFT", QuestieSmazak.db.profile.nameplateX, QuestieSmazak.db.profile.nameplateY)

    frame.Icon = frame:CreateTexture(nil, "ARTWORK")
    frame.Icon:ClearAllPoints()
    frame.Icon:SetAllPoints(frame)

    npFrames[guid] = frame

    return frame
end

function _QuestieNameplate.GetTargetFrameIconFrame()
    local frame = CreateFrame("Frame")

    local iconScale = QuestieSmazak.db.profile.nameplateTargetFrameScale
    local strata = "MEDIUM"

    local targetFrame = TargetFrame -- Default Blizzard target frame
    if ElvUF_Target then
        targetFrame = ElvUF_Target
        strata = "LOW"
    elseif PitBull4_Frames_Target then
        targetFrame = PitBull4_Frames_Target
    elseif AzeriteUnitFrameTarget then
        targetFrame = AzeriteUnitFrameTarget
        strata = "LOW"
    elseif GwTargetUnitFrame then
        targetFrame = GwTargetUnitFrame
        strata = "LOW"
    elseif InvenUnitFrames_Target then
        targetFrame = InvenUnitFrames_Target
        strata = "LOW"
    elseif SUFUnittarget then
        targetFrame = SUFUnittarget
        frame:SetFrameLevel(SUFUnittarget:GetFrameLevel() + 1)
    elseif XPerl_Target then
        targetFrame = XPerl_Target
    end

    frame:SetParent(targetFrame)
    frame:SetFrameStrata(strata)
    frame:SetFrameLevel(11)
    frame:SetWidth(16 * iconScale)
    frame:SetHeight(16 * iconScale)
    frame:EnableMouse(false)

    frame:SetPoint("RIGHT", QuestieSmazak.db.profile.nameplateTargetFrameX, QuestieSmazak.db.profile.nameplateTargetFrameY)

    frame.Icon = frame:CreateTexture(nil, "ARTWORK")
    frame.Icon:ClearAllPoints()
    frame.Icon:SetAllPoints(frame)

    return frame
end

---@param guid string
function _QuestieNameplate.RemoveFrame(guid)
    if (not npFrames[guid]) then
        return
    end

    table.insert(npUnusedFrames, npFrames[guid])
    npFrames[guid].Icon:SetTexture(nil) -- fix for overlapping icons
    npFrames[guid]:Hide()
    npFrames[guid] = nil
end

---@param tooltips table<string, table>
function _QuestieNameplate.GetValidIcon(tooltips) -- helper function to get the first valid (incomplete) icon from the specified tooltip, or nil if there is none
    if (not tooltips) then
        return
    end

    for _, tooltip in pairs(tooltips) do
        if tooltip.objective and tooltip.objective.Update then
            tooltip.objective:Update() -- get latest qlog data if its outdated
            if (not tooltip.objective.Completed) and tooltip.objective.Icon then
                -- If the tooltip icon is QuestieSmazak.ICON_TYPE_OBJECT we use QuestieSmazak.ICON_TYPE_LOOT because NPCs should never show
                -- a cogwheel icon (for pfquest only).
                local iconType = tooltip.objective.Icon
                if iconType == QuestieSmazak.ICON_TYPE_LOOT then
                    return QuestieSmazak.db.profile.iconTheme == 'pfquest' and QuestieSmazak.icons["loot"] or QuestieSmazak.db.profile.ICON_LOOT or QuestieSmazak.icons["loot"]
                elseif iconType == QuestieSmazak.ICON_TYPE_OBJECT then
                    return QuestieSmazak.db.profile.iconTheme == 'pfquest' and QuestieSmazak.icons["loot"] or QuestieSmazak.db.profile.ICON_LOOT or QuestieSmazak.icons["loot"]
                elseif iconType == QuestieSmazak.ICON_TYPE_SLAY then
                    return QuestieSmazak.db.profile.iconTheme == 'pfquest' and QuestieSmazak.icons["slay"] or QuestieSmazak.db.profile.ICON_SLAY or QuestieSmazak.icons["slay"]
                elseif iconType == QuestieSmazak.ICON_TYPE_EVENT then
                    return QuestieSmazak.db.profile.iconTheme == 'pfquest' and QuestieSmazak.icons["event"] or QuestieSmazak.db.profile.ICON_EVENT or QuestieSmazak.icons["event"]
                elseif iconType == QuestieSmazak.ICON_TYPE_TALK then
                    return QuestieSmazak.db.profile.iconTheme == 'pfquest' and QuestieSmazak.icons["talk"] or QuestieSmazak.db.profile.ICON_TALK or QuestieSmazak.icons["talk"]
                elseif iconType == QuestieSmazak.ICON_TYPE_INTERACT then
                    return QuestieSmazak.db.profile.iconTheme == 'pfquest' and QuestieSmazak.icons["interact"] or QuestieSmazak.db.profile.ICON_INTERACT or QuestieSmazak.icons["interact"]
                elseif iconType == QuestieSmazak.ICON_TYPE_MOUNT_UP then
                    return QuestieSmazak.db.profile.iconTheme == 'pfquest' and QuestieSmazak.icons["mount_up"] or QuestieSmazak.db.profile.MOUNT_UP or QuestieSmazak.icons["mount_up"]
                elseif iconType == QuestieSmazak.ICON_TYPE_PET_BATTLE then
                    return QuestieSmazak.db.profile.iconTheme == 'pfquest' and QuestieSmazak.icons["petbattle"] or QuestieSmazak.db.profile.ICON_TYPE_PET_BATTLE or QuestieSmazak.icons["petbattle"]
                --? icon types below here are never reached or just not used on nameplates ?
                elseif iconType == QuestieSmazak.ICON_TYPE_AVAILABLE or iconType == QuestieSmazak.ICON_TYPE_AVAILABLE_GRAY then
                    return QuestieSmazak.icons["available"]
                elseif iconType == QuestieSmazak.ICON_TYPE_REPEATABLE then
                    return QuestieSmazak.icons["repeatable"]
                elseif iconType == QuestieSmazak.ICON_TYPE_COMPLETE then
                    return QuestieSmazak.icons["complete"]
                end
            end
        end
    end
end
