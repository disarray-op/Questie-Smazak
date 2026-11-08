---@class ExpandZoneButton
local ExpandZoneButton = QuestieSmazakLoader:CreateModule("ExpandZoneButton")

---@type QuestieTracker
local QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker") -- TODO: Remove this explicit dependency
---@type TrackerFadeTicker
local TrackerFadeTicker = QuestieSmazakLoader:ImportModule("TrackerFadeTicker")
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieSmazakLoader:ImportModule("QuestieCombatQueue")
---@type TrackerBaseFrame
local TrackerBaseFrame = QuestieSmazakLoader:ImportModule("TrackerBaseFrame")

---@param index number
---@param parent TrackerLineFrame
---@param OnEnter function @Callback function for OnEnter
---@param OnLeave function @Callback function for OnLeave
---@return Button
function ExpandZoneButton.New(index, parent, OnEnter, OnLeave)
    local expandZone = CreateFrame("Button", "QuestieSmazaklinePool.expandZone" .. index, parent)
    expandZone:SetWidth(1)
    expandZone:SetHeight(1)
    expandZone:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)

    function expandZone:SetMode(mode)
        if mode ~= self.mode then
            self.mode = mode
        end
    end

    expandZone:SetMode(1) -- maximized
    expandZone:EnableMouse(true)
    expandZone:RegisterForDrag("LeftButton")
    expandZone:RegisterForClicks("LeftButtonUp", "LeftButtonDown", "RightButtonUp", "RightButtonDown")

    expandZone:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            if IsShiftKeyDown() then
                -- This sets up the minAllQuestsInZone table upon first click
                if not QuestieSmazak.db.char.collapsedZones[self.zoneId] then
                    if not QuestieSmazak.db.char.minAllQuestsInZone[self.zoneId] then
                        QuestieSmazak.db.char.minAllQuestsInZone[self.zoneId] = {}
                        -- This flag prevents repopulating QuestID's where we don't want them.
                        QuestieSmazak.db.char.minAllQuestsInZone[self.zoneId].isTrue = true

                        QuestieCombatQueue:Queue(function()
                            QuestieTracker:Update()
                        end)
                    end
                end
            end
        end
    end)

    expandZone:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            if self.ignoreNextMouseUp or TrackerBaseFrame.isMoving then
                self.ignoreNextMouseUp = nil
                return
            end

            if IsShiftKeyDown() then
                if not QuestieSmazak.db.char.collapsedZones[self.zoneId] then
                    C_Timer.After(0.1, function()
                        if QuestieSmazak.db.char.minAllQuestsInZone[self.zoneId].isTrue then
                            -- Places all QuestID's into the collapsedQuests table and keeps the Min/Max buttons in sync.
                            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[TrackerLine:minAllQuestsInZone] - Minimize")
                            for questId, _ in pairs(QuestieSmazak.db.char.minAllQuestsInZone[self.zoneId]) do
                                if type(questId) == "number" then
                                    QuestieSmazak.db.char.collapsedQuests[questId] = true
                                end
                            end

                            QuestieSmazak.db.char.minAllQuestsInZone[self.zoneId].isTrue = nil
                        else
                            -- Removes all QuestID's from the collapsedQuests table.
                            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[TrackerLine:minAllQuestsInZone] - Maximize")
                            for questId, _ in pairs(QuestieSmazak.db.char.minAllQuestsInZone[self.zoneId]) do
                                if type(questId) == "number" then
                                    QuestieSmazak.db.char.collapsedQuests[questId] = nil
                                end
                            end

                            QuestieSmazak.db.char.minAllQuestsInZone[self.zoneId] = nil
                        end

                        QuestieCombatQueue:Queue(function()
                            QuestieTracker:Update()
                        end)
                    end)
                end
            else
                if self.mode == 1 then
                    self:SetMode(0)
                    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[TrackerLine:expandZone] - Minimize")
                else
                    self:SetMode(1)
                    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[TrackerLine:expandZone] - Maximize")
                end

                if QuestieSmazak.db.char.collapsedZones[self.zoneId] == true then
                    QuestieSmazak.db.char.collapsedZones[self.zoneId] = nil
                else
                    QuestieSmazak.db.char.collapsedZones[self.zoneId] = true
                end

                QuestieCombatQueue:Queue(function()
                    QuestieTracker:Update()
                end)
            end
        end
    end)

    expandZone:SetScript("OnDragStart", function(self, button)
        if TrackerBaseFrame.OnDragStart(self, button) then
            self.ignoreNextMouseUp = true
        end
    end)

    expandZone:SetScript("OnDragStop", function(self, button)
        TrackerBaseFrame.OnDragStop(self, button)
        C_Timer.After(0, function()
            self.ignoreNextMouseUp = nil
        end)
    end)

    expandZone:SetScript("OnEnter", function(self)
        OnEnter(self)
        TrackerFadeTicker.Unfade()
    end)

    expandZone:SetScript("OnLeave", function(self)
        OnLeave(self)
        TrackerFadeTicker.Fade()
    end)

    expandZone:Hide()

    return expandZone
end
