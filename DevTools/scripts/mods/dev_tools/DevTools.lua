local mod = get_mod("DevTools")

local mod_data = {}
mod_data.name = "DevTools" -- Readable mod name
mod_data.description = "Testing Playground" -- readable description.
mod_data.is_togglable = false -- If the mod can be enabled/disabled
mod_data.is_mutator = false -- If the mod is mutator
mod_data.options_widgets = {
}

-- local iter = 1000
-- local clock = os.clock

-- local function get_ms(start_time, end_time)
--     local ms = (end_time - start_time) * 1000
--     return string.format("%.3f", ms):gsub("%.?0+$", "")
-- end

local mods = {}
for i = 1, 7 do mods[i] = new_mod("HookTestingMod"..i) end

local function contains(t, num)
    for i = 1, #t do
        if t[i] == num then
            return true
        end
    end
end

--luacheck: globals A B
rawset(_G, "A", {
    A = 3,
    B = function(self, str)
        mod:echo("A Call: %s", str)
    end,
})
rawset(_G, "B", {
    A = 3,
    B = function(self, str)
        mod:echo("B Call: %s", str)
    end,
})

-- ####################################################################################################################
-- ##### VMF Old Hook System ##########################################################################################
-- ####################################################################################################################
local hooks_loaded = false
local function load_hooks()
    mods[1]:hook("A.B", function(func, self, str)
        mod:echo("E-Fixing Weapons.")
    end)

    mods[2]:hook("A.B", function(func, self, str)
        if str == "ping" then
            mod:echo("E-Modding Value")
            str = "pong"
        end
        func(self, str)
    end)

    mods[3]:hook("A.B", function(func, self, str)
        func(self, str)
        mod:echo("E-After Hook: %s (%d)", str, self.A)
    end)

    mods[4]:hook("A.B", function(func, self, str)
        mod:echo("Before Hook: %s (%s)", str, self.A)
        if not self.A then mod:echo("Cant find Self.A 1") end
        self.A = 4
        if not self.A then mod:echo("Cant find Self.A 2") end
        func(self, str)
    end)

    mods[5]:hook("A.B", function(func, self, str)
        mod:echo("L-Early Print: %s (%d)", str, self.A)
        func(self, str)
        mod:echo("L-After Hook: %s (%d)", str, self.A)
    end)

    mods[6]:hook("A.B", function(func, self, str)
        if str == "ping" then
            mod:echo("L-Modding value.")
            str = "pong"
        end
        func(self, str)
    end)

    mods[7]:hook("A.B", function(func, self, str)
        mod:echo("L-Fixing Weapons.")
    end)
    hooks_loaded = true
end

-- ####################################################################################################################
-- ##### VMF New Hook System ##########################################################################################
-- ####################################################################################################################
local newhooks_loaded = false
local function load_newhooks()
    mods[1].obj = mods[1]:new_hook("B.B", function(func, self, str)
        mod:echo("E-Fixing Weapons.")
    end)

    mods[2].obj = mods[2]:new_hook("B.B", function(func, self, str)
        if str == "ping" then
            mod:echo("E-Modding Value")
            str = "pong"
        end
        func(self, str)
    end)

    mods[3].obj = mods[3]:new_hook("B.B", function(func, self, str)
        func(self, str)
        mod:echo("E-After Hook: %s (%d)", str, self.A)
    end)

    mods[4].obj = mods[4]:new_hook("B.B", function(func, self, str)
        mod:echo("Before Hook: %s (%s)", str, self.A)
        if not self.A then mod:echo("Cant find Self.A 1") end
        self.A = 4
        if not self.A then mod:echo("Cant find Self.A 2") end
        func(self, str)
    end)

    mods[5].obj = mods[5]:new_hook("B.B", function(func, self, str)
        mod:echo("L-Early Print: %s (%d)", str, self.A)
        func(self, str)
        mod:echo("L-After Hook: %s (%d)", str, self.A)
    end)

    mods[6].obj = mods[6]:new_hook("B.B", function(func, self, str)
        if str == "ping" then
            mod:echo("L-Modding value.")
            str = "pong"
        end
        func(self, str)
    end)

    mods[7].obj = mods[7]:new_hook("B.B", function(func, self, str)
        mod:echo("L-Fixing Weapons.")
    end)
    newhooks_loaded = true
end

-- ####################################################################################################################
-- ##### VMF New Hook System - Alt Setup ##############################################################################
-- ####################################################################################################################
local althooks_loaded = false
local function load_althooks()
    -- mods[1].obj = mods[1]:new_rawhook("B.B", function(self, str)
    --     mod:echo("E-Fixing Weapons.")
    -- end)

    mods[2].obj = mods[2]:new_hook("B.B", function(func, self, str)
        if str == "ping" then
            mod:echo("E-Modding Value")
            str = "pong"
        end
        func(self, str)
    end)

    mods[3].obj = mods[3]:new_after("B.B", function(self, str)
        mod:echo("E-After Hook: %s (%d)", str, self.A)
    end)

    mods[4].obj = mods[4]:new_before("B.B", function(self, str)
        mod:echo("Before Hook: %s (%s)", str, self.A)
        self.A = 4
    end)

    mods[5].obj = mods[5]:new_hook("B.B", function(func, self, str)
        mod:echo("L-Early Print: %s (%d)", str, self.A)
        func(self, str)
        mod:echo("L-After Hook: %s (%d)", str, self.A)
    end)

    mods[6].obj = mods[6]:new_hook("B.B", function(func, self, str)
        if str == "ping" then
            mod:echo("L-Modding value.")
            str = "pong"
        end
        func(self, str)
    end)

    mods[7].obj = mods[7]:new_rawhook("B.B", function(func, self, str)
        mod:echo("L-Fixing Weapons.")
    end)
    althooks_loaded = true
end

-- ####################################################################################################################
-- ##### Functions calls ##############################################################################################
-- ####################################################################################################################

local function test_hooking(value, nums)
    if not hooks_loaded and not newhooks_loaded then
        load_hooks()
    end

    for i = 1, 7 do
        mods[i]:disable_all_hooks()
    end
    if nums then
        for i = 1, #nums do
            local n = tonumber(nums:sub(i,i))
            mods[n]:enable_all_hooks()
        end
    end

    A.A = 3
    A:B(value)
end

local function test_newhooking(value, nums)
    if not hooks_loaded and not newhooks_loaded and not althooks_loaded then load_newhooks() end
    for i = 1, 7 do
        mods[i].obj:disable()
    end
    if nums then
        for i = 1, #nums do
            local n = tonumber(nums:sub(i,i))
            mods[n].obj:enable()
        end
    end

    B.A = 3
    B:B(value)
end

local function test_althooking(value, nums)
    if not hooks_loaded and not newhooks_loaded and not althooks_loaded then load_althooks() end
    for i = 1, 7 do
        if mods[i].obj then
            mods[i].obj:disable()
        end
    end
    if nums then
        for i = 1, #nums do
            local n = tonumber(nums:sub(i,i))
            mods[n].obj:enable()
        end
    end

    B.A = 3
    B:B(value)
end

local function check_global(str)
    mod:echo("Checking %s", str)
    if _G[str] then
        mod:echo("%s exists", str)
    end
end

-- ####################################################################################################################
-- ##### New Object ###################################################################################################
-- ####################################################################################################################

local function hook_class()
    
end

-- ##########################################################
-- ################### Commands #############################

-- mod:command("hook", "Test old hook system", test_hooking)
-- mod:command("new", "Test new hook system", test_newhooking)
-- mod:command("alt", "Test new hook system (alt)", test_althooking)
mod:command("global", "Check if a variable is global", check_global)
mod:command("class", "Check if possible to hook an instance", hook_class)