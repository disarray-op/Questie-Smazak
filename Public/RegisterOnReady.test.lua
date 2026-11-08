---@diagnostic disable: param-type-mismatch
dofile("setupTests.lua")

describe("RegisterOnReady", function()
    ---@type QuestieAPI
    local QuestieAPI

    before_each(function()
        dofile("Public/Enums.lua")
        _G.QuestieSmazak.API.isReady = true

        dofile("Public/RegisterOnReady.lua")
        QuestieAPI = QuestieSmazakLoader:ImportModule("QuestieAPI")
    end)

    it("should error when callback is not a function", function()
        assert.has_error(function()
            _G.QuestieSmazak.API.RegisterOnReady(nil)
        end)
        assert.has_error(function()
            _G.QuestieSmazak.API.RegisterOnReady(123)
        end)
        assert.has_error(function()
            _G.QuestieSmazak.API.RegisterOnReady("not-a-function")
        end)
        assert.has_error(function()
            _G.QuestieSmazak.API.RegisterOnReady(true)
        end)
        assert.has_error(function()
            _G.QuestieSmazak.API.RegisterOnReady({})
        end)
    end)

    it("should register and call the callback once the QuestieSmazak API is ready", function()
        _G.QuestieSmazak.API.isReady = false
        local callbackSpy = spy.new(function() end)

        _G.QuestieSmazak.API.RegisterOnReady(function() callbackSpy() end)
        assert.spy(callbackSpy).was.not_called()

        _G.QuestieSmazak.API.isReady = true
        QuestieAPI.PropagateOnReady()

        assert.spy(callbackSpy).was.called()
    end)

    it("should call the callback immediately if the QuestieSmazak API is already ready", function()
        _G.QuestieSmazak.API.isReady = true
        local callbackSpy = spy.new(function() end)

        _G.QuestieSmazak.API.RegisterOnReady(function() callbackSpy() end)

        assert.spy(callbackSpy).was.called()
    end)

    it("should not call the callback when not ready yet", function()
        _G.QuestieSmazak.API.isReady = false
        local callbackSpy = spy.new(function() end)

        _G.QuestieSmazak.API.RegisterOnReady(function() callbackSpy() end)
        QuestieAPI.PropagateOnReady()

        assert.spy(callbackSpy).was.not_called()
    end)
end)
