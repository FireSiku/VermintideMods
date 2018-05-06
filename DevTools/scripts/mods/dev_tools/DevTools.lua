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

-- Placeholder until I find a better way to get a path.
local DEFAULT_PATH = "F:\\Steam\\SteamApps\\common\\Warhammer End Times Vermintide\\binaries\\dev"

-- ##########################################################
-- ############### Local Functions ##########################

local function do_file(...)
	mod:echo(...)
end

-- ##########################################################
-- #################### Hooks ###############################

mod:hook("", function (func, ...)
	
	-- Original function
	local result = func(...)
	return result
end)

-- ##########################################################
-- ################### Callback #############################


-- ##########################################################
-- ################### Script ###############################

mod:initialize_data(mod_data)
mod:command("dofile", "Execute an arbitrary file", do_file)