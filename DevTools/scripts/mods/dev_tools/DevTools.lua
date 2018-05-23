--[[
	author: FireSiku
	-----
	Copyright 2018 FireSiku
	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	-----
--]]

local mod = get_mod("DevTools")

local mod_data = {}
mod_data.name = "DevTools" -- Readable mod name
mod_data.description = "Provide easy access to some slash commands and other utilities that may be useful while developping mods." ..
						"No mods should ever depend on the functionality given by this mod. " -- Readable mod description
mod_data.is_togglable = false -- If the mod can be enabled/disabled
mod_data.is_mutator = false -- If the mod is mutator
mod_data.options_widgets = {
}

local iter = 1000
local clock = os.clock

local function get_ms(start_time, end_time)
    local ms = (end_time - start_time) * 1000
    return string.format("%.3f", ms):gsub("%.?0+$", "")
end

local mods = {}
for i = 1, 5 do mods[i] = new_mod("HookTestingMod"..i) end

function A()
    mod:echo("A Call")
    return 1
end

local function hooktest_DeclareGlobal()
    function NewGlobal()
        mod:echo("NewGlobal Called")
        return 1
    end

    mods[1]:hook("NewGlobal", function(func)
        mod:echo("Hook")
        return func()
    end)

    NewGlobal()
    --Result: No hook created.
end

local function hooktest_ModifyReturnParameters()
    mods[1]:hook("A", function(func)
        mod:echo("Prehook")
        return func()
    end)
    -- mods[2]:hook("A", function(func)
    --     mod:echo("Prehook stuff. Dont care about func")
    --     func()
    -- end)
    mods[3]:hook("A", function(func)
        func()
        mod:echo("Class Posthook")
    end)
    -- mods[4]:hook("A", function(func)
    --     mod:echo("LateRaw")
    --     return 3
    -- end)

    local ret = A()
    mod:echo("Final Result: %s", ret)
    --Result: Call, Hook3 returned 1, Final is nil.
    --Result with Prehook: Hook2 returned nil, Hook3 said it was nil, Final is nil.
    --Result with Late Raw: Hook4 returned 3. Final is 3.
    --Result with Early Raw: Hook1 was called. Hook3 said it returned 3. Final result: nil
end

local function test_hooking()
    hooktest_ModifyReturnParameters()
end

local function test_log()
    mod:echo("Test Echo")
    mod:warning("Test Warning")
    mod:error("Test Error")
    mod:info("Test Info")
    mod:debug("Test Debug")
end

-- ##########################################################
-- ################### Script ###############################

mod:initialize_data(mod_data)
mod:command("hook", "Test arbitrary stuff", test_hooking)
mod:command("log", "Test Logging", test_log)