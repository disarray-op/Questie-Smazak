---@type QuestieOptions
local QuestieOptions = QuestieSmazakLoader:ImportModule("QuestieOptions")
---@type QuestieOptionsEngine
local QuestieOptionsEngine = QuestieSmazakLoader:ImportModule("QuestieOptionsEngine")
---@type QuestieOptionsDefaults
local QuestieOptionsDefaults = QuestieSmazakLoader:ImportModule("QuestieOptionsDefaults")
---@type QuestieOptionsUtils
local QuestieOptionsUtils = QuestieSmazakLoader:ImportModule("QuestieOptionsUtils")
---@type QuestieFramePool
local QuestieFramePool = QuestieSmazakLoader:ImportModule("QuestieFramePool")
---@type QuestieMap
local QuestieMap = QuestieSmazakLoader:ImportModule("QuestieMap")
---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")
---@type QuestieQuest
local QuestieQuest = QuestieSmazakLoader:ImportModule("QuestieQuest")
---@type ActiveQuests
local ActiveQuests = QuestieSmazakLoader:ImportModule("ActiveQuests")
---@type QuestieTooltips
local QuestieTooltips = QuestieSmazakLoader:ImportModule("QuestieTooltips")
---@type QuestieMenu
local QuestieMenu = QuestieSmazakLoader:ImportModule("QuestieMenu")
---@type Expansions
local Expansions = QuestieSmazakLoader:ImportModule("Expansions")
---@type ThreadLib
local ThreadLib = QuestieSmazakLoader:ImportModule("ThreadLib")

QuestieOptionsEngine.tabs.icons = { ... }

local optionsDefaults = QuestieOptionsDefaults:Load()

local _GetIconTypes
local _GetIconTypesSort
local _GetIconThemes
local _GetIconThemesSort

local function _IsEnabled()
    return QuestieSmazak.db.profile.enabled
end

local function _IsMapEnabled()
    return QuestieSmazak.db.profile.enabled and QuestieSmazak.db.profile.enableMapIcons
end

local function _IsMinimapEnabled()
    return QuestieSmazak.db.profile.enabled and QuestieSmazak.db.profile.enableMiniMapIcons
end

function QuestieOptionsEngine.tabs.icons:Initialize()
    return {
        title = "Icons",
        subtitle = "Icon Options",
        order = 1,
        icon = 132328,
        items = {
            icon_options_group = {
                type = "container",
                order = 1,
                title = "Icon Options",
                items = {
                    show_icons = {
                        type = "checkbox",
                        order = 1.1,
                        title = "Enable Icons",
                        description = "Shows or hides the icons that QuestieSmazak draws on the world map and minimap.",
                        width = 0.6,
                        get = function() return QuestieSmazak.db.profile.enabled end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.enabled = value
                            QuestieQuest:ToggleNotes(value)
                        end,
                    },
                    iconThemePicker = {
                        type = "dropdown",
                        order = 1.2,
                        title = "Objective Icon Theme",
                        tooltip = "Change between themes for objective icons.",
                        width = 0.39,
                        options = _GetIconThemes,
                        sortOrder = _GetIconThemesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.iconTheme end,
                        set = function(key)
                            QuestieOptionsUtils.ExecuteTheme(nil, key)
                        end,
                    },
                    hideMapIconsForUntrackedToggle = {
                        type = "checkbox",
                        order = 1.3,
                        title = "Hide icons of untracked quests",
                        tooltip = "Hide icons for quests that are not tracked.",
                        width = "full",
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.hideUntrackedQuestsMapIcons end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.hideUntrackedQuestsMapIcons = value
                            ThreadLib.ThreadInstant(function()
                                if value then
                                    QuestieQuest:HideQuestIcons()
                                else
                                    QuestieQuest:ShowQuestIcons()
                                end
                                if value == true then
                                    for questId, acceptance in ActiveQuests.Iterate() do
                                        if acceptance.quest and (not QuestieQuest:ShouldShowQuestNotes(questId)) then
                                            QuestieTooltips:RemoveQuest(questId)
                                        end
                                    end
                                else
                                    for _, acceptance in ActiveQuests.Iterate() do
                                        if acceptance.quest then
                                            QuestieQuest:PopulateObjectiveNotes(acceptance.quest)
                                        end
                                    end
                                end
                            end)
                        end,
                    },
                },
            },
            icon_toggles_group = {
                type = "container",
                order = 2,
                title = "Show icons for...",
                enabled = _IsEnabled,
                items = {
                    quest_options = {
                        type = "divider",
                        order = 1,
                        title = "Quests",
                        width = "full",
                    },
                    showNormalQuests = {
                        type = "checkbox",
                        order = 2.01,
                        title = "Available Normal Quests",
                        tooltip = "If checked, the locations of available quests will be shown on the map/minimap.",
                        width = "half",
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.enableAvailable end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.enableAvailable = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showItemQuests = {
                        type = "checkbox",
                        order = 2.02,
                        title = "Available Quests from Items",
                        tooltip = "If checked, the locations of item drops that start quests will be shown on the map/minimap.",
                        width = "half",
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.enableAvailableItems end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.enableAvailableItems = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showEventQuests = {
                        type = "checkbox",
                        order = 2.03,
                        title = "Available Event Quests",
                        tooltip = "If checked, the locations of active event quests will be shown on the map/minimap.",
                        width = "half",
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.showEventQuests end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.showEventQuests = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showRepeatableQuests = {
                        type = "checkbox",
                        order = 2.04,
                        title = "Available Repeatable Quests",
                        tooltip = "If checked, the locations of repeatable quests will be shown on the map/minimap.",
                        width = "half",
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.showRepeatableQuests end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.showRepeatableQuests = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showPvPQuests = {
                        type = "checkbox",
                        order = 2.05,
                        title = "Available PvP Quests",
                        tooltip = "If checked, the locations of PvP quests will be shown on the map/minimap.",
                        width = "half",
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.showPvPQuests end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.showPvPQuests = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showDungeonQuests = {
                        type = "checkbox",
                        order = 2.06,
                        title = "Available Dungeon Quests",
                        tooltip = "If checked, the locations of dungeon quests will be shown on the map/minimap.",
                        width = "half",
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.showDungeonQuests end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.showDungeonQuests = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showRaidQuests = {
                        type = "checkbox",
                        order = 2.07,
                        title = "Available Raid Quests",
                        tooltip = "If checked, the locations of raid quests will be shown on the map/minimap.",
                        width = "half",
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.showRaidQuests end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.showRaidQuests = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showCompleteQuests = {
                        type = "checkbox",
                        order = 2.08,
                        title = "Completed Quests",
                        tooltip = "If checked, the quest turn-in locations will be shown on the map/minimap.",
                        width = "half",
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.enableTurnins end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.enableTurnins = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showObjectivesToggle = {
                        type = "checkbox",
                        order = 2.09,
                        title = "Objectives",
                        tooltip = "If checked, quest objective icons will be shown on the map/minimap.",
                        width = "half",
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.enableObjectives end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.enableObjectives = value
                            QuestieQuest:ToggleNotes(value)
                            QuestieOptionsUtils.DetermineTheme()
                        end,
                    },
                    showAQWarEffortQuests = {
                        type = "checkbox",
                        order = 2.10,
                        title = "Available AQ War Effort Quests",
                        tooltip = "If checked, the locations of the AQ War Effort quests will be shown on the map/minimap.",
                        width = "half",
                        visible = QuestieSmazak.IsClassic,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.showAQWarEffortQuests end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.showAQWarEffortQuests = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    sod_rune_options = {
                        type = "divider",
                        order = 2.20,
                        title = "Season of Discovery Runes",
                        width = "full",
                        visible = QuestieSmazak.IsSoD,
                    },
                    showSoDRunes = {
                        type = "checkbox",
                        order = 2.21,
                        title = "Show Runes",
                        tooltip = "If checked, the locations of Season of Discovery Runes and Rune quests will be shown on the map/minimap.",
                        width = "full",
                        visible = QuestieSmazak.IsSoD,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.showSoDRunes end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.showSoDRunes = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    sodRuneSelection = {
                        type = "container",
                        order = 2.22,
                        title = "",
                        visible = QuestieSmazak.IsSoD,
                        enabled = function() return _IsEnabled() and QuestieSmazak.db.profile.showSoDRunes end,
                        items = {
                            phase1 = {
                                type = "checkbox",
                                order = 1,
                                title = "Phase 1",
                                width = "quarter",
                                enabled = function() return _IsEnabled() and QuestieSmazak.db.profile.showSoDRunes end,
                                get = function() return QuestieSmazak.db.profile.showRunesOfPhase.phase1 end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.showRunesOfPhase.phase1 = value
                                    QuestieQuest.ToggleAvailableQuests(value)
                                end,
                            },
                            phase2 = {
                                type = "checkbox",
                                order = 2,
                                title = "Phase 2",
                                width = "quarter",
                                enabled = function() return _IsEnabled() and QuestieSmazak.db.profile.showSoDRunes end,
                                get = function() return QuestieSmazak.db.profile.showRunesOfPhase.phase2 end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.showRunesOfPhase.phase2 = value
                                    QuestieQuest.ToggleAvailableQuests(value)
                                end,
                            },
                            phase3 = {
                                type = "checkbox",
                                order = 3,
                                title = "Phase 3",
                                width = "quarter",
                                enabled = function() return _IsEnabled() and QuestieSmazak.db.profile.showSoDRunes end,
                                get = function() return QuestieSmazak.db.profile.showRunesOfPhase.phase3 end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.showRunesOfPhase.phase3 = value
                                    QuestieQuest.ToggleAvailableQuests(value)
                                end,
                            },
                            phase4 = {
                                type = "checkbox",
                                order = 4,
                                title = "Phase 4",
                                width = "quarter",
                                enabled = function() return _IsEnabled() and QuestieSmazak.db.profile.showSoDRunes end,
                                get = function() return QuestieSmazak.db.profile.showRunesOfPhase.phase4 end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.showRunesOfPhase.phase4 = value
                                    QuestieQuest.ToggleAvailableQuests(value)
                                end,
                            },
                        },
                    },
                    townsfolk_options = {
                        type = "divider",
                        order = 2.30,
                        title = "Other Icons",
                        width = "full",
                    },
                    townsfolkOptions = {
                        type = "button",
                        order = 2.31,
                        title = "Townsfolk",
                        btnLabel = "Townsfolk",
                        tooltip = "Allows to select which tracking icons (like Mailbox, Repair-NPCs) to show on the map and minimap.",
                        width = "third",
                        align = "CENTER",
                        enabled = _IsEnabled,
                        func = function()
                            QuestieMenu:ShowTownsfolk(1)
                        end,
                    },
                    professionOptions = {
                        type = "button",
                        order = 2.32,
                        title = "Profession Trainers",
                        btnLabel = "Profession Trainers",
                        tooltip = "Allows to select which profession trainers to show on the map and minimap.",
                        width = "third",
                        align = "CENTER",
                        enabled = _IsEnabled,
                        func = function()
                            QuestieMenu:ShowProfessions(1)
                        end,
                    },
                    vendorOptions = {
                        type = "button",
                        order = 2.33,
                        title = "Vendors",
                        btnLabel = "Vendors",
                        tooltip = "Allows to select which vendors to show on the map and minimap.",
                        width = "third",
                        align = "CENTER",
                        enabled = _IsEnabled,
                        func = function()
                            QuestieMenu:ShowVendors(1)
                        end,
                    },
                },
            },
            map_settings_group = {
                type = "container",
                order = 3,
                title = "Map Options",
                enabled = _IsEnabled,
                items = {
                    enableMapToggle = {
                        type = "checkbox",
                        order = 3.1,
                        title = "Enable Map Icons",
                        description = "Show/hide all icons from the main map.",
                        width = "full",
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.enableMapIcons end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.enableMapIcons = value
                            QuestieQuest:ToggleNotes(value)
                        end,
                    },
                    alwaysGlowMap = {
                        type = "checkbox",
                        order = 3.2,
                        title = "Map Icons Glow",
                        tooltip = "Draw a glow texture behind map icons, colored unique to each quest.",
                        width = "half",
                        enabled = _IsMapEnabled,
                        get = function() return QuestieSmazak.db.profile.alwaysGlowMap end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.alwaysGlowMap = value
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieFramePool:UpdateGlowConfig(false, value)
                        end,
                    },
                    questObjectiveColors = {
                        type = "checkbox",
                        order = 3.3,
                        title = "Unique Map Icon Colors",
                        tooltip = "Show map icons with colors that are randomly generated based on quest ID.",
                        width = "half",
                        enabled = _IsMapEnabled,
                        get = function() return QuestieSmazak.db.profile.questObjectiveColors end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.questObjectiveColors = value
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieFramePool:UpdateColorConfig(false, value)
                        end,
                    },
                    hideUnexploredMapIconsToggle = {
                        type = "checkbox",
                        order = 3.4,
                        title = "Hide Icons in Unexplored Areas",
                        tooltip = "Hide icons in unexplored map regions.",
                        width = "half",
                        enabled = _IsMapEnabled,
                        get = function() return QuestieSmazak.db.profile.hideUnexploredMapIcons end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.hideUnexploredMapIcons = value
                            QuestieQuest:ToggleNotes(not value)
                        end,
                    },
                    hideIconsOnContinents = {
                        type = "checkbox",
                        order = 3.5,
                        title = "Hide Icons on Continent Map",
                        tooltip = "Hide icons on the continent map, when not viewing a specific zone.",
                        width = "half",
                        enabled = _IsMapEnabled,
                        get = function() return QuestieSmazak.db.profile.hideIconsOnContinents end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.hideIconsOnContinents = value
                            QuestieQuest:SmoothReset()
                        end,
                    },
                },
            },
            minimap_settings_group = {
                type = "container",
                order = 4,
                title = "Minimap Options",
                enabled = _IsEnabled,
                items = {
                    enableMiniMapToggle = {
                        type = "checkbox",
                        order = 4.1,
                        title = "Enable Minimap Icons",
                        description = "Show/hide all icons from the minimap.",
                        width = "full",
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.enableMiniMapIcons end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.enableMiniMapIcons = value
                            QuestieQuest:ToggleNotes(value)
                        end,
                    },
                    alwaysGlowMinimap = {
                        type = "checkbox",
                        order = 4.2,
                        title = "Minimap Icons Glow",
                        tooltip = "Draw a glow texture behind minimap icons, colored unique to each quest.",
                        width = "half",
                        enabled = _IsMinimapEnabled,
                        get = function() return QuestieSmazak.db.profile.alwaysGlowMinimap end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.alwaysGlowMinimap = value
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieFramePool:UpdateGlowConfig(true, value)
                        end,
                    },
                    questMinimapObjectiveColors = {
                        type = "checkbox",
                        order = 4.3,
                        title = "Unique Minimap Icon Colors",
                        tooltip = "Show minimap icons with colors that are randomly generated based on quest ID.",
                        width = "half",
                        enabled = _IsMinimapEnabled,
                        get = function() return QuestieSmazak.db.profile.questMinimapObjectiveColors end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.questMinimapObjectiveColors = value
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieFramePool:UpdateColorConfig(true, value)
                        end,
                    },
                    fadeLevel = {
                        type = "slider",
                        order = 4.4,
                        title = "Minimap Icon Fade Distance",
                        tooltip = { "How much objective icons should fade depending on distance.\n(Default: %s)", optionsDefaults.profile.fadeLevel },
                        width = "full",
                        min = 10,
                        max = 100,
                        step = 1,
                        enabled = _IsMinimapEnabled,
                        get = function() return QuestieSmazak.db.profile.fadeLevel end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.fadeLevel = value
                        end,
                    },
                    fadeOverPlayer = {
                        type = "checkbox",
                        order = 4.5,
                        title = "Fade Icons over Player",
                        tooltip = "Fades icons on the minimap when your player walks near them.",
                        width = "full",
                        enabled = _IsMinimapEnabled,
                        get = function() return QuestieSmazak.db.profile.fadeOverPlayer end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.fadeOverPlayer = value
                        end,
                    },
                    fadeOverPlayerDistance = {
                        type = "slider",
                        order = 4.6,
                        title = "Fade over Player Distance",
                        tooltip = { "How far from player should icons start to fade.\n(Default: %s)", optionsDefaults.profile.fadeOverPlayerDistance },
                        width = "half",
                        min = 0,
                        max = 20,
                        step = 0.5,
                        enabled = function() return _IsMinimapEnabled() and QuestieSmazak.db.profile.fadeOverPlayer end,
                        get = function() return QuestieSmazak.db.profile.fadeOverPlayerDistance end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.fadeOverPlayerDistance = value
                        end,
                    },
                    fadeOverPlayerLevel = {
                        type = "slider",
                        order = 4.7,
                        title = "Fade over Player Amount",
                        tooltip = { "How much should the icons around the player fade.\n(Default: %s)", optionsDefaults.profile.fadeOverPlayerLevel },
                        width = "half",
                        min = 0.1,
                        max = 1,
                        step = 0.1,
                        enabled = function() return _IsMinimapEnabled() and QuestieSmazak.db.profile.fadeOverPlayer end,
                        get = function() return QuestieSmazak.db.profile.fadeOverPlayerLevel end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.fadeOverPlayerLevel = value
                        end,
                    },
                },
            },
            icon_scales_group = {
                type = "container",
                order = 5,
                title = "Icon Scales",
                enabled = _IsEnabled,
                items = {
                    globalScale = {
                        type = "slider",
                        order = 5.1,
                        title = "Map Icons",
                        tooltip = { "How large the map icons are.\n(Default: %s)", optionsDefaults.profile.globalScale },
                        width = "half",
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        isPercent = true,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.globalScale end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.globalScale = value
                            QuestieMap:RescaleIcons()
                        end,
                    },
                    globalMiniMapScale = {
                        type = "slider",
                        order = 5.2,
                        title = "Minimap Icons",
                        tooltip = { "How large the minimap icons are.\n(Default: %s)", optionsDefaults.profile.globalMiniMapScale },
                        width = "half",
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        isPercent = true,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.globalMiniMapScale end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.globalMiniMapScale = value
                            QuestieMap:RescaleIcons()
                        end,
                    },
                    globalTownsfolkScale = {
                        type = "slider",
                        order = 5.3,
                        title = "Townsfolk Icons",
                        tooltip = { "How large the townsfolk map icons are.\n(Default: %s)", optionsDefaults.profile.globalTownsfolkScale },
                        width = "half",
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        isPercent = true,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.globalTownsfolkScale end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.globalTownsfolkScale = value
                            QuestieMap:RescaleTownsfolkIcons()
                        end,
                    },
                    globalMiniMapTownsfolkScale = {
                        type = "slider",
                        order = 5.4,
                        title = "Minimap Townsfolk Icons",
                        tooltip = { "How large the townsfolk minimap icons are.\n(Default: %s)", optionsDefaults.profile.globalMiniMapTownsfolkScale },
                        width = "half",
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        isPercent = true,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.globalMiniMapTownsfolkScale end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.globalMiniMapTownsfolkScale = value
                            QuestieMap:RescaleTownsfolkIcons()
                        end,
                    },
                    availableScale = {
                        type = "slider",
                        order = 5.5,
                        title = "Quest Icons",
                        tooltip = { "How large the available/complete icons are. Affects both map and minimap icons.\n(Default: %s)", optionsDefaults.profile.availableScale },
                        width = "full",
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        isPercent = true,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.availableScale end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.availableScale = value
                            QuestieMap:RescaleIcons()
                        end,
                    },
                    lootScale = {
                        type = "slider",
                        order = 5.6,
                        title = "Loot objectives",
                        tooltip = { "How large the loot icons are.\n(Default: %s)", optionsDefaults.profile.lootScale },
                        width = "half",
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        isPercent = true,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.lootScale end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.lootScale = value
                            QuestieMap:RescaleIcons()
                        end,
                    },
                    monsterScale = {
                        type = "slider",
                        order = 5.7,
                        title = "Slay objectives",
                        tooltip = { "How large the slay icons are.\n(Default: %s)", optionsDefaults.profile.monsterScale },
                        width = "half",
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        isPercent = true,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.monsterScale end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.monsterScale = value
                            QuestieMap:RescaleIcons()
                        end,
                    },
                    eventScale = {
                        type = "slider",
                        order = 5.8,
                        title = "Event objectives",
                        tooltip = { "How large the event icons are.\n(Default: %s)", optionsDefaults.profile.eventScale },
                        width = "half",
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        isPercent = true,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.eventScale end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.eventScale = value
                            QuestieMap:RescaleIcons()
                        end,
                    },
                    objectScale = {
                        type = "slider",
                        order = 5.9,
                        title = "Object objectives",
                        tooltip = { "How large the object icons are.\n(Default: %s)", optionsDefaults.profile.objectScale },
                        width = "half",
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        isPercent = true,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak.db.profile.objectScale end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.objectScale = value
                            QuestieMap:RescaleIcons()
                        end,
                    },
                },
            },
            icon_overrides_group = {
                type = "container",
                order = 6,
                title = "Icon Overrides",
                enabled = _IsEnabled,
                items = {
                    overrideObjectivesHeader = {
                        type = "divider",
                        order = 1,
                        title = "Objectives",
                        width = "full",
                    },
                    iconTypeSlay = {
                        type = "dropdown",
                        order = 2,
                        title = "Slay objectives",
                        tooltip = "The icon that is displayed for quest objectives where you need to kill an NPC",
                        width = "third",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_SLAY) or "slay" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_SLAY = QuestieSmazak.icons[key]
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypeLoot = {
                        type = "dropdown",
                        order = 3,
                        title = "Loot objectives",
                        tooltip = "The icon that is displayed for quest objectives where you need to loot an item",
                        width = "third",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_LOOT) or "loot" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_LOOT = QuestieSmazak.icons[key]
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypeObject = {
                        type = "dropdown",
                        order = 4,
                        title = "Object objectives",
                        tooltip = "The icon that is displayed for quest objectives where you need to interact with an object",
                        width = "third",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_OBJECT) or "object" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_OBJECT = QuestieSmazak.icons[key]
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypeEvent = {
                        type = "dropdown",
                        order = 5,
                        title = "Event objectives",
                        tooltip = "The icon that is displayed for quest objectives where you need to do something in a certain area, like exploring it or casting a spell there",
                        width = "third",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_EVENT) or "event" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_EVENT = QuestieSmazak.icons[key]
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypeTalk = {
                        type = "dropdown",
                        order = 6,
                        title = "Talk objectives",
                        tooltip = "The icon that is displayed for quest objectives where you need to talk to an NPC",
                        width = "third",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_TALK) or "talk" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_TALK = QuestieSmazak.icons[key]
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypeInteract = {
                        type = "dropdown",
                        order = 7,
                        title = "Interact objectives",
                        tooltip = "The icon that is displayed for quest objectives where you need to use an item or interact with an NPC",
                        width = "third",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_INTERACT) or "interact" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_INTERACT = QuestieSmazak.icons[key]
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    overrideNormalQuestsHeader = {
                        type = "divider",
                        order = 8,
                        title = "Quests",
                        width = "full",
                    },
                    iconTypeAvailable = {
                        type = "dropdown",
                        order = 9,
                        title = "Available quests",
                        tooltip = "The icon that is displayed for available quests",
                        width = "third",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_AVAILABLE) or "available" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_AVAILABLE = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypeComplete = {
                        type = "dropdown",
                        order = 10,
                        title = "Complete quests",
                        tooltip = "The icon that is displayed for completed quests that can be handed in",
                        width = "third",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_COMPLETE) or "complete" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_COMPLETE = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypeAvailableGray = {
                        type = "dropdown",
                        order = 11,
                        title = "Unavailable and trivial quests",
                        tooltip = "The icon that is displayed for quests that require additional conditions to be met before they can be accepted, or are so low level they don't reward experience",
                        width = "third",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_AVAILABLE_GRAY) or "available_gray" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_AVAILABLE_GRAY = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypeRepeatable = {
                        type = "dropdown",
                        order = 12,
                        title = "Available repeatable quests",
                        tooltip = "The icon that is displayed for available repeatable quests like dailies",
                        width = "half",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_REPEATABLE) or "repeatable" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_REPEATABLE = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypeRepeatableComplete = {
                        type = "dropdown",
                        order = 13,
                        title = "Complete repeatable quests",
                        tooltip = "The icon that is displayed for repeatable quests that can be handed in",
                        width = "half",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_REPEATABLE_COMPLETE) or "repeatable_complete" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_REPEATABLE_COMPLETE = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypeEventQuest = {
                        type = "dropdown",
                        order = 14,
                        title = "Available event quests",
                        tooltip = "The icon that is displayed for available event quests during holidays",
                        width = "half",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_EVENTQUEST) or "eventquest" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_EVENTQUEST = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypeEventQuestComplete = {
                        type = "dropdown",
                        order = 15,
                        title = "Complete event quests",
                        tooltip = "The icon that is displayed for event quests that can be handed in",
                        width = "half",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_EVENTQUEST_COMPLETE) or "eventquest_complete" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_EVENTQUEST_COMPLETE = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypePVPQuest = {
                        type = "dropdown",
                        order = 16,
                        title = "Available PvP quests",
                        tooltip = "The icon that is displayed for available PvP quests",
                        width = "half",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_PVPQUEST) or "pvpquest" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_PVPQUEST = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypePVPQuestComplete = {
                        type = "dropdown",
                        order = 17,
                        title = "Complete PvP quests",
                        tooltip = "The icon that is displayed for PvP quests that can be handed in",
                        width = "half",
                        options = _GetIconTypes,
                        sortOrder = _GetIconTypesSort,
                        enabled = _IsEnabled,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_PVPQUEST_COMPLETE) or "pvpquest_complete" end,
                        set = function(key)
                            QuestieSmazak.db.profile.ICON_PVPQUEST_COMPLETE = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                },
            },
        },
    }
end

_GetIconTypes = function()
    return {
        ["slay"] = "|T" .. QuestieSmazak.icons["slay"] .. ":0|t " .. l10n("Slay"),
        ["loot"] = "|T" .. QuestieSmazak.icons["loot"] .. ":0|t " .. l10n("Loot"),
        ["node"] = "|T" .. QuestieSmazak.icons["node"] .. ":0|t " .. l10n("pfQuest/Codex node"),
        ["player"] = "|T" .. QuestieSmazak.icons["player"] .. ":0|t " .. l10n("Party marker"),
        ["event"] = "|T" .. QuestieSmazak.icons["event"] .. ":0|t " .. l10n("Event"),
        ["object"] = "|T" .. QuestieSmazak.icons["object"] .. ":0|t " .. l10n("Object"),
        ["talk"] = "|T" .. QuestieSmazak.icons["talk"] .. ":0|t " .. l10n("Talk"),
        ["interact"] = "|T" .. QuestieSmazak.icons["interact"] .. ":0|t " .. l10n("Interact"),
        ["available"] = "|T" .. QuestieSmazak.icons["available"] .. ":0|t " .. l10n("Available"),
        ["available_gray"] = "|T" .. QuestieSmazak.icons["available_gray"] .. ":0|t " .. l10n("Available gray"),
        ["complete"] = "|T" .. QuestieSmazak.icons["complete"] .. ":0|t " .. l10n("Complete"),
        ["incomplete"] = "|T" .. QuestieSmazak.icons["incomplete"] .. ":0|t " .. l10n("Incomplete"),
        ["repeatable"] = "|T" .. QuestieSmazak.icons["repeatable"] .. ":0|t " .. l10n("Repeatable"),
        ["repeatable_complete"] = "|T" .. QuestieSmazak.icons["repeatable_complete"] .. ":0|t " .. l10n("Repeatable Complete"),
        ["eventquest"] = "|T" .. QuestieSmazak.icons["eventquest"] .. ":0|t " .. l10n("Event Quest"),
        ["eventquest_complete"] = "|T" .. QuestieSmazak.icons["eventquest_complete"] .. ":0|t " .. l10n("Event Quest Complete"),
        ["pvpquest"] = "|T" .. QuestieSmazak.icons["pvpquest"] .. ":0|t " .. l10n("PvP Quest"),
        ["pvpquest_complete"] = "|T" .. QuestieSmazak.icons["pvpquest_complete"] .. ":0|t " .. l10n("PvP Quest Complete"),
        ["fav"] = "|T" .. QuestieSmazak.icons["fav"] .. ":0|t " .. l10n("Favourite"),
        ["hand"] = "|T" .. QuestieSmazak.icons["hand"] .. ":0|t " .. l10n("Hand"),
        ["faction_alliance"] = "|T" .. QuestieSmazak.icons["faction_alliance"] .. ":0|t " .. l10n("Alliance"),
        ["faction_horde"] = "|T" .. QuestieSmazak.icons["faction_horde"] .. ":0|t " .. l10n("Horde"),
        ["loot_mono"] = "|T" .. QuestieSmazak.icons["loot_mono"] .. ":0|t " .. l10n("Loot mono"),
        ["node_cut"] = "|T" .. QuestieSmazak.icons["node_cut"] .. ":0|t " .. l10n("pfQuest/Codex node cut center"),
        ["object_mono"] = "|T" .. QuestieSmazak.icons["object_mono"] .. ":0|t " .. l10n("Object mono"),
        ["route"] = "|T" .. QuestieSmazak.icons["route"] .. ":0|t " .. l10n("Route waypoint"),
        ["slay_mono"] = "|T" .. QuestieSmazak.icons["slay_mono"] .. ":0|t " .. l10n("Slay mono"),
        ["startend"] = "|T" .. QuestieSmazak.icons["startend"] .. ":0|t " .. l10n("Start and end"),
        ["startendstart"] = "|T" .. QuestieSmazak.icons["startendstart"] .. ":0|t " .. l10n("Start and unfinished"),
        ["tracker_clean"] = "|T" .. QuestieSmazak.icons["tracker_clean"] .. ":0|t " .. l10n("Clean"),
        ["tracker_close"] = "|T" .. QuestieSmazak.icons["tracker_close"] .. ":0|t " .. CLOSE,
        ["tracker_database"] = "|T" .. QuestieSmazak.icons["tracker_database"] .. ":0|t " .. l10n("Pin"),
        ["tracker_giver"] = "|T" .. QuestieSmazak.icons["tracker_giver"] .. ":0|t " .. l10n("Available white"),
        ["tracker_quests"] = "|T" .. QuestieSmazak.icons["tracker_quests"] .. ":0|t " .. l10n("Book"),
        ["tracker_search"] = "|T" .. QuestieSmazak.icons["tracker_search"] .. ":0|t " .. l10n("Search"),
        ["tracker_settings"] = "|T" .. QuestieSmazak.icons["tracker_settings"] .. ":0|t " .. SETTINGS,
    }
end

_GetIconTypesSort = function()
    return {
        "slay",
        "slay_mono",
        "loot",
        "loot_mono",
        "object",
        "object_mono",
        "event",
        "talk",
        "interact",
        "available",
        "available_gray",
        "incomplete",
        "complete",
        "repeatable",
        "repeatable_complete",
        "eventquest",
        "eventquest_complete",
        "pvpquest",
        "pvpquest_complete",
        "startend",
        "startendstart",
        "node",
        "node_cut",
        "route",
        "player",
        "fav",
        "hand",
        "faction_alliance",
        "faction_horde",
        "tracker_clean",
        "tracker_close",
        "tracker_database",
        "tracker_giver",
        "tracker_quests",
        "tracker_search",
        "tracker_settings",
    }
end

_GetIconThemes = function()
    if Expansions.Current >= Expansions.Wotlk or QuestieSmazak.IsForever then
        return {
            ["questie"] = "|T" .. QuestieSmazak.icons["slay"] .. ":14|t QuestieSmazak",
            ["blizzard"] = "|TInterface/buttons/adventureguidemicrobuttonalert.blp:20:20:0:0:32:32:2:28:2:28|t Blizzard",
            ["pfquest"] = "|T" .. QuestieSmazak.icons["node"] .. ":14|t pfQuest",
            ["custom"] = "|T" .. QuestieSmazak.icons["object"] .. ":16|t " .. l10n("Custom"),
        }
    else
        return {
            ["questie"] = "|T" .. QuestieSmazak.icons["complete"] .. ":14|t QuestieSmazak",
            ["pfquest"] = "|T" .. QuestieSmazak.icons["node"] .. ":14|t pfQuest",
            ["custom"] = "|T" .. QuestieSmazak.icons["object"] .. ":16|t " .. l10n("Custom"),
        }
    end
end

_GetIconThemesSort = function()
    if Expansions.Current >= Expansions.Wotlk or QuestieSmazak.IsForever then
        return {
            "questie",
            "blizzard",
            "pfquest",
            "custom",
        }
    else
        return {
            "questie",
            "pfquest",
            "custom",
        }
    end
end

function QuestieOptionsUtils.SetPfQuestIcons(info, value)
    QuestieSmazak.db.profile.usePfQuestIcons = value
    if value then
        QuestieSmazak.db.profile.ICON_SLAY = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_LOOT = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_EVENT = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_OBJECT = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_TALK = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_INTERACT = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.questObjectiveColors = true
        QuestieSmazak.db.profile.alwaysGlowMap = false
        QuestieSmazak.db.profile.questMinimapObjectiveColors = true
        QuestieSmazak.db.profile.alwaysGlowMinimap = false
        QuestieSmazak.db.profile.objectiveFilterDistance = 0
    else
        QuestieSmazak.db.profile.ICON_SLAY = QuestieSmazak.icons["slay"]
        QuestieSmazak.db.profile.ICON_LOOT = QuestieSmazak.icons["loot"]
        QuestieSmazak.db.profile.ICON_EVENT = QuestieSmazak.icons["event"]
        QuestieSmazak.db.profile.ICON_OBJECT = QuestieSmazak.icons["object"]
        QuestieSmazak.db.profile.ICON_TALK = QuestieSmazak.icons["talk"]
        QuestieSmazak.db.profile.ICON_INTERACT = QuestieSmazak.icons["interact"]
        QuestieSmazak.db.profile.questObjectiveColors = false
        QuestieSmazak.db.profile.alwaysGlowMap = true
        QuestieSmazak.db.profile.questMinimapObjectiveColors = false
        QuestieSmazak.db.profile.alwaysGlowMinimap = false
        QuestieSmazak.db.profile.objectiveFilterDistance = optionsDefaults.profile.objectiveFilterDistance
    end
    QuestieSmazak:SetIcons()
    QuestieQuest:SmoothReset()
end

function QuestieOptionsUtils.DetermineTheme()
    if (GetCVar("questPOI") == "1" and QuestieSmazak.db.profile.enableObjectives == false) then
        QuestieSmazak.db.profile.iconTheme = "blizzard"
    else
        if (QuestieSmazak.db.profile.enableObjectives == true and
                QuestieSmazak.db.profile.ICON_SLAY == QuestieSmazak.icons["node"] and
                QuestieSmazak.db.profile.ICON_LOOT == QuestieSmazak.icons["node"] and
                QuestieSmazak.db.profile.ICON_EVENT == QuestieSmazak.icons["node"] and
                QuestieSmazak.db.profile.ICON_OBJECT == QuestieSmazak.icons["node"] and
                QuestieSmazak.db.profile.ICON_TALK == QuestieSmazak.icons["node"] and
                QuestieSmazak.db.profile.ICON_INTERACT == QuestieSmazak.icons["node"] and
                QuestieSmazak.db.profile.questObjectiveColors == true and
                QuestieSmazak.db.profile.alwaysGlowMap == false and
                QuestieSmazak.db.profile.questMinimapObjectiveColors == true and
                QuestieSmazak.db.profile.alwaysGlowMinimap == false and
                QuestieSmazak.db.profile.objectiveFilterDistance == 2)
        then
            QuestieSmazak.db.profile.iconTheme = "pfquest"
        elseif (QuestieSmazak.db.profile.enableObjectives == true and
                QuestieSmazak.db.profile.ICON_SLAY == QuestieSmazak.icons["slay"] and
                QuestieSmazak.db.profile.ICON_LOOT == QuestieSmazak.icons["loot"] and
                QuestieSmazak.db.profile.ICON_EVENT == QuestieSmazak.icons["event"] and
                QuestieSmazak.db.profile.ICON_OBJECT == QuestieSmazak.icons["object"] and
                QuestieSmazak.db.profile.ICON_TALK == QuestieSmazak.icons["talk"] and
                QuestieSmazak.db.profile.ICON_INTERACT == QuestieSmazak.icons["interact"] and
                QuestieSmazak.db.profile.questObjectiveColors == optionsDefaults.profile.questObjectiveColors and
                QuestieSmazak.db.profile.alwaysGlowMap == optionsDefaults.profile.alwaysGlowMap and
                QuestieSmazak.db.profile.questMinimapObjectiveColors == optionsDefaults.profile.questMinimapObjectiveColors and
                QuestieSmazak.db.profile.alwaysGlowMinimap == optionsDefaults.profile.alwaysGlowMinimap and
                QuestieSmazak.db.profile.objectiveFilterDistance == optionsDefaults.profile.objectiveFilterDistance)
        then
            QuestieSmazak.db.profile.iconTheme = "questie"
        else
            QuestieSmazak.db.profile.iconTheme = "custom"
        end
    end
end

function QuestieOptionsUtils.ExecuteTheme(info, value)
    QuestieSmazak.db.profile.iconTheme = value
    local currentQuestPOI = GetCVar("questPOI")
    if value == "questie" then
        if currentQuestPOI and currentQuestPOI ~= "0" then
            SetCVar("questPOI", "0")
        end
        if WorldMapQuestShowObjectives then
            WorldMapQuestShowObjectives:SetChecked(false)
        end
        QuestieSmazak.db.profile.enableObjectives = true
        QuestieSmazak.db.profile.ICON_SLAY = QuestieSmazak.icons["slay"]
        QuestieSmazak.db.profile.ICON_LOOT = QuestieSmazak.icons["loot"]
        QuestieSmazak.db.profile.ICON_EVENT = QuestieSmazak.icons["event"]
        QuestieSmazak.db.profile.ICON_OBJECT = QuestieSmazak.icons["object"]
        QuestieSmazak.db.profile.ICON_TALK = QuestieSmazak.icons["talk"]
        QuestieSmazak.db.profile.ICON_INTERACT = QuestieSmazak.icons["interact"]
        QuestieSmazak.db.profile.questObjectiveColors = optionsDefaults.profile.questObjectiveColors
        QuestieSmazak.db.profile.alwaysGlowMap = optionsDefaults.profile.alwaysGlowMap
        QuestieSmazak.db.profile.questMinimapObjectiveColors = optionsDefaults.profile.questMinimapObjectiveColors
        QuestieSmazak.db.profile.alwaysGlowMinimap = optionsDefaults.profile.alwaysGlowMinimap
        QuestieSmazak.db.profile.objectiveFilterDistance = optionsDefaults.profile.objectiveFilterDistance
    elseif value == "pfquest" then
        if currentQuestPOI and currentQuestPOI ~= "0" then
            SetCVar("questPOI", "0")
        end
        if WorldMapQuestShowObjectives then
            WorldMapQuestShowObjectives:SetChecked(false)
        end
        QuestieSmazak.db.profile.enableObjectives = true
        QuestieSmazak.db.profile.ICON_SLAY = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_LOOT = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_EVENT = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_OBJECT = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_TALK = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_INTERACT = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.questObjectiveColors = true
        QuestieSmazak.db.profile.alwaysGlowMap = false
        QuestieSmazak.db.profile.questMinimapObjectiveColors = true
        QuestieSmazak.db.profile.alwaysGlowMinimap = false
        QuestieSmazak.db.profile.objectiveFilterDistance = 2
    elseif value == "blizzard" then
        if currentQuestPOI and currentQuestPOI ~= "1" then
            SetCVar("questPOI", "1")
        end
        if WorldMapQuestShowObjectives then
            WorldMapQuestShowObjectives:SetChecked(false)
        end
        QuestieSmazak.db.profile.enableObjectives = false
        QuestieSmazak.db.profile.ICON_SLAY = QuestieSmazak.icons["slay"]
        QuestieSmazak.db.profile.ICON_LOOT = QuestieSmazak.icons["loot"]
        QuestieSmazak.db.profile.ICON_EVENT = QuestieSmazak.icons["event"]
        QuestieSmazak.db.profile.ICON_OBJECT = QuestieSmazak.icons["object"]
        QuestieSmazak.db.profile.ICON_TALK = QuestieSmazak.icons["talk"]
        QuestieSmazak.db.profile.ICON_INTERACT = QuestieSmazak.icons["interact"]
        QuestieSmazak.db.profile.questObjectiveColors = optionsDefaults.profile.questObjectiveColors
        QuestieSmazak.db.profile.alwaysGlowMap = optionsDefaults.profile.alwaysGlowMap
        QuestieSmazak.db.profile.questMinimapObjectiveColors = optionsDefaults.profile.questMinimapObjectiveColors
        QuestieSmazak.db.profile.alwaysGlowMinimap = optionsDefaults.profile.alwaysGlowMinimap
        QuestieSmazak.db.profile.objectiveFilterDistance = optionsDefaults.profile.objectiveFilterDistance
    elseif value == "custom" then
        return
    end
    QuestieSmazak:SetIcons()
    QuestieQuest:SmoothReset()
end