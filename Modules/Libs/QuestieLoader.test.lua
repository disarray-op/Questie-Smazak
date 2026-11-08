dofile("setupTests.lua")

describe("QuestieSmazakLoader", function()
    local originalProfilerEnabled
    local originalGetTimePreciseSec
    local originalDebugStack
    local originalCollectGarbage
    local clockSeconds
    local currentSourceFile

    ---Loads QuestieSmazakLoader with the current mocks in place. It reads QuestieSmazakProfilerEnabled at load time,
    ---so the flag has to be set before this runs.
    local function LoadQuestieSmazakLoader()
        dofile("Modules/Libs/QuestieSmazakLoader.lua")
    end

    ---@param milliseconds number
    local function AdvanceClock(milliseconds)
        clockSeconds = clockSeconds + (milliseconds / 1000)
    end

    before_each(function()
        originalProfilerEnabled = _G.QuestieSmazakProfilerEnabled
        originalGetTimePreciseSec = _G.GetTimePreciseSec
        originalDebugStack = _G.debugstack
        originalCollectGarbage = _G.collectgarbage

        clockSeconds = 0
        currentSourceFile = "Modules/Unknown.lua"
        _G.GetTimePreciseSec = function()
            return clockSeconds
        end
        -- WoW renders the path bracketed, which is what the loader parses.
        _G.debugstack = function()
            return "[Interface/AddOns/QuestieSmazak/" .. currentSourceFile .. "]:3: in main chunk\n"
        end
    end)

    after_each(function()
        _G.QuestieSmazakProfilerEnabled = originalProfilerEnabled
        _G.GetTimePreciseSec = originalGetTimePreciseSec
        _G.debugstack = originalDebugStack
        _G.collectgarbage = originalCollectGarbage
        -- Leave a clean, uninstrumented loader behind for any test file that runs after this one.
        LoadQuestieSmazakLoader()
    end)

    describe("module registration", function()
        before_each(function()
            _G.QuestieSmazakProfilerEnabled = nil
            LoadQuestieSmazakLoader()
        end)

        it("returns the same table for repeated CreateModule calls", function()
            assert.are_equal(QuestieSmazakLoader:CreateModule("Repeated"), QuestieSmazakLoader:CreateModule("Repeated"))
        end)

        it("returns the same table from ImportModule as from CreateModule", function()
            assert.are_equal(QuestieSmazakLoader:CreateModule("Shared"), QuestieSmazakLoader:ImportModule("Shared"))
        end)

        it("gives every module a private table", function()
            assert.are_same("table", type(QuestieSmazakLoader:CreateModule("WithPrivate").private))
        end)
    end)

    describe("module call observer", function()
        before_each(function()
            _G.QuestieSmazakProfilerEnabled = nil
            LoadQuestieSmazakLoader()
        end)

        after_each(function()
            QuestieSmazakLoader:SetModuleCallObserver(nil)
        end)

        it("is not called until something registers one", function()
            -- The default path must cost one comparison and nothing else.
            local calls = 0
            QuestieSmazakLoader:CreateModule("ObserverUnset")

            QuestieSmazakLoader:SetModuleCallObserver(function() calls = calls + 1 end)
            QuestieSmazakLoader:CreateModule("ObserverSet")

            assert.are_same(1, calls)
        end)

        it("tells the observer which module was named", function()
            -- This is what lets an observer look at one module instead of re-reading all of them.
            local seen = {}
            QuestieSmazakLoader:SetModuleCallObserver(function(moduleName)
                seen[#seen + 1] = moduleName
            end)

            QuestieSmazakLoader:CreateModule("ObserverNamedCreate")
            QuestieSmazakLoader:ImportModule("ObserverNamedImport")

            assert.are_same({"ObserverNamedCreate", "ObserverNamedImport"}, seen)
        end)

        it("fires on both CreateModule and ImportModule", function()
            local calls = 0
            QuestieSmazakLoader:SetModuleCallObserver(function() calls = calls + 1 end)

            QuestieSmazakLoader:CreateModule("ObserverCreate")
            QuestieSmazakLoader:ImportModule("ObserverImport")

            assert.are_same(2, calls)
        end)

        it("fires before the caller can reach the module it is registering", function()
            -- This ordering is the whole point: an observer installs into a module that is already loaded,
            -- and the file making this call has not yet run the line that would capture one of its functions.
            local seen
            QuestieSmazakLoader:SetModuleCallObserver(function()
                seen = QuestieSmazakLoader._modules.ObserverEarlier ~= nil
            end)
            QuestieSmazakLoader:CreateModule("ObserverEarlier")

            assert.is_false(seen)
        end)

        it("stops calling once the observer clears itself", function()
            local calls = 0
            local function observer()
                calls = calls + 1
                QuestieSmazakLoader:SetModuleCallObserver(nil)
            end
            QuestieSmazakLoader:SetModuleCallObserver(observer)

            QuestieSmazakLoader:CreateModule("ObserverOnce")
            QuestieSmazakLoader:CreateModule("ObserverAgain")
            QuestieSmazakLoader:ImportModule("ObserverThird")

            assert.are_same(1, calls)
        end)

        it("still registers modules normally while an observer is attached", function()
            QuestieSmazakLoader:SetModuleCallObserver(function() end)

            local module = QuestieSmazakLoader:CreateModule("ObserverRegistered")

            assert.are_equal(module, QuestieSmazakLoader:ImportModule("ObserverRegistered"))
            assert.are_same("table", type(module.private))
        end)
    end)

    describe("load timing when the profiler is disabled", function()
        before_each(function()
            _G.QuestieSmazakProfilerEnabled = nil
            LoadQuestieSmazakLoader()
        end)

        it("records nothing", function()
            QuestieSmazakLoader:CreateModule("First")
            AdvanceClock(50)
            QuestieSmazakLoader:CreateModule("Second")

            assert.is_nil(QuestieSmazakLoader.loadTimings)
        end)

        it("does not read the clock", function()
            local clockReads = 0
            _G.GetTimePreciseSec = function()
                clockReads = clockReads + 1
                return clockSeconds
            end

            QuestieSmazakLoader:CreateModule("First")
            QuestieSmazakLoader:ImportModule("Second")
            QuestieSmazakLoader:StampLoadBoundary()

            assert.are_same(0, clockReads)
        end)
    end)

    describe("load timing on a client with no usable clock", function()
        before_each(function()
            -- Profiling asked for, but GetTimePreciseSec absent. This file runs before anything that could
            -- report an error, so the only safe response is to record nothing rather than abort the addon.
            _G.QuestieSmazakProfilerEnabled = true
            _G.GetTimePreciseSec = nil
        end)

        it("loads without aborting", function()
            assert.has_no.errors(LoadQuestieSmazakLoader)
        end)

        it("records no timings rather than half of them", function()
            LoadQuestieSmazakLoader()

            currentSourceFile = "Modules/Alpha.lua"
            QuestieSmazakLoader:CreateModule("Alpha")
            currentSourceFile = "Modules/Beta.lua"
            QuestieSmazakLoader:CreateModule("Beta")

            assert.is_nil(QuestieSmazakLoader.loadTimings)
            assert.is_nil(QuestieSmazakLoader.loadMemory)
        end)

        it("still registers modules normally", function()
            LoadQuestieSmazakLoader()

            local module = QuestieSmazakLoader:CreateModule("StillWorks")
            assert.are_equal(module, QuestieSmazakLoader:ImportModule("StillWorks"))
            assert.are_same("table", type(module.private))
        end)

        it("does not fall back to debugprofilestop", function()
            local fallbackReads = 0
            _G.debugprofilestop = function()
                fallbackReads = fallbackReads + 1
                return 0
            end
            LoadQuestieSmazakLoader()

            QuestieSmazakLoader:CreateModule("Alpha")
            QuestieSmazakLoader:FinishLoadTimings()

            -- A resettable clock can run backwards, which would publish a negative interval.
            assert.are_same(0, fallbackReads)
        end)
    end)

    describe("load timing when the profiler is enabled", function()
        before_each(function()
            _G.QuestieSmazakProfilerEnabled = true
            LoadQuestieSmazakLoader()
        end)

        it("charges elapsed time to the file that opened the interval", function()
            currentSourceFile = "Modules/Alpha.lua"
            QuestieSmazakLoader:CreateModule("Alpha")
            AdvanceClock(50)

            currentSourceFile = "Modules/Beta.lua"
            QuestieSmazakLoader:CreateModule("Beta")

            assert.are_same(50, QuestieSmazakLoader.loadTimings["Modules/Alpha.lua"])
        end)

        it("attributes time before the first stamp to the loader file that started timing", function()
            AdvanceClock(12)
            currentSourceFile = "Modules/Alpha.lua"
            QuestieSmazakLoader:CreateModule("Alpha")

            assert.are_same(12, QuestieSmazakLoader.loadTimings["Modules/Libs/QuestieSmazakLoader.lua"])
        end)

        it("names the embedded-library interval from the boundary stamp in embeds.xml", function()
            -- The real startup sequence: the loader's own remainder, then the embeds boundary, then the
            -- libraries, closed by the first Lua file's module call.
            AdvanceClock(2)
            currentSourceFile = "embeds.xml:<Scripts>"
            QuestieSmazakLoader:StampLoadBoundary()
            AdvanceClock(400)

            currentSourceFile = "QuestieSmazak.lua"
            QuestieSmazakLoader:CreateModule("QuestieSmazak")

            assert.are_same(2, QuestieSmazakLoader.loadTimings["Modules/Libs/QuestieSmazakLoader.lua"])
            assert.are_same(400, QuestieSmazakLoader.loadTimings["embeds.xml"])
        end)

        it("opens an interval named after an XML group at a boundary stamp", function()
            currentSourceFile = "Localization/lookups/lookupZones.lua"
            QuestieSmazakLoader:ImportModule("l10n")
            AdvanceClock(3)

            -- An inline Script chunk reports the XML's own path, ":<Scripts>" suffixed, in main chunk.
            currentSourceFile = "Localization/Translations/Translations.xml:<Scripts>"
            QuestieSmazakLoader:StampLoadBoundary()
            AdvanceClock(200)

            currentSourceFile = "Modules/Libs/DistanceUtils.lua"
            QuestieSmazakLoader:CreateModule("DistanceUtils")

            -- Without the boundary, the group's whole parse cost lands on lookupZones.lua.
            assert.are_same(3, QuestieSmazakLoader.loadTimings["Localization/lookups/lookupZones.lua"])
            assert.are_same(200, QuestieSmazakLoader.loadTimings["Localization/Translations/Translations.xml"])
        end)

        it("uses an explicit source name for a boundary interval", function()
            currentSourceFile = "Libs/ThirdPartyLibraries.xml:<Scripts>"
            QuestieSmazakLoader:StampLoadBoundary("Libs/Vendor/Library.lua")
            AdvanceClock(30)

            currentSourceFile = "Modules/Beta.lua"
            QuestieSmazakLoader:CreateModule("Beta")

            assert.are_same(30, QuestieSmazakLoader.loadTimings["Libs/Vendor/Library.lua"])
            assert.is_nil(QuestieSmazakLoader.loadTimings["Libs/ThirdPartyLibraries.xml"])
        end)

        it("ignores a boundary stamp that does not come from a main chunk", function()
            currentSourceFile = "Localization/lookups/lookupZones.lua"
            QuestieSmazakLoader:ImportModule("l10n")
            AdvanceClock(3)

            _G.debugstack = function()
                return "[Interface/AddOns/QuestieSmazak/Modules/Foo.lua]:10: in function DoWork\n"
            end
            QuestieSmazakLoader:StampLoadBoundary()
            AdvanceClock(4)

            _G.debugstack = function()
                return "[Interface/AddOns/QuestieSmazak/Modules/Beta.lua]:3: in main chunk\n"
            end
            QuestieSmazakLoader:CreateModule("Beta")

            -- The runtime stamp neither closed the interval nor opened one of its own.
            assert.are_same(7, QuestieSmazakLoader.loadTimings["Localization/lookups/lookupZones.lua"])
        end)

        it("accumulates repeated intervals for the same file", function()
            currentSourceFile = "Modules/Alpha.lua"
            QuestieSmazakLoader:CreateModule("Alpha")
            AdvanceClock(10)
            QuestieSmazakLoader:ImportModule("Something")
            AdvanceClock(5)
            currentSourceFile = "Modules/Beta.lua"
            QuestieSmazakLoader:CreateModule("Beta")

            assert.are_same(15, QuestieSmazakLoader.loadTimings["Modules/Alpha.lua"])
        end)

        it("times ImportModule as well as CreateModule", function()
            currentSourceFile = "Modules/Alpha.lua"
            QuestieSmazakLoader:ImportModule("Alpha")
            AdvanceClock(7)
            currentSourceFile = "Modules/Beta.lua"
            QuestieSmazakLoader:ImportModule("Beta")

            assert.are_same(7, QuestieSmazakLoader.loadTimings["Modules/Alpha.lua"])
        end)

        it("falls back to a named bucket when a main chunk yields no usable path", function()
            _G.debugstack = function()
                return "[string \"a loaded chunk\"]:1: in main chunk\n"
            end
            QuestieSmazakLoader:CreateModule("Alpha")
            AdvanceClock(3)
            QuestieSmazakLoader:CreateModule("Beta")

            assert.are_same(3, QuestieSmazakLoader.loadTimings["(unknown source)"])
        end)

        it("closes the final file's interval on FinishLoadTimings", function()
            currentSourceFile = "QuestieSmazak.lua"
            QuestieSmazakLoader:CreateModule("Last")
            AdvanceClock(25)

            QuestieSmazakLoader:FinishLoadTimings()

            assert.are_same(25, QuestieSmazakLoader.loadTimings["QuestieSmazak.lua"])
        end)

        it("stops timing after FinishLoadTimings", function()
            currentSourceFile = "QuestieSmazak.lua"
            QuestieSmazakLoader:CreateModule("Last")
            QuestieSmazakLoader:FinishLoadTimings()
            local closedTotal = QuestieSmazakLoader.loadTimings["QuestieSmazak.lua"]

            AdvanceClock(100)
            QuestieSmazakLoader:ImportModule("AfterLoad")

            assert.are_same(closedTotal, QuestieSmazakLoader.loadTimings["QuestieSmazak.lua"])
        end)

        it("records allocation alongside elapsed time", function()
            local allocatedKilobytes = 0
            _G.collectgarbage = function(option)
                if option == "count" then return allocatedKilobytes end
                return 0
            end
            currentSourceFile = "Modules/Alpha.lua"
            QuestieSmazakLoader:CreateModule("Alpha")
            allocatedKilobytes = 2048

            currentSourceFile = "Modules/Beta.lua"
            QuestieSmazakLoader:CreateModule("Beta")

            assert.are_same(2048, QuestieSmazakLoader.loadMemory["Modules/Alpha.lua"])
        end)

        it("reports a negative allocation when the collector freed memory", function()
            local allocatedKilobytes = 5000
            _G.collectgarbage = function(option)
                if option == "count" then return allocatedKilobytes end
                return 0
            end
            currentSourceFile = "Modules/Alpha.lua"
            QuestieSmazakLoader:CreateModule("Alpha")
            allocatedKilobytes = 1000

            currentSourceFile = "Modules/Beta.lua"
            QuestieSmazakLoader:CreateModule("Beta")

            assert.are_same(-4000, QuestieSmazakLoader.loadMemory["Modules/Alpha.lua"])
        end)

        it("ignores a call made from inside a function", function()
            currentSourceFile = "Modules/Alpha.lua"
            QuestieSmazakLoader:CreateModule("Alpha")
            AdvanceClock(40)

            -- An init routine or lazy import resolving a module at runtime, rather than a file registering
            -- itself. Stamping here would close Alpha's interval and charge what follows to the caller.
            _G.debugstack = function()
                return "[Interface/AddOns/QuestieSmazak/Modules/Beta.lua]:120: in function 'Initialize'\n"
            end
            QuestieSmazakLoader:ImportModule("Beta")

            assert.is_nil(QuestieSmazakLoader.loadTimings["Modules/Beta.lua"])
        end)

        it("leaves the loading file's interval open across a runtime import", function()
            currentSourceFile = "Modules/Alpha.lua"
            QuestieSmazakLoader:CreateModule("Alpha")
            AdvanceClock(40)
            _G.debugstack = function()
                return "[Interface/AddOns/QuestieSmazak/Modules/Beta.lua]:120: in function 'Initialize'\n"
            end
            QuestieSmazakLoader:ImportModule("Beta")
            AdvanceClock(10)

            QuestieSmazakLoader:FinishLoadTimings()

            -- All 50ms belongs to the file that was loading, not split with the runtime caller.
            assert.are_same(50, QuestieSmazakLoader.loadTimings["Modules/Alpha.lua"])
        end)

        it("ignores a tail call, whose frame the interpreter has already discarded", function()
            currentSourceFile = "Modules/Alpha.lua"
            QuestieSmazakLoader:CreateModule("Alpha")
            AdvanceClock(30)
            _G.debugstack = function()
                return "[tail call]: ?\n"
            end
            QuestieSmazakLoader:ImportModule("Beta")
            QuestieSmazakLoader:FinishLoadTimings()

            assert.are_same(30, QuestieSmazakLoader.loadTimings["Modules/Alpha.lua"])
        end)

        it("still registers modules normally while timing", function()
            local module = QuestieSmazakLoader:CreateModule("Timed")

            assert.are_equal(module, QuestieSmazakLoader:ImportModule("Timed"))
            assert.are_same("table", type(module.private))
        end)
    end)
end)
