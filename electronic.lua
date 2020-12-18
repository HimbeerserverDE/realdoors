realdoors.electronic_defs = {}

realdoors.electronic_formspec = "size[16,4]" ..
"list[context;cardslot;1,1;1,1]" ..
"button[3,1;3,1;cardcheck;Use keycard]" ..
"list[context;cardslot;7,1;1,1;1]" ..
"button[9,1;3,1;carddup;Copy card]" ..
"button[13,1;3,1;cardadd;Add card]" ..
"button[13,2;3,1;cardrm;Remove card]" ..
"button[13,3;3,1;cardrst;Remove all cards]" ..
"button[1,3;3,1;close;Close door]" ..
"list[current_player;main;1,2;9,1]"

function table_contains(t, e)
	for _, v in ipairs(t) do
		if v == e then
			return true
		end
	end
	return false
end

function table_remove(t, e)
	for k, v in ipairs(t) do
		if v == e then
			t[k] = nil
		end
	end
	return t
end

realdoors.electronic_formspec_handler = function(pos, fields, sender)
	local meta = minetest.get_meta(pos)
	if fields.close then
		if meta:get_string("state") == "open" then
			realdoors.toggle(pos)
		end
	end
	local inv = minetest.get_inventory({type = "node", pos = pos})
	local cardstack = inv:get_stack("cardslot", 1)
	if cardstack:get_name() ~= "realdoors:card" then return end
	local key = cardstack:get_meta():get_string("id")
	
	local reqkeys = minetest.deserialize(meta:get_string("keys")) or {}
	
	if fields.carddup then
		local dupstack = inv:get_stack("cardslot", 2)
		if dupstack:get_name() ~= "realdoors:card_blank" then return end
		dupstack:set_name("realdoors:card")
		dupstack:get_meta():set_string("id", key)
		inv:set_stack("cardslot", 2, dupstack)
		return
	end
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
	if not fields.cardcheck then return end
	if meta:get_string("key") == "" then
		meta:set_string("key", key)
		minetest.chat_send_player(sender:get_player_name(), "The following card is now the master card: " .. key)
		minetest.sound_play("lockbeep_ok", {
			pos = pos,
			max_hear_distance = 8,
			gain = 4.0,
		})
		return
	end
	if table_contains(reqkeys, key) then
		realdoors.toggle(pos)
		minetest.sound_play("lockbeep_ok", {
			pos = pos,
			max_hear_distance = 8,
			gain = 4.0,
		})
	else
		minetest.chat_send_player(sender:get_player_name(), "Your keycard is not valid")
		minetest.sound_play("lockbeep_error", {
			pos = pos,
			max_hear_distance = 8,
			gain = 4.0,
		})
	end
end

realdoors.register_electronic = function(def)
	minetest.register_node("realdoors:edoor_" .. def.name .. "_a", {
		description = def.desc .. " (left)",
		drawtype = "mesh",
		tiles = {def.tex},
		inventory_image = def.tex_inv,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		sunlight_propagates = false,
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 1.5, -0.375},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 1.5, -0.375},
			},
		},
		mesh = "realdoor_a.obj",
		sounds = default.node_sound_wood_defaults(),
		groups = {snappy = 3},
		on_construct = function(pos)
			minetest.get_meta(pos):set_string("state", "closed")
			local inv = minetest.get_inventory({type = "node", pos = pos})
			inv:set_size("cardslot", 2)
			minetest.get_meta(pos):set_string("formspec", realdoors.electronic_formspec)
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			realdoors.electronic_formspec_handler(pos, fields, sender)
		end,
	})
	minetest.register_node("realdoors:edoor_" .. def.name .. "_b", {
		description = def.desc .. " (right)",
		drawtype = "mesh",
		tiles = {def.tex},
		inventory_image = def.tex_inv,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		sunlight_propagates = false,
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 1.5, -0.375},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 1.5, -0.375},
			},
		},
		mesh = "realdoor_b.obj",
		sounds = default.node_sound_wood_defaults(),
		groups = {snappy = 3},
		on_construct = function(pos)
			minetest.get_meta(pos):set_string("state", "closed")
			local inv = minetest.get_inventory({type = "node", pos = pos})
			inv:set_size("cardslot", 2)
			minetest.get_meta(pos):set_string("formspec", realdoors.electronic_formspec)
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			realdoors.electronic_formspec_handler(pos, fields, sender)
		end,
	})
	realdoors.electronic_defs[def.name] = def
end

realdoors.init_card = function(itemstack, id)
	if not id then
		math.randomseed(os.clock())
		id = math.random(111111111, 999999999)
	end
	local meta = itemstack:get_meta()
	meta:set_string("id", tostring(id))
	return itemstack
end

minetest.register_craftitem("realdoors:card_blank", {
	description = "Blank keycard",
	inventory_image = "card_blank.png",
})
minetest.register_craftitem("realdoors:card", {
	description = "Keycard",
	inventory_image = "realdoors_card.png",
})

minetest.register_craft({
	type = "shaped",
	output = "realdoors:card_blank",
	recipe = {
		{"default:paper"},
		{"default:mese_crystal"},
		{"default:paper"},
	},
})
minetest.register_craft({
	type = "shapeless",
	output = "realdoors:card",
	recipe = {"realdoors:card_blank", "default:mese_crystal"},
})

minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	if itemstack:get_name() ~= "realdoors:card" then return end
	return realdoors.init_card(itemstack)
end)

minetest.log("verbose", "[realdoors] Loaded electronic.lua v" .. realdoors.v)
