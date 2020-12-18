realdoors.connection_rules = {
	{x = 0,  y = 0,  z = -1},
	{x = 1,  y = 0,  z = 0},
	{x = -1, y = 0,  z = 0},
	{x = 0,  y = 0,  z = 1},
	{x = 1,  y = 1,  z = 0},
	{x = 1,  y = -1, z = 0},
	{x = -1, y = 1,  z = 0},
	{x = -1, y = -1, z = 0},
	{x = 0,  y = 1,  z = 1},
	{x = 0,  y = -1, z = 1},
	{x = 0,  y = 1,  z = -1},
	{x = 0,  y = -1, z = -1},
	{x = 0,  y = -1, z = 0},
	
	{x = 0,  y = 0,  z = -2},
	{x = 2,  y = 0,  z = 0},
	{x = -2, y = 0,  z = 0},
	{x = 0,  y = 0,  z = 2},
	{x = 2,  y = 2,  z = 0},
	{x = 2,  y = -2, z = 0},
	{x = -2, y = 2,  z = 0},
	{x = -2, y = -2, z = 0},
	{x = 0,  y = 2,  z = 2},
	{x = 0,  y = -2, z = 2},
	{x = 0,  y = 2,  z = -2},
	{x = 0,  y = -2, z = -2},
	{x = 0,  y = -2, z = 0},
}

realdoors.keyswitch_formspec = "size[10,3]" ..
"list[context;keyslot;1,1;1,1]" ..
"button[3,1;3,1;trigger;Use key]" ..
"list[current_player;main;1,2;9,1]"

realdoors.cardreader_formspec = "size[13,3]" ..
"list[context;cardslot;1,1;1,1]" ..
"button[3,1;3,1;trigger;Use keycard]" ..
"list[context;cardslot;7,1;1,1;1]" ..
"button[10,0;3,1;cardadd;Add card]" ..
"button[10,1;3,1;cardrm;Remove card]" ..
"button[10,2;3,1;cardrst;Remove all cards]" ..
"list[current_player;main;1,2;9,1]"

realdoors.codepad_formspec = "size[5,6]" ..
"button[1,2;1,1;one;1]button[2,2;1,1;two;2]button[3,2;1,1;three;3]" ..
"button[1,3;1,1;four;4]button[2,3;1,1;five;5]button[3,3;1,1;six;6]" ..
"button[1,4;1,1;seven;7]button[2,4;1,1;eight;8]button[3,4;1,1;nine;9]" ..
"button[1,5;1,1;clear;C]button[2,5;1,1;zero;0]button[3,5;1,1;submit;E]"

realdoors.saferoute_formspec = "size[10,5]" ..
"list[context;keyslot;1,1;1,1]" ..
"button[3,1;3,1;trigger;Use key]" ..
"button[3,3;3,1;alarm;Trigger alarm]" ..
"list[current_player;main;1,2;9,1]"

realdoors.keyswitch_formspec_handler = function(pos, fields, sender)
	local meta = minetest.get_meta(pos)
	if not fields.trigger then return end
	local inv = minetest.get_inventory({type = "node", pos = pos})
	local keystack = inv:get_stack("keyslot", 1)
	if keystack:get_name() ~= "realdoors:key" then return end
	local key = keystack:get_meta():get_string("shape")
	if meta:get_string("key") == "" then
		meta:set_string("key", key)
		minetest.chat_send_player(sender:get_player_name(), "This switch has been linked to key " .. key)
		return
	end
	if key == meta:get_string("key") then
		mesecon.receptor_on(pos, realdoors.connection_rules)
		minetest.after(1, realdoors.keyswitch_formspec_handler_2, pos)
	else
		minetest.chat_send_player(sender:get_player_name(), "Your key does not match the lock")
	end
end
realdoors.keyswitch_formspec_handler_2 = function(pos)
	mesecon.receptor_off(pos, realdoors.connection_rules)
end

realdoors.cardreader_formspec_handler = function(pos, fields, sender)
	local meta = minetest.get_meta(pos)
	local inv = minetest.get_inventory({type = "node", pos = pos})
	local cardstack = inv:get_stack("cardslot", 1)
	if cardstack:get_name() ~= "realdoors:card" then return end
	local key = cardstack:get_meta():get_string("id")
	
	local reqkeys = minetest.deserialize(meta:get_string("keys")) or {}
	
	if fields.cardadd then
		local newstack = inv:get_stack("cardslot", 2)
		if newstack:get_name() ~= "realdoors:card" then return end
		if key == meta:get_string("key") then
			table.insert(reqkeys, newstack:get_meta():get_string("id"))
			meta:set_string("keys", minetest.serialize(reqkeys))
			minetest.chat_send_player(sender:get_player_name(), "The following card has been added: " .. newstack:get_meta():get_string("id"))
			minetest.sound_play("lockbeep_ok", {
				pos = pos,
				max_hear_distance = 8,
				gain = 4.0,
			})
		else
			minetest.chat_send_player(sender:get_player_name(), "Your keycard is not the correct master card")
			minetest.sound_play("lockbeep_error", {
				pos = pos,
				max_hear_distance = 8,
				gain = 4.0,
			})
		end
		return
	end
	if fields.cardrm then
		local newstack = inv:get_stack("cardslot", 2)
		if newstack:get_name() ~= "realdoors:card" then return end
		if key == meta:get_string("key") then
			reqkeys = table_remove(reqkeys, newstack:get_meta():get_string("id"))
			meta:set_string("keys", minetest.serialize(reqkeys))
			minetest.chat_send_player(sender:get_player_name(), "The following card has been removed: " .. newstack:get_meta():get_string("id"))
			minetest.sound_play("lockbeep_ok", {
				pos = pos,
				max_hear_distance = 8,
				gain = 4.0,
			})
		else
			minetest.chat_send_player(sender:get_player_name(), "Your keycard is not the correct master card")
			minetest.sound_play("lockbeep_error", {
				pos = pos,
				max_hear_distance = 8,
				gain = 4.0,
			})
		end
		return
	end
	if fields.cardrst then
		if key == meta:get_string("key") then
			reqkeys = {}
			meta:set_string("keys", minetest.serialize(reqkeys))
			minetest.chat_send_player(sender:get_player_name(), "All cards except for the master card have been removed")
			minetest.sound_play("lockbeep_ok", {
				pos = pos,
				max_hear_distance = 8,
				gain = 4.0,
			})
		else
			minetest.chat_send_player(sender:get_player_name(), "Your keycard is not the correct master card")
			minetest.sound_play("lockbeep_error", {
				pos = pos,
				max_hear_distance = 8,
				gain = 4.0,
			})
		end
		return
	end
	if not fields.trigger then return end
	if meta:get_string("key") == "" then
		meta:set_string("key", key)
		minetest.chat_send_player(sender:get_player_name(), "This reader has been linked to card " .. key)
		minetest.sound_play("lockbeep_ok", {
				pos = pos,
				max_hear_distance = 8,
				gain = 4.0,
			})
		return
	end
	if table_contains(reqkeys, key) then
		mesecon.receptor_on(pos, realdoors.connection_rules)
		minetest.sound_play("lockbeep_ok", {
			pos = pos,
			max_hear_distance = 8,
			gain = 4.0,
		})
		minetest.after(1, realdoors.cardreader_formspec_handler_2, pos)
	else
		minetest.chat_send_player(sender:get_player_name(), "Your keycard is not valid")
		minetest.sound_play("lockbeep_error", {
			pos = pos,
			max_hear_distance = 8,
			gain = 4.0,
		})
	end
end
realdoors.cardreader_formspec_handler_2 = function(pos)
	mesecon.receptor_off(pos, realdoors.connection_rules)
end

realdoors.codepad_formspec_handler = function(pos, fields, sender)
	local meta = minetest.get_meta(pos)
	local entered = meta:get_string("entered")
	local numberstrings = {"zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"}
	for i = 0, 9 do
		if fields[numberstrings[i + 1]] then
			entered = entered .. tostring(i)
			minetest.sound_play("lockbeep_keypress", {
				pos = pos,
				max_hear_distance = 8,
				gain = 4.0,
			})
		end
	end
	if fields.clear then
		if meta:get_string("setup") == "auth" or meta:get_string("setup") == "menu" then meta:set_string("setup", "no") end
		minetest.sound_play("lockbeep_keypress", {
			pos = pos,
			max_hear_distance = 8,
			gain = 4.0,
		})
		entered = ""
	end
	if fields.submit then
		if entered == "" and meta:get_string("setup") ~= "auth" and meta:get_string("setup") ~= "menu" then
			meta:set_string("setup", "auth")
			minetest.sound_play("lockbeep_keypress", {
				pos = pos,
				max_hear_distance = 8,
				gain = 4.0,
			})
		elseif meta:get_string("setup") == "auth" then
			if meta:get_string("code") == "" or entered == meta:get_string("code") then
				meta:set_string("setup", "menu")
				minetest.sound_play("lockbeep_ok", {
					pos = pos,
					max_hear_distance = 8,
					gain = 4.0,
				})
			else
				minetest.sound_play("lockbeep_error", {
					pos = pos,
					max_hear_distance = 8,
					gain = 4.0,
				})
			end
		elseif meta:get_string("setup") == "menu" then
			meta:set_string("code", entered)
			meta:set_string("setup", "no")
			minetest.sound_play("lockbeep_ok", {
				pos = pos,
				max_hear_distance = 8,
				gain = 4.0,
			})
		elseif meta:get_string("code") == "" or entered == meta:get_string("code") then
			mesecon.receptor_on(pos, realdoors.connection_rules)
			minetest.sound_play("lockbeep_ok", {
				pos = pos,
				max_hear_distance = 8,
				gain = 4.0,
			})
			minetest.after(1, realdoors.codepad_formspec_handler_2, pos)
		else
			minetest.sound_play("lockbeep_error", {
				pos = pos,
				max_hear_distance = 8,
				gain = 4.0,
			})
		end
		entered = ""
	end
	meta:set_string("entered", entered)
end
realdoors.codepad_formspec_handler_2 = function(pos)
	mesecon.receptor_off(pos, realdoors.connection_rules)
end

realdoors.saferoute_formspec_handler = function(pos, fields, sender)
	local meta = minetest.get_meta(pos)
	if fields.alarm and meta:get_string("alarm") == "" then
		meta:set_string("alarm", "yes")
		mesecon.receptor_on(pos, realdoors.connection_rules)
		local node = minetest.get_node(pos)
		node.name = "realdoors:saferoute_alarm"
		minetest.swap_node(pos, node)
		return
	end
	if not fields.trigger then return end
	local inv = minetest.get_inventory({type = "node", pos = pos})
	local keystack = inv:get_stack("keyslot", 1)
	if keystack:get_name() ~= "realdoors:key" then return end
	local key = keystack:get_meta():get_string("shape")
	if meta:get_string("key") == "" then
		meta:set_string("key", key)
		minetest.chat_send_player(sender:get_player_name(), "This SafeRoute has been linked to key " .. key)
		return
	end
	if key == meta:get_string("key") then
		meta:set_string("alarm", "")
		local node = minetest.get_node(pos)
		if node.name == "realdoors:saferoute_alarm" then
			node.name = "realdoors:saferoute"
			minetest.swap_node(pos, node)
		end
		mesecon.receptor_on(pos, realdoors.connection_rules)
		minetest.after(1, realdoors.saferoute_formspec_handler_2, pos)
	else
		minetest.chat_send_player(sender:get_player_name(), "Your key does not match the lock")
	end
end
realdoors.saferoute_formspec_handler_2 = function(pos)
	mesecon.receptor_off(pos, realdoors.connection_rules)
end

minetest.register_node("realdoors:keyswitch", {
	description = "Key switch",
	drawtype = "nodebox",
	tiles = {"keyswitch.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sunlight_propagates = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1, -0.1, 0.4, 0.1, 0.1, 0.5},
		},
	},
	groups = {snappy = 1},
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("formspec", realdoors.keyswitch_formspec)
		local inv = minetest.get_inventory({type = "node", pos = pos})
		inv:set_size("keyslot", 1)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		realdoors.keyswitch_formspec_handler(pos, fields, sender)
	end,
	mesecons = {
		receptor = {
			state = mesecon.state.off,
			rules = realdoors.connection_rules,
		},
	},
})

minetest.register_node("realdoors:cardreader", {
	description = "Keycard reader",
	drawtype = "nodebox",
	tiles = {"keycardreader.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sunlight_propagates = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1, -0.125, 0.4, 0.1, 0.125, 0.5},
		},
	},
	groups = {snappy = 1},
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("formspec", realdoors.cardreader_formspec)
		local inv = minetest.get_inventory({type = "node", pos = pos})
		inv:set_size("cardslot", 2)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		realdoors.cardreader_formspec_handler(pos, fields, sender)
	end,
	mesecons = {
		receptor = {
			state = mesecon.state.off,
			rules = realdoors.connection_rules,
		},
	},
})

minetest.register_node("realdoors:codepad", {
	description = "Codepad",
	drawtype = "nodebox",
	tiles = {"codepad.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sunlight_propagates = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1, -0.125, 0.4, 0.1, 0.125, 0.5},
		},
	},
	groups = {snappy = 1},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", realdoors.codepad_formspec)
		meta:mark_as_private("entered")
		meta:mark_as_private("code")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		realdoors.codepad_formspec_handler(pos, fields, sender)
	end,
	mesecons = {
		receptor = {
			state = mesecon.state.off,
			rules = realdoors.connection_rules,
		},
	},
})

minetest.register_node("realdoors:saferoute", {
	description = "SafeRoute system",
	drawtype = "nodebox",
	tiles = {"saferoute_default.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sunlight_propagates = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1, -0.125, 0.4, 0.1, 0.125, 0.5},
		},
	},
	groups = {snappy = 1},
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("formspec", realdoors.saferoute_formspec)
		local inv = minetest.get_inventory({type = "node", pos = pos})
		inv:set_size("keyslot", 1)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		realdoors.saferoute_formspec_handler(pos, fields, sender)
	end,
	mesecons = {
		receptor = {
			state = mesecon.state.off,
			rules = realdoors.connection_rules,
		},
	},
})

minetest.register_node("realdoors:saferoute_alarm", {
	description = "SafeRoute system (alarm going off)",
	drawtype = "nodebox",
	tiles = {"saferoute_active.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sunlight_propagates = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1, -0.125, 0.4, 0.1, 0.125, 0.5},
		},
	},
	groups = {snappy = 1, not_in_creative_inventory = 1},
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("formspec", realdoors.saferoute_formspec)
		local inv = minetest.get_inventory({type = "node", pos = pos})
		inv:set_size("keyslot", 1)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		realdoors.saferoute_formspec_handler(pos, fields, sender)
	end,
	mesecons = {
		receptor = {
			state = mesecon.state.on,
			rules = realdoors.connection_rules,
		},
	},
})

minetest.register_abm({
	label = "SafeRoute alarm",
	nodenames = {"realdoors:saferoute_alarm"},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		minetest.sound_play("lockbeep_error", {
			pos = pos,
			max_hear_distance = 8,
			gain = 4.0,
		})
	end,
})

minetest.register_node("realdoors:toggler", {
	description = "Door toggler",
	drawtype = "nodebox",
	tiles = {"toggler.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sunlight_propagates = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
	groups = {snappy = 1},
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("formspec", "field[doorpos;Door position;${door}]")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass = true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if fields.doorpos then
			minetest.get_meta(pos):set_string("door", fields.doorpos)
		end
	end,
	mesecons = {
		effector = {
			rules = realdoors.connection_rules,
			action_on = function(pos, node)
				local doorpos = minetest.string_to_pos(minetest.get_meta(pos):get_string("door"))
				if not doorpos then return end
				realdoors.toggle(doorpos)
			end,
			action_off = function(pos, node)
				local doorpos = minetest.string_to_pos(minetest.get_meta(pos):get_string("door"))
				if not doorpos then return end
				realdoors.toggle(doorpos)
			end,
		},
	},
})

minetest.log("verbose", "[realdoors] Loaded controllers.lua v" .. realdoors.v)
