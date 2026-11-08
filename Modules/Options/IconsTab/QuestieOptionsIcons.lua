---@type QuestieOptions
local QuestieOptions = QuestieSmazakLoader:ImportModule("QuestieOptions");
---@type QuestieOptionsDefaults
local QuestieOptionsDefaults = QuestieSmazakLoader:ImportModule("QuestieOptionsDefaults");
---@type QuestieOptionsUtils
local QuestieOptionsUtils = QuestieSmazakLoader:ImportModule("QuestieOptionsUtils");
---@type QuestieFramePool
local QuestieFramePool = QuestieSmazakLoader:ImportModule("QuestieFramePool");
---@type QuestieMap
local QuestieMap = QuestieSmazakLoader:ImportModule("QuestieMap");
---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")
---@type QuestieQuest
local QuestieQuest = QuestieSmazakLoader:ImportModule("QuestieQuest");
---@type ActiveQuests
local ActiveQuests = QuestieSmazakLoader:ImportModule("ActiveQuests")
---@type QuestieTooltips
local QuestieTooltips = QuestieSmazakLoader:ImportModule("QuestieTooltips");
---@type QuestieMenu
local QuestieMenu = QuestieSmazakLoader:ImportModule("QuestieMenu");
---@type Expansions
local Expansions = QuestieSmazakLoader:ImportModule("Expansions")
---@type ThreadLib
local ThreadLib = QuestieSmazakLoader:ImportModule("ThreadLib")

QuestieOptions.tabs.icons = {...}
local optionsDefaults = QuestieOptionsDefaults:Load()

local _GetIconTypes
local _GetIconTypesSort
local _GetIconThemes
local _GetIconThemesSort

function QuestieOptions.tabs.icons:Initialize()
    return {
        name = function() return l10n("Icons"); end,
        type = "group",
        order = 2,
        args = {
            icon_options = {
                type = "header",
                order = 1,
                width = "normal",
                name = function() return l10n("Icon Options"); end,
            },
            iconsSpacer = {
                type = "description",
                order = 1.01,
                name = "",
                desc = "",
                image = "",
                imageWidth = 0.06,
                width = 0.06,
                func = function() end,
            },
            show_icons = {
                type = "toggle",
                order = 1.1,
                name = function() return l10n("Enable Icons"); end,
                desc = function() return l10n("Shows or hides the icons that QuestieSmazak draws on the world map and minimap."); end,
                descStyle = "inline",
                width = 1.595,
                get = function() return QuestieSmazak.db.profile.enabled; end,
                set = function(info, value)
                    QuestieSmazak.db.profile.enabled = value
                    QuestieQuest:ToggleNotes(value);
                end,
            },
            themeSpacer = {
                type = "description",
                order = 1.11,
                name = "",
                desc = "",
                image = "",
                imageWidth = 0.3,
                width = 0.3,
                func = function() end,
            },
            iconThemePicker = {
                type = "select",
                order = 1.2,
                values = _GetIconThemes,
                sorting = _GetIconThemesSort(),
                style = "dropdown",
                width = 1,
                disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                name = function() return l10n("Objective Icon Theme") end,
                desc = function() return l10n("Change between themes for objective icons."); end,
                get = function() return QuestieSmazak.db.profile.iconTheme; end,
                set = function(info, value) QuestieOptionsUtils.ExecuteTheme(info, value) end,
            },
            themeSpacerPost = {
                type = "description",
                order = 1.21,
                name = "",
                desc = "",
                image = "",
                imageWidth = 0.35,
                width = 0.35,
                func = function() end,
            },
            untrackedSpacer = {
                type = "description",
                order = 1.22,
                name = "",
                desc = "",
                image = "",
                imageWidth = 0.06,
                width = 0.06,
                func = function() end,
            },
            hideMapIconsForUntrackedToggle = {
                type = "toggle",
                order = 1.3,
                name = function() return l10n("Hide icons of untracked quests"); end,
                desc = function() return l10n("Hide icons for quests that are not tracked."); end,
                width = 1.6,
                disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                get = function() return QuestieSmazak.db.profile.hideUntrackedQuestsMapIcons; end,
                set = function(_, value)
                    QuestieSmazak.db.profile.hideUntrackedQuestsMapIcons = value
                    ThreadLib.ThreadInstant(function()
                        if value then
                            QuestieQuest:HideQuestIcons()
                        else
                            QuestieQuest:ShowQuestIcons()
                        end

                        -- Hides tooltips for untracked quests
                        if value == true then
                            for questId, acceptance in ActiveQuests.Iterate() do
                                if acceptance.quest and (not QuestieQuest:ShouldShowQuestNotes(questId)) then
                                    QuestieTooltips:RemoveQuest(questId)
                                end
                            end
                        end

                        -- Readds tooltips from all missing quests
                        if value == false then
                            for _, acceptance in ActiveQuests.Iterate() do
                                if acceptance.quest then
                                    QuestieQuest:PopulateObjectiveNotes(acceptance.quest)
                                end
                            end
                        end
                    end)
                end,
            },
            icon_toggles_group = {
                type = "group",
                order = 2,
                inline = true,
                width = 0.5,
                name = function() return l10n("Show icons for..."); end,
                disabled = function() return not QuestieSmazak.db.profile.enabled end,
                args = {
                    quest_options = {
                        type = "header",
                        order = 2,
                        width = "normal",
                        name = function() return l10n("Quests"); end,
                    },
                    showNormalQuests = {
                        type = "toggle",
                        order = 2.01,
                        name = function() return l10n("Available Normal Quests"); end,
                        desc = function() return l10n("If checked, the locations of available quests will be shown on the map/minimap."); end,
                        width = 1.595,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        get = function() return QuestieSmazak.db.profile.enableAvailable; end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.enableAvailable = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showItemQuests = {
                        type = "toggle",
                        order = 2.011,
                        name = function() return l10n("Available Quests from Items"); end,
                        desc = function() return l10n("If checked, the locations of item drops that start quests will be shown on the map/minimap."); end,
                        width = 1.595,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        get = function() return QuestieSmazak.db.profile.enableAvailableItems; end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.enableAvailableItems = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showEventQuests = {
                        type = "toggle",
                        order = 2.02,
                        name = function() return l10n("Available Event Quests"); end,
                        desc = function() return l10n("If checked, the locations of active event quests will be shown on the map/minimap."); end,
                        width = 1.595,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        get = function(info) return QuestieSmazak.db.profile.showEventQuests end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.showEventQuests = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showRepeatableQuests = {
                        type = "toggle",
                        order = 2.03,
                        name = function() return l10n("Available Repeatable Quests"); end,
                        desc = function() return l10n("If checked, the locations of repeatable quests will be shown on the map/minimap."); end,
                        width = 1.595,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        get = function(info) return QuestieSmazak.db.profile.showRepeatableQuests end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.showRepeatableQuests = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showPvPQuests = {
                        type = "toggle",
                        order = 2.04,
                        name = function() return l10n("Available PvP Quests"); end,
                        desc = function() return l10n("If checked, the locations of PvP quests will be shown on the map/minimap."); end,
                        width = 1.595,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        get = function(info) return QuestieSmazak.db.profile.showPvPQuests end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.showPvPQuests = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showDungeonQuests = {
                        type = "toggle",
                        order = 2.05,
                        name = function() return l10n("Available Dungeon Quests"); end,
                        desc = function() return l10n("If checked, the locations of dungeon quests will be shown on the map/minimap."); end,
                        width = 1.595,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        get = function(info) return QuestieSmazak.db.profile.showDungeonQuests end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.showDungeonQuests = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showRaidQuests = {
                        type = "toggle",
                        order = 2.06,
                        name = function() return l10n("Available Raid Quests"); end,
                        desc = function() return l10n("If checked, the locations of raid quests will be shown on the map/minimap."); end,
                        width = 1.595,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        get = function(info) return QuestieSmazak.db.profile.showRaidQuests end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.showRaidQuests = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showCompleteQuests = {
                        type = "toggle",
                        order = 2.07,
                        name = function() return l10n("Completed Quests"); end,
                        desc = function() return l10n("If checked, the quest turn-in locations will be shown on the map/minimap."); end,
                        width = 1.595,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        get = function() return QuestieSmazak.db.profile.enableTurnins; end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.enableTurnins = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    showObjectivesToggle = {
                        type = "toggle",
                        order = 2.08,
                        name = function() return l10n("Objectives"); end,
                        desc = function() return l10n("If checked, quest objective icons will be shown on the map/minimap."); end,
                        width = 1.595,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        get = function() return QuestieSmazak.db.profile.enableObjectives; end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.enableObjectives = value
                            QuestieQuest:ToggleNotes(value)
                            QuestieOptionsUtils.DetermineTheme()
                        end,
                    },
                    showAQWarEffortQuests = {
                        type = "toggle",
                        order = 2.09,
                        hidden = (not QuestieSmazak.IsClassic),
                        name = function() return l10n("Available AQ War Effort Quests"); end,
                        desc = function() return l10n("If checked, the locations of the AQ War Effort quests will be shown on the map/minimap."); end,
                        width = 1.595,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        get = function(info) return QuestieSmazak.db.profile.showAQWarEffortQuests end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.showAQWarEffortQuests = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    sod_rune_options = {
                        type = "header",
                        order = 2.091,
                        width = "normal",
                        hidden = (not QuestieSmazak.IsSoD),
                        name = function() return l10n("Season of Discovery Runes"); end,
                    },
                    showSoDRunes = {
                        type = "toggle",
                        order = 2.092,
                        hidden = (not QuestieSmazak.IsSoD),
                        name = function() return l10n("Show Runes"); end,
                        desc = function() return l10n("If checked, the locations of Season of Discovery Runes and Rune quests will be shown on the map/minimap."); end,
                        width = "full",
                        disabled = function()
                            return (not QuestieSmazak.db.profile.enabled);
                        end,
                        get = function(info) return QuestieSmazak.db.profile.showSoDRunes end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.showSoDRunes = value
                            QuestieQuest.ToggleAvailableQuests(value)
                        end,
                    },
                    sodRuneSelection = {
                        type = "group",
                        order = 2.093,
                        name = "",
                        hidden = (not QuestieSmazak.IsSoD),
                        disabled = function() return not QuestieSmazak.db.profile.showSoDRunes end,
                        args = {
                            phase1 = {
                                type = "toggle",
                                name = l10n("Phase 1"),
                                get = function() return QuestieSmazak.db.profile.showRunesOfPhase.phase1; end,
                                set = function(info, value)
                                    QuestieSmazak.db.profile.showRunesOfPhase.phase1 = value
                                    QuestieQuest.ToggleAvailableQuests(value)
                                end,
                            },
                            phase2 = {
                                type = "toggle",
                                name = l10n("Phase 2"),
                                get = function() return QuestieSmazak.db.profile.showRunesOfPhase.phase2; end,
                                set = function(info, value)
                                    QuestieSmazak.db.profile.showRunesOfPhase.phase2 = value
                                    QuestieQuest.ToggleAvailableQuests(value)
                                end,
                            },
                            phase3 = {
                                type = "toggle",
                                name = l10n("Phase 3"),
                                get = function() return QuestieSmazak.db.profile.showRunesOfPhase.phase3; end,
                                set = function(info, value)
                                    QuestieSmazak.db.profile.showRunesOfPhase.phase3 = value
                                    QuestieQuest.ToggleAvailableQuests(value)
                                end,
                            },
                            phase4 = {
                                type = "toggle",
                                name = l10n("Phase 4"),
                                get = function() return QuestieSmazak.db.profile.showRunesOfPhase.phase4; end,
                                set = function(info, value)
                                    QuestieSmazak.db.profile.showRunesOfPhase.phase4 = value
                                    QuestieQuest.ToggleAvailableQuests(value)
                                end,
                            },
                        },
                    },
                    townsfolk_options = {
                        type = "header",
                        order = 2.10,
                        width = "normal",
                        name = function() return l10n("Other Icons"); end,
                    },
                    townsfolkSpacer1 = {
                        type = "description",
                        order = 2.11,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.32,
                        width = 0.32,
                        func = function() end,
                    },
                    townsfolkOptions = {
                        type = "execute",
                        order = 2.12,
                        name = function() return l10n("Townsfolk"); end,
                        desc = function() return l10n("Allows to select which tracking icons (like Mailbox, Repair-NPCs) to show on the map and minimap."); end,
                        width = 0.8,
                        disabled = false,
                        func = function(info, value)
                            QuestieMenu:ShowTownsfolk(1)
                        end
                    },
                    professionOptions = {
                        type = "execute",
                        order = 2.13,
                        name = function() return l10n("Profession Trainers"); end,
                        desc = function() return l10n("Allows to select which profession trainers to show on the map and minimap."); end,
                        width = 0.95,
                        disabled = false,
                        func = function(info, value)
                            QuestieMenu:ShowProfessions(1)
                        end
                    },
                    vendorOptions = {
                        type = "execute",
                        order = 2.14,
                        name = function() return l10n("Vendors"); end,
                        desc = function() return l10n("Allows to select which vendors to show on the map and minimap."); end,
                        width = 0.8,
                        disabled = false,
                        func = function(info, value)
                            QuestieMenu:ShowVendors(1)
                        end
                    },
                },
            },
            map_settings_group = {
                type = "group",
                order = 3,
                inline = true,
                width = 0.5,
                name = function() return l10n("Map Options"); end,
                args = {
                    enableMapToggle = {
                        type = "toggle",
                        order = 3.1,
                        name = function() return l10n("Enable Map Icons"); end,
                        desc = function() return l10n("Show/hide all icons from the main map."); end,
                        descStyle = "inline",
                        width = 3.1,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        get = function() return QuestieSmazak.db.profile.enableMapIcons; end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.enableMapIcons = value
                            QuestieQuest:ToggleNotes(value)
                        end,
                    },
                    alwaysGlowMap = {
                        type = "toggle",
                        order = 3.2,
                        name = function() return l10n("Map Icons Glow"); end,
                        desc = function() return l10n("Draw a glow texture behind map icons, colored unique to each quest."); end,
                        width = 1.595,
                        disabled = function() return ((not QuestieSmazak.db.profile.enabled) or (not QuestieSmazak.db.profile.enableMapIcons)); end,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieOptions:SetProfileValue(info, value)
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieFramePool:UpdateGlowConfig(false, value)
                        end,
                    },
                    questObjectiveColors = {
                        type = "toggle",
                        order = 3.3,
                        name = function() return l10n("Unique Map Icon Colors"); end,
                        desc = function() return l10n("Show map icons with colors that are randomly generated based on quest ID."); end,
                        width = 1.595,
                        disabled = function() return ((not QuestieSmazak.db.profile.enabled) or (not QuestieSmazak.db.profile.enableMapIcons)); end,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieOptions:SetProfileValue(info, value)
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieFramePool:UpdateColorConfig(false, value)
                        end,
                    },
                    hideUnexploredMapIconsToggle = {
                        type = "toggle",
                        order = 3.4,
                        name = function() return l10n("Hide Icons in Unexplored Areas"); end,
                        desc = function() return l10n("Hide icons in unexplored map regions."); end,
                        width = 1.595,
                        disabled = function() return ((not QuestieSmazak.db.profile.enabled) or (not QuestieSmazak.db.profile.enableMapIcons)); end,
                        get = function() return QuestieSmazak.db.profile.hideUnexploredMapIcons; end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.hideUnexploredMapIcons = value
                            QuestieQuest:ToggleNotes(not value)
                        end,
                    },
                    hideIconsOnContinents = {
                        type = "toggle",
                        order = 3.5,
                        name = function() return l10n("Hide Icons on Continent Map"); end,
                        desc = function() return l10n("Hide icons on the continent map, when not viewing a specific zone."); end,
                        width = 1.595,
                        disabled = function() return ((not QuestieSmazak.db.profile.enabled) or (not QuestieSmazak.db.profile.enableMapIcons)); end,
                        get = function() return QuestieSmazak.db.profile.hideIconsOnContinents; end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.hideIconsOnContinents = value
                            QuestieQuest:SmoothReset()
                        end,
                    },
                },
            },
            minimap_settings_group = {
                type = "group",
                order = 4,
                inline = true,
                width = 0.5,
                name = function() return l10n("Minimap Options"); end,
                disabled = function() return not QuestieSmazak.db.profile.enabled end,
                args = {
                    enableMiniMapToggle = {
                        type = "toggle",
                        order = 4.1,
                        name = function() return l10n("Enable Minimap Icons"); end,
                        desc = function() return l10n("Show/hide all icons from the minimap."); end,
                        descStyle = "inline",
                        width = 3.1,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        get = function() return QuestieSmazak.db.profile.enableMiniMapIcons; end,
                        set = function(info, value)
                            QuestieSmazak.db.profile.enableMiniMapIcons = value
                            QuestieQuest:ToggleNotes(value)
                        end,
                    },
                    alwaysGlowMinimap = {
                        type = "toggle",
                        order = 4.2,
                        name = function() return l10n("Minimap Icons Glow"); end,
                        desc = function() return l10n("Draw a glow texture behind minimap icons, colored unique to each quest."); end,
                        width = 1.595,
                        disabled = function() return ((not QuestieSmazak.db.profile.enabled) or (not QuestieSmazak.db.profile.enableMiniMapIcons)); end,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieOptions:SetProfileValue(info, value)
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieFramePool:UpdateGlowConfig(true, value)
                        end,
                    },
                    questMinimapObjectiveColors = {
                        type = "toggle",
                        order = 4.3,
                        name = function() return l10n("Unique Minimap Icon Colors"); end,
                        desc = function() return l10n("Show minimap icons with colors that are randomly generated based on quest ID."); end,
                        width = 1.595,
                        disabled = function() return ((not QuestieSmazak.db.profile.enabled) or (not QuestieSmazak.db.profile.enableMiniMapIcons)); end,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieOptions:SetProfileValue(info, value)
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieFramePool:UpdateColorConfig(true, value)
                        end,
                    },
                    fadeLevel = {
                        type = "range",
                        order = 4.4,
                        name = function() return l10n("Minimap Icon Fade Distance"); end,
                        desc = function()
                            return l10n("How much objective icons should fade depending on distance.\n(Default: %s)",
                                optionsDefaults.profile.fadeLevel);
                        end,
                        width = 3.1,
                        min = 10,
                        max = 100,
                        step = 1,
                        disabled = function() return ((not QuestieSmazak.db.profile.enabled) or (not QuestieSmazak.db.profile.enableMiniMapIcons)); end,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                    fadeOverPlayer = {
                        type = "toggle",
                        order = 4.5,
                        name = function() return l10n("Fade Icons over Player"); end,
                        desc = function() return l10n("Fades icons on the minimap when your player walks near them."); end,
                        width = "full",
                        disabled = function() return ((not QuestieSmazak.db.profile.enabled) or (not QuestieSmazak.db.profile.enableMiniMapIcons)); end,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                    fadeOverPlayerDistance = {
                        type = "range",
                        order = 4.6,
                        name = function() return l10n("Fade over Player Distance"); end,
                        desc = function()
                            return l10n("How far from player should icons start to fade.\n(Default: %s)",
                                optionsDefaults.profile.fadeOverPlayerDistance);
                        end,
                        width = 1.55,
                        min = 0,
                        max = 20,
                        step = 0.5,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        disabled = function() return ((not QuestieSmazak.db.profile.enabled) or (not QuestieSmazak.db.profile.enableMiniMapIcons) or (not QuestieSmazak.db.profile.fadeOverPlayer)); end,
                        --disabled = function() return (not QuestieSmazak.db.profile.fadeOverPlayer); end,
                        set = function(info, value)
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                    fadeOverPlayerLevel = {
                        type = "range",
                        order = 4.7,
                        name = function() return l10n("Fade over Player Amount"); end,
                        desc = function()
                            return l10n("How much should the icons around the player fade.\n(Default: %s)",
                                optionsDefaults.profile.fadeOverPlayerLevel);
                        end,
                        width = 1.55,
                        min = 0.1,
                        max = 1,
                        step = 0.1,
                        disabled = function() return ((not QuestieSmazak.db.profile.enabled) or (not QuestieSmazak.db.profile.enableMiniMapIcons) or (not QuestieSmazak.db.profile.fadeOverPlayer)); end,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                },
            },
            icon_scales_group = {
                type = "group",
                order = 5,
                inline = true,
                width = 0.5,
                name = function() return l10n("Icon Scales"); end,
                disabled = function() return not QuestieSmazak.db.profile.enabled end,
                args = {
                    globalScale = {
                        type = "range",
                        order = 5.1,
                        name = function() return l10n("Map Icons"); end,
                        desc = function() return l10n("How large the map icons are.\n(Default: %s)", optionsDefaults.profile.globalScale); end,
                        width = 1.55,
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieMap:RescaleIcons()
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                    globalMiniMapScale = {
                        type = "range",
                        order = 5.2,
                        name = function() return l10n("Minimap Icons"); end,
                        desc = function() return l10n("How large the minimap icons are.\n(Default: %s)", optionsDefaults.profile.globalMiniMapScale); end,
                        width = 1.55,
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieMap:RescaleIcons()
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                    globalTownsfolkScale = {
                        type = "range",
                        order = 5.3,
                        name = function() return l10n("Townsfolk Icons"); end,
                        desc = function() return l10n("How large the townsfolk map icons are.\n(Default: %s)", optionsDefaults.profile.globalTownsfolkScale); end,
                        width = 1.55,
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieMap:RescaleTownsfolkIcons()
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                    globalMiniMapTownsfolkScale = {
                        type = "range",
                        order = 5.31,
                        name = function() return l10n("Minimap Townsfolk Icons"); end,
                        desc = function()
                            return l10n("How large the townsfolk minimap icons are.\n(Default: %s)",
                                optionsDefaults.profile.globalMiniMapTownsfolkScale);
                        end,
                        width = 1.55,
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieMap:RescaleTownsfolkIcons()
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                    spacer_scale = QuestieOptionsUtils:Spacer(5.4),
                    availableScale = {
                        type = "range",
                        order = 5.4,
                        name = function() return l10n("Quest Icons"); end,
                        desc = function()
                            return l10n("How large the available/complete icons are. Affects both map and minimap icons.\n(Default: %s)",
                                optionsDefaults.profile.availableScale);
                        end,
                        width = 3.1,
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieMap:RescaleIcons()
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                    lootScale = {
                        type = "range",
                        order = 5.5,
                        name = function() return l10n("Loot objectives"); end,
                        desc = function() return l10n("How large the loot icons are.\n(Default: %s)", optionsDefaults.profile.lootScale); end,
                        width = 1.55,
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieMap:RescaleIcons()
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                    monsterScale = {
                        type = "range",
                        order = 5.6,
                        name = function() return l10n("Slay objectives"); end,
                        desc = function() return l10n("How large the slay icons are.\n(Default: %s)", optionsDefaults.profile.monsterScale); end,
                        width = 1.55,
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieMap:RescaleIcons()
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                    eventScale = {
                        type = "range",
                        order = 5.7,
                        name = function() return l10n("Event objectives"); end,
                        desc = function() return l10n("How large the event icons are.\n(Default: %s)", optionsDefaults.profile.eventScale); end,
                        width = 1.55,
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieMap:RescaleIcons()
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                    objectScale = {
                        type = "range",
                        order = 5.8,
                        name = function() return l10n("Object objectives"); end,
                        desc = function() return l10n("How large the object icons are.\n(Default: %s)", optionsDefaults.profile.objectScale); end,
                        width = 1.55,
                        min = 0.01,
                        max = 4,
                        step = 0.01,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieMap:RescaleIcons()
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                },
            },
            iconOverrides = {
                type = "group",
                order = 16,
                inline = true,
                name = function() return l10n("Icon Overrides") end,
                args = {
                    --usePfQuestIcons = {
                    --    type = "toggle",
                    --    order = 16.1,
                    --    name = function() return l10n("Toggle pfQuest/ClassicCodex icon style"); end,
                    --    desc = function()
                    --        return l10n("Toggles between QuestieSmazak icon style and pfQuest/ClassicCodex icon style.\n\nToggling affects the following settings:\n\n- Objective icons\n- ")
                    --            .. l10n("Map Icons Glow") .. "\n- "
                    --            .. l10n("Unique Map Icon Colors") .. "\n- "
                    --            .. l10n("Minimap Icons Glow") .. "\n- "
                    --            .. l10n("Unique Minimap Icon Colors") .. "\n- "
                    --            .. l10n("Objective icon cluster amount");
                    --    end,
                    --    width = 3,
                    --    disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                    --    get = function(info) return QuestieSmazak.db.profile.usePfQuestIcons end,
                    --    set = QuestieOptionsUtils.SetPfQuestIcons,
                    --},
                    overrideObjectivesHeader = {
                        type = "header",
                        order = 16.5,
                        name = function() return l10n("Objectives") end,
                    },
                    objectiveSpacer1 = {
                        type = "description",
                        order = 16.9,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypeSlay = {
                        type = "select",
                        order = 17,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 0.796,
                        name = function() return l10n("Slay objectives") end,
                        desc = function() return l10n("The icon that is displayed for quest objectives where you need to kill an NPC"); end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_SLAY) or "slay"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_SLAY = QuestieSmazak.icons[key]
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    objectiveSpacer2 = {
                        type = "description",
                        order = 17.5,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypeLoot = {
                        type = "select",
                        order = 18,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 0.796,
                        name = function() return l10n("Loot objectives") end,
                        desc = function() return l10n("The icon that is displayed for quest objectives where you need to loot an item"); end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_LOOT) or "loot"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_LOOT = QuestieSmazak.icons[key]
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    objectiveSpacer3 = {
                        type = "description",
                        order = 18.5,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypeObject = {
                        type = "select",
                        order = 19,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 0.796,
                        name = function() return l10n("Object objectives") end,
                        desc = function() return l10n("The icon that is displayed for quest objectives where you need to interact with an object"); end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_OBJECT) or "object"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_OBJECT = QuestieSmazak.icons[key]
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    iconTypeLineBreak = QuestieOptionsUtils:Spacer(19.3, nil, "minimal"),
                    objectiveSpacer4 = {
                        type = "description",
                        order = 19.5,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypeEvent = {
                        type = "select",
                        order = 20,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 0.796,
                        name = function() return l10n("Event objectives") end,
                        desc = function()
                            return l10n(
                                "The icon that is displayed for quest objectives where you need to do something in a certain area, like exploring it or casting a spell there");
                        end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_EVENT) or "event"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_EVENT = QuestieSmazak.icons[key]
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    objectiveSpacer5 = {
                        type = "description",
                        order = 20.5,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypeTalk = {
                        type = "select",
                        order = 21,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 0.796,
                        name = function() return l10n("Talk objectives") end,
                        desc = function() return l10n("The icon that is displayed for quest objectives where you need to talk to an NPC"); end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_TALK) or "talk"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_TALK = QuestieSmazak.icons[key]
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    objectiveSpacer6 = {
                        type = "description",
                        order = 21.1,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypeInteract = {
                        type = "select",
                        order = 21.2,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 0.796,
                        name = function() return l10n("Interact objectives") end,
                        desc = function() return l10n("The icon that is displayed for quest objectives where you need to use an item or interact with an NPC"); end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_INTERACT) or "interact"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_INTERACT = QuestieSmazak.icons[key]
                            QuestieOptionsUtils.DetermineTheme()
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    overrideNormalQuestsHeader = {
                        type = "header",
                        order = 22,
                        name = function() return l10n("Quests") end,
                    },
                    questSpacer1 = {
                        type = "description",
                        order = 22.5,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypeAvailable = {
                        type = "select",
                        order = 23,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 0.796,
                        name = function() return l10n("Available quests") end,
                        desc = function() return l10n("The icon that is displayed for available quests"); end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_AVAILABLE) or "available"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_AVAILABLE = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    questSpacer2 = {
                        type = "description",
                        order = 23.5,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypeComplete = {
                        type = "select",
                        order = 25,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 0.796,
                        name = function() return l10n("Complete quests") end,
                        desc = function() return l10n("The icon that is displayed for completed quests that can be handed in"); end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_COMPLETE) or "complete"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_COMPLETE = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    questSpacer3 = {
                        type = "description",
                        order = 25.5,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypeAvailableGray = {
                        type = "select",
                        order = 26,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 0.796,
                        name = function() return l10n("Unavailable and trivial quests") end,
                        desc = function()
                            return l10n(
                                "The icon that is displayed for quests that require additional conditions to be met before they can be accepted, or are so low level they don't reward experience");
                        end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_AVAILABLE_GRAY) or "available_gray"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_AVAILABLE_GRAY = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    repeatable_spacer = QuestieOptionsUtils:Spacer(27, nil, "minimal"),
                    repeatableSpacer1 = {
                        type = "description",
                        order = 27.5,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypeRepeatable = {
                        type = "select",
                        order = 28,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 1.295,
                        name = function() return l10n("Available repeatable quests") end,
                        desc = function() return l10n("The icon that is displayed for available repeatable quests like dailies"); end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_REPEATABLE) or "repeatable"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_REPEATABLE = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    repeatableSpacer2 = {
                        type = "description",
                        order = 28.5,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypeRepeatableComplete = {
                        type = "select",
                        order = 29,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 1.295,
                        name = function() return l10n("Complete repeatable quests") end,
                        desc = function() return l10n("The icon that is displayed for repeatable quests that can be handed in"); end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_REPEATABLE_COMPLETE) or "repeatable_complete"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_REPEATABLE_COMPLETE = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    event_spacer = QuestieOptionsUtils:Spacer(30, nil, "minimal"),
                    eventSpacer1 = {
                        type = "description",
                        order = 30.5,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypeEventQuest = {
                        type = "select",
                        order = 31,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 1.295,
                        name = function() return l10n("Available event quests") end,
                        desc = function() return l10n("The icon that is displayed for available event quests during holidays"); end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_EVENTQUEST) or "eventquest"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_EVENTQUEST = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    eventSpacer2 = {
                        type = "description",
                        order = 31.5,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypeEventQuestComplete = {
                        type = "select",
                        order = 32,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 1.295,
                        name = function() return l10n("Complete event quests") end,
                        desc = function() return l10n("The icon that is displayed for event quests that can be handed in"); end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_EVENTQUEST_COMPLETE) or "eventquest_complete"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_EVENTQUEST_COMPLETE = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    pvp_spacer = QuestieOptionsUtils:Spacer(33, nil, "minimal"),
                    pvpSpacer1 = {
                        type = "description",
                        order = 33.5,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypePVPQuest = {
                        type = "select",
                        order = 34,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 1.295,
                        name = function() return l10n("Available PvP quests") end,
                        desc = function() return l10n("The icon that is displayed for available PvP quests"); end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_PVPQUEST) or "pvpquest"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
                            QuestieSmazak.db.profile.ICON_PVPQUEST = QuestieSmazak.icons[key]
                            QuestieSmazak:SetIcons()
                            QuestieQuest:SmoothReset()
                        end,
                    },
                    pvpSpacer2 = {
                        type = "description",
                        order = 34.5,
                        name = "",
                        desc = "",
                        image = "",
                        imageWidth = 0.2,
                        width = 0.2,
                        func = function() end,
                    },
                    iconTypePVPQuestComplete = {
                        type = "select",
                        order = 35,
                        values = _GetIconTypes,
                        sorting = _GetIconTypesSort(),
                        style = "dropdown",
                        width = 1.295,
                        name = function() return l10n("Complete PvP quests") end,
                        desc = function() return l10n("The icon that is displayed for PvP quests that can be handed in"); end,
                        get = function() return QuestieSmazak:GetIconNameFromPath(QuestieSmazak.db.profile.ICON_PVPQUEST_COMPLETE) or "pvpquest_complete"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.enabled); end,
                        set = function(input, key)
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

function QuestieOptionsUtils.SetPfQuestIcons(info, value)
    QuestieSmazak.db.profile.usePfQuestIcons = value
    if value then
        QuestieSmazak.db.profile.ICON_SLAY = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_LOOT = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_EVENT = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_OBJECT = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_TALK = QuestieSmazak.icons["node"]
        QuestieSmazak.db.profile.ICON_INTERACT = QuestieSmazak.icons["node"]
        -- TODO remove these setting changes once we have a style selection window/frame
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
        -- TODO remove these setting changes once we have a style selection window/frame
        QuestieSmazak.db.profile.questObjectiveColors = false
        QuestieSmazak.db.profile.alwaysGlowMap = true
        QuestieSmazak.db.profile.questMinimapObjectiveColors = false
        QuestieSmazak.db.profile.alwaysGlowMinimap = false
        QuestieSmazak.db.profile.objectiveFilterDistance = optionsDefaults.profile.objectiveFilterDistance
    end
    QuestieSmazak:SetIcons()
    QuestieQuest:SmoothReset()
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
        if currentQuestPOI and currentQuestPOI ~= "0" then -- check for Blizzard style objectives
            SetCVar("questPOI", "0")
        end
        if WorldMapQuestShowObjectives then
            -- Blizzard objectives button exists
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
        if currentQuestPOI and currentQuestPOI ~= "0" then -- check for Blizzard style objectives
            SetCVar("questPOI", "0")
        end
        if WorldMapQuestShowObjectives then
            -- Blizzard objectives button exists
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
        if currentQuestPOI and currentQuestPOI ~= "1" then -- check for Blizzard style objectives
            SetCVar("questPOI", "1")
        end
        if WorldMapQuestShowObjectives then
            -- Blizzard objectives button exists
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
