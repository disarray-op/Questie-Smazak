---@type QuestieCompat
local QuestieCompat = QuestieSmazakLoader:ImportModule("QuestieCompat")

-------------------------
--Import modules.
-------------------------
---@type QuestieOptions
local QuestieOptions = QuestieSmazakLoader:ImportModule("QuestieOptions")
---@type QuestieOptionsUtils
local QuestieOptionsUtils = QuestieSmazakLoader:ImportModule("QuestieOptionsUtils")
---@type QuestieTracker
local QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker")
---@type TrackerBaseFrame
local TrackerBaseFrame = QuestieSmazakLoader:ImportModule("TrackerBaseFrame")
---@type TrackerLinePool
local TrackerLinePool = QuestieSmazakLoader:ImportModule("TrackerLinePool")
---@type TrackerUtils
local TrackerUtils = QuestieSmazakLoader:ImportModule("TrackerUtils")
---@type Expansions
local Expansions = QuestieSmazakLoader:ImportModule("Expansions")
---@type CommsVisibility
local CommsVisibility = QuestieSmazakLoader:ImportModule("CommsVisibility")

---@type l10n
local l10n = QuestieSmazakLoader:ImportModule("l10n")

QuestieOptions.tabs.tracker = { ... }

local _GetShortcuts
local trackerOptions = {}

local SharedMedia = LibStub("LibSharedMedia-3.0")
local IsAddOnLoaded = QuestieCompat.IsAddOnLoaded

---Toggle tracker visibility based on a condition
---@param shouldHide boolean Whether to hide (true) or show (false) the tracker
---@param conditionFn fun(): boolean Function that returns true if the condition is met
local function toggleTrackerVisibility(shouldHide, conditionFn)
    local baseFrame = TrackerBaseFrame.baseFrame
    if baseFrame and conditionFn() then
        if shouldHide then
            QuestieTracker:Hide()
        else
            QuestieTracker:Show()
        end
    end
end

local function startFadeTicker()
    local fadeTicker
    local fadeTickerValue = 1

    fadeTicker = C_Timer.NewTicker(0.02, function()
        if fadeTickerValue <= 1 then
            fadeTickerValue = fadeTickerValue - 0.05

            if fadeTickerValue < 0 then
                fadeTickerValue = 0
                fadeTicker:Cancel()
            end

            if QuestieSmazak.db.char.isTrackerExpanded then
                local c = QuestieSmazak.db.profile.trackerBackdropColor
                TrackerBaseFrame.baseFrame:SetBackdropColor(c.r, c.g, c.b, fadeTickerValue)

                if QuestieSmazak.db.profile.trackerBorderEnabled then
                    TrackerBaseFrame.baseFrame:SetBackdropBorderColor(1, 1, 1, fadeTickerValue)
                end
            end
        end
    end)
end

local debounceTimer

local function debounceFadeTicker()
    if debounceTimer then
        debounceTimer:Cancel()
    end

    debounceTimer = C_Timer.NewTimer(1, function()
        startFadeTicker()
    end)
end

function QuestieOptions.tabs.tracker:Initialize()
    trackerOptions = {
        name = function() return l10n("Tracker") end,
        type = "group",
        order = 3,
        args = {
            header = {
                type = "header",
                order = 1,
                name = function() return l10n("Tracker Options") end,
            },
            enableQuestieTracker = {
                type = "toggle",
                order = 2,
                width = 1.5,
                name = function() return l10n("Enable Tracker") end,
                desc = function() return l10n("Enabling the Tracker will replace the default Blizzard Quest Tracker with the QuestieSmazak Tracker.\n\nNOTE: Changing this setting will reload the UI.") end,
                disabled = function() return InCombatLockdown() end,
                get = function() return QuestieSmazak.db.profile.trackerEnabled end,
                set = function()
                    if QuestieSmazak.db.profile.trackerEnabled then
                        QuestieTracker:Disable()
                    else
                        QuestieTracker:Enable()
                    end
                end
            },
            Space_X = QuestieOptionsUtils:HorizontalSpacer(3, 0.1),
            resetTrackerLocation = {
                type = "execute",
                order = 4,
                width = 0.8,
                name = function() return l10n("Reset Tracker") end,
                desc = function() return l10n("If the QuestieSmazak Tracker is stuck offscreen or lost, you can reset it's location to the center of the screen with this button.") end,
                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled or InCombatLockdown() end,
                func = function()
                    QuestieTracker:ResetLocation()
                    QuestieTracker:Update()
                end
            },
            Spacer_S = QuestieOptionsUtils:Spacer(5),
            group_quests = {
                type = "group",
                order = 6,
                inline = true,
                width = 0.5,
                name = function()
                    if Expansions.Current >= Expansions.Wotlk then
                        return l10n("Quest and Achievement Options")
                    else
                        return l10n("Quest Options")
                    end
                end,
                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                args = {
                    autoTrackQuests = {
                        type = "toggle",
                        order = 1,
                        width = 1.5,
                        name = function() return l10n("Auto Track Quests") end,
                        desc = function() return l10n("This is the same as \"Enable Automatic Quest Tracking\" in the Blizzard Interface Options. If checked, the QuestieSmazak Tracker will automatically track all Quests in your Quest Log. Disabling this option will untrack all Quests. You will have to manually select which Quests to track.\n\nNOTE: \"Show Complete Quests\" is disabled while this option is not being used.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.autoTrackQuests end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.autoTrackQuests = value
                            if value then
                                QuestieSmazak.db.char.TrackedQuests = {}
                            else
                                QuestieSmazak.db.char.AutoUntrackedQuests = {}
                            end
                            -- Switching modes rewrites the meaning of tracked/untracked for every
                            -- quest, so send one full QuestieV1 visibility snapshot.
                            CommsVisibility:ScheduleSnapshot("AUTO_TRACK_QUESTS")

                            -- Update Quest Log and mark tracked Quests
                            local questLogFrame = QuestLogExFrame or ClassicQuestLog or QuestLogFrame
                            if questLogFrame and questLogFrame:IsShown() then
                                QuestieCompat.QuestLog_Update()
                            end

                            QuestieTracker:Update()
                        end
                    },
                    showQuestLevels = {
                        type = "toggle",
                        order = 2,
                        width = 1.5,
                        name = function() return l10n("Show Quest Level") end,
                        desc = function() return l10n("If checked, the Quest Level Tags for Quest Titles will show in the QuestieSmazak Tracker.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerShowQuestLevel end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerShowQuestLevel = value
                            QuestieTracker:Update()
                        end
                    },
                    followSuperTracking = {
                        type = "toggle",
                        order = 3.1,
                        width = 1.5,
                        name = function() return l10n("Follow Blizzard Super Tracking") end,
                        desc = function() return l10n("If checked, the Quest Focus follows the quest that is super tracked by Blizzard, e.g. when accepting a quest or clicking it on the map.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        hidden = function() return not QuestieCompat.IsSuperTrackingSupported() end,
                        get = function() return QuestieSmazak.db.profile.trackerFollowSuperTracking end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerFollowSuperTracking = value
                        end
                    },
                    listAchievementsFirst = {
                        type = "toggle",
                        order = 4,
                        width = 1.5,
                        name = function() return l10n("List Achievements First") end,
                        desc = function() return l10n("If checked, the QuestieSmazak Tracker will list Achievements first then Quests.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        hidden = function() return Expansions.Current < Expansions.Wotlk end,
                        get = function() return QuestieSmazak.db.profile.listAchievementsFirst end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.listAchievementsFirst = value
                            QuestieTracker:Update()
                        end
                    },
                    Spacer_Dropdowns = QuestieOptionsUtils:Spacer(5),
                    openQuestLog = {
                        type = "select",
                        order = 7,
                        values = _GetShortcuts,
                        style = "dropdown",
                        name = function()
                            if Expansions.Current >= Expansions.Wotlk then
                                return l10n("Show Quest / Achievement")
                            else
                                return l10n("Show in Quest Log")
                            end
                        end,
                        desc = function()
                            if Expansions.Current >= Expansions.Wotlk then
                                return l10n("This shortcut will open the Quest Log with the clicked Quest selected or open Achievements with the clicked Achievement selected.")
                            else
                                return l10n("This shortcut will open the Quest Log with the clicked Quest selected.")
                            end
                        end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerbindOpenQuestLog end,
                        set = function(_, key)
                            QuestieSmazak.db.profile.trackerbindOpenQuestLog = key
                        end
                    },
                    Space_Y = QuestieOptionsUtils:HorizontalSpacer(7.1, 0.1),
                    untrackQuest = {
                        type = "select",
                        order = 8,
                        values = _GetShortcuts,
                        style = "dropdown",
                        name = function()
                            if Expansions.Current >= Expansions.Wotlk then
                                return l10n("Untrack / Link")
                            else
                                return l10n("Untrack / Link Quest")
                            end
                        end,
                        desc = function()
                            if Expansions.Current >= Expansions.Wotlk then
                                return l10n("This shortcut removes a Quest or an Achievement from the QuestieSmazak Tracker when the chat input box is NOT visible, otherwise this will link a Quest or an Achievement to chat.")
                            else
                                return l10n("This shortcut removes a Quest from the QuestieSmazak Tracker when the chat input box is NOT visible, otherwise this will link a Quest to chat.")
                            end
                        end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerbindUntrack end,
                        set = function(_, key)
                            QuestieSmazak.db.profile.trackerbindUntrack = key
                        end
                    },
                    Spacer_Sliders = QuestieOptionsUtils:Spacer(9),
                    questPadding = {
                        type = "range",
                        order = 10,
                        name = function() return l10n("Padding Between Quests") end,
                        desc = function() return l10n("The amount of padding between Quests in the QuestieSmazak Tracker.\n\nNOTE: Changing this setting while in Sizer Manual Mode will reset the Sizer back to Auto Mode") end,
                        width = 3,
                        min = 2,
                        max = 15,
                        step = 1,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerQuestPadding end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerQuestPadding = value
                            local trackerHeightByManual = QuestieSmazak.db.profile.TrackerHeight
                            if IsMouseButtonDown("LeftButton") and trackerHeightByManual == 0 then
                                QuestieTracker:Update()
                            elseif IsMouseButtonDown("LeftButton") and trackerHeightByManual > 0 then
                                QuestieSmazak.db.profile.TrackerWidth = 0
                                QuestieSmazak.db.profile.TrackerHeight = 0
                                QuestieTracker:Update()
                            end
                        end
                    },
                    group_tracker = {
                        type = "group",
                        order = 11,
                        inline = true,
                        width = 0.5,
                        name = function() return l10n("Objectives"); end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        args = {
                            showCompleteQuests = {
                                type = "toggle",
                                order = 1,
                                width = 1.5,
                                name = function() return l10n("Show Completed Quests") end,
                                desc = function() return l10n("If checked, completed Quests will show in the QuestieSmazak Tracker.\n\nNOTE: This setting only works when \"Auto Track Quests\" is enabled.") end,
                                disabled = function() return (not QuestieSmazak.db.profile.trackerEnabled) or (not QuestieSmazak.db.profile.autoTrackQuests) end,
                                get = function() return QuestieSmazak.db.profile.trackerShowCompleteQuests end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.trackerShowCompleteQuests = value
                                    QuestieTracker:Update()
                                end
                            },
                            collapseCompletedQuests = {
                                type = "toggle",
                                order = 2,
                                width = 1.5,
                                name = function() return l10n("Auto Minimize Completed Quests") end,
                                desc = function() return l10n("If checked, completed Quests will automatically minimize.") end,
                                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                                get = function() return QuestieSmazak.db.profile.collapseCompletedQuests end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.collapseCompletedQuests = value
                                    if QuestieSmazak.db.profile.collapseCompletedQuests == false then
                                        QuestieSmazak.db.char.collapsedQuests = {}
                                    end
                                    QuestieTracker:Update()
                                end
                            },
                            hideCompletedQuestObjectives = {
                                type = "toggle",
                                order = 3,
                                width = 1.5,
                                name = function() return l10n("Hide Completed Quest Objectives") end,
                                desc = function() return l10n("If checked, completed Quest Objectives will automatically be removed from the QuestieSmazak Tracker.") end,
                                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                                get = function() return QuestieSmazak.db.profile.hideCompletedQuestObjectives end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.hideCompletedQuestObjectives = value
                                    QuestieTracker:Update()
                                end
                            },
                            hideCompletedAchieveObjectives = {
                                type = "toggle",
                                order = 4,
                                width = 1.5,
                                name = function() return l10n("Hide Completed Achieve Objectives") end,
                                desc = function() return l10n("If checked, completed Achievement Objectives will automatically be removed from the QuestieSmazak Tracker.") end,
                                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                                hidden = function() return Expansions.Current < Expansions.Wotlk end,
                                get = function() return QuestieSmazak.db.profile.hideCompletedAchieveObjectives end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.hideCompletedAchieveObjectives = value
                                    QuestieTracker:Update()
                                end
                            },
                            Spacer_X = QuestieOptionsUtils:Spacer(5),
                            colorObjectives = {
                                type = "select",
                                order = 6,
                                values = function()
                                    return {
                                        ["white"] = l10n("White"),
                                        ["whiteToGreen"] = l10n("White to Green"),
                                        ["whiteAndGreen"] = l10n("White and Green"),
                                        ["redToGreen"] = l10n("Red to Green"),
                                        ["minimal"] = l10n("Minimalistic")
                                    }
                                end,
                                style = "dropdown",
                                name = function() return l10n("Objective Color") end,
                                desc = function() return l10n("Change the color of Objectives in the QuestieSmazak Tracker by how complete they are.\n\nNOTE: The Minimalistic option will not display the \"Blizzard Completion Text\" and just label the Quest as either \"Quest Complete!\" or \"Quest Failed!\".") end,
                                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                                get = function() return QuestieSmazak.db.profile.trackerColorObjectives end,
                                set = function(_, key)
                                    QuestieSmazak.db.profile.trackerColorObjectives = key
                                    QuestieTracker:Update()
                                end
                            },
                            Space_Y = QuestieOptionsUtils:HorizontalSpacer(7, 0.1),
                            hideBlizzardCompletionText = {
                                type = "toggle",
                                order = 8,
                                width = 1.5,
                                name = function() return l10n("Hide Blizzard Completion Text") end,
                                desc = function() return l10n("If checked, Blizzard Completion Text will be hidden for completed Quests and instead show the old QuestieSmazak tags: \"Quest Complete!\" or \"Quest Failed!\"") end,
                                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled or QuestieSmazak.db.profile.trackerColorObjectives == "minimal" end,
                                get = function() return QuestieSmazak.db.profile.hideBlizzardCompletionText end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.hideBlizzardCompletionText = value
                                    if QuestieSmazak.db.profile.hideBlizzardCompletionText == false then
                                        QuestieSmazak.db.char.collapsedQuests = {}
                                    end
                                    QuestieTracker:Update()
                                end
                            },
                            Spacer_Z = QuestieOptionsUtils:Spacer(9),
                            sortObjectives = {
                                type = "select",
                                order = 10,
                                values = function()
                                    return {
                                        ["byComplete"] = l10n("By %% Complete"),
                                        ["byCompleteReversed"] = l10n("By %% Complete (Reversed)"),
                                        ["byLevel"] = l10n("By Level"),
                                        ["byLevelReversed"] = l10n("By Level (Reversed)"),
                                        ["byProximity"] = l10n("By Proximity"),
                                        ["byProximityReversed"] = l10n("By Proximity (Reversed)"),
                                        ["byZone"] = l10n("By Zone"),
                                        ["byZonePlayerProximity"] = l10n("By Zone Prox"),
                                        ["byZonePlayerProximityReversed"] = l10n("By Zone Prox (Reversed)"),
                                    }
                                end,
                                style = "dropdown",
                                name = function() return l10n("Objective Sorting") end,
                                desc = function() return l10n("How Objectives are sorted in the QuestieSmazak Tracker.") end,
                                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                                get = function() return QuestieSmazak.db.profile.trackerSortObjectives end,
                                set = function(_, key)
                                    QuestieSmazak.db.profile.trackerSortObjectives = key
                                    QuestieTracker:Update()
                                end
                            },
                        },
                    },
                }
            },
            group_tracker = {
                type = "group",
                order = 7,
                inline = true,
                width = 0.5,
                name = function() return l10n("Tracker Window Options"); end,
                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                args = {
                    minimizeInCombat = {
                        type = "toggle",
                        order = 1,
                        width = 1.5,
                        name = function() return l10n("Minimize In Combat") end,
                        desc = function() return l10n("If checked, the QuestieSmazak Tracker will automatically be minimized while entering combat.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.minimizeTrackerInCombat end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.minimizeTrackerInCombat = value
                            -- Disable the hide option when minimize is enabled
                            if value then
                                QuestieSmazak.db.profile.hideTrackerInCombat = false
                                QuestieTracker.OnHideInCombatChanged(false)
                            end
                            QuestieTracker.OnMinimizeInCombatChanged(value)
                        end
                    },
                    minimizeInInstances = {
                        type = "toggle",
                        order = 2,
                        width = 1.5,
                        name = function() return l10n("Minimize In Instances") end,
                        desc = function() return l10n("If checked, the QuestieSmazak Tracker will automatically be minimized when entering a dungeon, raid, or battleground.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.minimizeTrackerInInstances end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.minimizeTrackerInInstances = value
                            -- Disable the hide option when minimize is enabled
                            if value then
                                QuestieSmazak.db.profile.hideTrackerInInstances = false
                                QuestieTracker.OnHideInInstancesChanged(false)
                            end
                            QuestieTracker.OnMinimizeInInstancesChanged(value)
                        end
                    },
                    hideInCombat = {
                        type = "toggle",
                        order = 3,
                        width = 1.5,
                        name = function() return l10n("Hide In Combat") end,
                        desc = function() return l10n("If checked, the QuestieSmazak Tracker will automatically be hidden when entering combat.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.hideTrackerInCombat end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.hideTrackerInCombat = value
                            if value then
                                QuestieSmazak.db.profile.minimizeTrackerInCombat = false
                                QuestieTracker.OnMinimizeInCombatChanged(false)
                            end
                            QuestieTracker.OnHideInCombatChanged(value)
                        end
                    },
                    hideInInstances = {
                        type = "toggle",
                        order = 4,
                        width = 1.5,
                        name = function() return l10n("Hide In Instances") end,
                        desc = function() return l10n("If checked, the QuestieSmazak Tracker will automatically be hidden when entering a dungeon, raid, or battleground.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.hideTrackerInInstances end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.hideTrackerInInstances = value
                            if value then
                                QuestieSmazak.db.profile.minimizeTrackerInInstances = false
                                QuestieTracker.OnMinimizeInInstancesChanged(false)
                            end
                            QuestieTracker.OnHideInInstancesChanged(value)
                        end
                    },
                    hideInPetBattles = {
                        type = "toggle",
                        order = 5,
                        width = 1.5,
                        name = function() return l10n("Hide In Pet Battles") end,
                        desc = function() return l10n("If checked, the QuestieSmazak Tracker will automatically be hidden when entering a pet battle.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        hidden = function() return Expansions.Current < Expansions.MoP end,
                        get = function() return QuestieSmazak.db.profile.hideTrackerInPetBattles end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.hideTrackerInPetBattles = value
                            toggleTrackerVisibility(value, function()
                                return (C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle()) or false
                            end)
                        end
                    },
                    fadeMinMaxButtons = {
                        type = "toggle",
                        order = 6,
                        width = 1.5,
                        name = function() return l10n("Fade Min/Max Buttons") end,
                        desc = function() return l10n("If checked, the Minimize and Maximize Buttons will fade and become transparent when not in use.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerFadeMinMaxButtons end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerFadeMinMaxButtons = value
                            if value == true then
                                local fadeTicker
                                local fadeTickerValue = 1
                                fadeTicker = C_Timer.NewTicker(0.02, function()
                                    if fadeTickerValue <= 1 then
                                        fadeTickerValue = fadeTickerValue - 0.05

                                        if fadeTickerValue < 0 then
                                            fadeTickerValue = 0
                                            fadeTicker:Cancel()
                                        end

                                        if (QuestieSmazak.db.char.isTrackerExpanded) then
                                            TrackerLinePool.SetAllExpandQuestAlpha(fadeTickerValue)
                                        end
                                    else
                                        fadeTickerValue:Cancel()
                                        TrackerLinePool.SetAllExpandQuestAlpha(0)
                                    end
                                end)
                            else
                                TrackerLinePool.SetAllExpandQuestAlpha(1)
                            end
                            QuestieTracker:Update()
                        end
                    },
                    fadeQuestItemButtons = {
                        type = "toggle",
                        order = 7,
                        width = 1.5,
                        name = function() return l10n("Fade Quest Item Buttons") end,
                        desc = function() return l10n("If checked, the Quest Item Buttons will fade and become transparent when not in use.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerFadeQuestItemButtons end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerFadeQuestItemButtons = value
                            if value == true then
                                local fadeTicker
                                local fadeTickerValue = 1
                                fadeTicker = C_Timer.NewTicker(0.02, function()
                                    if fadeTickerValue <= 1 then
                                        fadeTickerValue = fadeTickerValue - 0.05

                                        if fadeTickerValue < 0 then
                                            fadeTickerValue = 0
                                            fadeTicker:Cancel()
                                        end

                                        if (QuestieSmazak.db.char.isTrackerExpanded) then
                                            TrackerLinePool.SetAllItemButtonAlpha(fadeTickerValue)
                                        end
                                    else
                                        fadeTickerValue:Cancel()
                                        TrackerLinePool.SetAllItemButtonAlpha(0)
                                    end
                                end)
                            else
                                TrackerLinePool.SetAllItemButtonAlpha(1)
                            end
                            QuestieTracker:Update()
                        end
                    },
                    showQuestFocusButtons = {
                        type = "toggle",
                        order = 7.1,
                        width = 1.5,
                        name = function() return l10n("Show Quest Focus Buttons") end,
                        desc = function() return l10n("If checked, a round button in front of each Quest lets you focus or unfocus the Quest on the map.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerShowQuestFocusButtons end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerShowQuestFocusButtons = value
                            QuestieTracker:Update()
                        end
                    },
                    showQuestGiverOnFocus = {
                        type = "toggle",
                        order = 7.25,
                        width = 1.5,
                        name = function() return l10n("Show Quest Giver On Focus") end,
                        desc = function() return l10n("If checked, focusing a Quest also shows the Quest Giver it was picked up from on the map.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerShowQuestGiverOnFocus end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerShowQuestGiverOnFocus = value
                        end
                    },
                    showPlayButtons = {
                        type = "toggle",
                        order = 7.3,
                        width = 1.5,
                        name = function() return l10n("Show Play Buttons") end,
                        desc = function() return l10n("If checked, a button in front of each Quest plays its voice-over from VoiceOver or Spoken.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        hidden = function() return not (TrackerUtils:IsVoiceOverLoaded() or TrackerUtils:IsSpokenLoaded()) end,
                        get = function() return QuestieSmazak.db.profile.trackerShowPlayButtons end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerShowPlayButtons = value
                            QuestieTracker:Update()
                        end
                    },
                    fadeQuestFocusButtons = {
                        type = "toggle",
                        order = 7.2,
                        width = 1.5,
                        name = function() return l10n("Fade Quest Focus Buttons") end,
                        desc = function() return l10n("If checked, the Quest Focus Buttons will fade and become transparent when not in use.") end,
                        disabled = function() return (not QuestieSmazak.db.profile.trackerEnabled) or (not QuestieSmazak.db.profile.trackerShowQuestFocusButtons) end,
                        get = function() return QuestieSmazak.db.profile.trackerFadeQuestFocusButtons end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerFadeQuestFocusButtons = value
                            TrackerLinePool.SetAllQuestFocusAlpha(value and 0 or 1)
                            QuestieTracker:Update()
                        end
                    },
                    disableHoverFade = {
                        type = "toggle",
                        order = 8,
                        width = 1.5,
                        name = function() return l10n("Disable Quest Hover Fade") end,
                        desc = function() return l10n("If checked, the other quests in the tracker will stay fully opaque while hovering a quest.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerDisableHoverFade end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerDisableHoverFade = value
                        end
                    },
                    hideSizer = {
                        type = "toggle",
                        order = 9,
                        width = 1.5,
                        name = function() return l10n("Hide Tracker Sizer") end,
                        desc = function() return l10n("If checked, the QuestieSmazak Tracker Sizer that appears in the bottom or top right hand corner will be hidden.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.sizerHidden end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.sizerHidden = value
                            QuestieTracker:UpdateFormatting()
                        end
                    },
                    lockTracker = {
                        type = "toggle",
                        order = 10,
                        width = 1.5,
                        name = function() return l10n("Lock Tracker") end,
                        desc = function() return l10n("If checked, the QuestieSmazak Tracker is locked and you need to hold CTRL when you want to move it.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerLocked end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerLocked = value
                            TrackerBaseFrame:Update()
                        end
                    },
                    stickyDurabilityFrame = {
                        type = "toggle",
                        order = 11,
                        width = 1.5,
                        name = function() return l10n("Sticky Durability Frame") end,
                        desc = function() return l10n("If checked, the durability frame will be placed on the left or right side of the QuestieSmazak Tracker depending on where the Tracker is placed on your screen.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.stickyDurabilityFrame end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.stickyDurabilityFrame = value
                            if value == false then
                                QuestieTracker:ResetDurabilityFrame()
                            end
                            QuestieTracker:Update()
                        end
                    },
                    stickyVoiceOverFrame = {
                        type = "toggle",
                        order = 12,
                        width = 1.5,
                        name = function() return l10n("Sticky VoiceOver Frame") end,
                        desc = function() return l10n("If checked, the VoiceOver talking head / sound queue frame will be placed on the left or right side of the QuestieSmazak Tracker depending on where the Tracker is placed on your screen.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        hidden = function() return not TrackerUtils:IsVoiceOverLoaded() end,
                        get = function() return QuestieSmazak.db.profile.stickyVoiceOverFrame end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.stickyVoiceOverFrame = value
                            if value == false then
                                QuestieTracker:ResetVoiceOverFrame()
                            end
                            QuestieTracker:Update()
                        end
                    },
                    Spacer_Dropdowns = QuestieOptionsUtils:Spacer(9),
                    setTomTom = {
                        type = "select",
                        order = 13,
                        values = _GetShortcuts,
                        style = "dropdown",
                        name = function() return l10n("Set |cFF54e33bTomTom|r Target") end,
                        desc = function()
                            if Expansions.Current >= Expansions.Wotlk then
                                return l10n("This shortcut will set the TomTom arrow to point to either an NPC or the first incomplete Quest Objective (if location data is available).\n\nNOTE: This will not work with Achievements.")
                            else
                                return l10n("This shortcut will set the TomTom arrow to point to either an NPC or the first incomplete Quest Objective (if location data is available).")
                            end
                        end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        hidden = function() return not IsAddOnLoaded("TomTom") end,
                        get = function() return QuestieSmazak.db.profile.trackerbindSetTomTom end,
                        set = function(_, key)
                            QuestieSmazak.db.profile.trackerbindSetTomTom = key
                        end
                    },
                    trackerSetpoint = {
                        type = "select",
                        order = 14,
                        values = function()
                            return {
                                ["TOPLEFT"] = l10n("Down & Right"),
                                ["BOTTOMLEFT"] = l10n("Up & Right"),
                                ["TOPRIGHT"] = l10n("Down & Left"),
                                ["BOTTOMRIGHT"] = l10n("Up & Left"),
                            }
                        end,
                        style = "dropdown",
                        name = function() return l10n("Tracker Growth Direction") end,
                        desc = function()
                            return l10n("This determines the direction in which the QuestieSmazak Tracker grows when you add or remove Quests. For example, if you use the \"Up & Right\" option then the ideal place for the Tracker should be in the lower left-hand corner of your screen. This allows the \"Sizer Mode: Auto\" to push the Tracker Height and Width \"Up & Right\" so the Tracker doesn't inadvertently cover up elements of your UI.")
                        end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerSetpoint end,
                        set = function(_, key)
                            QuestieSmazak.db.profile.trackerSetpoint = key
                            QuestieTracker:ResetLocation()
                            QuestieTracker:Update()
                        end
                    },
                    Spacer_Sliders = QuestieOptionsUtils:Spacer(12),
                    trackerHeightRatio = {
                        type = "range",
                        order = 15,
                        name = function() return l10n("Tracker Height Ratio") end,
                        desc = function() return l10n("The height of the QuestieSmazak Tracker based on percentage of usable screen height. A setting of 100 percent would make the Tracker fill the players entire screen height.\n\nNOTE: This setting only applies while in Sizer Mode: Auto") end,
                        width = 3,
                        min = 20,
                        max = 100,
                        step = 1,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerHeightRatio * 100 end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerHeightRatio = value / 100
                            if IsMouseButtonDown("LeftButton") and QuestieSmazak.db.profile.TrackerHeight == 0 then
                                TrackerBaseFrame.isSizing = true
                                QuestieSmazak.db.profile.trackerBackdropEnabled = true
                                QuestieSmazak.db.profile.trackerBorderEnabled = true
                                QuestieSmazak.db.profile.trackerBackdropFader = false
                                QuestieTracker:UpdateFormatting()
                            else
                                TrackerBaseFrame.isSizing = false
                                QuestieSmazak.db.profile.trackerBackdropEnabled = QuestieSmazak.db.profile.currentBackdropEnabled
                                QuestieSmazak.db.profile.trackerBorderEnabled = QuestieSmazak.db.profile.currentBorderEnabled
                                QuestieSmazak.db.profile.trackerBackdropFader = QuestieSmazak.db.profile.currentBackdropFader
                                QuestieTracker:UpdateFormatting()
                            end
                        end
                    },
                    trackerWidthRatio = {
                        type = "range",
                        order = 15.1,
                        name = function() return l10n("Tracker Width Ratio") end,
                        desc = function() return l10n("The width of the QuestieSmazak Tracker based on percentage of usable screen width. A setting of 100 percent would make the Tracker fill the players entire screen width.\n\nNOTE: This setting only applies while in Sizer Mode: Auto") end,
                        width = 3,
                        min = 15,
                        max = 100,
                        step = 1,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerWidthRatio * 100 end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerWidthRatio = value / 100
                            if IsMouseButtonDown("LeftButton") and QuestieSmazak.db.profile.TrackerWidth == 0 then
                                TrackerBaseFrame.isSizing = true
                                QuestieSmazak.db.profile.trackerBackdropEnabled = true
                                QuestieSmazak.db.profile.trackerBorderEnabled = true
                                QuestieSmazak.db.profile.trackerBackdropFader = false
                                QuestieTracker:UpdateFormatting()
                            else
                                TrackerBaseFrame.isSizing = false
                                QuestieSmazak.db.profile.trackerBackdropEnabled = QuestieSmazak.db.profile.currentBackdropEnabled
                                QuestieSmazak.db.profile.trackerBorderEnabled = QuestieSmazak.db.profile.currentBorderEnabled
                                QuestieSmazak.db.profile.trackerBackdropFader = QuestieSmazak.db.profile.currentBackdropFader
                                QuestieTracker:UpdateFormatting()
                            end
                        end
                    },
                    group_header = {
                        type = "group",
                        order = 16,
                        inline = true,
                        width = 0.5,
                        name = function() return l10n("Tracker Header") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        args = {
                            enableHeader = {
                                type = "toggle",
                                order = 1,
                                width = 1.5,
                                name = function() return l10n("Enable Tracker Header") end,
                                desc = function() return l10n("If checked, the Tracker Header with the number of active quests and the QuestieSmazak Icon will be permanently visible.\n\nWhen this is disabled the QuestieSmazak Icon will fade in while your mouse is over the Tracker.") end,
                                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                                get = function() return QuestieSmazak.db.profile.trackerHeaderEnabled end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.trackerHeaderEnabled = value
                                    QuestieTracker:UpdateFormatting()
                                end
                            },
                            moveHeaderToBottom = {
                                type = "toggle",
                                order = 2,
                                width = 1.5,
                                name = function() return l10n("Show Tracker Header At The Bottom") end,
                                desc = function() return l10n("If checked, the Tracker Header and/or the QuestieSmazak Icon will be moved to the bottom of the QuestieSmazak Tracker and the sizer to the top.") end,
                                disabled = function() return (not QuestieSmazak.db.profile.trackerEnabled) end,
                                get = function() return QuestieSmazak.db.profile.moveHeaderToBottom end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.moveHeaderToBottom = value
                                    QuestieTracker:UpdateFormatting()
                                end
                            },
                            alwaysShowTracker = {
                                type = "toggle",
                                order = 3,
                                width = 1.5,
                                name = function() return l10n("Show Header For Empty Tracker") end,
                                desc = function() return l10n("If checked, the Tracker Header will be visible even when no quests are being tracked versus the Tracker being hidden completely.") end,
                                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                                get = function() return QuestieSmazak.db.profile.alwaysShowTracker end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.alwaysShowTracker = value
                                    if (QuestieSmazak.db.profile.alwaysShowTracker == true) and (QuestieSmazak.db.char.isTrackerExpanded == false) then
                                        QuestieSmazak.db.char.isTrackerExpanded = true
                                        -- Expanding needs quest lines, not only formatting.
                                        QuestieTracker:Update()
                                    end
                                    QuestieTracker:UpdateFormatting()
                                end
                            },
                        },
                    },
                    group_background = {
                        type = "group",
                        order = 17,
                        inline = true,
                        width = 0.5,
                        name = function() return l10n("Tracker Background") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        args = {
                            enableBackground = {
                                type = "toggle",
                                order = 1,
                                width = 1.5,
                                name = function() return l10n("Enable Background") end,
                                desc = function() return l10n("If checked, the QuestieSmazak Tracker Background becomes visible.") end,
                                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                                get = function() return QuestieSmazak.db.profile.trackerBackdropEnabled end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.trackerBackdropEnabled = value
                                    QuestieSmazak.db.profile.currentBackdropEnabled = value

                                    if value == true and not QuestieSmazak.db.profile.trackerBackdropFader then
                                        local c = QuestieSmazak.db.profile.trackerBackdropColor
                                        TrackerBaseFrame.baseFrame:SetBackdropColor(c.r, c.g, c.b, c.a)
                                    else
                                        TrackerBaseFrame.baseFrame:SetBackdropColor(0, 0, 0, 0)
                                    end
                                    QuestieTracker:UpdateFormatting()
                                end
                            },
                            enableBorder = {
                                type = "toggle",
                                order = 2,
                                width = 1.5,
                                name = function() return l10n("Enable Border") end,
                                desc = function() return l10n("If checked, the QuestieSmazak Tracker Border becomes visible.") end,
                                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled or not QuestieSmazak.db.profile.trackerBackdropEnabled end,
                                get = function() return QuestieSmazak.db.profile.trackerBorderEnabled end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.trackerBorderEnabled = value
                                    QuestieSmazak.db.profile.currentBorderEnabled = value

                                    if value == true and not QuestieSmazak.db.profile.trackerBackdropFader then
                                        local c = QuestieSmazak.db.profile.trackerBackdropColor
                                        TrackerBaseFrame.baseFrame:SetBackdropBorderColor(1, 1, 1, c.a)
                                    else
                                        TrackerBaseFrame.baseFrame:SetBackdropBorderColor(1, 1, 1, 0)
                                    end
                                    QuestieTracker:UpdateFormatting()
                                end
                            },
                            fadeTrackerBackdrop = {
                                type = "toggle",
                                order = 3,
                                width = 1.5,
                                name = function() return l10n("Fade Background") end,
                                desc = function() return l10n("If checked, the QuestieSmazak Tracker background and border (if enabled) will fade and become transparent when not in use.") end,
                                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled or not QuestieSmazak.db.profile.trackerBackdropEnabled end,
                                get = function() return QuestieSmazak.db.profile.trackerBackdropFader end,
                                set = function(_, value)
                                    QuestieSmazak.db.profile.trackerBackdropFader = value
                                    QuestieSmazak.db.profile.currentBackdropFader = value

                                    if value == true then
                                        startFadeTicker()
                                    end
                                    QuestieTracker:UpdateFormatting()
                                end
                            },
                            trackerBackdropColor = {
                                type = "color",
                                order = 4,
                                width = 1.5,
                                name = function() return l10n("Background Color") end,
                                desc = function() return l10n("Choose the color for the QuestieSmazak Tracker background.") end,
                                hasAlpha = true,
                                disabled = function() return (not QuestieSmazak.db.profile.trackerBackdropEnabled) or (not QuestieSmazak.db.profile.trackerEnabled) end,
                                get = function()
                                    local c = QuestieSmazak.db.profile.trackerBackdropColor
                                    return c.r, c.g, c.b, c.a
                                end,
                                set = function(_, r, g, b, a)
                                    QuestieSmazak.db.profile.trackerBackdropColor = {r = r, g = g, b = b, a = a}
                                    if QuestieSmazak.db.profile.trackerBackdropEnabled then
                                        TrackerBaseFrame.baseFrame:SetBackdropColor(r, g, b, a)
                                    end

                                    if QuestieSmazak.db.profile.trackerBorderEnabled then
                                        TrackerBaseFrame.baseFrame:SetBackdropBorderColor(1, 1, 1, a)
                                    end

                                    if QuestieSmazak.db.profile.trackerBackdropFader then
                                        debounceFadeTicker()
                                    end
                                end
                            },
                        },
                    },
                }
            },
            group_fonts = {
                type = "group",
                order = 8,
                inline = true,
                width = 0.5,
                name = function() return l10n("Font Options"); end,
                disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                args = {
                    fontSizeHeader = {
                        type = "range",
                        order = 1,
                        name = function() return l10n("Font Size for Active Quests Header") end,
                        desc = function() return l10n("The font size used for the Active Quests Header.") end,
                        width = "double",
                        min = 8,
                        max = 26,
                        step = 1,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled or not QuestieSmazak.db.profile.trackerHeaderEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerFontSizeHeader end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerFontSizeHeader = value
                            QuestieTracker:Update()
                        end
                    },
                    fontHeader = {
                        type = "select",
                        dialogControl = "LSM30_Font",
                        order = 2,
                        values = SharedMedia:HashTable("font"),
                        style = "dropdown",
                        name = function() return l10n("Font for Active Quests Header") end,
                        desc = function() return l10n("The font used for the Active Quests Header.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled or not QuestieSmazak.db.profile.trackerHeaderEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerFontHeader or "Friz Quadrata TT" end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerFontHeader = value
                            QuestieTracker:Update()
                        end
                    },
                    fontSizeZone = {
                        type = "range",
                        order = 3,
                        name = function() return l10n("Font Size for Zone Names") end,
                        desc = function() return l10n("The font size used for zone names.") end,
                        width = "double",
                        min = 8,
                        max = 26,
                        step = 1,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerFontSizeZone end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerFontSizeZone = value
                            QuestieTracker:Update()
                        end
                    },
                    fontZone = {
                        type = "select",
                        dialogControl = "LSM30_Font",
                        order = 4,
                        values = SharedMedia:HashTable("font"),
                        style = "dropdown",
                        name = function() return l10n("Font for Zone Names") end,
                        desc = function() return l10n("The font used for zone names.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerFontZone or "Friz Quadrata TT" end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerFontZone = value
                            QuestieTracker:Update()
                        end
                    },
                    fontSizeQuest = {
                        type = "range",
                        order = 5,
                        name = function() return l10n("Font Size for Quest Titles") end,
                        desc = function() return l10n("The font size used for Quest Titles.\n\nNOTE: Objective font size will auto adjust to less than or equal to Quest font size. This is necessary to avoid any text collisions and formatting abnormalities.") end,
                        width = "double",
                        min = 8,
                        max = 26,
                        step = 1,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerFontSizeQuest end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerFontSizeQuest = value
                            QuestieTracker:Update()
                        end
                    },
                    fontQuest = {
                        type = "select",
                        dialogControl = "LSM30_Font",
                        order = 6,
                        values = SharedMedia:HashTable("font"),
                        style = "dropdown",
                        name = function() return l10n("Font for Quest Titles") end,
                        desc = function() return l10n("The font used for Quest Titles.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerFontQuest or "Friz Quadrata TT" end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerFontQuest = value
                            QuestieTracker:Update()
                        end
                    },
                    fontSizeObjective = {
                        type = "range",
                        order = 7,
                        name = function() return l10n("Font Size for Objectives") end,
                        desc = function() return l10n("The font size used for Objectives.\n\nNOTE: Objective font size will auto adjust to less than or equal to Quest font size. This is necessary to avoid any text collisions and formatting abnormalities.") end,
                        width = "double",
                        min = 8,
                        max = 26,
                        step = 1,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerFontSizeObjective end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerFontSizeObjective = value
                            QuestieTracker:Update()
                        end
                    },
                    fontObjective = {
                        type = "select",
                        dialogControl = "LSM30_Font",
                        order = 8,
                        values = SharedMedia:HashTable("font"),
                        style = "dropdown",
                        name = function() return l10n("Font for Objectives") end,
                        desc = function() return l10n("The font used for Objectives.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function() return QuestieSmazak.db.profile.trackerFontObjective or "Friz Quadrata TT" end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerFontObjective = value
                            QuestieTracker:Update()
                        end
                    },
                    fontOutline = {
                        type = "select",
                        order = 9,
                        width = 1.5,
                        values = {
                            [""] = NONE,
                            ["OUTLINE"] = SELF_HIGHLIGHT_MODE_OUTLINE,
                        },
                        style = "dropdown",
                        name = function() return l10n("Outline for Zones, Titles, and Objectives") end,
                        desc = function() return l10n("The outline used for Quest Zones, Titles, and Objectives in the QuestieSmazak Tracker.") end,
                        disabled = function() return not QuestieSmazak.db.profile.trackerEnabled end,
                        get = function()
                            return QuestieSmazak.db.profile.trackerFontOutline
                        end,
                        set = function(_, value)
                            QuestieSmazak.db.profile.trackerFontOutline = value
                            QuestieTracker:Update()
                        end
                    },
                }
            },
        }
    }

    return trackerOptions
end

_GetShortcuts = function()
    return {
        ["left"] = l10n("Left Click"),
        ["right"] = l10n("Right Click"),
        ["shiftleft"] = l10n("Shift") .. " + " .. l10n("Left Click"),
        ["shiftright"] = l10n("Shift") .. " + " .. l10n("Right Click"),
        ["ctrlleft"] = l10n("Control") .. " + " .. l10n("Left Click"),
        ["ctrlright"] = l10n("Control") .. " + " .. l10n("Right Click"),
        ["altleft"] = l10n("Alt") .. " + " .. l10n("Left Click"),
        ["altright"] = l10n("Alt") .. " + " .. l10n("Right Click"),
        ["disabled"] = l10n("Disabled"),
    }
end
