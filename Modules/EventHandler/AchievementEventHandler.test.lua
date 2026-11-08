dofile("setupTests.lua")

describe("AchievementEventHandler", function()
    ---@type AchievementEventHandler
    local AchievementEventHandler
    local QuestieTracker, QuestieCombatQueue, AchievementTracking
    local originalUpdate, originalQueue, originalGetTrackedIds, originalIsTracked, trackedIds, tracked

    before_each(function()
        QuestieTracker = QuestieSmazakLoader:ImportModule("QuestieTracker")
        QuestieCombatQueue = QuestieSmazakLoader:ImportModule("QuestieCombatQueue")
        AchievementTracking = QuestieSmazakLoader:ImportModule("AchievementTracking")
        originalUpdate, originalQueue = QuestieTracker.Update, QuestieCombatQueue.Queue
        originalGetTrackedIds, originalIsTracked = AchievementTracking.GetTrackedIds, AchievementTracking.IsTracked
        trackedIds = {}
        tracked = true
        QuestieTracker.Update = spy.new(function() end)
        QuestieCombatQueue.Queue = function(_, callback) callback() end
        AchievementTracking.GetTrackedIds = function() return trackedIds end
        AchievementTracking.IsTracked = function() return tracked end
        QuestieSmazak.db.char.collapsedQuests = {}
        QuestieSmazak.db.char.collapsedZones = {}

        dofile("Modules/EventHandler/AchievementEventHandler.lua")
        AchievementEventHandler = QuestieSmazakLoader:ImportModule("AchievementEventHandler")
    end)

    after_each(function()
        QuestieTracker.Update, QuestieCombatQueue.Queue = originalUpdate, originalQueue
        AchievementTracking.GetTrackedIds, AchievementTracking.IsTracked = originalGetTrackedIds, originalIsTracked
    end)

    describe("AchievementEarned", function()
        it("should update the tracker", function()
            AchievementEventHandler.AchievementEarned()

            assert.spy(QuestieTracker.Update).was.called(1)
        end)
    end)

    describe("TrackedAchievementListChanged", function()
        it("should update the tracker", function()
            AchievementEventHandler.TrackedAchievementListChanged(12)

            assert.spy(QuestieTracker.Update).was.called(1)
        end)

        it("should expand a newly tracked achievement and the Achievements zone", function()
            QuestieSmazak.db.char.collapsedQuests = {[12] = true, [13] = true}
            QuestieSmazak.db.char.collapsedZones = {Achievements = true, Durotar = true}

            AchievementEventHandler.TrackedAchievementListChanged(12)

            assert.are_same({[13] = true}, QuestieSmazak.db.char.collapsedQuests)
            assert.are_same({Durotar = true}, QuestieSmazak.db.char.collapsedZones)
        end)

        it("should keep the minimized states when an achievement is untracked", function()
            QuestieSmazak.db.char.collapsedQuests = {[12] = true}
            QuestieSmazak.db.char.collapsedZones = {Achievements = true}
            tracked = false

            AchievementEventHandler.TrackedAchievementListChanged(12)

            assert.are_same({[12] = true}, QuestieSmazak.db.char.collapsedQuests)
            assert.are_same({Achievements = true}, QuestieSmazak.db.char.collapsedZones)
            assert.spy(QuestieTracker.Update).was.called(1)
        end)

        it("should not change the minimized states without an achievement id", function()
            QuestieSmazak.db.char.collapsedZones = {Achievements = true}

            AchievementEventHandler.TrackedAchievementListChanged(0)

            assert.are_same({Achievements = true}, QuestieSmazak.db.char.collapsedZones)
        end)
    end)

    describe("CriteriaUpdate", function()
        it("should update the tracker while achievements are tracked", function()
            trackedIds = {12}

            AchievementEventHandler.CriteriaUpdate()

            assert.spy(QuestieTracker.Update).was.called(1)
        end)

        it("should not update the tracker without tracked achievements", function()
            AchievementEventHandler.CriteriaUpdate()

            assert.spy(QuestieTracker.Update).was.not_called()
        end)
    end)
end)
