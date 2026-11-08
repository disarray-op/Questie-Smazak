dofile("setupTests.lua")

describe("Migration", function()
    ---@type Migration
    local Migration
    local originalQuestieDB

    before_each(function()
        originalQuestieDB = QuestieSmazak.db
        QuestieSmazak.db = {
            profile = {
                migrationVersion = 37,
                disableDatabaseWarnings = true,
            },
            global = {},
            char = {
                townsfolkVersion = 42,
            },
        }

        dofile("Modules/Migration.lua")
        Migration = QuestieSmazakLoader:ImportModule("Migration")
    end)

    after_each(function()
        QuestieSmazak.db = originalQuestieDB
    end)

    it("clears compiler payloads from ordinary, SoD, and Titan scopes", function()
        local compilerPayload = {
            dbIsCompiled = true,
            dbCompiledOnVersion = "v1",
            dbCompiledLang = "deDE",
            dbCompiledExpansion = 1,
            dbCompiledCount = 2,
            npcBin = "npc",
            npcPtrs = {1},
            questBin = "quest",
            questPtrs = {2},
            objBin = "object",
            objPtrs = {3},
            itemBin = "item",
            itemPtrs = {4},
            retained = "keep",
        }
        QuestieSmazak.db.global = {}
        QuestieSmazak.db.global.sod = {}
        QuestieSmazak.db.global.titanReforged = {}
        for key, value in pairs(compilerPayload) do
            QuestieSmazak.db.global[key] = value
            QuestieSmazak.db.global.sod[key] = value
            QuestieSmazak.db.global.titanReforged[key] = value
        end

        Migration:Migrate()

        local expectedScope = {retained = "keep"}
        assert.are_same(expectedScope, QuestieSmazak.db.global.sod)
        assert.are_same(expectedScope, QuestieSmazak.db.global.titanReforged)
        QuestieSmazak.db.global.sod = nil
        QuestieSmazak.db.global.titanReforged = nil
        assert.are_same(expectedScope, QuestieSmazak.db.global)
        assert.is_nil(QuestieSmazak.db.profile.disableDatabaseWarnings)
        assert.is_nil(QuestieSmazak.db.char.townsfolkVersion)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("preserves tracker preferences when upgrading from version 37", function()
        QuestieSmazak.db.profile.minimizeTrackerInDungeons = true
        QuestieSmazak.db.profile.hideTrackerInDungeons = false

        Migration:Migrate()

        assert.is_true(QuestieSmazak.db.profile.minimizeTrackerInInstances)
        assert.is_false(QuestieSmazak.db.profile.hideTrackerInInstances)
        assert.is_nil(QuestieSmazak.db.profile.minimizeTrackerInDungeons)
        assert.is_nil(QuestieSmazak.db.profile.hideTrackerInDungeons)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("clears compiler state without rerunning tracker migration from version 38", function()
        QuestieSmazak.db.profile.migrationVersion = 38
        QuestieSmazak.db.profile.minimizeTrackerInInstances = false
        QuestieSmazak.db.profile.hideTrackerInInstances = true
        QuestieSmazak.db.global.dbIsCompiled = true
        QuestieSmazak.db.global.questBin = "quest"

        Migration:Migrate()

        assert.is_nil(QuestieSmazak.db.global.dbIsCompiled)
        assert.is_nil(QuestieSmazak.db.global.questBin)
        assert.is_nil(QuestieSmazak.db.profile.disableDatabaseWarnings)
        assert.is_nil(QuestieSmazak.db.char.townsfolkVersion)
        assert.is_false(QuestieSmazak.db.profile.minimizeTrackerInInstances)
        assert.is_true(QuestieSmazak.db.profile.hideTrackerInInstances)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("clears Titan compiler payloads when the SoD scope is absent", function()
        QuestieSmazak.db.profile.migrationVersion = 38
        QuestieSmazak.db.global.titanReforged = {
            dbIsCompiled = true,
            questBin = "quest",
            retained = "keep",
        }

        Migration:Migrate()

        assert.are_same({retained = "keep"}, QuestieSmazak.db.global.titanReforged)
        assert.is_nil(QuestieSmazak.db.global.sod)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("removes the Townsfolk lookups when upgrading from version 39", function()
        QuestieSmazak.db.profile.migrationVersion = 39
        QuestieSmazak.db.global.townsfolk = {Repair = {1001}}
        QuestieSmazak.db.global.professionTrainers = {[1] = {2001}}
        QuestieSmazak.db.global.classSpecificTownsfolk = {WARRIOR = {}}
        QuestieSmazak.db.global.factionSpecificTownsfolk = {Horde = {}}
        QuestieSmazak.db.global.petFoodVendorTypes = {Meat = {7001}}
        QuestieSmazak.db.global.retained = "keep"

        Migration:Migrate()

        assert.are_same({retained = "keep"}, QuestieSmazak.db.global)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("retires the wording preference without rerunning completed migrations", function()
        QuestieSmazak.db.profile.migrationVersion = 40
        QuestieSmazak.db.profile.trimObjectiveText = false
        QuestieSmazak.db.profile.minimizeTrackerInInstances = true
        QuestieSmazak.db.global.retained = "keep"

        Migration:Migrate()

        assert.is_nil(QuestieSmazak.db.profile.trimObjectiveText)
        assert.is_true(QuestieSmazak.db.profile.minimizeTrackerInInstances)
        assert.are_same({retained = "keep"}, QuestieSmazak.db.global)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("handles Saved Variables without former seasonal compiler scopes", function()
        QuestieSmazak.db.global.retained = true

        Migration:Migrate()

        assert.is_true(QuestieSmazak.db.global.retained)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("should enable the quest focus buttons when upgrading from version 43", function()
        QuestieSmazak.db.profile.migrationVersion = 43

        Migration:Migrate()

        assert.is_true(QuestieSmazak.db.profile.trackerShowQuestFocusButtons)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("should not fade the quest focus buttons when upgrading from version 44", function()
        QuestieSmazak.db.profile.migrationVersion = 44

        Migration:Migrate()

        assert.is_false(QuestieSmazak.db.profile.trackerFadeQuestFocusButtons)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("should show the tracker play buttons when upgrading from version 45", function()
        QuestieSmazak.db.profile.migrationVersion = 45

        Migration:Migrate()

        assert.is_true(QuestieSmazak.db.profile.trackerShowPlayButtons)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("should not follow Blizzard super tracking when upgrading from version 46", function()
        QuestieSmazak.db.profile.migrationVersion = 46
        QuestieSmazak.db.profile.trackerFollowSuperTracking = true

        Migration:Migrate()

        assert.is_false(QuestieSmazak.db.profile.trackerFollowSuperTracking)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("should enable the compartment button when upgrading from version 47", function()
        QuestieSmazak.db.profile.migrationVersion = 47
        QuestieSmazak.db.profile.minimap = {hide = false}

        Migration:Migrate()

        assert.is_true(QuestieSmazak.db.profile.minimap.showInCompartment)
        assert.is_false(QuestieSmazak.db.profile.minimap.hide)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("should create the minimap table when it is missing", function()
        QuestieSmazak.db.profile.migrationVersion = 47
        QuestieSmazak.db.profile.minimap = nil

        Migration:Migrate()

        assert.is_true(QuestieSmazak.db.profile.minimap.showInCompartment)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("should remove the Blizzard quest timer setting when upgrading from version 48", function()
        QuestieSmazak.db.profile.migrationVersion = 48
        QuestieSmazak.db.profile.showBlizzardQuestTimer = true

        Migration:Migrate()

        assert.is_nil(QuestieSmazak.db.profile.showBlizzardQuestTimer)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)

    it("should show the quest giver on focus when upgrading from version 49", function()
        QuestieSmazak.db.profile.migrationVersion = 49

        Migration:Migrate()

        assert.is_true(QuestieSmazak.db.profile.trackerShowQuestGiverOnFocus)
        assert.are_same(50, QuestieSmazak.db.profile.migrationVersion)
    end)
end)
