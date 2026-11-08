---@type QuestieCompat
local QuestieCompat = QuestieSmazakLoader:ImportModule("QuestieCompat")

---@class TrackerLine
local TrackerLine = QuestieSmazakLoader:CreateModule("TrackerLine")

---@type QuestieTracker
local QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker") -- TODO: Remove this explicit dependency
---@type TrackerUtils
local TrackerUtils = QuestieSmazakLoader:ImportModule("TrackerUtils")
---@type TrackerBaseFrame
local TrackerBaseFrame = QuestieSmazakLoader:ImportModule("TrackerBaseFrame")
---@type TrackerQuestTimers
local TrackerQuestTimers = QuestieSmazakLoader:ImportModule("TrackerQuestTimers")
---@type TrackerFadeTicker
local TrackerFadeTicker = QuestieSmazakLoader:ImportModule("TrackerFadeTicker")
---@type TrackerMenu
local TrackerMenu = QuestieSmazakLoader:ImportModule("TrackerMenu")
---@type VoiceOverPlayButton
local VoiceOverPlayButton = QuestieSmazakLoader:ImportModule("VoiceOverPlayButton")
---@type SpokenPlayButton
local SpokenPlayButton = QuestieSmazakLoader:ImportModule("SpokenPlayButton")
---@type AchievementCriteriaCheckmark
local AchievementCriteriaCheckmark = QuestieSmazakLoader:ImportModule("AchievementCriteriaCheckmark")
---@type ExpandQuestButton
local ExpandQuestButton = QuestieSmazakLoader:ImportModule("ExpandQuestButton")
---@type QuestFocusButton
local QuestFocusButton = QuestieSmazakLoader:ImportModule("QuestFocusButton")
---@type ExpandZoneButton
local ExpandZoneButton = QuestieSmazakLoader:ImportModule("ExpandZoneButton")
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieSmazakLoader:ImportModule("QuestieCombatQueue")
---@type TrackerData
local TrackerData = QuestieSmazakLoader:ImportModule("TrackerData")
---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")
---@type Expansions
local Expansions = QuestieSmazakLoader:ImportModule("Expansions")
---@type AchievementTracking
local AchievementTracking = QuestieSmazakLoader:ImportModule("AchievementTracking")
---@type TrackerRecipes
local TrackerRecipes = QuestieSmazakLoader:ImportModule("TrackerRecipes")

local LSM30 = LibStub("LibSharedMedia-3.0")
local LibDropDown = LibStub:GetLibrary("LibUIDropDownMenuQuestie-4.0")

local _SetMode, _OnClickQuest, _OnClickAchieve, _OnClickRecipe

local lineMarginLeft = 10

---@param index number
---@param parent ScrollFrame
---@param previousLine TrackerLineFrame?
---@param OnEnter function @Callback function for OnEnter
---@param OnLeave function @Callback function for OnLeave
---@param OnQuestAdded function @Callback function for SetQuest
---@param OnScenarioCriteriaAdded function @Callback function for SetScenarioCriteria
---@return TrackerLineFrame
function TrackerLine.New(index, parent, previousLine, OnEnter, OnLeave, OnQuestAdded, OnScenarioCriteriaAdded)
    local timeElapsed = 0
    ---@class TrackerLineFrame : Button
    local line = CreateFrame("Button", "QuestieSmazaklinePool" .. index, parent)
    line:SetWidth(1)
    line:SetHeight(1)
    line.label = line:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    line.label:SetJustifyH("LEFT")
    line.label:SetJustifyV("TOP")
    line.label:SetPoint("TOPLEFT", line)
    line.label:Hide()

    if previousLine then
        line:SetPoint("TOPLEFT", previousLine, "BOTTOMLEFT", 0, 0)
    else
        line:SetPoint("TOPLEFT", parent, "TOPLEFT", lineMarginLeft, 0)
    end

    line.SetMode = _SetMode

    function line:SetZone(zoneId)
        if type(zoneId) == "string" then
            self.expandZone.zoneId = zoneId
        elseif type(zoneId) == "number" then
            self.ZoneId = TrackerUtils:GetZoneNameByID(zoneId)
            self.expandZone.zoneId = zoneId
        end
    end

    function line:SetQuest(quest)
        self.Quest = quest
        self.Recipe = nil
        self.expandQuest.questId = quest.Id

        OnQuestAdded(quest.Id, self)

        -- Set Timed Quest Flag
        if quest.trackTimedQuest then
            self.trackTimedQuest = quest.trackTimedQuest
        end
    end

    function line:SetObjective(objective)
        self.Objective = objective
    end

    ---@param recipe TrackerRecipe
    function line:SetRecipe(recipe)
        self.Recipe = recipe
        self.Quest = nil
        self.Objective = nil
    end

    function line:SetScenarioCriteria(objective)
        self.Objective = objective
        OnScenarioCriteriaAdded(objective.Id, self)
    end

    function line:OnUpdate(elapsed)
        if Expansions.Current >= Expansions.Wotlk then
            timeElapsed = timeElapsed + elapsed

            if timeElapsed > 1 and self.trackTimedQuest and self.label.activeTimer then
                local _, timeRemaining = TrackerQuestTimers:GetRemainingTimeByQuestId(self.Quest.Id)

                if timeRemaining ~= nil then
                    if timeRemaining > 1 then
                        TrackerQuestTimers:UpdateTimerFrame()
                    end

                    if timeRemaining == 1 then
                        TrackerQuestTimers:UpdateTimerFrame()
                    end

                    timeElapsed = 0
                else
                    self.label:SetText("")
                    timeElapsed = 0
                    return
                end
            end
        else
            return
        end
    end

    line:EnableMouse(true)
    line:RegisterForDrag("LeftButton")
    line:RegisterForClicks("RightButtonUp", "LeftButtonUp")

    function line:SetOnClick(onClickMode)
        if onClickMode == "quest" then
            self:SetScript("OnClick", _OnClickQuest)
        elseif onClickMode == "achieve" then
            self:SetScript("OnClick", _OnClickAchieve)
        elseif onClickMode == "recipe" then
            self:SetScript("OnClick", _OnClickRecipe)
        end
    end

    line:SetScript("OnDragStart", TrackerBaseFrame.OnDragStart)
    line:SetScript("OnDragStop", TrackerBaseFrame.OnDragStop)

    line:SetScript("OnEnter", function(self)
        OnEnter(self)
        TrackerFadeTicker.Unfade()
    end)

    line:SetScript("OnLeave", function(self)
        OnLeave(self)
        TrackerFadeTicker.Fade()
    end)

    line.criteriaMark = AchievementCriteriaCheckmark.New(index, line)
    line.expandZone = ExpandZoneButton.New(index, line, OnEnter, OnLeave)
    if TrackerUtils:IsSpokenLoaded() then
        line.playButton = SpokenPlayButton.New(index, line)
    else
        line.playButton = VoiceOverPlayButton.New(index, line)
    end
    line.expandQuest = ExpandQuestButton.New(index, line)
    line.questFocus = QuestFocusButton.New(index, line)

    -- Hovering a button in front of the title highlights the quest like hovering the line itself
    for _, button in ipairs({line.questFocus, line.playButton, line.expandQuest}) do
        button:HookScript("OnEnter", function()
            OnEnter(line)
        end)
        button:HookScript("OnLeave", function()
            OnLeave(line)
        end)
    end

    return line
end


---@param mode string
_SetMode = function(self, mode)
    if mode ~= self.mode then
        self.mode = mode
        if mode == "zone" then
            local trackerFontSizeZone = QuestieSmazak.db.profile.trackerFontSizeZone
            self.label:SetFont(LSM30:Fetch("font", QuestieSmazak.db.profile.trackerFontZone), trackerFontSizeZone, QuestieSmazak.db.profile.trackerFontOutline)
            self.label:SetHeight(trackerFontSizeZone)
        elseif mode == "quest" or mode == "achieve" then
            local trackerFontSizeQuest = QuestieSmazak.db.profile.trackerFontSizeQuest
            self.label:SetFont(LSM30:Fetch("font", QuestieSmazak.db.profile.trackerFontQuest), trackerFontSizeQuest, QuestieSmazak.db.profile.trackerFontOutline)
            self.label:SetHeight(trackerFontSizeQuest)
        elseif mode == "objective" then
            local trackerFontSizeObjective = QuestieSmazak.db.profile.trackerFontSizeObjective
            self.label:SetFont(LSM30:Fetch("font", QuestieSmazak.db.profile.trackerFontObjective), trackerFontSizeObjective, QuestieSmazak.db.profile.trackerFontOutline)
            self.label:SetHeight(trackerFontSizeObjective)
        end
    end
end


---@param button string
_OnClickQuest = function(self, button)
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[TrackerLine:_OnClickQuest]")
    if (not self.Quest) then
        return
    end

    if TrackerMenu.menuFrame:IsShown() then
        LibDropDown:CloseDropDownMenus()
    end

    if TrackerUtils:IsBindTrue(QuestieSmazak.db.profile.trackerbindSetTomTom, button) then
        TrackerUtils.SetQuestTomTomTarget(self.Quest.Id, self.Quest.enrichment)
    elseif TrackerUtils:IsBindTrue(QuestieSmazak.db.profile.trackerbindUntrack, button) then
        if (IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow()) then
            ChatEdit_InsertLink(TrackerData.GetQuestLink(self.Quest))
        else
            QuestieTracker:UntrackQuestId(self.Quest.Id)
            local questLogFrame = QuestLogExFrame or ClassicQuestLog or QuestLogFrame
            if questLogFrame and questLogFrame:IsShown() then
                QuestieCompat.QuestLog_Update()
            end
        end
    elseif TrackerUtils:IsBindTrue(QuestieSmazak.db.profile.trackerbindOpenQuestLog, button) then
        TrackerUtils:ShowQuestLog(self.Quest)
    elseif button == "RightButton" then
        local menu = TrackerMenu:GetMenuForQuest(self.Quest)
        LibDropDown:EasyMenu(menu, TrackerMenu.menuFrame, "cursor", 0, 0, "MENU")
    end
end

---@param button string
_OnClickAchieve = function(self, button)
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[TrackerLine:_OnClickAchieve]")
    if (not self.Quest) then
        return
    end

    if TrackerMenu.menuFrame:IsShown() then
        LibDropDown:CloseDropDownMenus()
    end

    if TrackerUtils:IsBindTrue(QuestieSmazak.db.profile.trackerbindUntrack, button) then
        if (IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow()) then
            ChatEdit_InsertLink(GetAchievementLink(self.Quest.Id))
        else
            if AchievementTracking.IsTracked(self.Quest.Id) then
                AchievementTracking.Untrack(self.Quest.Id)

                if (not AchievementFrame) then
                    AchievementFrame_LoadUI()
                end

                QuestieCompat.AchievementFrameAchievements_ForceUpdate()

                QuestieCombatQueue:Queue(function()
                    QuestieTracker:Update()
                end)
            else
                -- Assume this is an Objective of an Achievement
                UIErrorsFrame:AddMessage(format(l10n("You can't untrack an objective of an achievement.")), 1.0, 0.1, 0.1, 1.0)
            end
        end
    elseif TrackerUtils:IsBindTrue(QuestieSmazak.db.profile.trackerbindOpenQuestLog, button) then
        if (not AchievementFrame) then
            AchievementFrame_LoadUI()
        end

        if (not AchievementFrame:IsShown()) then
            QuestieCompat.AchievementFrame_ToggleAchievementFrame()
            QuestieCompat.AchievementFrame_SelectAchievement(self.Quest.Id)
        else
            if (AchievementFrameAchievements.selection ~= self.Quest.Id) then
                QuestieCompat.AchievementFrame_SelectAchievement(self.Quest.Id)
            end
        end
    elseif button == "RightButton" then
        local menu = TrackerMenu:GetMenuForAchievement(self.Quest)
        LibDropDown:EasyMenu(menu, TrackerMenu.menuFrame, "cursor", 0, 0, "MENU")
    end
end

---@param button string
_OnClickRecipe = function(self, button)
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[TrackerLine:_OnClickRecipe]")
    if (not self.Recipe) then
        return
    end

    if TrackerMenu.menuFrame:IsShown() then
        LibDropDown:CloseDropDownMenus()
    end

    if TrackerUtils:IsBindTrue(QuestieSmazak.db.profile.trackerbindUntrack, button) then
        if (IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow()) then
            ChatEdit_InsertLink(TrackerRecipes.GetLink(self.Recipe.Id))
        else
            TrackerRecipes.Untrack(self.Recipe.Id)
        end
    elseif TrackerUtils:IsBindTrue(QuestieSmazak.db.profile.trackerbindOpenQuestLog, button) then
        TrackerRecipes.OpenRecipe(self.Recipe.Id)
    end
end
