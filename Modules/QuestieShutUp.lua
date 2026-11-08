---@type QuestieCompat
local QuestieCompat = QuestieSmazakLoader:ImportModule("QuestieCompat")

---@class QuestieShutUp
local QuestieShutUp = QuestieSmazakLoader:CreateModule("QuestieShutUp")
---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")

local ChatFrameAddMessageEventFilter = QuestieCompat.AddMessageEventFilter
local ChatFrameRemoveMessageEventFilter = QuestieCompat.RemoveMessageEventFilter

---Registers a chat filter, retrying CreateSecureFiltersArray errors after a delay.
---@param event string
---@param filter function
local function SafeAddMessageEventFilter(event, filter)
    local success, err = pcall(function()
        ChatFrameAddMessageEventFilter(event, filter)
    end)
    if not success then
        if err and string.find(err, "CreateSecureFiltersArray") then
            C_Timer.After(0.1, function()
                SafeAddMessageEventFilter(event, filter)
            end)
        else
            QuestieSmazak.Error("Failed to register chat filter for", event, ":", err)
        end
    end
end

---Removes a chat filter, retrying CreateSecureFiltersArray errors after a delay.
---@param event string
---@param filter function
local function SafeRemoveMessageEventFilter(event, filter)
    local success, err = pcall(function()
        ChatFrameRemoveMessageEventFilter(event, filter)
    end)
    if not success then
        if err and string.find(err, "CreateSecureFiltersArray") then
            C_Timer.After(0.1, function()
                SafeRemoveMessageEventFilter(event, filter)
            end)
        else
            QuestieSmazak.Error("Failed to remove chat filter for", event, ":", err)
        end
    end
end

local stringFind = string.find
local pattern
local patternRU
local pattern_logo

function QuestieShutUp.FilterFunc(self, event, msg, author, ...)
    if stringFind(msg, pattern) or stringFind(msg, pattern_logo) or stringFind(msg, patternRU) then
        return true
    end
end

function QuestieShutUp:ToggleFilters(value)
    if value then
        -- In French a blank is added before the colon, so we need to account for that (%s?)
        pattern = "^" .. "{rt1}" .. " QuestieSmazak%s?: "
        -- ruRU clients don't have {rt1} so we also want to filter these
        patternRU = "^" .. "{звезда}" .. " QuestieSmazak%s?: "
        pattern_logo = "^|TInterface\\Addons\\QuestieSmazak\\Icons\\questie.png:0|t "
        QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "QuestieShutUp toggle on. Pattern:", pattern)
        SafeAddMessageEventFilter("CHAT_MSG_PARTY", QuestieShutUp.FilterFunc)
        SafeAddMessageEventFilter("CHAT_MSG_PARTY_LEADER", QuestieShutUp.FilterFunc)
        SafeAddMessageEventFilter("CHAT_MSG_RAID", QuestieShutUp.FilterFunc)
        SafeAddMessageEventFilter("CHAT_MSG_RAID_LEADER", QuestieShutUp.FilterFunc)
        SafeAddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", QuestieShutUp.FilterFunc)
        SafeAddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", QuestieShutUp.FilterFunc)
    else
        QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "QuestieShutUp toggle off.")
        SafeRemoveMessageEventFilter("CHAT_MSG_PARTY", QuestieShutUp.FilterFunc)
        SafeRemoveMessageEventFilter("CHAT_MSG_PARTY_LEADER", QuestieShutUp.FilterFunc)
        SafeRemoveMessageEventFilter("CHAT_MSG_RAID", QuestieShutUp.FilterFunc)
        SafeRemoveMessageEventFilter("CHAT_MSG_RAID_LEADER", QuestieShutUp.FilterFunc)
        SafeRemoveMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", QuestieShutUp.FilterFunc)
        SafeRemoveMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", QuestieShutUp.FilterFunc)
    end
end