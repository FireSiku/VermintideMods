local mod_name = BotAmmoPing
-- Mod to accompany Bot Improvements Mod, this mod will make bots interact with pinged ammo crates in a more timely manner.
--      It will also make them able to loot small ammo if all players are currently full.

----------------------------------------------------------------------
-- Options
----------------------------------------------------------------------

local OPTIONS = {
	LOOT_AMMO_CRATE = {
		["save"] = "cb_bot_ammo_loot_crate",
		["widget_type"] = "stepper",
		["text"] = "Bots Pick Up Pinged Ammo Crates",
		["tooltip"] = "Bots Pick Up Pinged Ammo Crates\n" ..
			"Bots will refill their ammo when a human player is near a pinged ammo crate.",
		["value_type"] = "boolean",
		["options"] = {
			{text = "Off", value = false},
			{text = "On", value = true}
		},
		["default"] = 2, -- Default second option is enabled. In this case On
	},
	LOOT_AMMO_SMALL = {
		["save"] = "cb_bot_ammo_loot_small",
		["widget_type"] = "stepper",
		["text"] = "Bots Pick Up Pinged Small Ammo",
		["tooltip"] = "Bots Pick Up Pinged Small Ammo\n" ..
			"Bots will pick up a small ammo refill when a human player pings it. " ..
			"Bots will only pick up ammo when no human players are missing ammo.",
		["value_type"] = "boolean",
		["options"] = {
			{text = "Off", value = false},
			{text = "On", value = true}
		},
		["default"] = 2, -- Default second option is enabled. In this case On
	},
}

local get = function(data)
	return Application.user_setting(data.save)
end

--- options
local function create_options()
	Mods.option_menu:add_group("bot_ammo","Bots Ammo Improvements")

	Mods.option_menu:add_item("bot_ammo", OPTIONS.LOOT_AMMO_CRATE, true)
	Mods.option_menu:add_item("bot_ammo", OPTIONS.LOOT_AMMO_SMALL, true)
end

safe_pcall(create_options)

----------------------------------------------------------------------
-- Helper Functions
----------------------------------------------------------------------

--Insert InteractAction into BotBehaviors for looting ammo. Taken from BotImprovements, but hooking their existing function led to trouble.
local insert_bt_node = function(lua_node)
	local lua_tree = BotBehaviors.default
	for i = 1, math.huge, 1 do
		if not lua_tree[i] then
			EchoConsole("ERROR: insertion point not found")
			return
		elseif lua_tree[i].name == lua_node.name then
			--EchoConsole("ERROR: bt node " .. lua_node.name .. " already inserted")
			return
		elseif lua_tree[i].name == "in_combat" then
			table.insert(lua_tree, i, lua_node)
			return
		end
	end
end

-- Helper function to retrieve the ammo extension from the given slot data. Taken from AmmoMeters.lua in QoL.
local function get_ammo_extension(slot_data)
	if slot_data then
		local right_unit = slot_data.right_unit_1p
		local left_unit = slot_data.left_unit_1p
		return (right_unit and ScriptUnit.has_extension(right_unit, "ammo_system")) or
			(left_unit and ScriptUnit.has_extension(left_unit, "ammo_system"))
	end
	return nil
end

--[[
	Returns the current ammo and the maximum ammo from the given ammo.  Based on
	SimpleInventoryExtension.current_ammo_status, which we can't use because it doesn't give the max
    ammo we want (it gives the 'raw' max ammo for the weapon type without the Ammo Holder trait).
	Taken from AmmoMeters.lua in QoL.
	
	Modified to fetch inventory and bot status from unit. Also do not return info if player is waiting for respawn 
--]]
local function current_ammo_status(player_unit)
	local inventory_ext = ScriptUnit.has_extension(player_unit, "inventory_system")
	local status_ext = ScriptUnit.has_extension(player_unit, "status_system")
	local is_dead = status_ext:is_dead()
	local is_respawned = status_ext:is_ready_for_assisted_respawn()

	-- self._customhud_is_dead and not self._customhud_player_unit_missing and not self._customhud_has_respawned

	if inventory_ext and status_ext and not is_dead and not is_respawned then
		local slot_data = inventory_ext:equipment().slots["slot_ranged"]
		if slot_data then
			local item_data = slot_data.item_data
			local item_template = BackendUtils.get_item_template(item_data)
			local ammo_data = item_template.ammo_data

			if ammo_data then
				local ammo_extn = get_ammo_extension(slot_data)
				if ammo_extn then
					return ammo_extn:total_remaining_ammo(), ammo_extn.max_ammo
				end

				if slot_data.ammo_extn then
					local max_ammo = ammo_data.max_ammo
					local is_bot = inventory_ext.player.bot_player
					for _, trait_name in pairs(slot_data.item_data.traits) do
						if trait_name == "ranged_weapon_total_ammo_tier1" and not is_bot then
							max_ammo = math.ceil(max_ammo * 1.3)
						end
					end
					return slot_data.ammo_extn.available_ammo, max_ammo
				end
			end
		end
	end
	return nil, nil
end

local function distance_from_object(player_unit, object)
	local player_pos = POSITION_LOOKUP[player_unit]
	local object_pos = POSITION_LOOKUP[object]
	if player_pos and object_pos then
		return Vector3.distance(player_pos, object_pos)
	end
end

local function unit_has_full_ammo(player_unit)
	local inventory_ext = ScriptUnit.has_extension(player_unit, "inventory_system")
	if inventory_ext and inventory_ext.has_full_ammo then
		return inventory_ext:has_full_ammo()
	end
	return true
end

----------------------------------------------------------------------
-- Main Functions
----------------------------------------------------------------------

local pinged_ammo
local pinged_ammo_small
function BTConditions.can_loot_pinged_ammo(blackboard)
	
    -- Avoids possible crash
	if blackboard.unit == nil or not blackboard.inventory_extension then
		return false
	end
	
	local self_unit = blackboard.unit

	-- If bot is been attacked
	for _, enemy_unit in pairs(blackboard.proximite_enemies) do
		if Unit.alive(enemy_unit) and Unit.get_data(enemy_unit, "blackboard").target_unit == self_unit then
			return false
		end
	end
	
	if pinged_ammo then -- Ammo Crates
		local player_near_ammo = false
		local players_full_ammo = true
		for id, player in pairs(Managers.player:human_players()) do
			local distance = distance_from_object(player.player_unit, pinged_ammo)
			if player and distance and 3.5 > distance then
				player_near_ammo = true
			end
		end

		if not player_near_ammo then 
			return false
		end

		if unit_has_full_ammo(self_unit) then
			return false
		end
		
		local distance = distance_from_object(self_unit, pinged_ammo)
		if distance and distance > 5.5 then 
			return false 
		end

		blackboard.interaction_unit = pinged_ammo
		return true
	end
	
	if pinged_ammo_small then -- Single-Use Ammo
		if not POSITION_LOOKUP[pinged_ammo_small] then
			pinged_ammo_small = nil
			return false
		end

		local curr_ammo, max_ammo = current_ammo_status(self_unit)
		if not curr_ammo or not max_ammo then
			return false 
		end

		-- Do not let bot loot ammo if a player could use it
		for id, player in pairs(Managers.player:human_players()) do
			if player and not unit_has_full_ammo(player.player_unit) then
				return false
			end
		end

		local distance = distance_from_object(self_unit, pinged_ammo_small)
		if distance and distance > 5.5 then
			return false 
		end

		local ammo_perc = curr_ammo/max_ammo
		for i, player in pairs(Managers.player:bots()) do
			local player_ammo, player_max = current_ammo_status(player.player_unit)
			if player_ammo and player_max and player_ammo/player_max < ammo_perc then
				return false
			end
		end

		blackboard.interaction_unit = pinged_ammo_small
		return true
	end

    return false
end

insert_bt_node({
	"BTBotInteractAction",
	condition = "can_loot_pinged_ammo",
	name = "loot_pinged_ammo"
})

Mods.hook.set(mod_name, "PingTargetExtension.set_pinged", function (func, self, pinged)
    if pinged then
		local pickup_extension = ScriptUnit.has_extension(self._unit, "pickup_system")
        local pickup_settings = pickup_extension and pickup_extension:get_pickup_settings()
        
		if pickup_extension and get(OPTIONS.LOOT_AMMO_CRATE) and 
				pickup_extension.pickup_name == "all_ammo" then
			pinged_ammo = self._unit
		else
			pinged_ammo = nil
		end

		if pickup_extension and get(OPTIONS.LOOT_AMMO_SMALL) and
				pickup_extension.pickup_name == "all_ammo_small" then
			pinged_ammo_small = self._unit
		else
			pinged_ammo_small = nil
		end

	elseif self._unit == pinged_ammo then
		pinged_ammo = nil
	elseif self._unit == pinged_ammo_small then
		pinged_ammo_small = nil
	end

	return func(self, pinged)
end)