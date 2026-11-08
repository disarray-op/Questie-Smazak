---@class QuestieAPI
local QuestieAPI = QuestieSmazakLoader:ImportModule("QuestieAPI")

---@type fun()[]
local onReadyCallbacks = {}

--- Register a callback to be invoked once QuestieSmazak.API.isReady becomes true.
--- If already ready, the callback is invoked immediately.
---@param callback fun()
function QuestieSmazak.API.RegisterOnReady(callback)
    if type(callback) ~= "function" then
        error("QuestieSmazak.API.RegisterOnReady: callback must be a function")
    end

    if QuestieSmazak.API.isReady then
        xpcall(callback, CallErrorHandler)
        return
    end

    table.insert(onReadyCallbacks, callback)
end

function QuestieAPI.PropagateOnReady()
    if (not QuestieSmazak.API.isReady) then
        return
    end

    for _, callback in pairs(onReadyCallbacks) do
        xpcall(callback, CallErrorHandler)
    end
    onReadyCallbacks = {}
end