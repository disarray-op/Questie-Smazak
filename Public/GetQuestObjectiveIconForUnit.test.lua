---@diagnostic disable: param-type-mismatch
dofile("setupTests.lua")

describe("GetQuestObjectiveIconForUnit", function()
    ---@type QuestieNameplate
    local QuestieNameplate

    before_each(function()
        _G.QuestieSmazak.API.isReady = true

        QuestieNameplate = QuestieSmazakLoader:ImportModule("QuestieNameplate")
        ---@diagnostic disable-next-line: assign-type-mismatch
        QuestieNameplate.GetIcon = spy.new(function()
            return "Interface\\Addons\\QuestieSmazak\\Icons\\slay.blp"
        end)

        dofile("Public/GetQuestObjectiveIconForUnit.lua")
    end)

    it("should return nil when QuestieSmazak API is not ready", function()
        _G.QuestieSmazak.API.isReady = false

        local result = _G.QuestieSmazak.API.GetQuestObjectiveIconForUnit("some-guid")

        assert.is_nil(result)
    end)

    it("should return error when guid is not a string", function()
        assert.has_error(function()
            _G.QuestieSmazak.API.GetQuestObjectiveIconForUnit(nil)
        end)
        assert.has_error(function()
            _G.QuestieSmazak.API.GetQuestObjectiveIconForUnit(123)
        end)
        assert.has_error(function()
            _G.QuestieSmazak.API.GetQuestObjectiveIconForUnit(true)
        end)
        assert.has_error(function()
            _G.QuestieSmazak.API.GetQuestObjectiveIconForUnit({})
        end)
    end)

    it("should return icon path when QuestieSmazak API is ready", function()
        local result = _G.QuestieSmazak.API.GetQuestObjectiveIconForUnit("some-guid")

        assert.is_equal("Interface\\Addons\\QuestieSmazak\\Icons\\slay.blp", result)
        assert.spy(QuestieNameplate.GetIcon).was.called_with("some-guid")
    end)
end)
