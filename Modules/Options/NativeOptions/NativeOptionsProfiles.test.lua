dofile("setupTests.lua")

describe("native profile options", function()
    local callbacks
    local QuestieOptionsEngine, AvailableQuests, QuestieNameplate, QuestieDBMIntegration, QuestieTracker, QuestieMap, QuestieQuest, MinimapIcon
    local originalDb, originalSetIcons, originalStrtrim, originalStrlenutf8
    local Popup, items, currentProfile

    before_each(function()
        originalDb = QuestieSmazak.db
        originalSetIcons = QuestieSmazak.SetIcons
        originalStrtrim, originalStrlenutf8 = _G.strtrim, _G.strlenutf8
        _G.strtrim = function(text) return (text:gsub("^%s+", ""):gsub("%s+$", "")) end
        _G.strlenutf8 = string.len

        callbacks = {}
        currentProfile = "Current"
        QuestieSmazak.SetIcons = function() end
        QuestieSmazak.db = {
            profile = {DBMHUDZoom = 80, DBMHUDRefresh = 0.05},
            keys = {},
            RegisterCallback = function(_, event, handler) callbacks[event] = handler end,
            GetCurrentProfile = function() return currentProfile end,
            GetProfiles = function() return {"Current", "Other"} end,
            SetProfile = spy.new(function() end),
            CopyProfile = spy.new(function() end),
            DeleteProfile = spy.new(function() end),
        }

        Popup = QuestieSmazakLoader:ImportModule("QuestiePopup")
        Popup.Dialogs = {}
        Popup.Show = spy.new(function() end)
        QuestieOptionsEngine = QuestieSmazakLoader:ImportModule("QuestieOptionsEngine")
        QuestieOptionsEngine.tabs = {}
        QuestieOptionsEngine.RefreshStates = spy.new(function() end)

        AvailableQuests = QuestieSmazakLoader:ImportModule("AvailableQuests")
        AvailableQuests.ResetLevelRequirementCache = spy.new(function() end)
        QuestieNameplate = QuestieSmazakLoader:ImportModule("QuestieNameplate")
        QuestieNameplate.RedrawIcons = spy.new(function() end)
        QuestieNameplate.RedrawFrameIcon = spy.new(function() end)
        QuestieDBMIntegration = QuestieSmazakLoader:ImportModule("QuestieDBMIntegration")
        QuestieDBMIntegration.ChangeZoomLevel = spy.new(function() end)
        QuestieDBMIntegration.ChangeRefreshRate = spy.new(function() end)
        QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker")
        QuestieTracker.Update = spy.new(function() end)
        QuestieTracker.UpdateFormatting = spy.new(function() end)
        QuestieMap = QuestieSmazakLoader:ImportModule("QuestieMap")
        QuestieMap.RescaleIcons = spy.new(function() end)
        QuestieMap.RescaleTownsfolkIcons = spy.new(function() end)
        QuestieQuest = QuestieSmazakLoader:ImportModule("QuestieQuest")
        QuestieQuest.SmoothReset = spy.new(function() end)
        MinimapIcon = QuestieSmazakLoader:ImportModule("MinimapIcon")
        MinimapIcon.RefreshProfile = spy.new(function() end)

        dofile("Modules/Options/NativeOptions/NativeOptionsProfiles.lua")
        items = QuestieOptionsEngine.tabs.profiles:Initialize().items
    end)

    after_each(function()
        QuestieSmazak.db = originalDb
        QuestieSmazak.SetIcons = originalSetIcons
        _G.strtrim, _G.strlenutf8 = originalStrtrim, originalStrlenutf8
    end)

    -- Refreshing a control doesn't run its setter, and a tab that was never opened has no controls at all.
    -- So applying the new profile can't be left to the sliders of the options window.
    describe("switching profile", function()
        for _, event in ipairs({"OnProfileChanged", "OnProfileCopied", "OnProfileReset"}) do
            it("should apply what the settings do on " .. event, function()
                callbacks[event]()

                assert.spy(AvailableQuests.ResetLevelRequirementCache).was.called(1)
                assert.spy(QuestieQuest.SmoothReset).was.called(1)
                assert.spy(QuestieMap.RescaleIcons).was.called(1)
                assert.spy(QuestieMap.RescaleTownsfolkIcons).was.called(1)
                assert.spy(QuestieTracker.Update).was.called(1)
                assert.spy(QuestieTracker.UpdateFormatting).was.called(1)
                assert.spy(QuestieNameplate.RedrawIcons).was.called(1)
                assert.spy(QuestieNameplate.RedrawFrameIcon).was.called(1)
                assert.spy(MinimapIcon.RefreshProfile).was.called(1)
                assert.spy(QuestieOptionsEngine.RefreshStates).was.called(1)
            end)
        end

        it("should apply the DBM HUD values of the new profile", function()
            callbacks.OnProfileChanged()

            assert.spy(QuestieDBMIntegration.ChangeZoomLevel).was.called_with(QuestieDBMIntegration, 80)
            assert.spy(QuestieDBMIntegration.ChangeRefreshRate).was.called_with(QuestieDBMIntegration, 0.05)
        end)
    end)

    -- AceDB fires the callbacks above for each of these, so applying the profile here as well would do it all twice.
    describe("the profile controls", function()
        it("should switch to a picked profile and leave applying it to the callback", function()
            items.existing_profiles.set("Other")

            assert.spy(QuestieSmazak.db.SetProfile).was.called(1)
            assert.are.equal("Other", QuestieSmazak.db.SetProfile.calls[1].vals[2])
            assert.spy(QuestieQuest.SmoothReset).was.not_called()
        end)

        it("should do nothing when picking the current profile", function()
            items.existing_profiles.set("Current")

            assert.spy(QuestieSmazak.db.SetProfile).was.not_called()
        end)

        it("should create a profile from a trimmed name", function()
            items.new_profile.set("  New  ")

            assert.spy(QuestieSmazak.db.SetProfile).was.called(1)
            assert.are.equal("New", QuestieSmazak.db.SetProfile.calls[1].vals[2])
        end)

        it("should refuse a blank profile name", function()
            items.new_profile.set("   ")

            assert.spy(QuestieSmazak.db.SetProfile).was.not_called()
        end)

        it("should copy from a picked profile and leave applying it to the callback", function()
            items.copy_profile.set("Other")

            assert.spy(QuestieSmazak.db.CopyProfile).was.called(1)
            assert.are.equal("Other", QuestieSmazak.db.CopyProfile.calls[1].vals[2])
            assert.spy(QuestieQuest.SmoothReset).was.not_called()
        end)

        it("should only offer other profiles to copy from or delete", function()
            local options = items.copy_profile.options()

            assert.are.equal("Other", options.Other)
            assert.is_nil(options.Current)
        end)

        it("should ask for confirmation before deleting, and delete the picked profile on acceptance", function()
            assert.is_false(items.delete_button.enabled())

            items.delete_dropdown.set("Other")
            assert.is_true(items.delete_button.enabled())

            items.delete_button.func()
            assert.spy(Popup.Show).was.called_with("QUESTIE_PROFILE_DELETE_CONFIRM")
            assert.spy(QuestieSmazak.db.DeleteProfile).was.not_called()

            Popup.Dialogs.QUESTIE_PROFILE_DELETE_CONFIRM.OnAccept()
            assert.spy(QuestieSmazak.db.DeleteProfile).was.called(1)
            assert.are.equal("Other", QuestieSmazak.db.DeleteProfile.calls[1].vals[2])
        end)

        it("should never delete the current profile, even if it became current after being picked", function()
            items.delete_dropdown.set("Other")
            currentProfile = "Other"

            Popup.Dialogs.QUESTIE_PROFILE_DELETE_CONFIRM.OnAccept()

            assert.spy(QuestieSmazak.db.DeleteProfile).was.not_called()
        end)
    end)
end)
