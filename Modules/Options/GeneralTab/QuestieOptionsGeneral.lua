---@type QuestieOptions
local QuestieOptions = QuestieSmazakLoader:ImportModule("QuestieOptions");
---@type QuestieOptionsDefaults
local QuestieOptionsDefaults = QuestieSmazakLoader:ImportModule("QuestieOptionsDefaults");
---@type QuestieOptionsUtils
local QuestieOptionsUtils = QuestieSmazakLoader:ImportModule("QuestieOptionsUtils");
---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")
---@type WorldMapButton
local WorldMapButton = QuestieSmazakLoader:ImportModule("WorldMapButton")
---@type QuestieCoords
local QuestieCoords = QuestieSmazakLoader:ImportModule("QuestieCoords");
---@type QuestieTracker
local QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker");
---@type QuestieShutUp
local QuestieShutUp = QuestieSmazakLoader:ImportModule("QuestieShutUp")
---@type Sounds
local Sounds = QuestieSmazakLoader:ImportModule("Sounds")
---@type AvailableQuests
local AvailableQuests = QuestieSmazakLoader:ImportModule("AvailableQuests")
---@type Expansions
local Expansions = QuestieSmazakLoader:ImportModule("Expansions")
---@type MinimapIcon
local MinimapIcon = QuestieSmazakLoader:ImportModule("MinimapIcon")
---@type QuestiePartyObjectives
local QuestiePartyObjectives = QuestieSmazakLoader:ImportModule("QuestiePartyObjectives")
---@type QuestieComms
local QuestieComms = QuestieSmazakLoader:ImportModule("QuestieComms")

QuestieOptions.tabs.general = { ... }
local optionsDefaults = QuestieOptionsDefaults:Load()

local LSM30 = LibStub("LibSharedMedia-3.0")

local tinsert, tableSort, stringLower = table.insert, table.sort, string.lower

local _GetAnnounceChannels
local _IsAnnounceDisabled
local _GetQuestSoundChoices
local _GetObjectiveSoundChoices
local _GetObjectiveProgressSoundChoices
local _GetSortedOptions

function QuestieOptions.tabs.general:Initialize()
    return {
        name = function() return l10n("General"); end,
        type = "group",
        order = 1,
        args = {
            questie_header = {
                type = "header",
                order = 1,
                name = function() return l10n("General Options"); end,
            },
            social_spacer = QuestieOptionsUtils:Spacer(1.5,nil,"minimal"),
            social_options_group = {
                type = "group",
                order = 2,
                inline = true,
                name = function() return l10n("Social Options"); end,
                args = {
                    filterQuestieAnnounce = {
                        type = "toggle",
                        order = 7.1,
                        name = function() return l10n("QuestieSmazak ShutUp!"); end,
                        desc = function() return l10n("Remove all QuestieSmazak chat messages coming from other players and disable sending your own."); end,
                        descStyle = "inline",
                        disabled = function() return false end,
                        width = 2,
                        get = function () return QuestieSmazak.db.profile.questieShutUp end,
                        set = function (_, value)
                            QuestieSmazak.db.profile.questieShutUp = value
                            QuestieShutUp:ToggleFilters(value)
                        end,
                    },
                    questAnnounceChannel = {
                        type = "select",
                        order = 7.2,
                        values = _GetAnnounceChannels,
                        style = "dropdown",
                        disabled = function() return QuestieSmazak.db.profile.questieShutUp end,
                        name = function() return l10n("Channels to announce in") end,
                        desc = function() return l10n("Announce quest updates to other players in your group"); end,
                        get = function() return QuestieSmazak.db.profile.questAnnounceChannel; end,
                        set = function(_, key)
                            QuestieSmazak.db.profile.questAnnounceChannel = key
                            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "Channels to announce changed to:", key)
                        end,
                    },
                    printLocalMessages = {
                        type = "toggle",
                        order = 7.3,
                        name = function() return l10n("Announce quest updates to yourself"); end,
                        desc = function() return l10n("QuestieSmazak will print your update messages to chat. Other players will NOT be able to see this."); end,
                        disabled = function() return QuestieSmazak.db.profile.questieShutUp end,
                        width = 2.5,
                        get = function () return QuestieSmazak.db.profile.questAnnounceLocally end,
                        set = function (_, value)
                            QuestieSmazak.db.profile.questAnnounceLocally = value
                            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "Quest announce locally changed to:", value)
                        end,
                    },
                    showPartyQuestObjectives = {
                        type = "toggle",
                        order = 7.35,
                        name = function() return l10n("Show party members' tracked quest objectives"); end,
                        desc = function()
                            return l10n(
                                "Show tracked quest objectives from party members on the map and minimap, even for quests you don't have or have already completed. Only your tracked quests will show for your party members.");
                        end,
                        width = 2.5,
                        get = function() return QuestieSmazak.db.profile.showPartyQuestObjectives end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.showPartyQuestObjectives = value
                            QuestiePartyObjectives:Update()
                        end,
                    },
                    shareQuestsNearby = {
                        type = "toggle",
                        order = 7.4,
                        name = function() return l10n("Share quest progress with nearby players"); end,
                        desc = function()
                            return l10n(
                                "Your quest progress will be periodically sent to nearby players. Disabling this doesn't affect sharing progress with party members.");
                        end,
                        disabled = function() return false end,
                        width = 1.7,
                        hidden = true, -- does this even do anything anymore after YELL removed?
                        get = function() return not QuestieSmazak.db.profile.disableYellComms end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.disableYellComms = not value
                            if not value then
                                QuestieComms:RemoveAllRemotePlayers()
                            end
                        end,
                    },
                    questAnnounceTypes = {
                        type = "group",
                        order = 7.5,
                        inline = true,
                        name = function() return l10n("Types of updates to announce in chat"); end,
                        disabled = function() return _IsAnnounceDisabled() or QuestieSmazak.db.profile.questieShutUp; end,
                        args = {
                            questAnnounceItems = {
                                type = "toggle",
                                order = 1,
                                name = function() return l10n("Items starting a quest"); end,
                                desc = function() return l10n("Announce looted items that start a quest to other players"); end,
                                width = 1.5,
                                get = function() return QuestieSmazak.db.profile.questAnnounceItems; end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.questAnnounceItems = value
                                    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "Items starting a quest changed to:", value)
                                end,
                            },
                            questAnnounceAccepted = {
                                type = "toggle",
                                order = 2,
                                name = function() return l10n("Quest accepted"); end,
                                desc = function() return l10n("Announce quest acceptance to other players"); end,
                                width = 1.5,
                                get = function() return QuestieSmazak.db.profile.questAnnounceAccepted; end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.questAnnounceAccepted = value
                                    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "Quest accepted announce changed to:", value)
                                end,
                            },
                            questAnnounceAbandoned = {
                                type = "toggle",
                                order = 3,
                                name = function() return l10n("Quest abandoned"); end,
                                desc = function() return l10n("Announce quest abortion to other players"); end,
                                width = 1.5,
                                get = function() return QuestieSmazak.db.profile.questAnnounceAbandoned; end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.questAnnounceAbandoned = value
                                    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "Quest abandoned announce changed to:", value)
                                end,
                            },
                            questAnnounceObjectives = {
                                type = "toggle",
                                order = 4,
                                name = function() return l10n("Objective completed"); end,
                                desc = function() return l10n("Announce completed objectives to other players"); end,
                                width = 1.5,
                                get = function() return QuestieSmazak.db.profile.questAnnounceObjectives; end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.questAnnounceObjectives = value
                                    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "Objective completed announce changed to:", value)
                                end,
                            },
                            questAnnounceCompleted = {
                                type = "toggle",
                                order = 5,
                                name = function() return l10n("Quest completed"); end,
                                desc = function() return l10n("Announce quest completion to other players"); end,
                                width = 1.5,
                                get = function() return QuestieSmazak.db.profile.questAnnounceCompleted; end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.questAnnounceCompleted = value
                                    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "Quest completed announce changed to:", value)
                                end,
                            },
                            questAnnounceIncompleteBreadcrumb = {
                                type = "toggle",
                                order = 6,
                                name = function() return l10n("Incomplete breadcrumb"); end,
                                desc = function() return l10n("Announce that you just picked up a quest for which you have an incomplete breadcrumb quest"); end,
                                width = 1.5,
                                get = function() return QuestieSmazak.db.profile.questAnnounceIncompleteBreadcrumb; end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.questAnnounceIncompleteBreadcrumb = value
                                    QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "Quest announce incomplete breadcrumb changed to:", value)
                                end,
                            },
                        },
                    },
                },
            },
            interface_spacer = QuestieOptionsUtils:Spacer(2.5, nil, "minimal"),
            interface_options_group = {
                type = "group",
                order = 3,
                inline = true,
                name = function() return l10n("Interface Options"); end,
                args = {
                    instantQuest = {
                        type = "toggle",
                        order = 5.1,
                        name = function() return l10n("Enable Instant Quest Text"); end,
                        desc = function() return l10n("Toggles the default Instant Quest Text option. This is just a shortcut for the WoW option in Interface."); end,
                        width = 1.55,
                        get = function()
                            if GetCVar("instantQuestText") == "1" then
                                return true;
                            else
                                return false;
                            end
                        end,
                        set = function(_, value)
                            if value then
                                SetCVar("instantQuestText", 1);
                            else
                                SetCVar("instantQuestText", 0);
                            end
                        end,
                    },
                    showCustomQuestFrameIcons = {
                        type = "toggle",
                        order = 5.2,
                        name = function() return l10n("Show custom quest frame icons"); end,
                        desc = function() return l10n("Use custom QuestieSmazak icons for NPC dialogs, reflecting the status and type of each quest."); end,
                        width = 1.55,
                        get = function() return QuestieSmazak.db.profile.enableQuestFrameIcons; end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.enableQuestFrameIcons = value
                        end,
                    },
                    mapShowHideEnabled = {
                        type = "toggle",
                        order = 5.25,
                        name = function() return l10n("Show QuestieSmazak Map Button"); end,
                        desc = function() return l10n("Enable or disable the Show/Hide QuestieSmazak Button on Map (May fix some Map Addon interactions)."); end,
                        width = 1.55,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieOptions:SetProfileValue(info, value)

                            WorldMapButton.Toggle(value)
                        end,
                    },
                    minimapButtonEnabled = {
                        type = "toggle",
                        order = 5.3,
                        name = function() return l10n("Show Minimap Button"); end,
                        desc = function() return l10n("Enable or disable the QuestieSmazak minimap button. You can still access the options menu with /questie."); end,
                        width = 1.55,
                        get = function() return not QuestieSmazak.db.profile.minimap.hide; end,
                        set = function(_, value)
                            MinimapIcon.Toggle(value)
                        end,
                    },
                    compartmentButtonEnabled = {
                        type = "toggle",
                        order = 5.35,
                        name = function() return l10n("Show QuestieSmazak in addon compartment"); end,
                        desc = function() return l10n("Enable or disable the QuestieSmazak button in the addon compartment. You can still access the options menu with /questie."); end,
                        width = 1.55,
                        hidden = function() return _G.AddonCompartmentFrame == nil end,
                        get = function() return QuestieSmazak.db.profile.minimap.showInCompartment; end,
                        set = function(_, value)
                            MinimapIcon.ToggleCompartment(value)
                        end,
                    },
                    mapCoordinatesEnabled = {
                        type = "toggle",
                        order = 5.4,
                        name = function() return l10n("Show Map Coordinates"); end,
                        desc = function() return l10n("Place the Player's coordinates and Cursor's coordinates on the Map's title."); end,
                        width = 1.55,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieOptions:SetProfileValue(info, value)

                            if not value then
                                QuestieCoords.ResetMapText();
                                QuestieCoords:ResetMiniWorldMapText();
                            end
                        end,
                    },
                    minimapCoordinatesEnabled = {
                        type = "toggle",
                        order = 5.5,
                        name = function() return l10n("Show Minimap Coordinates"); end,
                        desc = function() return l10n("Place the Player's coordinates on the Minimap title."); end,
                        width = 1.55,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieOptions:SetProfileValue(info, value)

                            if not value then
                                QuestieCoords:ResetMinimapText();
                            end
                        end,
                    },
                    mapCoordinatePrecision = {
                        type = "range",
                        order = 5.6,
                        name = function() return l10n("Map Coordinates Decimal Precision"); end,
                        desc = function()
                            return l10n(
                                "How many decimals to include in the precision on the Map for Player and Cursor coordinates.\n(Default: %s)",
                                optionsDefaults.profile.mapCoordinatePrecision);
                        end,
                        width = 1.4,
                        min = 0,
                        max = 5,
                        step = 1,
                        disabled = function() return not QuestieSmazak.db.profile.mapCoordinatesEnabled end,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function(info, value)
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                },
            },
            level_spacer = QuestieOptionsUtils:Spacer(3.5, nil, "minimal"),
            level_options_group = {
                type = "group",
                order = 4,
                inline = true,
                name = function() return l10n("Quest Level Options"); end,
                args = {
                    level_text = {
                        type = "description",
                        order = 1,
                        name = function()
                            return QuestieSmazak:Colorize(
                                l10n("By default, QuestieSmazak only shows quests that are relevant for your level. You can change this behavior below."), "gray");
                        end,
                        fontSize = "small",
                    },
                    level_spacer = QuestieOptionsUtils:Spacer(2),
                    radio = {
                        order = 3.0,
                        type = "select",
                        style = "radio",
                        width = 3,
                        name = function() return l10n("Which available quests should be displayed") end,
                        values = function()
                            return {
                                [QuestieSmazak.LOWLEVEL_NONE] = l10n("Show only quests granting experience (Default)"),
                                [QuestieSmazak.LOWLEVEL_ALL] = l10n("Show all low level quests"),
                                [QuestieSmazak.LOWLEVEL_OFFSET] = l10n("Show quests to a set level below the player"),
                                [QuestieSmazak.LOWLEVEL_RANGE] = l10n("Show quests between two set levels"),
                            }
                        end,
                        get = function() return QuestieSmazak.db.profile.lowLevelStyle end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.lowLevelStyle = value
                            AvailableQuests.ResetLevelRequirementCache()
                            AvailableQuests.CalculateAndDrawAll()
                            QuestieSmazak.Debug(QuestieSmazak.DEBUG_DEVELOP, "Lowlevel Quests set to:", value)
                        end,
                    },
                    manualOffset = {
                        type = "range",
                        order = 3.1,
                        name = function() return l10n("Player level offset"); end,
                        desc = function()
                            return l10n("How many levels below your character to show. (Default: %s)", optionsDefaults.profile.manualLevelOffset);
                        end,
                        width = 1.063,
                        min = 0,
                        max = GetMaxPlayerLevel(),
                        step = 1,
                        disabled = function() return (QuestieSmazak.db.profile.lowLevelStyle ~= QuestieSmazak.LOWLEVEL_OFFSET) end,
                        get = function() return QuestieSmazak.db.profile.manualLevelOffset end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.manualLevelOffset = value;
                            QuestieOptionsUtils:Delay(0.3, function()
                                AvailableQuests.ResetLevelRequirementCache()
                                AvailableQuests.CalculateAndDrawAll()
                            end, "manualLevelOffset set to " .. value)
                        end,
                    },
                    minLevelFilter = {
                        type = "range",
                        order = 3.2,
                        name = function() return l10n("Level from"); end,
                        desc = function() return l10n("Minimum quest level to show."); end,
                        width = 1.063,
                        min = 1,
                        max = GetMaxPlayerLevel(),
                        step = 1,
                        disabled = function() return (QuestieSmazak.db.profile.lowLevelStyle ~= QuestieSmazak.LOWLEVEL_RANGE) end,
                        get = function() return QuestieSmazak.db.profile.minLevelFilter; end,
                        set = function(info, value)
                            if value > QuestieSmazak.db.profile.maxLevelFilter then
                                value = QuestieSmazak.db.profile.maxLevelFilter
                            end
                            QuestieSmazak.db.profile.minLevelFilter = value;
                            QuestieOptionsUtils:Delay(0.3, function()
                                AvailableQuests.ResetLevelRequirementCache()
                                AvailableQuests.CalculateAndDrawAll()
                            end, "minLevelFilter set to " .. value)
                        end,
                    },
                    maxLevelFilter = {
                        type = "range",
                        order = 3.3,
                        name = function()
                            return l10n("Level to");
                        end,
                        desc = function()
                            return l10n("Maximum quest level to show.");
                        end,
                        width = 1.063,
                        min = 1,
                        max = GetMaxPlayerLevel(),
                        step = 1,
                        disabled = function() return (QuestieSmazak.db.profile.lowLevelStyle ~= QuestieSmazak.LOWLEVEL_RANGE) end,
                        get = function(_) return QuestieSmazak.db.profile.maxLevelFilter; end,
                        set = function(_, value)
                            if value < QuestieSmazak.db.profile.minLevelFilter then
                                value = QuestieSmazak.db.profile.minLevelFilter
                            end
                            QuestieSmazak.db.profile.maxLevelFilter = value;
                            QuestieOptionsUtils:Delay(0.3, function()
                                AvailableQuests.ResetLevelRequirementCache()
                                AvailableQuests.CalculateAndDrawAll()
                            end, "maxLevelFilter set to " .. value)
                        end,
                    },
                },
            },
            tooltip_spacer = QuestieOptionsUtils:Spacer(4.5, nil, "minimal"),
            tooltip_options_group = {
                type = "group",
                order = 5,
                inline = true,
                name = function() return l10n("Tooltip Options"); end,
                args = {
                    enableTooltipsToggle = {
                        type = "toggle",
                        order = 8.1,
                        name = function() return l10n("Enable World Tooltips"); end,
                        desc = function() return l10n("If checked, quest info will be added to relevant mob/item tooltips."); end,
                        width = 1.5,
                        get = function() return QuestieSmazak.db.profile.enableTooltips; end,
                        set = function(_, value) QuestieSmazak.db.profile.enableTooltips = value end
                    },
                    questsInNpcTooltip = {
                        type = "toggle",
                        order = 8.2,
                        name = function() return l10n("Show quests in NPC tooltips"); end,
                        desc = function() return l10n("Show quests (available/complete) in the NPC tooltips."); end,
                        width = 1.5,
                        disabled = function() return not QuestieSmazak.db.profile.enableTooltips; end,
                        get = function() return QuestieSmazak.db.profile.showQuestsInNpcTooltip; end,
                        set = function(_, value) QuestieSmazak.db.profile.showQuestsInNpcTooltip = value end
                    },
                    showQuestLevels = {
                        type = "toggle",
                        order = 8.3,
                        name = function() return l10n("Show quest level in tooltips"); end,
                        desc = function() return l10n("If checked, the level of quests will show in the tooltips."); end,
                        width = 1.5,
                        get = function() return QuestieSmazak.db.profile.enableTooltipsQuestLevel; end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.enableTooltipsQuestLevel = value
                            if value and not QuestieSmazak.db.profile.trackerShowQuestLevel then
                                QuestieSmazak.db.profile.trackerShowQuestLevel = true
                                QuestieTracker:Update()
                            end
                        end
                    },
                    questXpAtMaxLevel = {
                        type = "toggle",
                        order = 8.4,
                        name = function() return l10n("Show quest XP at max level"); end,
                        desc = function() return l10n("Shows the quest XP values on quests even at max level."); end,
                        width = 1.5,
                        get = function() return QuestieSmazak.db.profile.showQuestXpAtMaxLevel; end,
                        set = function(_, value) QuestieSmazak.db.profile.showQuestXpAtMaxLevel = value end
                    },
                    showNextInChain = {
                        type = "toggle",
                        order = 8.5,
                        name = function() return l10n("Show next quests in chain"); end,
                        desc = function() return l10n("If checked, the next quests in the chain will show in the expanded map tooltips."); end,
                        width = 1.5,
                        get = function() return QuestieSmazak.db.profile.enableTooltipsNextInChain; end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.enableTooltipsNextInChain = value
                        end
                    },
                    showBreadcrumbQuests = {
                        type = "toggle",
                        order = 8.51,
                        name = function() return l10n("Show breadcrumb quests"); end,
                        desc = function() return l10n("If checked, breadcrumb quests will show in the expanded map tooltips."); end,
                        width = 1.5,
                        get = function() return QuestieSmazak.db.profile.enableTooltipsBreadcrumbQuests; end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.enableTooltipsBreadcrumbQuests = value
                        end
                    },
                    showDropRates = {
                        type = "toggle",
                        order = 8.6,
                        name = function() return l10n("Show item drop rates"); end,
                        desc = function() return l10n("If checked, drop rates for quest objectives will show on mob tooltips."); end,
                        width = 1.5,
                        get = function() return QuestieSmazak.db.profile.enableTooltipDroprates; end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.enableTooltipDroprates = value
                        end
                    },
                    partyOnlyToggle = {
                        type = "toggle",
                        order = 8.76,
                        name = function() return l10n("Only show party members"); end,
                        desc = function() return l10n("If checked, shared quest info will only show players in your party."); end,
                        width = 1.5,
                        hidden = true, -- does this even do anything anymore after YELL removed?
                        get = function() return QuestieSmazak.db.profile.onlyPartyShared; end,
                        set = function(_, value) QuestieSmazak.db.profile.onlyPartyShared = value end
                    },
                },
            },
            sound_spacer = QuestieOptionsUtils:Spacer(5.5, nil, "minimal"),
            sound_options_group = {
                type = "group",
                order = 6,
                inline = true,
                name = function() return l10n("Sound Options"); end,
                args = {
                    loadCustomSounds = {
                        type = "toggle",
                        order = 8.7,
                        name = function() return l10n("Load custom sounds"); end,
                        desc = function() return l10n("If checked, sounds added through LibSharedMedia are loaded."); end,
                        width = 2.5,
                        get = function() return QuestieSmazak.db.profile.loadCustomSounds; end,
                        set = function(_, value) QuestieSmazak.db.profile.loadCustomSounds = value end
                    },
                    soundChannel = {
                        type = "select",
                        order = 8.6,
                        values = function()
                            return {
                                Master = MASTER_VOLUME,
                                Music = MUSIC_VOLUME,
                                SFX = FX_VOLUME,
                                Ambience = AMBIENCE_VOLUME,
                                Dialog = DIALOG_VOLUME,
                            }
                        end,
                        sorting = {"Master", "Music", "SFX", "Ambience", "Dialog"},
                        style = "dropdown",
                        name = function() return l10n("Sound Channel") end,
                        desc = function() return l10n("The sound channel used for QuestieSmazak's notification sounds.") end,
                        get = function() return QuestieSmazak.db.profile.soundChannel or "Master" end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.soundChannel = value
                        end,
                    },
                    questCompleteSound = {
                        type = "toggle",
                        order = 9.01,
                        name = function() return l10n("Quest completed"); end,
                        desc = function() return l10n("Play a short sound when completing a quest when it is ready to turn in."); end,
                        width = 1.2,
                        get = function() return QuestieSmazak.db.profile.soundOnQuestComplete; end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.soundOnQuestComplete = value
                        end,
                    },
                    questCompleteSoundButton = {
                        type = "execute",
                        order = 9.02,
                        name = "",
                        width = 0.5,
                        image = function()
                            return "Interface\\OptionsFrame\\VoiceChat-Play", 15, 15
                        end,
                        func = function()
                            PlaySoundFile(Sounds.GetSelectedSoundFile(QuestieSmazak.db.profile.questCompleteSoundChoiceName), QuestieSmazak.db.profile.soundChannel)
                        end
                    },
                    questCompleteSoundChoice = {
                        type = "select",
                        order = 9.03,
                        values = _GetQuestSoundChoices,
                        sorting = _GetSortedOptions(_GetQuestSoundChoices),
                        style = "dropdown",
                        name = function() return l10n("Quest Complete Sound Selection") end,
                        desc = function() return l10n("The sound you hear when a quest is completed"); end,
                        get = function() return QuestieSmazak.db.profile.questCompleteSoundChoiceName or "None"; end,
                        disabled = function() return (not QuestieSmazak.db.profile.soundOnQuestComplete); end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.questCompleteSoundChoiceName = value
                        end,
                    },
                    soundLineBreak = {
                        type = "description",
                        name = " ",
                        width = 0.1,
                        order = 9.04,
                    },
                    objectiveCompleteSound = {
                        type = "toggle",
                        order = 9.05,
                        name = function() return l10n("Quest objective completed"); end,
                        desc = function() return l10n("Play a short sound when completing a quest objective."); end,
                        width = 1.2,
                        get = function() return QuestieSmazak.db.profile.soundOnObjectiveComplete; end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.soundOnObjectiveComplete = value
                        end,
                    },
                    objectiveCompleteSoundButton = {
                        type = "execute",
                        order = 9.06,
                        name = "",
                        width = 0.5,
                        image = function()
                            return "Interface\\OptionsFrame\\VoiceChat-Play", 15, 15
                        end,
                        func = function()
                            PlaySoundFile(Sounds.GetSelectedSoundFile(QuestieSmazak.db.profile.objectiveCompleteSoundChoiceName), QuestieSmazak.db.profile.soundChannel)
                        end
                    },
                    objectiveCompleteSoundChoice = {
                        type = "select",
                        order = 9.07,
                        values = _GetObjectiveSoundChoices,
                        sorting = _GetSortedOptions(_GetObjectiveSoundChoices),
                        style = "dropdown",
                        name = function() return l10n("Objective Complete Sound Selection") end,
                        desc = function() return l10n("The sound you hear when an objective is completed"); end,
                        get = function() return QuestieSmazak.db.profile.objectiveCompleteSoundChoiceName; end,
                        disabled = function() return (not QuestieSmazak.db.profile.soundOnObjectiveComplete); end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.objectiveCompleteSoundChoiceName = value
                        end,
                    },
                    objectiveProgressSound = {
                        type = "toggle",
                        order = 9.08,
                        name = function() return l10n("Quest objective progress"); end,
                        desc = function() return l10n("Play a short sound when making progress on a quest objective."); end,
                        width = 1.2,
                        get = function() return QuestieSmazak.db.profile.soundOnObjectiveProgress; end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.soundOnObjectiveProgress = value
                        end,
                    },
                    objectiveProgressSoundButton = {
                        type = "execute",
                        order = 9.09,
                        name = "",
                        width = 0.5,
                        image = function()
                            return "Interface\\OptionsFrame\\VoiceChat-Play", 15, 15
                        end,
                        func = function()
                            PlaySoundFile(Sounds.GetSelectedSoundFile(QuestieSmazak.db.profile.objectiveProgressSoundChoiceName), QuestieSmazak.db.profile.soundChannel)
                        end
                    },
                    objectiveProgressSoundChoice = {
                        type = "select",
                        order = 9.10,
                        values = _GetObjectiveProgressSoundChoices,
                        sorting = _GetSortedOptions(_GetObjectiveProgressSoundChoices),
                        style = "dropdown",
                        name = function() return l10n("Objective Progress Sound Selection") end,
                        desc = function() return l10n("The sound you hear when you make progress on a quest objective"); end,
                        get = function() return QuestieSmazak.db.profile.objectiveProgressSoundChoiceName; end,
                        disabled = function() return (not QuestieSmazak.db.profile.soundOnObjectiveProgress); end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.objectiveProgressSoundChoiceName = value
                        end,
                    },
                    soundDelay = {
                        type = "range",
                        order = 10.0,
                        name = function() return l10n("Progress Sound Delay"); end,
                        desc = function()
                            return l10n(
                                "Delay (in seconds, default: %s) for playing objective progress and completion sounds. Increase this if you hear double sounds.",
                                optionsDefaults.profile.soundDelay);
                        end,
                        width = 1.4,
                        min = 0.0,
                        max = 1.0,
                        step = 0.01,
                        get = function(info) return QuestieOptions:GetProfileValue(info); end,
                        set = function (info, value)
                            QuestieOptions:SetProfileValue(info, value)
                        end,
                    },
                },
            },
        },
    }
end

_GetAnnounceChannels = function()
    return {
        ["disabled"] = l10n("Disabled"),
        ["party"] = l10n("Party"),
        ["raid"] = l10n("Raid"),
        ["both"] = l10n("Both"),
    }
end

---@return boolean
_IsAnnounceDisabled = function()
    return (not QuestieSmazak.db.profile.questAnnounceChannel) or (QuestieSmazak.db.profile.questAnnounceChannel == "disabled")
end

_GetQuestSoundChoices = function()
    local options = {
        ["QuestDefault"]     = DEFAULT,
        ["GameDefault"]      = l10n("Game Default"),
        ["Troll Male"]       = l10n("Troll Male"),
        ["Troll Female"]     = l10n("Troll Female"),
        ["Tauren Male"]      = l10n("Tauren Male"),
        ["Tauren Female"]    = l10n("Tauren Female"),
        ["Undead Male"]      = l10n("Undead Male"),
        ["Undead Female"]    = l10n("Undead Female"),
        ["Orc Male"]         = l10n("Orc Male"),
        ["Orc Female"]       = l10n("Orc Female"),
        ["Night Elf Male"]   = l10n("Night Elf Male"),
        ["Night Elf Female"] = l10n("Night Elf Female"),
        ["Human Male"]       = l10n("Human Male"),
        ["Human Female"]     = l10n("Human Female"),
        ["Gnome Male"]       = l10n("Gnome Male"),
        ["Gnome Female"]     = l10n("Gnome Female"),
        ["Dwarf Male"]       = l10n("Dwarf Male"),
        ["Dwarf Female"]     = l10n("Dwarf Female"),
        ["Zug Zug"]          = l10n("Zug Zug"),
    }

    if Expansions.Current >= Expansions.Tbc or QuestieSmazak.IsForever then
        options["Draenei Male"]     = l10n("Draenei Male")
        options["Draenei Female"]   = l10n("Draenei Female")
        options["Blood Elf Male"]   = l10n("Blood Elf Male")
        options["Blood Elf Female"] = l10n("Blood Elf Female")
    end

    if Expansions.Current >= Expansions.Cata or QuestieSmazak.IsForever then
        options["Goblin Male"]    = l10n("Goblin Male")
        options["Goblin Female"]  = l10n("Goblin Female")
        options["Worgen Male"]    = l10n("Worgen Male")
        options["Worgen Female"]  = l10n("Worgen Female")
        options["Gilnean Male"]   = l10n("Gilnean Male")
        options["Gilnean Female"] = l10n("Gilnean Female")
    end

    if Expansions.Current >= Expansions.MoP or QuestieSmazak.IsForever then
        options["Pandaren Male"]    = l10n("Pandaren Male")
        options["Pandaren Female"]  = l10n("Pandaren Female")
    end

    if QuestieSmazak.db.profile.loadCustomSounds then
        for _, sound in pairs(LSM30:List(LSM30.MediaType.SOUND)) do
            options[sound] = sound
        end
    end

    return options
end

_GetObjectiveSoundChoices = function()
    local options = {
        ["ObjectiveDefault"]   = DEFAULT,
        ["Map Ping"]           = l10n("Map Ping"),
        ["Window Close"]       = l10n("Window Close"),
        ["Window Open"]        = l10n("Window Open"),
        ["Boat Docked"]        = l10n("Boat Docked"),
        ["Bell Toll Alliance"] = l10n("Bell Toll Alliance"),
        ["Bell Toll Horde"]    = l10n("Bell Toll Horde"),
    }
    if Expansions.Current >= Expansions.Tbc or QuestieSmazak.IsForever then
        options["Explosion"] = l10n("Explosion")
        options["Shing!"] = l10n("Shing!")
        options["Wham!"] = l10n("Wham!")
        options["Simon Chime"] = l10n("Simon Chime")
        options["War Drums"] = l10n("War Drums")
        options["Humm"] = l10n("Humm")
        options["Short Circuit"] = l10n("Short Circuit")
    end

    if QuestieSmazak.db.profile.loadCustomSounds then
        for _, sound in pairs(LSM30:List(LSM30.MediaType.SOUND)) do
            options[sound] = sound
        end
    end

    return options
end

_GetObjectiveProgressSoundChoices = function()
    local options = {
        ["ObjectiveProgress"]  = DEFAULT,
        ["ObjectiveDefault"]   = l10n("Objective Complete"),
        ["Map Ping"]           = l10n("Map Ping"),
        ["Window Close"]       = l10n("Window Close"),
        ["Window Open"]        = l10n("Window Open"),
        ["Boat Docked"]        = l10n("Boat Docked"),
        ["Bell Toll Alliance"] = l10n("Bell Toll Alliance"),
        ["Bell Toll Horde"]    = l10n("Bell Toll Horde"),
    }
    if Expansions.Current >= Expansions.Tbc or QuestieSmazak.IsForever then
        options["Explosion"] = l10n("Explosion")
        options["Shing!"] = l10n("Shing!")
        options["Wham!"] = l10n("Wham!")
        options["Simon Chime"] = l10n("Simon Chime")
        options["War Drums"] = l10n("War Drums")
        options["Humm"] = l10n("Humm")
        options["Short Circuit"] = l10n("Short Circuit")
    end

    if QuestieSmazak.db.profile.loadCustomSounds then
        for _, sound in pairs(LSM30:List(LSM30.MediaType.SOUND)) do
            options[sound] = sound
        end
    end

    return options
end

---Sorts options alphabetically, ignoring case.
---We return a function to allow ace to refetch the options.
---@param getOptions function
---@return function
_GetSortedOptions = function(getOptions)
    return function()
        local sorting = {}
        for key, value in pairs(getOptions()) do
            tinsert(sorting, {key = key, value = value})
        end
        tableSort(sorting, function(a, b)
            return stringLower(a.value) < stringLower(b.value)
        end)
        local sortedKeys = {}
        for _, pair in ipairs(sorting) do
            tinsert(sortedKeys, pair.key)
        end
        return sortedKeys
    end
end
