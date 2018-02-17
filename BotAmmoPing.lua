-- Mod to accompany Bot Improvements Mod, this mod will make bots interact with pinged ammo crates in a more timely manner.
--      It will also make them able to loot small ammo if all players are currently full.

local mod_name = BotAmmoPing

--[[
    Helper function to retrieve the ammo extension from the given slot data.
    Taken from AmmoMeters.lua in QoL.
--]]
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
--]]
local function current_ammo_status(inventory_extn, is_bot)
	local slot_data = inventory_extn:equipment().slots["slot_ranged"]
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
				for _, trait_name in pairs(slot_data.item_data.traits) do
					if trait_name == "ranged_weapon_total_ammo_tier1" and not is_bot then
						max_ammo = math.ceil(max_ammo * 1.3)
					end
				end
				return slot_data.ammo_extn.available_ammo, max_ammo
			end
		end
	end
	return nil, nil
end

local pinged_ammo
Mods.hook.set(mod_name, "BTConditions.can_loot_pinged_item", function (func, blackboard)
    -- Avoids possible crash
	if blackboard.unit == nil then
		return false
	end
	
	local inventory_extn = blackboard.inventory_extension
	local is_bot = inventory_extn.player.bot_player

	if pinged_ammo and inventory_extn then
		local curr_ammo, max_ammo = current_ammo_status(inventory_extn, is_bot)
		
		local player_near_ammo = false
		local players_full_ammo = true
		local ammo_position = POSITION_LOOKUP[pinged_ammo]
		for id, player in pairs(Managers.player:human_players()) do
			if ammo_position and player.player_unit and (3.5 > Vector3.distance(POSITION_LOOKUP[player.player_unit], ammo_position)) then
				player_near_ammo = true
			end
			-- Only let bots loot small ammo if all players are full.
			if players_full_ammo then
				local player_inventory_ext = ScriptUnit.extension(player.player_unit, "inventory_system")
				local player_ammo, player_max = current_ammo_status(player_inventory_ext, false)
				if player_ammo < player_max then 
					players_full_ammo = false 
				end
			end
		end

		--if local player_inventory_ext = ScriptUnit.extension(player.player_unit, "inventory_system")

		if is_bot and player_near_ammo and curr_ammo < max_ammo then
			blackboard.interaction_unit = pinged_ammo
			return true
		end
    end

    return func(blackboard)
end)

Mods.hook.set(mod_name, "PingTargetExtension.set_pinged", function (func, self, pinged)
    if pinged then
		local pickup_extension = ScriptUnit.has_extension(self._unit, "pickup_system")
        local pickup_settings = pickup_extension and pickup_extension:get_pickup_settings()
        
        if pickup_extension and pickup_extension.pickup_name =="all_ammo" then
            EchoConsole("Pinged Ammo Crate")
            pinged_ammo = self._unit
        end

	elseif self._unit == pinged_ammo then
		pinged_ammo = nil
	end

	return func(self, pinged)
end)