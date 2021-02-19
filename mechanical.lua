realdoors.mechanical_defs = {}

realdoors.mechanical_formspec = "size[13,4]" ..
"list[context;keyslot;1,1;1,1]" ..
"button[3,1;3,1;keycheck;Use key]" ..
"list[context;keyslot;7,1;1,1;1]" ..
"button[9,1;3,1;keydup;Copy key]" ..
"button[1,3;3,1;close;Close door]" ..
"list[current_player;main;1,2;9,1]"

realdoors.mechanical_formspec_handler = function(pos, fields, sender)
	local meta = minetest.get_meta(pos)
	if fields.close then
		if meta:get_string("state") == "open" then
			realdoors.toggle(pos)
		end
	end
	local inv = minetest.get_inventory({type = "node", pos = pos})
	local keystack = inv:get_stack("keyslot", 1)
	if keystack:get_name() ~= "realdoors:key" then return end
	local key = keystack:get_meta():get_string("shape")
	if fields.keydup then
		local dupstack = inv:get_stack("keyslot", 2)
		if dupstack:get_name() ~= "realdoors:key_unsmithed" then return end
		dupstack:set_name("realdoors:key")
		dupstack:get_meta():set_string("shape", key)
		inv:set_stack("keyslot", 2, dupstack)
		return
	end
	if not fields.keycheck then return end
	if meta:get_string("key") == "" then
		meta:set_string("key", key)
		minetest.chat_send_player(sender:get_player_name(), "This door has been linked to key " .. key)
		return
	end
	if key == meta:get_string("key") then
		realdoors.toggle(pos)
	else
		minetest.chat_send_player(sender:get_player_name(), "Your key does not match the lock")
	end
end

realdoors.register_mechanical = function(def)
	minetest.register_node("realdoors:door_" .. def.name .. "_a", {
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
			inv:set_size("keyslot", 2)
			minetest.get_meta(pos):set_string("formspec", realdoors.mechanical_formspec)
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			realdoors.mechanical_formspec_handler(pos, fields, sender)
		end,
	})
	minetest.register_node("realdoors:door_" .. def.name .. "_b", {
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
			inv:set_size("keyslot", 2)
			minetest.get_meta(pos):set_string("formspec", realdoors.mechanical_formspec)
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			realdoors.mechanical_formspec_handler(pos, fields, sender)
		end,
	})
	realdoors.mechanical_defs[def.name] = def
end

realdoors.toggle = function(pos)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	if not node.name:match("^realdoors%:e?door.*") then return end
	local open = false
	if meta:get_string("state") == "open" then open = true end
	local def = realdoors.mechanical_defs[node.name:gsub("realdoors:door_", ""):gsub("realdoors:edoor_", ""):gsub("_a", ""):gsub("_b", "")] or realdoors.electronic_defs[node.name:gsub("realdoors:door_", ""):gsub("realdoors:edoor_", ""):gsub("_a", ""):gsub("_b", "")]
	local align = node.name:gsub("realdoors:door_", ""):gsub("realdoors:edoor_", ""):gsub(def.name, ""):gsub("_", "")
	local elec = ""
	if node.name:find("realdoors:edoor_", nil, true) then elec = "e" end
	local newname = "realdoors:" .. elec .. "door_" .. def.name
	if align == "a" then
		newname = newname .. "_b"
	else
		newname = newname .. "_a"
	end
	local newdir = node.param2
	if align == "a" and not open then
		newdir = newdir + 1
	elseif align == "a" and open then
		newdir = newdir + 1
	elseif align == "b" and not open then
		newdir = newdir - 1
	elseif align == "b" and open then
		newdir = newdir - 1
	end
	if newdir <= -1 then newdir = newdir + 4
	elseif newdir >= 4 then newdir = newdir - 4 end
	open = not open
	if open then
		meta:set_string("state", "open")
	else
		meta:set_string("state", "closed")
	end
	minetest.swap_node(pos, {name = newname, param = node.param, param2 = newdir})
end

realdoors.init_key = function(itemstack, shape)
	if not shape then
		math.randomseed(os.clock())
		shape = math.random(111111111, 999999999)
	end
	local meta = itemstack:get_meta()
	meta:set_string("shape", tostring(shape))
	return itemstack
end

minetest.register_craftitem("realdoors:saw", {
	description = "Key saw",
	inventory_image = "key_saw.png",
})

minetest.register_craftitem("realdoors:key_unsmithed", {
	description = "Unsmithed key",
	inventory_image = "key_unsmithed.png",
})
minetest.register_craftitem("realdoors:key", {
	description = "Key",
	inventory_image = "realdoors_key.png",
})

minetest.register_craft({
	type = "shaped",
	output = "realdoors:saw",
	recipe = {
		{"", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "default:mese_crystal", "default:steel_ingot"},
		{"", "default:steel_ingot", "default:steel_ingot"},
	},
})

minetest.register_craft({
	type = "shaped",
	output = "realdoors:key_unsmithed",
	recipe = {
		{"", "", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "", "default:steel_ingot"},
	},
})
minetest.register_craft({
	type = "shapeless",
	output = "realdoors:key",
	recipe = {"realdoors:key_unsmithed", "realdoors:saw"},
})

minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	if itemstack:get_name() ~= "realdoors:key" then return end
	return realdoors.init_key(itemstack)
end)

minetest.log("verbose", "[realdoors] Loaded mechanical.lua v" .. realdoors.v)
