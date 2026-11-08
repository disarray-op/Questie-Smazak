dofile("setupTests.lua")

describe("TrackerSuperTrack", function()
    ---@type TrackerSuperTrack
    local TrackerSuperTrack
    local TrackerUtils
    local QuestieQuest
    local QuestieTracker
    local superTrackedQuestId

    before_each(function()
        QuestieSmazak.db.char.TrackerFocus = nil
        superTrackedQuestId = nil

        local QuestieCompat = QuestieSmazakLoader:ImportModule("QuestieCompat")
        QuestieCompat.GetSuperTrackedQuestID = function() return superTrackedQuestId end
        QuestieSmazak.db.profile.trackerFollowSuperTracking = true
        TrackerUtils = QuestieSmazakLoader:ImportModule("TrackerUtils")
        TrackerUtils.FocusQuest = spy.new(function() return true end)
        TrackerUtils.UnFocus = spy.new(function() end)
        QuestieQuest = QuestieSmazakLoader:ImportModule("QuestieQuest")
        QuestieQuest.ToggleQuestNotes = spy.new(function() end)
        QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker")
        QuestieTracker.Update = spy.new(function() end)
        QuestieSmazakLoader:ImportModule("QuestieCombatQueue").Queue = function(_, callback) callback() end

        dofile("Modules/Tracker/TrackerSuperTrack.lua")
        TrackerSuperTrack = QuestieSmazakLoader:ImportModule("TrackerSuperTrack")
    end)

    describe("OnSuperTrackingChanged", function()
        it("should ignore Blizzard super tracking when following is disabled", function()
            QuestieSmazak.db.profile.trackerFollowSuperTracking = false
            superTrackedQuestId = 123

            TrackerSuperTrack.OnSuperTrackingChanged()

            assert.spy(TrackerUtils.FocusQuest).was.not_called()
            assert.spy(TrackerUtils.UnFocus).was.not_called()
            assert.spy(QuestieQuest.ToggleQuestNotes).was.not_called()
            assert.spy(QuestieTracker.Update).was.not_called()
        end)

        it("should focus a quest super tracked by Blizzard", function()
            superTrackedQuestId = 123

            TrackerSuperTrack.OnSuperTrackingChanged()

            assert.spy(TrackerUtils.FocusQuest).was.called_with(TrackerUtils, 123)
            assert.spy(QuestieQuest.ToggleQuestNotes).was.called_with(false)
            assert.spy(QuestieTracker.Update).was.called()
        end)

        it("should only redraw the tracker when the super tracked quest is already focused", function()
            superTrackedQuestId = 123
            QuestieSmazak.db.char.TrackerFocus = 123

            TrackerSuperTrack.OnSuperTrackingChanged()

            assert.spy(TrackerUtils.FocusQuest).was.not_called()
            assert.spy(QuestieQuest.ToggleQuestNotes).was.not_called()
            assert.spy(QuestieTracker.Update).was.called()
        end)

        it("should unfocus the focused quest when Blizzard super tracks a quest QuestieSmazak can not focus", function()
            superTrackedQuestId = 123
            QuestieSmazak.db.char.TrackerFocus = 99
            TrackerUtils.FocusQuest = spy.new(function() return false end)

            TrackerSuperTrack.OnSuperTrackingChanged()

            assert.spy(TrackerUtils.UnFocus).was.called()
            assert.spy(QuestieQuest.ToggleQuestNotes).was.called_with(true)
            assert.spy(QuestieTracker.Update).was.called()
        end)

        it("should redraw the tracker when Blizzard super tracks a quest QuestieSmazak can not focus without a focus", function()
            superTrackedQuestId = 123
            TrackerUtils.FocusQuest = spy.new(function() return false end)

            TrackerSuperTrack.OnSuperTrackingChanged()

            assert.spy(TrackerUtils.UnFocus).was.not_called()
            assert.spy(QuestieTracker.Update).was.called()
        end)

        it("should unfocus the focused quest when Blizzard clears super tracking", function()
            QuestieSmazak.db.char.TrackerFocus = 123

            TrackerSuperTrack.OnSuperTrackingChanged()

            assert.spy(TrackerUtils.UnFocus).was.called()
            assert.spy(QuestieQuest.ToggleQuestNotes).was.called_with(true)
            assert.spy(QuestieTracker.Update).was.called()
        end)

        it("should redraw the tracker when super tracking is cleared without a focus", function()
            TrackerSuperTrack.OnSuperTrackingChanged()

            assert.spy(TrackerUtils.UnFocus).was.not_called()
            assert.spy(QuestieTracker.Update).was.called()
        end)
    end)
end)
