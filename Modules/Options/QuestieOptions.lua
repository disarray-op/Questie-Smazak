---@type QuestieCompat
local QuestieCompat = QuestieSmazakLoader:ImportModule("QuestieCompat")

---@class QuestieOptions
local QuestieOptions = QuestieSmazakLoader:CreateModule("QuestieOptions");
-------------------------
--Import modules.
-------------------------
---@type QuestieOptionsEngine
local QuestieOptionsEngine = QuestieSmazakLoader:ImportModule("QuestieOptionsEngine");
---@type QuestieQuest
local QuestieQuest = QuestieSmazakLoader:ImportModule("QuestieQuest");
---@type QuestieJourney
local QuestieJourney = QuestieSmazakLoader:ImportModule("QuestieJourney");
---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieSmazakLoader:ImportModule("QuestieCombatQueue")
---@type QuestieLib
local QuestieLib = QuestieSmazakLoader:ImportModule("QuestieLib")
---@type Sounds
local Sounds = QuestieSmazakLoader:ImportModule("Sounds")
---@type QuestieTracker
local QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker")
---@type TrackerBaseFrame
local TrackerBaseFrame = QuestieSmazakLoader:ImportModule("TrackerBaseFrame")

QuestieOptions.tabs = { ... }
QuestieSmazakConfigFrame = nil

local AceGUI = LibStub("AceGUI-3.0")
---@type AceConfigDialog-3.0
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")

-- Forward declaration
local _CreateOptionsTable

---Initializes the frames for the options menu
function QuestieOptions:Initialize()
    -------------------------------------------------------------------------------
    -- This code is for creating the native Settings API menu, added in API 10.0 --
    -------------------------------------------------------------------------------


    ------------------------------------------------------------
    -- Everything below this initializes the old AceGUI popup --
    ------------------------------------------------------------
    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieOptions]: Initializing...")

    local optionsTable = _CreateOptionsTable()

    coroutine.yield()

    LibStub("AceConfig-3.0"):RegisterOptionsTable("QuestieSmazak", optionsTable)
    --AceConfigDialog:AddToBlizOptions("QuestieSmazak", "QuestieSmazak");

    coroutine.yield()

    ---@type AceGUIFrame, AceGUIFrame
    local configFrame = AceGUI:Create("Frame")

    configFrame:Hide()
    coroutine.yield()

    AceConfigDialog:SetDefaultSize("QuestieSmazak", 640, 700)
    AceConfigDialog:Open("QuestieSmazak", configFrame) -- load the options into configFrame
    configFrame:SetLayout("Fill")
    configFrame:EnableResize(false)
    QuestieCompat.SetResizeBounds(configFrame.frame, 550, 400)

    configFrame:Hide()
    coroutine.yield()

    local journeyButton = CreateFrame("Button", nil, configFrame.frame, "UIPanelButtonTemplate")
    journeyButton:SetWidth(140)
    journeyButton:SetPoint("TOPRIGHT", configFrame.frame, "TOPRIGHT", -50, -13)
    journeyButton:SetText(l10n("My Journey"))
    journeyButton:SetScript("OnClick", function()
        QuestieCombatQueue:Queue(function()
            QuestieJourney:ToggleJourneyWindow()
            QuestieOptions:ToggleConfigWindow()
        end)
    end)

    configFrame:Hide()
    coroutine.yield()

    QuestieSmazakConfigFrame = configFrame
    table.insert(UISpecialFrames, "QuestieSmazakConfigFrame")

    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "[QuestieOptions]: Initialization done")
end

-- Generic function to hide the config frame.
function QuestieOptions:HideFrame()
    if QuestieSmazakConfigFrame and QuestieSmazakConfigFrame:IsShown() then
        QuestieSmazakConfigFrame:Hide();
    end
end

-- Open the configuration window
function QuestieOptions:ToggleConfigWindow()
    if not QuestieSmazakConfigFrame:IsShown() then
        PlaySound(882)
        AceConfigDialog:Open("QuestieSmazak", QuestieSmazakConfigFrame)
    else
        QuestieSmazakConfigFrame:Hide()
    end
end

-- get option value
function QuestieOptions:GetProfileValue(info)
    return QuestieSmazak.db.profile[info[#info]]
end

-- set option value
function QuestieOptions:SetProfileValue(info, value)
    QuestieSmazak.db.profile[info[#info]] = value
end

---@return table
_CreateOptionsTable = function()
    local general_tab = QuestieOptions.tabs.general:Initialize()
    coroutine.yield()
    local icons_tab = QuestieOptions.tabs.icons:Initialize()
    coroutine.yield()
    local map_tab = QuestieOptions.tabs.map:Initialize()
    coroutine.yield()
    local tracker_tab = QuestieOptions.tabs.tracker:Initialize()
    coroutine.yield()
    local auto_tab = QuestieOptions.tabs.auto:Initialize()
    coroutine.yield()
    local nameplate_tab = QuestieOptions.tabs.nameplate:Initialize()
    coroutine.yield()
    local dbm_hud_tab = QuestieOptions.tabs.dbm:Initialize()
    coroutine.yield()
    local advanced_tab = QuestieOptions.tabs.advanced:Initialize()
    coroutine.yield()
    QuestieOptionsEngine:Initialize()
    coroutine.yield()
    return {
        name = "QuestieSmazak",
        handler = QuestieSmazak,
        type = "group",
        childGroups = "tab",
        args = {
            general_tab = general_tab,
            icons_tab = icons_tab,
            map_tab = map_tab,
            tracker_tab = tracker_tab,
            auto_tab = auto_tab,
            nameplate_tab = nameplate_tab,
            dbm_hud_tab = dbm_hud_tab,
            advanced_tab = advanced_tab,
            profiles_tab = LibStub("AceDBOptions-3.0"):GetOptionsTable(QuestieSmazak.db)
        }
    }
end

-- Hook initialization into addon load sequence
--local initFrame = CreateFrame("Frame")
--initFrame:RegisterEvent("ADDON_LOADED")
--initFrame:SetScript("OnEvent", function(self, event, addonName)
--    if addonName == "QuestieSmazak" then -- Replace with your actual folder name
--        self:UnregisterEvent("ADDON_LOADED")
--    end
--end)

return QuestieOptions
